%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<cstdio>
#include<vector>
#include "1605106_SymbolTable.h"
using namespace std;
int yyparse(void);
extern "C" int yylex(void);
extern FILE *yyin;
vector<SymbolInfo*> parameters;
vector<SymbolInfo*> declarations;
vector<SymbolInfo*> arguments;
FILE *parser = fopen("1605106_parser.txt", "w");
FILE *errorFile = fopen("1605106_error.txt", "w");
FILE *fp;
SymbolTable *myTable = new SymbolTable(7);
int lines = 1;
int errors = 0;

void yyerror(char *s){cerr << "Line no" << lines << endl;}

%}
%name parse
%token IF ELSE FOR WHILE DO BREAK
%token INT CHAR FLOAT DOUBLE
%token VOID RETURN SWITCH CASE
%token DEFAULT CONTINUE
%token ADDOP MULOP INCOP RELOP ASSIGNOP LOGICOP BITOP
%token NOT COMMA SEMICOLON
%token LPAREN LCURL LTHIRD RPAREN RCURL RTHIRD
%token CONST_INT CONST_FLOAT CONST_CHAR CONST_STRING ID
%token PRINTLN DECOP
%left RELOP LOGICOP BITOP
%left ADDOP
%left MULOP
%nonassoc AFTER_ELSE
%nonassoc ELSE
%union
{
    SymbolInfo* var;
}
%type <s>start

%%

start: program { 
}
;

program: program unit {
	fprintf(parser, "At line no : %d program : program unit\n\n", lines);
	$<var>$ = new SymbolInfo(); $<var>$ -> setName($<var>1 -> getName() + $<var>2 -> getName()); fprintf(parser, "%s %s\n\n", $<var>1 -> getName().c_str(), $<var>2 -> getName().c_str());
}
| unit {
	fprintf(parser, "At line no : %d program : unit\n\n", lines);
	$<var>$ = new SymbolInfo(); $<var>$ -> setName($<var>1 -> getName()); fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
}
;

