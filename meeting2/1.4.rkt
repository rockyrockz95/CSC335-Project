(load "1.1.rkt")
;1.4 Correctness Proof for Closure and Lexical Scope

#|

Closure: the function to capture environment at definition time, so that functions can have access to variables from its outer function, even after the outer function executed.

Lexical scope: scope of the variables is determined by its position in the code's structure. For a nested function, the lexical environment for the outer-most function is the global scope, and the lexical environment of the inner functions is its parent functions' scope, where it can access variables from its parent function's scope(including the global scope). The lexical scope is determined at the time of definition not execution, this allows access to variables in outer function even after the execution.

|#
  
;Ex:
(define (plus-1 x)
    (lambda () (+ x 1)))

(plus-1 1) ;when you call plus-1 directly, it'll return a procedure, which is the inner lambda and it creates a closure where it captures the lexical environment, where it contains the binding of variable x with 1.

((plus-1 1)); when you try to call the inner lambda, it will return 2 since we passed the argument 1 and the inner lambda should increment the input by 1. This is a result of closure. When plus-1 is called, it captures the lexical environment with x=1, then because of lexical scope, inner lambda would have access to the variable x because the varibale x is in its parent function's scope.

((plus-1 2));->3
((plus-1 100));->101
(newline)

;To prove that our  TLS implements closure and lexical scope correctly we can use structural induction.

;Base Case:

;For atom expression(number, boolean, primitives, identifiers), TLS handles closure and lexical scoping correctly.

;Correct because number and boolean are self-evaluating constants that do not depend on environment.
;For a primitive, if they are referenced directly, they will be tagged as primitive and treated as a constant, which do not require environment as well. When applied, the primitive itself is not a closure and does not capture any environment. If it needs to look up its arguments, it will just refer to it‘s current environment. If it's in a closure, then it will refer to the saved environment captured by closure, which ensure that the variables are resolved in their lexical definition.
;For identifiers,it also does not create a closure that capture environment, it just refer to it's environment passed with the function meaning. In a closure, it's environment will be the the environment captured by closure, which ensure the identifier will be resolved using its lexical definition.

;Hence, atomic expression will be trivial to the proof of closure and lexical scoping as they do not involve creating closure.

;Assume for all subexpression 'exp of expression exp, the TLS scheme correctly implements closure that captures the environment, and evaluate the variables according to the lexical environment.

;Induction step:

;In the TLS scheme, when defining a lambda expression, the function *lambda would return the closure: (non-primitive (env (parameters) (body))). In which it tagged the user defined function as non-prmitive,so that when evaluating the function, the interpreters knows its a closure and can appply closure. The environment env is the lexical environment captured by closure, which will be the parent scope of the function, where it would store the future entries of variables so that its inner function can access variables from outer function. By induction hypothesis, since all variables are resolve according to the lexical environment, when the function body is later evaluated it will look up its arguments in the saved environment using look-up-table, ensuring lexical scope, where it would have the access to variables in the outer function as they are stored in the table. 

;Ex:
(value '(lambda (x) (cons x 1)));->(non-primitive (() (x) (+ x 1))). In this case, the first part of exp is the non-primitive tag, and the second part is the environment env with the formal body of the lambda expression. The empty list is the table or environment

;During function application, if the function is a primitive function, then according to our base case, they do not involve the creation of closure, hence the interpreter would handle their closure and lexical scope correctly. If the function is a non-primitive, then the function will be processed by *lambda to create a closure that captures environment, which is empty at top-level. When evaluating, the function apply-closure would evaluate the function body in the environment obtain by closure, and extend the environment with a new entry of the variable with its evaluated arguments, which means now the inner function have access to variables in the outer function as they are stored in the environment, whereas the outer function could never access the variables in the inner function, as by the time the outer function are evaluated with their respected arguments, variables of the inner function are not yet recorded in the table, so they can't find it in the table even if they try to. Hence, lexical scope is preserved.

;Therefore,the TLS scheme correctly implements closure and lexical scope.

;Ex:
(value '(((lambda (x) (lambda (y) (cons x y))) 2) 3))
(value '((((lambda (x) (lambda (y) (lambda (z) (cons x (cons y z))))) 2) 3) 4))
(value '(((lambda (x) (lambda (y) (car (cons x y)))) 2) 3))




