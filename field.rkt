#lang racket/base

(provide get set)
(require "loadlib.rkt" "translator.rkt" "base.rkt" ffi/unsafe)

(define-gi* g-field-info-get-field (_fun _pointer _pointer _pointer -> _bool))
(define-gi* g-field-info-set-field (_fun _pointer _pointer _pointer -> _bool))
(define-gi* g-field-info-get-type (_fun _pointer -> _pointer))

(define (get ptr field)
  (define giarg-res (make-giarg))
  (unless (g-field-info-get-field field ptr giarg-res)
    (error "FFI get field failed:" (g-base-info-get-name field)))
  (make-out (build-translator (g-field-info-get-type field)) giarg-res))

(define (set ptr field value)
  (define translators (list (build-translator (g-field-info-get-type field))))
  (define giargs-out (giargs translators (list value)))
  (unless (g-field-info-set-field field ptr giargs-out)
    (error "FFI set field failed:" (g-base-info-get-name field))))
