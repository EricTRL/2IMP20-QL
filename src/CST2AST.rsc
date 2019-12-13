module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return form("", [], src=f@\loc); 
}

list[AQuestion] toList(questions) {
	return for(Question q <- questions) append cst2ast(q);
}

AQuestion cst2ast(Question q) {
	switch(q) {
		case (Question)`<Str question> <Id identifier> ":" <Type varType>`:
			return simpleQuestion(cst2ast(question), cst2ast(identifier), cst2ast(varType), src=question@\loc);
		case (Question)`<Str question> <Id identifier> ":" <Type varType> "=" <Expr e>`:
			return computedQuestion(cst2ast(question), cst2ast(identifier), cst2ast(varType), cst2ast(e), src=question@\loc);
		case (Question)`"{" <Question* questions> "}"`: 
			return block(toList(questions));
		case (Question)`"if" <Expr cond> "{" <Question* thenPart> "}" "else" "{" <Question* elsePart> "}"`:
			return ifThenElse(cst2ast(cond), toList(thenPart), toList(elsePart));
		case (Question)`"if" <Expr cond> "{" <Question* thenPart> "}"`:
			return ifThen(cst2ast(cond), toList(thenPart));
		default:
			throw "Unhandled question: <q>";
	}
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref("<x>", src=x@\loc);
    case (Expr)`<Expr lhs> "*" <Expr rhs>`: return multiplication(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`"!" <Expr e>`: return negation(cst2ast(e), src=e@\loc);
    case (Expr)`<Expr lhs> "/" <Expr rhs>`: return division(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> "+" <Expr rhs>`: return addition(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> "-" <Expr rhs>`: return subtraction(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> "\<" <Expr rhs>`: return smallerThan(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> "\>" <Expr rhs>`: return greaterThan(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> "\<=" <Expr rhs>`: return leq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> "\>=" <Expr rhs>`: return geq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> "==" <Expr rhs>`: return eq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> "!=" <Expr rhs>`: return neq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> "&&" <Expr rhs>`: return and(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> "||" <Expr rhs>`: return or(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Bool b>`: return boolean(fromString("<b>"), src=b@\loc);
    case (Expr)`<Int i>`: return integer(toInt("<i>"), src=i@\loc);
    case (Expr)`<Str s>`: return string("<s>", src=s@\loc); 
    // etc.
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
	switch (t) {
		case (Type)`"boolean"<Type b>`: return boolean(src=b@\loc);
		case (Type)`"integer"<Type i>`: return integer(src=i@\loc);
		case (Type)`"string"<Type s>`: return string(src=s@\loc);
		default: throw "Unhandled type: <t>";
	}
}
