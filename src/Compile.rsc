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
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

//////////////////////////////////////////////////////////////////////////////////////
// HTML
//////////////////////////////////////////////////////////////////////////////////////

HTML5Node form2html(AForm f) {

    // Set the header (I.e. Make a Title and import jQuery and the JS)
    HTML5Node head = head(  title("QL - <f.name>"),
                            script(src("https://ajax.aspnetcdn.com/ajax/jQuery/jquery-3.4.1.min.js")),
                            script(src("<f.src[extension="js"].top.file>")),
                            style(".hidden { display : none }"));
    
    bodyContent = [];
    println("----------\nGenerating Questionaire HTML...");
    int cnt = 0;
    for (AQuestion q <- f.questions) {
        bodyContent += question2html(q, "<cnt>");
        cnt += 1;
    }
    println("Questionaire HTML was generated!\n");
    
  return html(head, body(bodyContent));
}

HTML5Node type2Widget(str widgetId, AType t, bool editable) {
    str widgetType;
    widgetValue = [id(widgetId)];
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

list[HTML5Node] question2html(AQuestion q, str cnt) {
    switch(q) {           
        case simpleQuestion(strng(sq), ref(AId id, src = loc u), AType var, src = loc qloc): {
            println("Generating question <id.name>...");
            return [p("<sq[1..-1]>", type2Widget("q_<cnt>", var, true))]; // TODO: run JS
        }
        case computedQuestion(strng(sq), ref(AId id, src = loc u), AType var, AExpr e, src = loc qloc): {
            println("Generating question <id.name>...");
            return [p("<sq[1..-1]>", type2Widget("q_<cnt>", var, false))]; // TODO: run JS
        }
        case ifThenElse(AExpr cond, list[AQuestion] thenpart, list[AQuestion] elsepart): { 
            println("Generating if-then-else-block...");
            ifContent = [];
            
            int cnt2 = 0;
            for (AQuestion question <- thenpart) {
                ifContent += question2html(question, "<cnt>_<cnt2>");
                cnt2 += 1;
            }
            
            elseContent = [];
            for (AQuestion question <- elsepart) {
                elseContent += question2html(question, "<cnt>_<cnt2>");
                cnt2 += 1;
            }
            
            ifElseContent = [div([id("if_q_<cnt>")] + ifContent), div([id("else_q_<cnt>")] + elseContent)];
            return ifElseContent;
        }
        case ifThen(AExpr cond, list[AQuestion] questions): {
            println("Generating if-then-block...");
            ifContent = [];
            
            int cnt2 = 0;
            for (AQuestion question <- questions) {
                ifContent += question2html(question, "<cnt>_<cnt2>");
                cnt2 += 1;
            }
            ifContent = [div([id("if_q_<cnt>")] + ifContent)];
            return ifContent;
            // TODO: RUN JS
            // TODO: condition checking
        }
        case block(list[AQuestion] questions): { 
            println("Generating block...");  
            blockContent = [];
            
            int cnt2 = 0;
            for (AQuestion question <- questions) {
                blockContent += question2html(question, "<cnt>_block_<cnt2>");
                cnt2 += 1;
            }
            return blockContent;
            //MAYBE TODO: iets
        }
        default: {
            println("ERROR. Unexpected AQuestion <q> found!");
            return li("/* ERROR: Question could not be parsed! */");
        }
    }
}

//////////////////////////////////////////////////////////////////////////////////////
// JS
//////////////////////////////////////////////////////////////////////////////////////

str form2js(AForm f) {
    println("----------\nGenerating form...");
    str updateJS = "function update() {\n";
    updateJS += "\tconsole.log(\"Updated the Questionaire!\");\n";
    str jqueryJS = "// This file was generated autmatically from the <f.name> form\n";
    jqueryJS += "$(\"document\").ready(function(){\n";
    int cnt = 0;
    for (AQuestion q <- f.questions) {
        res = question2js(q, "<cnt>");
        jqueryJS += res.jquery;
        updateJS += res.update;
        cnt += 1;
    }
    jqueryJS += "\n\n\n";
    updateJS += "}\n";
    updateJS += "function setHide(id, val){";
    updateJS += "\tif (val) {console.log(\"Hide called\" + id);$(id).addClass(\"hidden\");} else {$(id).removeClass(\"hidden\");}";
    updateJS += "}\n";    
    updateJS += "update();\n";
    println("Form was generated!\n");
    return jqueryJS + updateJS + "});\n";
}

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

str getjsWidget(str name, AType t) {
    switch(t) {
        case string(): {
            return "$(\"<name>\").val();";
        }
        case boolean(): {
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


str setjsWidget(str name, AType t, str val) {
    switch(t) {
        case string(): {
            return "$(\"<name>\").val(<val>);";
        }
        case boolean(): {
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

tuple[str jquery, str update] question2js(AQuestion q, str cnt) {
    switch(q) {           
        case simpleQuestion(strng(sq), ref(AId id, src = loc u), AType var, src = loc qloc): {
            println("Generating question <id.name>...");
            str simpleQ = "";
            
            simpleQ += "$(\"#q_<cnt>\").change(function() {\n";
            simpleQ +=      "\t<id.name> = <getjsWidget("#q_<cnt>", var)>\n";
            simpleQ +=      "\tupdate();\n";
            simpleQ +=  "});\n";
            simpleQ += "<id.name> = <getjsDefaultValue(var)>; \n";
            return <simpleQ, "">;
        }
        case computedQuestion(strng(sq), ref(AId id, src = loc u), AType var, AExpr e, src = loc qloc): {
            println("Generating question <id.name>...");
            str computedQ = "";
            str update = "";
            
            computedQ += "<id.name> = <expression2js(e)>; \n";
            update += computedQ;
            update += "\t<setjsWidget("#q_<cnt>", var, id.name)>\n";
            
            return <computedQ, update>;
        }
        case ifThenElse(AExpr cond, list[AQuestion] thenpart, list[AQuestion] elsepart): { 
            println("Generating if-then-else-block...");
            tuple[str jquery, str update] ifblock = <"", "">;
            
            ifblock.update += "if (<expression2js(cond)>) { \n";
            ifblock.update += "\tsetHide(\"#if_q_<cnt>\", false);\n";
            ifblock.update += "\tsetHide(\"#else_q_<cnt>\", true);\n";
            
            int cnt2 = 0;
            for (AQuestion question <- thenpart) {
                res = question2js(question, "<cnt>_<cnt2>");
                ifblock.jquery += res.jquery;
                ifblock.update += res.update;
                cnt2 += 1;
            }
            ifblock.update += "} else { \n";
            ifblock.update += "\tsetHide(\"#if_q_<cnt>\", true);\n";
            ifblock.update += "\tsetHide(\"#else_q_<cnt>\", false);\n";
            
            for (AQuestion question <- elsepart) {
                res = question2js(question, "<cnt>_<cnt2>");
                ifblock.jquery += res.jquery;
                ifblock.update += res.update;
                cnt2 += 1;
            }
            ifblock.update += "} \n";
            return ifblock; 
        }
        case ifThen(AExpr cond, list[AQuestion] questions): {
            println("Generating if-then-block...");
            tuple[str jquery, str update] ifblock = <"", "">;
            
            ifblock.update += "if (<expression2js(cond)>) { \n";
            ifblock.update += "\tsetHide(\"#if_q_<cnt>\", false);\n";
            
            int cnt2 = 0;
            for (AQuestion question <- questions) {
                res = question2js(question, "<cnt>_<cnt2>");
                ifblock.jquery += res.jquery;
                ifblock.update += res.update;
                cnt2 += 1;
            }
            ifblock.update += "} else { \n";
            ifblock.update += "\tsetHide(\"#if_q_<cnt>\", true);\n";
            
            ifblock.update += "} \n";
            return ifblock; //} \n";
        }
        case block(list[AQuestion] questions): { 
            println("Generating block...");  
            tuple[str jquery, str update] ifblock = <"", "">; //"{ \n";
            int cnt2 = 0;
            for (AQuestion question <- questions) {
                res = question2js(question, "<cnt>_<cnt2>");
                ifblock.jquery += res.jquery;
                ifblock.update += res.update;
                cnt2 += 2;
            }
            return ifblock; //"} \n";
        }
        default: {
            println("ERROR. Unexpected AQuestion <q> found!");
            return <"/* ERROR: Question could not be parsed! */", "">;
        }
    }
}


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
        //For equal(==) and neq(!=) it is possible to compare arguments of different types, 
        //though depending on the implementation this will in (almost) all cases evaluate to false
        case equal(AExpr lhs, AExpr rhs, src = loc u): {
            return "(<expression2js(lhs)> === <expression2js(rhs)>)";    
        }
        case neq(AExpr lhs, AExpr rhs, src = loc u): {
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
