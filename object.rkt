#lang racket
(require "loadlib.rkt" "base.rkt" ffi/unsafe "function.rkt")
(provide build-object)

(define-gi* g-object-info-find-method (_fun _pointer _string -> _info))
(define-gi* g-object-info-get-parent (_fun _pointer -> _info))

(define (find-method info name)
  (if info      
    (let ([method (g-object-info-find-method info name)])
      (or (g-object-info-find-method info name)
          (begin
            ;(display "Checking parent: ") (displayln (g-base-info-get-name info))
            (find-method (g-object-info-get-parent info) name))))
    #f))

(define (name-this? name)
  (eq? name 'this))

(define (build-object info)
  (λ (name . args)
    (define function-info (find-method info (gtk-name name)))
    (unless function-info
      (raise-argument-error 'build-object "FFI method name" name))
    (define this (apply (build-function function-info) args))
    (λ (name . args)
      (if (name-this? name) this
          (let ([function-info (find-method info (gtk-name name))])
            (unless function-info
              (raise-argument-error 'build-object "FFI method name" name))
            (displayln "Run")
            (apply (build-function function-info) this args))))))