`include "AXI_DMEM_PROTOCOL.sv"

module PS_DDR_Controller_wrapper (
    MPSOC_S_AXI4_HP_bus.slave bus,
    output logic ACLK,
    output logic ARESETn
);
    // wrap the verilog wrapper for block design

    design_1_wrapper ddr_controller 
   (S_AXI_HP0_araddr(bus.ARADDR),
    S_AXI_HP0_arburst(bus.ARBURST),
    S_AXI_HP0_arcache(bus.ARCACHE),
    S_AXI_HP0_arid(bus.ARID),
    S_AXI_HP0_arlen(bus.ARLEN),
    S_AXI_HP0_arlock(bus.ARLOCK),
    S_AXI_HP0_arprot(bus.ARPROT),
    S_AXI_HP0_arqos(bus.ARQOS),
    S_AXI_HP0_arready(bus.ARREADY),
    S_AXI_HP0_arsize(bus.ARSIZE),
    S_AXI_HP0_aruser(bus.ARUSER),
    S_AXI_HP0_arvalid(bus.ARVALID),
    S_AXI_HP0_awaddr(bus.AWADDR),
    S_AXI_HP0_awburst(bus.AWBURST),
    S_AXI_HP0_awcache(bus.AWCACHE),
    S_AXI_HP0_awid(bus.AWID),
    S_AXI_HP0_awlen(bus.AWLEN),
    S_AXI_HP0_awlock(bus.AWLOCK),
    S_AXI_HP0_awprot(bus.AWPROT),
    S_AXI_HP0_awqos(bus.AWQOS),
    S_AXI_HP0_awready(bus.AWREADY),
    S_AXI_HP0_awsize(bus.AWSIZE),
    S_AXI_HP0_awuser(bus.AWUSER),
    S_AXI_HP0_awvalid(bus.AWVALID),
    S_AXI_HP0_bid(bus.BID),
    S_AXI_HP0_bready(bus.BREADY),
    S_AXI_HP0_bresp(bus.BRESP),
    S_AXI_HP0_bvalid(bus.BVALID),
    S_AXI_HP0_rdata(bus.RDATA),
    S_AXI_HP0_rid(bus.RID),
    S_AXI_HP0_rlast(bus.RLAST),
    S_AXI_HP0_rready(bus.RREADY),
    S_AXI_HP0_rresp(bus.RRESP),
    S_AXI_HP0_rvalid(bus.RVALID),
    S_AXI_HP0_wdata(bus.WDATA),
    S_AXI_HP0_wlast(bus.WLAST),
    S_AXI_HP0_wready(bus.WREADY),
    S_AXI_HP0_wstrb(bus.WSTRB),
    S_AXI_HP0_wvalid(bus.WVALID),
    axi_hp_clk(ACLK),
    axim_rst_n(ARESETn),
    pl_clk0(ACLK));
endmodule