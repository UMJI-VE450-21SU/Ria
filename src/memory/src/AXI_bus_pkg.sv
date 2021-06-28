`ifndef AXI_BUS_PKG
`define AXI_BUS_PKG

package AXI_bus_pkg;

    parameter AXI_WIDTH = 64; // AXI bus width == WBKSZ * WDSZ

    typedef logic [AXI_WIDTH-1:0] axi_word_t;
    
endpackage

`endif