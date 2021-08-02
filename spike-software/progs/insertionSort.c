#include "ExecLib.h"
#define N 20

int A[N] = {387, 552, 201, 808, 220, 996, 594, 282, 152, 999, 
            876, 395, 542, 557, 430, 562, 342, 357, 682, 670};

char buf[5] = {0};
reg_t tohost = 0;
reg_t fromhost = 0;
reg_t tohost_cmd[8] = {0};

void insertion(int arr[], int size){
  int min_idx, min;
  for(int i = 0; i < (size-1); i++){
    min_idx = i;
    min = arr[i];
    for(int j = i+1; j< size; j++){
      if(arr[j] < min){
        min_idx = j;
        min = arr[j];
      }
    }
    int temp = arr[i];
    arr[i] = min;
    arr[min_idx] = temp;
  }
}

int main(){
  insertion(A, N);

  return 0;
}
