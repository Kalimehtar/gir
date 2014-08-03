#lang racket/base

(provide with-template find-pos)

(define (find-pos elt list)
  (for/first ([cur-elt list] 
              [i (in-naturals)]
              #:when (eq? cur-elt elt)) 
    i))

(define-syntax-rule (with-template (var ...) ([form ...] ...) body ...)
  (begin (define-syntax-rule (inner var ...) (begin ((... ...) body) ...))
         (inner form ...) ...))



