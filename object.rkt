#lang racket/base

(require "contract.rkt")
(provide (contract-out (build-object ffi-builder?)))

(require "loadlib.rkt" "base.rkt" ffi/unsafe "function.rkt")

(define-gi* g-object-info-find-method (_fun _pointer _string -> _info))
(define-gi* g-object-info-get-parent (_fun _pointer -> _info))

(define (find-method info name)
  (and info
       (or (g-object-info-find-method info name)
           (find-method (g-object-info-get-parent info) name))))      

(define (name-this? name)
  (eq? name ':this))

(define (build-object info)
  (define (call name args)
    (define function-info (find-method info (gtk-name name)))
    (if function-info
        (apply (build-function function-info) args)
        (raise-argument-error 'build-object "FFI method name" name)))
  (λ (name . args)
    (define this (call name args))
    (λ (name . args)
      (if (name-this? name) 
          this
          (call name (cons this args))))))