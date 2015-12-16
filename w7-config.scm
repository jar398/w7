; Scheme 48 module configuration file for the W7 mock-up server.

; Cf. MIT AI memo 1564.

;-----------------------------------------------------------------------------
; w7-fundamentals: basic things used by W7 implementation and its users.

(define-interface w7-fundamentals-interface
  (export
	  ;; In Scheme- but not in Scheme
	  new-cell cell-ref cell-set!
	  enclose
	  ;; Control is silly.  Let's leave it out.
	  ;; control

	  ;; Defined by Marge ... but better provided primitively
	  new-seal seal unseal sealed?
	  ))

(define-structure w7-fundamentals w7-fundamentals-interface

  (open scheme define-record-types tables signals
	record-types)
  (files w7-fun))

;-----------------------------------------------------------------------------
; Multi-user feature(s).

(define-interface mud-interface
  (export publish! lookup))

(define-structure mud (export publish! lookup)
  (open scheme signals tables)
  (files mud))

;-----------------------------------------------------------------------------
; Standard environment for W7 users, sans DEFINE.
;
; Things that not-logged-in users can use.  If they log in, they additionally
; get DEFINE and a few other goodies.
; Might be simpler to start with scheme-interface and exclude things...
;
; N.b. Scheme's string->symbol and symbol->string provide a covert
; communication channel.

(define-interface innocuous-interface
  (compound-interface
   w7-fundamentals-interface
   (export 
           ;; Things from Scheme- (AI Memo)
	   ((quote lambda if begin let) :syntax)
	   + - * / < = >
	   cons car cdr
	   null? pair? list
	   symbol? eq?

	   ;; Additional things from R5RS
	   ((and cond do let let* or
		 let-syntax letrec-syntax
		 case quasiquote) :syntax)
	   <= >=
	   abs
	   angle magnitude make-polar make-rectangular
	   append  assoc assv	  
	   apply
	   boolean?
	   caaaar caaadr caadar caaddr caaar caadr caar
	   cadaar cadadr caddar cadddr cadar caddr cadr
	   cdaaar cdaadr cdadar cdaddr cdaar cdadr cdar
	   cddaar cddadr cdddar cddddr cddar cdddr cddr
	   ceiling
	   char->integer char-alphabetic?
	   char-ci<=? char-ci<? char-ci=? char-ci>=? char-ci>?
	   char-downcase char-lower-case? char-numeric?
	   char-upcase
	   char-upper-case? char-whitespace? char<=?
	   char=? char<?
	   char>=? char>?
	   char?
	   eof-object?
	   equal? eqv? even? expt
	   eval
	   exact? exact->inexact inexact->exact
	   exp log sin cos tan asin acos atan sqrt
	   floor numerator denominator
	   for-each
	   gcd
	   inexact?
	   input-port? output-port?
	   integer->char char->integer
	   lcm length list list->string list->vector
	   list-ref list-tail
	   list?
	   map max member memq memv min modulo
	   negative? not null?
	   number->string string->number
	   number? integer? rational? real? complex?
	   odd?
	   positive?
	   procedure?
	   quotient remainder
	   rationalize
	   real-part imag-part
	   reverse
	   round 
	   string string->list string->symbol
	   string->symbol
	   string-append
	   string-ci<=? string-ci<? string-ci=? string-ci>=? string-ci>?
	   string<=? string<? string=? string>=? string>?
	   string=? vector assq
	   string? string-length string-ref
	   substring
	   symbol->string
	   truncate
	   values call-with-values
	   vector->list
	   vector? vector-length vector-ref
	   zero?
	   )))

(define-structure innocuous-features
  innocuous-interface
  (open scheme
	w7-fundamentals))


(define-structure usual-w7-features
  (compound-interface innocuous-interface
		      (interface-of mud)
		      (export (define :syntax)
			      (define-syntax :syntax)))
  (open scheme
	w7-fundamentals
	mud))

(define-structure reflect-w7-features
  (export innocuous-features
	  innocuous-environment
	  usual-w7-features)
  (open scheme 
	environments
	packages
	package-commands-internal)
  (files reflect))
	   

;-----------------------------------------------------------------------------
; Setup from dissertation

(define-structure w7 (export w7x get-random)
  (open scheme
	define-record-types tables signals
	packages environments built-in-structures
	extended-ports
	handle conditions
	;; There's a conflict over the name "p" between html and pretty-print.
	(subset pp (pretty-print))
	ascii
	display-conditions
	;; w7-fundamentals  -- needed?
	;; mud  -- needed?
	reflect-w7-features
	with-sharp-sharping
	;; (subset utils (end-of-line))
	)
  (files w7))

;-----------------------------------------------------------------------------
; The server itself

;(define-structure w7-server (export w7 get-random)
;  (open scheme
;        define-record-types tables signals
;        packages environments built-in-structures
;        extended-ports handle conditions
;        ;; There's a conflict over the name "p" between html and pretty-print.
;        (subset pp (pretty-print))
;        ascii
;        display-conditions
;        ;; w7-fundamentals  -- needed?
;        ;; mud  -- needed?
;        reflect-w7-features
;        with-sharp-sharping
;        http html cgi
;        (subset utils (end-of-line)))
;  (files w7-server))

(define-structure with-sharp-sharping (export with-sharp-sharp)
  (open scheme more-structures environments packages)
  (begin (define with-sharp-sharp
	   (environment-ref (structure-package command-processor)
			    'with-sharp-sharp))))

