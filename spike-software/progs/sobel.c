#include "ExecLib.h"

#define LOG2_FM_DIM 6
#define FM_DIM      1 << LOG2_FM_DIM
#define FM_SIZE     FM_DIM * FM_DIM
#define WT_DIM      3
#define WT_SIZE     WT_DIM * WT_DIM

reg_t tohost = 0;
reg_t fromhost = 0;
reg_t tohost_cmd[8] = {0};

// weight matrices
static int32_t wt_x[WT_SIZE] = {-1,  0, 1,
                                -2,  0, 2,
                                -1,  0, 1};

static int32_t wt_y[WT_SIZE] = {1,  2,  1,
                                0,  0,  0,
                               -1, -2, -1};

static int32_t ofm_x[FM_SIZE] = {0};
static int32_t ofm_y[FM_SIZE] = {0};
static uint8_t ifm_buf[FM_SIZE] = {0};
static int32_t ifm_use[FM_SIZE] = {0};

int32_t times(int32_t a, int32_t b) {
    int32_t a_neg = a < 0;
    int32_t b_neg = b < 0;
    int32_t result = 0;
    if (a_neg) a = -a;
    if (b_neg) b = -b;
    while (b) {
        if (b & 1) {
            result += a;
        }
        a <<= 1;
        b >>= 1;
    }
    if ((a_neg && !b_neg) || (!a_neg && b_neg)) {
        result = -result;
    }
    return result;
}

// source: https://en.wikipedia.org/wiki/Integer_square_root
int32_t int_sqrt(int32_t n) {
    int32_t result, tmp;
    int32_t shift = 2;
    int32_t n_shifted = n >> shift;

    while (n_shifted != 0 && n_shifted != n) {
        shift   = shift + 2;
        n_shifted = n >> shift;
    }
    shift = shift - 2;

    result = 0;
    while (shift >= 0) {
        result = result << 1;
        tmp = result + 1;
        if (times(tmp, tmp) <= (n >> shift))
          result = tmp;
        shift = shift - 2;
    }

    return result;
}


void conv2D_sw(int32_t *ifm, int32_t *wt, int32_t *ofm) {
    int32_t fm_idx, wt_idx;
    int32_t x, y, m, n, idx, idy;

    x = 0; y = 0;;
    for (fm_idx = 0; fm_idx < FM_SIZE; fm_idx++) {
        ofm[fm_idx] = 0;
        m = 0; n = 0;
        for (wt_idx = 0; wt_idx < WT_SIZE; wt_idx++) {
            idx = x - (WT_DIM >> 1) + n;
            idy = y - (WT_DIM >> 1) + m;

            int32_t d = 0;
            if (!(idx < 0 || idx >= FM_DIM || idy < 0 || idy >= FM_DIM))
                d = ifm[(idy << LOG2_FM_DIM) + idx];

            ofm[fm_idx] = ofm[fm_idx] + times(d, wt[wt_idx]);

            // index update
            n = n + 1;
            if (n == WT_DIM) {
                n = 0;
                m = m + 1;
            }
        }

        // index update
        x = x + 1;
        if (x == FM_DIM) {
            x = 0;
            y = y + 1;
        }
    }
}

uint32_t checksum(int32_t *array) {                                                                                                                                                                
   int checksum = 0;                                                                                                                                                                              
   for (int i = 0; i < FM_SIZE; i++) {                                                                                                                                                            
      checksum += array[i];                                                                                                                                                                      
   }                                                                                                                                                                                              
   return checksum;
}           

char ifm_file[] = "data/lena.img.bin";
char str0[] = "read the input data from 'data/lena.img.bin'\n";
char str1[] = "read done\n";
char str2[] = "calculate idx\n";
char str3[] = "calculate idy\n";
char str4[] = "combine the output feature map\n";
char str5[] = "output the result to data/sobel.out\n";
char str6[] = "checksum: ";
char output_file[] = "data/sobel.out";


char chline[] = "\n";
char step[] = " ";

char ibuf[100] = {0};

int main(int argc, char**argv) {
    uint32_t i;

    tohost_printstr(str0);

    reg_t fd = tohost_open(ifm_file, O_RDONLY);
    tohost_read(fd, ifm_buf, FM_SIZE);
    tohost_close(fd);

    for (uint32_t i = 0, j = 0; i < FM_SIZE; i++) {
      ifm_use[i] = ifm_buf[i];
//      uint64_to_str(ifm_buf[i], ibuf);
//      tohost_printstr(ibuf);
//      tohost_printstr(step);
//      if (j == 63) {
//        tohost_printstr(chline);
//        j = 0;
//      } else {
//        j++;
//      }
    }


    tohost_printstr(str1);

    // Sobel Edge Detection
    // ofm_x = img_data (*) wt_x
    // ofm_y = img_data (*) wt_y
    // result = sqrt(ofm_x ^ 2 + ofm_y ^ 2) 

    tohost_printstr(str2);
    conv2D_sw(ifm_use, wt_x, ofm_x);
    tohost_printstr(str3);
    conv2D_sw(ifm_use, wt_y, ofm_y);
    tohost_printstr(str4);

    for (i = 0; i < FM_SIZE; i++) {
        int32_t mag = int_sqrt(times(ofm_x[i], ofm_x[i]) + times(ofm_y[i], ofm_y[i]));
        mag = (mag > 255) ? 255 : mag;
        ifm_buf[i] = mag;
        ifm_use[i] = mag;
    }

    tohost_printstr(str6);
    reg_t cs = checksum(ifm_use);
    uint64_to_str(cs, ibuf);
    tohost_printstr(ibuf);
    tohost_printstr(chline);

    tohost_printstr(str5);
    fd = tohost_open(output_file, O_WRONLY | O_CREAT);


    tohost_write(fd, ifm_buf, FM_SIZE);
    tohost_close(fd);

    tohost_exit(0);
}
