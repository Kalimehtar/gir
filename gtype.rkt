#lang racket/base

(require (for-syntax racket/base "utils.rkt") ffi/unsafe)

(provide case-gtype _gtype gtype)

(define _gtype _ulong)

(define (gtype obj) (ptr-ref (ptr-ref obj _pointer) _ulong))

(define-for-syntax gtypes '(invalid void interface char uchar boolean
                                    int uint long ulong int64 uint64
                                    enum flags float double string
                                    pointer boxed param object))

(define-syntax (case-gtype stx)
  (define (substitute vals)
    (for/list ([val (in-list (syntax->list vals))])
      (or (find-pos (syntax-e val) gtypes) val)))
  (define (process exprs) 
    (for/list ([expr (in-list (syntax->list exprs))])
      (define expr-list (syntax->list expr))
      (cond 
        [(pair? (syntax-e (car expr-list)))
         (cons (substitute (car expr-list)) (cdr expr-list))]
        [else expr])))
  (syntax-case stx ()
    [(_ var
        exprs ...)
     #`(case (quotient var 4) #,@(process #'(exprs ...)))]))



