#|

Team: LingJie Pan, Xin Gao, Joquanna Scott
1.1 

Walkthrough of TLS Interpreter This document walks through the TLS (The Little Schemer) interpreter implementation. It breaks down each section and explains what each function does.

SECTION 1: HELPER FUNCTIONS 
● build: Creates a two-element list. Used to create environment entries or closures. 
● first, second, third: Simple accessors for the first, second, and third elements of a list. SECTION 2: ENVIRONMENT (TABLE) OPERATIONS 
● new-entry: Creates a new environment entry (names and values). 
● lookup-in-entry: Searches a single entry for a name and returns the associated value. 
● extend-table: Adds a new entry to the front of the environment. 
● lookup-in-table: Searches through all environment entries (table) for a name. 
● initial-table: Default error handler when a name is unbound (not found in any entry). 

SECTION 3: TYPE PREDICATES AND EXPRESSION CLASSIFICATION

● atom?: Determines if a value is an atom (non-list, non-null). 
● primitive?: Checks if a value is a tagged primitive (e.g., '(primitive add1)). 
● non-primitive?: Checks if a value is a tagged user-defined function (closure). 
● expression-to-action: Main classifier that dispatches based on expression type. 
● atom-to-action: Handles classification of atomic expressions. 
● list-to-action: Handles classification of list expressions (e.g., quote, lambda, cond, application).

 SECTION 4: ACTION IMPLEMENTATIONS

● *const: Evaluates constants and primitive operations. 
● *quote: Returns the quoted portion of a 'quote expression. 
● text-of: Retrieves the text inside a quote. 
● *identifier: Looks up a variable's value in the environment. 
● *lambda: Constructs a closure from a lambda expression. 
● table-of, formals-of, body-of: Accessors for closure components. 
● else?: Checks whether a cond clause is an 'else clause. 
● question-of, answer-of, cond-lines-of: Helpers for processing cond expressions. 
● evcon: Evaluates cond clauses in order, returning the first matching result. 
● *cond: Top-level cond evaluator that calls evcon. 
● evlis: Evaluates a list of arguments. 
● function-of, arguments-of: Accessors for the components of a function application. 
● apply-primitive: Applies a primitive operation to arguments. 
● apply1: Dispatches to either apply-primitive or apply-closure depending on function type. 
● apply-closure: Applies a user-defined function (closure) using its saved environment.
 ● *application: Handles function applications by evaluating function and arguments.

SECTION 5: TOP-LEVEL EVALUATION FUNCTIONS 
● meaning: Core evaluator that dispatches based on expression classification. 
● value: Top-level function that evaluates an expression starting from an empty environment.

SECTION 6: TEST CASES

1. Quoting and List Manipulation
(value '(cdr (quote (a b c d))))       ; => (b c d)
(value '(cons 'x (quote (y z))))       ; => (x y z)
(value '(car (cdr (quote (a b c d))))) ; => b

2. Basic Arithmetic with add1/sub1
(value '(add1 (add1 3)))        ; => 5
(value '(sub1 (sub1 3)))        ; => 1
(value '(add1 (sub1 (add1 0)))) ; => 1

3. Boolean and Type Predicates
(value '(null? (quote ())))    ; => #t
(value '(atom? 'a))            ; => #t
(value '(atom? (quote (a b)))) ; => #f
(value '(number? 42))          ; => #t
(value '(eq? 'a 'a))           ; => #t
(value '(eq? 'a 'b))           ; => #f


4. Conditionals with cond
(value '(cond (#f 'nope) ((null? (quote ())) 'yes)))   ; => yes
(value '(cond ((eq? 'x 'y) 'fail) (else 'ok)))         ; => ok
(value '(cond ((number? 'x) 'fail) ((atom? 'x) 'win))) ; => win

5. Lambda and Closures
-Identity function
(value '((lambda (x) x) 'hello)) ; => hello

-Function returns a pair of its argument with itself
(value '((lambda (x) (cons x (cons x '()))) 'foo)) ; => (foo foo)

-Function with arithmetic
(value '((lambda (x) (add1 x)) 9)) ; => 10

-Function using sub1 and cons
(value '((lambda (n) (cons n (cons (sub1 n) '()))) 5)) ; => (5 4)
(newline)

6. Nested Lambdas (Lexical Scope Demonstration)
-Curried function: returns a function that adds 1 to its argument
(value '(((lambda (x) (lambda (y) (cons x (cons y '())))) 'a) 'b)) ; => (a b)
(newline)

-7. Function Returning a Constant
(value '((lambda (x) 'whatever) 42)) ; => whatever
(newline)

