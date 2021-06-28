`ifndef COMMON_PKG
`define COMMON_PKG

package common_pkg;

    parameter WDSZ = 32;     // the address size == a word

    typedef logic [WDSZ-1:0] word_t; // a word, for addr & data

endpackage

`endif