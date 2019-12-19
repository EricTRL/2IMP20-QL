module Check

import AST;
import Resolve;
import Message; // see standard library
import IO;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;
  
str typeToStr(Type t) {
	switch(t) {
		case tint(): return "integer";
		case tbool(): return "boolean";
		case tstr(): return "string";
	}
	return "unknown";
}

Type ATypeToDataType(AType t) {
	switch(t) {
		case string(): return tstr();
		case integer(): return tint();
		case boolean(): return tbool();
		default: return tunknown();
	}
}

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  result = {};
  visit(f) {
  	case simpleQuestion(strng(str label), ref(AId id, src = loc u), AType varType, src = loc q): result = result + <q, id.name, "<label>", ATypeToDataType(varType)>;
    case computedQuestion(strng(str label), ref(AId id, src = loc u), AType varType, AExpr e, src = loc q): result = result + <q, id.name, "<label>", ATypeToDataType(varType)>; 
  }
  return result; 
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  result = {};
  for (AQuestion q <- f.questions) {
  	result = result + check(q, tenv, useDef);
  } 
  return result; 
}

// Produce an error if there are declared questions with the same name but different types.
set[Message] checkName(str name, AId id, Type t, AType var, loc def) {
	if (name == id.name) {
		if (t != ATypeToDataType(var)) {
			return {error("Another question has the same name but a different type", def)};
		}
	}
	return {};
}

// duplicate labels should trigger a warning.
set[Message] checkLabel(str label, str sq, loc def, loc qloc) {
    if (label == sq && def != qloc) {
		return { warning("There is another question with the same label", def) };
    }
    return {};
}

// Operations inside the Expression should have a valid type
set[Message] checkExprType(AExpr e, loc def, loc qloc, TEnv tenv, UseDef useDef) {
	if (def == qloc) {
		return check(e, tenv, useDef);
	}
	return {};
}

// the declared type computed questions should match the type of the expression.
set[Message] checkQuestionAndExprType(AExpr e, loc def, loc qloc, TEnv tenv, UseDef useDef, Type t) {
	if (def == qloc) {
		typeOfExpr = typeOf(e, tenv, useDef);
		if (typeOfExpr != t) {
			return { error("The expression type [\"<typeToStr(typeOfExpr)>\"] should match the question type [\"<typeToStr(t)>\"]", e.src) };
		}
	}
	return {};
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  	result = {};
  	switch(q) {  			
    	case simpleQuestion(strng(sq), ref(AId id), AType var, src = loc qloc): {
    		for (<loc def, str name, str label, Type t> <- tenv) {
    			result += checkName(name, id, t, var, def);
				result += checkLabel(label, sq, def, qloc);	
	    	}
		}
		case computedQuestion(strng(sq), ref(AId id), AType var, AExpr e, src = loc qloc): {
			for (<loc def, str name, str label, Type t> <- tenv) {
				result += checkName(name, id, t, var, def);
				result += checkLabel(label, sq, def, qloc);	
				result += checkExprType(e, def, qloc, tenv, useDef);
				result += checkQuestionAndExprType(e, def, qloc, tenv, useDef, t);
			} 
		}
		case ifThenElse(AExpr cond, list[AQuestion] thenpart, list[AQuestion] elsepart): { 
  			result += check(cond, tenv, useDef);
  			for (AQuestion question <- q.thenpart + q.elsepart) {
  				result += check(question, tenv, useDef);
  			}
  		}
		case ifThen(AExpr cond, list[AQuestion] questions): {
			result += check(cond, tenv, useDef);
  			for (AQuestion question <- q.questions) {
  				result += check(question, tenv, useDef);
  			}
  		}
  		case block(list[AQuestion] questions): {
  			for (AQuestion question <- q.questions) {
  				result += check(question, tenv, useDef);
  			}
  		}
  	}  
  return result; 
}

