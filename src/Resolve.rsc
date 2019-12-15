module Resolve

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

Use uses(AForm f) {
	//Loop over form (visit), check where identifiers (I.e. name) are used and link it to a location (with a relation)
	//Maybe we need to apply a strategy to distinguish places where they are used from where they are declared
  result = {};
  visit(f) {
  	case <Id x>: result = result + <x@\loc, "<x>">;
  	default: result = result;
  };
  return result; 
}

Def defs(AForm f) {
	//Loop over form (visit), check where identifiers (I.e. name) are defined (with a relation)
	//maybe through a strategy we can find distinguish places where they are declared from where they are used
  result = {};
  visit(f) {
    case <Id x>: result = result + <"<x>", x@\loc>;
    default: result = result; 
  }	
  return result; 
}