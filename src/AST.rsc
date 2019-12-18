module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = simpleQuestion(AExpr question, AExpr identifier, AType varType)
  | computedQuestion(AExpr question, AExpr identifier, AType varType, AExpr e)
  | block(list[AQuestion] questions)
  | ifThenElse(AExpr cond, list[AQuestion] thenpart, list[AQuestion] elsepart)
  | ifThen(AExpr cond, list[AQuestion] questions)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | negation(AExpr e)
  | multiplication(AExpr lhs, AExpr rhs)
  | division(AExpr lhs, AExpr rhs)
  | addition(AExpr lhs, AExpr rhs)
  | subtraction(AExpr lhs, AExpr rhs)
  | smallerThan(AExpr lhs, AExpr rhs)
  | greaterThan(AExpr lhs, AExpr rhs)
  | leq(AExpr lhs, AExpr rhs)
  | geq(AExpr lhs, AExpr rhs)
  | equal(AExpr lhs, AExpr rhs)
  | neq(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)
  | bln(bool b)
  | intgr(int i)
  | strng(str s)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = string() | integer() | boolean();
