module AST

/*
 * Abstract Syntax of QL
 *
 */

// Form definition
data AForm(loc src = |tmp:///|)
    = form(str name, list[AQuestion] questions); 

// Question definition.
data AQuestion(loc src = |tmp:///|)
    = simpleQuestion(AExpr question, AExpr identifier, AType varType)
    | computedQuestion(AExpr question, AExpr identifier, AType varType, AExpr e)
    | block(list[AQuestion] questions)
    | ifThenElse(AExpr cond, list[AQuestion] thenpart, list[AQuestion] elsepart)
    | ifThen(AExpr cond, list[AQuestion] questions); 

// Abstract Expression definition
// Note: Most operations are performed on a left hand side and a right hand side
// Note: The basic data types (integer, boolean, string) are converted to Rascal's primitive int, bool, and string respectively
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
    | strng(str s);

// IDs are represented by a name
data AId(loc src = |tmp:///|)
    = id(str name);

// Datatypes
data AType(loc src = |tmp:///|)
    = string() | integer() | boolean();
