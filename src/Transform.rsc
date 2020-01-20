module Transform

import Syntax;
import Resolve;
import AST;
import IO;
import CST2AST;
import ParseTree;
import Node;
import Exception;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
	list[AQuestion] flattenedQuestions = [];
	for (AQuestion q <- f.questions) {
  		flattenedQuestions = flattenedQuestions + flatten(q, bln(true));
  	} 
  	AForm flattenedForm = form(f.name, flattenedQuestions);
	return flattenedForm; 
}

list[AQuestion] flatten(AQuestion q, AExpr guard) {
	flattenedQuestion = [];
	switch(q) {  			
    	case simpleQuestion(strng(sq), ref(AId id, src = loc u), AType var, src = loc qloc): {
    		flattenedQuestion += ifThen(guard, [q]);
		}
		case computedQuestion(strng(sq), ref(AId id, src = loc u), AType var, AExpr e, src = loc qloc): {
			flattenedQuestion += ifThen(guard, [q]);
		}
		case ifThenElse(AExpr cond, list[AQuestion] thenpart, list[AQuestion] elsepart): { 
			for (AQuestion question <- thenpart) {
				flattenedQuestion += flatten(question, and(guard, cond));
			}
			
			for (AQuestion question <- elsepart) {
				flattenedQuestion += flatten(question, and(guard, negation(cond)));
			}
  		}
		case ifThen(AExpr cond, list[AQuestion] questions): {
			for (AQuestion question <- questions) {
				flattenedQuestion += flatten(question, and(guard, cond));
			}
  		}
  		case block(list[AQuestion] questions): {
  			for (AQuestion question <- questions) {
				flattenedQuestion += flatten(question, guard);
			}
  		}
  	}
	return flattenedQuestion;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
    // Stores the location where the variable is defined
 	loc definitionLocation = |tmp:///|;
 	
 	// Find the location where the variable is defined 
 	for (<loc use, loc def> <- useDef) {
        // useOrDef location should approximately equal
        if (use.offset <= useOrDef.offset && useOrDef.offset + useOrDef.length <= use.offset + use.length) {
            definitionLocation = def;
            break;
        }
 	}
 	
 	// If the location is still undefined, then an invalid location was passed
 	if (definitionLocation == |tmp:///|) {
 		throw NoSuchElement(useOrDef);
 	}
 	
 	// Store the locations where the variable is used and defined in a list
 	list[loc] usesAndDefs = [definitionLocation];
 	for (<loc use, definitionLocation> <- useDef) {
 		usesAndDefs += use;
 	}
 	
 	// For each variable, call method refactorId
 	f = visit(f) {           
        case Id id => refactorId(id, "<newName>", usesAndDefs)
    }
 	return f; 
 } 
 
 // If variable id is in the list of locations, we rename the Id to the new name,
 // else we keep the old id
 Id refactorId(Id id, str newName, list[loc] usesAndDefs) {
    
	if (id@\loc in usesAndDefs) {
	   	Id newId = parse(#Id, "<newName>");
		newId = setAnnotations(newId, ("loc": id@\loc));
		return newId;
	} else {
		return id;
	}
 }
 
 
 

