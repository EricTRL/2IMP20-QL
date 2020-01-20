# 2IMP20-QL
## Introduction
QL is a simple Domain Specific Language for questionaires that was developed for the Generic Language Theory course (2IMP20) at the Eindhoven University of Technology.

## Supported Syntax
- Variable types `boolean`, `integer`, and `string`
- Simple Questions that require user input: `"<string|Description>" <string|VariableName>: <type|VariableType>`
- Computed Questions that operate on previously defined variables: `"<string|Description>" <string|VariableName>: <type|VariableType> = <type|Operation>`
- If-blocks: `if (<boolean|Guard>) { }`
- If-else-blocks: `if (<boolean|Guard>) { } else { }`
- Blocks: `{ }`

### Example
```
form codeExample {
    "What is your name?" name: string
    
    "What is your age?" age: integer
    
    if (age >= 16) {
       "Have you earned your driver's license?" license: boolean
       
       if (license) {
           "At what age did you earn your driver's license?" driverAge: integer
           
           "You have had your driver's license for this many years: " years: integer = driverAge - age
       }
    } else {
       if (age >= 14) {
           "Don't forget that you can earn your diver's license when you're this old in the Netherlands:" minLicenseAge: integer = 16
       }
    }
}
```

## Supported Editor Features
- Code highlighting
- Type Checking
  - References to undefined questions
  - Duplicate question declarations with different types
  - Conditions that are not of the type `boolean`
  - Operands of invalid type to operators
  - Duplicate question descriptions (shows a warning)
- Flattening a questionaire (right-click in the editor)
- Renaming a variable (right-click in the editor)

## Known Problems
The following errors are not reported:
- A variable is used outside its scope
- A variable is used before it is defined

## Execution
To run the IDE, open any source file and then open a new Rascal terminal. Type `import IDE;` and then `main();`. Opening any .ql-file now utilises the IDE.

## Required Software
The following software was used to develop QL. Note that higher versions will probably also work, though those were untested.
- Eclipse (4.13.0)
- Rascal Plugin for Eclipse (0.16.2; Stable). Can be installed in Eclipse using the Help -> Install New Software option.
