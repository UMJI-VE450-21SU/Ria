#include <iostream>
#include <string>

#include "sim_memory.hpp"

int main(int argc, char** argv, char** env) {
    using std::string; using std::cout; using std::endl; using std::ifstream;
    cout << "---------------------------- init/ dump test -----------------------------" << endl;
    cout << "the arguments are :" << endl;
    for (int i = 0; argv[i]; ++i) {
      cout << argv[i] << " ";
    }
    cout << endl << endl;

    // use the second argument as the name of binary
    string binName{argv[1]};
    cout << "use bin file: " << binName << endl;
    IMem<> imem(binName);
    cout << "prog content: " << endl;
    imem.print();
    cout << endl;

    // use the third argument as the name of dcache init file
    string InitFile{argv[2]};
    cout << "use init file: " << InitFile << endl;
    DMem dmem(binName);
    cout << "dcache content: " << endl;
    dmem.print();
    cout << endl;

}
