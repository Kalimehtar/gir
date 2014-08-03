#lang racket/base

(require "main.rkt")
(provide pointer get-field set-field! get-properties set-properties! 
         send dynamic-send gi-ffi connect)

(define (dynamic-send obj method-name . vs) (apply obj method-name vs))

(define-syntax-rule (send obj method-id arg ...)
  (obj 'method-id arg ... arg-list))

(define-syntax-rule (send/apply obj method-id arg ... . arg-list)
  (apply obj 'method-id arg ... arg-list))

(define (pointer obj) (obj ':this))

(define (dynamic-get-field field-name obj) (obj ':field field-name))

(define-syntax-rule (get-field id obj) (obj ':field 'id))

(define (dynamic-set-field! field-name obj v) (obj ':set-field! field-name v))

(define-syntax-rule (set-field! id obj expr) (obj ':set-field! 'id expr))

(define (get-properties obj . args) (apply obj ':properties args))

(define (set-properties! obj . args) (apply obj ':set-properties! args))
