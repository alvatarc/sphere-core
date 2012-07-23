(namespace ("ffi#"))
(##include "~~/lib/gambit#.scm")

;-------------------------------------------------------------------------------
; Code needed by FFI-generation macros
;-------------------------------------------------------------------------------

(c-declare #<<c-declare-end

#ifndef FFIMACRO
#define FFIMACRO

#include <malloc.h>

___SCMOBJ ffimacro__leave_alone(void *p)
{
    return ___FIX(___NO_ERR);
}

___SCMOBJ ffimacro__free_foreign(void *p)
{
    if (p)
        free(p);
    return ___FIX(___NO_ERR);
}

#endif

c-declare-end
)

(define references
  (if (table? references)
    references
    (make-table weak-keys: #t weak-values: #f test: eq?)))

(define link
  (if (procedure? link)
    link
    (lambda (parent child)
      (table-set! references child parent)
      (make-will child (lambda (x) (table-set! references x))))))

;-------------------------------------------------------------------------------
; sizeof
;-------------------------------------------------------------------------------

(define sizeof-unsigned-char
  ((c-lambda () int "___result = sizeof(unsigned char);")))

;-------------------------------------------------------------------------------
; Operations
;-------------------------------------------------------------------------------

(define void*-offset
  (c-lambda ((pointer void #f) int) (pointer void #f)
            "___result_voidstar = ((void*)___arg1) + ___arg2;"))

;-------------------------------------------------------------------------------
; Conversion/casting
;-------------------------------------------------------------------------------

(define ->void*
  (c-lambda ((pointer void #f)) (pointer void #f)
            "___result_voidstar = (void*)___arg1;"))

(define void*->unsigned-char*
  (c-lambda ((pointer void)) (pointer unsigned-char)
            "___result_voidstar = ___arg1;"))

;-------------------------------------------------------------------------------
; Standard C functions
;-------------------------------------------------------------------------------

(define calloc
  (c-lambda (unsigned-int unsigned-int) (pointer void) "calloc"))

(define malloc
  (c-lambda (unsigned-int) (pointer void) "malloc"))

(define realloc
  (c-lambda ((pointer void) unsigned-int) (pointer void) "realloc"))

(define free
  (c-lambda ((pointer void)) void "free"))

;-------------------------------------------------------------------------------
; Arrays
;-------------------------------------------------------------------------------

;;; unsigned-int array

(define make-unsigned-int*
  (c-lambda (int) unsigned-int*
            "___result_voidstar = malloc(___arg1*sizeof(unsigned int));"))

(define unsigned-int*-ref
  (c-lambda (unsigned-int* int) unsigned-int
            "___result = ((unsigned int*)___arg1)[___arg2];"))

(define unsigned-int*-set!
  (c-lambda (unsigned-int* int unsigned-int) void
            "((unsigned int*)___arg1)[___arg2] = ___arg3;"))

(define (vector->unsigned-int* vec)
  (let* ((length (vector-length vec))
         (buf (make-unsigned-int* length)))
    (let loop ((i 0))
      (if (< i length)
          (begin
            (unsigned-int*-set! buf i (vector-ref vec i))
            (loop (+ i 1)))
          buf))))

