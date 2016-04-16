GObject Introspection

```racket
 (require gir)
```

# 1. Main interface

This is Gobject FFI.

Usage example:

```racket
(define gtk (gi-ffi "Gtk"))         
(gtk 'init 0 #f)                    
(let ([window (gtk 'Window 'new 0)])
  (window 'show)                    
  (gtk 'main))                      
```

Interface with the GObjectIntrospection is based on repositories. Main
function is

```racket
(gi-ffi repository-name [version]) -> procedure?
  repository-name : string?                     
  version : string? = ""                        
```

Returns interface to repository with name `repository-name`

# 2. Get FFI element

```racket
(repository func-name func-arg ...) -> any/c            
  func-name : (or/c string? symbol?)                    
  func-arg : any/c                                      
(repository const-name) -> any/c                        
  const-name : (or/c string? symbol?)                   
(repository enum-name enum-value-name) -> exact-integer?
  enum-name : (or/c string? symbol?)                    
  enum-value-name : (or/c string? symbol?)              
(repository class-name constructor-name) -> procedure?  
  class-name : (or/c string? symbol?)                   
  constructor-name : (or/c string? symbol?)             
```

This interface takes as a first argument name of foreign object. Name
could be `string?` or `symbol?`. In both cases it’s allowed to replace
"\_" with "-". So you can write either "get\_name" or ’get-name with the
same result.

If first argument is a name of function, then rest arguments are the
arguments of the function and it returns result of the function. In
example

```racket
(define gtk (gi-ffi "Gtk"))
(gtk 'init 0 #f)           
```

gtk\_init is called with 0 and null pointer.

If first argument is a name of constant, then it returns value of the
constant. For example,

`(gtk` `'MAJOR-VERSION)`

returns 2 for GTK2 or 3 for GTK3.

If first argument is a name of enumeration, then second arguments should
be value name. It returns integer value. For example,

`(gtk` `'WindowType` `':toplevel)`

Returns 0.

If first argument is a name of class (or struct), then the second
argument should be a name of class constructor (in GTK it is usually
"new"), rest arguments are the arguments of the constructor.

`(define` `window` `(gtk` `'Window` `'new` `0))`

This call will return a representation of object.

# 3. Foreign objects

```racket
(object method-name method-arg ...) -> any/c
  method-name : (or/c string? symbol?)      
  method-arg : any/c                        
```

Representation of an object is also a function. First argument of it
should be either name of method (`string?` or `symbol?`) or special
name.

`(window` `'add` `button)`

will call method "add" with argument "button".

## 3.1. Pointer to object

To get C pointer to an object call it with "method" :this.

`(window` `':this)`

## 3.2. Fields

Getting and setting field values are done with :field and :set-field!.

```racket
(define entry (gtk 'TargetEntry 'new "ok" 0 0))
                                               
> (entry ':field 'flags)                       
0                                              
> (entry ':set-field! 'flags 1)                
> (entry ':field 'flags)                       
1                                              
```

But you cannot set with :set-field! complex types such as structs,
unions or even strings. It is a restriction of GObjectIntrospection.

## 3.3. Properties

Getting and setting field values are done with :properties and
:set-properties!. You may get or set several properties at once.

```racket
(define-values (width height)                                    
  (window ':properties 'width-request 'height-request))          
(window ':set-properties! 'width-request 100 'height-request 200)
```

# 4. Signals

```racket
(connect object signal-name handler) -> void?
  object : procedure?                        
  signal-name : (or/c symbol? string?)       
  handler : (or/c procedure? cpointer?)      
```

# 5. Alternative interface

If you like more traditional interface, you may use `gir/interface`
module

```racket
 (require gir/interface)
```

It provides interface in style of `racket/class`: `send`, `send/apply`,
`dynamic-send`, `set-field!`, `get-field`, `dynamic-get-field`,
`dynamic-set-field!`.

Besides, it provides functional interface for object pointers and
properties:

```racket
(pointer object) -> cpointer?
  object : procedure?        
```

Returns pointer to object

```racket
(get-properties object property-name ...+) -> any/c ...+
  object : procedure?                                   
  property-name : (or/c string? symbol?)                
```

```racket
(set-properties! object                      
                 property-name               
                 property-value ...+         
                 ...+)               -> void?
  object : procedure?                        
  property-name : (or/c string? symbol?)     
  property-value : any/c                     
```
