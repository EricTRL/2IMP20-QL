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


  return {}; 
}

Def defs(AForm f) {
	//Loop over form (visit), check where identifiers (I.e. name) are defined (with a relation)
  return {}; 
}