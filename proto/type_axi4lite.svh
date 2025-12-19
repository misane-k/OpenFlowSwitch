/*
    input          arready,
    output         arvalid,
    output  [31:0] araddr,
    output         rready,
    input          rvalid,
    input   [1:0]  rresp,
    input   [31:0] rdata,
    input          awready,
    output         awvalid,
    output  [31:0] awaddr,
    input          wready,
    output         wvalid,
    output  [31:0] wdata,
    output  [3:0]  wstrb,
    output         bready,
    input          bvalid,
    input   [1:0]  bresp,
*/

`ifndef TYPE_AXI4LITE_SVH
`define TYPE_AXI4LITE_SVH

interface axi4lite_if (
);
    logic          arready;
    logic          arvalid;
    logic  [31:0]  araddr;
    logic          rready;
    logic          rvalid;
    logic  [1:0]   rresp;
    logic  [31:0]  rdata;
    logic          awready;
    logic          awvalid;
    logic  [31:0]  awaddr;
    logic          wready;
    logic          wvalid;
    logic  [31:0]  wdata;
    logic  [3:0]   wstrb;
    logic          bready;
    logic          bvalid;
    logic  [1:0]   bresp;
    
    modport master (
        input  arready, rvalid, rresp, rdata, awready, wready, bvalid, bresp, 
        output arvalid, araddr, rready, awvalid, awaddr, wvalid, wdata, wstrb, 
               bready 
    );
    
    modport slave (
        input  arvalid, araddr, rready, awvalid, awaddr, wvalid, wdata, wstrb, 
               bready, 
        output arready, rvalid, rresp, rdata, awready, wready, bvalid, bresp 
    );
endinterface

typedef struct packed {
    logic          arready;
    logic          arvalid;
    logic  [31:0]  araddr;
    logic          rready;
    logic          rvalid;
    logic  [1:0]   rresp;
    logic  [31:0]  rdata;
    logic          awready;
    logic          awvalid;
    logic  [31:0]  awaddr;
    logic          wready;
    logic          wvalid;
    logic  [31:0]  wdata;
    logic  [3:0]   wstrb;
    logic          bready;
    logic          bvalid;
    logic  [1:0]   bresp;
} axi4lite_t;

`define AXI4LITE_MASTER(ifc)     \
    input  logic         ifc``_arready, \
    output logic         ifc``_arvalid, \
    output logic [31:0]  ifc``_araddr, \
    output logic         ifc``_rready, \
    input  logic         ifc``_rvalid, \
    input  logic [1:0]   ifc``_rresp, \
    input  logic [31:0]  ifc``_rdata, \
    input  logic         ifc``_awready, \
    output logic         ifc``_awvalid, \
    output logic [31:0]  ifc``_awaddr, \
    input  logic         ifc``_wready, \
    output logic         ifc``_wvalid, \
    output logic [31:0]  ifc``_wdata, \
    output logic [3:0]   ifc``_wstrb, \
    output logic         ifc``_bready, \
    input  logic         ifc``_bvalid, \
    input  logic [1:0]   ifc``_bresp

`define AXI4LITE_SLAVE(ifc)     \
    output logic         ifc``_arready, \
    input  logic         ifc``_arvalid, \
    input  logic [31:0]  ifc``_araddr, \
    input  logic         ifc``_rready, \
    output logic         ifc``_rvalid, \
    output logic [1:0]   ifc``_rresp, \
    output logic [31:0]  ifc``_rdata, \
    output logic         ifc``_awready, \
    input  logic         ifc``_awvalid, \
    input  logic [31:0]  ifc``_awaddr, \
    output logic         ifc``_wready, \
    input  logic         ifc``_wvalid, \
    input  logic [31:0]  ifc``_wdata, \
    input  logic [3:0]   ifc``_wstrb, \
    input  logic         ifc``_bready, \
    output logic         ifc``_bvalid, \
    output logic [1:0]   ifc``_bresp

