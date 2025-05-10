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
              ((and (eq? (caar clauses) 'else) (not (null? (cdr clauses)))) #f) ;if it is a else clause, then it should be the last clause of the expression, if not then it should return #f 
              ((< (length (car clauses)) 2) #f) ;each clause should have a condition + result, which means the length of each clause can not be less than 2, if so, return #f
              ((and (pair? (cadr (car clauses))) (eq? (caadr (car clauses)) 'cond)) (and (cond-checker (cadr (car clauses))) (loop (cdr clauses)))) ;check for nested cond, if there is a nested cond, then it should check whether the expr is valid, if the nested cond was not valid, then it would also invalidate the main expression, if it is valid, we still have to check if the rest of the clauses are valid.
               ((and (pair? (cadr (car clauses))) (eq? (caadr (car clauses)) 'lambda)) (and (lambda-checker (cadr (car clauses))) (loop (cdr clauses))))
              (else  (loop (cdr clauses))))) ;if none of the clauses were triggered, then it should search the rest of the clauses
      #f)) ;Occur when the expression did not start with cond or the cond expression has 0 clause.

;;Test Cases

(cond-checker '(cond ((> x 0) 'pos) (else 'neg))) ;=>t
(cond-checker '(cond ((> x 0) 'pos) ((< x 0) 'neg)))   ;=>t
(cond-checker '(cond ((> x 0) 'pos) (else 'neg) ((< x 0) #t))) ;=>f
(cond-checker '(cond ((> x 0) 'pos) ((< x 0) 'neg) (else))) ;=>f
(cond-checker '(cond (else #t) ((> x 0) 'pos))) ;=>f
(cond-checker '(cond ((> x 0) 'pos) (else (if (> x y) 'greater 'smaller)))) ;=>t
(cond-checker '(cond)) ;=>f
(cond-checker '(cond ((> x 0) 'pos))) ;=>t

(cond-checker '(cond ((null? clauses) #t)
              ((not (pair? clauses)) #f)
              ((not (pair? (car clauses))) #f)
              ((and (eq? (caar clauses) 'else) (not (null? (cdr clauses)))) #f)
              ((< (length (car clauses)) 2) #f)
              (else  (loop (cdr clauses))))) ;=>t

(cond-checker '(cond ((null? clauses) #t)
              ((not (pair? clauses)) #f)
              ((not (pair? (car clauses))) #f)
              (else  (loop (cdr clauses)))
              ((and (eq? (caar clauses) 'else) (not (null? (cdr clauses)))) #f)
              ((< (length (car clauses)) 2) #f)
              )) ;=>f

(cond-checker '(cond (else #t))) ;=>t

(newline)

;nested cond test cases

(cond-checker '(cond
    ((< n 0) 'neg)
    ((= n 0) 'zero)
    (else
     (cond
       ((< n 10) 'x)
       (else 'y)
       ((< n 100) 'z)
       )))) ;=>f

(cond-checker '(cond
    ((< n 0) 'neg)
    ((= n 0) 'zero)
    (else
     (cond
       ((< n 10) 'x)
       ((< n 100) 'y)
       (else 'z)
       )))) ;=>t


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
          (else '1)))))
    (else #f))) ;=>t

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
    ((> n 10) 1)
    (else 1)
    )) ;=>t

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
        (cond ((not (pair? parameter)) #f)     ;if the paramter list is not a list, then its invalid             
              ((null? parameter) #f)           ;if the parameter is null then its not valid
              ((repeated? parameter) #f)       ;if the parameters repeated, then its not valid
              ((null? body) #f) ;if the body is null, then the expression is not valid
              ((pair? body)
               (cond ((eq? (car body) 'lambda) (lambda-checker body)) ;check for nested lambda in the body, if the nested lambda is valid, then that means the body of the original lambda expression should be valid as well, if not, then it should also invalidate the main lambda expression.
                     ((eq? (car body) 'cond) (cond-checker body))
                     (else #t)))
              (else #t))) ;if it triggered none of the above clauses, then it should return true                    
      #f)) ;Occur when the expression did not start with lambda or it does not have exactly two parts: parameters and body

;;Test Cases

(find? 1 '(2 1 3)) ;=>t
(find? 4 '(2 1 3)) ;=>f
(newline)

(repeated? '(a b c d)) ;=>f
(repeated? '(a b c a)) ;=>t
(newline)

(lambda-checker '(lambda (x y z) 1)) ;=>t
(lambda-checker '(lambda)) ;=>f
(lambda-checker '(lamda (x y z) 1)) ;=>f
(lambda-checker '(lambda (x x) 1)) ;=>f
(lambda-checker '(lambda (x y) (+ x y))) ;=>t
(lambda-checker '(lambda (x) ())) ;=>f
(lambda-checker '(lambda () ())) ;=>f
(lambda-checker '(lambda () (x))) ;=>f
(lambda-checker '(lambda (x) (x))) ;=>t
(lambda-checker '(lambda (x) (lambda (y) (cons x (cons y '())))));=>t
(lambda-checker '(lambda (x) (lambda (y y) (cons x (cons y '())))));=>f
(lambda-checker '(lambda (x) (lambda (x))));=>f
(lambda-checker '(lambda (x) (lambda (y) (lambda (z) (+ (+ x y) z))))) ;=>t
(lambda-checker '(lambda (x) (lambda (y) (lambda (z z) (+ (+ x y) z))))) ;=>f
(newline)

;define a list of primitives
(define primitives '(+ - * cons car cdr cond lambda modulo define if and or))


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
         ))
        
        

;;Top Level Function
;pre: expression
;post: return ture if the exp is a valid expression, else return #f

;Base Case: If the exp is null, then it is valid as empty list is a valid expression
;If the current element of exp is a pari, then it should check whether the pari is a lambda expression cond expression or primitives, if yes, then it should check the exp using the lambda-checker/cond-checker/primitive-length, and since we sitll need to care about the correctness of the rest of the expression, we need to also check the syntax of the rest of the expression.
;if the element if not a pari, then we should check if it is a primitive, if it is then we should check whether it has the correct length, also the correctness of the rest of the expression
;if none of the clauses above were triggered, then it should recurse into the expression and check the rest of the expression.
(define (syntax-checker exp)
  (cond ((null? exp) #t)
        ((pair? (car exp))
         (cond ((eq? (caar exp) 'lambda) (and (lambda-checker (car exp)) (syntax-checker (cdr exp))))
               ((eq? (caar exp) 'cond) (and (cond-checker (car exp)) (syntax-checker (cdr exp))))
               ((member (caar exp) primitives) (and (primitive-length (car exp)) (syntax-checker (car exp))))
               (else (and (syntax-checker (car exp)) (syntax-checker (cdr exp))))))
        ((member (car exp) primitives) (and (primitive-length exp) (syntax-checker (cdr exp))))
        (else (syntax-checker (cdr exp)))))

;Test Cases
               
(syntax-checker '(define (x) (lambda (x) (null? x))));-->t

(syntax-checker '(define x (define y (lambda (x) (lambda (y) (+ x y)))))) ;-->t

(syntax-checker '(define (pos? x) (cond ((> x 0) #t) (else #f)))) ;-->t

(syntax-checker '(define (pos? x) (cond  (else #f) ((> x 0) #t)))) ;-->f
(newline)

(syntax-checker '(define pos? (lambda (x) (cond ((> x 0) #t) (else #f))))) ;-->t

(syntax-checker '(define x (define y (lambda (x x) (null? x))))) ;-->f

(syntax-checker '(17 121 13212 (lambda (x) (null? x)))) ;-->t