8. Functions and cond
A function that checks if its argument is zero and returns accordingly
(value '((lambda (x) (cond ((zero? x) 'zero) (else 'nonzero))) 0)) ; => zero
(value '((lambda (x) (cond ((zero? x) 'zero) (else 'nonzero))) 5)) ; => nonzero

1.2

SECTION 1:Helper Function

●(find? Target set): Search through the set to check whether the target exists in the set or not.
●(Repeated? Set) Check whether the list contains duplicated elements. Used to detect if the parameters of lambda are duplicated.
●Helpers for Free Variable Collection
●(element-lst? element lst): Returns whether an element is contained within a list
●(union-lst lst1 lst2): Returns the union set of lst1 and lst2
●Primitives: Defined a list of primitives

SECTION 2: Syntax Checking Procedures

●(lambda-checker expr): Check whether the input expression is a valid lambda expression
●(cond-checker expr): Check whether the input expression is a valid cond expression
●(primitive-length expr): Check whether the input primitive expression has the correct number of arguments
●(unbound-var? expr): Returns whether the expression has any free variables.
●(free-vars expr vars): Returns the list of free variables from lambda expressions

SECTION 3: Top Level Function

●(Syntax-checker expr): Top level function that recursively search through an expression, and check whether the syntax is valid.
●(Simple-chekcer): Top level wrapper function that check whether the input is an atom or pair, if it is a atom, then it should check whether it is rational or a symbol. If it is a pair, then it should call syntax-checker on the expression.

SECTION 4: Test Cases:

1.Helper functions


(find? 1 '(2 1 3)) ;=>t
(find? 4 '(2 1 3)) ;=>f

(repeated? '(a b c d)) ;=>f
(repeated? '(a b c a)) ;=>t

(element-lst? 2 '(1 2 3));->t
(element-lst? 4 '(1 2 3));->f

(union-lst '(1 2 3) '(2 3 4));->(1 2 3 4)
(union-lst '(1 2 3) '(4 5 6));->(1 2 3 4 5 6)

2.Syntax Checking Procedures

-Primitive-length
(primitive-length '(cons 1 2));->t
(primitive-length '(cons 1 2 3));->f
(primitive-length '(define x (lambda (x) (+ x 1))));->t
(primitive-length '(define x (lambda (x) (+ x 1)) (lambda (y) (+ y 1))));->f
(primitive-length '(define (x) (define y (lambda (x) (+ x 1))) y));->t
(primitive-length '(define (x)));->f


-Lambda-checker
(lambda-checker '(lambda () ())) ;=>f
(lambda-checker '(lambda () (x))) ;=>t
(lambda-checker '(lambda (x) (lambda (y) (cons x (cons y '()) 1))));=>f
(lambda-checker '(lambda (x) (lambda (y) (cons x (cons y '())))));=>t
(lambda-checker '(lambda (x) (lambda (y) (lambda (z) (+ (+ x y) z))))) ;=>t
(lambda-checker '(lambda (x) (lambda (y) (lambda (z) (+ (+ x y) z 1))))) ;=>f

-Cond-checker
(cond-checker '(cond ((> x y) 'pos) (else 'neg))) ;=>t
(cond-checker '(cond (else #t) ((> x 0) 'pos))) ;=>f
(cond-checker '(cond ((> x 0) 'pos) ((< x 0) 'neg) (else #t))) ;=>t
(cond-checker '(cond ((> x 0) 'pos) ((< x 0 1) 'neg) (else #t))) ;=>f
(cond-checker '(cond ((< n 0) 'neg) ((= n 0) (cond((< n 10) 'x) ((< n 100) 'y) (else 'z))) (else #f))) ;=>t
(cond-checker '(cond ((< n 0) 'neg) ((= n 0) (cond((< n 10) 'x) ((< n 100) 'y) (else 'z))) (else (+ 1 2 3)))) ;=>f

-Syntax-Checker
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

-Simple-check
(simple-check 12);->t
(simple-check #t);->t
(simple-check 'x)
(simple-check 0+1i);->f

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

1.3

;; Environment properties: ****
      - Env structure: A nested list
      - Entry structure: "An entry is a pair of lists whose first list is a set. Also,
          the lists must be of equal length."
            * Implies that every valid variable in TLS is bound
  
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

 Claim: The environment subsystem of TLS is structured in a way that allows it to act as
         an abstract data type. Therefore, an a-list structure for the env, rather than the list of bindings, still satisfies
         the above specifications.
           * If this is true, then the action functions that utilize the subsystem should return
              the same value as the original interpreter's representation

       ; Environment properties: The only functions that need to be changed to adjust to the new
          structure are the primary components of the subsystem.


1.4 Correctness Proof for Closure and Lexical Scope

Closure: the function to capture environment at definition time, so that functions can have access to variables from its outer function, even after the outer function executed.

Lexical scope: the scope of the variables is determined by its position in the code's structure. In TLS, the lexical environment for the outer-most function is empty, and the lexical environment of the inner functions is the extended environment with entries of variables and their value, where it can access variables from its parent functions. The lexical scope is determined at the time of definition not execution, this allows access to variables in outer function even after execution.  

Atomic expression(number, Boolean, primitives, identifiers) will be trivial to the correctness of implementation of closure and lexical scope, as number and Booleans are self-evaluating constants, and primitives and identifiers do not create closure themselves, if they need to search up their arguments, they will just refer to their environment, in a closure, the environment they will be referring to is the environment obtained by closure.

In the TLS interpreter, closure is created when user inputs a user-defined function, in which the function *lambda would return a closure that tagged the function as non-primitive and store the environment with the parameters and the function body.  This environment will later be used to store the entries of variables and their evaluated value, so that the function body can be evaluated in their respected scope. This ensures that variables will be resolved according to their lexical definition.

For function applications, if the function is primitive, then it is trivial to the implementation of closure and lexical scope. If the function is user-defined, then they will be processed by the *lambda to convert to closure form that captures the environment that the function body will refer to when evaluating. At top level, the environment is empty as it hasn’t been extended with any entry yet. When evaluating, the function apply-closure would evaluate the function body in its current environment and extend the environment with new entry of variables and their evaluated arguments. This ensures that the inner function would have access to the variables from the outer functions as they are extended into the table by the time they are evaluated,  while the outer functions wouldn’t have access to the variables in the inner functions as by the time they were evaluated, the variables of inner functions have not yet been extended into the table. Hence, lexical scoping is preserved.

Hence, the TLS interpreters implements closure and lexical scoping correctly.


1.5: Proof of Correctness for TLS Implementation

The goal of this section is to provide a proof that the implementation of the TLS interpreter
adheres to the correctness standards defined by the specifications of *The Little Schemer* (TLS).
We will prove correctness based on the following criteria:
1. Lexical scoping - variables must resolve according to the scope in which they were defined.
2. Closure - functions must capture and correctly reference the environment in which they were defined.
3. Determinism - the evaluation of expressions should always yield the same result for the same input.
4. Side-effect-free evaluation - the interpreter should not modify global state or perform actions outside evaluation.

We will proceed by proving correctness through structural induction.

Base Case: Atomic Expressions
Base cases deal with the simplest forms of expressions in TLS: numbers, booleans, and symbols.
These expressions are self-evaluating or lookup-based, and do not involve closures or scoping issues.

(define (eval-base-case expr env)
  (cond
    ((number? expr) expr)  ;; A number is its own value.
    ((boolean? expr) expr)  ;; A boolean is its own value.
    ((symbol? expr) (lookup-in-env expr env)) ;; A symbol looks up its value in the environment.
    (else (error "Unsupported expression in base case"))))

1. Numbers and booleans are self-evaluating, so they do not require a lookup in the environment.
    They will always evaluate to themselves, which ensures correctness.
2. If the expression is a symbol (identifier), it needs to be looked up in the environment.
    The environment should return the correct value that was bound to the symbol.
    The lookup operation correctly follows lexical scoping rules and ensures that the value resolved for a variable is determined by the closest enclosing environment.

Inductive Case: Function Definitions (Lambdas)
In the inductive step, we need to prove that the interpreter correctly handles function definitions.
Function definitions create closures that capture their lexical environment at the time of definition.

Example:
 (define (plus-1 x) (lambda () (+ x 1)))
 Here, plus-1 is a function that returns a closure. The closure will have access to the environment where x is bound.

(define (eval-lambda expr env)
  (if (and (list? expr) (= (length expr) 2))
      (let ((params (first expr))      ;; Extract parameters from the lambda expression.
            (body (second expr)))      ;; Extract the body of the lambda expression.
        (lambda args                  ;; Create a lambda closure that takes arguments.
          (let ((new-env (extend-env params args env))) ;; Extend the environment with the arguments.
            (eval body new-env))))         ;; Evaluate the body in the new extended environment.
    (error "Invalid lambda expression")))

 The evaluation of a lambda expression returns a closure, which consists of:
 1. The function body.
 2. The environment where the lambda was defined.
 This closure captures the lexical environment, which will be used when the lambda is later called.

 Inductive Case: Function Applications
 In TLS, when a function is applied, the interpreter must correctly handle both primitive functions and closures.
 If the function being applied is a closure, the closure's lexical environment must be used to resolve variable bindings.
 The environment for the closure is extended with the arguments, and the body of the closure is evaluated.

(define (eval-application expr env)
  (let ((func (eval (first expr) env))    ;; Evaluate the function part of the application.
        (args (map (lambda (arg) (eval arg env)) (rest expr)))) ;; Evaluate each argument in the current environment.
    (if (closure? func)
        (apply-closure func args)          ;; If the function is a closure, apply it.
        (error "Invalid function application"))))

 Applying a closure:
 When applying a closure, the environment from the closure is extended with the arguments passed to the closure.
 The closure environment will retain access to the variables from the scope where the closure was created.

 Determinism: Expression Evaluation
 TLS ensures determinism by evaluating expressions in a consistent manner based on the current environment.
 Since each lookup operation, closure creation, and function application is deterministic, the same expression
 will always evaluate to the same result for the same input, given the same environment.

 Side-effect-free Evaluation
 TLS operates under the assumption of a side-effect-free evaluation model. This means that expressions do not modify
 any global state or interact with external systems. The only effect of an evaluation is producing a result.
 This ensures that the evaluation is safe and does not introduce unintended consequences.

 Closure and Lexical Scope Proof via Structural Induction
 We can now provide a formal proof of correctness by induction on the structure of the expressions being evaluated.

 Base Case:
 For atomic expressions (numbers, booleans, and symbols), the proof is trivial:
 - Numbers and booleans are self-evaluating, so they return their own values, satisfying lexical scoping.
 - Symbols are resolved by looking them up in the environment, which ensures correctness according to the environment's lexical structure.

 Inductive Step:
 Assume that the TLS implementation correctly evaluates all subexpressions (i.e., for each subexpression, it correctly handles closures, environments, and scoping).
 Now, consider a lambda expression `(lambda (x) ...)` and its application `(lambda (x) ...) 10`.
 - The lambda expression creates a closure that captures the current environment.
 - When the closure is applied, a new environment is created by extending the closure's environment with the argument binding for `x`.
 - The body of the lambda is then evaluated in this new extended environment, preserving lexical scoping by ensuring that the correct environment is used.
 - Thus, the correct value for `x` is used, and the closure behaves according to lexical scoping rules, correctly referencing variables from the outer environment.

 Conclusion:
 By structural induction, we have shown that TLS correctly implements closure and lexical scope, handles function applications deterministically,
 and does so in a side-effect-free manner. These properties satisfy the specifications of the TLS interpreter and prove the correctness of the implementation.


1.6 

The TLS (The Little Schemer) interpreter is implemented as a pure Scheme program running on top of the R5RS-compliant DrRacket environment. This design means that TLS depends heavily on DrRacket’s underlying Scheme system, especially in the execution of primitive operations and the mechanics of function calling. 

Dependence on R5RS of DrRacket 

TLS defines an interpreter that processes Scheme expressions by representing and evaluating them explicitly as data structures (lists, atoms, etc.). However, TLS does not implement all aspects of Scheme from scratch; instead, it leverages DrRacket’s R5RS Scheme runtime for: 

Primitive operations: Basic arithmetic, list operations, boolean logic, and other built-in primitives are directly performed by DrRacket’s native implementation. 

Low-level evaluation and environment management: TLS uses custom environment structures but relies on DrRacket to manage actual memory, variable bindings, and function calls at the system level. 

Function call mechanics for primitives: When TLS evaluates a primitive function application, it invokes DrRacket’s built-in function directly. TLS itself only dispatches to these primitives without implementing their internal mechanics. 

Mechanics of Function Calling: TLS vs. DrRacket 

In TLS: 

Function application expressions are parsed and classified. 

TLS evaluates the function expression to determine if it is a primitive or a user-defined closure. 

If it is a user-defined closure, TLS constructs a new environment frame extending the saved closure environment with the bindings of parameters to argument values. 

TLS then recursively evaluates the function body expression in this extended environment. 

In DrRacket 

TLS is itself a Scheme program running inside DrRacket, so every TLS function call — including recursive calls in the interpreter — is executed by DrRacket’s function calling mechanism. 

When TLS applies a primitive function (e.g., +, car, cons), the call is delegated directly to DrRacket’s built-in primitive function implementations. 

When TLS applies a user-defined closure, TLS’s environment and evaluation rules govern the evaluation, but the recursive invocation of TLS evaluation functions is managed by DrRacket’s call stack and execution engine. 

Thus, TLS performs the semantic interpretation and environment handling at the Scheme language level, while relying on DrRacket’s runtime system for the actual execution, stack management, and primitive operation execution. 

|#




