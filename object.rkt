#lang racket/base

(require "contract.rkt")
(provide (contract-out (build-object ffi-builder?)) build-object-ptr)

(require "loadlib.rkt" "base.rkt" ffi/unsafe "function.rkt")

(define-gi* g-object-info-find-method (_fun _pointer _string -> _info))
(define-gi* g-object-info-get-parent (_fun _pointer -> _info))

(define (find-method info name)
  (and info
       (or (g-object-info-find-method info name)
           (find-method (g-object-info-get-parent info) name))))

(define (closures info)
  (define (call name args)
    (define function-info (find-method info (c-name name)))
    (if function-info
        (apply (build-function function-info) args)
        (raise-argument-error 'build-object "FFI method name" name)))
  (define (closure this)
    (define signals (box null))
    (λ (name . args)
      (case name
        [(:this) this]
        [(:signals) signals]
        [else (call name (cons this args))])))
  (values call closure))

(define (build-object info)
  (define-values (call closure) (closures info))
  (λ (name . args)
    (define this (call name args))
    (closure this)))

(define (build-object-ptr info ptr)
  (define-values (call closure) (closures info))
  (closure ptr))


