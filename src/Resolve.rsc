module Resolve
import IO;
import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

//Create a mapping between identifiers (I.e. names) and,
//the locations where they are used
Use uses(AForm f) {
	result = {};
	visit(f) {
		case ref(AId id, src = loc u): result = result + <u, "<id.name>">;
	};
	return result; 
}

//Create a mapping between identifiers (I.e. names) and,
//the location of the question in which they are defined
Def defs(AForm f) {
	result = {};
	visit(f) {
		case simpleQuestion(AExpr x, ref(AId id, src = loc u), AType varType, src = loc q): result = result + <"<id.name>", q>;
		case computedQuestion(AExpr x, ref(AId id, src = loc u), AType varType, AExpr e, src = loc q): result = result + <"<id.name>", q>;
	}	
  return result; 
}