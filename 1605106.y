%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<cstdio>
#include <limits>
#include <sstream>
#include<vector>
#include "1605106_SymbolTable.h"
using namespace std;
int yyparse(void);
extern "C" int yylex(void);
extern FILE *yyin;

vector<string> declaredVariables;
vector<string> declaredFunctions;
vector<pair<string, string>> declaredArrays;

string global;
vector<SymbolInfo*> parameters;
vector<SymbolInfo*> declarations;
vector<SymbolInfo*> arguments;





FILE *parser = fopen("1605106_info.txt", "w");
FILE *errorFile = fopen("1605106_log.txt", "w");
FILE *fp;




SymbolTable *myTable = new SymbolTable(20);
int lines = 1;
int errors = 0;

void yyerror(char *s){cerr << "Line no" << lines << endl;}

int labelCount=0;
int tempCount=0;

char *newTemp()
{
	char *temp= new char[4];
	strcpy(temp,"t");
	char array[3];
	sprintf(array,"%d", tempCount);
	tempCount++;
	strcat(temp,array);
	return temp;
}

char *newLabel()
{
	char *label= new char[4];
	strcpy(label,"L");
	char array[3];
	sprintf(array,"%d", labelCount);
	labelCount++;
	strcat(label,array);
	return label;
}



void optimize(FILE *asmcode);



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
	if(errors==0){
		string assembly = ".MODEL SMALL\n\.STACK 100H\n\.DATA";
		for(int i=0; i<declaredVariables.size();i++){
			assembly = assembly + "\n"+declaredVariables[i]+" dw ?";
		}
		for(int i=0;i<declaredArrays.size();i++){
			assembly = assembly+"\n"+declaredArrays[i].first+" dw "+declaredArrays[i].second+" dup(?)";
		}
		assembly = assembly + "\n.CODE\n" + $<var>1 -> getAssembly()+"\nOUTDEC PROC  \n PUSH AX \nPUSH BX \nPUSH CX \nPUSH DX  \nCMP AX,0 \nJGE BEGIN \nPUSH AX \nMOV DL,'-' \nMOV AH,2 \nINT 21H \nPOP AX \nNEG AX \n\n BEGIN: \nXOR CX,CX \nMOV BX,10 \n\nREPEAT: \nXOR DX,DX \nDIV BX \nPUSH DX \nINC CX \nOR AX,AX \nJNE REPEAT \nMOV AH,2 \n\nPRINT_LOOP: \nPOP DX \nADD DL,30H \nINT 21H \nLOOP PRINT_LOOP \n\nMOV AH,2\nMOV DL,10\nINT 21H\n\nMOV DL,13\nINT 21H\n\nPOP DX \n POP CX \n POP BX \n POP AX \n ret \nOUTDEC ENDP \nEND MAIN\n";
		$<var>1 -> setAssembly(assembly);
		FILE *asmConverted = fopen("code.asm", "w");
		fprintf(asmConverted, "%s", $<var>1 -> getAssembly().c_str());
		fclose(asmConverted);
		asmConverted = fopen("code.asm","r");
		optimize(asmConverted);
	}
}
;

program: program unit {
	fprintf(parser, "At line no : %d program : program unit\n\n", lines);
	$<var>$ = new SymbolInfo(); $<var>$ -> setName($<var>1 -> getName() + $<var>2 -> getName()); fprintf(parser, "%s %s\n\n", $<var>1 -> getName().c_str(), $<var>2 -> getName().c_str());
	$<var>$ -> setAssembly($<var>1 -> getAssembly()+$<var>2 -> getAssembly());
}
| unit {
	fprintf(parser, "At line no : %d program : unit\n\n", lines);
	$<var>$ = new SymbolInfo(); $<var>$ -> setName($<var>1 -> getName()); fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	$<var>$ -> setAssembly($<var>1 -> getAssembly());
}
;

