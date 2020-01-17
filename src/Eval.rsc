module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);

Value getDefaultValue(AType t) {
    switch(t) {
        case string(): return vstr("");
        case integer(): return vint(0);
        case boolean(): return vbool(false);
        default: return vint(0);
    }
}

  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
    result = ();
    visit(f) {
        case simpleQuestion(strng(str label), ref(AId id, src = loc u), AType varType, src = loc q):
            result = result + ("<label>": getDefaultValue(varType));
        case computedQuestion(strng(str label), ref(AId id, src = loc u), AType varType, AExpr e, src = loc q):
            result = result + ("<label>": getDefaultValue(varType)); 
    }
    return result; 
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
    println(venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
	for (AQuestion q <- f.questions) {
		venv = eval(q, inp, venv);
	}
	return venv; 
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  
  switch(q) {           
    case simpleQuestion(strng(sq), ref(AId id, src = loc u), AType var, src = loc qloc): {
        venv += eval(q.question, inp, venv); // evaluate the expression
    }
    case computedQuestion(strng(sq), ref(AId id, src = loc u), AType var, AExpr e, src = loc qloc): {
        venv += eval(q.question, inp, venv); // evaluate the expression
    }
    case ifThenElse(AExpr cond, list[AQuestion] thenpart, list[AQuestion] elsepart): { 
        if (eval(cond, venv) == vbool(true)) {
            for (AQuestion question <- thenpart) {
                venv += eval(question, inp, venv); // TODO: inp klopt hier wss niet
            }
        } else {
            for (AQuestion question <- elsepart) {
                venv += eval(question, inp, venv); // TODO: inp klopt hier wss niet
            }
        }
    }
    case ifThen(AExpr cond, list[AQuestion] questions): {
        if (eval(cond, venv) == vbool(true)) {
            for (AQuestion question <- questions) {
                venv += eval(question, inp, venv); // TODO: inp klopt hier wss niet
            }
        }
    }
    case block(list[AQuestion] questions): {   
        // TODO: Handle scoping? I.e. questions defined here do not affect the VEnv outside the block     
        for (AQuestion question <- questions) {
            venv += eval(question, inp, venv); // TODO: inp klopt hier wss niet
        }
    }
  } 
  
  return venv; 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x), src = loc u): {
        return venv[x];
    }
    case negation(AExpr e, src = loc u): {
        //return tbool(!eval(e, venv)); // TODO: alternative?
        return vbool(eval(e, venv) == vbool(false));
    }
    case multiplication(AExpr lhs, AExpr rhs, src = loc u): {
        return vint(eval(lhs, venv) * eval(rhs, venv));
    }
    case division(AExpr lhs, AExpr rhs, src = loc u): {
        return vint(eval(lhs, venv) / eval(rhs, venv));
    }
    case addition(AExpr lhs, AExpr rhs, src = loc u): {
        return vint(eval(lhs, venv) + eval(rhs, venv));
    }
    case subtraction(AExpr lhs, AExpr rhs, src = loc u): {
        return vint(eval(lhs, venv) - eval(rhs, venv));
    }
    case smallerThan(AExpr lhs, AExpr rhs, src = loc u): {
        return vbool(eval(lhs, venv) < eval(rhs, venv));
    }
    case greaterThan(AExpr lhs, AExpr rhs, src = loc u): {
        return vbool(eval(lhs, venv) > eval(rhs, venv));
    }
    case leq(AExpr lhs, AExpr rhs, src = loc u): {
        return vbool(eval(lhs, venv) <= eval(rhs, venv));
    }
    case geq(AExpr lhs, AExpr rhs, src = loc u): {
        return vbool(eval(lhs, venv) >= eval(rhs, venv));
    }
    //For equal(==) and neq(!=) it is possible to compare arguments of different types, 
    //though depending on the implementation this will in (almost) all cases evaluate to false
    // TODO: wss moeten we strict type checking doen. Dus int != bool != string (dus "0" != 0 != false)
    case equal(AExpr lhs, AExpr rhs, src = loc u): {
        return vbool(eval(lhs, venv) == eval(rhs, venv));    
    }
    case neq(AExpr lhs, AExpr rhs, src = loc u): {
        return vbool(eval(lhs, venv) != eval(rhs, venv));   
    }
    case and(AExpr lhs, AExpr rhs, src = loc u): {
        return vbool(eval(lhs, venv) && eval(rhs, venv));   
    }
    case or(AExpr lhs, AExpr rhs, src = loc u): {
        return vbool(eval(lhs, venv) || eval(rhs, venv));   
    }
    // String Methods
        // String concatenation is not supported  
    // Base Cases
    case bln(bool b): {
        return vbool(b);
    }   
    case strng(str s): {
        return vstr(s);
    }   
    case intgr(int i): {
        return vint(i);
    }    
    default: throw "Unsupported expression <e>";
  }
}