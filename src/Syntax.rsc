module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id name "{" Question* questions "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = simpleQuestion: Expr question Expr identifier ":" Type varType
  | computedQuestion: Expr question Id identifier ":" Type varType "=" Expr e
  | block: "{" Question* questions "}"
  | ifThenElse: "if" Expr cond "{" Question* thenPart "}" "else" "{" Question* elsePart "}"
  | ifThen: "if" Expr cond "{" Question* questions "}" 
  ;  

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = var: Id \ "true" \ "false" // true/false are reserved keywords.
  | boolean: Bool b
  | integer: Int i
  | string: Str s
  | bracket "(" Expr e ")" 
  > non-assoc (negation: "!" Expr e
  				) //TODO: min-getallen
  > left	( multiplication: Expr lhs "*" Expr rhs
  			| division: Expr lhs "/" Expr rhs
  			)
  > left 	( addition: Expr lhs "+" Expr rhs
  			| subtraction: Expr lhs "-" Expr rhs
  			)
  > non-assoc ( smallerThan: Expr lhs "\<" Expr rhs
			  | greaterThan: Expr lhs "\>" Expr rhs
			  | leq: Expr lhs "\<=" Expr rhs
			  | geq: Expr lhs "\>=" Expr rhs
			  )
  > left	( eq: Expr lhs "==" Expr rhs
  			| neq: Expr lhs "!=" Expr rhs
  			)
  > left (and: Expr lhs "&&" Expr rhs)
  > left (or: Expr lhs "||" Expr rhs)
  ;
  
syntax Type
  = "string" | "integer" | "boolean";  
  
lexical Str = "\"" ![\"]*  "\"";

lexical Int = [0] | [+\-]?[1-9][0-9]*;

lexical Bool = "true" | "false";



