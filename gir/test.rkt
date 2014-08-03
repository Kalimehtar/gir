#lang racket/base

(require "main.rkt")
(provide gtk run)

(define gtk (gi-ffi "Gtk")) ;  "2.0"))

(define (run)
  (gtk 'init 0 #f)
  (define win (gtk 'Window 'new (gtk 'WindowType ':toplevel)))
  (connect win "destroy" (λ (window) (gtk 'main-quit)))
  (define button (gtk 'Button 'new-with-label "Hello, world"))
  (connect button "clicked" (λ (btn)
                              (displayln (btn 'get-label))
                              (displayln (btn ':properties 'xalign))
                              (let-values ([(width height) (btn ':properties 'width-request 'height-request)])
                                (display width) (display " ") (displayln height))
                              (btn ':set-properties! 'label "OK")))
  (button 'show)
  (win 'add button)
  (win 'show)
  (gtk 'main))