`define AXI4LITE_IF_TO_S(ifc, s) \
    assign s.arready = ifc.arready; \
    assign ifc.arvalid = s.arvalid; \
    assign ifc.araddr = s.araddr; \
    assign ifc.rready = s.rready; \
    assign s.rvalid = ifc.rvalid; \
    assign s.rresp = ifc.rresp; \
    assign s.rdata = ifc.rdata; \
    assign s.awready = ifc.awready; \
    assign ifc.awvalid = s.awvalid; \
    assign ifc.awaddr = s.awaddr; \
    assign s.wready = ifc.wready; \
    assign ifc.wvalid = s.wvalid; \
    assign ifc.wdata = s.wdata; \
    assign ifc.wstrb = s.wstrb; \
    assign ifc.bready = s.bready; \
    assign s.bvalid = ifc.bvalid; \
    assign s.bresp = ifc.bresp; \

`define AXI4LITE_S_TO_IF(s, ifc) \
    assign ifc.arready = s.arready; \
    assign s.arvalid = ifc.arvalid; \
    assign s.araddr = ifc.araddr; \
    assign s.rready = ifc.rready; \
    assign ifc.rvalid = s.rvalid; \
    assign ifc.rresp = s.rresp; \
    assign ifc.rdata = s.rdata; \
    assign ifc.awready = s.awready; \
    assign s.awvalid = ifc.awvalid; \
    assign s.awaddr = ifc.awaddr; \
    assign ifc.wready = s.wready; \
    assign s.wvalid = ifc.wvalid; \
    assign s.wdata = ifc.wdata; \
    assign s.wstrb = ifc.wstrb; \
    assign s.bready = ifc.bready; \
    assign ifc.bvalid = s.bvalid; \
    assign ifc.bresp = s.bresp; \

`define AXI4LITE_PACK(ifc) \
    assign ifc``_arready = ifc``.arready; \
    assign ifc``.arvalid = ifc``_arvalid; \
    assign ifc``.araddr = ifc``_araddr; \
    assign ifc``.rready = ifc``_rready; \
    assign ifc``_rvalid = ifc``.rvalid; \
    assign ifc``_rresp = ifc``.rresp; \
    assign ifc``_rdata = ifc``.rdata; \
    assign ifc``_awready = ifc``.awready; \
    assign ifc``.awvalid = ifc``_awvalid; \
    assign ifc``.awaddr = ifc``_awaddr; \
    assign ifc``_wready = ifc``.wready; \
    assign ifc``.wvalid = ifc``_wvalid; \
    assign ifc``.wdata = ifc``_wdata; \
    assign ifc``.wstrb = ifc``_wstrb; \
    assign ifc``.bready = ifc``_bready; \
    assign ifc``_bvalid = ifc``.bvalid; \
    assign ifc``_bresp = ifc``.bresp; \

`define AXI4LITE_FLAT(ifc) \
    assign ifc``.arready = ifc``_arready; \
    assign ifc``_arvalid = ifc``.arvalid; \
    assign ifc``_araddr = ifc``.araddr; \
    assign ifc``_rready = ifc``.rready; \
    assign ifc``.rvalid = ifc``_rvalid; \
    assign ifc``.rresp = ifc``_rresp; \
    assign ifc``.rdata = ifc``_rdata; \
    assign ifc``.awready = ifc``_awready; \
    assign ifc``_awvalid = ifc``.awvalid; \
    assign ifc``_awaddr = ifc``.awaddr; \
    assign ifc``.wready = ifc``_wready; \
    assign ifc``_wvalid = ifc``.wvalid; \
    assign ifc``_wdata = ifc``.wdata; \
    assign ifc``_wstrb = ifc``.wstrb; \
    assign ifc``_bready = ifc``.bready; \
    assign ifc``.bvalid = ifc``_bvalid; \
    assign ifc``.bresp = ifc``_bresp; \

`define AXI4LITE_CACHE(a, b, cond) \
    axi4lite_t now_``a; \
    axi4lite_t next_``a; \
    `AXI4LITE_IF_TO_S(b, next_``a) \
    `AXI4LITE_S_TO_IF(now_``a, a) \
    always @(posedge clk) begin \
        if (cond) next_``a <= now_``a; \
    end

`define AXI4LITE_CONNECT(a, b) \
    axi4lite_t mid_``b``_``a; \
    `AXI4LITE_IF_TO_S(b, mid_``b``_``a) \
    `AXI4LITE_S_TO_IF(mid_``b``_``a, a) \

`define AXI4LITE_MUTEX(a, b, cond, c) \
    axi4lite_t mux_``a; \
    axi4lite_t mux_``b; \
    axi4lite_t mux_``c; \
    `AXI4LITE_IF_TO_S(c, mux_``c) \
    always_comb begin \
        mux_``c = (cond) ? mux_``a : mux_``b; \
    end \
    `AXI4LITE_S_TO_IF(mux_``a, a) \
    `AXI4LITE_S_TO_IF(mux_``b, b) \

`endif