unit: var_declaration { 
	fprintf(parser, "At line no : %d unit : var_declaration\n\n", lines);
	$<var>$ = new SymbolInfo();
	$<var>$ -> setName($<var>1 -> getName()+"\n");fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	
}
| func_declaration {
	fprintf(parser, "At line no : %d unit : func_declaration\n\n", lines);
	$<var>$ = new SymbolInfo();
	$<var>$ -> setName($<var>1 -> getName() + "\n"); fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	
}
| func_definition {
	fprintf(parser, "At line no : %d unit : func_definition\n\n", lines);
	$<var>$ = new SymbolInfo();
	$<var>$ -> setName($<var>1 -> getName() + "\n"); fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
}
;
func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
	fprintf(parser, "At line no : %d func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n", lines);
	$<var>$ = new SymbolInfo();
	string variableName = $<var>2->getName();
	fprintf(parser, "%s %s(%s);\n\n", $<var>1 -> getName().c_str(), $<var>2 -> getName().c_str(), $<var>4 -> getName().c_str());
	SymbolInfo *temp = myTable->lookUp(variableName);
	if(temp != 0){
		//cout << "Check totalparameter " << temp -> getFunction() -> getTotalParameters() << endl;
		if(temp -> getFunction() -> getTotalParameters() != parameters.size()){
			vector<string>pType = temp -> getFunction()-> getParameterType();
			int limit = parameters.size();
			for(int i=0; i < limit; i++) {
				string decI = parameters[i] -> getDeclaration(); 
				if(decI != pType[i]){
					fprintf(errorFile, "Error at Line %d : Type Mismatch \n\n",lines);
					errors++;
					break;
				}
			}
			string returnType = temp->getFunction() -> getRType();
			if(returnType != $<var>1 -> getName()){
				fprintf(errorFile,"Error at Line %d : Return Type Mismatch \n\n",lines);
				errors++;
			}
			parameters.clear();
		}
		else {
			fprintf(errorFile, "Error at Line %d : Parameter size doesn't match \n\n",lines);
			errors++;
		}

	}
	else{
		string name2 = $<var>2 -> getName();
		myTable->insert($<var>2->getName(), "ID", "Function");
		temp = myTable -> lookUp(name2);
		temp -> setFunction();
		int limit = parameters.size();
		for(int i=0; i<limit; i++){
			string paramName = parameters[i]->getName();
			string paramDec = parameters[i]->getDeclaration();
			temp -> getFunction() -> addParameter(paramName, paramDec);
		}
		//cout << "Check size " << parameters.size()<< endl;
		parameters.clear();
		string n = $<var>1->getName();
		temp -> getFunction() -> setRType(n);
	}
	string var1 = $<var>1 -> getName();  string var2 = $<var>2 -> getName(); string var4 = $<var>4 -> getName();
	$<var>$ -> setName(var1 + var2 + "(" + var4 + ")" + ";");
}
| type_specifier ID LPAREN RPAREN SEMICOLON {
	fprintf(parser, "At line no : %d func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n", lines);
	fprintf(parser, "%s %s();\n\n", $<var>1 -> getName().c_str(), $<var>2 -> getName().c_str());
	
	$<var>$ = new SymbolInfo();
	
	SymbolInfo* temp = myTable -> lookUp($<var>2 -> getName());
	
	if(temp != 0){
		int total = temp -> getFunction() -> getTotalParameters();
		if(total != 0){
			
			fprintf(errorFile,"Error at Line %d : Invalid number of parameters \n\n",lines);


			errors++;
		}

		string returnType = temp->getFunction() -> getRType();

		if(returnType != $<var>1 -> getName()){
			
			fprintf(errorFile,"Error at Line %d : Return Type Mismatch \n\n",lines);



			errors++;
		}
		


		
	}
	else{
		string var2Name = $<var>2->getName();
		myTable->insert(var2Name, "ID", "Function");
		temp = myTable -> lookUp(var2Name);
		string var1Name = $<var>1->getName();
		temp -> setFunction(); //this creates the function for temp
		//now the function must have a return type
		temp -> getFunction() -> setRType(var1Name);
	}
	string name1 = $<var>1 -> getName();
	string name2 = $<var>2 -> getName();
	string extra = "();";
	$<var>$ -> setName(name1 + name2 + extra);
}
;
func_definition: type_specifier ID LPAREN parameter_list RPAREN {
	$<var>$ = new SymbolInfo();
	string name2 = $<var>2->getName();
	SymbolInfo *temp = myTable->lookUp(name2);
	if(temp != 0){
		bool def = temp->getFunction()->getDefined();
		if(def != 0){
			fprintf(errorFile,"Error at Line %d : Multiple definition of Function %s\n\n",lines, $<var>2->getName().c_str());
			errors++;
		}
		else {
			if(temp -> getFunction() -> getTotalParameters() != parameters.size()){
				
				fprintf(errorFile,"Error at Line %d : Invalid number of parameters \n\n",lines);

				errors++;
			}
			else {
				vector<string>pType = temp -> getFunction()-> getParameterType();
				int limit = parameters.size();


				for(int i=0; i<limit; i++) {
					//Type Mismatch checking 
					string paramDec = parameters[i] -> getDeclaration();
					if(paramDec != pType[i]){
						fprintf(errorFile, "Error at Line %d : Type Mismatch \n\n",lines);
						errors++;
						break;
					}
				}
				string returnType = temp->getFunction() -> getRType();
				string n1 = $<var>1 -> getName();
				if(returnType != n1){
					fprintf(errorFile,"Error at Line %d : Return Type Mismatch \n\n",lines);
					errors++;
				}
			}
			//the function must set defined
			temp -> getFunction() -> setDefined();

			
		}
		
	}
	else {
		string name2 = $<var>2 -> getName();string type = "ID";string dec = "Function";myTable -> insert(name2, type, dec);
		temp = myTable -> lookUp(name2);
		temp -> setFunction();
		temp -> getFunction() -> setDefined();
		int limit = parameters.size();
		string returnType = $<var>1 -> getName();
		//cout << "LIMIT " << limit << endl;
		for(int i=0; i<limit; i++){ 
			string paramName = parameters[i] -> getName();
			string paramDec = parameters[i] -> getDeclaration();
			temp -> getFunction() -> addParameter(paramName, paramDec);
			}
		temp -> getFunction() -> setRType(returnType);
	}
} compound_statement {
	fprintf(parser, "At line no : %d func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n", lines);
	fprintf(parser, "%s %s(%s) %s\n\n", $<var>1 -> getName().c_str(), $<var>2 -> getName().c_str(), $<var>4 -> getName().c_str(), $<var>7 -> getName().c_str());
	string name1 = $<var>1 -> getName();string name2 = $<var>2 -> getName();string name4 = $<var>4 -> getName();string name7 = $<var>7 -> getName(); 
	$<var>$ -> setName(name1 + " " + name2 + "(" + name4 + ")" + name7);
	//cout << $<var>1 -> getName() << endl;
}
| type_specifier ID LPAREN RPAREN {
	$<var>$ = new SymbolInfo();
	string name = $<var>2 -> getName();
	string name1 = $<var>1 -> getName();
	SymbolInfo *temp = myTable -> lookUp(name);
	if(temp == 0){
		myTable -> insert(name, "ID", "Function");
		temp = myTable -> lookUp(name);
		temp -> setFunction();
		temp -> getFunction() -> setDefined();
		temp -> getFunction() -> setRType(name1);
	}
	else if(temp -> getFunction() -> getDefined() == 0) {
		int total = temp -> getFunction() -> getTotalParameters();
		string returnType = temp -> getFunction() -> getRType();
		if(total != 0){
			fprintf(errorFile,"Error at Line %d : Invalid number of parameters \n\n",lines);
			errors++;
		}
		if(returnType != $<var>1 -> getName()){
			fprintf(errorFile,"Error at Line %d : Return Type Mismatch \n\n",lines);
			errors++;
		}
		temp -> getFunction() -> setDefined();
	}

	
	
	else {
		
		fprintf(errorFile,"Error at Line %d : Multiple definition of Function %s\n\n",lines, $<var>2->getName().c_str());
		
		
		errors++;
		
		}
} compound_statement {
	fprintf(parser, "At line no : %d func_definition : type_specifier ID LPAREN RPAREN compound_statement\n", lines);
	fprintf(parser, "%s %s() %s\n\n", $<var>1 -> getName().c_str(),$<var>2 -> getName().c_str() ,$<var>6 -> getName().c_str());
	string name1 = $<var>1 -> getName();
	string name2 = $<var>2 -> getName();
	string name6 = $<var>6 -> getName();
	$<var>$ -> setName(name1 +name2+"()"+ name6);
}
;

