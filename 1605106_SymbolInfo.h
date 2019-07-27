//
// Created by Muntaka on 5/5/2019.
//
#ifndef COMPILEROFFLINES_SYMBOLINFO_H
#define COMPILEROFFLINES_SYMBOLINFO_H
#endif //COMPILEROFFLINES_SYMBOLINFO_H

#include <iostream>
#include <string>
#include "1605106_fileInputOutput.h"
#include "1605106_Methods.h"
using namespace std;

class SymbolInfo
{
private:
    string name;
    string type;
    Method *method;
    string declaration;



public:
    SymbolInfo * next;

    SymbolInfo(){
        next = nullptr;
        method = nullptr;
    }

    SymbolInfo(const string &name, const string &type){
        this->name = name;
        this->type = type;
        this->next = nullptr;
    }
    SymbolInfo(const string &name, const string &type, const string &declaration){
        this->name = name;
        this->type = type;        
        this->declaration = declaration;
        this->next = nullptr;
    }
    
    SymbolInfo* getNext(){
        return next;
    }

    void setNext(SymbolInfo* s){
        next = s;
    }


    const string & getName(){
        return name;
    }
    const string &getType() const {
        return type;
    }

    const string &getDeclaration() const {
        return declaration;
    }
    Method* getMethod(){
           return method;
    }
    void setName(const string name) {
        SymbolInfo::name = name;
    }
    void setType(const string &type) {
        SymbolInfo::type = type;
    }
    void setDeclaration(const string &declaration){
        SymbolInfo::declaration = declaration;
    }

    void setMethod(){
            method = new Method();
    }




    //friend ostream& operator<<(ostream& os, const SymbolInfo& symbolInfo);
    void printSymbol(){
        FileInputOutput::write("<" +this->getName()+","+this->getType()+">");
    }

};



/* ostream& operator<<(ostream& os, const SymbolInfo& symbolInfo)
{
    os << "<" << symbolInfo.getName() << "," << symbolInfo.getType() << ">";
    return os;
}*/



