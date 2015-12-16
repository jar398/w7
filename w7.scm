
; W7

; Environment (= key ring) management.

(define (new-user-environment)
  (set-up-environment
    (make-simple-package (list usual-w7-features) #t #f)
    #t))

(define (set-up-environment env enabled?)
  ;; (init-focus-values! env)
  ;; (environment-define! env '%transcript (list '()))
  ;; (environment-define! env '%enabled? enabled?)
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
