#include <bits/stdc++.h>
using namespace std;

class Method
        {

        vector<string> parameterList;
        vector<string> parameterType;
        vector<string> listOfVariables;
        int scopeID;
        string rType;
        int totalParameters;
       
        bool defined;

        public:
            Method(){
                totalParameters = 0;
                defined = false;
                parameterList.clear();
                parameterType.clear();
                rType = "";

            }
            void setDefined(){
                this->defined=true;
            }
            bool getDefined(){
                return defined;
            }
            void setRType(string type){
                this->rType=type;
            }
            string getRType(){
                return rType;
            }
            void setTotalParameters(){
                totalParameters = parameterList.size();
            }
            int getTotalParameters(){
              return  totalParameters;
            }
            void addParameter(string newparameter,string type){
                parameterList.push_back(newparameter);
                parameterType.push_back(type);
                setTotalParameters();
            }
            vector<string> getParameterList(){
                return parameterList;
            }
            vector<string> getParameterType(){
                return parameterType;
            }

            void addVariable(string s){
                listOfVariables.push_back(s);
            }

            vector<string> getListOfVariable(){
                return listOfVariables;
            }

            void setScopeID(int n){
                this -> scopeID = n;
            } 

            int getScopeID(){
                return scopeID;
            }
            
            void clear(){
                parameterList.clear();
                parameterType.clear();
                setTotalParameters();
            }


        };
