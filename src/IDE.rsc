module IDE

import Syntax;
import AST;
import CST2AST;
import Resolve;
import Check;
import Compile;
import Transform;
import IO;

import util::IDE;
import Message;
import ParseTree;

import util::Prompt;


private str MyQL ="MyQL";

anno rel[loc, loc] Tree@hyperlinks;

void main() {
  registerLanguage(MyQL, "myql", Tree(str src, loc l) {
    return parse(#start[Form], src, l);
  });
  
  contribs = {
    annotator(Tree(Tree t) {
      if (start[Form] pt := t) {
        AForm ast = cst2ast(pt);
        UseDef useDef = resolve(ast).useDef;
        set[Message] msgs = check(ast, collect(ast), useDef);
		
        return t[@messages=msgs][@hyperlinks=useDef];
      }
      return t[@messages={error("Not a form", t@\loc)}];
    }),
    
    builder(set[Message] (Tree t) {
      if (start[Form] pt := t) {
        AForm ast = cst2ast(pt);
        AForm flatForm = flatten(ast);
        UseDef useDef = resolve(ast).useDef;
        set[Message] msgs = check(ast, collect(ast), useDef);
        if (msgs == {}) {
          compile(ast);
        }
        return msgs;
      }
      return {error("Not a form", t@\loc)};
    }),
    
    popup(menu("Edit QL-file", [
        action("Compile and Flatten Form", void (Tree t, loc clickLocation) { flatten(t, clickLocation);}),
        action("Rename Selected Variable", void (Tree t, loc clickLocation) { rename(t, clickLocation);})
        //toggle("toggletest", bool () {return true;}, void (Tree t, loc clickLocation) { println("");})
    ]))
  };
  
  registerContributions(MyQL, contribs);
}


// Executes the Transform-flatten method, and does some checks to see if the result is valid
void flatten(Tree t, loc clickLocation) {
    if (start[Form] pt := t) {
        println("Flattening Form... (step 1/2)");
        AForm ast = cst2ast(pt);
        UseDef useDef = resolve(ast).useDef;
        
        // Prevent flattening a form with errors
        set[Message] msgs = check(ast, collect(ast), useDef);
        if (msgs != {}) {
            alert("Cannot Flatten and Compile a form with errors!");
            println("Cannot Flatten and Compile a form with errors!");
            return;
        }
                
        AForm flatForm = flatten(ast);
        flatForm.src = clickLocation.top;
        println("Form Flattened!\nCompiling Flattened Form... (step 2/2)");
        
        useDef = resolve(flatForm).useDef;
        msgs = check(flatForm, collect(ast), useDef);
        // Prevent compilation if errors are introduced
        if (msgs == {}) {
          // Compile modified file
          compile(flatForm);
          println("Flattened Form Compiled!");
        } else {
            alert("ERROR: Invalid form was generated!");
            println("ERROR: Invalid form was generated!");
            return;
        }
    }
}

str rename(Tree t, loc clickLocation) {    
    if (start[Form] pt := t) {
        println("Renaming Variable...");
        AForm ast = cst2ast(pt);
        UseDef useDef = resolve(ast).useDef;

        // Prevent renaming in a form with errors
        set[Message] msgs = check(ast, collect(ast), useDef);
        if (msgs != {}) {
            alert("Cannot Rename a Variable in a form with errors!");
            println("Cannot Rename a Variable in a form with errors!");
            return;
        }
        // Ask for user input
        str newName = prompt("Insert a new variable name:");
        start[Form] renamedForm;
        
        // Abort renaming if a parser error occurs
        try {
            renamedForm = rename(pt, clickLocation, newName, useDef);
        } catch ParseError(loc l): {
            alert("ERROR: Renaming into <newName> caused an error in the form! Renaming was aborted!");
            println("ERROR: Renaming into <newName> caused an error in the form! Renaming was aborted!");
            return;
        } catch: {
            // Abort if no variable was selected to rename
            alert("ERROR: Did not select a variable!");
            println("ERROR: Did not select a variable!");
            return;
        }

        AForm newForm = cst2ast(renamedForm);
        useDef = resolve(newForm).useDef;

        // Prevent renaming if that introduces new errors
        msgs = check(newForm, collect(newForm), useDef);
        if (msgs == {}) {       
            writeFile(clickLocation.top, unparse(renamedForm));
            println("Variable Renamed!");
        } else {
            alert("ERROR: Renaming into <newName> caused an error in the form! Renaming was aborted!");
            println("ERROR: Renaming into <newName> caused an error in the form! Renaming was aborted!");
            return;      
        }
    }
}
