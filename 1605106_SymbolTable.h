//
// Created by Muntaka on 5/7/2019.
//

#ifndef COMPILEROFFLINES_SYMBOLTABLE_H
#define COMPILEROFFLINES_SYMBOLTABLE_H

#endif //COMPILEROFFLINES_SYMBOLTABLE_H

#include<bits/stdc++.h>
#include "1605106_ScopeTable.h"
using namespace std;

class SymbolTable{
public:
    ScopeTable* currentScope;
    int currentScopeID;

SymbolTable() {
    currentScope = nullptr;
    currentScopeID = 0;
}


SymbolTable(int scopeTableSize) {
    currentScope = nullptr;
	//enterScope(scopeTableSize);
    currentScopeID = 0;
}

bool insert(const string &name, const string &type, const string &declaration){
    if(currentScope == 0){
        this -> enterScope(7);
    }
    return currentScope -> insert(name, type, declaration);    
}

void enterScope(const int &size) {
    ScopeTable* temp = currentScope;
    int id;
    if (temp!=nullptr) id = currentScopeID +1 ;
    else id = 1;
    currentScopeID = id;
    auto* newScope = new ScopeTable(id, size);
    newScope->parentScope = temp;
    currentScope = newScope;
    if (currentScope->tableId!=1)
        FileInputOutput::write("New ScopeTable with id "+to_string(this->currentScope->tableId)+" created"+"\n");
        
}

void enterScope(const int &size, FILE* file) {
    ScopeTable* temp = currentScope;
    int id;
    if (temp!=nullptr) id = currentScopeID +1 ;
    else id = 1;
    currentScopeID = id;
    auto* newScope = new ScopeTable(id, size);
    newScope->parentScope = temp;
    currentScope = newScope;
    if (currentScope->tableId!=1)
        fprintf(file, "New ScopeTable with id %d created\n\n", this->currentScopeID);
}

void exitScope() {
    FileInputOutput::write("ScopeTable with id "+to_string(this->currentScope->tableId)+" removed"+"\n");
    currentScope = currentScope->parentScope;
}

void exitScope(FILE* file) {
    fprintf(file, "ScopeTable with id %d removed\n\n", this->currentScopeID);
    currentScope = currentScope->parentScope;
}

bool insert(SymbolInfo &s) {
    bool isInserted = currentScope->insert(s);
    return isInserted;
}

bool remove(string name) {
    bool isRemoved = currentScope->deleteEntry(name);
    return isRemoved;
}

/*SymbolInfo* lookUp(string name) {
    SymbolInfo* temp = currentScope->lookUp(name);
    if (temp== nullptr&&currentScope->parentScope!= nullptr) 
        temp = currentScope->parentScope->lookUp(name);
    return temp;
}*/

SymbolInfo* lookUp(string name) {
    ScopeTable* temp = currentScope;
    while (temp)
    {
        if (temp -> lookUp(name))
        {
            return temp -> lookUp(name);
        }
        temp = temp -> parentScope;
        
    }
    return 0;
    
}



SymbolInfo* findCurrent(string name){
    if(currentScope) {
        return currentScope -> lookUp(name);
    }
    return 0;
}

void printCurrentScopeTable() {
    //cout<<"ScopeTable #"<<currentScope->tableId<<endl;
    currentScope->printScopeTable();
}

void printScopeTable(FILE *file){
  //fprintf(file, "\n\n\tScopeTable #%d",this->currentScope->tableId );

    SymbolInfo *current;
    for (int i = 0; i < this->currentScope->tableSize; ++i) {
        if (this->currentScope->list[i] != nullptr) {
            fprintf(file, "\n\t%d --> ", i);
            //write(file, to_string(i) + " --> ");
            current = this->currentScope->list[i];
            fprintf(file, "<%s,%s>", current->getName().c_str(), current->getType().c_str());
            while (current->next != nullptr) {
                fprintf(file, " <%s,%s> ", current->next->getName().c_str(), current->next->getType().c_str());
                current = current->next;
            }
        }
    }
    fprintf(file, "\n\n");
}

void printAllST(FILE *file){
    ScopeTable* temp = currentScope;
    ///TODO printing all scopes in log file
    fprintf(file, "\n\n\tScopeTable #%d",temp->tableId);
    temp-> printScopeTable(file);
    while (temp->parentScope!=nullptr)
    {
        temp = temp -> parentScope;
        fprintf(file, "\n\n\tScopeTable #%d",temp->tableId);
        temp-> printScopeTable(file);
    }
    

}

void printAllScopeTables() {
    ScopeTable* temp = currentScope;
    //cout<<"ScopeTable #"<<temp->tableId<<endl;
    temp->printScopeTable();
    while (temp->parentScope!= nullptr){
        temp = temp->parentScope;
        //cout<<"ScopeTable #"<<temp->tableId<<endl;
        temp->printScopeTable();
    }
}



void execute(list<string> list, int size){
    string part1 = list.front();
    list.pop_front();

    string part2, part3;
    if (part1=="I"){
        part2 = list.front();
        list.pop_front();
        part3 = list.front();
        list.pop_front();
        SymbolInfo s(part2, part3);
        this->insert(s);
    } else if (part1 == "L"){
        part2 = list.front();
        list.pop_front();
        if (this->lookUp(part2)== nullptr)
            FileInputOutput::write("Not Found\n");
    } else if (part1 == "D"){
        part2 = list.front();
        list.pop_front();
        this->remove(part2);
    }else if (part1 == "P"){
        part2 = list.front();
        list.pop_front();
        if (part2 == "A") this->printAllScopeTables();
        else if (part2 == "C") this->printCurrentScopeTable();
    }else if (part1 == "S"){
        this->enterScope(size);
    }else if (part1 == "E"){
        this->exitScope();
    } else FileInputOutput::write("Invalid Input\n");
}
};
