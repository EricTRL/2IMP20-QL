module Transform

import Syntax;
import Resolve;
import AST;
import IO;

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
  	for (AQuestion q <- flattenedForm.questions) {
  		println(q.cond);
  		println();
  	}
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
   return f; 
 } 
 
 
 

