(load "Pan.Gao.Scott.1.2.scm")
;;; ====================================================
;;; TLS (The Little Schemer) Interpreter Implementation
;;; 
;;; This interpreter evaluates a subset of Scheme expressions
;;; including: constants, variables, lambdas, conditionals,
;;; and primitive operations.
;;; ====================================================

;;; ====================================================
;;; SECTION 1: HELPER FUNCTIONS
;;; ====================================================

;; Construct a pair of elements with proper list structure
;; Example: (build 'a 'b) => (a b)

;; Pre-condition: Both s1 and s2 are values to be added as elements of a pair.
;; Post-condition: A pair (cons) containing s1 as the first element and s2 as the second.
(define build
  (lambda (s1 s2)
    (cons s1 (cons s2 '()))))

;; Accessor functions for better readability
(define first car)    ;; Get first element of a list
(define second cadr)  ;; Get second element
(define third caddr)  ;; Get third element

;;; ====================================================
;;; SECTION 2: ENVIRONMENT (TABLE) OPERATIONS
;;; ====================================================

;; Environments are represented as tables (lists of entries)
;; Each entry contains two parallel lists: names and values
;; Example entry: ((x y z) (1 2 3))

;; Create a new environment entry from names and values
;; Pre-condition: The first argument is a list of names and the second is a list of corresponding values.
;; Post-condition: Returns a new environment entry, represented as a pair of names and values.
(define new-entry build)

;; Look up a name in a single environment entry
;; Parameters:
;; - name: symbol to look up
;; - entry: environment entry ((names...) (values...))
;; - entry-f: failure continuation if name not found

;; Pre-condition: The entry is a pair of two lists (names and values).
;; Post-condition: If the name is found, returns the corresponding value; otherwise, invokes entry-f.
(define lookup-in-entry
  (lambda (name entry entry-f)
    (letrec ((lookup-in-entry-help
              (lambda (names values)
                (cond
                 ((null? names) (entry-f name))  ;; Name not found - use failure handler
                 ((eq? (car names) name) (car values))  ;; Found match
                 (else (lookup-in-entry-help (cdr names) (cdr values)))))))  ;; Continue searching
      (lookup-in-entry-help (first entry) (second entry)))))  ;; Start search

;; Extend a table by adding a new entry to the front
;; Pre-condition: New entry is a valid environment entry.
;; Post-condition: Returns a new environment table with the entry added at the front.
(define extend-table cons)

;; Look up a name in an entire environment (list of entries)
;; Parameters:
;; - name: symbol to look up
;; - table: environment (list of entries)
;; - table-f: failure continuation if name not found

;; Pre-condition: table is a list of environment entries.
;; Post-condition: If the name is found in any entry, return its value; otherwise, invoke table-f.
(define lookup-in-table
  (lambda (name table table-f)
    (cond
     ((null? table) (table-f name))  ;; Name not found in any entry
     (else (lookup-in-entry name
                           (car table)  ;; Check first entry
                           (lambda (name)  ;; If not found, continue searching
                             (lookup-in-table name (cdr table) table-f)))))))

;; Default failure handler for unbound variables
;; Pre-condition: None
;; Post-condition: Raises an error if the variable is unbound.
(define initial-table
  (lambda (name)
    (error "Unbound variable:" name)))

;;; ====================================================
;;; SECTION 3: TYPE PREDICATES AND EXPRESSION CLASSIFICATION
;;; ====================================================

;; Check if a value is an atom (not a pair or null)
;; Pre-condition: x is any Scheme value.
;; Post-condition: Returns #t if x is an atom (neither pair nor null), otherwise #f.
(define atom?
  (lambda (x)
    (cond
     ((null? x) #f)   ;; Null is not an atom
     ((pair? x) #f)   ;; Pairs are not atoms
     (else #t))))     ;; Everything else is an atom

;; Check if a value is a primitive function
;; Pre-condition: l is a Scheme expression.
;; Post-condition: Returns #t if l is a primitive function, otherwise #f.
(define primitive?
  (lambda (l)
    (and (pair? l)          ;; Must be a pair
         (eq? (first l) 'primitive))))  ;; Tagged as primitive

;; Check if a value is a user-defined function (closure)
;; Pre-condition: l is a Scheme expression.
;; Post-condition: Returns #t if l is a user-defined function, otherwise #f.
(define non-primitive?
  (lambda (l)
    (and (pair? l)          ;; Must be a pair
         (eq? (first l) 'non-primitive))))  ;; Tagged as non-primitive

;; Main expression classifier - determines what kind of expression we have
;; Pre-condition: e is a Scheme expression.
;; Post-condition: Returns a corresponding action handler for the expression (atom-to-action or list-to-action).
(define expression-to-action
  (lambda (e)
    (cond
     ((atom? e) (atom-to-action e))  ;; Handle atomic expressions
     (else (list-to-action e)))))    ;; Handle list expressions

;; Classify atomic expressions (numbers, booleans, primitives, variables)
;; Pre-condition: e is an atomic expression (number, boolean, or symbol).
;; Post-condition: Returns the action corresponding to the type of the atom.
(define atom-to-action
  (lambda (e)
    (cond
     ((number? e) *const)           ;; Numbers evaluate to themselves
     ((eq? e #t) *const)            ;; Booleans evaluate to themselves
     ((eq? e #f) *const)
     ;; Primitive operations get tagged as constants
     ((eq? e 'cons) *const)
     ((eq? e 'car) *const)
     ((eq? e 'cdr) *const)
     ((eq? e 'null?) *const)
     ((eq? e 'eq?) *const)
     ((eq? e 'atom?) *const)
     ((eq? e 'zero?) *const)
     ((eq? e 'add1) *const)
     ((eq? e 'sub1) *const)
     ((eq? e 'number?) *const)
     (else *identifier))))          ;; All other atoms are treated as variables

;; Classify list expressions (special forms or function applications)
;; Pre-condition: e is a list expression.
;; Post-condition: Returns the corresponding action for a list expression (quote, lambda, cond, or application).
(define list-to-action
  (lambda (e)
    (cond
     ((atom? (car e))               ;; Check if first element is atomic
      (cond
       ((eq? (car e) 'quote) *quote)    ;; Quoted expressions
       ((eq? (car e) 'lambda) *lambda)  ;; Lambda expressions
       ((eq? (car e) 'cond) *cond)      ;; Conditional expressions
       (else *application)))            ;; Function application
     (else *application))))             ;; Nested application (e.g., ((f) x))

;;; ====================================================
;;; SECTION 4: ACTION IMPLEMENTATIONS
;;; ====================================================

;; Handle constant expressions
;; Pre-condition: e is a constant expression (number, boolean, or primitive).
;; Post-condition: Returns the constant value (unchanged).
(define *const
  (lambda (e table)
    (cond
     ((number? e) e)                ;; Numbers evaluate to themselves
     ((eq? e #t) #t)                ;; Booleans evaluate to themselves
     ((eq? e #f) #f)
     (else (build 'primitive e))))) ;; Tag primitives for later application

;; Handle quoted expressions - return the quoted part
;; Pre-condition: e is a quoted expression.
;; Post-condition: Returns the quoted part of the expression.
(define *quote
  (lambda (e table)
    (text-of e)))

;; Helper to extract the quoted text from a quote expression
;; Pre-condition: e is a quoted expression.
;; Post-condition: Returns the text following 'quote'.
(define text-of second)

;; Handle variable references - look up in environment
;; Pre-condition: e is a symbol representing a variable.
;; Post-condition: Returns the value of the variable from the environment.
(define *identifier
  (lambda (e table)
    (lookup-in-table e table initial-table)))

;; Handle lambda expressions - create closures
;; Pre-condition: e is a lambda expression.
;; Post-condition: Returns a closure representing the lambda function.
(define *lambda
  (lambda (e table)
    (build 'non-primitive           ;; Tag as user-defined function
           (cons table (cdr e)))))  ;; Store environment + (formals body)

;; Accessors for closure components
(define table-of first)       ;; Get saved environment from closure
(define formals-of second)    ;; Get formal parameters from closure
(define body-of third)        ;; Get function body from closure

;; Helper for conditionals - check if a clause is 'else'
;; Pre-condition: x is a condition in a cond clause.
;; Post-condition: Returns #t if the condition is 'else', otherwise #f.
(define else?
  (lambda (x)
    (cond
     ((atom? x) (eq? x 'else))  ;; Check if atom is 'else'
     (else #f))))

;; Accessors for cond clauses
(define question-of first)  ;; Get the question part of a cond clause
(define answer-of second)   ;; Get the answer part of a cond clause
(define cond-lines-of cdr)  ;; Get all clauses after 'cond' symbol

;; Evaluate a conditional (cond) expression
;; Pre-condition: 
;;   - `lines` is a list of cond clauses where each clause is a pair of (condition . action).
;;   - `table` is the current environment used for evaluation.
;; Post-condition:
;;   - Evaluates and returns the result of the first valid clause's action.
(define evcon
  (lambda (lines table)
    (cond
     ((null? lines) (error "No else clause in cond"))  ;; No valid clauses
     ((else? (question-of (car lines)))  ;; Found else clause
      (meaning (answer-of (car lines)) table))
     ((meaning (question-of (car lines)) table)  ;; Test condition
      (meaning (answer-of (car lines)) table))   ;; If true, evaluate answer
     (else (evcon (cdr lines) table)))))        ;; Try next clause

;; Handle cond expressions
;; Pre-condition: 
;;   - `e` is a cond expression (a list starting with 'cond' followed by clauses).
;;   - `table` is the current environment used for evaluation.
;; Post-condition:
;;   - Evaluates the cond expression and returns the result of the matched clause.
(define *cond
  (lambda (e table)
    (evcon (cond-lines-of e) table)))  ;; Skip the 'cond' symbol and process clauses

;; Evaluate a list of expressions (for function arguments)
;; Pre-condition: 
;;   - `args` is a list of arguments to be evaluated.
;;   - `table` is the current environment used for evaluation.
;; Post-condition:
;;   - Returns a list of evaluated argument values.
(define evlis
  (lambda (args table)
    (cond
     ((null? args) '())  ;; Base case: empty list
     (else (cons (meaning (car args) table)  ;; Evaluate first argument
                 (evlis (cdr args) table))))))  ;; Recursively evaluate rest

;; Accessors for application expressions
(define function-of car)     ;; Get the function part of an application
(define arguments-of cdr)    ;; Get the arguments part of an application

;; Apply primitive operations
;; Pre-condition: 
;;   - `name` is a symbol representing a primitive operation (e.g., 'cons', 'car', etc.).
;;   - `vals` is a list of evaluated arguments for the operation.
;; Post-condition:
;;   - Returns the result of applying the primitive operation to the arguments.
(define apply-primitive
  (lambda (name vals)
    (cond
     ((eq? name 'cons) (cons (first vals) (second vals))) ;; cons two items
     ((eq? name 'car) (car (first vals)))                 ;; car of first arg
     ((eq? name 'cdr) (cdr (first vals)))                 ;; cdr of first arg
     ((eq? name 'null?) (null? (first vals)))             ;; null? check
     ((eq? name 'eq?) (eq? (first vals) (second vals)))   ;; equality check
     ((eq? name 'atom?) (atom? (first vals)))             ;; atom? check
     ((eq? name 'zero?) (zero? (first vals)))             ;; zero? check
     ((eq? name 'add1) (+ (first vals) 1))                ;; increment
     ((eq? name 'sub1) (- (first vals) 1))                ;; decrement
     ((eq? name 'number?) (number? (first vals))))))      ;; number? check

;; Apply a function to evaluated arguments
;; Pre-condition: 
;;   - `fun` is a function (either primitive or closure).
;;   - `vals` is a list of evaluated arguments to be passed to the function.
;; Post-condition:
;;   - If `fun` is primitive, applies the primitive operation and returns the result.
;;   - If `fun` is a user-defined closure, applies it in the environment with the arguments and returns the result.
;;   - If `fun` is not a valid function, raises an error.
(define apply1
  (lambda (fun vals)
    (cond
     ((primitive? fun) (apply-primitive (second fun) vals))  ;; Handle primitives
     ((non-primitive? fun) (apply-closure (second fun) vals)) ;; Handle closures
     (else (error "Not a function:" fun)))))

;; Apply user-defined functions (closures)
;; Pre-condition:
;;   - `closure` is a closure (a function with an environment).
;;   - `vals` is a list of evaluated arguments for the closure.
;; Post-condition:
;;   - Applies the closure to the given arguments and returns the result.
(define apply-closure
  (lambda (closure vals)
    (meaning (body-of closure)  ;; Evaluate the body
             (extend-table (new-entry (formals-of closure) vals)  ;; Extend env with args
                          (table-of closure)))))  ;; Use closure's saved environment

;; Handle function applications
;; Pre-condition: 
;;   - `e` is a function application expression (e.g., (f arg1 arg2)).
;;   - `table` is the current environment used for evaluation.
;; Post-condition:
;;   - Evaluates the application expression and returns the result.
(define *application
  (lambda (e table)
    (apply1 (meaning (function-of e) table)  ;; Evaluate the function
           (evlis (arguments-of e) table)))) ;; Evaluate all arguments

;;; ====================================================
;;; SECTION 5: TOP-LEVEL EVALUATION FUNCTIONS
;;; ====================================================

;; Core evaluation function - dispatches to appropriate action
;; Pre-condition: e is any Scheme expression.
;; Post-condition: Returns the evaluated result of the expression.
(define meaning
  (lambda (e table)
    ((expression-to-action e) e table)))

;; Top-level evaluation function - starts with empty environment
;; Pre-condition: e is a Scheme expression.
;; Post-condition: Check whether the expression is valid, if yes returns the evaluated result of the expression using an initial empty environment, if no, return error message.
(define value
  (lambda (e)
    (if (simple-check e) (meaning e '()) "Error")))

;;; ====================================================
;;; SECTION 6: TEST CASES
;;; ====================================================

;; 1. Quoting and List Manipulation
(value '(cdr (quote (a b c d))))       ; => (b c d)
(value '(cons 'x (quote (y z))))       ; => (x y z)
(value '(car (cdr (quote (a b c d))))) ; => b
(newline)


;; 2. Basic Arithmetic with add1/sub1
(value '(add1 (add1 3)))        ; => 5
(value '(sub1 (sub1 3)))        ; => 1
(value '(add1 (sub1 (add1 0)))) ; => 1
(newline)

;; 3. Boolean and Type Predicates
(value '(null? (quote ())))    ; => #t
(value '(atom? 'a))            ; => #t
(value '(atom? (quote (a b)))) ; => #f
(value '(number? 42))          ; => #t
(value '(eq? 'a 'a))           ; => #t
(value '(eq? 'a 'b))           ; => #f
(newline)

;; 4. Conditionals with cond
(value '(cond (#f 'nope) ((null? (quote ())) 'yes)))   ; => yes
(value '(cond ((eq? 'x 'y) 'fail) (else 'ok)))         ; => ok
(value '(cond ((number? 'x) 'fail) ((atom? 'x) 'win))) ; => win
(newline)

;; 5. Lambda and Closures
;; Identity function
(value '((lambda (x) x) 'hello)) ; => hello
(newline)
;; Function returns a pair of its argument with itself
(value '((lambda (x) (cons x (cons x '()))) 'foo)) ; => (foo foo)
(newline)
;; Function with arithmetic
(value '((lambda (x) (add1 x)) 9)) ; => 10
(newline)
;; Function using sub1 and cons
(value '((lambda (n) (cons n (cons (sub1 n) '()))) 5)) ; => (5 4)
(newline)

;; 6. Nested Lambdas (Lexical Scope Demonstration)
;; Curried function: returns a function that adds 1 to its argument
(value '(((lambda (x) (lambda (y) (cons x (cons y '())))) 'a) 'b)) ; => (a b)
(newline)

;; 7. Function Returning a Constant
(value '((lambda (x) 'whatever) 42)) ; => whatever
(newline)

;; 8. Functions and cond
;; A function that checks if its argument is zero and returns accordingly
(value '((lambda (x) (cond ((zero? x) 'zero) (else 'nonzero))) 0)) ; => zero
(value '((lambda (x) (cond ((zero? x) 'zero) (else 'nonzero))) 5)) ; => nonzero
(newline)

;;Test for invalid expression
(value '((lambda (x) (cond ((zero? x 1) 'zero) (else 'nonzero))) 0));->Error
(value '(cond (else 'ok) ((eq? 'x 'y) 'fail)));->Error
(value '(cons 1 2 3));->Error
(value 0+1i)
(value '(+ 1 0+1i));->Error



