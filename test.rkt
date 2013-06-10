#lang racket/base

(require "loadlib.rkt" "repository.rkt")
(provide gtk run)


(gtk-init*)
(define gtk (gi-ffi "Gtk"))
(display "Found Gtk ")
(display (gtk 'get-major-version))
(display ".")
(displayln (gtk 'get-minor-version))

(define (run)
  (define win (gtk 'Window 'new 0))
  (g-signal-connect-data (win 'this) "destroy" (λ () (gtk 'main-quit))  #f #f)
  (win 'show)
  (gtk 'main))