#lang racket/base

(provide with-template)

(define-syntax-rule (with-template (var ...) ([form ...] ...) body ...)
  (begin (define-syntax-rule (inner var ...) (begin ((... ...) body) ...))
         (inner form ...) ...))

