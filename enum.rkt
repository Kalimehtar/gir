#lang racket/base

(require "contract.rkt")
(provide (contract-out (build-enum ffi-builder?)))

(require "base.rkt" "loadlib.rkt" "function.rkt" ffi/unsafe)
;; (gtk 'WindowType ':toplevel) => 0 

(define-gi* g-enum-info-get-n-values (_fun _pointer -> _int))
(define-gi* g-enum-info-get-value (_fun _pointer _int -> _info))
(define-gi* g-value-info-get-value (_fun _pointer -> _int64))
(define-gi* g-enum-info-get-n-methods (_fun _pointer -> _int))
(define-gi* g-enum-info-get-method (_fun _pointer _int -> _info))
  

(define (build-enum info)
  (define values-dict
    (for/list ([i (in-range (g-enum-info-get-n-values info))])
      (define value-info (g-enum-info-get-value info i))
      (cons (g-base-info-get-name value-info)
            (g-value-info-get-value value-info))))
  (define methods-dict
    (for/list ([i (in-range (g-enum-info-get-n-methods info))])
      (define func-info (g-enum-info-get-method i))
      (cons (g-base-info-get-name func-info)
            (build-function func-info))))
  (λ (name . args)
    (define name* (gtk-name name))
    (if (char=? (string-ref name* 0) #\:)
        (cdr (or (assoc (substring name* 1) values-dict)
                 (raise-argument-error 'build-enum "FFI enum value name" name)))
        (apply (or (assoc name* methods-dict) 
                   (raise-argument-error 'build-enum "FFI method name" name))
               args))))