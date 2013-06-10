#lang racket/base
(require "loadlib.rkt" ffi/unsafe ffi/unsafe/alloc)
(provide _info g-base-info-get-name)

(define-gi* g-base-info-unref (_fun _pointer -> _void)
  #:wrap (deallocator))

(define-gi* g-base-info-get-name (_fun _pointer -> _string))

(define-fun-syntax _info
  (syntax-id-rules (_info)
    [_info (type: _pointer post: (x => (((allocator g-base-info-unref) (λ () x)))))]))
