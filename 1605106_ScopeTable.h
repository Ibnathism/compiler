//
// Created by Muntaka on 5/5/2019.
//
#ifndef COMPILEROFFLINES_SCOPETABLE_H
#define COMPILEROFFLINES_SCOPETABLE_H
#endif //COMPILEROFFLINES_SCOPETABLE_H


#include <iostream>
#include <string>
#include "1605106_SymbolInfo.h"
using namespace std;

class ScopeTable
{
public:
    ScopeTable * parentScope;
    int tableId;
    int tableSize;
    SymbolInfo ** list;

    int hash(string name){
        int hashVal = 0;
        int size = tableSize;
        for(int i = 0; i<name.length();  i++)
            hashVal = 37*hashVal+name[i];
        hashVal %= size;
        if(hashVal<0)
            hashVal += size;
        return hashVal;
    }

    ScopeTable(const int &id, const int &size){
        parentScope = nullptr;
        tableId = id;
        tableSize = size;
        list = new SymbolInfo*[tableSize];
        for (int i = 0; i < tableSize; ++i) {
            list[i] = nullptr;
        }
    }
    



SymbolInfo* lookUp(string name){
    SymbolInfo* current= nullptr;
    int i = hash(name);
    int number = 0;
    if (list[i] != nullptr) {
        current = list[i];
        if (current->getName() == name) {
            FileInputOutput::write("Found in ScopeTable #" + to_string(this->tableId) + " at position " + to_string(i) + " , " +
                  to_string(number) + "\n");
            return current;
        } else {
            while (current->next != nullptr) {
                current = current->next;
                number++;
                if (current->getName() == name) {
                    FileInputOutput::write("Found in ScopeTable #" + to_string(this->tableId) + " at position " + to_string(i) + " , " +
                          to_string(number) + "\n");
                    return current;
                }
            }
        }
    }
    return nullptr;
}

bool insert( SymbolInfo &s)
{
    SymbolInfo* symInfo = new SymbolInfo(s.getName(),s.getType());
    int number = 0;
    SymbolInfo* current = lookUp(s.getName());
    int hashValue = hash(s.getName());
    SymbolInfo* temp = list[hashValue];
    if (current == nullptr){
        if (temp == nullptr){
            this->list[hashValue] = symInfo;
        } else{
            number++;
            while (temp->next!= nullptr){
                temp=temp->next;
                number++;
            }
            temp->next=symInfo;
        }
        //cout << "Inserted at ScopeTable #" << this->tableId << " at position " << hashValue << " , " << number<< endl;
        FileInputOutput::write("Inserted at ScopeTable #"+to_string(this->tableId)+" at position "+to_string(hashValue)+" , "+to_string(number)+"\n");
        return true;
    } else{
        //cout << s << " already exists in current scope table"<<endl;
        FileInputOutput::write(s.getName()+" already exists in current scope table"+"\n");
        return false;
    }
}

bool insert(const string &name, const string &type, const string &declaration){
    SymbolInfo *temp = lookUp(name);
    if(temp!=0) return false;
    int h = hash(name);
    temp = list[h];
    SymbolInfo *sym = new SymbolInfo(name, type, declaration);
    if (temp == 0)
    {
        list[h] = sym;
        return true;
    }
    int i = 0;
    while (temp -> getNext() != 0)
    {
        temp = temp -> getNext();
        i++;
    }
    temp -> setNext(sym);
    return true;
    
    
}

bool deleteEntry(string name){
    int number = 0;
    SymbolInfo* current = lookUp(name);
    int hashValue = hash(name);
    SymbolInfo* temp = list[hashValue];
    SymbolInfo* prev = list[hashValue];
    if (current == nullptr){
        //cout << name << " not found" << endl;
        FileInputOutput::write(name+" not found"+"\n");
        return false;
    } else{
        if (temp->getName()==current->getName()){
            list[hashValue]= nullptr;
            //cout << "Found in ScopeTable #" << this->tableId << " at position " << hashValue << " , " << number<< endl;
           // write("Found in ScopeTable #"+to_string(this->tableId)+" at position "+to_string(hashValue)+" , "+to_string(number));
            FileInputOutput::write("Deleted entry at "+to_string(hashValue)+" , "+to_string(number)+" from current scopeTable"+"\n");
            return true;
        }
        while (temp->next!= nullptr){
            prev = temp;
            temp = temp->next;
            number++;
            if (temp->getName()==current->getName())
            {
                prev->next =temp->next;
                //cout << "Found in ScopeTable #" << this->tableId << " at position " << hashValue << " , " << number<< endl;
               // write("Found in ScopeTable #"+to_string(this->tableId)+" at position "+to_string(hashValue)+" , "+to_string(number));
                FileInputOutput::write("Deleted entry at "+to_string(hashValue)+" , "+to_string(number)+" from current scopeTable"+"\n");
            }
        }
        return true;
    }
}

void printScopeTable() {
    FileInputOutput::write("ScopeTable #" + to_string(this->tableId)+"\n");
    SymbolInfo *current;
    for (int i = 0; i < this->tableSize; ++i) {
        if (this->list[i] != nullptr) {
	FileInputOutput::write(to_string(i) + " --> ");
            current = this->list[i];
            current->printSymbol();
            while (current->next != nullptr) {
                FileInputOutput::write(" --> ");
                current->next->printSymbol();
                current = current->next;
            }
        }
    FileInputOutput::write("\n");
    }
}

void printScopeTable(FILE *file){
    SymbolInfo *current;
    for (int i = 0; i < this->tableSize; ++i) {
        if (this->list[i] != nullptr) {
            fprintf(file, "\n\t%d --> ", i);
            //write(file, to_string(i) + " --> ");
            current = this->list[i];
            fprintf(file, "<%s,%s>", current->getName().c_str(), current->getType().c_str());
            while (current->next != nullptr) {
                fprintf(file, " <%s,%s> ", current->next->getName().c_str(), current->next->getType().c_str());
                current = current->next;
            }
        }
    }
    fprintf(file, "\n\n");
}



~ScopeTable()  {
    delete[] list;
    delete parentScope;
    tableSize = 0;
    tableId = 0;
}
};
