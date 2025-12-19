/*
    input          awready,
    output         awvalid,
    output  [31:0] awaddr,
    output  [3:0]  awid,
    output  [7:0]  awlen,
    output  [2:0]  awsize,
    output  [1:0]  awburst,
    input          wready,
    output         wvalid,
    output  [63:0] wdata,
    output  [7:0]  wstrb,
    output         wlast,
    output         bready,
    input          bvalid,
    input   [1:0]  bresp,
    input   [3:0]  bid,
*/

`ifndef TYPE_AXI4W_SVH
`define TYPE_AXI4W_SVH

interface axi4w_if (
);
    logic          awready;
    logic          awvalid;
    logic  [31:0]  awaddr;
    logic  [3:0]   awid;
    logic  [7:0]   awlen;
    logic  [2:0]   awsize;
    logic  [1:0]   awburst;
    logic          wready;
    logic          wvalid;
    logic  [63:0]  wdata;
    logic  [7:0]   wstrb;
    logic          wlast;
    logic          bready;
    logic          bvalid;
    logic  [1:0]   bresp;
    logic  [3:0]   bid;
    
    modport master (
        input  awready, wready, bvalid, bresp, bid, 
        output awvalid, awaddr, awid, awlen, awsize, awburst, wvalid, wdata, 
               wstrb, wlast, bready 
    );
    
    modport slave (
        input  awvalid, awaddr, awid, awlen, awsize, awburst, wvalid, wdata, 
               wstrb, wlast, bready, 
        output awready, wready, bvalid, bresp, bid 
    );
endinterface

typedef struct packed {
    logic          awready;
    logic          awvalid;
    logic  [31:0]  awaddr;
    logic  [3:0]   awid;
    logic  [7:0]   awlen;
    logic  [2:0]   awsize;
    logic  [1:0]   awburst;
    logic          wready;
    logic          wvalid;
    logic  [63:0]  wdata;
    logic  [7:0]   wstrb;
    logic          wlast;
    logic          bready;
    logic          bvalid;
    logic  [1:0]   bresp;
    logic  [3:0]   bid;
} axi4w_t;

`define AXI4W_MASTER(ifc)     \
    input  logic         ifc``_awready, \
    output logic         ifc``_awvalid, \
    output logic [31:0]  ifc``_awaddr, \
    output logic [3:0]   ifc``_awid, \
    output logic [7:0]   ifc``_awlen, \
    output logic [2:0]   ifc``_awsize, \
    output logic [1:0]   ifc``_awburst, \
    input  logic         ifc``_wready, \
    output logic         ifc``_wvalid, \
    output logic [63:0]  ifc``_wdata, \
    output logic [7:0]   ifc``_wstrb, \
    output logic         ifc``_wlast, \
    output logic         ifc``_bready, \
    input  logic         ifc``_bvalid, \
    input  logic [1:0]   ifc``_bresp, \
    input  logic [3:0]   ifc``_bid

`define AXI4W_SLAVE(ifc)     \
    output logic         ifc``_awready, \
    input  logic         ifc``_awvalid, \
    input  logic [31:0]  ifc``_awaddr, \
    input  logic [3:0]   ifc``_awid, \
    input  logic [7:0]   ifc``_awlen, \
    input  logic [2:0]   ifc``_awsize, \
    input  logic [1:0]   ifc``_awburst, \
    output logic         ifc``_wready, \
    input  logic         ifc``_wvalid, \
    input  logic [63:0]  ifc``_wdata, \
    input  logic [7:0]   ifc``_wstrb, \
    input  logic         ifc``_wlast, \
    input  logic         ifc``_bready, \
    output logic         ifc``_bvalid, \
    output logic [1:0]   ifc``_bresp, \
    output logic [3:0]   ifc``_bid