parameter_list: parameter_list COMMA type_specifier ID {
	fprintf(parser, "At line no : %d parameter_list : parameter_list COMMA type_specifier ID\n\n", lines);
	$<var>$ = new SymbolInfo();

	$<var>$ -> setName($<var>1 -> getName() + "," + $<var>3 -> getName() + " " + $<var>4 -> getName());
	parameters.push_back(new SymbolInfo($<var>4 -> getName(), "ID", $<var>3 -> getName()));
	fprintf(parser, "%s,%s %s\n\n", $<var>1 -> getName().c_str(), $<var>3 -> getName().c_str(), $<var>4 -> getName().c_str());
	
}
| parameter_list COMMA type_specifier {
	fprintf(parser, "At line no : %d parameter_list : parameter_list COMMA type_specifier\n\n", lines);
	$<var>$ = new SymbolInfo();
	string var1 = $<var>1 -> getName();
	string var3 = $<var>3 -> getName();
	$<var>$ -> setName(var1 + "," + var3);
	string type = "ID";
	parameters.push_back(new SymbolInfo("",type,var3));
	fprintf(parser, "%s,%s\n\n", $<var>1 -> getName().c_str(), $<var>3 -> getName().c_str());
	
}
| type_specifier ID {
	fprintf(parser, "At line no : %d parameter_list : type_specifier ID\n\n", lines);
	$<var>$ = new SymbolInfo();

	$<var>$ -> setName($<var>1 -> getName() + " " + $<var>2 -> getName());
	parameters.push_back(new SymbolInfo($<var>2 -> getName(), "ID", $<var>1 -> getName()));

	fprintf(parser, "%s %s\n\n", $<var>1 -> getName().c_str(), $<var>2 -> getName().c_str());
	
}
| type_specifier {
	fprintf(parser, "At line no : %d parameter_list : type_specifier\n\n", lines);
	$<var>$ = new SymbolInfo();


	$<var>$ -> setName($<var>1 -> getName() + " ");
	parameters.push_back(new SymbolInfo("", "ID", $<var>3 -> getName()));

	fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	
}
;

compound_statement: LCURL {
	myTable -> enterScope(7);
	int limit = parameters.size();
	for(int i=0; i < limit; i++){
		myTable -> insert(parameters[i]->getName(), "ID", parameters[i] -> getDeclaration());
	}
	parameters.clear();
} statements RCURL {
	fprintf(parser, "At line no : %d compound_statement : LCURL statements RCURL\n\n", lines);
	$<var>$ = new SymbolInfo();

	$<var>$ -> setName("{\n" + $<var>3 -> getName() + "\n}");

	fprintf(parser, "{\n%s\n}\n\n", $<var>3 -> getName().c_str());
	
	//myTable -> printAllScopeTables();
	myTable -> exitScope();
}
| LCURL RCURL {
	myTable -> enterScope(7);
	int limit = parameters.size();

	for(int i=0; i < limit; i++){
		string dec = parameters[i] -> getDeclaration();
		string name = parameters[i]->getName();
		string type = "ID";
		myTable -> insert(name, type, dec);
	}
	parameters.clear();
	fprintf(parser, "At line no : %d compound_statement : LCURL RCURL\n\n", lines);
	fprintf(parser, "{}\n\n");
	$<var>$ = new SymbolInfo();
	$<var>$ -> setName("{}");
	//myTable -> printAllScopeTables();
	myTable -> exitScope();
}
;

var_declaration: type_specifier declaration_list SEMICOLON {
	fprintf(parser, "At line no : %d var_declaration : type_specifier declaration_list SEMICOLON\n\n", lines);
	$<var>$ = new SymbolInfo();
	fprintf(parser, "%s %s;\n\n", $<var>1->getName().c_str(), $<var>2->getName().c_str());
	string name = $<var>1 -> getName();
	string v = "void ";
	if(name == v){
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);

		errors++;
	}
	else {
		int limit = declarations.size();
		for(int i =0; i < limit; i++){
			if(myTable -> findCurrent(declarations[i]->getName())) {
				fprintf(errorFile,"Error at Line %d : Multiple declaration of variable %s\n\n",lines, declarations[i]->getName().c_str());
				errors++;
				continue;
			}
			int decSize = declarations[i]-> getType().size();
			string decName = declarations[i] -> getName();
			string decType = declarations[i] -> getType();
			if(decSize != 3){
				myTable -> insert(decName, decType, $<var>1 -> getName());
			}
			else {
				string s = declarations[i] -> getType().substr(0, declarations[i] -> getType().size()-1);
				declarations[i] -> setType(s);
				myTable -> insert(decName, decType, $<var>1 -> getName()+"array");
			}
		}
	}
	string name1 = $<var>1 -> getName();
	string name2 = $<var>2 -> getName();
	declarations.clear();
	$<var>$ -> setName(name1 + " " + name2 + ";");
}
;

