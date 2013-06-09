Racket-gir
==========

Racket GObjectIntrospection FFI

License: BSD

Release status: Alpha

Now only objects, methods and functions are working. 
Memory management is realised only for object of GObjectIntrospection itself. 
So, if you need to call g_object_unref, you should do it manually.

Minimal example is in test.rkt.

Important: run it from Racket, not GRacket, or DrRacket. GRacket gui is linked with GTK2, so it conflicts with GTK3.
