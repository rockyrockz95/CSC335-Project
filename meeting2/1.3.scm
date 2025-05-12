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


;===========================================================================================
#|
 Environment Specification for TLS:
  ;; TLS' environment subsystem manages the ((name)(value)) pair entries that makeup the environment.
     
  ;; The primary operations that handle environment management are:
         - new-entry:
             * Pre-condition: The first argument is a list of names and the second is a list of corresponding values.
             * Post-condition: Returns a new environment entry, represented as a pair of names and values.
         - lookup-in-entry
             * Pre-condition: The entry is a pair of two lists (names and values).
             * Post-condition: If the name is found, returns the corresponding value; otherwise, invokes entry-f.
         - extend-table
             * Pre-condition: New entry is a valid environment entry.
             * Post-condition: Returns a new environment table with the entry added at the front.
         - lookup-in-table
             * Pre-condition: table is a list of environment entries.
             * Post-condition: If the name is found in any entry, return its value; otherwise, invoke table-f.

  ;; In tandem, these functions are used to build and maintain a stack of environment entries (bindings).

  ;; Interpreter property:
      - Lexical Scoping: In the environment level*, maintained by extend-table.
         * As opposed to the underlying R5RS
  
  ;; Environment properties:
      - Env structure: A nested list
      - Entry structure: "An entry is a pair of lists whose first list is a set. Also,
          the lists must be of equal length."
                     
|#
;======================================================================================



#| ======================================================================================
   Part 2: Change the representation of the env and show that the representation satisfies the spec
     and works with the rest of the interpreter
       Claim: The environment subsytem of TLS is structured in a way that allows it to act as
         an abstract data type. Therefore, an a-list structure for the env still satisfies
         the specifications stated before.

       ; Assume that the input is already in a-list form: ((name value) (name2 value2) ....)

   ============================================================================================
|# 


  

