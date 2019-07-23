//
// Created by Muntaka on 5/8/2019.
//

#ifndef COMPILEROFFLINES_FILEINPUTOUTPUT_H
#define COMPILEROFFLINES_FILEINPUTOUTPUT_H

#endif //COMPILEROFFLINES_FILEINPUTOUTPUT_H

#include <iostream>
#include <fstream>
#include <list>
using namespace std;

class FileInputOutput{

public:

static list<string> readFile(list<string> &list){
    ifstream file("1605106_input.txt");
    string str;
    while (std::getline(file, str)){
        list.push_back(str);
    }
    return list;
}

static void write(string str){
    //cout << str;
    ofstream file;
    file.open("1605106_output.txt", std::ios_base::app);
    file << str;
}

};
