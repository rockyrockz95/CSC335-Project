(load "1.1.rkt")

;;Top Level Function
;pre: expression
;post: return ture if the exp is a valid expression, else return #f

;Base Case: If the exp is null, then it is valid as empty list is a valid expression
;If the current element of exp is a pari, then it should check whether the pari is a lambda expression cond expression or primitives, if yes, then it should check the exp using the lambda-checker/cond-checker/primitive-length, and since we sitll need to care about the correctness of the rest of the expression, we need to also check the syntax of the rest of the expression.
;if the element if not a pari, then we should check if it is a primitive, if it is then we should check whether it has the correct length, also the correctness of the rest of the expression
;if none of the clauses above were triggered, then it should recurse into the expression and check the rest of the expression.

(define (simple-check exp)
  (cond ((null? exp) #t)
        ((atom? exp)
          (or (rational? exp) (symbol? exp)))
        ((pair? exp) (syntax-checker exp '())) ; empty env to add closure records -- placeholder now
        ))

; added env to deep search
  ; lambda creates closures + extends table
  ; cond should not unless lambda is nested within
  ; free-var check should have access to entries and their values
(define (syntax-checker exp env)
  (cond ((null? exp) #t)
        ((pair? (car exp))
         (cond ((eq? (caar exp) 'lambda) (and (lambda-checker (car exp)) (syntax-checker (cdr exp) (extend-table (cadr (car exp)) env)))) ;if the current subexpression is a lambda expression, then it should call lambda expression, and check the rest of the expression.
               ((eq? (caar exp) 'cond) (and (cond-checker (car exp)) (syntax-checker (cdr exp) env)))
               ((member (caar exp) primitives) (and (primitive-length (car exp)) (syntax-checker (car exp) env)))
               (else (and (syntax-checker (car exp) env) (syntax-checker (cdr exp) env)))))
        ((eq? (car exp) 'lambda) (and (lambda-checker exp) (syntax-checker (cdr exp) env)))
        ((eq? (car exp) 'cond) (and (cond-checker exp) (syntax-checker (cdr exp) env)))
        ((member (car exp) primitives) (and (primitive-length exp) (syntax-checker (cdr exp) env)))
        (else (syntax-checker (cdr exp) env))))

;define a list of primitives
(define primitives '(+ - * cons car cdr cond lambda modulo define if and or > < = eq? null? zero?))


;pre: expression
;post: return true if the primitive matches its length, else return false
(define (primitive-length exp)
  (cond ((eq? (car exp) '+) (eq? (length exp) 3))
        ((eq? (car exp) '-) (eq? (length exp) 3))
        ((eq? (car exp) '*) (eq? (length exp) 3))
        ((eq? (car exp) 'cons) (eq? (length exp) 3))
        ((eq? (car exp) 'lambda) (eq? (length exp) 3))
        ((eq? (car exp) 'modulo) (eq? (length exp) 3))
        ((eq? (car exp) 'define) (eq? (length exp) 3))
        ((eq? (car exp) 'if) (eq? (length exp) 4))
         ((eq? (car exp) 'and) (eq? (length exp) 3))
         ((eq? (car exp) 'or) (eq? (length exp) 3))
         ((eq? (car exp) 'cond) (> (length exp) 0))
         ((eq? (car exp) '>) (eq? (length exp) 3))
         ((eq? (car exp) '<) (eq? (length exp) 3))
         ((eq? (car exp) '=) (eq? (length exp) 3))
         ((eq? (car exp) 'eq?) (eq? (length exp) 3))
          ((eq? (car exp) 'null?) (eq? (length exp) 2))
          ((eq? (car exp) 'zero?) (eq? (length exp) 2))
         ))


;;Cond syntax checker
;;expr: the expression that we are checking whether it is a valid cond expression or not

;;Pre: Expression
;;Post: Return #t if the expression is a valid cond expression, else #f

(define (cond-checker expr)
  (if (and (eq? (car expr) 'cond) (not (null? (cdr expr)))) ;Check whether the expression is a cond expression and if it has at least 1 clause
      (let loop ((clauses (cdr expr))) ;declare a recursive loop and extract the clauses
        (cond ((null? clauses) #t)     ;if the function was able to get to the end of the expressio without trigger any condition, then it should return #t
              ((not (pair? clauses)) #f) ;if the clauses are nor pair then it is invalid expression, hence return #f
              ((not (pair? (car clauses))) #f) ;each clause should be a pair, if not, then  the expression is invalid, hence return #f
              ((eq? (caar clauses) 'else)
               (cond ((not (null? (cdr clauses))) #f) ;if it is a else clause, then it should be the last clause of the expression, if not then it should return #f,
                     (else (simple-check (cdr (car clauses)))))) ;syntax check the result statement of else clause
              ((atom? (caar clauses)) #f) ;predicate cannot be an atom, if it is an atom, then return #f
              ((pair? (caar clauses)) (if (member (caaar clauses) primitives) (and (and (simple-check (caar clauses)) (simple-check (cdr (car clauses)))) (loop (cdr clauses))) #f)) 
              ((< (length (car clauses)) 2) #f) ;each clause should have a condition + result, which means the length of each clause can not be less than 2, if so, return #f
              ;((pair? (cadr (car clauses))) (and (syntax-checker (cadr (car clauses))) (loop (cdr clauses)))) ;
              (else  (loop (cdr clauses))))) ;if none of the clauses were triggered, then it should search the rest of the clauses
      #f)) ;Occur when the expression did not start with cond or the cond expression has 0 clause.


;;Test Cases
(cond-checker '(cond ((> x y) 'pos) (else 'neg))) ;=>t
(cond-checker '(cond ((> x 0) 'pos) ((< x 0) 'neg)))   ;=>t
(cond-checker '(cond ((> x 0) 'pos) (else 'neg) ((< x 0) #t))) ;=>f
(cond-checker '(cond ((> x 0) 'pos) ((< x 0 1) 'neg) (else #t))) ;=>f
(cond-checker '(cond (else #t) ((> x 0) 'pos))) ;=>f

(newline)

;nested cond test cases


(cond-checker '(cond
    ((< n 0) 'neg)
    ((= n 0)
     (cond
       ((< n 10) 'x)
       ((< n 100) 'y)
       (else 'z)))    
    (else #f))) ;=>t

(cond-checker '(cond
    ((< n 0) 'neg)
    ((= n 0)
     (cond
       ((< n 10) 'x)
       ((< n 100) 'y)
       (else
        (cond
          ((< n 10) 'x)
          ((< n 100) 'y)
          (else '1)
          ))))
    (else #f)
    ((> n 10) 1))) ;=>f



(newline)


;;Helper function that help to find if an element exist in a list or not
;;Used to help with the function repeated? to see if a list contains duplicate elements
;;Target: Elements that we want to find
;;set: the list that we are searching

(define (find? target set)             
  (cond ((null? set) #f) ;Base case: if the list is null, then it should return #f
        ((eq? (car set) target) #t) ;If at any point, the current element is equal to the target value, then it should return #t
        (else (find? target (cdr set))))) ;If not, then it should search through the next element

;;Helper function that help to determine whether a list contains duplicated element, in this case we need to determine whether the parameters are duplicated in the lambda expression
;;set: the list we are searching through

(define (repeated? set)                 
  (cond ((null? (cdr set)) #f) ;Base case: if the current element is the last element then it should return #f as it is the only element in the list, hence can not be repeated
        ((find? (car set) (cdr set)) #t) ;If at any point, the current element is found again in the rest of the list, then that means the elements was repeated, hence return #t
        (else (repeated? (cdr set))))) ;If not, then it should search the rest of the list
    
;;Pre: Expression
;;Post; Return #t if the expresion pass the checker, else #f
(define (lambda-checker expr)
  (if (and (eq? (car expr) 'lambda) (eq? (length (cdr expr)) 2)) ;check whether the expression starts with lambda if no, then its not lambda. If yes, then it should contains a parameter list and a body
      (let ((parameter (cadr expr))      ;extract the parameter list
            (body (caddr expr)))         ;extract the body 
        (cond ((atom? parameter) #f)     ;if the paramter list is an atom, then its invalid
              ((and (pair? parameter) (repeated? parameter)) #f)       ;if the parameters repeated, then its not valid
              ((null? body) #f) ;if the body is null, then the expression is not valid
              ((pair? body) (simple-check body)) ;if the body is a pair, the syntax check the body
              (else #t))) ;if it triggered none of the above clauses, then it should return true                    
      #f)) ;Occur when the expression did not start with lambda or it does not have exactly two parts: parameters and body

;;Test Cases

(find? 1 '(2 1 3)) ;=>t
(find? 4 '(2 1 3)) ;=>f
(newline)

(repeated? '(a b c d)) ;=>f
(repeated? '(a b c a)) ;=>t
(newline)


(lambda-checker '(lambda () ())) ;=>f
(lambda-checker '(lambda () (x))) ;=>t
(lambda-checker '(lambda (x) (lambda (y) (cons x (cons y '()) 1))));=>f
(lambda-checker '(lambda (x) (lambda (y) (cons x (cons y '())))));=>f
(lambda-checker '(lambda (x) (lambda (x))));=>f
(lambda-checker '(lambda (x) (lambda (y) (lambda (z) (+ (+ x y) z))))) ;=>t
(newline)

;;Test Cases
               
(simple-check '(define pos? (lambda (x) (cond ((> x 0) #t) (else #f))))) ;-->t

(simple-check '(define x (define y (lambda (x x) (null? x))))) ;-->f

(simple-check '(17 121 13212 (lambda (x) (null? x)))) ;-->t

(simple-check '(12)) ;->t

(simple-check '(cond ((> x 0) (+ 1 2 3))));->f

(simple-check '(define (pos? x) (cond ((> x 0) #t) (else #f)))) ;-->t

(simple-check +01i) ;->f

(simple-check '(cond ((> x 0) (lambda (x) (+ x 1))) ((< x 0) (lambda (x) (- x 1))) (else (+ 2 3 3)))) ;->f


#| ==========================================================================================
   Second Half
    (ii) Primitive arity checker -- How is this different than primitive-length?
    (iii) Free variable count
   ==========================================================================================
|#

;; Pre: Given an expression, expr
;; Post: return a bool - #t if unbound var is found, #f if not
(define (unbound-var? expr env)
  (cond ((number? expr) #f) ; literals and bool vals are not bound
        (else (not (null? (free-vars expr env))))))

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

; Changing to 2D env --> ((names) (vals))s
(define (free-vars expr env)
      (cond
         ; if the var is in the expr, add to the list of free vars
        ((and (symbol? expr) (not (element-lst? expr primitives)))
         (if (element-lst? expr env) '() (list expr)))
        
         ; parameters check: free vars occur in the body and not captured in param list
        ((and (pair? expr) (eq? (car expr) 'lambda))
           (let ((parameters (cadr expr))
                 (body (caddr expr)))
             (free-vars body (append parameters env))))
                            
         ; check each clause for an unbound var
        ((and (pair? expr) (eq? (car expr) 'cond))
         (cond-free expr env))
        
        ;; (*application (func args-list)) -- search all the args
        ((list? expr)
         (app-free expr env))
        
         (else '())))

; Pre: Given a cond expression, expr, and list of currently free variables, var 
; Post: Output all the free vars in the clauses of cond
(define (cond-free expr env)
    (let loop ((clauses (cdr expr)))
      (cond ((null? clauses) env)
            (else (free-vars clauses env)))))

; Pre: Given an application
; Post: Output all the free vars in the functions in the application
(define (app-free expr env)
  (let loop ((args (cdr expr))
             ; retrieving function variables
             (arg-vars (free-vars (car expr) env)))
    (cond ((null? args) arg-vars)
           (else (loop (cdr args)
            (union-lst arg-vars (free-vars (car args) env)))))))


;(syntax-checker '(lambda (x) x) '()) ; #f
;(syntax-checker '(lambda (x) y) '()) ; #t
;(syntax-checker '(lambda (x) (+ x x)) '()) ; #f
