#include <bits/stdc++.h>
using namespace std;

class Function
        {
        string rType;
        int totalParameters;
        vector<string> parameterList;
        vector<string> parameterType;
        bool defined;

        public:
            Function(){
                totalParameters = 0;
                defined = false;
                parameterList.clear();
                parameterType.clear();
                rType = "";

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
            void setDefined(){
                this->defined=true;
            }
            bool getDefined(){
                return defined;
            }


        };
