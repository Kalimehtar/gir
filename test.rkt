#lang racket/base

(require "loadlib.rkt" "repository.rkt" ffi/unsafe)
(provide gtk run)

(g-type-init)
(define gtk (gi-ffi "Gtk"  "2.0"))

(define (run)
  (define win (gtk 'Window 'new (gtk 'WindowType ':toplevel)))
  (g-signal-connect-data (win ':this) "destroy" (λ () (gtk 'main-quit))  #f #f)
  (define button (gtk 'Button 'new-with-label "Hello, world"))
  (button 'show)
  (win 'add button)
  (win 'show)
  (gtk 'main))
