#lang racket/base

(provide with-g-error raise-g-error)

(require "loadlib.rkt" ffi/unsafe)

;;; GError

(define-struct (exn:fail:g-error exn:fail) ())

(define-syntax-rule (with-g-error (g-error) body ...)
  (let ([g-error (malloc _pointer)])
    body ...))

(define-cstruct _g-error
  ([domain _uint32]
   [code _int]
   [message _string]))
  

(define-gtk* g-quark-to-string (_fun _uint32 -> _string))

(define (make-message g-error)
  ; g-error = GError**
  (let ([s (ptr-ref g-error _g-error-pointer)])
    (format "GError: ~a: ~a (code ~a)" 
            (g-quark-to-string (g-error-domain s))
            (g-error-message s) (g-error-code s))))

(define (raise-g-error g-error)
  (raise (make-exn:fail:g-error (make-message g-error) (current-continuation-marks))))