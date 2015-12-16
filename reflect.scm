
; Kludge... would be better if no reference to command processor

(define innocuous-features
  (environment-ref (config-package) 'innocuous-features))

(define usual-w7-features
  (environment-ref (config-package) 'usual-w7-features))

; Innocuous environment

(define innocuous-environment
  (make-simple-package (list innocuous-features) #t #f))

