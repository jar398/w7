
; User-to-user communication feature(s).

; Publication (what Marge does)

(define publications (make-table))

(define (publish! name obj)
  (if (table-ref publications name)
      (error "Can't publish under this name, it's already taken"
	     name obj)
      (table-set! publications name obj)))

(define (lookup name)
  (table-ref publications name))

