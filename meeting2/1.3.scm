(load "1.1.rkt")

;;; 1.3 Environment Subsystem Proof & Change in Representation

;=======================================================================================================================
#|
 Environment Specification for TLS:
  ;; TLS' environment subsystem manages the ((name)(value)) pair entries that makeup the environment.

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
  
  ;; Interpreter objects that use the subsystem:
      - *identifier: uses lookup-in-table to create var references
      - *lamdba: creates a closure within the environment
      - Other action functions: don't modify the table, but keep track of it 
      - apply-closure: evaluates the body of the function and extends the existing environment
          with its arguments
  
  ;; All of these functions keep track of and/or use the environment maintain the value of bound variables
  
  ;; Interpreter property:
      - Lexical Scoping: In the environment level*, maintained by extend-table. Cons'ing the new entries to the front to the stack is analogous to
                  going deeper into scope frames as new closures are created. 
             - In the action functions that modify the table, lookup-in-table is used to provide the first occurrence of the variable in the table
                 As established before, new-entry adds entries to the top of the stack. By retrieving the first occurence
                 of the variable in the stack, the action functions are using the value assigned in the latest frame of the
                  environment. Thus, lexical scope is maintained by this interpreter.
         
             * As opposed to the underlying R5RS

  ;; Claim: Our implementation* satisfies this specification as well.
    * Will be calling TLS-335 for clarity

    - Primary environment operations: Our interpreter makes no changes to the original TLS implementation
        therefore it is true that in the case of lookup and adding variables, TLS and TLS-335 function the same.

    - Lexical scoping:
        - Each new entry is added to the top of the stack ~= nesting lambda statements create deeper
              closures that hold free variables and their values specific to their body.
        - The only new operation dealing with closures in our system is the syntax checker, which deals with
              * lambda
              * unbound vars
              - In either case, the checker only verifies errors in syntax using an internal table. Since
                  the interpreter's table is not changed, its handling of closures should be maintained.
                     
|#
;==========================================================================================================================



#| ========================================================================================================================
   Part 2: Change the representation of the env and show that the representation satisfies the spec
     and works with the rest of the interpreter

       Claim: The environment subsytem of TLS is structured in a way that allows it to act as
         an abstract data type. Therefore, an a-list structure for the env, rather than the list of bindings, still satisfies
         the specifications stated above.

       ; Environment properties: The only functions that need to be changed to adjust to the new
          structure are the the primary components of the subsystem.
       
       ; Interpreter properties: The implementation of the action functions do not need to change. As the ADS allows for
          operations to work even with differing structure
         

   ========================================================================================================================
|# 

;;; Environment Changes
  ;; Creating an env: build & new-entry
  ;; Extending the table -- needs no change, cons'ing the pair to the front of the stack maintains scope
    ; and fulfills the expectations of the action functions
  ;; Table Lookup: lookup-in-entry & lookup-in-table -- must be changed to account for alist structure.

;;; Action Function Calls ****


  