type_specifier: INT {
	fprintf(parser, "At line no : %d type_specifier : INT\n\n", lines);
	$<var>$ = new SymbolInfo();
	$<var>$ -> setName("int ");
	fprintf(parser, "int \n\n");
	
}
| FLOAT {
	fprintf(parser, "At line no : %d type_specifier : FLOAT\n\n", lines);
	$<var>$ = new SymbolInfo();
	$<var>$ -> setName("float ");
	fprintf(parser, "float \n\n");
	
}
| VOID {
	fprintf(parser, "At line no : %d type_specifier : VOID \n\n", lines);
	$<var>$ = new SymbolInfo();
	$<var>$ -> setName("void ");
	fprintf(parser, "void \n\n");
	
}
;

declaration_list: declaration_list COMMA ID {
	fprintf(parser, "At line no : %d declaration_list : declaration_list COMMA ID\n\n", lines);
	$<var>$ = new SymbolInfo();
	$<var>$ -> setName($<var>1 -> getName() + "," + $<var>3 -> getName());
	fprintf(parser, "%s,%s\n\n", $<var>1->getName().c_str(), $<var>3->getName().c_str());
	string  n3 = $<var>3 -> getName();
	string type =  "ID";
	declarations.push_back(new SymbolInfo(n3, type));
	
}
| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
	fprintf(parser, "At line no : %d declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n", lines);
	$<var>$ = new SymbolInfo();

	$<var>$ -> setName($<var>1 -> getName() + "," + $<var>3 -> getName() + "[" + $<var>5 -> getName() + "]");
	string  n3 = $<var>3 -> getName();
	string type =  "IDa";
	fprintf(parser, "%s,%s[%s]\n\n", $<var>1 -> getName().c_str(), $<var>3 -> getName().c_str(), $<var>5 -> getName().c_str());
	declarations.push_back(new SymbolInfo(n3,type));
	
}
| ID {
	fprintf(parser, "At line no : %d declaration_list : ID\n\n", lines);
	$<var>$ = new SymbolInfo();
	$<var>$ -> setName($<var>1 -> getName());
	fprintf(parser, "%s\n\n", $<var>1->getName().c_str());
	string  n1 = $<var>1 -> getName();
	string type =  "ID";
	declarations.push_back(new SymbolInfo(n1, type));
	
}
| ID LTHIRD CONST_INT RTHIRD {
	fprintf(parser, "At line no : %d declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n", lines);
	$<var>$ = new SymbolInfo();
	$<var>$ -> setName($<var>1 -> getName() + "[" + $<var>3 -> getName() + "]");
	fprintf(parser, "%s[%s]\n\n", $<var>1 -> getName().c_str(), $<var>3 -> getName().c_str());
	string  n1 = $<var>1 -> getName();
	string type =  "IDa";
	declarations.push_back(new SymbolInfo(n1, type));
	
}
;

statements: statement {
	fprintf(parser, "At line no : %d statements : statement\n\n", lines);
	$<var>$ = new SymbolInfo();

	$<var>$ -> setName($<var>1 -> getName());

	fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());	
	
}
| statements statement {
	fprintf(parser, "At line no : %d statements : statements statement\n\n", lines);
	$<var>$ = new SymbolInfo();

	$<var>$ -> setName($<var>1 -> getName() + "\n" + $<var>2 -> getName());

	fprintf(parser, "%s \n%s\n\n", $<var>1 -> getName().c_str(), $<var>2 -> getName().c_str());
	
}
;

