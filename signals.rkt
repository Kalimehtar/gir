#lang racket/base
(provide connect)
(require "loadlib.rkt" "base.rkt" "object.rkt" ffi/unsafe)
(define _signal-flags (_bitmask '(run-first
                                  = 1
                                  run-last = 2
                                  run-cleanup = 4
                                  no-recurse = 8
                                  detailed = 16
                                  action = 32
                                  no-hooks = 64
                                  must-collect = 128
                                  deprecated = 256)))

(define-cstruct _signal-query ([id _uint]
                               [name _string]
                               [itype _ulong]
                               [flags _signal-flags]
                               [return-type _ulong]
                               [n-params _uint]
                               [params _pointer]))


(define-gobject* g-signal-query (_fun _int (q : (_ptr o _signal-query)) -> _void -> q))
(define-gobject* g-signal-lookup (_fun _string _ulong -> _uint))
(define-gobject* g-type-name (_fun _ulong -> _string))
(define (gtype obj) (ptr-ref (ptr-ref obj _pointer) _ulong))


(define-gi* g-irepository-find-by-gtype (_fun (_pointer = #f) _long -> _pointer))

(define (gobject gtype ptr)
  (let ([info (g-irepository-find-by-gtype gtype)])
      (if (and info (eq? (g-base-info-get-type info) 'object))
          (build-object-ptr info ptr)
          (raise-argument-error 'gi-ffi "gtype not found in GI" gtype))))

(define _gobject (make-ctype _pointer (λ (x) (x ':this)) (λ (x) (gobject (gtype x) x))))

(define (gtype->ffi gtype)
  (case (quotient gtype 4)
    [(0 1) _void]
    [(3) _byte]
    [(4) _ubyte]
    [(5) _bool]
    [(6) _int]
    [(7) _long]
    [(8) _ulong]
    [(9) _int64]
    [(10) _uint64]
    [(13) _float]
    [(14) _double]
    [(15) _pointer]
    [else _gobject]))

(define (build-signal-handler object signal-name signals-box) 
  (define query (g-signal-query (g-signal-lookup signal-name (gtype object))))
  (_cprocedure (cons _gobject
                     (for/list ([i (in-range (signal-query-n-params query))])
                       (gtype->ffi (ptr-ref (signal-query-params query) _ulong i))))
               (gtype->ffi (signal-query-return-type query)) #:keep signals-box))

(define-gobject* g-signal-connect-data (_fun _pointer
                                             _string
                                             _pointer
                                             (_pointer = #f) ; data
                                             (_pointer = #f) ; notify
                                             (_bitmask '(after = 1 swapped = 2)) -> _ulong))

(define (connect object signal function [flags null])
  (define object-ptr (object ':this))
  (define real-type (build-signal-handler object-ptr signal (object ':signals)))
  (g-signal-connect-data object-ptr signal (cast function real-type _pointer) flags))