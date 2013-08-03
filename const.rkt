#lang racket/base

(provide get-const)
(require "loadlib.rkt" "base.rkt" "translator.rkt" ffi/unsafe)

(define-gi* g-constant-info-get-type (_fun _pointer -> _info))
(define-gi* g-constant-info-get-value (_fun _pointer _pointer -> _int))

(define (get-const info)
  (define giarg-res (make-giarg))
  (g-constant-info-get-value info giarg-res)
  (make-out (build-translator (g-constant-info-get-type info)) giarg-res))