unit: var_declaration { 
	fprintf(parser, "At line no : %d unit : var_declaration\n\n", lines);
	$<var>$ = new SymbolInfo();
	declaredFunctions.clear();
	$<var>$ -> setAssembly($<var>1 -> getAssembly());
	$<var>$ -> setName($<var>1 -> getName()+"\n");fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	
}
| func_declaration {
	fprintf(parser, "At line no : %d unit : func_declaration\n\n", lines);
	$<var>$ = new SymbolInfo();
	$<var>$ -> setAssembly($<var>1 -> getAssembly());
	$<var>$ -> setName($<var>1 -> getName() + "\n"); fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	
}
| func_definition {
	fprintf(parser, "At line no : %d unit : func_definition\n\n", lines);
	$<var>$ = new SymbolInfo();
	$<var>$ -> setAssembly($<var>1 -> getAssembly());
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
		//cout << "Check totalparameter " << temp -> getMethod() -> getTotalParameters() << endl;
		if(temp -> getMethod() -> getTotalParameters() != parameters.size()){
			vector<string>pType = temp -> getMethod()-> getParameterType();
			int limit = parameters.size();
			for(int i=0; i < limit; i++) {
				string decI = parameters[i] -> getDeclaration(); 
				if(decI != pType[i]){
					fprintf(errorFile, "Error at Line %d : Type Mismatch \n\n",lines);
					errors++;
					break;
				}
			}
			string returnType = temp->getMethod() -> getRType();
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
		myTable->insert($<var>2->getName(), "ID", "Method");
		temp = myTable -> lookUp(name2);
		temp -> setMethod();
		int limit = parameters.size();
		
		
		
		for(int i=0; i<limit; i++){
			string paramName = parameters[i]->getName();
			string paramDec = parameters[i]->getDeclaration();
			temp -> getMethod() -> addParameter(paramName, paramDec);
		}
		//cout << "Check size " << parameters.size()<< endl;
		parameters.clear();
		string n = $<var>1->getName();
		temp -> getMethod() -> setRType(n);
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
		int total = temp -> getMethod() -> getTotalParameters();
		
		
		if(total != 0){
			
			fprintf(errorFile,"Error at Line %d : Invalid number of parameters \n\n",lines);


			errors++;
		}

		string returnType = temp->getMethod() -> getRType();

		if(returnType != $<var>1 -> getName()){
			
			fprintf(errorFile,"Error at Line %d : Return Type Mismatch \n\n",lines);



			errors++;
		}
		


		
	}
	else{
		string var2Name = $<var>2->getName();
		myTable->insert(var2Name, "ID", "Method");
		temp = myTable -> lookUp(var2Name);
		string var1Name = $<var>1->getName();
		temp -> setMethod(); //this creates the Method for temp
		//now the Method must have a return type
		temp -> getMethod() -> setRType(var1Name);
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
	//cout << "line " << lines << " " <<name2<< endl;
	SymbolInfo *temp = myTable->lookUp(name2);
	//cout << temp-> getName() << " line " << lines << endl;
	if(temp != 0){
		//cout << "line yay " << lines << " " <<name2<< endl;
		bool def = temp->getMethod()->getDefined();
		if(def != 0){
			fprintf(errorFile,"Error at Line %d : Multiple definition of function %s\n\n",lines, $<var>2->getName().c_str());
			errors++;
		}
		else {
			if(temp -> getMethod() -> getTotalParameters() != parameters.size()){
				fprintf(errorFile,"Error at Line %d : Invalid number of parameters \n\n",lines);
				errors++;
			}
			else {
				vector<string>pType = temp -> getMethod()-> getParameterType();
				int limit = parameters.size();
				for(int i=0; i<limit; i++) {
					string paramDec = parameters[i] -> getDeclaration();
					if(paramDec != pType[i]){
						fprintf(errorFile, "Error at Line %d : Type Mismatch \n\n",lines);
						errors++;
						break;
					}
				}
				string returnType = temp->getMethod() -> getRType();
				string n1 = $<var>1 -> getName();
				if(returnType != n1){
					fprintf(errorFile,"Error at Line %d : Return Type Mismatch \n\n",lines);
					errors++;
				}
			}
			temp -> getMethod() -> clear();
			for(int i=0; i<parameters.size();i++){
				int c = myTable -> currentScopeID + 1;
				ostringstream a;
				a<<c;
				string s = a.str(); 
				string name = parameters[i] -> getName() + s;
				//cout << "line " << lines << " " <<name<< endl;
				string type = parameters[i] -> getDeclaration();
				temp -> getMethod() -> addParameter(name, type);
			}
			temp -> getMethod() -> setDefined();
		}
	}
	else {
		string type = "ID";string dec = "Method";
		//cout <<" name " << name2 <<  myTable -> insert(name2, type, dec) << endl;
		myTable -> insert(name2, type, dec);
		temp = myTable -> lookUp(name2);
		//cout << temp -> getName() << endl;
		temp -> setMethod();
		temp -> getMethod() -> setDefined();
		int limit = parameters.size();
		string returnType = $<var>1 -> getName();
		//cout << "LIMIT " << limit << endl;
		for(int i=0; i<limit; i++){ 
			int c = myTable -> currentScopeID + 1;
			ostringstream a;
			a<<c;
			string s = a.str(); 
			string paramName = parameters[i] -> getName() + s;
			string paramDec = parameters[i] -> getDeclaration();
			//cout << "line " << lines << " " <<paramName<< endl;
			temp -> getMethod() -> addParameter(paramName, paramDec);
			}
		temp -> getMethod() -> setRType(returnType);
	}
	global = name2;
	declaredVariables.push_back(global+"_return");
} compound_statement {
	string v1 = $<var>1 -> getName();
	string v2 = $<var>2 -> getName();
	string v4 = $<var>4 -> getName();
	string v7 = $<var>7 -> getName(); 
	string var = v1 + " " + v2 + "(" + v4 + ")" + v7;
	fprintf(parser, "At line no : %d func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n", lines);
	fprintf(parser, "%s %s(%s) %s\n\n", $<var>1 -> getName().c_str(), $<var>2 -> getName().c_str(), $<var>4 -> getName().c_str(), $<var>7 -> getName().c_str());
	$<var>$ -> setAssembly(v2+" PROC");
	if(v2=="main"){
		string assembly = $<var>$ -> getAssembly() + " \nMOV AX,@DATA\nMOV DS,AX\n"+ $<var>7 -> getAssembly();
		assembly = assembly + "\nLReturn" + global + ":\nMOV AH,4CH\nINT 21H";
		$<var>$ -> setAssembly(assembly);
	}
	else{
		SymbolInfo *temp = myTable -> lookUp(v2);
		for(int i = 0;i<declaredFunctions.size();i++){
			temp -> getMethod() -> addVariable(declaredFunctions[i]);
		}
		declaredFunctions.clear();
		vector<string> variableList = temp -> getMethod() -> getListOfVariable();
		string assembly = $<var>$ -> getAssembly() + "\nPUSH AX\nPUSH BX\nPUSH CX\nPUSH DX";
		vector<string> parameterList = temp -> getMethod() -> getParameterList();
		int psize = parameterList.size();
		int vsize = variableList.size();
		for(int i=0; i<psize;i++){
			//cout << parameterList[i] << endl;
			assembly = assembly + "\nPUSH "+ parameterList[i];
		}
		for(int i=0; i<vsize;i++){
			assembly = assembly + "\nPUSH " + variableList[i];
		}
		assembly = assembly + $<var>7 -> getAssembly() + "\nLReturn"+global+":";
		for(int i=vsize-1; i>=0; i--){
			assembly = assembly + "\nPOP " + variableList[i];
		}
		for(int i=psize-1; i>=0; i--){
			assembly = assembly + "\nPOP " + parameterList[i];
		}
		assembly = assembly + "\nPOP AX\nPOP BX\nPOP CX\nPOP DX\nRET\n";
		$<var>$ -> setAssembly(assembly+v2+ " ENDP\n");
	}
	$<var>$ -> setName(var);
	//cout << $<var>1 -> getName() << endl;
}
| type_specifier ID LPAREN RPAREN {
	$<var>$ = new SymbolInfo();
	string name2 = $<var>2 -> getName();
	string name1 = $<var>1 -> getName();
	SymbolInfo *temp = myTable -> lookUp(name2);
	if(temp == 0){
		myTable -> insert(name2, "ID", "Method");
		temp = myTable -> lookUp(name2);
		temp -> setMethod();
		temp -> getMethod() -> setDefined();
		temp -> getMethod() -> setRType(name1);
	}
	else if(temp -> getMethod() -> getDefined() == 0) {
		int total = temp -> getMethod() -> getTotalParameters();
		string returnType = temp -> getMethod() -> getRType();
		if(total != 0){
			fprintf(errorFile,"Error at Line %d : Invalid number of parameters \n\n",lines);
			errors++;
		}
		if(returnType != name1){
			fprintf(errorFile,"Error at Line %d : Return Type Mismatch \n\n",lines);
			errors++;
		}
		temp -> getMethod() -> setDefined();
	}
	else {	
		fprintf(errorFile,"Error at Line %d : Multiple definition of function %s\n\n",lines, $<var>2->getName().c_str());
		errors++;
		}
	global = name2;
	declaredVariables.push_back(global+"_return");
	$<var>1 -> setName(name1+" "+name2+"()");
} compound_statement {
	fprintf(parser, "At line no : %d func_definition : type_specifier ID LPAREN RPAREN compound_statement\n", lines);
	fprintf(parser, "%s %s() %s\n\n", $<var>1 -> getName().c_str(),$<var>2 -> getName().c_str() ,$<var>6 -> getName().c_str());
	string name1 = $<var>1 -> getName();
	string name2 = $<var>2 -> getName();
	string name6 = $<var>6 -> getName();
	$<var>$ -> setAssembly(name2+" PROC");
	if(name2=="main"){
		string assembly = $<var>$ -> getAssembly() + " \nMOV AX,@DATA\nMOV DS,AX\n"+ $<var>6 -> getAssembly();
		assembly = assembly + "\nLReturn" + global + ":\nMOV AH,4CH\nINT 21H";
		$<var>$ -> setAssembly(assembly);
	}
	else{
		SymbolInfo *temp = myTable -> lookUp(name2);
		int ds = declaredFunctions.size();
		for(int i = 0;i<ds;i++){
			temp -> getMethod() -> addVariable(declaredFunctions[i]);
		}
		declaredFunctions.clear();
		vector<string> variableList = temp -> getMethod() -> getListOfVariable();
		string assembly = $<var>$ -> getAssembly() + "\nPUSH AX\nPUSH BX\nPUSH CX\nPUSH DX";
		vector<string> parameterList = temp -> getMethod() -> getParameterList();
		int psize = parameterList.size();
		int vsize = variableList.size();
		for(int i=0; i<psize;i++){
			assembly = assembly + "\nPUSH "+ parameterList[i];
		}
		for(int i=0; i<vsize;i++){
			assembly = assembly + "\nPUSH " + variableList[i];
		}
		assembly = assembly + $<var>6 -> getAssembly() + "\nLReturn"+global+":";
		for(int i=vsize-1; i>=0; i--){
			assembly = assembly + "\nPOP " + variableList[i];
		}
		for(int i=psize-1; i>=0; i--){
			assembly = assembly + "\nPOP " + parameterList[i];
		}
		
		assembly = assembly + "\nPOP AX\nPOP BX\nPOP CX\nPOP DX\nRET\n";
		$<var>$ -> setAssembly(assembly+name2+ " ENDP\n");
	}
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
	myTable -> enterScope(7, parser);
	int limit = parameters.size();
	for(int i=0; i < limit; i++){
		string paraName = parameters[i]->getName();
		string paraType = parameters[i] -> getDeclaration();
		int c = myTable -> currentScopeID;
		ostringstream a;
		a<<c;
		string s = a.str(); 
		//cout << s;
		myTable -> insert(paraName, "ID", paraType);
		declaredVariables.push_back(paraName+s);
	}
	parameters.clear();
} statements RCURL {
	fprintf(parser, "At line no : %d compound_statement : LCURL statements RCURL\n\n", lines);
	$<var>$ = new SymbolInfo();
	string name3 = $<var>3 -> getName();
	string a3 = $<var>3 -> getAssembly();
	$<var>$ -> setName("{\n" + name3 + "\n}");
	$<var>$ -> setAssembly(a3);
	fprintf(parser, "{\n%s\n}\n\n", $<var>3 -> getName().c_str());
	//myTable -> printAllST(parser);
	myTable -> exitScope(parser);
}
| LCURL RCURL {
	myTable -> enterScope(7, parser);
	int limit = parameters.size();
	for(int i=0; i < limit; i++){
		string dec = parameters[i] -> getDeclaration();
		string name = parameters[i]->getName();
		string type = "ID";
		myTable -> insert(name, type, dec);
		int c = myTable -> currentScopeID;
		ostringstream a;
		a<<c;
		string s = a.str();
		declaredVariables.push_back(name+s);
	}
	parameters.clear();
	fprintf(parser, "At line no : %d compound_statement : LCURL RCURL\n\n", lines);
	fprintf(parser, "{}\n\n");
	$<var>$ = new SymbolInfo();
	$<var>$ -> setName("{}");
	//myTable -> printAllScopeTables();
	myTable -> exitScope(parser);
}
;

var_declaration: type_specifier declaration_list SEMICOLON {
	fprintf(parser, "At line no : %d var_declaration : type_specifier declaration_list SEMICOLON\n\n", lines);
	$<var>$ = new SymbolInfo();
	fprintf(parser, "%s %s;\n\n", $<var>1->getName().c_str(), $<var>2->getName().c_str());
	string name1 = $<var>1 -> getName();
	string name2 = $<var>2 -> getName();
	string v = "void ";
	if(name1 == v){
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);

		errors++;
	}
	else {
		int limit = declarations.size();
		for(int i =0; i < limit; i++){
			int decSize = declarations[i]-> getType().size();
			string decName = declarations[i] -> getName();
			string decType = declarations[i] -> getType();
			if(myTable -> findCurrent(declarations[i]->getName())) {
				fprintf(errorFile,"Error at Line %d : Multiple declaration of variable %s\n\n",lines, declarations[i]->getName().c_str());
				errors++;
				continue;
			}
			int c = myTable -> currentScopeID;
			ostringstream a;
			a<<c;
			string s = a.str();
			string part1 = decName+s;
			string part2 = decType.substr(2, decType.size()-1);
			if(decSize <= 2){
				myTable -> insert(decName, decType, name1);
				declaredFunctions.push_back(part1);
				declaredVariables.push_back(part1);
			}
			else {
				pair<string,string> temp = make_pair(part1, part2);
				declaredArrays.push_back(temp);
				string s1 = decType.substr(0, declarations[i] -> getType().size()-1);
				declarations[i] -> setType(s1);
				myTable -> insert(decName, decType, name1+"array");
			}
		}
	}
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
	string type =  "ID"+$<var>5->getName();
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
	string type =  "ID"+$<var>5 -> getName();
	declarations.push_back(new SymbolInfo(n1, type));
	
}
;

