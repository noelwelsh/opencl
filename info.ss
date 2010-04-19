#lang setup/infotab
(define name "OpenCL")
(define blurb
  (list "An FFI for OpenCL"))
(define scribblings '(["scribblings/opencl.scrbl" (multi-page)]))
(define categories '(devtools))
(define primary-file "scheme.ss")
(define compile-omit-paths '("examples" "tests"))
(define version "1.0.48")
(define release-notes 
  (list
   '(ul (li "Windows support added"))))
(define repositories '("4.x"))