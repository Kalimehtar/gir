#lang racket/base

(require racket/contract/base (only-in ffi/unsafe cpointer?))

(provide ffi-builder? ffi-function-builder? contract-out)

(define ffi-builder? 
  ((and/c (not/c #f) cpointer?) . -> . (->* ((or/c symbol? string?)) #:rest (listof any/c) any)))

(define ffi-function-builder? 
  ((and/c (not/c #f) cpointer?) . -> . (->* () #:rest (listof any/c) any)))

