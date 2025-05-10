(load "1.1.rkt")

;;; 1.3 Environment Subsystem Proof & Change in Representation

;====================================================================
#|
 Environment Specification for TLS:
  ;; The environments of TLS are composed of ([name][value]) pair entries.
     ;; Functions that makeup the environment subsystem:
;         - new-entry
;         - lookup-in-entry
;         - extend-table
;         - lookup-in-table
;         - initial-table
|#
;======================================================================

;;;; TLS-Let: helper for subsystem proof
       ; Since lambda creates closures and keeps track of its env, it can be used to display
       ;   environment changes as we change contours
;;; let structure:  (let <(<var><exp>)...)> <body>)
 ;; let == syntactic sugar for lambda: (let ((name val)) exp) == ((lambda (name) exp) val)
     ; To be used in tests to ensure that *let works as syntactic sugar for lambda

; Accessors
(define *let-body caddr)

; Pre: Given a let expr
; Post: Return the variables from the bindings
(define (*let-var expr)
  (let loop ((binds (*let-bindings expr)))
    (cond ((null? binds) '())
          (else (cons (caar binds) (loop (cdr binds)))))))

; Pre: Given a let expr
; Post: Return the init values from the bindings
(define (*let-init expr)
  (let loop ((binds (cadr expr)))
    (cond ((null? binds) '())
          (else (cons (cadr (car binds)) (loop (cdr binds)))))))

; Predicate
(define (*let? expr)
   (eq? (car expr) '*let))

;;; Action Function -- Handles *let expresseions in TLS
 ;; IDEA: (i) let should evaluate each of its args before the body --- correctness standard acc. documentation
 ;;       (ii) should keep track of the current env like lambda implementation
 ;;       *** (i) can't garuntee order of operations
; Pre: Given a let expr, e, and the current env, table
; Post: Evaluates the let expression and stores its current environment

(define (*let expr table)
  (let ((var (*let-vars expr))
        (init (*let-init expr)))
    ; evaluate and store init values
    (meaning init (cons table '()))
    ; extend table with evaluated body
    (meaning (*let-body expr) (cons (new-entry var (evlis init table))
                                    table))))

; Test Cases
;;; ((lambda (x) x) 'hello) == (let ((x 'hello)) x)
;(*let ((x 'hello) x))
;(value '(*let ((x 'hello)) x))


;;; "TLS-Bind":
  ;; Assumption: Provided 2 equal length sets of sexps, TLS properly constructs entries of [(name)(value)] that
    ;; make up an environment.
  ;; [INCORRECT] TLS-Bind makes no changes to the data of TLS, only its representation. Therefore, each member of
    ;; TLS-Bind should be an S-exp and a member of TLS 

 ; Pre: Given an entry ((names)(vals))
 ; Post: Return the entry in binding form
 ; IDEA: cdr down both names and vals and cons the pairs to create a binding list of entries
    ; using existing accessors: first, second

;;; Helper(s)

;; merge
 ; pre: Given 2 lists, list1 and list2
 ; Post: Return the list whose elements are interwoven with elements of lists1 and 2
(define (merge lst1 lst2)
  (cond ((null? lst1) lst2)
        ((null? lst2) lst1)
        (else (cons (list (car lst1) (car lst2)) (merge (cdr lst1) (cdr lst2))))))

;(merge '(x y z) '(1 2 3))
;(merge '((x y) z) '(1 2 3))

;;; Constructor
 ;; Pre: Given an entry of the form: ((names...)(values...))
 ;; Post: Return the entry as a binding
(define (new-binding entry)
     (let ((names (first entry))
           (values (second entry)))
               (merge names values)))

;;;; Test - Creating a Bind
;(let ((example (build '(x y z) '(1 2 3))))
;   (third (new-binding example)))


; Selectors --- Stay the same, the entries are now a list of tables
(define first-bind car) ; first == (x 1)
(define second-bind cadr) ; second == (y 2)
(define third-bind caadr) ; (z 3)


  

