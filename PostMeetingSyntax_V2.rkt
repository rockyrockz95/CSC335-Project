;;Helper Function
;;Pre: a datum x
;;Post: Return #t if x is an atom, else #f

(define atom?
  (lambda (x)
    (cond
     ((null? x) #f)  
     ((pair? x) #f)   
     (else #t))))  

;Test Case
(atom? 1);->t
(atom? '(1));->f
(newline)

;;Top Level Function

;pre: expression
;post: return ture if the exp is a valid expression, else return #f

;;Wrapper function
;;Check whether the exp is an atom, if it is, then it needs to be a rational number, or symbol, or a boolean. If it is none of the above, then it should return #f
;;If the exp is a pair, then it should call the syntax-checker to check the expression exp.

(define (simple-check exp)
  (cond ((null? exp) #t)
        ((atom? exp)
          (or (or (rational? exp) (symbol? exp)) (boolean? exp)))
        ((pair? exp) (syntax-checker exp))
        ))

;pre: expression
;post: return ture if the exp is a valid expression, else return #f

;Base Case: If the exp is null, then it is valid as empty list is a valid expression
;If the current element of exp is a pair, then it should check whether the pair is a lambda expression cond expression or primitives, if yes, then it should check the exp using the lambda-checker/cond-checker/primitive-length, and since we sitll need to care about the correctness of the rest of the expression, we need to also check the syntax of the rest of the expression.
;if the element if not a pair, then we should check if it is a lambda/cond/primitives, if it is then we should check the correctness of the expression, also the correctness of the rest of the expression
;if none of the clauses above were triggered, then it should recurse into the expression and check the rest of the expression.

(define (syntax-checker exp)
  (cond ((null? exp) #t)
        ((pair? (car exp))
         (cond ((eq? (caar exp) 'lambda) (and (lambda-checker (car exp)) (simple-check (cdr exp))))
               ((eq? (caar exp) 'cond) (and (cond-checker (car exp)) (simple-check (cdr exp))))
               ((member (caar exp) primitives) (and (and (primitive-length (car exp)) (simple-check (car exp))) (simple-check (cdr exp))))
               (else (and (simple-check (car exp)) (simple-check (cdr exp))))))
        ((eq? (car exp) 'lambda) (and (lambda-checker exp) (simple-check (cdr exp))))
        ((eq? (car exp) 'cond) (and (cond-checker exp) (simple-check (cdr exp))))
        ((member (car exp) primitives) (and (primitive-length exp) (simple-check (cdr exp))))
        (else (and (simple-check (car exp)) (simple-check (cdr exp))))))

;define a list of primitives
(define primitives '(+ - * cons car cdr cond lambda modulo define if and or > < = eq? null? zero? / quotient number? symbol? rational? boolean?))
  

;pre: expression
;post: return true if the primitive matches its length, else return false
(define (primitive-length exp)
  (cond ((eq? (car exp) '+) (eq? (length exp) 3))
        ((eq? (car exp) '-) (eq? (length exp) 3))
        ((eq? (car exp) '*) (eq? (length exp) 3))
        ((eq? (car exp) '/) (eq? (length exp) 3))
        ((eq? (car exp) 'quotient) (eq? (length exp) 3))
        ((eq? (car exp) 'cons) (eq? (length exp) 3))
        ((eq? (car exp) 'car) (eq? (length exp) 2))
        ((eq? (car exp) 'cdr) (eq? (length exp) 2))
        ((eq? (car exp) 'number?) (eq? (length exp) 2))
        ((eq? (car exp) 'symbol?)(eq? (length exp) 2))
        ((eq? (car exp) 'rational?) (eq? (length exp) 2))
        ((eq? (car exp) 'boolean?) (eq? (length exp) 2))
        ((eq? (car exp) 'lambda) (eq? (length exp) 3))
        ((eq? (car exp) 'modulo) (eq? (length exp) 3))
        ((eq? (car exp) 'define)
         (cond ((atom? (cadr exp)) (eq? (length exp) 3))
               ((pair? (cadr exp)) (>= (length exp) 3))
               (else #f)))
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

;;Test Case:
(primitive-length '(cons 1 2));->t
(primitive-length '(cons 1 2 3));->f
(primitive-length '(define x (lambda (x) (+ x 1))));->t
(primitive-length '(define x (lambda (x) (+ x 1)) (lambda (y) (+ y 1))));->f
(primitive-length '(define (x) (define y (lambda (x) (+ x 1))) y));->t
(primitive-length '(define (x)));->f

(newline)

;;Cond syntax checker
;;expr: the expression that we are checking whether it is a valid cond expression or not

;;Pre: Expression
;;Post: Return #t if the expression is a valid cond expression, else #f

;;For a cond expression, the expression needs to start with cond and have at least 1 clause. If it is then it should recurse into the clauses and check all the clauses, if it is not, then it should return #f
;;Since we already check whether the cond expression has at least 1 clause at the beginning, when recurse into the clauses, if the clauses is null, then that means we have gone through all clauses without flagging #f, hence return #t
;;Clauses need to be a pair, if not then return #f
;;Each clause needs to be a pair, if not then return #f
;;If it is a else-clause, then it should be the last clause of the expression, if not return #f. If it is the last clause, then we should syntax-check the result statement of the else clause.
;;if the predicate statement of the clause is a atom, then it needs to be a boolean, else return #f
;;result statement of each clause needs to be the last element of a clause, if not then it should return #f
;;if the predicate statement is a pair, then it should syntax check the predicate, result statement and the rest of the clauses. If any of them return false, then the expression should be invalid.
;;each clause should have a predicate + result, which means the length of each clause can not be less than 2, if so, return #f
;;if none of the above were triggered, then it should recurse into the rest of the expression and check whether it is valid.

(define (cond-checker expr)
  (if (and (eq? (car expr) 'cond) (not (null? (cdr expr))))
      (let loop ((clauses (cdr expr))) ;declare a recursive loop and extract the clauses
        (cond ((null? clauses) #t)     
              ((not (pair? clauses)) #f) 
              ((not (pair? (car clauses))) #f) 
              ((eq? (caar clauses) 'else)
               (cond ((not (null? (cdr clauses))) #f)
                     (else (simple-check (cdr (car clauses)))))) 
              ((and (atom? (caar clauses)) (not (boolean? (caar clauses)))) #f) 
              ((not (null? (cddr (car clauses)))) #f) 
              ((pair? (caar clauses)) (and (and (simple-check (caar clauses)) (simple-check (cdr (car clauses)))) (loop (cdr clauses))))
              ((< (length (car clauses)) 2) #f)
              (else  (loop (cdr clauses))))) 
      #f)) 


;;Test Cases
(cond-checker '(cond ((> x y) 'pos) (else 'neg))) ;=>t
(cond-checker '(cond (else #t) ((> x 0) 'pos))) ;=>f
(cond-checker '(cond ((> x 0) 'pos) ((< x 0) 'neg) (else #t))) ;=>t
(cond-checker '(cond ((> x 0) 'pos) ((< x 0 1) 'neg) (else #t))) ;=>f

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
       (else 'z)))    
    (else (+ 1 2 3)))) ;=>f


(newline)


;;Helper function that help to find if an element exist in a list or not
;;Used to help with the function repeated? to see if a list contains duplicate elements
;;Target: Elements that we want to find
;;set: the list that we are searching

;;Base case: if the list is null, then it should return #f
;;If at any point, the current element is equal to the target value, then it should return #t
;If not, then it should search through the next element

(define (find? target set)             
  (cond ((null? set) #f)
        ((eq? (car set) target) #t) 
        (else (find? target (cdr set))))) 

;;Helper function that help to determine whether a list contains duplicated element, in this case we need to determine whether the parameters are duplicated in the lambda expression
;;set: the list we are searching through

;Pre: A list x
;Post: return true if elements in the list x repeated, else return #f

;;Base case: if the current element is the last element then it should return #f as it is the only element in the list, hence can not be repeated
;If at any point, the current element is found again in the rest of the list, then that means the elements was repeated, hence return #t
;If not, then it should search the rest of the list

(define (repeated? set)                 
  (cond ((null? (cdr set)) #f)
        ((find? (car set) (cdr set)) #t) 
        (else (repeated? (cdr set))))) 
    
;;Pre: Expression
;;Post; Return #t if the expresion pass the checker, else #f

;;For a valid lambda expression it needs to start with lambda and with a length of 3.So we need to check whether the expression starts with lambda if no, then its not lambda.
;;Parameters of lambda cannot be atom, it has to be a pair, so if the parameter of the expression is atom, then it should return #f
;;Parameters of lambda expression cannot repeated, it if repeated then the expression is not valid
;;the body of the lambda expression needs to have something,if not, then it should return #f
;;if the body of the lambda expression is a pair, then it should syntax check the body
;;if none of the clauses were triggered, then it should return #t

(define (lambda-checker expr)
  (if (and (eq? (car expr) 'lambda) (eq? (length (cdr expr)) 2)) 
      (let ((parameter (cadr expr))      ;extract the parameter list
            (body (caddr expr)))         ;extract the body 
        (cond ((atom? parameter) #f)     
              ((and (pair? parameter) (repeated? parameter)) #f)     
              ((null? body) #f)
              ((pair? body) (simple-check body)) 
              (else #t)))                    
      #f)) 

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
(lambda-checker '(lambda (x) (lambda (y) (cons x (cons y '())))));=>t
(lambda-checker '(lambda (x) (lambda (x))));=>f
(lambda-checker '(lambda (x) (lambda (y) (lambda (z) (+ (+ x y) z))))) ;=>t
(lambda-checker '(lambda (x) (lambda (y) (lambda (z) (+ (+ x y) z 1))))) ;=>f
(newline)

(syntax-checker '(17 121 13123132 (lambda (x) (zero? x))));->t
(syntax-checker '(17 121 13123132 (lambda (x) (zero? x 1))));->f

(syntax-checker '(define (find? target set)             
  (cond ((null? set) #f)
        ((eq? (car set) target) #t) 
        (else (find? target (cdr set))))));->t

(syntax-checker '(define (find? target set)             
  (cond ((null? set) #f)
        ((eq? (car set) target) #t) 
        (else (find? target (cdr set 1))))));->f

(newline)

(simple-check 12);->t
(simple-check #t);->t
(simple-check 'x);->t
(simple-check 0+1i);->f

(newline)


(simple-check '(define (module x)
                 (define (add m n) (cond ((zero? m) n) (else (+ 1 (add (- m 1) n)))))
                 (define (mul m n) (cond ((zero? m) 0) (else (add n (add (- m 1) n)))))

                 (cond ((eq? x add) add)
                       ((eq? x mul) mul))));->t

(simple-check '(define (module x)
                 (define (add m n) (cond ((zero? m) n) (else (+ 1 (add (- m 1) n)))))
                 (define (mul m n) (cond ((zero? m) 0) (else (add n (add (- m 1) n)))))

                 (cond ((eq? x add) add)
                       ((eq? x mul) mul 1))));->f

(simple-check '(define (module x)
                 (define (add m n) (cond ((zero? m) n) (else (+ 1 (add (- m 1) n)))))
                 (define (mul m n) (cond ((zero? m) 0) (else (add n (add (- m 1) n)))))
                 (define (sub m n) (cond ((zero? n) m) (else (- (sub m (- n 1)) 1))))

                 (cond ((eq? x add) add)
                       ((eq? x mul) mul)
                       ((eq? x sub) sub))));->t

(simple-check '(define (module x)
                 (define (add m n) (cond ((zero? m) n) (else (+ 1 (add (- m 1) n)))))
                 (define (mul m n) (cond ((zero? m) 0) (else (add n (add (- m 1) n)))))
                 (define (sub m n) (cond ((zero? n) m) (else (- (sub m (- n 1 1)) 1))))

                 (cond ((eq? x add) add)
                       ((eq? x mul) mul)
                       ((eq? x sub) sub))));->f

(newline)

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

(element-lst? 2 '(1 2 3));->t
(element-lst? 4 '(1 2 3));->f

; Pre: Given 2 lists
; Post: Return the union set of both lists
(define (union-lst lst1 lst2)
  (cond ((null? lst1) lst2)
        ((element-lst? (car lst1) lst2) (union-lst (cdr lst1) lst2))
        (else (cons (car lst1) (union-lst (cdr lst1) lst2)))))

(union-lst '(1 2 3) '(2 3 4));->(1 2 3 4)
(union-lst '(1 2 3) '(4 5 6));->(1 2 3 4 5 6)

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