statement: var_declaration {
	fprintf(parser, "At line no : %d statement : var_declaration\n\n", lines);
	$<var>$ = new SymbolInfo();

	$<var>$ -> setName($<var>1 -> getName());

	fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	
}
| expression_statement {
	fprintf(parser, "At line no : %d statement : expression_statement\n\n", lines);
	$<var>$ = new SymbolInfo();

	$<var>$ -> setName($<var>1 -> getName());

	fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	
}
| compound_statement {
	fprintf(parser, "At line no : %d statement : compound_statement\n\n", lines);
	$<var>$ = new SymbolInfo();

	$<var>$ -> setName($<var>1 -> getName());

	fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	
}
| FOR LPAREN expression_statement expression_statement expression RPAREN statement {
	fprintf(parser, "At line no : %d statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n", lines);
	$<var>$ = new SymbolInfo();
	string v = "void ";
	string dec3 = $<var>3 -> getDeclaration();
	fprintf(parser, "for(%s %s %s)\n%s\n", $<var>3 -> getName().c_str(), $<var>4 -> getName().c_str(), $<var>5 -> getName().c_str(), $<var>7 -> getName().c_str());
	if(dec3 == v){
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);
		errors++;
	}
	string name3 = $<var>3 -> getName();
	string name4 = $<var>4 -> getName();
	string name5 = $<var>5 -> getName();
	string name7 = $<var>7 -> getName();
	$<var>$ -> setName("for(" + name3 + name4 + name5 +")" + "\n" + name7);
}
| IF LPAREN expression RPAREN statement %prec AFTER_ELSE {
	fprintf(parser, "At line no : %d statement : IF LPAREN expression RPAREN statement\n\n", lines);
	$<var>$ = new SymbolInfo();
	string v = "void ";
	fprintf(parser, "if(%s)\n %s \n\n", $<var>3 -> getName().c_str(), $<var>5 -> getName().c_str());
	if($<var>3 -> getDeclaration() == v){
		
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);

		errors++;
	}
	$<var>$ -> setName("if(" + $<var>3 -> getName()+ ")" + "\n" + $<var>5 -> getName());

}
| IF LPAREN expression RPAREN statement ELSE statement {
	fprintf(parser, "At line no : %d statement : IF LPAREN expression RPAREN statement ELSE statement\n\n", lines);
	$<var>$ = new SymbolInfo();
	fprintf(parser, "if(%s)\n%s\n else \n %s \n\n", $<var>3 -> getName().c_str(), $<var>5 -> getName().c_str(), $<var>7 -> getName().c_str());
	
	string v = "void ";
	string dec = $<var>3 -> getDeclaration();

	if(dec == v){
		
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);

		errors++;
	}
	$<var>$ -> setName("if(" + $<var>3 -> getName()+ ")" + "\n" + $<var>5 -> getName() + "\n" + "else" + "\n" + $<var>7 -> getName());
}
| WHILE LPAREN expression RPAREN statement {
	fprintf(parser, "At line no : %d statement : WHILE LPAREN expression RPAREN statement\n\n", lines);
	$<var>$ = new SymbolInfo();
	fprintf(parser, "while(%s)\n %s \n\n", $<var>3 -> getName().c_str(), $<var>5 -> getName().c_str());
	string v = "void ";
	string dec = $<var>3 -> getDeclaration();
	if(dec == v){
		
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);

		errors++;
	}
	$<var>$ -> setName("while(" + $<var>3 -> getName()+ ")" + "\n" + $<var>5 -> getName());
}
| PRINTLN LPAREN ID RPAREN SEMICOLON {
	fprintf(parser, "At line no : %d statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n", lines);
	$<var>$ = new SymbolInfo();
	
	$<var>$ -> setName("\n(" + $<var>3 -> getName()+ ")" + ";");

	fprintf(parser, "\n (%s); \n\n", $<var>3 -> getName().c_str());
	
}
| RETURN expression SEMICOLON {
	fprintf(parser, "At line no : %d statement : RETURN expression SEMICOLON\n\n", lines);
	$<var>$ = new SymbolInfo();
	fprintf(parser, "return %s;\n\n", $<var>2 -> getName().c_str());
	string dec2 = $<var>2 -> getDeclaration();
	string v = "void ";
	string i ="int ";
	if(dec2 == v){

		$<var>$ -> setDeclaration(i);

		
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);

		errors++;
		
	}
	$<var>$ -> setName("return " + $<var>2 -> getName()+ ";");
}
;

expression_statement: SEMICOLON {
	fprintf(parser, "At line no : %d expression_statement : SEMICOLON\n\n", lines);
	$<var>$ = new SymbolInfo();

	$<var>$ -> setName(";");

	fprintf(parser, ";\n\n");
	
}
| expression SEMICOLON {
	fprintf(parser, "At line no : %d expression_statement : expression SEMICOLON\n\n", lines);
	$<var>$ = new SymbolInfo();

	$<var>$ -> setName($<var>1 -> getName()+ ";");

	fprintf(parser, "%s ;\n\n", $<var>1 -> getName().c_str());
	
}
;

variable: ID {
	fprintf(parser, "At line no : %d variable : ID\n\n", lines);

	$<var>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	string variableName = $<var>1 -> getName();
	if(myTable -> lookUp(variableName) != 0){
		$<var>$ -> setDeclaration(myTable -> lookUp($<var>1 -> getName()) -> getDeclaration());
	}
	if(myTable -> lookUp($<var>1 -> getName()) == 0){
		
		fprintf(errorFile,"Error at Line %d : Undeclared variable: %s\n\n",lines, $<var>1 -> getName().c_str());
		
		errors++;
		}
	/*else if(myTable -> lookUp($<var>1 -> getName())-> getDeclaration() == "float array" || myTable -> lookUp($<var>1 -> getName())-> getDeclaration() == "int array" ){
		
		fprintf(errorFile,"Error at Line %d : %s is not an array\n\n",lines, $<var>1 -> getName().c_str());
		
		errors++;
		}*/
	


	$<var>$ -> setName($<var>1 -> getName());


}
| ID LTHIRD expression RTHIRD {


	fprintf(parser, "At line no : %d variable : ID LTHIRD expression RTHIRD\n\n", lines);

	$<var>$ = new SymbolInfo();

	string dec = $<var>3 -> getDeclaration();
	string v = "void ";
	string f = "float ";
	string fa = "float array";
	string ia = "int array";
	string i = "int ";

	fprintf(parser, "%s[%s]\n\n", $<var>1 -> getName().c_str(), $<var>3 -> getName().c_str());
	if(dec == v || dec == f) {
		
		fprintf(errorFile,"Error at Line %d : Non-integer Array Index  \n\n",lines);

		errors++;
	}
	if(myTable -> lookUp($<var>1 -> getName())==0){
		
		fprintf(errorFile,"Error at Line %d : Undeclared variable : %s \n\n",lines, $<var>1 -> getName().c_str());
		
		errors++;
	}

	if(myTable -> lookUp($<var>1 -> getName()) != 0){
		if(myTable -> lookUp($<var>1 -> getName()) -> getDeclaration() == fa) 
			$<var>1 -> setDeclaration(f);
		if(myTable -> lookUp($<var>1 -> getName()) -> getDeclaration() != fa && myTable -> lookUp($<var>1 -> getName()) -> getDeclaration() != ia){
			//cout << "Line No : "<< lines << " " << $<var>1 -> getName() << "  " << myTable -> lookUp($<var>1 -> getName()) -> getDeclaration() << endl;
			fprintf(errorFile,"Error at Line %d : Type Mismatch \n\n",lines);
			errors++;
		}
		string name1 = $<var>1 -> getName();
		string dec1 = $<var>1 -> getDeclaration();
		if(myTable -> lookUp(name1) -> getDeclaration() == ia) 
			$<var>1 -> setDeclaration(i);	
		$<var>$ -> setDeclaration(dec1);
	}
	string n1 = $<var>1 -> getName();
	string n3 = $<var>3 -> getName();
	$<var>$ -> setName(n1 + "[" + n3 + "]");

}
;

