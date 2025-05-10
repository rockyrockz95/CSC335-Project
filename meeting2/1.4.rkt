
;1.4 Correctness proof for closure and lexical scope

#|
Base Case: 

Case 1: exp is a constant, (value exp) returns exp
Case 2: exp is an identifier, (value exp) returns the corresponding value of exp in the environment or table using the function lookup-in-table

Induction Step:
Assume that for all expression exp’ smaller than the expression exp, evaluating exp’ respects lexical scoping through closure.

For a lambda-expression: (lambda (parameters) (body)), (value lambda-expression) returns:
(non-primitive (env (parameters) (body)))
Where it creates closure that captures environment env at definition time, which ensures that any free variable in the exp is resolved using the environment at definition, thus lexical scope is preserved.

For evaluation of an exp, (meaning exp env) either returns a primitive tagged function or a non-primitive.
-If it returns primitive tagged function, then it is not closure, so it does not reference any environment, hence lexical scope is preserved. 
-If it returns a non-primitive, then by the induction hypothesis, each argument of the expression respects lexical scoping. When we use apply-closure, it extends the closure's saved lexical environment with the new frame binding each identifier in the parameter to its corresponding evaluated argument. The function body is then evaluated in this extended environment. Thus, lexical scoping is preserved.

Therefore, by structural induction, all expression respect lexical scope.

|#

