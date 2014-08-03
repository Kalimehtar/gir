#lang setup/infotab

(define name "GI-FFI")
(define blurb
  '("GI-FFI is a foreign function interface to the GObjectIntrospection"
    "which is a modern interface to GTK, GNOME, DBus and so on"))
(define primary-file "main.rkt")
(define categories '(system ui))
(define version "0.2")
(define scribblings '(("gir.scrbl" () (library))))
(define release-notes
  (list '(ul
          (li "0.1: Initial release ")
          (li "0.2: Added (connect ...)")
          (li "0.9: Added (set-field ...) (field ...) (get-properties
...)"))))
