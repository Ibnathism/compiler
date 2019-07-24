%{
#include <iostream>
#include<stdio.h>
#include<stdlib.h>
#include<vector>
#include "1605106_SymbolTable.h"
#include "y.tab.h"

extern YYSTYPE yylval;
extern SymbolTable* table;
extern FILE* error;
using namespace std;

extern "C" int yylex();

SymbolTable s(7);
extern int lines;
extern int errors;




FILE* showTokens;
FILE* showLog;

string convertSpecialCharacter(string str);
string charModification(string str);




%}
NUMBER [0-9]
WHITESPACE [ \t\f\r\v]+
ALPHABETS [A-Za-z]


IDENTIFIERS [A-Za-z_][_a-zA-Z0-9]*
INVALID_ID [0-9][_A-Za-z0-9]*


CHAR [ -~]{-}['\\]
CONST_CHAR \'{CHAR}\' 
CHAR_SPECIAL \\[nt\\"afrbv0]|\\\'
CONST_CHAR_SPECIAL \'{CHAR_SPECIAL}\'
MULTI_CHAR_CONST \'{CHAR}{CHAR}+\'|\'{CHAR_SPECIAL}{CHAR_SPECIAL}+\'
UNTERMINATED_CHAR (\'({CHAR}|[\\])*[^'\n]?)|(\'\\\')
EMPTY_CHAR_CONST \'\'


CONST_INT {NUMBER}+
CONST_FLOAT {NUMBER}*\.?{NUMBER}+([E][-+]?{NUMBER}+)?
TOO_MANY_DECIMALS  {NUMBER}*([\.]+{NUMBER}*)+(E[\.]*[+-]?[\.]*{NUMBER}*)?[\.]*{NUMBER}*
ILL_FORMED {NUMBER}+([E][-+]?{NUMBER}+)\.{NUMBER}*



CONST_STRING \"([^\"\n]|\\[\n])*\"
UNTERMINATED_STRING \"([^\"\n]|\\[\n])*

ONE_LINE_COMMENT [/][/]([^\n]|\\[\n])*

MORE_LINE_COMMENT [/][*]([^*]|([*][^/]))*[*][/]
UNTERMINATED_COMMENT [/][*]([^*]|([*][^/]))*[^"*/"]


%%

{WHITESPACE} {}

"\n" {
	lines++;
	}

{CONST_INT} {
	SymbolInfo *si = new SymbolInfo(yytext, "CONST_INT");
	yylval.var = si;
	return CONST_INT;
	}

{CONST_FLOAT} {
	SymbolInfo *si = new SymbolInfo(yytext, "CONST_FLOAT");
	yylval.var = si;
	return CONST_FLOAT;
	}


{TOO_MANY_DECIMALS} {
	fprintf(showLog, "\nError at line %d: Too many decimal points %s\n", lines, yytext);
	errors++;
	}

{ILL_FORMED} {
	fprintf(showLog, "\nError at line %d: Ill formed number %s\n", lines, yytext);
	errors++;
	}




{CONST_STRING} {
	string str = convertSpecialCharacter(yytext);
	SymbolInfo *si = new SymbolInfo(str, "CONST_STRING");
	yylval.var = si;
	return CONST_STRING;
}
{UNTERMINATED_STRING} {
	fprintf(showLog, "\nError at line %d: Unterminated string %s\n", lines, yytext);
	errors++;
	string str = convertSpecialCharacter(yytext);
	}

{ONE_LINE_COMMENT}|{MORE_LINE_COMMENT}	{
	fprintf(showLog, "\nLine No. %d: Token <COMMENT> Lexeme %s found\n", lines, yytext);
	string str = convertSpecialCharacter(yytext);
	}

{UNTERMINATED_COMMENT} {
	fprintf(showLog, "\nError at line %d: Unterminated comment %s\n", lines, yytext);
	errors++;
	string str = convertSpecialCharacter(yytext);
	}

"if" {return IF;}
"else" {return ELSE;}
"for" {return FOR;}
"while" {return WHILE;}
"do" {return DO;}
"break" {return BREAK;}
"int" {return INT;}
"char" {return CHAR;}
"float" {return FLOAT;}
"double" {return DOUBLE;}
"void" {return VOID;}
"return" {return RETURN;}
"switch" {return SWITCH;}
"case" {return CASE;}
"default" {return DEFAULT;}
"continue" {return CONTINUE;}


"+"|"-" {
	SymbolInfo *si = new SymbolInfo(yytext, "ADDOP");
	yylval.var = si;
	return ADDOP;
}

"*"|"/"|"%" {
	SymbolInfo *si = new SymbolInfo(yytext, "MULOP");
	yylval.var = si;
	return MULOP;
}

"++"|"--" {
	SymbolInfo *si = new SymbolInfo(yytext, "INCOP");
	yylval.var = si;
	return INCOP;
}

"<"|"<="|">"|">="|"=="|"!=" {
	SymbolInfo *si = new SymbolInfo(yytext, "RELOP");
	yylval.var = si;
	return RELOP;
}

"=" {return ASSIGNOP;}

"&&"|"||" {
	SymbolInfo *si = new SymbolInfo(yytext, "LOGICOP");
	yylval.var = si;
	return LOGICOP;
}

"&"|"|"|"^"|"<<"|">>" {
	SymbolInfo *si = new SymbolInfo(yytext, "BITOP");
	yylval.var = si;
	return BITOP;
}

"!" {return NOT;}
"(" {return LPAREN;}
")" {return RPAREN;}
"{" {return LCURL;}
"}" {return RCURL;}
"[" {return LTHIRD;}
"]" {return RTHIRD;}
"," {return COMMA;}
";" {return SEMICOLON;}


{IDENTIFIERS} {
	SymbolInfo *si = s.lookUp(yytext);
	if(si==NULL){
		si = new SymbolInfo(yytext, "ID");
	}
	yylval.var = si;
	return ID;
	}

{INVALID_ID} {
	fprintf(showLog, "\nError at line %d: Invalid prefix on ID or invalid suffix on Number %s\n", lines, yytext);
	errors++;
	}

. {
	fprintf(showLog, "\nError at line %d: Unrecognised character %s\n", lines, yytext);
	errors++;
	}




%%


string charModification(string str){
	string modified;
	if(str[1]=='\\'){
		if(str[2]=='n') modified.push_back('\n');
		else if(str[2]=='t') modified.push_back('\t');
		else if(str[2]=='\\') modified.push_back('\\');
		else if(str[2]=='\"') modified.push_back('\"');
		else if(str[2]=='a') modified.push_back('\a');
		else if(str[2]=='f') modified.push_back('\f');
		else if(str[2]=='r') modified.push_back('\r');
		else if(str[2]=='b') modified.push_back('\b');
		else if(str[2]=='v') modified.push_back('\v');
		else if(str[2]=='\0') modified.push_back('\0');
		else if(str[2]=='\'') modified.push_back('\'');
		else {}
	}
	else {
		modified.push_back(str[1]);
	}
	return modified;
}


string convertSpecialCharacter(string str){
	string converted;
	bool increase;
	int length = str.size();
	for(int i=0; i<length; i++){
		increase = false;
		if(str[i]=='\n'){
			lines++;
		}
		if(str[i]=='\\' and str[i+1]=='\n'){
			i++;
			lines++;
			continue;
		}
		if(str[i]=='\\'){
			if(str[i+1]=='n') converted.push_back('\n');
			else if(str[i+1]=='t') converted.push_back('\t');
			else if(str[i+1]=='\\') converted.push_back('\\');
			else if(str[i+1]=='\"') converted.push_back('\"');
			else if(str[i+1]=='a') converted.push_back('\a');
			else if(str[i+1]=='f') converted.push_back('\f');
			else if(str[i+1]=='r') converted.push_back('\r');
			else if(str[i+1]=='b') converted.push_back('\b');
			else if(str[i+1]=='v') converted.push_back('\v');
			else if(str[i+1]=='\0') converted.push_back('\0');
			else if(str[i+1]=='\'') converted.push_back('\'');
			else {
				converted.push_back(str[i]);
				increase = true;
		}
	}
		else {
			converted.push_back(str[i]);
			increase = true;
		}




		if(!increase) i++;
	}
	return converted;
}



/*int main(int argc,char *argv[]){


	if(argc!=2){
		printf("Invalid Input\n");
		return 0;
	}

	FILE *inputFile=fopen(argv[1],"r");
	if(inputFile==NULL){
		printf("Cant open file\n");
		return 0;
	}


	showTokens  = fopen("1605106_tokenFile.txt", "w");
	showLog = fopen("1605106_logFile.txt", "w");
	yyin= inputFile;

	yylex();


	s.printScopeTable(showLog);
	fprintf(showLog, "\nTotal lines : %d\nTotal errors : %d", lines-1, errors);
	fclose(yyin);
	fclose(showLog);
	fclose(showTokens);

	return 0;
}*/


