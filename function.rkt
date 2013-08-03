#lang racket/base

(require "contract.rkt")
(provide (contract-out (build-function ffi-function-builder?)))

(require "loadlib.rkt" "base.rkt" "glib.rkt" "translator.rkt" ffi/unsafe racket/format)

(define-gi* g-function-info-invoke (_fun _pointer _pointer _int
                                         _pointer _int _pointer _pointer -> _bool))
(define-gi* g-function-info-get-flags 
  (_fun _pointer -> (_bitmask '(method = 1 
                                constructor = 2 
                                getter = 4 
                                setter = 8
                                wraps-vfunc = 16
                                throws = 32))))

(define _transfer (_enum '(nothing container everything)))
(define _direction (_enum '(in out inout)))

(define-gi* g-callable-info-get-n-args (_fun _pointer -> _int))
(define-gi* g-callable-info-get-arg (_fun _pointer _int -> _info))
(define-gi* g-callable-info-get-return-type (_fun _pointer -> _info))
(define-gi* g-callable-info-get-caller-owns (_fun _pointer -> _transfer))

(define-gi* g-arg-info-get-ownership-transfer (_fun _pointer -> _transfer))
(define-gi* g-arg-info-get-direction (_fun _pointer -> _direction))
(define-gi* g-arg-info-get-type (_fun _pointer -> _info))

(define (get-args info)
  ;; if construct, then add in-arg
  (define n-args (g-callable-info-get-n-args info))
  (define (method? flags)
    (and (memq 'method flags) (not (memq 'constructor flags))))
  (let inner ([i 0]
              [in (if (method? (g-function-info-get-flags info))
                      (list pointer-translator)
                      null)]
              [out null])
    (if (= i n-args)
        (values (reverse in) (reverse out))
        (let* ([arg (g-callable-info-get-arg info i)]
               [type (g-arg-info-get-type arg)]
               [direction (g-arg-info-get-direction arg)]
               [builder (build-translator type)])
          (inner (add1 i)
                 (if (memq direction '(in inout)) (cons builder in) in)
                 (if (memq direction '(out inout)) (cons builder out) out))))))

(define (return-giarg-trans info)
  (build-translator (g-callable-info-get-return-type info)))

(define (build-function info)
  (define-values (in-trans out-trans) (get-args info))
  (define res-trans (return-giarg-trans info))
  (define name (g-base-info-get-name info))
  (λ args
    (check-args args in-trans name)
    (define giargs-in (giargs in-trans args))
    (define giargs-out (giargs out-trans))
    (define giarg-res (make-giarg))
    (with-g-error (g-error)
      (if (g-function-info-invoke info
                                  giargs-in (length in-trans) 
                                  giargs-out (length out-trans) giarg-res g-error)
          (make-out res-trans giarg-res out-trans giargs-out)
          (raise-g-error g-error)))))
                              