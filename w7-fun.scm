
; W7 fundamentals -- what all users see.


; Scheme- as defined by AI Memo 1564

; Cells - the primitive side effect.
; We eschew set-car!, vector-set!, etc. because they can too easily 
; create accidental communication channels.

(define-record-type cell :cell
  (make-cell)
  cell?
  (value cell-ref cell-set!))

(define (new-cell . init-option)
  (let ((cell (make-cell)))
    (if (not (null? init-option))
	(cell-set! cell (car init-option)))
    cell))


; Enclose converts a lambda-expression to a procedure.

(define (enclose lambda-exp env)
  (if (and (pair? lambda-exp)
	   (eq? (car lambda-exp) 'lambda))
      (eval lambda-exp env)
      (error "arg to enclose wasn't a lambda-expression" lambda-exp env)))

(define (control hunoz whatnot)
  (error "arg to CONTROL isn't a known hardware I/O device" hunoz))


; Rights amplification - built into Scheme 48.

(define (new-seal)
  (make-record-type 'sealed '(obj)))

(define (seal obj s)
  ((record-constructor s '(obj)) obj))

(define (unseal z s)
  ((record-accessor s 'obj) z))

(define (sealed? candidate s)
  ((record-predicate s) candidate))