set[Message] checkExpr(set[AExpr] expr, TEnv tenv, UseDef useDef, set[Type] t, loc u) {
	msgs = {};
	for (AExpr e <- expr) {
		msgs += check(e, tenv, useDef);
		typeOfE = typeOf(e, tenv, useDef);
		if (!(typeOfE in t)) {
			msgs += { error("Expression contains incompatible types. Got [\"<typeToStr(typeOfE)>\"] expected one of <[typeToStr(expType) | (Type expType <- t)]>", u)};
		}
	}
	return msgs;
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(id(str x), src = loc u): {
      	msgs += { error("Undeclared question", u) | useDef[u] == {} };
  	}
  	case negation(AExpr e, src = loc u): {
  		msgs += checkExpr({e}, tenv, useDef, {tbool()}, u);
  	}
  	case multiplication(AExpr lhs, AExpr rhs, src = loc u): {
  		msgs += checkExpr({lhs, rhs}, tenv, useDef, {tint()}, u);
  	}
  	case division(AExpr lhs, AExpr rhs, src = loc u): {
  		msgs += checkExpr({lhs, rhs}, tenv, useDef, {tint()}, u);
  	}
	case addition(AExpr lhs, AExpr rhs, src = loc u): {
		msgs += checkExpr({lhs, rhs}, tenv, useDef, {tint()}, u);
	}
	case subtraction(AExpr lhs, AExpr rhs, src = loc u): {
  		msgs += checkExpr({lhs, rhs}, tenv, useDef, {tint()}, u);
  	}
  	case smallerThan(AExpr lhs, AExpr rhs, src = loc u): {
  		msgs += checkExpr({lhs, rhs}, tenv, useDef, {tint()}, u);
  	}
  	case greaterThan(AExpr lhs, AExpr rhs, src = loc u): {
  		msgs += checkExpr({lhs, rhs}, tenv, useDef, {tint()}, u);
  	}
  	case leq(AExpr lhs, AExpr rhs, src = loc u): {
  		msgs += checkExpr({lhs, rhs}, tenv, useDef, {tint()}, u);
  	}
  	case geq(AExpr lhs, AExpr rhs, src = loc u): {
  		msgs += checkExpr({lhs, rhs}, tenv, useDef, {tint()}, u);
  	}
  	case equal(AExpr lhs, AExpr rhs, src = loc u): {
  		msgs += checkExpr({lhs, rhs}, tenv, useDef, {tint(), tstr(), tbool()}, u);
  	}
  	case neq(AExpr lhs, AExpr rhs, src = loc u): {
  		msgs += checkExpr({lhs, rhs}, tenv, useDef, {tint(), tstr(), tbool()}, u);
  	}
  	case and(AExpr lhs, AExpr rhs, src = loc u): {
  		msgs += checkExpr({lhs, rhs}, tenv, useDef, {tbool()}, u);
  	}
  	case or(AExpr lhs, AExpr rhs, src = loc u): {
  		msgs += checkExpr({lhs, rhs}, tenv, useDef, {tbool()}, u);
  	}
  }
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
  	// ID checking
    case ref(id(str x), src = loc u): {  		
	  	if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
	    	return t;
	  	}
  	}
  	// Integer Methods
  	case multiplication(): {
  		return tint();
  	}
  	case division(): {
  		return tint();
  	}
  	case addition(AExpr lhs, AExpr rhs): {
  		return tint();
	}
	case subtraction(AExpr lhs, AExpr rhs): {
  		return tint();
	}
	// Boolean Methods
	case negation(): {
  		return tbool();
  	}
	case smallerThan(): {
		return tbool();
	}
	case greaterThan(): {
		return tbool();
	}
	case leq(): {
		return tbool();
	}
	case geq(): {
		return tbool();
	}
	case equal(): {
		return tbool();
	}
	case neq(): {
		return tbool();
	}
	case and(): {
		return tbool();
	}
	case or(): {
		return tbool();
	}
	// String Methods
		// String concatenation is not supported
			
	// Base Cases
	case bln(bool b): {
		return tbool();
	}	
	case strng(str s): {
		return tstr();
	}	
	case intgr(int i): {
		return tint();
	}
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(str x, src = loc u), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

