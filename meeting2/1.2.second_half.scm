(load "1.1.rkt")
(load "1.2-Syntax-Checker_V2.rkt")
; 1.2 Second half

;;; TLS interpreter: The least set containing Scheme integers, bools, primitives, and identifiers
  ;;; closed (so far) under cond, lambda, quote, application

;; Simple checker -- function to catch non-TLS sexp
 ;   rational numbers, boolean vals, procedures, and improperly constructed fine structures
 ;  sexp Qs - null?, (atom? (car 1)), else

; Pre: Given an expression
; Post: Determine if the expression is a valid s-exp for input
(define (simple-check exp) ; check for sexp
  (cond ((null? exp) #f)
        ((or (rational? exp) (boolean? exp)) #f)
        ((atom? exp) #t)
        (else (simple-check (car exp)))))

;;; Test Cases
;(simple-check 17/18)
;(simple-check '(17 cond 18 lambda x))
;(simple-check '(define (x) (lambda (x) (null? x))))


;;; Idea: Current implementation of the has primitives: const values != user closures
  ;;; Included primitives are {cons, car, cdr, .....}
  ;;; If the entered function is a primitive ---> it should have assigned # of parameter values

;;; pre: Given a sexp (atom or list of Scheme exprs)
;;; post: If sexp is a primitive, return whether or not the correct number of args were given
     ;; if not, throw a syntax error
;;;; Hardcoded expected param number to primitives -- Not abstract enough
(define (param-check-help name)      
    (cond ((eq? name 'cons) 2)
          ((eq? name 'eq?) 2)
          ((eq? name 'car) 1)
          ((eq? name 'cdr) 1)
          ((eq? name 'null?) 1)
          ((eq? name 'atom?) 1)
          ((eq? name 'zero?) 1)
          ((eq? name 'add1) 1)
          ((eq? name 'sub1) 1)
          ((eq? name 'number?) 1)
  (else (error "Syntax Error: Invalid number of args for:" name))))

;; primitives: ('primitive', 'op rand1 rand2') -- ignoring tags for now
(define (param-check expr)
  (let ((name (car expr))
         (args (cdr expr)))
         ; assuming higher level syntax checker does primitive check
      (= (length args) (param-check-help name))))

;;;; Test cases
;(param-check (list 'cons 1 2)) ;#t
;(param-check (list 'cons 1))  ; #f
;
;(param-check (list 'zero?))  ; #f
;(param-check (list 'zero? 0))  ; #t


; 1.2.iv -- Detect unbound vars
;;; unbound var - a var not bound in the env (fail case captured by lookup-in-entry --> initial-table)
 ;;   a single var OR a var not captured by a lambda expr & other operations
                                       
;; Pre: Given an expression, expr
;; Post: return a bool - #t if unbound var is found, #f if not
(define (unbound-var? expr)
  (cond ((number? expr) #f) ; literals and bool vals are not bound
        (else (not (null? (free-vars expr '()))))))

;;; Helpers for finding free vars

; Pre: Given an element and a list of elements
; Post: Return a bool, #t - if element is found in lst, #f if not
(define (element-lst? element lst)
  (cond ((null? lst) #f)
        ((equal? (car lst) element))
         (else (element-lst? element (cdr lst)))))

; Pre: Given 2 lists
; Post: Return the union set of both lists
(define (union-lst lst1 lst2)
  (cond ((null? lst1) lst2)
        ((element-lst? (car lst1) lst2) (union-lst (cdr lst1) lst2))
        (else (cons (car lst1) (union-lst (cdr lst1) lst2)))))

; (union-lst '(1 2 3) '(2 3 4 5))

;(element-lst? 1 '(1425 5651644 2 685)) ; #f
;(element-lst? 1 '(2 3 4 5 1 8)) ; #t

#|
 pre: Given an epression, expr and a list of free vars (init == '())
 post: Return the list of free vars in the expr
 DI: Since TLS is closed under cond, lambda, quote and app, look for free vars in those ops
    - quote takes a literal and returns a quoted ver --> no ndeed to search for unbound vars
    - lambda: a var is unbound when it is not captured by the parameter or bound in the body
    - (cond <clause1> <clause2>....): each clause may contain an unbound var
    - application: a var is unbound when it is unbound in the function and its args
|#

(define (free-vars expr vars)
      (cond
         ; if the var is in the expr, add to the list of free vars
        ((and (symbol? expr) (not (element-lst? expr primitives)))
         (if (element-lst? expr vars) '() (list expr)))
        
         ; parameters check: free vars occur in the body and not captured in param list
        ((and (pair? expr) (eq? (car expr) 'lambda))
           (let ((parameters (cadr expr))
                 (body (caddr expr)))
             (free-vars body (append parameters vars))))
                            
         ; check each clause for an unbound var
        ((and (pair? expr) (eq? (car expr) 'cond))
         (cond-free expr vars))
        
        ;; (*application (func args-list)) -- search the function and each arg
        ((list? expr)
         (app-free expr vars))
        
         (else '())))

; Pre: Given a cond expression, expr, and list of currently free variables, var 
; Post: Output all the free vars in the clauses of cond
(define (cond-free expr vars)
    (let loop ((clauses (cdr expr)))
      (cond ((null? clauses) vars)
            (else (free-vars clauses vars)))))

; Pre: Given an application
; Post: Output all the free vars in the functions in the application
(define (app-free expr vars)
  (let loop ((args (cdr expr))
             ; retrieving function variables
             (arg-vars (free-vars (car expr) vars)))
    (cond ((null? args) arg-vars)
             ; retrieve each of the args' free vars
        (else (loop (cdr args)
         (union-lst arg-vars (free-vars (car args) vars)))))))

;;; Test Cases
;(unbound-var? '(lambda (x) x)) ; #f
;(unbound-var? '(lambda (x) y)) ; #t
;(unbound-var? '(lambda (x) (+ x x))) ; #f
;(unbound-var? '(cond ((> x 0) 'pos) (else 'neg))) ; no outer context


;(unbound-var? (not #t)) ; ()
;(unbound-var? 124525) ; ()
;(unbound-var? 'x) ; #t
;(unbound-var? '(lambda (x) (+ x y))) ; #t
;(unbound-var? '(cond ((> 1 2) #t)
;                     (else #f))) ; --> issue with cond statements -- returns #t
;(unbound-var? '(cond ((> 1 2) x) (else y)))     ; ⇒ #t (x, y unbound)

;(define (myfunc-unbound)
;  (lambda (x) (+ x y)))
;(free-vars '(define (myfunc-unbound)
;  (lambda (x) (+ x y))) '()) ; Expected: y, Actual: (myfunc-unbound y) -- function names not being interpreted as symbols


           