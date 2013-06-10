#lang racket/base
(provide define-gi* define-gtk* gtk-init gtk-init* gtk-name g-signal-connect-data)

(require "utils.rkt" ffi/unsafe ffi/unsafe/define
         (for-syntax racket/base syntax/parse))

(define gtk-lib 
  (case (system-type)
    [(windows) 
     (ffi-lib "libgtk-win32-3-0")]
    [else (ffi-lib "libgtk-3" '("0" ""))]))

(define gi-lib 
  (case (system-type)
    [(windows) 
     (ffi-lib "libgirepository-win32-1-0")]
    [else (ffi-lib "libgirepository-1.0" '("1" "0" ""))]))

(define-ffi-definer define-gtk gtk-lib)
(define-ffi-definer define-gi gi-lib)

(module gtk-name racket/base
  (provide gtk-name)
  (require racket/string)
  (define (gtk-name name)
    (if (symbol? name)
        (gtk-name (symbol->string name))
        (string-replace name "-" "_"))))
(require 'gtk-name (for-syntax 'gtk-name))

(with-template 
 (src dst)
 ([define-gi define-gi*]
  [define-gtk define-gtk*])
 (define-syntax (dst stx)
   (syntax-parse stx
     [(_ id:id expr:expr 
         (~or params:expr
              (~and (~seq (~seq kw:keyword arg:expr)) (~seq kwd ...))
              (~optional (~seq #:c-id c-id) 
                         #:defaults ([c-id (datum->syntax
                                            #'id 
                                            (string->symbol 
                                             (gtk-name (syntax-e #'id))))]))) ...)
      #`(src id expr params ... kwd ... ... #:c-id c-id)])))

(define-gtk* gtk-init (_fun _pointer _pointer -> _void))
(define (gtk-init*) (gtk-init #f #f))
(define-gtk* g-signal-connect-data (_fun _pointer _string (_fun -> _void) _pointer _pointer -> _pointer))
