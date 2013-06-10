#lang racket/base
(provide build-function)

(require "loadlib.rkt" "base.rkt" "glib.rkt" ffi/unsafe racket/format)

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

(define tag-list '(void boolean int8 uint8 int16 uint16 int32 uint32 int64 uint64
                        float double gtype utf8 filename array interface glist gslist
                        ghash error unichar))

(define-gi* g-type-info-get-tag (_fun _pointer -> (_enum tag-list)))
(define-gi* g-type-info-is-pointer (_fun _pointer -> _bool))
(define-gi* g-type-info-get-param-type (_fun _pointer _int -> _info))
(define-gi* g-type-info-get-interface (_fun _pointer -> _info))
(define-gi* g-type-info-get-array-length (_fun _pointer -> _int))
(define-gi* g-type-info-get-array-fixed-size (_fun _pointer -> _int))
(define-gi* g-type-info-is-zero-terminated (_fun _pointer -> _bool))

(define _giarg (_union _bool _int8 _uint8 _int16 _uint16
                       _int32 _uint32 _int64 _uint64
                       _float _double _long _ulong _pointer _string))

(define (value->giarg translator)
  (vector-ref translator 0))

(define (giarg->value translator)
  (vector-ref translator 1))

(define (check-value translator)
  (vector-ref translator 2))

(define (translator-tag translator)
  (vector-ref translator 3))

(define (find-pos elt list)
  (define (inner list n)
    (cond 
      ((null? list) #f)
      ((eq? (car list) elt) n)
      (else (inner (cdr list) (add1 n)))))
  (inner list 0))

(define (describe-type type-info)
  (define tag (g-type-info-get-tag type-info))
  (~a (if (g-type-info-is-pointer type-info) "pointer to " "")
      tag
      (case tag
        ((interface)
         (~a " to " (g-type-info-get-interface type-info)))
        ((array)
         (~a " of " (describe-type (g-type-info-get-param-type type-info 0))
             ", length param: " (g-type-info-get-array-length type-info)
             ", fixed length: " (g-type-info-get-array-fixed-size type-info)            
             (if (g-type-info-is-zero-terminated type-info) ", zero terminated" "")))
        ((ghash)
         (~a " of {" (describe-type (g-type-info-get-param-type type-info 0))
             ", " (describe-type (g-type-info-get-param-type type-info 1))
             "}"))
        (else ""))))

(define (pointer->giarg giarg value) 
  (ptr-set! giarg _pointer (if (procedure? value) (value 'this) value)))

(define (giarg->pointer giarg) 
  (ptr-ref giarg _pointer))

(define (build-translator type)
  (define tag (g-type-info-get-tag type))
  (define pos (- (find-pos tag tag-list) 1))
  (define pointer? (g-type-info-is-pointer type))
  (define value->giarg
    (if pointer?
        pointer->giarg
        (case tag
          ((void) (λ (giarg value) (ptr-set! giarg _pointer #f)))
          ((boolean int8 uint8 int16 uint16 
                    int32 uint32 int64 uint64 float double) (λ (giarg value)
                                                              (union-set! 
                                                               (ptr-ref giarg _giarg)  
                                                               pos value)))
          ((gtype interface) (λ (giarg value)
                     (ptr-set! giarg _ulong value)))
          (else pointer->giarg))))
  (define giarg->value
    (if pointer?
        giarg->pointer
        (case tag
          ((void) (λ (giarg) #f))
          ((boolean int8 uint8 int16 uint16 
                    int32 uint32 int64 uint64 float double) (λ (giarg)
                                                              (union-ref 
                                                               (ptr-ref giarg _giarg) 
                                                               pos)))
          ((gtype interface) (λ (giarg)
                     (ptr-ref giarg _ulong)))
          (else giarg->pointer))))
  (define check-value
    (if pointer? (λ (x) (or (cpointer? x) (and (procedure? x) (cpointer? (x 'this)))))
        (case tag
          ((void)
           (λ (value) #t))
          ((boolean) boolean?)
          ((gtype interface int8 uint8 int16 uint16 
                  int32 uint32 int64 uint64) exact-integer?)
          ((float double) flonum?)
          (else cpointer?))))
  (define description (describe-type type))
  (vector-immutable value->giarg giarg->value check-value description))

(define (get-args info)
  ;; if construct + in-arg
  (define n-args (g-callable-info-get-n-args info))
  (define (inner i in out)
    (if (= i n-args)
        (values (reverse in) (reverse out))
        (let* ([arg (g-callable-info-get-arg info i)]
               [type (g-arg-info-get-type arg)]
               [direction (g-arg-info-get-direction arg)]
               [builder (build-translator type)])
          (inner (add1 i)
                 (if (memq direction '(in inout)) (cons builder in) in)
                 (if (memq direction '(out inout)) (cons builder out) out)))))
  (define (method? flags)
    (define (check-flags flags acc)
      (if (null? flags) acc
          (case (car flags) 
            ((constructor) #f)
            ((method) (check-flags (cdr flags) #t))
            (else (check-flags (cdr flags) acc)))))
    (check-flags flags #f))
  (inner 0 
         (if (method? (g-function-info-get-flags info))
             (list (vector-immutable pointer->giarg giarg->pointer 
                                     cpointer? "instance pointer"))
             null)
         null))

(define (check-args args translators name)
  (unless (= (length args) (length translators))
    (apply raise-arity-error (string->symbol name) (length translators) args))
  (define (inner args translators)
    (unless (null? args)
      (unless ((check-value (car translators)) (car args))
        (raise-argument-error (string->symbol name) 
                              (translator-tag (car translators))
                              (car args)))
      (inner (cdr args) (cdr translators))))
  (inner args translators))

(define (giargs translators [values #f])
  (define ptr (malloc _giarg (length translators)))
  (when values
    (define (inner translators values ptr)
      (unless (null? translators)        
        ((value->giarg (car translators)) ptr (car values))
        (inner (cdr translators) (cdr values) (ptr-add ptr 1 _giarg))))
    (inner translators values ptr))
  ptr)

(define (return-giarg info)
  (build-translator (g-callable-info-get-return-type info)))

(define (make-out res-trans giarg-res out-translators giargs-out)
  (define (inner translators values ptr)
    (if (null? translators)
        (reverse values)
        (inner (cdr translators) 
               (cons ((giarg->value (car translators)) ptr) values) 
               (ptr-add ptr 1 _giarg))))
  (apply values (cons
                 ((giarg->value res-trans) giarg-res)
                 (inner out-translators null giargs-out))))

(define (build-function info)
  (unless (and info (cpointer? info))
    (raise-argument-error 'build-function "info pointer" info))
  (define-values (in-trans out-trans) (get-args info))
  (define name (g-base-info-get-name info))
  (λ args
    (check-args args in-trans name)
    (define giargs-in (giargs in-trans args))
    (define giargs-out (giargs out-trans))
    (define res-trans (return-giarg info))
    (define giarg-res (malloc _giarg))
    (with-g-error (g-error)
      (if (g-function-info-invoke info
                                  giargs-in (length in-trans) 
                                  giargs-out (length out-trans) giarg-res g-error)
          (make-out res-trans giarg-res out-trans giargs-out)
          (raise-g-error g-error)))))
                              