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

Type ATypeToDataType(AType t) {
	switch(t) {
		case string(): return tstr();
		case integer(): return tint();
		case boolean(): return tstr();
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

void checkExprType() {

}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  	result = {};
  	switch(q) {
    	case simpleQuestion(strng(sq), ref(AId id), AType var, src = loc qloc): {
    		println("simple");
    		for (<loc def, str name, str label, Type t> <- tenv) {
    			result += checkName(name, id, t, var, def);
				result += checkLabel(label, sq, def, qloc);	
	    	}
		}
		//case computedQuestion(strng(sq), ref(AId id), AType var, AExpr e, src = loc qloc): {
		//	println("computed");
		//	for (<loc def, str name, str label, Type t> <- tenv) {
		//		result += checkName(name, id, t, var, def);
		//		result += checkLabel(label, sq, def, qloc);	
		//		// the declared type computed questions should match the type of the expression.
		//		if (def == qloc) {
		//			println(e);
		//			println(ATypeToDataType(e));
		//			if (ATypeToDataType(e) != t) {
		//				result = result + error("The expression type should match the question type");
		//			}
		//		}
		//	} 
		//}
  	}
    
  
  return result; 
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(str x, src = loc u):
      msgs += { error("Undeclared question", u) | useDef[u] == {} };

    // etc.
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(str x, src = loc u):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case negation(AExpr e, src = loc u): { return t; }
    case multiplication(AExpr lhs, AExpr rhs): { return t;}
    case division(AExpr lhs, AExpr rhs): { return t;}
    case addition(AExpr lhs, AExpr rhs): { return t; }
    case subtraction(AExpr lhs, AExpr rhs): {return t;}
    case smallerThan(AExpr lhs, AExpr rhs): {return t;}
    case greaterThan(AExpr lhs, AExpr rhs): {return t;}
    case leq(AExpr lhs, AExpr rhs): {return t;}
    case geq(AExpr lhs, AExpr rhs): {return t;}
    case equal(AExpr lhs, AExpr rhs): {return t;}
    case neq(AExpr lhs, AExpr rhs): {return t;}
    case and(AExpr lhs, AExpr rhs): {return t;}
    case or(AExpr lhs, AExpr rhs): {return t;}
    case bln(bool b): {return t;}
    case intgr(int i): {return t;}
    case strng(str s): {return t;}
    // etc.
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
 
 