statements: statement {
	fprintf(parser, "At line no : %d statements : statement\n\n", lines);
	$<var>$ = new SymbolInfo();
	string a1 = $<var>1 -> getAssembly();
	$<var>$ -> setName($<var>1 -> getName());

	fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	$<var>$ -> setAssembly(a1);	
	
}
| statements statement {
	fprintf(parser, "At line no : %d statements : statements statement\n\n", lines);
	$<var>$ = new SymbolInfo();

	string a1 = $<var>1 -> getAssembly();
	string a2 = $<var>2 -> getAssembly();
	$<var>$ -> setName($<var>1 -> getName() + "\n" + $<var>2 -> getName());

	fprintf(parser, "%s \n%s\n\n", $<var>1 -> getName().c_str(), $<var>2 -> getName().c_str());
	$<var>$ -> setAssembly(a1+a2);
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
	$<var>$ -> setAssembly($<var>1 -> getAssembly());
	fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	
}
| compound_statement {
	fprintf(parser, "At line no : %d statement : compound_statement\n\n", lines);
	$<var>$ = new SymbolInfo();

	$<var>$ -> setName($<var>1 -> getName());
	$<var>$ -> setAssembly($<var>1 -> getAssembly());
	fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	
}
| FOR LPAREN expression_statement expression_statement expression RPAREN statement {
	fprintf(parser, "At line no : %d statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n", lines);
	$<var>$ = new SymbolInfo();
	string v = "void ";
	string name3 = $<var>3 -> getName();
	string name4 = $<var>4 -> getName();
	string name5 = $<var>5 -> getName();
	string name7 = $<var>7 -> getName();
	string a3 = $<var>3 -> getAssembly();
	string a4 = $<var>4 -> getAssembly();
	string a5 = $<var>5 -> getAssembly();
	string a7 = $<var>7 -> getAssembly();
	string un4 = $<var>4 -> getUnique();
	string dec3 = $<var>3 -> getDeclaration();
	fprintf(parser, "for(%s %s %s)\n%s\n", $<var>3 -> getName().c_str(), $<var>4 -> getName().c_str(), $<var>5 -> getName().c_str(), $<var>7 -> getName().c_str());
	if(dec3 == v){
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);
		errors++;
	}
	else{
		char *l1 = newLabel();
		char *l2 = newLabel();
		string assembly = a3+"\n"+string(l1)+":\n"+a4+"\nMOV AX,"+un4+"\nCMP AX,0\nJE "+string(l2)+"\n"+a7+a5+"\nJMP "+string(l1)+"\n"+string(l2)+":";
		//cout << "line " << lines << " " << string(l1) << " " << string(l2);
		$<var>$ -> setAssembly(assembly);
	}

	$<var>$ -> setName("for(" + name3 + name4 + name5 +")" + "\n" + name7);
}
| IF LPAREN expression RPAREN statement %prec AFTER_ELSE {
	fprintf(parser, "At line no : %d statement : IF LPAREN expression RPAREN statement\n\n", lines);
	$<var>$ = new SymbolInfo();
	string v = "void ";
	string un3 = $<var>3 -> getUnique();
	string a3 = $<var>3 -> getAssembly();
	string a5 = $<var>5 -> getAssembly();
	fprintf(parser, "if(%s)\n %s \n\n", $<var>3 -> getName().c_str(), $<var>5 -> getName().c_str());
	if($<var>3 -> getDeclaration() == v){
		
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);

		errors++;
	}
	else{
		char *l1 = newLabel();
		string assembly = a3+"\nMOV AX,"+un3+"\nCMP AX,0\nJE "+string(l1)+"\n"+a5+"\n"+string(l1)+":";
		$<var>$ -> setAssembly(assembly);
	}
	$<var>$ -> setName("if(" + $<var>3 -> getName()+ ")" + "\n" + $<var>5 -> getName());

}
| IF LPAREN expression RPAREN statement ELSE statement {
	fprintf(parser, "At line no : %d statement : IF LPAREN expression RPAREN statement ELSE statement\n\n", lines);
	$<var>$ = new SymbolInfo();
	fprintf(parser, "if(%s)\n%s\n else \n %s \n\n", $<var>3 -> getName().c_str(), $<var>5 -> getName().c_str(), $<var>7 -> getName().c_str());
	
	string v = "void ";
	string dec = $<var>3 -> getDeclaration();
	string un3 = $<var>3 -> getUnique();
	string a3 = $<var>3 -> getAssembly();
	string a5 = $<var>5 -> getAssembly();
	string a7 = $<var>7 -> getAssembly();
	if(dec == v){
		
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);

		errors++;
	}
	else{
		char *l1 = newLabel();
		char *l2 = newLabel();
		string assembly = a3+"\nMOV AX,"+un3+"\nCMP AX,0\nJE "+string(l1)+"\n"+a5+"\nJMP "+string(l2)+"\n"+string(l1)+":\n"+a7+"\n"+string(l2)+":";
		//cout << "line " << lines << " " << string(l1) << " " << string(l2);
		$<var>$ -> setAssembly(assembly);
	}
	$<var>$ -> setName("if(" + $<var>3 -> getName()+ ")" + "\n" + $<var>5 -> getName() + "\n" + "else" + "\n" + $<var>7 -> getName());
}
| WHILE LPAREN expression RPAREN statement {
	fprintf(parser, "At line no : %d statement : WHILE LPAREN expression RPAREN statement\n\n", lines);
	$<var>$ = new SymbolInfo();
	fprintf(parser, "while(%s)\n %s \n\n", $<var>3 -> getName().c_str(), $<var>5 -> getName().c_str());
	string v = "void ";
	string un3 = $<var>3 -> getUnique();
	string a3 = $<var>3 -> getAssembly();
	string a5 = $<var>5 -> getAssembly();
	string dec = $<var>3 -> getDeclaration();
	if(dec == v){
		
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);

		errors++;
	}
	else{
		char *l1 = newLabel();
		char *l2 = newLabel();
		string assembly = "\n"+string(l1)+":\n"+a3+"\nMOV AX,"+un3+"\nCMP AX,0\nJE "+string(l2)+"\n"+a5+"\nJMP "+string(l1)+"\n"+string(l2)+":\n";
		//cout << "line " << lines << " " << string(l1) << " " << string(l2);
		$<var>$ -> setAssembly(assembly);
	}
	$<var>$ -> setName("while(" + $<var>3 -> getName()+ ")" + "\n" + $<var>5 -> getName());
}
| PRINTLN LPAREN ID RPAREN SEMICOLON {
	fprintf(parser, "At line no : %d statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n", lines);
	$<var>$ = new SymbolInfo();
	string assembly = "";
	string name3 = $<var>3 -> getName();
	$<var>$ -> setName("println(" + name3+ ")" + ";");

	fprintf(parser, "\nprintln(%s); \n\n", $<var>3 -> getName().c_str());
	if(myTable -> getScopeID(name3)==-1){
		fprintf(errorFile, "Error at Line %d : Undeclared variable : %s\n\n", lines, $<var>3->getName().c_str());
		errors++;
	}
	else{
		int i = myTable -> getScopeID(name3);
		ostringstream a;
		a<<i;
		string s = a.str();
		assembly = "\nMOV AX,"+name3+s+"\nCALL OUTDEC";
	}
	$<var>$ -> setAssembly(assembly);
}
| RETURN expression SEMICOLON {
	fprintf(parser, "At line no : %d statement : RETURN expression SEMICOLON\n\n", lines);
	$<var>$ = new SymbolInfo();
	fprintf(parser, "return %s;\n\n", $<var>2 -> getName().c_str());
	string dec2 = $<var>2 -> getDeclaration();
	string a2 = $<var>2 -> getAssembly();
	string un2 = $<var>2 -> getUnique();
	string v = "void ";
	string i ="int ";
	if(dec2 == v){

		$<var>$ -> setDeclaration(i);

		
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);

		errors++;
		
	}
	else{
		string assembly = a2 + "\nMOV AX,"+un2+"\nMOV "+global+"_return,AX"+"\nJMP LReturn"+global;
		$<var>$ -> setAssembly(assembly);
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
	$<var>$ -> setUnique($<var>1->getUnique());
	$<var>$ -> setAssembly($<var>1->getAssembly());
}
;

