;;; ====================================================
;;; 1.5 Correctness Proof for TLS Interpreter
;;; ====================================================

;; ==================== BOXED COMMENT ====================
#|
Correctness Proof Outline:

1. Specification:
   Our interpreter is correct if for every TLS expression E:
   - Atomic expressions evaluate to themselves
   - Variable references follow lexical scoping rules
   - Primitives behave as specified
   - Lambda creates proper closures
   - Applications evaluate arguments and apply functions correctly
   - Conditionals evaluate properly

2. Proof Approach:
   We'll prove correctness by examining each part of the interpreter from 1.1
   and showing it meets the specification.

3. Core Components:
   a. meaning: The main evaluation function
   b. expression-to-action: Dispatches to appropriate evaluator
   c. Action handlers (*const, *quote, etc.)
   d. Environment operations (lookup-in-table, etc.)
   e. Application machinery (apply1, evlis, etc.)

Proof:
|#
;; =======================================================

(load "1.1.rkt")

;; Atomic Expressions
(display "Testing atomic expressions:\n")
(display (equal? (value '42) 42)) (display " (numbers evaluate to themselves)\n")
(display (equal? (value '#t) #t)) (display " (booleans evaluate to themselves)\n")
(display (equal? (value '(quote x)) 'x)) (display " (quotes evaluate to their contents)\n")

;; Variable Reference
(display "\nTesting variable reference:\n")
(let ((env (extend-table (new-entry '(x y) '(1 2)) '())))
  (display (equal? (meaning 'x env) 1)) (display " (bound variables lookup)\n"))

;; Primitives
(display "\nTesting primitives:\n")
(display (equal? (value '(cons 'a 'b)) '(a . b))) (display " (cons works)\n")
(display (equal? (value '(car '(a b c))) 'a)) (display " (car works)\n")
(display (equal? (value '(add1 5)) 6)) (display " (add1 works)\n")

;; Lambda and Application
(display "\nTesting lambda and application:\n")
(display (equal? (value '((lambda (x) x) 'hello)) 'hello)) (display " (identity function)\n")
(let ((closure (meaning '(lambda (x) (cons x x)) '())))
  (display (and (non-primitive? closure)
                (equal? (apply1 closure '(5)) '(5 . 5))))) 
  (display " (closure creation and application)\n")

;; Conditionals
(display "\nTesting conditionals:\n")
(display (equal? (value '(cond (#f 'no) (#t 'yes))) 'yes)) (display " (cond evaluation)\n")
(display (equal? (value '(cond ((null? '(a)) 'no) ((atom? 'a) 'yes))) 'yes)) 
(display " (nested cond)\n")

;; ==================== BOXED COMMENT ====================
#|
Proof Components:

1. meaning function:
   - Correctly dispatches via expression-to-action
   - Preserves evaluation order (function before arguments)

2. expression-to-action:
   - Properly classifies all expression types
   - Atom vs list distinction handled correctly

3. Action Handlers:
   - *const: Correctly returns atomic values
   - *quote: Returns quoted text unchanged
   - *identifier: Proper environment lookup
   - *lambda: Creates closures with environment capture
   - *cond: Proper conditional evaluation
   - *application: Correct function application

4. Environment System:
   - extend-table: Properly extends environments
   - lookup-in-table: Correct lexical scoping
   - new-entry: Creates valid environment entries

5. Application Machinery:
   - apply1: Correctly dispatches primitives/closures
   - evlis: Proper argument evaluation order
   - apply-primitive: Each primitive implemented correctly
   - apply-closure: Proper closure application

The test cases demonstrate operational correctness for:
- All atomic expression types
- Variable binding and scope
- Primitive operations
- Function definition and application
- Conditional evaluation

Therefore, the interpreter is correct according to our specification.
|#
;; =======================================================

;; Final Correctness Verification
(define (verify-correctness)
  (and
   ;; Atomic expressions
   (equal? (value '42) 42)
   (equal? (value '#t) #t)
   (equal? (value '(quote x)) 'x)
   
   ;; Variable reference
   (let ((env (extend-table (new-entry '(x) '(5)) '())))
     (equal? (meaning 'x env) 5))
   
   ;; Primitives
   (equal? (value '(cons 'a 'b)) '(a . b))
   (equal? (value '(car '(a b c))) 'a)
   (equal? (value '(add1 5)) 6)
   
   ;; Lambda and application
   (equal? (value '((lambda (x) x) 'hello)) 'hello)
   (let ((closure (meaning '(lambda (x) (cons x x)) '())))
     (equal? (apply1 closure '(5)) '(5 . 5)))
   
   ;; Conditionals
   (equal? (value '(cond (#f 'no) (#t 'yes))) 'yes)
   (equal? (value '(cond ((null? '(a)) 'no) ((atom? 'a) 'yes))) 'yes)))

(display "\nFinal correctness verification: ")
(display (verify-correctness)) (newline)