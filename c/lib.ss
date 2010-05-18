#lang scheme/base
(require scheme/foreign)
(unsafe!)

(define opencl-path
  (case (system-type)
    [(macosx)
     (build-path "/System" "Library" "Frameworks" "OpenCL.framework" "OpenCL")]
    [(windows)
     (build-path (getenv "WINDIR") "system32" "OpenCL")]
    [else
     ;; Assume libOpenCL is found in LD_LIBRARY_PATH
     "libOpenCL"]))

(define opencl-lib
  (with-handlers
      ([exn?
        (lambda (e)
          (when (eq? (system-type) 'unix)
            ;; Be moderately useful if library loading fails on Unix
            (display
             "Error loading the OpenCL library. Please make sure libOpenCL.so is in your LD_LIBRARY_PATH\n"
             (current-error-port)))
          (raise e))])
    (ffi-lib opencl-path)))

(define-syntax define-opencl
  (syntax-rules ()
    [(_ id ty)
     (define-opencl id id ty)]
    [(_ id internal-id ty)
     (define id (get-ffi-obj 'internal-id opencl-lib ty))]))

(provide define-opencl)