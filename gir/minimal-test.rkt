#lang racket/base

;;; This is test for GTK without GObjectIntrospection

(require ffi/unsafe ffi/unsafe/define)
(provide gtk_init gtk_get_major_version gtk_get_minor_version test)

(define gtk-lib (case (system-type)
                  [(windows) 
                   (ffi-lib "libgtk-win32-3-0")]
                  [else (ffi-lib "libgtk-3" '("0" ""))]))

(define-ffi-definer define-gtk gtk-lib)

(define-gtk gtk_init (_fun _pointer _pointer -> _void))
(define-gtk gtk_get_major_version (_fun -> _int))
(define-gtk gtk_get_minor_version (_fun -> _int))

(define-gtk gtk_window_new (_fun _int -> _pointer))
(define-gtk g_signal_connect_data (_fun _pointer _string _pointer _pointer _pointer -> _pointer))
(define-gtk gtk_widget_show (_fun _pointer -> _void))
(define-gtk gtk_main (_fun -> _void))

(define (test)
  (let ([window (gtk_window_new 0)])
    (g_signal_connect_data window "destroy" (ffi-obj-ref "gtk_main_quit" gtk-lib) #f #f)
    (gtk_widget_show window)
    (gtk_main)))
