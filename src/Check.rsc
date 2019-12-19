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
  			for (AQuestion question <- q.thenpart + q.elsepart) {
  				result += check(question, tenv, useDef);
  			}
  		}
		default: { // ifThen and block
  			for (AQuestion question <- q.questions) {
  				result += check(question, tenv, useDef);
  			}
  		}
  	}  
  return result; 
}

set[Message] exprTypeError(set[Type] t, AExpr e, TEnv tenv, UseDef useDef, loc u) {
	typeOfExpr = typeOf(e, tenv, useDef);
	if (!(typeOfExpr in t)) {
		return {error("Expression contains incompatible types. Got [\"<typeToStr(typeOfExpr)>\"] expected one of <[typeToStr(expType) | (Type expType <- t)]>", u)};
	}
	return {};
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(str x, src = loc u):
      	msgs += { error("Undeclared question", u) | useDef[u] == {} };
	case addition(_, _, src = loc u): {
		msgs += exprTypeError({tint()}, e, tenv, useDef, u);
	}
	case subtraction(_, _, src = loc u): {
		msgs += exprTypeError({tint()}, e, tenv, useDef, u);
	}
	case multiplication(_, _, src = loc u): {
		msgs += exprTypeError({tint()}, e, tenv, useDef, u);
	}
	case division(_, _, src = loc u): {
		msgs += exprTypeError({tint()}, e, tenv, useDef, u);
	}
	case smallerThan(_, _, src = loc u): {
		msgs += exprTypeError({tint()}, e, tenv, useDef, u);
	}
	case greaterThan(_, _, src = loc u): {
		msgs += exprTypeError({tint()}, e, tenv, useDef, u);
	}
	case leq(_, _, src = loc u): {
		msgs += exprTypeError({tint()}, e, tenv, useDef, u);
	}
	case geq(_, _, src = loc u): {
		msgs += exprTypeError({tint()}, e, tenv, useDef, u);
	}
	case and(_, _, src = loc u): {
		msgs += exprTypeError({tint()}, e, tenv, useDef, u);
	}
	case or(_, _, src = loc u): {
		msgs += exprTypeError({tbool()}, e, tenv, useDef, u);
	}
	case negation(_, _, src = loc u): {
		msgs += exprTypeError({tbool()}, e, tenv, useDef, u);
	}
	case equal(_, _, src = loc u): {
		msgs += exprTypeError({tint(), tbool(), tstr()}, e, tenv, useDef, u);
	}
	case neq(_, _, src = loc u): {
		msgs += exprTypeError({tint(), tbool(), tstr()}, e, tenv, useDef, u);
	}
  }
  return msgs; 
}

Type doubleType(Type t, Type returnType, AExpr lhs, AExpr rhs, TEnv tenv, UseDef useDef) {
	lhsType = typeOf(lhs, tenv, useDef);
	if (lhsType == t && lhsType == typeOf(rhs, tenv, useDef)) {
		return returnType;
	}
	return tunknown();
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
  	// ID checking
    case ref(id(str x), src = loc u): {  		
	  	if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
	  		println("???");
	    	return t;
	  	}
  	}
    // Integer Methods
  	case addition(AExpr lhs, AExpr rhs): {
  		return doubleType(tint(), tint(), lhs, rhs, tenv, useDef);
	}
	case subtraction(AExpr lhs, AExpr rhs): {
  		return doubleType(tint(), tint(), lhs, rhs, tenv, useDef);
	}
	case multiplication(AExpr lhs, AExpr rhs): {
  		return doubleType(tint(), tint(), lhs, rhs, tenv, useDef);
	}
	case division(AExpr lhs, AExpr rhs): {
  		return doubleType(tint(), tint(), lhs, rhs, tenv, useDef);
	}
	case smallerThan(AExpr lhs, AExpr rhs): {
  		return doubleType(tint(), tbool(), lhs, rhs, tenv, useDef);
	}
	case greaterThan(AExpr lhs, AExpr rhs): {
  		return doubleType(tint(), tbool(), lhs, rhs, tenv, useDef);
	}
	case leq(AExpr lhs, AExpr rhs): {
  		return doubleType(tint(), tbool(), lhs, rhs, tenv, useDef);
	}
	case geq(AExpr lhs, AExpr rhs): {
  		return doubleType(tint(), tbool(), lhs, rhs, tenv, useDef);
	}
	// Boolean Methods
	case and(AExpr lhs, AExpr rhs): {
  		return doubleType(tbool(), tbool(), lhs, rhs, tenv, useDef);
	}
	case or(AExpr lhs, AExpr rhs): {
  		return doubleType(tbool(), tbool(), lhs, rhs, tenv, useDef);
	}
	case negation(AExpr expr): {
		// Special case: No left hand side or right hand side
		if (typeOf(expr, tenv, useDef) == tbool()) {
			return tbool();
		}
	}
	// String Methods
		// String concatenation is not supported
		// Lexicographical comparison of strings is not supported
		
	// Boolean, String, or Integer Methods
	case equal(AExpr lhs, AExpr rhs): {
		lhsType = typeOf(lhs, tenv, useDef);
		if (lhsType == typeOf(rhs, tenv, useDef)) {
			return tbool();
		}
	}
	case neq(AExpr lhs, AExpr rhs): {
		lhsType = typeOf(lhs, tenv, useDef);
		if (lhsType == typeOf(rhs, tenv, useDef)) {
			return tbool();
		}
	}
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
	default: {
		println("here <e>");
		println("None of the above");
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
 
 

