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


SymbolTable *table = new SymbolTable(7);
int lines = 1;
int errors = 0;


void yyerror(char *s)
{
	//write your code
	cerr << "Line no" << lines << endl;
}


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
    SymbolInfo* symbol;
}
%type <s>start


%%

start: program { 
}
;

program: program unit {
	fprintf(parser, "At line no : %d program : program unit\n\n", lines);

	$<symbol>$ = new SymbolInfo();
	$<symbol>$ -> setName($<symbol>1 -> getName() + $<symbol>2 -> getName());


	fprintf(parser, "%s %s\n\n", $<symbol>1 -> getName().c_str(), $<symbol>2 -> getName().c_str());
}
| unit {
	fprintf(parser, "At line no : %d program : unit\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	$<symbol>$ -> setName($<symbol>1 -> getName());

	fprintf(parser, "%s\n\n", $<symbol>1 -> getName().c_str());
}
;

unit: var_declaration { 
	fprintf(parser, "At line no : %d unit : var_declaration\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1 -> getName().c_str());
	$<symbol>$ -> setName($<symbol>1 -> getName()+"\n");
}
| func_declaration {
	fprintf(parser, "At line no : %d unit : func_declaration\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1 -> getName().c_str());
	$<symbol>$ -> setName($<symbol>1 -> getName() + "\n");
}
| func_definition {
	fprintf(parser, "At line no : %d unit : func_definition\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1 -> getName().c_str());
	$<symbol>$ -> setName($<symbol>1 -> getName() + "\n");
}
;

func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
	fprintf(parser, "At line no : %d func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s %s(%s);\n\n", $<symbol>1 -> getName().c_str(), $<symbol>2 -> getName().c_str(), $<symbol>4 -> getName().c_str());
	SymbolInfo *temp = table->lookUp($<symbol>2->getName());
	if(temp != 0){

		if(temp -> getFunction() -> getTotalParameters() != parameters.size()){
			vector<string>pType = temp -> getFunction()-> getParameterType();

			for(int i=0; i<parameters.size(); i++) {
				if(parameters[i] -> getDeclaration() != pType[i]){
					fprintf(errorFile, "Error at Line %d : Type Mismatch \n\n",lines);

					errors++;
					break;
				}
			}
			string returnType = temp->getFunction() -> getRType();
			if(returnType != $<symbol>1 -> getName()){
				
				fprintf(errorFile,"Error at Line %d : Return Type Mismatch \n\n",lines);

				errors++;
			}
			parameters.clear();
			
		}
		else {

			errors++;
			fprintf(errorFile, "Error at Line %d : Parameter size doesn't match \n\n",lines);
		}

	}
	else{
		table->insert($<symbol>2->getName(), "ID", "Function");
		temp = table -> lookUp($<symbol>2 -> getName());
		temp -> setFunction();
		int limit = parameters.size();

		for(int i=0; i<limit; i++){

			temp -> getFunction() -> addParameter(parameters[i]->getName(), parameters[i]->getDeclaration());
		}
		parameters.clear();
		temp -> getFunction() -> setRType($<symbol>1->getName());
		
	}
	$<symbol>$ -> setName($<symbol>1 -> getName() + $<symbol>2 -> getName() + "(" + $<symbol>4 -> getName() + ")" + ";");
}
| type_specifier ID LPAREN RPAREN SEMICOLON {
	fprintf(parser, "At line no : %d func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n", lines);
	fprintf(parser, "%s %s();\n\n", $<symbol>1 -> getName().c_str(), $<symbol>2 -> getName().c_str());
	
	$<symbol>$ = new SymbolInfo();
	
	SymbolInfo* temp = table -> lookUp($<symbol>2 -> getName());
	if(temp != 0){
		int total = temp -> getFunction() -> getTotalParameters();
		if(total != 0){
			
			fprintf(errorFile,"Error at Line %d : Invalid number of parameters \n\n",lines);


			errors++;
		}

		string returnType = temp->getFunction() -> getRType();

		if(returnType != $<symbol>1 -> getName()){
			
			fprintf(errorFile,"Error at Line %d : Return Type Mismatch \n\n",lines);



			errors++;
		}
		


		
	}
	else{
		table->insert($<symbol>2->getName(), "ID", "Function");
		temp = table -> lookUp($<symbol>2 -> getName());
		temp -> setFunction();
		temp -> getFunction() -> setRType($<symbol>1->getName());
	}
	$<symbol>$ -> setName($<symbol>1 -> getName() + $<symbol>2 -> getName() + "(" + ")" + ";");
}
;

func_definition: type_specifier ID LPAREN parameter_list RPAREN {
	$<symbol>$ = new SymbolInfo();




	SymbolInfo *temp = table->lookUp($<symbol>2->getName());
	if(temp == 0){
		table -> insert($<symbol>2 -> getName(), "ID", "Function");
		temp = table -> lookUp($<symbol>2 -> getName());
		temp -> setFunction();
		temp -> getFunction() -> setDefined();

		for(int i=0; i<parameters.size(); i++){
			temp -> getFunction() -> addParameter(parameters[i] -> getName(), parameters[i] -> getDeclaration());
		}
		temp -> getFunction() -> setRType($<symbol>1 -> getName());
	}
	else {
		if(temp->getFunction()->getDefined()==0){
			int totalParameters = temp -> getFunction() -> getTotalParameters();
			if(totalParameters != parameters.size()){
				errors++;
				fprintf(errorFile,"Error at Line %d : Invalid number of parameters \n\n",lines);
			}
			else {
				vector<string>pType = temp -> getFunction()-> getParameterType();
				for(int i=0; i<parameters.size(); i++) {
					if(parameters[i] -> getDeclaration() != pType[i]){
						errors++;
						fprintf(errorFile, "Error at Line %d : Type Mismatch \n\n",lines);
						break;
					}
				}
				if(temp->getFunction() -> getRType() != $<symbol>1 -> getName()){
					errors++;
					fprintf(errorFile,"Error at Line %d : Return Type Mismatch \n\n",lines);
				}
			}
			temp -> getFunction() -> setDefined();
		}
		else {
			errors++;
			fprintf(errorFile,"Error at Line %d : Multiple definition of Function %s\n\n",lines, $<symbol>2->getName().c_str());
		}
	}
} compound_statement {
	fprintf(parser, "At line no : %d func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n", lines);
	$<symbol>$ -> setName($<symbol>1 -> getName() + " " + $<symbol>2 -> getName() + "(" + $<symbol>4 -> getName() + ")" + $<symbol>7 -> getName());



	fprintf(parser, "%s %s(%s)%s\n\n", $<symbol>1 -> getName().c_str(), $<symbol>2 -> getName().c_str(), $<symbol>4 -> getName().c_str(), $<symbol>7 -> getName().c_str());
}

| type_specifier ID LPAREN RPAREN {
	$<symbol>$ = new SymbolInfo();
	SymbolInfo *temp = table -> lookUp($<symbol>2 -> getName());
	if(temp == 0){
		table -> insert($<symbol>2 -> getName(), "ID", "Function");
		temp = table -> lookUp($<symbol>2 -> getName());
		temp -> setFunction();
		temp -> getFunction() -> setDefined();
		temp -> getFunction() -> setRType($<symbol>1 -> getName());
	}
	else if(temp -> getFunction() -> getDefined() == 0) {
		if(temp -> getFunction() -> getRType() != $<symbol>1 -> getName()){
			errors++;
			fprintf(errorFile,"Error at Line %d : Return Type Mismatch \n\n",lines);
		}
		if(temp -> getFunction() -> getTotalParameters() != 0){
			errors++;
			fprintf(errorFile,"Error at Line %d : Invalid number of parameters \n\n",lines);
		}
		temp -> getFunction() -> setDefined();
	}
	else {
		errors++;
		fprintf(errorFile,"Error at Line %d : Multiple definition of Function %s\n\n",lines, $<symbol>2->getName().c_str());
	}
} compound_statement {
	fprintf(parser, "At line no : %d func_definition : type_specifier ID LPAREN RPAREN compound_statement\n", lines);
	fprintf(parser, "%s %s() %s\n\n", $<symbol>1 -> getName().c_str(),$<symbol>2 -> getName().c_str() ,$<symbol>6 -> getName().c_str());
	$<symbol>$ -> setName($<symbol>1 -> getName() +$<symbol>2 -> getName()+"()"+ $<symbol>6 -> getName());
}
;

parameter_list: parameter_list COMMA type_specifier ID {
	fprintf(parser, "At line no : %d parameter_list : parameter_list COMMA type_specifier ID\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s,%s %s\n\n", $<symbol>1 -> getName().c_str(), $<symbol>3 -> getName().c_str(), $<symbol>4 -> getName().c_str());
	$<symbol>$ -> setName($<symbol>1 -> getName() + "," + $<symbol>3 -> getName() + " " + $<symbol>4 -> getName());
}
| parameter_list COMMA type_specifier {
	fprintf(parser, "At line no : %d parameter_list : parameter_list COMMA type_specifier\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s,%s\n\n", $<symbol>1 -> getName().c_str(), $<symbol>3 -> getName().c_str());
	$<symbol>$ -> setName($<symbol>1 -> getName() + "," + $<symbol>3 -> getName());
}
| type_specifier ID {
	fprintf(parser, "At line no : %d parameter_list : type_specifier ID\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s %s\n\n", $<symbol>1 -> getName().c_str(), $<symbol>2 -> getName().c_str());
	$<symbol>$ -> setName($<symbol>1 -> getName() + " " + $<symbol>2 -> getName());
}
| type_specifier {
	fprintf(parser, "At line no : %d parameter_list : type_specifier\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1 -> getName().c_str());
	$<symbol>$ -> setName($<symbol>1 -> getName() + " ");
}
;

compound_statement: LCURL {
	table -> enterScope(7);
	for(int i=0; i<parameters.size(); i++){
		table -> insert(parameters[i]->getName(), "ID", parameters[i] -> getDeclaration());
	}
	parameters.clear();
} statements RCURL {
	fprintf(parser, "At line no : %d compound_statement : LCURL statements RCURL\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "{\n%s\n}\n\n", $<symbol>3 -> getName().c_str());
	$<symbol>$ -> setName("{\n" + $<symbol>3 -> getName() + "\n}");
	//table -> printAllScopeTables();
	table -> exitScope();
}
| LCURL RCURL {
	table -> enterScope(7);
	for(int i=0; i<parameters.size(); i++){
		table -> insert(parameters[i]->getName(), "ID", parameters[i] -> getDeclaration());
	}
	parameters.clear();
	fprintf(parser, "At line no : %d compound_statement : LCURL RCURL\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "{}\n\n");
	$<symbol>$ -> setName("{}");
	//table -> printAllScopeTables();
	table -> exitScope();
}
;

var_declaration: type_specifier declaration_list SEMICOLON {
	fprintf(parser, "At line no : %d var_declaration : type_specifier declaration_list SEMICOLON\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s %s;\n\n", $<symbol>1->getName().c_str(), $<symbol>2->getName().c_str());
	if($<symbol>1 -> getName() == "void "){
		errors++;
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);
	}
	else {
		for(int i =0; i<declarations.size(); i++){
			if(table -> findCurrent(declarations[i]->getName())) {
				errors++;
				fprintf(errorFile,"Error at Line %d : Multiple declaration of variable %s\n\n",lines, declarations[i]->getName().c_str());
				continue;
			}
			if(declarations[i]-> getType().size()==3){
				declarations[i] -> setType(declarations[i] -> getType().substr(0, declarations[i] -> getType().size()-1));
				table -> insert(declarations[i]->getName(), declarations[i] -> getType(), $<symbol>1 -> getName()+"array");
			}
			else {
				table -> insert(declarations[i] -> getName(), declarations[i] -> getType(), $<symbol>1 -> getName());
			}
		}
	}
	declarations.clear();
	$<symbol>$ -> setName($<symbol>1 -> getName() + " " + $<symbol>2 -> getName() + ";");
}
;

type_specifier: INT {
	fprintf(parser, "At line no : %d type_specifier : INT\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "int \n\n");
	$<symbol>$ -> setName("int ");
}
| FLOAT {
	fprintf(parser, "At line no : %d type_specifier : FLOAT\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "float \n\n");
	$<symbol>$ -> setName("float ");
}
| VOID {
	fprintf(parser, "At line no : %d type_specifier : VOID \n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "void \n\n");
	$<symbol>$ -> setName("void ");
}
;

declaration_list: declaration_list COMMA ID {
	fprintf(parser, "At line no : %d declaration_list : declaration_list COMMA ID\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s,%s\n\n", $<symbol>1->getName().c_str(), $<symbol>3->getName().c_str());
	declarations.push_back(new SymbolInfo($<symbol>3 -> getName(), "ID"));
	$<symbol>$ -> setName($<symbol>1 -> getName() + "," + $<symbol>3 -> getName());
}
| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
	fprintf(parser, "At line no : %d declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s,%s[%s]\n\n", $<symbol>1 -> getName().c_str(), $<symbol>3 -> getName().c_str(), $<symbol>5 -> getName().c_str());
	declarations.push_back(new SymbolInfo($<symbol>3 -> getName(), "IDa"));
	$<symbol>$ -> setName($<symbol>1 -> getName() + "," + $<symbol>3 -> getName() + "[" + $<symbol>5 -> getName() + "]");
}
| ID {
	fprintf(parser, "At line no : %d declaration_list : ID\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1->getName().c_str());
	declarations.push_back(new SymbolInfo($<symbol>1 -> getName(), "ID"));
	$<symbol>$ -> setName($<symbol>1 -> getName());
}
| ID LTHIRD CONST_INT RTHIRD {
	fprintf(parser, "At line no : %d declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s[%s]\n\n", $<symbol>1 -> getName().c_str(), $<symbol>3 -> getName().c_str());
	declarations.push_back(new SymbolInfo($<symbol>3 -> getName(), "IDa"));
	$<symbol>$ -> setName($<symbol>1 -> getName() + "[" + $<symbol>3 -> getName() + "]");
}
;

statements: statement {
	fprintf(parser, "At line no : %d statements : statement\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1 -> getName().c_str());	
	$<symbol>$ -> setName($<symbol>1 -> getName());
}
| statements statement {
	fprintf(parser, "At line no : %d statements : statements statement\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s \n%s\n\n", $<symbol>1 -> getName().c_str(), $<symbol>2 -> getName().c_str());
	$<symbol>$ -> setName($<symbol>1 -> getName() + "\n" + $<symbol>2 -> getName());
}
;

statement: var_declaration {
	fprintf(parser, "At line no : %d statement : var_declaration\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1 -> getName().c_str());
	$<symbol>$ -> setName($<symbol>1 -> getName());
}
| expression_statement {
	fprintf(parser, "At line no : %d statement : expression_statement\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1 -> getName().c_str());
	$<symbol>$ -> setName($<symbol>1 -> getName());
}
| compound_statement {
	fprintf(parser, "At line no : %d statement : compound_statement\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1 -> getName().c_str());
	$<symbol>$ -> setName($<symbol>1 -> getName());
}
| FOR LPAREN expression_statement expression_statement expression RPAREN statement {
	fprintf(parser, "At line no : %d statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "for(%s %s %s)\n%s\n", $<symbol>3 -> getName().c_str(), $<symbol>4 -> getName().c_str(), $<symbol>5 -> getName().c_str(), $<symbol>7 -> getName().c_str());
	if($<symbol>3 -> getDeclaration() == "void "){
		errors++;
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);
	}
	$<symbol>$ -> setName("for(" + $<symbol>3 -> getName()+$<symbol>4 -> getName()+$<symbol>5 -> getName()+")" + "\n" + $<symbol>7 -> getName());
}
| IF LPAREN expression RPAREN statement %prec AFTER_ELSE {
	fprintf(parser, "At line no : %d statement : IF LPAREN expression RPAREN statement\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "if(%s)\n %s \n\n", $<symbol>3 -> getName().c_str(), $<symbol>5 -> getName().c_str());
	if($<symbol>3 -> getDeclaration() == "void "){
		errors++;
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);
	}
	$<symbol>$ -> setName("if(" + $<symbol>3 -> getName()+ ")" + "\n" + $<symbol>5 -> getName());

}
| IF LPAREN expression RPAREN statement ELSE statement {
	fprintf(parser, "At line no : %d statement : IF LPAREN expression RPAREN statement ELSE statement\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "if(%s)\n%s\n else \n %s \n\n", $<symbol>3 -> getName().c_str(), $<symbol>5 -> getName().c_str(), $<symbol>7 -> getName().c_str());
	if($<symbol>3 -> getDeclaration() == "void "){
		errors++;
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);
	}
	$<symbol>$ -> setName("if(" + $<symbol>3 -> getName()+ ")" + "\n" + $<symbol>5 -> getName() + "\n" + "else" + "\n" + $<symbol>7 -> getName());
}
| WHILE LPAREN expression RPAREN statement {
	fprintf(parser, "At line no : %d statement : WHILE LPAREN expression RPAREN statement\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "while(%s)\n %s \n\n", $<symbol>3 -> getName().c_str(), $<symbol>5 -> getName().c_str());
	if($<symbol>3 -> getDeclaration() == "void "){
		errors++;
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);
	}
	$<symbol>$ -> setName("while(" + $<symbol>3 -> getName()+ ")" + "\n" + $<symbol>5 -> getName());
}
| PRINTLN LPAREN ID RPAREN SEMICOLON {
	fprintf(parser, "At line no : %d statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "\n (%s); \n\n", $<symbol>3 -> getName().c_str());
	$<symbol>$ -> setName("\n(" + $<symbol>3 -> getName()+ ")" + ";");
}
| RETURN expression SEMICOLON {
	fprintf(parser, "At line no : %d statement : RETURN expression SEMICOLON\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "return %s;\n\n", $<symbol>2 -> getName().c_str());
	if($<symbol>2 -> getDeclaration() == "void "){
		errors++;
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);
		$<symbol>$ -> setDeclaration("void ");
	}
	$<symbol>$ -> setName("return " + $<symbol>2 -> getName()+ ";");
}
;

expression_statement: SEMICOLON {
	fprintf(parser, "At line no : %d expression_statement : SEMICOLON\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, ";\n\n");
	$<symbol>$ -> setName(";");
}
| expression SEMICOLON {
	fprintf(parser, "At line no : %d expression_statement : expression SEMICOLON\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s ;\n\n", $<symbol>1 -> getName().c_str());
	$<symbol>$ -> setName($<symbol>1 -> getName()+ ";");
}
;

variable: ID {
	fprintf(parser, "At line no : %d variable : ID\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1 -> getName().c_str());
	if(table -> lookUp($<symbol>1 -> getName())==0){
		errors++;
		fprintf(errorFile,"Error at Line %d : Undeclared variable: %s\n\n",lines, $<symbol>1 -> getName().c_str());
	}
	else if(table -> lookUp($<symbol>1 -> getName())-> getDeclaration() == "int array" || table -> lookUp($<symbol>1 -> getName())-> getDeclaration() == "float array" ){
		errors++;
		fprintf(errorFile,"Error at Line %d : %s is not an array\n\n",lines, $<symbol>1 -> getName().c_str());
	}
	if(table -> lookUp($<symbol>1 -> getName()) != 0){
		$<symbol>$ -> setDeclaration(table -> lookUp($<symbol>1 -> getName()) -> getDeclaration());
	}
	$<symbol>$ -> setName($<symbol>1 -> getName());


}
| ID LTHIRD expression RTHIRD {
	fprintf(parser, "At line no : %d variable : ID LTHIRD expression RTHIRD\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s[%s]\n\n", $<symbol>1 -> getName().c_str(), $<symbol>3 -> getName().c_str());
	if(table -> lookUp($<symbol>1 -> getName())==0){
		errors++;
		fprintf(errorFile,"Error at Line %d : Undeclared variable : %s \n\n",lines, $<symbol>1 -> getName().c_str());
	}
	if($<symbol>3 -> getDeclaration() == "float " || $<symbol>3 -> getDeclaration() == "void ") {
		errors++;
		fprintf(errorFile,"Error at Line %d : Invalid array type \n\n",lines);
	}
	if(table -> lookUp($<symbol>1 -> getName()) != 0){
		if(table -> lookUp($<symbol>1 -> getName()) -> getDeclaration() != "int array" && table -> lookUp($<symbol>1 -> getName()) -> getDeclaration() != "float array"){
			errors++;
			fprintf(errorFile,"Error at Line %d : Type Mismatch \n\n",lines);
		}
		if(table -> lookUp($<symbol>1 -> getName()) -> getDeclaration() == "int array"){
			$<symbol>1 -> setDeclaration("int ");
		}
		if(table -> lookUp($<symbol>1 -> getName()) -> getDeclaration() == "float array"){
			$<symbol>1 -> setDeclaration("float ");
		}
		$<symbol>$ -> setDeclaration($<symbol>1 -> getDeclaration());
	}
	$<symbol>$ -> setName($<symbol>1 -> getName() + "[" + $<symbol>3 -> getName() + "]");

}
;

expression: logic_expression {
	fprintf(parser, "At line no : %d expression : logic_expression\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1 -> getName().c_str());
	$<symbol>$ -> setName($<symbol>1 -> getName());
	$<symbol>$ -> setDeclaration($<symbol>1 -> getDeclaration());
}
| variable ASSIGNOP logic_expression {
	fprintf(parser, "At line no : %d expression : variable ASSIGNOP logic_expression\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s=%s\n\n", $<symbol>1 -> getName().c_str(), $<symbol>3 -> getName().c_str());
	if($<symbol>3 -> getDeclaration() == "void"){
		errors++;
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);
		$<symbol>$ -> setDeclaration("int ");
	}
	else if(table -> lookUp($<symbol>1 -> getName()) != 0){
		if(table -> lookUp($<symbol>1 -> getName())-> getDeclaration() != $<symbol>3 -> getDeclaration()){
			errors++;
			fprintf(errorFile,"Error at Line %d : Type mismatch\n\n",lines);
		}
	}
	$<symbol>$ -> setName($<symbol>1 -> getName()+"=" + $<symbol>3 -> getName());
	$<symbol>$ -> setDeclaration($<symbol>1 -> getDeclaration());
}
;

logic_expression: rel_expression {
	fprintf(parser, "At line no : %d logic_expression : rel_expression\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1->getName().c_str());
	$<symbol>$ -> setDeclaration($<symbol>1 ->getDeclaration());
	$<symbol>$ -> setName($<symbol>1 -> getName())
}
| rel_expression LOGICOP rel_expression {
	fprintf(parser, "At line no : %d logic_expression : rel_expression LOGICOP rel_expression\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s%s%s\n\n", $<symbol>1->getName().c_str(), $<symbol>2->getName().c_str(), $<symbol>3->getName().c_str());
	if($<symbol>1->getDeclaration() == "void " || $<symbol>3->getDeclaration() == "void ") {
		errors++;
		fprintf(errorFile,"Error at Line %d : Type mismatch\n\n",lines);
	}
	$<symbol>$ -> setDeclaration("int ");
	$<symbol>$ -> setName($<symbol>1 -> getName()+ $<symbol>2->getName()+ $<symbol>3->getName().c_str());
}
;

rel_expression: simple_expression {
	fprintf(parser, "At line no : %d rel_expression : simple_expression\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1->getName().c_str());
	$<symbol>$ -> setDeclaration($<symbol>1 ->getDeclaration());
	$<symbol>$ -> setName($<symbol>1 -> getName())
}
| simple_expression RELOP simple_expression {
	fprintf(parser, "At line no : %d rel_expression : simple_expression RELOP simple_expression\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s%s%s\n\n", $<symbol>1->getName().c_str(), $<symbol>2->getName().c_str(), $<symbol>3->getName().c_str());
	if($<symbol>1->getDeclaration() == "void " || $<symbol>3->getDeclaration() == "void ") {
		errors++;
		fprintf(errorFile,"Error at Line %d : Type mismatch\n\n",lines);
	}
	$<symbol>$ -> setDeclaration("int ");
	$<symbol>$ -> setName($<symbol>1 -> getName()+ $<symbol>2->getName()+ $<symbol>3->getName().c_str());
}
;

simple_expression: term {
	fprintf(parser, "At line no : %d simple_expression : term\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1->getName().c_str());
	$<symbol>$ -> setDeclaration($<symbol>1 ->getDeclaration());
	$<symbol>$ -> setName($<symbol>1 -> getName());
}
| simple_expression ADDOP term {
	fprintf(parser, "At line no : %d simple_expression : simple_expression ADDOP term\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s%s%s\n\n", $<symbol>1->getName().c_str(), $<symbol>2->getName().c_str(), $<symbol>3->getName().c_str());
	if($<symbol>1->getDeclaration() == "void " || $<symbol>3->getDeclaration() == "void ") {
		errors++;
		fprintf(errorFile,"Error at Line %d : Type mismatch\n\n",lines);
		$<symbol>$ -> setDeclaration("int ");
	}
	else if($<symbol>1->getDeclaration() == "float " || $<symbol>3->getDeclaration() == "float ") {
		$<symbol>$ -> setDeclaration("float ");
	}
	else $<symbol>$ -> setDeclaration("int ");
	$<symbol>$ -> setName($<symbol>1 -> getName()+ $<symbol>2->getName()+ $<symbol>3->getName().c_str());
}
;

term: unary_expression {
	fprintf(parser, "At line no : %d term : unary_expression\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<symbol>1->getName().c_str());
	$<symbol>$ -> setDeclaration($<symbol>1 ->getDeclaration());
	$<symbol>$ -> setName($<symbol>1 -> getName());
}
| term MULOP unary_expression {
	fprintf(parser, "At line no : %d term : term MULOP unary_expression\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s%s%s\n\n", $<symbol>1->getName().c_str(), $<symbol>2->getName().c_str(), $<symbol>3->getName().c_str());
	if($<symbol>1->getDeclaration() == "void " || $<symbol>3->getDeclaration() == "void ") {
		errors++;
		fprintf(errorFile,"Error at Line %d : Type mismatch\n\n",lines);
		$<symbol>$ -> setDeclaration("int ");
	}
	else if($<symbol>2 -> getName() == "/"){
		if($<symbol>1->getDeclaration() == "int " && $<symbol>3->getDeclaration() == "int ")
			$<symbol>$ -> setDeclaration("int ");
		else $<symbol>$ -> setDeclaration("float ");
	}
	else if($<symbol>2 -> getName() == "%"){
		if($<symbol>1->getDeclaration() != "int " || $<symbol>3->getDeclaration() != "int ") {
			errors++;
			fprintf(errorFile,"Error at Line %d : Both operand of modulus operator must be integer\n\n",lines);
		}
		$<symbol>$ -> setDeclaration("int ");
	}
	else {
		if($<symbol>1->getDeclaration() == "float " && $<symbol>3->getDeclaration() == "float ")
			$<symbol>$ -> setDeclaration("float ");
		else $<symbol>$ -> setDeclaration("int ");
	}
	$<symbol>$ -> setName($<symbol>1 -> getName()+ $<symbol>2->getName()+ $<symbol>3->getName());
}
;

unary_expression: ADDOP unary_expression {
	fprintf(parser, "At line no : %d unary_expression : ADDOP unary_expression\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s%s\n\n", $<symbol>1->getName().c_str(), $<symbol>2->getName().c_str());
	if($<symbol>2 -> getDeclaration() == "void "){
		errors++;
		fprintf(errorFile,"Error at Line %d : Type mismatch\n\n",lines);
		$<symbol>$ -> setDeclaration("int ");
	}
	else {
		$<symbol>$ -> setDeclaration($<symbol>2 -> getDeclaration());
	}
	$<symbol>$ -> setName($<symbol>1 -> getName()+ $<symbol>2->getName());

}
| NOT unary_expression {
	fprintf(parser, "At line no : %d unary_expression : NOT unary_expression\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "!%s\n\n",$<symbol>2->getName().c_str());
	if($<symbol>2 -> getDeclaration() == "void "){
		errors++;
		fprintf(errorFile,"Error at Line %d : Type mismatch\n\n",lines);
		$<symbol>$ -> setDeclaration("int ");
	}
	else {
		$<symbol>$ -> setDeclaration($<symbol>2 -> getDeclaration());
	}
	$<symbol>$ -> setName("!"+ $<symbol>2->getName());
}
| factor {
	fprintf(parser, "At line no : %d unary_expression : factor\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n",$<symbol>1->getName().c_str());
	$<symbol>$ -> setDeclaration($<symbol>1-> getDeclaration());
	$<symbol>$ -> setName($<symbol>1->getName());
}
;

factor: variable {
	fprintf(parser, "At line no : %d factor : variable\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n",$<symbol>1->getName().c_str());
	$<symbol>$ -> setDeclaration($<symbol>1 -> getDeclaration());
	$<symbol>$ -> setName($<symbol>1->getName());
}
| ID LPAREN argument_list RPAREN {
	fprintf(parser, "At line no : %d factor : ID LPAREN argument_list RPAREN\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s(%s)\n\n",$<symbol>1->getName().c_str(), $<symbol>3->getName().c_str());
	SymbolInfo *temp = table -> lookUp($<symbol>1->getName());
	if(temp == 0){
		errors++;
		fprintf(errorFile,"Error at Line %d : Undeclared function\n\n",lines);
		$<symbol>$->setDeclaration("int ");
	}
	else if(temp -> getFunction() == 0){
		errors++;
		fprintf(errorFile,"Error at Line %d : Not a function\n\n",lines);
		$<symbol>$->setDeclaration("int ");
	}
	else{
		if(temp -> getFunction() -> getDefined() == 0){
			errors++;
			fprintf(errorFile,"Error at Line %d : Undeclared function\n\n",lines);
		}
		int p = temp -> getFunction() -> getTotalParameters();
		$<symbol>$ -> setDeclaration(temp -> getFunction() -> getRType());
		if(p != arguments.size()){
			errors++;
			fprintf(errorFile,"Error at Line %d : Invalid number of arguments\n\n",lines);
		}
		else{
			vector<string> pl = temp -> getFunction() -> getParameterList();
			vector<string> pt = temp -> getFunction() -> getParameterType();
			for(int i=0; i<arguments.size(); i++){
				if(arguments[i]->getDeclaration()!=pt[i]){
					errors++;
					fprintf(errorFile,"Error at Line %d : Type mismatch\n\n",lines);
					break;
				}
			}
		}
	}
	arguments.clear();
	$<symbol>$ -> setName($<symbol>1->getName()+ "(" + $<symbol>3->getName() + ")");
}
| LPAREN expression RPAREN {
	fprintf(parser, "At line no : %d factor : LPAREN expression RPAREN\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "(%s)\n\n",$<symbol>2->getName().c_str());
	$<symbol>$ -> setDeclaration($<symbol>2 -> getDeclaration());
	$<symbol>$ -> setName("("+ $<symbol>2->getName()+")");
}
| CONST_INT {
	fprintf(parser, "At line no : %d factor : CONST_INT\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n",$<symbol>1->getName().c_str());
	$<symbol>$ -> setDeclaration("int ");
	$<symbol>$ -> setName($<symbol>1->getName());
}
| CONST_FLOAT {
	fprintf(parser, "At line no : %d factor : CONST_FLOAT\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n",$<symbol>1->getName().c_str());
	$<symbol>$ -> setDeclaration("float ");
	$<symbol>$ -> setName($<symbol>1->getName());
}
| variable INCOP {
	fprintf(parser, "At line no : %d factor : variable INCOP\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n",$<symbol>1->getName().c_str());
	$<symbol>$ -> setDeclaration($<symbol>1 -> getDeclaration());
	$<symbol>$ -> setName($<symbol>1->getName() + "++");
}
| variable DECOP {
	fprintf(parser, "At line no : %d factor : variable DECOP\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n",$<symbol>1->getName().c_str());
	$<symbol>$ -> setDeclaration($<symbol>1 -> getDeclaration());
	$<symbol>$ -> setName($<symbol>1->getName()+"--");
}
;


argument_list: arguments {
	fprintf(parser, "At line no : %d argument_list : arguments\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n",$<symbol>1->getName().c_str());
	$<symbol>$ -> setName($<symbol>1->getName());
}
|  {
	fprintf(parser, "At line no : %d argument_list : \n\n", lines);
	$<symbol>$ = new SymbolInfo();
	$<symbol>$ -> setName("");
}
;

arguments: arguments COMMA logic_expression {
	fprintf(parser, "At line no : %d arguments : arguments COMMA logic_expression\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s,%s\n\n",$<symbol>1->getName().c_str(), $<symbol>3->getName().c_str());
	arguments.push_back($<symbol>3);
	$<symbol>$ -> setName($<symbol>1->getName()+ "," + $<symbol>3->getName());
}
| logic_expression {
	fprintf(parser, "At line no : %d arguments : logic_expression\n\n", lines);
	$<symbol>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n",$<symbol>1->getName().c_str());
	arguments.push_back(new SymbolInfo($<symbol>1->getName(), $<symbol>1->getType(), $<symbol>1->getDeclaration()));
	$<symbol>$ -> setName($<symbol>1->getName());
} 







%%



int main(int argc,char *argv[])
{

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	yyin=fp;
	table -> enterScope(7);
	yyparse();


	fprintf(parser, "Total lines : %d\n",lines);
	fprintf(errorFile, "Total errors : %d", errors);


	fclose(fp);
	fclose(parser);
	fclose(errorFile);

	return 0;
}
