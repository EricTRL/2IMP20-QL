module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */
 
void compile(AForm f) {
    // Compile the QL-file to an HTML and Js file
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

//////////////////////////////////////////////////////////////////////////////////////
// HTML
//////////////////////////////////////////////////////////////////////////////////////

// Compiles a from to HTML
HTML5Node form2html(AForm f) {
    // Set the header (I.e. Make a Title and import jQuery and the compiled JS)
    HTML5Node head = head(  title("QL - <f.name>"),
                            script(src("https://ajax.aspnetcdn.com/ajax/jQuery/jquery-3.4.1.min.js")),
                            script(src("<f.src[extension="js"].top.file>")),
                            style(".hidden { display : none }"));
    
    bodyContent = [];
    println("----------\nGenerating Questionaire HTML...");
    int cnt = 0;
    // Generate the body (based on the form's questions)
    for (AQuestion q <- f.questions) {
        bodyContent += question2html(q, "<cnt>");
        cnt += 1;
    }
    println("Questionaire HTML was generated!\n");
    
  return html(head, body(bodyContent));
}

// Compiles a variable type to an HTML-widget and gives it a given Id
// editable Denotes wheter the widget can be edited by the user
HTML5Node type2Widget(str widgetId, AType t, bool editable) {
    str widgetType;
    widgetValue = [id(widgetId), class("question")];
    switch(t) {
        case string(): {
            widgetType = "text";
            widgetValue += [\value("")];
        }
        case boolean(): {
            widgetType = "checkbox";
            widgetValue += [\value("")];
        }
        case integer(): {
            widgetType = "number";
            widgetValue += [\value("0"), step("1")];
        }
        default: {
            println("ERROR. Unexpected AType <t> found!");
            return li("/* ERROR: Type could not be parsed! */");
        }
    }
    widgetValue += [\type(widgetType)];
    return editable ? input(widgetValue)
                    : input(widgetValue + [disabled("")]);
}

// Compiles a question to HTML
list[HTML5Node] question2html(AQuestion q, str cnt) {
    switch(q) {           
        case simpleQuestion(strng(sq), ref(AId id, src = loc u), AType var, src = loc qloc): {
            println("Generating question <id.name>...");
            return [p("<sq[1..-1]>", type2Widget("q_<cnt>", var, true))];
        }
        case computedQuestion(strng(sq), ref(AId id, src = loc u), AType var, AExpr e, src = loc qloc): {
            println("Generating question <id.name>...");
            return [p("<sq[1..-1]>", type2Widget("q_<cnt>", var, false))];
        }
        case ifThenElse(AExpr cond, list[AQuestion] thenpart, list[AQuestion] elsepart): { 
            println("Generating if-then-else-block...");
            ifContent = [];
            
            // Obtain all questions from the if-branch
            int cnt2 = 0;
            for (AQuestion question <- thenpart) {
                ifContent += question2html(question, "<cnt>_<cnt2>");
                cnt2 += 1;
            }
            
            // Obtain all quesitons from the else-branch
            elseContent = [];
            for (AQuestion question <- elsepart) {
                elseContent += question2html(question, "<cnt>_<cnt2>");
                cnt2 += 1;
            }
            
            // Store all questions in the if-branch in a single div,
            // and store all questions in the else-branch in another single div
            ifElseContent = [div([id("if_q_<cnt>")] + ifContent), div([id("else_q_<cnt>")] + elseContent)];
            return ifElseContent;
        }
        case ifThen(AExpr cond, list[AQuestion] questions): {
            println("Generating if-then-block...");
            ifContent = [];
            
            // Obtain all questions from the if-branch
            int cnt2 = 0;
            for (AQuestion question <- questions) {
                ifContent += question2html(question, "<cnt>_<cnt2>");
                cnt2 += 1;
            }
            
            // Storea all questions in the if-branch in a single div
            ifContent = [div([id("if_q_<cnt>")] + ifContent)];
            return ifContent;
        }
        case block(list[AQuestion] questions): { 
            println("Generating block...");  
            blockContent = [];
            
            // Obtain all questions from the block
            int cnt2 = 0;
            for (AQuestion question <- questions) {
                blockContent += question2html(question, "<cnt>_block_<cnt2>");
                cnt2 += 1;
            }
            return blockContent;
        }
        default: {
            println("ERROR. Unexpected AQuestion <q> found!");
            return li("/* ERROR: Question could not be parsed! */");
        }
    }
}

//////////////////////////////////////////////////////////////////////////////////////
// Javascript
//////////////////////////////////////////////////////////////////////////////////////

// Compiles a given form to Javascript
str form2js(AForm f) {
    println("----------\nGenerating form...");
    
    // Will contain the update function that re-evaluates the form
    str js = "// This file was generated autmatically from the <f.name> form\n";
    js += "$(\"document\").ready(function(){\n";
    js += "function update() {\n";
    js += "\tconsole.log(\"Updated the Questionaire!\");\n";
    
    // Generate the Js-code based on the form
    int cnt = 0;
    for (AQuestion q <- f.questions) {
        js += question2js(q, "<cnt>");
        cnt += 1;
    }
    js += "}\n\n";
    
    // Create a function that hides an HTML-element (by adding a class)
    js += "function setHide(id, val){\n";
    js += "\tif (val) {\n";
    js += "\t\t$(id).addClass(\"hidden\");\n";
    js += "\t} else {\n";
    js += "\t\t$(id).removeClass(\"hidden\");\n";
    js += "\t}\n";
    js += "}\n\n";    
    
    // Re-evaluate the form when a question answer changes
    js += "$(\".question\").change(function() {\n";
    js +=      "\tupdate();\n";
    js +=  "});\n\n";
    
    // Evaluate the form upon load    
    js += "update();\n";
    println("Form was generated!\n");
    
    return js + "});\n";
}

// Gets the Javascript default value (in the form of a string) for a given type
str getjsDefaultValue(AType t) {
    switch(t) {
        case string(): {
            return "\"\"";
        }
        case boolean(): {
            return "false";
        }
        case integer(): {
            return "0";
        }
        default: {
            println("ERROR. Unexpected AType <t> found!");
            return "/* ERROR: Type could not be parsed! */";
        }
    }
}

// Compiles getting a variable of a given type to jQuery code
str getjsWidget(str name, AType t) {
    switch(t) {
        case string(): {
            return "$(\"<name>\").val();";
        }
        case boolean(): {
            // Note: Checking if a checkbox is checked is done differently than for other input fields
            return "$(\"<name>\").is(\":checked\");";
        }
        case integer(): {
            return "$(\"<name>\").val();";
        }
        default: {
            println("ERROR. Unexpected AType <t> found!");
            return "/* ERROR: Type could not be parsed! */";
        }
    }
}

// Compiles setting a variable of a given type to jQuery code
str setjsWidget(str name, AType t, str val) {
    switch(t) {
        case string(): {
            return "$(\"<name>\").val(<val>);";
        }
        case boolean(): {
            // Note: (Un)checking a checkbox is done differently than for other input fields
            return "$(\"<name>\").prop(\"checked\", <val>);";
        }
        case integer(): {
            return "$(\"<name>\").val(<val>);";
        }
        default: {
            println("ERROR. Unexpected AType <t> found!");
            return "/* ERROR: Type could not be parsed! */";
        }
    }
}

// Compiles a given question to Js
str question2js(AQuestion q, str cnt) {
    switch(q) {           
        case simpleQuestion(strng(sq), ref(AId id, src = loc u), AType var, src = loc qloc): {
            println("Generating question <id.name>...");            
            
            // Generate update-code for the question
            str update = "\t//<sq>\n";
            update += "\tvar <id.name> = <getjsWidget("#q_<cnt>", var)>\n"; 
            
            return update;
        }
        case computedQuestion(strng(sq), ref(AId id, src = loc u), AType var, AExpr e, src = loc qloc): {
            println("Generating question <id.name>...");
                        
            // Generate update-code for the question
            str update = "\t//<sq[1..-1]>\n";
            update += "\tvar <id.name> = <expression2js(e)>; \n";
            update += "\t<setjsWidget("#q_<cnt>", var, id.name)>\n";
            
            return update;
        }
        case ifThenElse(AExpr cond, list[AQuestion] thenpart, list[AQuestion] elsepart): { 
            println("Generating if-then-else-block...");
            str ifblock = "";
            
            // Show and hide the if and else branch respectively if the guard is true
            ifblock += "if (<expression2js(cond)>) { \n";
            ifblock += "\tsetHide(\"#if_q_<cnt>\", false);\n";
            ifblock += "\tsetHide(\"#else_q_<cnt>\", true);\n";
            
            // Compile all questions in the if-branch to Js
            int cnt2 = 0;
            for (AQuestion question <- thenpart) {
                ifblock += question2js(question, "<cnt>_<cnt2>");
                cnt2 += 1;
            }
            ifblock += "} else { \n";
            
            // Hide and show the if and else branch respectively if the guard is false
            ifblock += "\tsetHide(\"#if_q_<cnt>\", true);\n";
            ifblock += "\tsetHide(\"#else_q_<cnt>\", false);\n";
            
            // Compile all questions in the else-branch to Js
            for (AQuestion question <- elsepart) {
                ifblock += question2js(question, "<cnt>_<cnt2>");
                cnt2 += 1;
            }
            ifblock += "} \n";
            return ifblock; 
        }
        case ifThen(AExpr cond, list[AQuestion] questions): {
            println("Generating if-then-block...");
            str ifelseblock = "";
            
            // Show the if branch if the guard is true
            ifelseblock += "if (<expression2js(cond)>) { \n";
            ifelseblock += "\tsetHide(\"#if_q_<cnt>\", false);\n";
            
            // Compile all questions in the if-branch to Js
            int cnt2 = 0;
            for (AQuestion question <- questions) {
                ifelseblock += question2js(question, "<cnt>_<cnt2>");
                cnt2 += 1;
            }
            ifelseblock += "} else { \n";
            
            // Hide the if branch if the guard is false
            ifelseblock += "\tsetHide(\"#if_q_<cnt>\", true);\n";
            
            ifelseblock += "} \n";
            return ifelseblock;
        }
        case block(list[AQuestion] questions): { 
            println("Generating block...");  
            str block = ""; //"{ \n";
            int cnt2 = 0;
            // Compile all questions in the block
            for (AQuestion question <- questions) {
                block += question2js(question, "<cnt>_<cnt2>");
                cnt2 += 2;
            }
            return ifblock;
        }
        default: {
            println("ERROR. Unexpected AQuestion <q> found!");
            return <"/* ERROR: Question could not be parsed! */", "">;
        }
    }
}

// Compiles an expression to Js
str expression2js(AExpr e) {
    switch (e) {
        case ref(id(str x), src = loc u): {
            return "<x>";
        }
        case negation(AExpr e, src = loc u): {
            return "(!<expression2js(e)>)";
        }
        case multiplication(AExpr lhs, AExpr rhs, src = loc u): {
            return "(<expression2js(lhs)> * <expression2js(rhs)>)";
        }
        case division(AExpr lhs, AExpr rhs, src = loc u): {
            return "(<expression2js(lhs)> / <expression2js(rhs)>)";
        }
        case addition(AExpr lhs, AExpr rhs, src = loc u): {
            return "(<expression2js(lhs)> + <expression2js(rhs)>)";
        }
        case subtraction(AExpr lhs, AExpr rhs, src = loc u): {
            return "(<expression2js(lhs)> - <expression2js(rhs)>)";
        }
        case smallerThan(AExpr lhs, AExpr rhs, src = loc u): {
            return "(<expression2js(lhs)> \< <expression2js(rhs)>)";
        }
        case greaterThan(AExpr lhs, AExpr rhs, src = loc u): {
            return "(<expression2js(lhs)> \> <expression2js(rhs)>)";
        }
        case leq(AExpr lhs, AExpr rhs, src = loc u): {
            return "(<expression2js(lhs)> \<= <expression2js(rhs)>)";
        }
        case geq(AExpr lhs, AExpr rhs, src = loc u): {
            return "(<expression2js(lhs)> \>= <expression2js(rhs)>)";
        }
        case equal(AExpr lhs, AExpr rhs, src = loc u): {
            // Javascript uses === for strict type checking. E.g. comparing a boolean to an integer results in false
            return "(<expression2js(lhs)> === <expression2js(rhs)>)";    
        }
        case neq(AExpr lhs, AExpr rhs, src = loc u): {
            // Javascript uses !== for strict type checking. E.g. comparing a boolean to an integer results in true
            return "(<expression2js(lhs)> !== <expression2js(rhs)>)";   
        }
        case and(AExpr lhs, AExpr rhs, src = loc u): {
            return "(<expression2js(lhs)> && <expression2js(rhs)>)";   
        }
        case or(AExpr lhs, AExpr rhs, src = loc u): {
            return "(<expression2js(lhs)> || <expression2js(rhs)>)";   
        }
        // String Methods
            // String concatenation is not supported  
        // Base Cases
        case bln(bool b): {
            return "<b ? "true" : "false">";
        }   
        case strng(str s): {
            //Note: s already has double-quotes around it
            return "<s>";
        }   
        case intgr(int i): {
            return "<i>";
        }
        default: {
            println("ERROR. Unexpected AExpr <e> found!");
            return "/* ERROR! Expression could not be parsed! */";
        }
    }
}
