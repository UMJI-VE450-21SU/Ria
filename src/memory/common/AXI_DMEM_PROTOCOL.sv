`ifndef AXI_DMEM_PROTOCOL
`define AXI_DMEM_PROTOCOL

// data bus width = 64 bits, 8 bytes
interface MPSOC_S_AXI4_HP_bus(input logic ACLK, ARESETn);
    // AW channel (REQ, M -> S), IP lists 12 signals
    logic [5:0] AWID;
    logic [48:0] AWADDR;
    logic [7:0] AWLEN;
    logic [2:0] AWSIZE;
    logic [1:0] AWBURST;

    logic AWLOCK;
    logic [3:0] AWCACHE;
    logic [2:0] AWPROT;
    logic [3:0] AWQOS;
    logic AWREGION; // not listed by XILINX IP
    logic AWUSER;

    logic AWVALID;
    logic AWREADY;

    // W channel (DRESP, M -> S), IP lists 5 signals
    logic [63:0] WDATA;
    logic [7:0] WSTRB;

    logic WLAST;
    logic WUSER; // not listed by XILINX IP

    logic WVALID;
    logic WREADY;

    // B channel (RESP, S -> M), IP uses 4 signals
    logic [5:0] BID;
    logic [1:0] BRESP;

    logic BUSER; // not listed by XILINX IP

    logic BVALID;
    logic BREADY;

    // AR channel (REQ, M -> S), IP lists 12 signals
    logic [5:0] ARID;
    logic [48:0] ARADDR;
    logic [7:0] ARLEN;
    logic [2:0] ARSIZE;
    logic [2:0] ARBURST;

    logic ARLOCK;
    logic [3:0] ARCACHE;
    logic [2:0] ARPROT;
    logic [3:0] ARQOS;
    logic ARREGION; // not listed by XILINX IP
    logic ARUSER;

    logic ARVALID;
    logic ARREADY;

    // R channel (RESP, S -> M), IP lists 6 signals
    logic [5:0] RID;
    logic [63:0] RDATA;
    logic [1:0] RRESP;

    logic RLAST;
    logic RUSER; // not listed by XILINX IP

    logic RVALID;
    logic RREADY;

    modport master (
    // AR channel
    output ARADDR, ARBURST, ARCACHE, ARID, ARLEN, ARLOCK, ARPROT,
        ARQOS, ARSIZE, ARUSER, ARVALID;

    input ARREADY;

    // AW channel
    output AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWQOS, AWLOCK, 
        AWCACHE, AWPROT, AWUSER, AWVALID;
    
    input AWREADY;

    // R channel
    input RID, RDATA, RRESP, RVALID, RLAST;

    output RREADY;

    // W channel
    output WDATA, WSTRB, WVALID, WLAST;

    input WREADY;

    // B channel
    input BID, BRESP, BVALID;

    output BREADY;
    );

    modport slave (
    // AR channel
    input ARADDR, ARBURST, ARCACHE, ARID, ARLEN, ARLOCK, ARPROT,
        ARQOS, ARSIZE, ARUSER, ARVALID;

    output ARREADY;

    // AW channel
    input AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWQOS, AWLOCK, 
        AWCACHE, AWPROT, AWUSER, AWVALID;
    
    output AWREADY;

    // R channel
    output RID, RDATA, RRESP, RVALID, RLAST;

    input RREADY;

    // W channel
    input WDATA, WSTRB, WVALID, WLAST;

    output WREADY;

    // B channel
    output BID, BRESP, BVALID;

    input BREADY;
    );
endinterface //AXI4_bus

`endif
