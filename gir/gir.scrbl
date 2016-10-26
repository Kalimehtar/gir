#lang scribble/manual
@(require (for-label racket/base racket/class ffi/unsafe gir 
                     (only-in "interface.rkt" pointer 
                              get-properties set-properties!)))

@title{GObject Introspection}

@(defmodule gir)

@section{Main interface}

This is Gobject FFI. 

Usage example:

@racketblock[
(define gtk (gi-ffi "Gtk"))
(gtk 'init 0 #f)
(let ([window (gtk 'Window 'new 0)])
  (window 'show)
  (gtk 'main))
]

Interface with the GObjectIntrospection is based on repositories. Main function is

@defproc[(gi-ffi [repository-name string?] [version string? ""]) procedure?]{
  Returns interface to repository with name @racket[repository-name]                                                                                                                                                                       
}

@section{Get FFI element}

@(defproc* ([(repository [func-name (or/c string? symbol?)] [func-arg any/c] ...) any/c]
            [(repository [const-name (or/c string? symbol?)]) any/c]
            [(repository [enum-name (or/c string? symbol?)] [enum-value-name (or/c string? symbol?)]) exact-integer?]
            [(repository [class-name (or/c string? symbol?)] [constructor-name (or/c string? symbol?)]) procedure?]))

This interface takes as a first argument name of foreign object. Name could be @racket[string?] 
or @racket[symbol?]. In both cases it's allowed to replace "_" with "-". So you can write either 
"get_name" or 'get-name with the same result.

If first argument is a name of function, then rest arguments are the arguments of the function and
it returns result of the function.
In example
@racketblock[
(define gtk (gi-ffi "Gtk"))
(gtk 'init 0 #f)
]
gtk_init is called with 0 and null pointer.

If first argument is a name of constant, then it returns value of the constant.
For example,
@racketblock[
(gtk 'MAJOR-VERSION)
]
returns 2 for GTK2 or 3 for GTK3.

If first argument is a name of enumeration, then second arguments should be value name. It returns integer value.
For example,
@racketblock[
(gtk 'WindowType ':toplevel)
]
Returns 0.

If first argument is a name of class (or struct), then the second argument should be a name of class constructor 
(in GTK it is usually "new"), rest arguments are the arguments of the constructor.
@racketblock[
(define window (gtk 'Window 'new 0))
]
This call will return a representation of object.

@section{Foreign objects}

@(defproc (object [method-name (or/c string? symbol?)] [method-arg any/c] ...) any/c)

Representation of an object is also a function. First argument of it should be either name of method 
(@racket[string?] or @racket[symbol?]) or special name.

@racketblock[
(window 'add button)
]
will call method "add" with argument "button".

@subsection{Pointer to object}

To get C pointer to an object call it with "method" :this.
@racketblock[
(window ':this)
]

@subsection{Fields}

Getting and setting field values are done with :field and :set-field!.
@racketblock[
(define entry (gtk 'TargetEntry 'new "ok" 0 0))

> (entry ':field 'flags)
0
> (entry ':set-field! 'flags 1)
> (entry ':field 'flags)
1
]

But you cannot set with :set-field! complex types such as structs, unions or even strings. 
It is a restriction of GObjectIntrospection.

@subsection{Properties}

Getting and setting field values are done with :properties and :set-properties!. 
You may get or set several properties at once.

@racketblock[
(define-values (width height) 
  (window ':properties 'width-request 'height-request))
(window ':set-properties! 'width-request 100 'height-request 200)
]

@section{Signals}

@defproc[(connect [object procedure?] [signal-name (or/c symbol? string?)] [handler (or/c procedure? cpointer?)]) void?]

@section{Alternative interface}

If you like more traditional interface, you may use @racketmod[gir/interface] module

@defmodule[gir/interface]

It provides interface in style of @racket[racket/class]: @racket[send], @racket[send/apply], @racket[dynamic-send], 
@racket[set-field!], @racket[get-field], @racket[dynamic-get-field], @racket[dynamic-set-field!].

Besides, it provides functional interface for object pointers and properties:

@(defproc (pointer [object procedure?]) cpointer? "Returns pointer to object")

@(defproc (get-properties [object procedure?] [property-name (or/c string? symbol?)] ...+) (values any/c ...+))

@(defproc (set-properties! [object procedure?] 
                           [property-name (or/c string? symbol?)] 
                           [property-value any/c] 
                           ...+ 
                           ...+) void?)
