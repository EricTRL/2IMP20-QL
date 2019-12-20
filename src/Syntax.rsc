module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id name "{" Question* questions "}"; 

// Concrete Syntax for (computed) questions and statements (such as 'if')
syntax Question
  = simpleQuestion: Str question Id identifier ":" Type varType
  | computedQuestion: Str question Id identifier ":" Type varType "=" Expr e
  | block: "{" Question* questions "}"
  | ifThenElse: "if (" Expr cond ") {" Question* thenPart "}" "else" "{" Question* elsePart "}"
  | ifThen: "if (" Expr cond ") {" Question* questions "}";  

// Concrete Syntax for Expressions and operations on those
// Uses C/Java-style precedence rules, and handles disambiguation using priorities and associativity
syntax Expr
    = Id \ "true" \ "false" // true/false are reserved keywords.
    | bln: Bool b
    | intgr: Int i
    | strng: Str s
    | bracket "(" Expr e ")" 
    > non-assoc (negation: "!" Expr e)
    > left  ( multiplication: Expr lhs "*" Expr rhs
            | division: Expr lhs "/" Expr rhs
            )
    > left  ( addition: Expr lhs "+" Expr rhs
            | subtraction: Expr lhs "-" Expr rhs
            )
    > non-assoc ( smallerThan: Expr lhs "\<" Expr rhs
                | greaterThan: Expr lhs "\>" Expr rhs
                | leq: Expr lhs "\<=" Expr rhs
                | geq: Expr lhs "\>=" Expr rhs
                )
    > left  (equal: Expr lhs "==" Expr rhs
            | neq: Expr lhs "!=" Expr rhs
            )
    > left (and: Expr lhs "&&" Expr rhs)
    > left (or: Expr lhs "||" Expr rhs);

// QL consists of strings, integers, and booleans
syntax Type
    = "string" | "integer" | "boolean";  

// RegEx definition of strings; any series of characters within double quotes
lexical Str = "\"" ![\"]*  "\"";

// RegEx definition of integers; zero, or can start with a sign, and not starting with a zero
lexical Int = [0] | [+\-]?[1-9][0-9]*;

// Regex definition of booleans; either true or false
lexical Bool = "true" | "false";