variable: ID {
	fprintf(parser, "At line no : %d variable : ID\n\n", lines);

	$<var>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n", $<var>1 -> getName().c_str());
	string variableName = $<var>1 -> getName();
	if(myTable -> lookUp(variableName) != 0){
		$<var>$ -> setDeclaration(myTable -> lookUp($<var>1 -> getName()) -> getDeclaration());
		int i = myTable -> getScopeID(variableName);
		ostringstream a;
		a<<i;
		string s = a.str();
		$<var>$ -> setUnique(variableName+s);
	}
	if(myTable -> lookUp($<var>1 -> getName()) == 0){
		
		fprintf(errorFile,"Error at Line %d : Undeclared variable: %s\n\n",lines, $<var>1 -> getName().c_str());
		
		errors++;
		}
	/*else if(myTable -> lookUp($<var>1 -> getName())-> getDeclaration() == "float array" || myTable -> lookUp($<var>1 -> getName())-> getDeclaration() == "int array" ){
		
		fprintf(errorFile,"Error at Line %d : %s is not an array\n\n",lines, $<var>1 -> getName().c_str());
		
		errors++;
		}*/
	


	$<var>$ -> setType("notarray");
;	$<var>$ -> setName($<var>1 -> getName());


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
	string n1 = $<var>1 -> getName();
	string n3 = $<var>3 -> getName();
	string a3 = $<var>3 -> getAssembly();
	string un3 = $<var>3 -> getUnique();

	fprintf(parser, "%s[%s]\n\n", $<var>1 -> getName().c_str(), $<var>3 -> getName().c_str());
	if(dec == v || dec == f) {
		
		fprintf(errorFile,"Error at Line %d : Non-integer Array Index  \n\n",lines);

		errors++;
		int i = myTable -> getScopeID(n1);
		ostringstream a;
		a<<i;
		string s = a.str();
		$<var>$ -> setUnique(n1+s);
	}
	if(myTable -> lookUp(n1)==0){
		
		fprintf(errorFile,"Error at Line %d : Undeclared variable : %s \n\n",lines, $<var>1 -> getName().c_str());
		
		errors++;
	}

	if(myTable -> lookUp(n1) != 0){
		if(myTable -> lookUp(n1) -> getDeclaration() != fa && myTable -> lookUp(n1) -> getDeclaration() != ia){
			//cout << "Line No : "<< lines << " " << $<var>1 -> getName() << "  " << myTable -> lookUp($<var>1 -> getName()) -> getDeclaration() << endl;
			fprintf(errorFile,"Error at Line %d : Type Mismatch \n\n",lines);
			errors++;
		}
		else
		{
			if(myTable -> lookUp(n1) -> getDeclaration() == fa) 
				$<var>1 -> setDeclaration(f);
		
			string dec1 = $<var>1 -> getDeclaration();
			if(myTable -> lookUp(n1) -> getDeclaration() == ia) 
				$<var>1 -> setDeclaration(i);	
			$<var>$ -> setDeclaration(dec1);

			string assembly = a3 + "\nMOV BX,"+un3+"\nADD BX,BX";
			$<var>$ -> setAssembly(assembly);
			int i = myTable -> getScopeID(n1);
			ostringstream a;
			a<<i;
			string s = a.str();
			$<var>$ -> setUnique(n1+s);
		}
	}
	
	$<var>$ -> setName(n1 + "[" + n3 + "]");
	$<var>$ -> setType("array");

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
	string un = $<var>1 -> getUnique();
	string assembly = $<var>1 -> getAssembly();
	$<var>$ -> setUnique(un);
	$<var>$ -> setAssembly(assembly);
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
	string a1 = $<var>1 -> getAssembly();
	string a3 = $<var>3 -> getAssembly();
	string un1 = $<var>1 -> getUnique();
	string un3 = $<var>3 -> getUnique();
	string type1 = $<var>1 -> getType();
	if(dec3 == v){
		$<var>$ -> setDeclaration(i);
		fprintf(errorFile,"Error at Line %d : Invalid declaration of variable\n\n",lines);
		errors++;
	}
	else if (myTable -> lookUp(n1) != 0){
		//cout <<"\nLine " << lines<< "  "<<dec1 << " " << dec3;
		if(myTable -> lookUp(n1) -> getDeclaration() != dec3){
			fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);
			errors++;
		}
		else {
			string assembly = a1 + a3 + "\nMOV AX,"+un3+"\nMOV " + un1;
			//cout << "Line "<<lines << "  " << un3 << endl;
			//cout << "Line "<<lines << "  " << un1 << endl;
			if(type1!="notarray") assembly = assembly + "[BX],AX";
			else assembly = assembly + ",AX";
			$<var>$ -> setUnique(un1);
			$<var>$ -> setAssembly(assembly);
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
	string un = $<var>1 -> getUnique();
	string assembly = $<var>1 -> getAssembly();
	$<var>$ -> setUnique(un);
	$<var>$ -> setAssembly(assembly);

}
| rel_expression LOGICOP rel_expression {
	fprintf(parser, "At line no : %d logic_expression : rel_expression LOGICOP rel_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	string a1 = $<var>1 -> getAssembly();
	string a3 = $<var>3 -> getAssembly();
	string un1 = $<var>1 -> getUnique();
	string un3 = $<var>3 -> getUnique();
	string i = "int ";
	string v = "void ";
	string dec1 = $<var>1->getDeclaration();
	string dec3 = $<var>3->getDeclaration();
	fprintf(parser, "%s%s%s\n\n", $<var>1->getName().c_str(), $<var>2->getName().c_str(), $<var>3->getName().c_str());
	string n2 = $<var>2 -> getName();
	if(dec1 == v || dec3 == v) {
		fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);
		errors++;
	}
	else {
		char *l1 = newLabel();
		char *t = newTemp();
		char *l2 = newLabel();
		char *l3 = newLabel();
		string assembly = a1 + a3;
		if(n2 == "||") assembly = assembly + "\nMOV AX," + un1 + "\nCMP AX,0\nJNE "+string(l1)+"\nMOV AX,"+un3+"\nCMP AX,0\nJNE " + string(l1)+"\n"+string(l2)+":\nMOV "+string(t)+",0\nJMP "+string(l3)+"\n"+string(l1)+":\nMOV "+string(t)+",1\n"+string(l3)+":";
		else assembly = assembly + "\nMOV AX," + un1 + "\nCMP AX,0\nJE "+string(l1)+"\nMOV AX,"+un3+"\nCMP AX,0\nJE " + string(l1)+"\n"+string(l2)+":\nMOV "+string(t)+",1\nJMP "+string(l3)+"\n"+string(l1)+":\nMOV "+string(t)+",0\n"+string(l3)+":";
		//cout << "line " << lines << " " << string(l1) << " " << string(l2) << " " << string(l3);
		$<var>$ -> setUnique(t);
		declaredVariables.push_back(t);
		$<var>$ -> setAssembly(assembly);
	}
	$<var>$ -> setDeclaration(i);
	string n1 = $<var>1 -> getName();
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
	$<var>$ -> setName(n1);
	string un = $<var>1 -> getUnique();
	string assembly = $<var>1 -> getAssembly();
	$<var>$ -> setUnique(un);
	$<var>$ -> setAssembly(assembly);
}
| simple_expression RELOP simple_expression {
	fprintf(parser, "At line no : %d rel_expression : simple_expression RELOP simple_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	string un1 = $<var>1 -> getUnique();
	string un3 = $<var>3 -> getUnique();
	string v = "void ";
	string i = "int ";
	string dec1 = $<var>1->getDeclaration();
	string dec3 = $<var>3->getDeclaration();
	string name1 = $<var>1 -> getName();
	string name2 = $<var>2 -> getName();
	string name3 = $<var>3 -> getName();
	fprintf(parser, "%s%s%s\n\n", $<var>1->getName().c_str(), $<var>2->getName().c_str(), $<var>3->getName().c_str());
	string a1 = $<var>1 -> getAssembly();
	string a3 = $<var>3 -> getAssembly();
	if(dec1 == v || dec3 == v) {
		fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);
		errors++;
	}
	else {
		char *l1 = newLabel();
		char *t = newTemp();
		char *l2 = newLabel();
		string assembly = a1 + a3 + "\nMOV AX," +un1+"\nCMP AX,"+un3;
		if(name2 == "==") assembly = assembly + "\nJE " + string(l1);
		else if(name2 == "!=") assembly = assembly + "\nJNE " + string(l1);
		else if(name2 == "<") assembly = assembly + "\nJL " + string(l1);
		else if(name2 == "<=") assembly = assembly + "\nJLE " + string(l1);
		else if(name2 == ">") assembly = assembly + "\nJG " + string(l1);
		else if(name2 == ">=") assembly = assembly + "\nJGE " + string(l1);
		assembly = assembly + "\nMOV " + string(t) + ",0\nJMP " + string(l2) + "\n" + string(l1) + ":\nMOV " + string(t) + ",1\n" + string(l2) + ":";
		//cout << "line " << lines << " " << string(l1) << " " << string(l2);
		$<var>$ -> setUnique(t);
		declaredVariables.push_back(t);
		$<var>$ -> setAssembly(assembly); 
	}
	$<var>$ -> setDeclaration(i);
	$<var>$ -> setName(name1+ name2+ name3);
}
;

simple_expression: term {
	fprintf(parser, "At line no : %d simple_expression : term\n\n", lines);
	$<var>$ = new SymbolInfo();
	$<var>$ -> setName($<var>1 -> getName());
	$<var>$ -> setDeclaration($<var>1 ->getDeclaration());
	fprintf(parser, "%s\n\n", $<var>1->getName().c_str());
	string un = $<var>1 -> getUnique();
	string assembly = $<var>1 -> getAssembly();
	$<var>$ -> setUnique(un);
	$<var>$ -> setAssembly(assembly);
}
| simple_expression ADDOP term {
	fprintf(parser, "At line no : %d simple_expression : simple_expression ADDOP term\n\n", lines);
	$<var>$ = new SymbolInfo();
	string a1 = $<var>1 -> getAssembly();
	string a3 = $<var>3 -> getAssembly();
	string un1 = $<var>1 -> getUnique();
	string un3 = $<var>3 -> getUnique();
	fprintf(parser, "%s%s%s\n\n", $<var>1->getName().c_str(), $<var>2->getName().c_str(), $<var>3->getName().c_str());
	string dec3 = $<var>3->getDeclaration();
	string dec1 = $<var>1->getDeclaration();
	string f = "float ";
	string v = "void ";
	string i = "int ";
	string name1 = $<var>1 -> getName();
	string name2 = $<var>2 -> getName();
	string name3 = $<var>3 -> getName();
	if(dec3 == f || dec1 == f ) {
		$<var>$ -> setDeclaration(f);
		char *t = newTemp();
		string assembly = a1 + a3 + "\nMOV AX," + un1;
		if(name2=="+"){
			assembly = assembly + "\nADD AX," + un3;
		}
		else assembly = assembly + "\nSUB AX," + un3;
		assembly = assembly +"\nMOV " + string(t) + ",AX";
		declaredVariables.push_back(t);
		$<var>$ -> setUnique(t);
		$<var>$ -> setAssembly(assembly);
	}
	else if($<var>3->getDeclaration() == v || $<var>1->getDeclaration() == v) {
		$<var>$ -> setDeclaration(i);
		fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);
		errors++;
	}
	else {
		$<var>$ -> setDeclaration(i);
		char *t = newTemp();
		string assembly = a1 + a3 + "\nMOV AX," + un1;
		if(name2=="+"){
			assembly = assembly + "\nADD AX," + un3;
		}
		else assembly = assembly + "\nSUB AX," + un3;
		assembly = assembly +"\nMOV " + string(t) + ",AX";
		declaredVariables.push_back(t);
		$<var>$ -> setUnique(t);
		$<var>$ -> setAssembly(assembly);
	}
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
	string un = $<var>1 -> getUnique();
	$<var>$ -> setUnique(un);
	string assembly = $<var>1 -> getAssembly();
	$<var>$ -> setAssembly(assembly);
	
}
| term MULOP unary_expression {
	fprintf(parser, "At line no : %d term : term MULOP unary_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	string a1 = $<var>1 -> getAssembly();
	string a3 = $<var>3 -> getAssembly();
	string un1 = $<var>1 -> getUnique();
	string un3 = $<var>3 -> getUnique();
	string v = "void ";
	string i = "int ";
	string f = "float ";
	string dec1 = $<var>1->getDeclaration();
	string dec3 = $<var>3->getDeclaration();
	string name2 = $<var>2 -> getName();
	fprintf(parser, "%s%s%s\n\n", $<var>1->getName().c_str(), $<var>2->getName().c_str(), $<var>3->getName().c_str());
	if(dec1 == v || dec3 == v) {
		$<var>$ -> setDeclaration(i);
		fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);
		errors++;
	}
	else if(name2 == "/"){
		if(dec1 == i && dec3 == i) {
			$<var>$ -> setDeclaration(i);
			char *t = newTemp();
			string assembly = a1 + a3 + "\nMOV AX," + un1 + "\nMOV BX," + un3 + "\nDIV BX\nMOV " + string(t) + ",AX";
			declaredVariables.push_back(t);
			$<var>$ -> setUnique(t);
			$<var>$ -> setAssembly(assembly);
		}
		else if(dec1 == v || dec3 == v){
			$<var>$ -> setDeclaration(i);
			fprintf(errorFile, "Error at Line %d : Type Mismatch\n\n", lines);
			errors++;
		}
		else {
			$<var>$ -> setDeclaration(f);
			char *t = newTemp();
			string assembly = a1 + a3 + "\nMOV AX," + un1 + "\nMOV BX," + un3 + "\nDIV BX\nMOV " + string(t) + ",AX";
			declaredVariables.push_back(t);
			$<var>$ -> setUnique(t);
			$<var>$ -> setAssembly(assembly);
		}
	}
	else if(name2 == "%"){
		if(dec1 != i || dec3 != i) {
			fprintf(errorFile,"Error at Line %d : Integer operand on modulus operator\n\n",lines);
			errors++;
		}
		else {
			$<var>$ -> setDeclaration(i);
		}
		char *t = newTemp();
		string assembly = a1 + a3 + "\nMOV AX," + un1 + "\nMOV BX," + un3 + "\nMOV DX,0\nDIV BX\nMOV " + string(t) + ",DX";
		declaredVariables.push_back(t);
		$<var>$ -> setUnique(t);
		$<var>$ -> setAssembly(assembly);
	}
	else {
		if(dec1 == f || dec3 == f){
			$<var>$ -> setDeclaration(f);
			char *t = newTemp();
			string assembly = a1 + a3 + "\nMOV AX," + un1 + "\nMOV BX," + un3 + "\nMUL BX\nMOV " + string(t) + ",AX";
			declaredVariables.push_back(t);
			$<var>$ -> setUnique(t);
			$<var>$ -> setAssembly(assembly);
		}
		else if(dec1 == v || dec3 == v){
			$<var>$ -> setDeclaration(i);
			fprintf(errorFile, "Error at Line %d : Type Mismatch\n\n", lines);
			errors++;
		}
		else {
			$<var>$ -> setDeclaration(i);
			char *t = newTemp();
			string assembly = a1 + a3 + "\nMOV AX," + un1 + "\nMOV BX," + un3 + "\nMUL BX\nMOV " + string(t) + ",AX";
			declaredVariables.push_back(t);
			$<var>$ -> setUnique(t);
			$<var>$ -> setAssembly(assembly);
		}
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
	string str1 = $<var>1 -> getName();
	string str2 = $<var>2 -> getName();
	fprintf(parser, "%s%s\n\n", $<var>1->getName().c_str(), $<var>2->getName().c_str());
	if(dec2 == v){
		$<var>$ -> setDeclaration(i);
		fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);
		errors++;
	}
	else {
		string dec2 = $<var>2 -> getDeclaration();
		$<var>$ -> setDeclaration(dec2);
		string assembly = "";
		assembly = $<var>2 -> getAssembly();
		string un = $<var>2 -> getUnique();
		if(str1 == "-") {
			assembly = assembly + "\nMOV AX," + un + "\nNEG AX\nMOV " + un + ",AX";
		}
		$<var>$ -> setUnique(un);
		$<var>$ -> setAssembly(assembly);
	}
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
		string assembly = "";
		assembly = $<var>2 -> getAssembly();
		string un = $<var>2 -> getUnique();
		assembly = assembly + "\nMOV AX," + un + "\nNOT AX\nMOV " + un + ",AX";
		$<var>$ -> setUnique(un);
		$<var>$ -> setAssembly(assembly);
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
	string un = $<var>1 -> getUnique();
	$<var>$ -> setUnique(un);
	string assembly = $<var>1 -> getAssembly();
	$<var>$ -> setAssembly(assembly);
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
	string type = $<var>$ -> getType();
	string assembly = $<var>1 -> getAssembly();
	string un = $<var>1 -> getUnique();
	if(type != "array"){
		$<var>$ -> setUnique(un);
	}
	else {
		char *t = newTemp();
		assembly = assembly + "\nMOV AX," + un + "[BX]\nMOV " + string(t) + ",AX";
		$<var>$ -> setUnique(t);
		declaredVariables.push_back(t);
	}

	$<var>$ -> setAssembly(assembly);


}
| ID LPAREN argument_list RPAREN {
	fprintf(parser, "At line no : %d factor : ID LPAREN argument_list RPAREN\n\n", lines);
	$<var>$ = new SymbolInfo();
	string i = "int ";
	fprintf(parser, "%s(%s)\n\n",$<var>1->getName().c_str(), $<var>3->getName().c_str());
	string variableName = $<var>1->getName();
	SymbolInfo *temp = myTable -> lookUp(variableName);
	string assembly = $<var>3 -> getAssembly();
	//cout << $<var>1->getName()<< endl;
	//cout << temp->getMethod() -> getTotalParameters() << endl;
	if(temp == 0){
		$<var>$->setDeclaration(i);
		fprintf(errorFile,"Error at Line %d : Undeclared function\n\n",lines);
		errors++;
	}
	else if(temp -> getMethod() == 0){
		$<var>$->setDeclaration(i);
		fprintf(errorFile,"Error at Line %d : Not a function\n\n",lines);
		errors++;
		
	}
	else{
		int p = temp -> getMethod() -> getTotalParameters();
		bool def = temp -> getMethod() -> getDefined();
		if(def == 0){
			fprintf(errorFile,"Error at Line %d : Undeclared function\n\n",lines);
			errors++;
		}
		$<var>$ -> setDeclaration(temp -> getMethod() -> getRType());
		
		if(p != arguments.size()){
			//cout << lines << " " <<p <<endl;
			//cout << lines << " " <<arguments.size() <<endl;
			fprintf(errorFile,"Error at Line %d : Invalid number of arguments\n\n",lines);
			errors++;
		}
		else{
			vector<string> pt = temp -> getMethod() -> getParameterType();
			int argSize = arguments.size();
			vector<string> pl = temp -> getMethod() -> getParameterList();
			vector<string> lv = temp -> getMethod() -> getListOfVariable();
			for(int i=0; i < argSize; i++){
				//cout << argSize << endl;
				string un = arguments[i] -> getUnique();
				//cout << arguments[i] << " " << arguments[i]-> getName() << " " <<un << endl;
				//cout << "Name : " << arguments[i] -> getName() << endl;
				assembly = assembly + "\nMOV AX," + un + "\nMOV " + pl[i] + ",AX";
				//cout << "Line " << lines << " " << un << endl;
				if(arguments[i]->getDeclaration()!=pt[i]){
					fprintf(errorFile,"Error at Line %d : Type Mismatch\n\n",lines);
					errors++;
					break;
				}
			}
			char *t = newTemp();
			assembly = assembly + "\nCALL " + variableName + "\nMOV AX," + variableName + "_return\nMOV " + string(t) + ",AX";
			declaredVariables.push_back(t);
			$<var>$ -> setUnique(t);
			$<var>$ -> setAssembly(assembly);
			
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
	string un = $<var>2 -> getUnique();
	$<var>$ -> setUnique(un);
	string assembly = $<var>2 -> getAssembly();
	$<var>$ -> setAssembly(assembly);
}
| CONST_INT {
	fprintf(parser, "At line no : %d factor : CONST_INT\n\n", lines);
	$<var>$ = new SymbolInfo();
	string i = "int ";
	string var1 = $<var>1->getName();
	$<var>$ -> setName(var1);
	fprintf(parser, "%s\n\n",$<var>1->getName().c_str());
	$<var>$ -> setDeclaration(i);
	char *t = newTemp();
	string assembly = "\nMOV " + string(t) + "," + var1;
	declaredVariables.push_back(t);
	//cout << "line " << lines << " " << $<var>$ -> getName() << " "<< string(t) << endl;
	$<var>$ -> setUnique(string(t));
	//cout << "line " << lines << " " <<$<var>$ << "  "<< $<var>$ -> getName() << " "<< $<var>$ -> getUnique() << endl;
	$<var>$ -> setAssembly(assembly);
}
| CONST_FLOAT {
	fprintf(parser, "At line no : %d factor : CONST_FLOAT\n\n", lines);
	$<var>$ = new SymbolInfo();
	string f = "float ";
	string var1 = $<var>1->getName();
	$<var>$ -> setName(var1);
	fprintf(parser, "%s\n\n",$<var>1->getName().c_str());
	$<var>$ -> setDeclaration(f);
	char *t = newTemp();
	string assembly = "\nMOV " + string(t) + "," + var1;
	declaredVariables.push_back(t);
	$<var>$ -> setUnique(string(t));
	$<var>$ -> setAssembly(assembly);
	
}
| variable INCOP {
	fprintf(parser, "At line no : %d factor : variable INCOP\n\n", lines);
	$<var>$ = new SymbolInfo();	
	string var1 = $<var>1->getName() + "++";
	$<var>$ -> setName(var1);
	fprintf(parser, "%s\n\n",$<var>1->getName().c_str());
	string dec1 = $<var>1 -> getDeclaration();
	$<var>$ -> setDeclaration(dec1);
	char *t = newTemp();
	string type1 = $<var>1 -> getType();
	string assembly = "";
	string un = $<var>1 -> getUnique();
	if(type1!="array"){
		assembly = assembly + "\nMOV AX," + un;
	}
	else {
		assembly = assembly + "\nMOV AX," + un + "[BX]";
	}
	assembly = assembly + "\nMOV "+string(t) + ",AX";
	if(type1!="array"){
		assembly = assembly + "\nINC " + un;
	}
	else{
		assembly = assembly + "\nMOV AX," + un + "[BX]\nINC AX\nMOV " + un + "[BX],AX"; 
	}
	
	declaredVariables.push_back(t);
	$<var>$ -> setUnique(t);
	$<var>$ -> setAssembly(assembly);
}
| variable DECOP {
	fprintf(parser, "At line no : %d factor : variable DECOP\n\n", lines);
	$<var>$ = new SymbolInfo();
	string var1 = $<var>1->getName()+"--";
	$<var>$ -> setName(var1);
	fprintf(parser, "%s\n\n",$<var>1->getName().c_str());
	string dec1 = $<var>1 -> getDeclaration();
	$<var>$ -> setDeclaration(dec1);
	char *t = newTemp();
	string type1 = $<var>1 -> getType();
	string assembly = "";
	string un = $<var>1 -> getUnique();
	if(type1!="array"){
		assembly = assembly + "\nMOV AX," + un;
	}
	else {
		assembly = assembly + "\nMOV AX," + un + "[BX]";
	}
	assembly = assembly + "\nMOV "+string(t) + ",AX";
	if(type1!="array"){
		assembly = assembly + "\nDEC " + un;
	}
	else{
		assembly = assembly + "\nMOV AX," + un + "[BX]\nDEC AX\nMOV " + un + "[BX],AX"; 
	}
	declaredVariables.push_back(t);
	$<var>$ -> setUnique(t);
	$<var>$ -> setAssembly(assembly);
}
;


argument_list: arguments {
	fprintf(parser, "At line no : %d argument_list : arguments\n\n", lines);
	$<var>$ = new SymbolInfo();
	string var1 = $<var>1->getName();
	$<var>$ -> setName(var1);
	fprintf(parser, "%s\n\n",$<var>1->getName().c_str());
	string assembly = $<var>1 -> getAssembly();
	$<var>$ -> setAssembly(assembly);
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
	string assembly = $<var>1 -> getAssembly()+$<var>3 -> getAssembly();
	$<var>$ -> setAssembly(assembly);

}
| logic_expression {
	fprintf(parser, "At line no : %d arguments : logic_expression\n\n", lines);
	$<var>$ = new SymbolInfo();
	fprintf(parser, "%s\n\n",$<var>1->getName().c_str());
	string n1 = $<var>1->getName();
	//string type1 = $<var>1->getType();
	//string dec1 = $<var>1->getDeclaration();
	$<var>$ -> setName(n1);
	//arguments.push_back(new SymbolInfo(n1, type1, dec1));
	arguments.push_back($<var>1);
	string assembly = $<var>1 -> getAssembly();
	$<var>$ -> setAssembly(assembly);
} 

%%


bool checkAssembly(string str1, string str2){
	if(str1 == str2){
		cout << "Same Line" << endl;
		return true;
	}
	string dest1 = "";
	string dest2 = "";
	string src1 = "";
	string src2 = "";
	if(str1[0]=='M' && str1[1]=='O' && str1[2] == 'V'){
		//cout << "Str1 MOV " << endl;
		if(str2[0]=='M' && str2[1]=='O' && str2[2] == 'V'){
			//cout << "Str2 MOV " << endl;
			int i = 4;
			for(; i<str1.size(); i++){
				if(str1[i]==' ' || str1[i] == ',') break;
				dest1 = dest1 + str1[i]; 
			}
			for(int j = i+1; j<str1.size(); j++){
				if(str1[j] == ' ' || str1[j] == '\n') break;
				src1 = src1 + str1[j];
			}
			int k = 4;
			for(; k<str2.size(); k++){
				if(str2[k]==' ' || str2[k] == ',') break;
				dest2 = dest2 + str2[k]; 
			}
			for(int m = k+1; m<str2.size(); m++){
				if(str2[m] == ' ' || str2[m] == '\n') break;
				src2 = src2 + str2[m];
			}
			if(src1==dest2 && src2==dest1) {
				//cout <<  " Src1 = " << src1 << " Dest1 = " << dest1 << " Src2 = " << src2 << " Dest2 = " << dest2 << endl;
				//cout << " Found " << endl;
				return true;
			}
		}
	}
	return false;
}


void optimize(FILE *code){
	FILE *optimized = fopen("optcode.asm", "w");
	vector<string> vect;
	ssize_t temp;
	size_t size;
	char *str = NULL;
	while((temp = getline(&str, &size, code))!=-1){
		vect.push_back(string(str));
	}
	bool array[vect.size()];
	for(int i = 0; i < vect.size(); i++){
		array[i] = true;
	}
	for(int i = 0; i < vect.size()-1; i++){
		bool b = checkAssembly(vect[i], vect[i+1]);
		if(b){
			array[i+1] = false;
		}
	}
	for(int i = 0; i < vect.size(); i++){
		if(array[i]){
			fprintf(optimized, "%s", vect[i].c_str());
		}
	}
	fclose(code);
	fclose(optimized);
	if(str) free(str);
}





int main(int argc,char *argv[])
{
	if((fp=fopen(argv[1],"r"))==NULL){
		printf("Cannot Open Input File.\n"); exit(1);}
	yyin=fp;
	myTable -> enterScope(20);
	yyparse();
	//fprintf(parser, "SymbolTable : ");
	//myTable -> printAllST(parser);
	fprintf(parser, "Total lines : %d\n",lines);
	fprintf(errorFile, "Total lines : %d\n",lines);
	fprintf(errorFile, "Total errors : %d", errors);
	fprintf(parser, "Total errors : %d", errors);
	fclose(fp);
	fclose(parser);
	fclose(errorFile);
	return 0;
}
