#lang racket/base
(provide define-gobject* define-gobject define-gi* define-gi g-type-init c-name); g-signal-connect-data)

(require "utils.rkt" ffi/unsafe ffi/unsafe/define
         (for-syntax racket/base syntax/parse))

(define gobject-lib 
  (ffi-lib (case (system-type)
             [(windows) "libgobject-2.0-0"]
             [else "libgobject-2.0"])
           #:fail (λ () #f)))

(define gi-lib 
  (ffi-lib (case (system-type)
             [(windows) "libgirepository-win32-1-0"]
             [else "libgirepository-1.0"])
           #:fail (λ () #f)))

(define-ffi-definer define-gobject gobject-lib #:default-make-fail (λ _ #f))
(define-ffi-definer define-gi gi-lib #:default-make-fail (λ _ #f))

(module c-name racket/base
  (provide c-name)
  (require racket/string)

  (define (c-name name)
    (if (symbol? name)
        (c-name (symbol->string name))
        (string-replace name "-" "_"))))
(require 'c-name (for-syntax 'c-name))

(with-template 
 (src dst)
 ([define-gi define-gi*]
  [define-gobject define-gobject*])
 (define-syntax (dst stx)
   (syntax-parse stx
     [(_ id:id expr:expr 
         (~or params:expr
              (~and (~seq (~seq kw:keyword arg:expr)) (~seq kwd ...))
              (~optional (~seq #:c-id c-id) 
                         #:defaults ([c-id (datum->syntax
                                            #'id 
                                            (string->symbol 
                                             (c-name (syntax-e #'id))))]))) ...)
      (syntax-protect (syntax/loc stx (src id expr params ... kwd ... ... #:c-id c-id)))])))

(define-gobject* g-type-init (_fun -> _void))
(g-type-init)