expression: logic_expression {
	fprintf(parser, "At line no : %d expression : logic_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	string name1 = $<var>1 -> getName();
	$<var>$ -> setName(name1);
	string dec1 = $<var>1 -> getDeclaration();
	fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	$<var>$ -> setDeclaration(dec1);
}
| variable ASSIGNOP logic_expression {
	fprintf(parser, "At line no : %d expression : variable ASSIGNOP logic_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	fprintf(parser, "%s=%s\n\n", $<var>1 -> getName().c_str(), $<var>3 -> getName().c_str());
	string v = "void ";
	string i = "int ";
	string dec3 = $<var>3 -> getDeclaration();
	string n1 = $<var>1 -> getName();
	string n3 = $<var>3 -> getName();
	string dec1 = $<var>1 -> getDeclaration();

	if(dec3 == v){
		$<var>$ -> setDeclaration(i);
		
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);
		
		errors++;
		
	}
	else if(myTable -> lookUp(n1) != 0){
		if(myTable -> lookUp(n1)-> getDeclaration() != dec3){
			
			fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);

			errors++;
		}
	}
	$<var>$ -> setName(n1+"=" + n3);
	$<var>$ -> setDeclaration(dec1);
}
;

logic_expression: rel_expression {
	fprintf(parser, "At line no : %d logic_expression : rel_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	string dec1 = $<var>1 ->getDeclaration();
	string n1 = $<var>1 -> getName();
	$<var>$ -> setDeclaration(dec1);
	fprintf(parser, "%s\n\n", $<var>1->getName().c_str());
	$<var>$ -> setName(n1);

}
| rel_expression LOGICOP rel_expression {
	fprintf(parser, "At line no : %d logic_expression : rel_expression LOGICOP rel_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	string i = "int ";
	string v = "void ";
	string dec1 = $<var>1->getDeclaration();
	string dec3 = $<var>3->getDeclaration();
	fprintf(parser, "%s%s%s\n\n", $<var>1->getName().c_str(), $<var>2->getName().c_str(), $<var>3->getName().c_str());
	if(dec1 == v || dec3 == v) {
		
		fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);

		errors++;
	}
	$<var>$ -> setDeclaration(i);
	string n1 = $<var>1 -> getName();
	string n2 = $<var>2 -> getName();
	string n3 = $<var>3 -> getName();
	$<var>$ -> setName(n1 + n2 + n3);
}
;

rel_expression: simple_expression {
	fprintf(parser, "At line no : %d rel_expression : simple_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	string n1 = $<var>1 -> getName();
	string dec1 = $<var>1 ->getDeclaration();
	$<var>$ -> setDeclaration(dec1);
	fprintf(parser, "%s\n\n", $<var>1->getName().c_str());
	$<var>$ -> setName(n1)
}
| simple_expression RELOP simple_expression {
	fprintf(parser, "At line no : %d rel_expression : simple_expression RELOP simple_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	string v = "void ";
	string i = "int ";
	string dec1 = $<var>1->getDeclaration();
	string dec3 = $<var>3->getDeclaration();
	fprintf(parser, "%s%s%s\n\n", $<var>1->getName().c_str(), $<var>2->getName().c_str(), $<var>3->getName().c_str());
	if(dec1 == v || dec3 == v) {
		
		fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);

		errors++;
	}
	$<var>$ -> setDeclaration(i);
	$<var>$ -> setName($<var>1 -> getName()+ $<var>2->getName()+ $<var>3->getName().c_str());
}
;

simple_expression: term {
	fprintf(parser, "At line no : %d simple_expression : term\n\n", lines);
	$<var>$ = new SymbolInfo();

	$<var>$ -> setName($<var>1 -> getName());
	
	$<var>$ -> setDeclaration($<var>1 ->getDeclaration());

	fprintf(parser, "%s\n\n", $<var>1->getName().c_str());
}
| simple_expression ADDOP term {
	fprintf(parser, "At line no : %d simple_expression : simple_expression ADDOP term\n\n", lines);
	$<var>$ = new SymbolInfo();
	fprintf(parser, "%s%s%s\n\n", $<var>1->getName().c_str(), $<var>2->getName().c_str(), $<var>3->getName().c_str());
	string f = "float ";
	string v = "void ";
	string i = "int ";
	if($<var>3->getDeclaration() == f || $<var>1->getDeclaration() == f ) {
		$<var>$ -> setDeclaration(f);
	}
	else if($<var>3->getDeclaration() == v || $<var>1->getDeclaration() == v) {
		$<var>$ -> setDeclaration(i);
		fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);
		

		errors++;
	}
	else $<var>$ -> setDeclaration(i);
	$<var>$ -> setName($<var>1 -> getName()+ $<var>2->getName()+ $<var>3->getName().c_str());
}
;

term: unary_expression {
	fprintf(parser, "At line no : %d term : unary_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	string dec = $<var>1 ->getDeclaration();
	string name1 = $<var>1 -> getName();
	$<var>$ -> setName(name1);
	fprintf(parser, "%s\n\n", $<var>1->getName().c_str());
	$<var>$ -> setDeclaration(dec);
	
}
| term MULOP unary_expression {
	fprintf(parser, "At line no : %d term : term MULOP unary_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	string v = "void ";
	string i = "int ";
	string f = "float ";
	string dec1 = $<var>1->getDeclaration();
	string dec3 = $<var>3->getDeclaration();
	fprintf(parser, "%s%s%s\n\n", $<var>1->getName().c_str(), $<var>2->getName().c_str(), $<var>3->getName().c_str());
	if(dec1 == v || dec3 == v) {
		$<var>$ -> setDeclaration(i);
		fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);
		errors++;
	}
	else if($<var>2 -> getName() == "/"){
		if(dec1 == i && dec3 == i)
			$<var>$ -> setDeclaration(i);
		else if(dec1 == v || dec3 == v){
			$<var>$ -> setDeclaration(i);
			fprintf(errorFile, "Error at Line %d : Type Mismatch\n\n", lines);
			errors++;
		}
		else $<var>$ -> setDeclaration(f);
	}
	else if($<var>2 -> getName() == "%"){
		if(dec1 != i || dec3 != i) {
			
			fprintf(errorFile,"Error at Line %d : Integer operand on modulus operator\n\n",lines);

			errors++;
		}
		$<var>$ -> setDeclaration(i);
	}
	else {
		if(dec1 == f || dec3 == f)
			$<var>$ -> setDeclaration(f);
		else if(dec1 == v || dec3 == v){
			$<var>$ -> setDeclaration(i);
			fprintf(errorFile, "Error at Line %d : Type Mismatch\n\n", lines);
			errors++;
		}
		else $<var>$ -> setDeclaration(i);
	}
	string str1 = $<var>1 -> getName();
	string str2 = $<var>2->getName();
	string str3 = $<var>3->getName();
	string name =  $<var>1 -> getName() + $<var>2->getName() + $<var>3->getName();
	$<var>$ -> setName(name);
}
;

unary_expression: ADDOP unary_expression {
	fprintf(parser, "At line no : %d unary_expression : ADDOP unary_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	string v = "void ";
	string i = "int ";
	string f = "float ";
	string dec2 = $<var>2 -> getDeclaration();

	fprintf(parser, "%s%s\n\n", $<var>1->getName().c_str(), $<var>2->getName().c_str());
	if(dec2 == v){
		
		$<var>$ -> setDeclaration(i);
		
		fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);

		errors++;
		
	}
	else {
		string dec2 = $<var>2 -> getDeclaration();
		$<var>$ -> setDeclaration(dec2);
	}
	string str1 = $<var>1 -> getName();
	string str2 = $<var>2 -> getName();
	$<var>$ -> setName(str1+ str2);

}
| NOT unary_expression {
	fprintf(parser, "At line no : %d unary_expression : NOT unary_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	fprintf(parser, "!%s\n\n",$<var>2->getName().c_str());

	string v = "void ";
	string i = "int ";
	string dec2 = $<var>2 -> getDeclaration();
	string n2 = $<var>2->getName();
	if(dec2 == v){
		$<var>$ -> setDeclaration(i);

		
		fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);

		errors++;
		
	}
	else {
		$<var>$ -> setDeclaration(dec2);
	}
	$<var>$ -> setName("!"+ n2);
}
| factor {
	fprintf(parser, "At line no : %d unary_expression : factor\n\n", lines);
	$<var>$ = new SymbolInfo();
	string var1 = $<var>1->getName();
	$<var>$ -> setName(var1);
	fprintf(parser, "%s\n\n",$<var>1->getName().c_str());
	string dec1 = $<var>1 -> getDeclaration();
	$<var>$ -> setDeclaration(dec1);
}
;
factor: variable {
	fprintf(parser, "At line no : %d factor : variable\n\n", lines);
	$<var>$ = new SymbolInfo();
	string var1 = $<var>1->getName();
	$<var>$ -> setName(var1);
	fprintf(parser, "%s\n\n",$<var>1->getName().c_str());
	string dec1 = $<var>1 -> getDeclaration();
	$<var>$ -> setDeclaration(dec1);
}
| ID LPAREN argument_list RPAREN {
	fprintf(parser, "At line no : %d factor : ID LPAREN argument_list RPAREN\n\n", lines);
	$<var>$ = new SymbolInfo();
	string i = "int ";
	fprintf(parser, "%s(%s)\n\n",$<var>1->getName().c_str(), $<var>3->getName().c_str());
	string variableName = $<var>1->getName();
	SymbolInfo *temp = myTable -> lookUp(variableName);
	//cout << $<var>1->getName()<< endl;
	//cout << temp->getFunction() -> getTotalParameters() << endl;
	if(temp == 0){
		$<var>$->setDeclaration(i);
		fprintf(errorFile,"Error at Line %d : Undeclared function\n\n",lines);
		errors++;
	}
	else if(temp -> getFunction() == 0){
		$<var>$->setDeclaration(i);
		fprintf(errorFile,"Error at Line %d : Not a function\n\n",lines);
		errors++;
		
	}
	else{
		int p = temp -> getFunction() -> getTotalParameters();
		bool def = temp -> getFunction() -> getDefined();
		if(def == 0){
			fprintf(errorFile,"Error at Line %d : Undeclared function\n\n",lines);
			errors++;
		}
		$<var>$ -> setDeclaration(temp -> getFunction() -> getRType());
		
		if(p != arguments.size()){
			//cout << lines << " " <<p <<endl;
			//cout << lines << " " <<arguments.size() <<endl;
			fprintf(errorFile,"Error at Line %d : Invalid number of arguments\n\n",lines);
			errors++;
		}
		else{
			vector<string> pt = temp -> getFunction() -> getParameterType();
			int argSize = arguments.size();
			for(int i=0; i < argSize; i++){
				if(arguments[i]->getDeclaration()!=pt[i]){
					fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);
					errors++;
					break;
				}
			}
		}
	}
	arguments.clear();
	$<var>$ -> setName($<var>1->getName()+ "(" + $<var>3->getName() + ")");
}
| LPAREN expression RPAREN {
	fprintf(parser, "At line no : %d factor : LPAREN expression RPAREN\n\n", lines);
	$<var>$ = new SymbolInfo();
	string var2 = "("+ $<var>2->getName()+")";
	$<var>$ -> setName(var2);
	fprintf(parser, "(%s)\n\n",$<var>2->getName().c_str());
	string dec2 = $<var>2 -> getDeclaration();
	$<var>$ -> setDeclaration(dec2);
}
| CONST_INT {
	fprintf(parser, "At line no : %d factor : CONST_INT\n\n", lines);
	$<var>$ = new SymbolInfo();
	string i = "int ";
	string var1 = $<var>1->getName();
	$<var>$ -> setName(var1);
	fprintf(parser, "%s\n\n",$<var>1->getName().c_str());
	$<var>$ -> setDeclaration(i);
}
| CONST_FLOAT {
	fprintf(parser, "At line no : %d factor : CONST_FLOAT\n\n", lines);
	$<var>$ = new SymbolInfo();
	string f = "float ";
	string var1 = $<var>1->getName();
	$<var>$ -> setName(var1);
	fprintf(parser, "%s\n\n",$<var>1->getName().c_str());
	$<var>$ -> setDeclaration(f);
}
| variable INCOP {
	fprintf(parser, "At line no : %d factor : variable INCOP\n\n", lines);
	$<var>$ = new SymbolInfo();	
	string var1 = $<var>1->getName() + "++";
	$<var>$ -> setName(var1);
	fprintf(parser, "%s\n\n",$<var>1->getName().c_str());
	string dec1 = $<var>1 -> getDeclaration();
	$<var>$ -> setDeclaration(dec1);
}
| variable DECOP {
	fprintf(parser, "At line no : %d factor : variable DECOP\n\n", lines);
	$<var>$ = new SymbolInfo();
	string var1 = $<var>1->getName()+"--";
	$<var>$ -> setName(var1);
	fprintf(parser, "%s\n\n",$<var>1->getName().c_str());
	string dec1 = $<var>1 -> getDeclaration();
	$<var>$ -> setDeclaration(dec1);
}
;


argument_list: arguments {
	fprintf(parser, "At line no : %d argument_list : arguments\n\n", lines);
	$<var>$ = new SymbolInfo();
	string var1 = $<var>1->getName();
	$<var>$ -> setName(var1);
	fprintf(parser, "%s\n\n",$<var>1->getName().c_str());
}
|  {
	fprintf(parser, "At line no : %d argument_list : \n\n", lines);
	$<var>$ = new SymbolInfo();
	$<var>$ -> setName("");
}
;

arguments: arguments COMMA logic_expression {
	fprintf(parser, "At line no : %d arguments : arguments COMMA logic_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	fprintf(parser, "%s,%s\n\n",$<var>1->getName().c_str(), $<var>3->getName().c_str());
	arguments.push_back($<var>3);
	string setter = $<var>1->getName()+ "," + $<var>3->getName();
	$<var>$ -> setName(setter);
}
| logic_expression {
	fprintf(parser, "At line no : %d arguments : logic_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n",$<var>1->getName().c_str());
	string n1 = $<var>1->getName();
	string type1 = $<var>1->getType();
	string dec1 = $<var>1->getDeclaration();
	$<var>$ -> setName(n1);
	arguments.push_back(new SymbolInfo(n1, type1, dec1));
} 

%%

int main(int argc,char *argv[])
{
	if((fp=fopen(argv[1],"r"))==NULL){
		printf("Cannot Open Input File.\n"); exit(1);}
	yyin=fp;
	myTable -> enterScope(7);
	yyparse();
	fprintf(parser, "Total lines : %d\n",lines);
	fprintf(errorFile, "Total errors : %d", errors);
	fprintf(parser, "Total errors : %d", errors);
	fclose(fp);
	fclose(parser);
	fclose(errorFile);
	return 0;
}
