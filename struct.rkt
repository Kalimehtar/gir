#lang racket/base
(require "contract.rkt")
(provide (contract-out (build-struct ffi-builder?)) build-struct-ptr)

(require "loadlib.rkt" "base.rkt" ffi/unsafe "function.rkt" "translator.rkt" 
         racket/match (prefix-in f: "field.rkt"))

(define-gi* g-struct-info-find-method (_fun _pointer _string -> _info))
(define-gi* g-struct-info-get-parent (_fun _pointer -> _info))
(define-gi* g-struct-info-get-n-fields (_fun _pointer -> _int))
(define-gi* g-struct-info-get-field (_fun _pointer _int -> _info))


(define (closures info)
  (define (call name args)
    (define function-info (g-struct-info-find-method info (c-name name)))
    (if function-info
        (apply (build-function function-info) args)
        (raise-argument-error 'build-struct "FFI method name" name)))
  (define fields-dict
    (for/list ([i (in-range (g-struct-info-get-n-fields info))])
      (define field-info (g-struct-info-get-field info i))
      (cons (g-base-info-get-name field-info) field-info)))
  (define (find-field name)
    (cdr (or (assoc (c-name name) fields-dict)
             (raise-argument-error 'build-struct "FFI field name" name))))
  (define (closure this)
    (define signals (box null))
    (λ (name . args)
      (case name
        [(:this) this]
        [(:signals) signals]
        [(:field)
         (match args
           [(list name) (f:get this (find-field name))])]
        [(:set-field) 
         (match args
           [(list name value) (f:set (find-field name) value)])]
        [else (call name (cons this args))])))
  (values call closure))

(define (build-struct info)
  (define-values (call closure) (closures info))
  (λ (name . args)
    (define this (call name args))
    (closure this)))

(define (build-struct-ptr info ptr)
  (define-values (call closure) (closures info))
  (closure ptr))