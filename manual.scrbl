#lang scribble/manual
@(require (for-label racket))

@title{GObject Introspection}

This is Gobject FFI. 

Usage example:

@racketblock[
(define gtk (gi-ffi "Gtk"))
(gtk 'init 0 #f)
(let ([window (gtk 'Window 'new 0)])
  (window 'show)
  (gtk 'main))
]