`define AXI4W_IF_TO_S(ifc, s) \
    assign s.awready = ifc.awready; \
    assign ifc.awvalid = s.awvalid; \
    assign ifc.awaddr = s.awaddr; \
    assign ifc.awid = s.awid; \
    assign ifc.awlen = s.awlen; \
    assign ifc.awsize = s.awsize; \
    assign ifc.awburst = s.awburst; \
    assign s.wready = ifc.wready; \
    assign ifc.wvalid = s.wvalid; \
    assign ifc.wdata = s.wdata; \
    assign ifc.wstrb = s.wstrb; \
    assign ifc.wlast = s.wlast; \
    assign ifc.bready = s.bready; \
    assign s.bvalid = ifc.bvalid; \
    assign s.bresp = ifc.bresp; \
    assign s.bid = ifc.bid; \

`define AXI4W_S_TO_IF(s, ifc) \
    assign ifc.awready = s.awready; \
    assign s.awvalid = ifc.awvalid; \
    assign s.awaddr = ifc.awaddr; \
    assign s.awid = ifc.awid; \
    assign s.awlen = ifc.awlen; \
    assign s.awsize = ifc.awsize; \
    assign s.awburst = ifc.awburst; \
    assign ifc.wready = s.wready; \
    assign s.wvalid = ifc.wvalid; \
    assign s.wdata = ifc.wdata; \
    assign s.wstrb = ifc.wstrb; \
    assign s.wlast = ifc.wlast; \
    assign s.bready = ifc.bready; \
    assign ifc.bvalid = s.bvalid; \
    assign ifc.bresp = s.bresp; \
    assign ifc.bid = s.bid; \

`define AXI4W_PACK(ifc) \
    assign ifc``_awready = ifc``.awready; \
    assign ifc``.awvalid = ifc``_awvalid; \
    assign ifc``.awaddr = ifc``_awaddr; \
    assign ifc``.awid = ifc``_awid; \
    assign ifc``.awlen = ifc``_awlen; \
    assign ifc``.awsize = ifc``_awsize; \
    assign ifc``.awburst = ifc``_awburst; \
    assign ifc``_wready = ifc``.wready; \
    assign ifc``.wvalid = ifc``_wvalid; \
    assign ifc``.wdata = ifc``_wdata; \
    assign ifc``.wstrb = ifc``_wstrb; \
    assign ifc``.wlast = ifc``_wlast; \
    assign ifc``.bready = ifc``_bready; \
    assign ifc``_bvalid = ifc``.bvalid; \
    assign ifc``_bresp = ifc``.bresp; \
    assign ifc``_bid = ifc``.bid; \

`define AXI4W_FLAT(ifc) \
    assign ifc``.awready = ifc``_awready; \
    assign ifc``_awvalid = ifc``.awvalid; \
    assign ifc``_awaddr = ifc``.awaddr; \
    assign ifc``_awid = ifc``.awid; \
    assign ifc``_awlen = ifc``.awlen; \
    assign ifc``_awsize = ifc``.awsize; \
    assign ifc``_awburst = ifc``.awburst; \
    assign ifc``.wready = ifc``_wready; \
    assign ifc``_wvalid = ifc``.wvalid; \
    assign ifc``_wdata = ifc``.wdata; \
    assign ifc``_wstrb = ifc``.wstrb; \
    assign ifc``_wlast = ifc``.wlast; \
    assign ifc``_bready = ifc``.bready; \
    assign ifc``.bvalid = ifc``_bvalid; \
    assign ifc``.bresp = ifc``_bresp; \
    assign ifc``.bid = ifc``_bid; \

`define AXI4W_CACHE(a, b, cond) \
    axi4w_t now_``a; \
    axi4w_t next_``a; \
    `AXI4W_IF_TO_S(b, next_``a) \
    `AXI4W_S_TO_IF(now_``a, a) \
    always @(posedge clk) begin \
        if (cond) next_``a <= now_``a; \
    end

`define AXI4W_CONNECT(a, b) \
    axi4w_t mid_``b``_``a; \
    `AXI4W_IF_TO_S(b, mid_``b``_``a) \
    `AXI4W_S_TO_IF(mid_``b``_``a, a) \

`define AXI4W_MUTEX(a, b, cond, c) \
    axi4w_t mux_``a; \
    axi4w_t mux_``b; \
    axi4w_t mux_``c; \
    `AXI4W_IF_TO_S(c, mux_``c) \
    always_comb begin \
        mux_``c = (cond) ? mux_``a : mux_``b; \
    end \
    `AXI4W_S_TO_IF(mux_``a, a) \
    `AXI4W_S_TO_IF(mux_``b, b) \

`endif

