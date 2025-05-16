 ;;;Team: LingJie Pan, Xin Gao, Joquanna Scott

;; 1.6 Carefully explain the dependence of TLS on the underlying R5RS of DrRacket.
;;      Focus, in particular, on the mechanics of function calling: which system does which work?

;; INTRODUCTION
;; The TLS interpreter (from "The Little Schemer") is a meta-circular interpreter: it is written in
;; Scheme and interprets a subset of Scheme expressions itself. Although it *appears* to replicate
;; the behavior of Scheme from scratch, it in fact *relies heavily* on the host Scheme implementation
;; (R5RS in DrRacket) to do fundamental work. This dependency is most visible in function application
;; and evaluation of primitive operations, but it also extends to basic list operations, predicate
;; checking, and error behavior.

;; OVERVIEW OF FUNCTION CALL MECHANICS
;;
;; In TLS, when a function application is evaluated—such as:
;;
;;     ((lambda (x) (add1 x)) 5)
;;
;; the interpreter follows this process:
;;
;;     1. Identify the function part and the arguments.
;;     2. Evaluate the function and arguments using the environment.
;;     3. Dispatch to an appropriate handler: either 'apply-primitive' or 'apply-closure'.
;;
;; While this entire process is controlled by TLS’s own logic, the actual *computations* (such as
;; arithmetic or list manipulation) are performed by the underlying R5RS Scheme.

;; DETAILS OF WORK SPLIT BETWEEN TLS AND R5RS
;;
;; -------------------------------
;; TLS Responsibilities (Interpreter Level)
;; -------------------------------
;;
;; TLS is responsible for:
;;
;; 1. **Parsing and expression dispatching**
;;    - `expression-to-action` and its helpers classify expressions: atom vs list, and dispatch to
;;      appropriate action handlers.
;;    - Expressions such as `'quote`, `lambda`, `cond`, and applications are recognized by TLS logic.
;;
;; 2. **Managing lexical environments**
;;    - TLS defines its own structure for environments, called "tables" (lists of name-value pairs).
;;    - `extend-table`, `lookup-in-table`, and `new-entry` manage variable bindings and scope.
;;
;; 3. **Closure creation and application**
;;    - When a lambda expression is evaluated, it produces a tagged structure like:
;;        (non-primitive (env formals body))
;;      This is TLS’s way of implementing closures, capturing the lexical environment at definition time.
;;
;; 4. **Recursive evaluation of expressions**
;;    - `meaning` recursively evaluates expressions in the context of a given environment.
;;    - This includes evaluation of cond branches, quote expressions, variable lookups, and lambda bodies.
;;
;; 5. **Function application**
;;    - TLS uses `apply1` to determine whether a function is primitive or user-defined.
;;    - If it is a closure (user-defined), `apply-closure` extends the closure’s saved environment
;;      with argument bindings and evaluates the body.

;; -------------------------------
;; R5RS Responsibilities (Host Runtime Level)
;; -------------------------------
;;
;; Despite all this logic, TLS *does not reimplement the functionality* of basic operations like
;; addition, equality checks, or list access. These are delegated directly to the host Scheme system.
;; Specifically:
;;
;; 1. **Primitive function computation**
;;    - `apply-primitive` contains code like:
;;
;;        (cond ((eq? name 'add1) (add1 (car args)))
;;              ((eq? name 'car)  (car  (car args)))
;;              ((eq? name 'null?) (null? (car args))) ...)
;;
;;    - These function calls (e.g., `add1`, `car`, `null?`) are not defined by TLS—they are built-in
;;      R5RS Scheme functions provided by DrRacket.
;;    - TLS merely wraps the correct arguments and relies on Scheme to actually do the work.
;;
;; 2. **Basic data structures and utilities**
;;    - TLS relies on Scheme pairs (cons cells), null values, and list operations (`cons`, `car`, `cdr`).
;;    - Environment tables are implemented as lists; all manipulations on them (searching, binding,
;;      destructuring) rely on R5RS behavior of `cons`, `car`, `cdr`, `null?`, etc.
;;
;; 3. **Equality, tagging, and predicates**
;;    - TLS defines tags like `(primitive add1)` to identify functions, and uses `eq?` or `equal?`
;;      to compare symbols and structures.
;;    - These comparisons and predicate checks (`symbol?`, `number?`, `pair?`) are also native R5RS functions.

;; EXAMPLE OF CALL FLOW
;;
;; Consider evaluating:  (value '((lambda (x) (add1 x)) 5))
;;
;; The process unfolds as:
;;   -> value (top-level evaluator)
;;       -> meaning (calls expression-to-action)
;;           -> *application
;;               -> meaning of function part => (lambda (x) (add1 x))
;;                   -> returns (non-primitive closure)
;;               -> evlis of args => (5)
;;               -> apply1
;;                   -> apply-closure (since it's a closure)
;;                       -> extend-table
;;                       -> meaning of body (add1 x)
;;                           -> meaning of add1 => (primitive add1)
;;                           -> evlis of args => (5)
;;                           -> apply-primitive
;;                               -> (add1 5) ← computed by **R5RS**, not TLS

;; WITHOUT R5RS...
;; TLS would fail to perform:
;;   - Arithmetic operations (add1, sub1, +, *)
;;   - Boolean checks (number?, symbol?, null?)
;;   - Basic list functions (car, cdr, cons)
;;   - Even the equality comparisons used in cond-dispatches and lookup

;; TLS is built on the *assumption* that R5RS behaves consistently and correctly.
;; Without it, TLS would need to define its own number system, list structure, arithmetic rules,
;; equality mechanics, and error handling—a much more complex undertaking.

;; SUMMARY: WHO DOES WHAT?
;;
;;                  TASK                              | TLS Interpreter | R5RS Scheme
;; ---------------------------------------------------|------------------|---------------
;; Parsing & classifying expressions                  | Yes             | No
;; Managing environments and closures                 | Yes             | No
;; Dispatching meaning and evaluating structure       | Yes             | No
;; Applying closures (user-defined functions)         | Yes             | No
;; Applying primitives                                | Dispatcher only | Yes
;; Arithmetic operations (e.g., add1, *)              | No              | Yes
;; List operations (car, cdr, cons, null?)            | No              | Yes
;; Predicate checks (number?, symbol?, equal?)        | No              | Yes
;; Equality comparison and tagging (eq?, equal?)      | No              | Yes
;; Error signaling (e.g., unbound variable)           | Partial         | Yes

;; CONCLUSION
;;
;; TLS is a structured, layered Scheme interpreter written in Scheme itself. However, its
;; interpreter logic stops at the level of identifying *what* operation needs to happen
;; and *how* environments are managed. When it comes to actually *computing results*, especially
;; for primitives, TLS delegates the heavy lifting to R5RS.
;;
;; This separation models how interpreters work in practice: the high-level interpreter defines
;; syntax and control structures, but depends on the runtime to implement primitives.
;; In TLS’s case, DrRacket’s R5RS is not just a convenience—it is a necessary computational engine.
