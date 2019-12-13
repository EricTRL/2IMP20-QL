module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean;
import IO;


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
  list[AQuestion] aqs = [];
  for (Question q <- f.questions) {
  	aqs = aqs + [cst2ast(q)];
  }
  AForm result = form("<f.name>", aqs, src=f@\loc);
  println(result);
  return result; 
}

list[AQuestion] toList(questions) {
L = [cst2ast(q) | (Question q <- questions)];
	return [cst2ast(q) | (Question q <- questions)];
}

AQuestion cst2ast(Question q) {
	switch(q) {
		case (Question)`<Expr question> <Expr identifier> : <Type varType>`: {
			println(cst2ast(question));
			println(cst2ast(identifier));
			println(cst2ast(varType));
			println(q@\loc);
			//println(identifier);
			//println(cst2ast((Expr)`<Str question>`));
			//println(cst2ast((Expr)`<Id identifier>`));
			return simpleQuestion(cst2ast(question), cst2ast(identifier), cst2ast(varType), src=q@\loc);
		}
			//return simpleQuestion(cst2ast(question), cst2ast(identifier), cst2ast(varType), src=question@\loc);
		case (Question)`<Str question> <Id identifier> : <Type varType> = <Expr e>`:
			return computedQuestion(cst2ast(question), cst2ast(identifier), cst2ast(varType), cst2ast(e), src=question@\loc);
		case (Question)`{ <Question* questions> }`: 
			return block([]);
		case (Question)`if <Expr cond> { <Question* thenPart> } else { <Question* elsePart> }`:
			return ifThenElse(cst2ast(cond), [], []);
		case (Question)`if <Expr cond> { <Question* thenPart> }`:
			return ifThen(cst2ast(cond), []);
		default:
			throw "Unhandled question: <q>";
	}
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: {println(e); 
    return ref(id("<x>"), src=x@\loc);}
    case (Expr)`<Expr lhs> * <Expr rhs>`: return multiplication(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`! <Expr e>`: return negation(cst2ast(e), src=e@\loc);
    case (Expr)`<Expr lhs> / <Expr rhs>`: return division(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> + <Expr rhs>`: return addition(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> - <Expr rhs>`: return subtraction(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \< <Expr rhs>`: return smallerThan(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \> <Expr rhs>`: return greaterThan(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \<= <Expr rhs>`: return leq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \>= <Expr rhs>`: return geq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> == <Expr rhs>`: return eq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> != <Expr rhs>`: return neq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> && <Expr rhs>`: return and(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> || <Expr rhs>`: return or(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Bool b>`: return boolean(fromString("<b>"), src=b@\loc);
    case (Expr)`<Int i>`: return integer(toInt("<i>"), src=i@\loc);
    case (Expr)`<Str s>`: return string("<s>", src=s@\loc); 
    // etc.
    
    default: {println("test"); throw "Unhandled expression: <e>";}
  }
}

AType cst2ast(Type t) {
	switch (t) {
		case (Type)`boolean`: return boolean(src=t@\loc);
		case (Type)`integer`: return integer(src=t@\loc);
		case (Type)`string`: return string(src=t@\loc);
		default: throw "Unhandled type: <t>";
	}
}
