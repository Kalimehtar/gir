#lang racket/base
(provide connect)
(require "loadlib.rkt" "object.rkt" "gtype.rkt" ffi/unsafe)
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
                               [itype _gtype]
                               [flags _signal-flags]
                               [return-type _gtype]
                               [n-params _uint]
                               [params _pointer]))


(define-gobject* g-signal-query (_fun _int (q : (_ptr o _signal-query)) -> _void -> q))
(define-gobject* g-signal-lookup (_fun _string _ulong -> _uint))
(define-gobject* g-type-name (_fun _ulong -> _string))



(define (build-signal-handler object signal-name signals-box) 
  (define query (g-signal-query (g-signal-lookup signal-name (gtype object))))
  (_cprocedure (cons _gobject
                     (for/list ([i (in-range (signal-query-n-params query))])
                       (gtype->ffi (ptr-ref (signal-query-params query) _gtype i))))
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