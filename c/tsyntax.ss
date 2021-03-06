#lang at-exp scheme/base
(require scheme/foreign
         (except-in scheme/contract ->)
         (for-syntax scheme/base
                     scheme/function)
         (file "util.ss"))
(require scribble/srcdoc)
(require/doc scheme/base
             scribble/manual)

(define-syntax-rule (define-opencl-bitfield _type _cl_bitfield valid-options _type/c
                      (value ...))
  (begin (define _type (_bitmask (append `(value = ,value)
                                         ...)
                                 _cl_bitfield))
         (define the-symbols '(value ...))
         (define symbol/c (apply symbols the-symbols))
         (define _type/c (or/c symbol/c (listof symbol/c)))
         (define valid-options the-symbols)
         (provide/doc
          (thing-doc _type ctype?
                     @{A ctype that represents an OpenCL bitfield where @scheme[valid-options] are the valid flags. It is actually a @scheme[_cl_bitfield].})
          (thing-doc _type/c contract?
                     @{A contract for @scheme[_type] that accepts any symbol in @scheme[valid-options] or lists containing subsets of @scheme[valid-options].})
          (thing-doc valid-options (listof symbol?)
                     @{A list of valid options for @scheme[_type]. Its value is @scheme['(value ...)].}))))

(define-syntax-rule (define-opencl-enum _type base-type valid-options _type/c
                      (value ...))
  (begin (define _type (_enum (append `(value = ,value)
                                      ...)
                              base-type))
         (define the-symbols '(value ...))
         (define symbol/c (apply symbols the-symbols))
         (define _type/c symbol/c)
         (define valid-options the-symbols)
         (provide/doc
          (thing-doc _type ctype?
                     @{A ctype that represents an OpenCL enumeration, implemented by @scheme[base-type], where @scheme[valid-options] are the valid values.})
          (thing-doc _type/c contract?
                     @{A contract for @scheme[_type] that accepts any symbol in @scheme[valid-options].})
          (thing-doc valid-options (listof symbol?)
                     @{A list of valid options for @scheme[_type]. Its value is @scheme['(value ...)].}))))

(define-for-syntax (stxformat fmt stx . others)
  (datum->syntax stx (string->symbol (apply format fmt (syntax->datum stx) 
                                            (map syntax->datum others)))))

(define-syntax (define-opencl-pointer stx)
  (syntax-case stx ()
    [(_ _id)
     (with-syntax ([_id/c (stxformat "~a/c" #'_id)]
                   [_id/null (stxformat "~a/null" #'_id)]
                   [id? (datum->syntax 
                         stx 
                         (string->symbol 
                          (format "~a?" 
                                  (substring 
                                   (symbol->string
                                    (syntax->datum #'_id))
                                   1))))]
                   [_id/null/c (stxformat "~a/null/c" #'_id)]
                   [_id_vector/c (stxformat "~a_vector/c" #'_id)])                    
       (syntax/loc stx
         (begin (define-cpointer-type _id)
                (define _id/c id?)
                (define _id/null/c (or/c false/c id?))
                (define _id_vector/c (cvector-of? _id))
                (provide/doc
                 (thing-doc _id ctype?
                            @{Represents a pointer to a particular kind of OpenCL object.})
                 (thing-doc _id/null ctype?
                            @{Represents a pointer to a particular kind of OpenCL object that may be NULL.})
                 (thing-doc _id/c contract?
                            @{A contract for @scheme[_id] values.})
                 (thing-doc _id/null/c contract?
                            @{A contract for @scheme[_id] values that includes NULL pointers, represented by @scheme[#f].})
                 (thing-doc _id_vector/c contract?
                            @{A contract for cvectors of @scheme[_id] values.})))))]))

(define-syntax (define-opencl-cstruct stx)
  (syntax-case stx ()
    [(_ _id ([field _type] ...))
     (with-syntax ([id (datum->syntax 
                        stx 
                        (string->symbol 
                         (substring 
                          (symbol->string
                           (syntax->datum #'_id))
                          1)))])
       (with-syntax ([_id/c (stxformat "~a/c" #'_id)]
                     [_id-pointer (stxformat "~a-pointer" #'_id)]
                     [id? (stxformat "~a?" #'id)]
                     [_id_vector/c (stxformat "~a_vector/c" #'_id)]
                     [make-id (stxformat "make-~a" #'id)]
                     [(_type/c ...) 
                      (map (curry stxformat "~a/c")
                           (syntax->list #'(_type ...)))]
                     [(_id-field ...) 
                      (map (curry stxformat "~a-~a" #'id)
                           (syntax->list #'(field ...)))]
                     [(set-_id-field! ...)
                      (map (curry stxformat "set-~a-~a!" #'id)
                           (syntax->list #'(field ...)))])
         (syntax/loc stx
           (begin (define-cstruct _id
                    ([field _type] ...))
                  (define _id/c id?)
                  (define _id_vector/c (cvector-of? _id))
                  (provide/doc
                   (thing-doc _id ctype?
                              @{Represents a structure value of a particular kind of OpenCL object.})
                   (thing-doc _id-pointer ctype?
                              @{Represents a pointer to a particular kind of OpenCL object.})
                   (proc-doc make-id (->d ([field _type/c] ...) () [_ _id/c])
                             @{Constructs a @scheme[_id] value.})
                   (proc-doc _id-field (->d ([obj _id/c]) () [_ _type/c])
                             @{Extracts the @scheme[field] of a @scheme[_id] value.})
                   ...
                   (proc-doc set-_id-field! (->d ([obj _id/c] [v _type/c]) () [_ void])
                             @{Sets the @scheme[field] of a @scheme[_id] value.})
                   ...
                   (thing-doc _id/c contract?
                              @{A contract for @scheme[_id] values.})
                   (thing-doc _id_vector/c contract?
                              @{A contract for cvectors of @scheme[_id] values.}))))))]))

(define-syntax (define-opencl-alias stx)
  (syntax-case stx ()
    [(_ _opencl_type _ctype contract-expr)
     (with-syntax ([_opencl_type/c (stxformat "~a/c" #'_opencl_type)]
                   [_opencl_type_vector/c (stxformat "~a_vector/c" #'_opencl_type)])
       (syntax/loc stx
         (begin (define _opencl_type _ctype)
                (define _opencl_type/c contract-expr)
                (define _opencl_type_vector/c (cvector-of? _opencl_type))
                (provide/doc
                 (thing-doc _opencl_type ctype?
                            @{An alias for @scheme[_ctype].})
                 (thing-doc _opencl_type/c contract?
                            @{A contract for @scheme[_opencl_type] values. Defined as @scheme[contract-expr].})
                 (thing-doc _opencl_type_vector/c contract?
                            @{A contract for vectors of @scheme[_opencl_type] values.})))))]))

(provide define-opencl-bitfield
         define-opencl-enum
         define-opencl-pointer
         define-opencl-cstruct
         define-opencl-alias
         (for-syntax stxformat))