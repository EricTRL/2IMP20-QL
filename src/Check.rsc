module Check

import AST;
import Resolve;
import Message; // see standard library
import IO;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown();

//Transform a data Type to a string, used for specification in error messages
str typeToStr(Type t) {
	switch(t) {
		case tint(): return "integer";
		case tbool(): return "boolean";
		case tstr(): return "string";
	}
	return "unknown";
}

//Convert AType to the needed data Types
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
//Add all questions into the Type Environment, excluding the if (else) / block constructs
//Note that all the questions within the constructs are added to the Type Environment
TEnv collect(AForm f) {
  result = {};
  visit(f) {
  	case simpleQuestion(strng(str label), ref(AId id, src = loc u), AType varType, src = loc q):
  		result = result + <q, id.name, "<label>", ATypeToDataType(varType)>;
    case computedQuestion(strng(str label), ref(AId id, src = loc u), AType varType, AExpr e, src = loc q):
    	result = result + <q, id.name, "<label>", ATypeToDataType(varType)>; 
  }
  return result; 
}

//For all questions in the form, check for errors / warnings
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

// If there are duplicate labels they should trigger a warning.
set[Message] checkLabel(str label, str sq, loc def, loc qloc) {
    if (label == sq && def != qloc) {
		return { warning("There is another question with the same label", def) };
    }
    return {};
}

// Operations inside the Expression should have a valid type (checked via the check-method)
// the declared type of expressions should match the type of the computed question.
set[Message] checkQuestionAndExprType(AExpr e, Type t, TEnv tenv, UseDef useDef) {
	msgs = {};
		msgs += check(e, tenv, useDef);
		typeOfExpr = typeOf(e, tenv, useDef);
		if (typeOfExpr != t) {
			msgs += { error("The expression type [\"<typeToStr(typeOfExpr)>\"] should match the question type [\"<typeToStr(t)>\"]", e.src) };
		}
	return msgs;
}

//Check whether the names of questions are equal to reserved keywords,
//in which case we give an error
set[Message] checkKeyWords(AId id, loc u) {
	if (id.name in {"true", "false", "if", "else"}) {
		return { error("<id.name> is a reserved keyword", u) };
	}
	return {};
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  	result = {};
  	switch(q) {  			
    	case simpleQuestion(strng(sq), ref(AId id, src = loc u), AType var, src = loc qloc): {
    		result += checkKeyWords(id, u);
    		for (<loc def, str name, str label, Type t> <- tenv) {
    			//For all questions except for the one we are currently verifying
    			if (def != qloc) {
    				//Check for duplicate name with different type
    				result += checkName(name, id, t, var, def);
    				//Check for duplicate labels
					result += checkLabel(label, sq, def, qloc);	
				}		    	
	    	}
		}
		case computedQuestion(strng(sq), ref(AId id, src = loc u), AType var, AExpr e, src = loc qloc): {
			result += checkKeyWords(id, u);
			for (<loc def, str name, str label, Type t> <- tenv) {
				//For all questions except for the one we are currently verifying
				if (def != qloc) {
					//Check for duplicate name with different type
					result += checkName(name, id, t, var, def);
					//Check for duplicate labels
					result += checkLabel(label, sq, def, qloc);	
				} else {//For the one we are currently verifying
					//Check whether the expression type matches the question type, 
					//and check whether the expression contains compatible types
					result += checkQuestionAndExprType(e, t, tenv, useDef);
				}
			} 
		}
		case ifThenElse(AExpr cond, list[AQuestion] thenpart, list[AQuestion] elsepart): { 
			//Check whether the condition is of type boolean and,
			//whether the expression contains compatible types
  			result += checkQuestionAndExprType(cond, tbool(), tenv, useDef);
  			//Recursively check all questions within the if and else construct for errors/warnings
  			for (AQuestion question <- q.thenpart + q.elsepart) {
  				result += check(question, tenv, useDef);
  			}
  		}
		case ifThen(AExpr cond, list[AQuestion] questions): {
			//Check whether the condition is of type boolean and,
			//whether the expression contains compatible types
			result += checkQuestionAndExprType(cond, tbool(), tenv, useDef);
			//Recursively check all questions within the if construct for errors/warnings
  			for (AQuestion question <- q.questions) {
  				result += check(question, tenv, useDef);
  			}
  		}
  		case block(list[AQuestion] questions): {
  			//Recursively check all questions within the block construct for errors/warnings
  			for (AQuestion question <- q.questions) {
  				result += check(question, tenv, useDef);
  			}
  		}
  	}  
  return result; 
}

//For all the expressions in the set expr, check the operand compatability recursively
//If the type of an expression does not match one of the expected types in t, then add an error
set[Message] checkExpr(set[AExpr] expr, TEnv tenv, UseDef useDef, set[Type] t, loc u) {
	msgs = {};
	for (AExpr e <- expr) {
		msgs += check(e, tenv, useDef);
		typeOfE = typeOf(e, tenv, useDef);
		if (!(typeOfE in t)) {
			msgs += { error("Expression contains incompatible types. Got [\"<typeToStr(typeOfE)>\"] expected one of <[typeToStr(expType)
				| (Type expType <- t)]>", u)};
		}
	}
	return msgs;
}

// Check operand compatibility with operators recursively.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(id(str x), src = loc u): {
      	msgs += { error("Undeclared question [\"<x>\"]", u) | useDef[u] == {} };
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
  	//For equal(==) and neq(!=) it is possible to compare arguments of different types, 
	//though depending on the implementation this will in (almost) all cases evaluate to false
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

//Given an expression e, return the expected type for that expression
Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
  	// ID checking
    case ref(id(str x), src = loc u): {  		
	  	if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
	    	return t;
	  	}
  	}
  	// Integer Methods
  	case multiplication(AExpr lhs, AExpr rhs): {
  		return tint();
  	}
  	case division(AExpr lhs, AExpr rhs): {
  		return tint();
  	}
  	case addition(AExpr lhs, AExpr rhs): {
  		return tint();
	}
	case subtraction(AExpr lhs, AExpr rhs): {
  		return tint();
	}
	// Boolean Methods
	case negation(AExpr e): {
  		return tbool();
  	}
	case smallerThan(AExpr lhs, AExpr rhs): {
		return tbool();
	}
	case greaterThan(AExpr lhs, AExpr rhs): {
		return tbool();
	}
	case leq(AExpr lhs, AExpr rhs): {
		return tbool();
	}
	case geq(AExpr lhs, AExpr rhs): {
		return tbool();
	}
	case equal(AExpr lhs, AExpr rhs): {
		return tbool();
	}
	case neq(AExpr lhs, AExpr rhs): {
		return tbool();
	}
	case and(AExpr lhs, AExpr rhs): {
		return tbool();
	}
	case or(AExpr lhs, AExpr rhs): {
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

 

