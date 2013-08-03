#lang racket/base

(provide set-properties get-properties property-gtype)
(require "loadlib.rkt" "object.rkt" "gtype.rkt"ffi/unsafe racket/list)

; (define-gobject* g-object-set (_fun _gobject _string ... -> void))

(define-cstruct _gparam ([instance _pointer]
                         [name _string]
                         [_flags _int]
                         [gtype _gtype]
                         [owner-gtype _gtype]))

(define-gobject* g-object-class-find-property (_fun _pointer _string -> _pointer))

(define (property-gtype object name)
  (define param (g-object-class-find-property (ptr-ref (pointer object) _pointer) name))
  (unless param
    (raise-argument-error 'property 
                          "property name" name))
  (gparam-gtype (ptr-ref param _gparam)))


(define (set-properties object . properties)
  (define (make-type gtypes)
    (_cprocedure 
     (append
      (list _gobject)
      (for*/list ([type gtypes]
                  [i (in-range 2)])
        (if (= i 1) (gtype->ffi type) _string))
      (list _pointer))
     _void))
  (define-values (type args)
    (let loop ([properties properties] 
               [gtypes null] 
               [args null])
      (cond 
        [(null? properties)
         (values (make-type (reverse gtypes)) (reverse (cons #f args)))]
        [(and (pair? properties) (pair? (cdr properties)))
         (define arg (c-name (first properties)))
         (define val (second properties))
         (loop (cddr properties) 
               (cons (property-gtype object arg) gtypes)
               (cons val (cons arg args)))])))
  (apply (get-ffi-obj "g_object_set" #f type) object args))

(define (get-properties object . properties)
  (define (make-type gtypes)
    (_cprocedure 
     (append
      (list _gobject)
      (for*/list ([type gtypes]
                  [i (in-range 2)])
        (if (= i 1) _pointer _string))
      (list _pointer))
     _void))
  (define-values (type arg-types args)
    (let loop ([properties properties] 
               [gtypes null] 
               [arg-types null] 
               [args null])
      (cond 
        [(null? properties)
         (values (make-type (reverse gtypes)) (reverse arg-types) (reverse (cons #f args)))]
        [else
         (define arg (c-name (first properties)))
         (define gtype (property-gtype object arg))
         (define arg-type (gtype->ffi gtype))
         (define val (malloc arg-type))
         (loop (cdr properties) 
               (cons gtype gtypes)
               (cons arg-type arg-types)
               (cons val (cons arg args)))])))
  (apply (get-ffi-obj "g_object_get" #f type) object args)
  (apply values 
         (let loop ([vals null] [args args] [arg-types arg-types])
           (cond
             [(null? arg-types) (reverse vals)]
             [else 
              (define val (ptr-ref (second args) (car arg-types)))
              (loop (cons val vals) (cddr args) (cdr arg-types))]))))
  
