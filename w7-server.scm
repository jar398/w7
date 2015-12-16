; W7 server
; Quick hack

; TBD:
;   Use HTTPS
;   Transcript
;   Logging

; ,open posix
; (open-file "w7.log" (file-options append write-only))
; (call-with-append-file "w7.log" ...)

(define (w7)
  (display "The server is listening.") (newline)
  (service-http-requests 1597
			 (lambda (request) (w7-responder request))))

(define (w7-responder request)
  (prevent-error-propagation
   (lambda ()
     (let ((command (request-command request))
	   (uri (request-uri request)))
       (cond ((or (string=? uri "/")
		  (string=? uri "/eval"))
	      (case command
		((GET) (w7-root-response request))
		((POST) (w7-evaluate request))
		(else (error-response 405 "Method not allowed, binky"))))
	     ((string=? uri "/login")
	      (case command
		((GET) (w7-present-login request))
		((POST) (w7-attempt-login request))
		(else (error-response 405 "Method not allowed, binky"))))
	     ((string=? uri "/quit")
	      ;; Please don't do this if you aren't JAR - you'll deny service
	      'quit)
	     (else
	      (error-response 404 "Not found, silly")))))))

; GET /login HTTP/1.x

(define (w7-present-login request)
  (simple-html-response
   "Log in"
   (h2 "Log in")
   (form (action= "login")
	 (method= "POST")
	 (p "Email address:"
	    (br)
	    (input (name= "username")
		   (type= "text") (size= 30)))
	 (p "Password:"
	    (br)
	    (input (name= "password")
		   (type= "password") (size= 30)))
	 (p (input (type= "submit")
		   (value= "Log in")))
	 (p "Please log in if you would like to be able to use "
	    "any of the following:"
	    (ul (li (kbd 'define))
		(li (kbd 'define-syntax))
		(li (kbd 'publish!))
		(li (kbd 'lookup))))
	 (p "If this is your first time here, enter your email address, which "
	    "will be your W7 user name, and choose and remember a password.")
	 (p "If you are returning, enter the same email address and password "
	    "that you used last time."))))


; POST /login HTTP/1.x

(define (w7-attempt-login request)
  (if (eq? (content-type (request-content request))
	   'application/x-www-form-urlencoded)
      (let* ((cgi-alist (extract-content (request-content request)))
	     (uname-maybe (assoc "username" cgi-alist))
	     (password-maybe (assoc "password" cgi-alist)))
	(if (and uname-maybe password-maybe)
	    (let ((uname (cdr uname-maybe))
		  (password (cdr password-maybe)))
	      (let ((probe (table-ref known-users uname)))
		(if probe
		    ;; probe = (password . env-string)
		    ;; Returning user - check password
		    (if (string=? password (car probe))
			;; OK - env-string is (cdr probe)
			(let ((env-string (cdr probe)))
			  (reset-transcript! (look-up-environment env-string))
			  (simple-html-response
			   "W7"
			   (h2 "Welcome back, " uname)
			   (w7-evaluation-form env-string)))
			(simple-html-response
			 "W7"
			 (p "Password incorrect.  Please "
			    (a (href= "login") "try again."))))
		    ;; New user - create environment
		    (let ((env-string (get-env-string (new-user-environment))))
		      (table-set! known-users
				  uname
				  (cons password env-string))
		      (simple-html-response
		       "W7"
		       (h2 "Greetings, " uname)
		       (w7-evaluation-form env-string))))))
	    (error-response 400 "Bad request - missing CGI field(s)")))
      (error-response 400 "Bad request - not CGI")))

(define known-users (make-string-table))

; GET / HTTP/1.x

(define (w7-root-response request)
  (simple-html-response
   "W7"
   (h2 "Welcome to W7")
   (w7-evaluation-form make-fresh-env-cookie)))

(define (w7-evaluation-form env-string)
  (a (name= "eval_form")
     (form (action= "eval#eval_form")        ;Must be relative for ProxyPass
	   (method= "POST")
	   (p "Evaluate "
	      (br)
	      (textarea (name= "expression") ;No way to get this in red.
			(cols= 80)
			(rows= 4)
			"'Your-expression-here")
	      (br))
	   (p (input (type= "submit") (value= "Do it")))
	   (input (name= "environment")
		  ;; (type= "text") (size= 30)
		  (type= "hidden")
		  (value= env-string))
	   (hr)
	   (if (string-for-enabled-env? env-string)
	       '()
	       (p (a (href="login") "-LOG IN-")))
	   (p (a (href= "../help.html")
		 "-W7 HELP-")))))

; POST /eval HTTP/1.x

(define (w7-evaluate request)
  (if (eq? (content-type (request-content request))
	   'application/x-www-form-urlencoded)
      (let* ((cgi-alist (extract-content (request-content request)))
	     (env-maybe (assoc "environment" cgi-alist))
	     (expr-maybe (assoc "expression" cgi-alist)))
	(if (and env-maybe expr-maybe)
	    (let* ((env-string (cdr env-maybe))
		   (env (look-up-environment env-string)))
	      (if env
		  (let* ((env-string (get-env-string env))
			 (iport (make-string-input-port (cdr expr-maybe)))
			 (expression (read-form iport))
			 (results (call-with-values
				      ;; TBD: Set up error handler.
				      (lambda ()
					(log-before! expression env-string)
					(eval expression env))
				    list)))
		    (set-focus-values! results env)
		    (log-after! results)
		    ;; Add new expression=>results entry to transcript
		    (w7-generate-response
		     (let ((tr (environment-ref env '%transcript)))
		       (set-car! tr
				 (cons (generate-one-evaluation expression
								results)
				       (car tr)))
		       (reverse (car tr)))
		     env-string))
		  (simple-html-response
		   "Bogus environment"
		   (p "I don't know any environment called " env-string
		      ".  Please go back and try another one."))))
	    (error-response 400 "Bad request - missing CGI field(s)")))
      (error-response 400 "Bad request - not CGI")))

;; TBD: put the <a name='foo'> at the last evaluation result.
;; Save text of pretty print instead of the expressions themselves ??

(define (w7-generate-response transcript env-string)
  (simple-html-response
   "Evaluation result"
   (h2 "Evaluation result")
   transcript
   (hr)
   ;; Form for user's next evaluation request.
   (w7-evaluation-form env-string)))

; Generate HTML for a single expression => vals item.

(define (generate-one-evaluation expression vals)
  (let ((evaluation-arrow " => ")
	(indent "    "))
    (p (pre (list indent
		  (font (color= "red")
			(sexpr->printable expression 4)))
	    end-of-line
	    (cond ((null? vals)
		   (list evaluation-arrow
			 ";; no values"))
		  ((null? (cdr vals))
		   (list evaluation-arrow
			 (font (color= "blue")
			       (sexpr->printable (car vals) 4))))
		  (else
		   (list evaluation-arrow
			 ";; " (length vals) " values:"
			 end-of-line
			 indent
			 (font (color= "blue")
			       (sexpr->printable (car vals) 4))
			 (map (lambda (val)
				(list
				 end-of-line
				 indent
				 (font (color= "blue")
				       (sexpr->printable val 4))))
			      (cdr vals)))))))))

(define (log-before! expression env-string)
  (display " ")
  (write expression)
  (display " in ")
  (write env-string)
  (newline))

(define (log-after! vals)
  (display " => ")
  (for-each (lambda (val) (write-char #\space) (write val))
	    vals)
  (newline))


(define (sexpr->printable sexpr indent)
  (call-with-string-output-port
   (lambda (oport)
     (pretty-print sexpr oport indent))))

; ,in command-processor with-sharp-sharp
; (define with-sharp-sharp ##)

(define focus-object-variable-name (string->symbol "##"))

(define (read-form port)
  (with-sharp-sharp focus-object-variable-name
    (lambda () (read port))))

(define (set-focus-values! vals env)
  (if (not (null? vals))
      (environment-set! env focus-object-variable-name (car vals))))

(define (init-focus-values! env)
  (environment-define! env focus-object-variable-name 'hello))

;-----------------------------------------------------------------------------
; Environment (= key ring) management.

(define (new-user-environment)
  (set-up-environment
    (make-simple-package (list usual-w7-features) #t #f)
    #t))

(define (set-up-environment env enabled?)
  (init-focus-values! env)
  (environment-define! env '%transcript (list '()))
  (environment-define! env '%enabled? enabled?)
  (let* ((name (number->string (get-random 100) 16))
	 (name (if enabled?
		   (string-append "!" name)
		   name)))
    (table-set! env-table name env)
    (display "New environment: ") (display name) (newline)
    (environment-define! env '%env-string name))
  env)

(define (get-env-string env)
  (environment-ref env '%env-string))

(define (reset-transcript! env)
  (set-car! (environment-ref env '%transcript) '()))

(define (enabled-env? env) (environment-ref env '%enabled?))
(define (string-for-enabled-env? s) (char=? (string-ref s 0) #\!))

; Find an existing environment, or create a limited one for not-logged-in users

(define (look-up-environment env-string)
  (if (string=? env-string make-fresh-env-cookie)
      (set-up-environment
        (make-simple-package (list innocuous-features) #t #f)
	#f)
      (table-ref env-table env-string)))

(define make-fresh-env-cookie "[make a fresh environment]")

(define env-table (make-string-table))

(define (get-random nbits)
  (call-with-input-file "/dev/urandom"
    (lambda (in)
      (do ((i 0 (+ i 8))
	   (r 0 (+ (* r 256) (char->ascii (read-char in)))))
	  ((>= i nbits) r)))))

;-----------------------------------------------------------------------------

; ,open handle conditions

(define (prevent-error-propagation thunk)
  (let ((foo (ignore-errors thunk)))
    (if (error? foo)
	(simple-html-response
	 "Error"
	 (p "An error occurred while your request was being processed.")
	 (p "Here is Scheme 48's idea of what the error was:"
	    ;; tbd: use scheme48 display-condition
	    (pre (lambda (port)
		   (display-condition foo port)))))
	foo)))
