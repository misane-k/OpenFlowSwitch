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
    input          arready,
    output         arvalid,
    output  [31:0] araddr,
    output  [3:0]  arid,
    output  [7:0]  arlen,
    output  [2:0]  arsize,
    output  [1:0]  arburst,
    output         rready,
    input          rvalid,
    input   [1:0]  rresp,
    input   [63:0] rdata,
    input          rlast,
    input   [3:0]  rid,
*/

`ifndef TYPE_AXI4_SVH
`define TYPE_AXI4_SVH

/* verilator lint_off UNUSEDSIGNAL */
interface axi4_if (
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
    logic          arready;
    logic          arvalid;
    logic  [31:0]  araddr;
    logic  [3:0]   arid;
    logic  [7:0]   arlen;
    logic  [2:0]   arsize;
    logic  [1:0]   arburst;
    logic          rready;
    logic          rvalid;
    logic  [1:0]   rresp;
    logic  [63:0]  rdata;
    logic          rlast;
    logic  [3:0]   rid;
    
    modport master (
        input  awready, wready, bvalid, bresp, bid, arready, rvalid, rresp, 
               rdata, rlast, rid, 
        output awvalid, awaddr, awid, awlen, awsize, awburst, wvalid, wdata, 
               wstrb, wlast, bready, arvalid, araddr, arid, arlen, arsize, 
               arburst, rready 
    );
    
    modport slave (
        input  awvalid, awaddr, awid, awlen, awsize, awburst, wvalid, wdata, 
               wstrb, wlast, bready, arvalid, araddr, arid, arlen, arsize, 
               arburst, rready, 
        output awready, wready, bvalid, bresp, bid, arready, rvalid, rresp, 
               rdata, rlast, rid 
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
    logic          arready;
    logic          arvalid;
    logic  [31:0]  araddr;
    logic  [3:0]   arid;
    logic  [7:0]   arlen;
    logic  [2:0]   arsize;
    logic  [1:0]   arburst;
    logic          rready;
    logic          rvalid;
    logic  [1:0]   rresp;
    logic  [63:0]  rdata;
    logic          rlast;
    logic  [3:0]   rid;
} axi4_t;

`define AXI4_MASTER(ifc)     \
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
    input  logic [3:0]   ifc``_bid, \
    input  logic         ifc``_arready, \
    output logic         ifc``_arvalid, \
    output logic [31:0]  ifc``_araddr, \
    output logic [3:0]   ifc``_arid, \
    output logic [7:0]   ifc``_arlen, \
    output logic [2:0]   ifc``_arsize, \
    output logic [1:0]   ifc``_arburst, \
    output logic         ifc``_rready, \
    input  logic         ifc``_rvalid, \
    input  logic [1:0]   ifc``_rresp, \
    input  logic [63:0]  ifc``_rdata, \
    input  logic         ifc``_rlast, \
    input  logic [3:0]   ifc``_rid

`define AXI4_SLAVE(ifc)     \
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
    output logic [3:0]   ifc``_bid, \
    output logic         ifc``_arready, \
    input  logic         ifc``_arvalid, \
    input  logic [31:0]  ifc``_araddr, \
    input  logic [3:0]   ifc``_arid, \
    input  logic [7:0]   ifc``_arlen, \
    input  logic [2:0]   ifc``_arsize, \
    input  logic [1:0]   ifc``_arburst, \
    input  logic         ifc``_rready, \
    output logic         ifc``_rvalid, \
    output logic [1:0]   ifc``_rresp, \
    output logic [63:0]  ifc``_rdata, \
    output logic         ifc``_rlast, \
    output logic [3:0]   ifc``_rid

`define AXI4_IF_TO_S(ifc, s) \
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
    assign s.arready = ifc.arready; \
    assign ifc.arvalid = s.arvalid; \
    assign ifc.araddr = s.araddr; \
    assign ifc.arid = s.arid; \
    assign ifc.arlen = s.arlen; \
    assign ifc.arsize = s.arsize; \
    assign ifc.arburst = s.arburst; \
    assign ifc.rready = s.rready; \
    assign s.rvalid = ifc.rvalid; \
    assign s.rresp = ifc.rresp; \
    assign s.rdata = ifc.rdata; \
    assign s.rlast = ifc.rlast; \
    assign s.rid = ifc.rid; \

`define AXI4_S_TO_IF(s, ifc) \
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
    assign ifc.arready = s.arready; \
    assign s.arvalid = ifc.arvalid; \
    assign s.araddr = ifc.araddr; \
    assign s.arid = ifc.arid; \
    assign s.arlen = ifc.arlen; \
    assign s.arsize = ifc.arsize; \
    assign s.arburst = ifc.arburst; \
    assign s.rready = ifc.rready; \
    assign ifc.rvalid = s.rvalid; \
    assign ifc.rresp = s.rresp; \
    assign ifc.rdata = s.rdata; \
    assign ifc.rlast = s.rlast; \
    assign ifc.rid = s.rid; \

`define AXI4_PACK(ifc) \
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
    assign ifc``_arready = ifc``.arready; \
    assign ifc``.arvalid = ifc``_arvalid; \
    assign ifc``.araddr = ifc``_araddr; \
    assign ifc``.arid = ifc``_arid; \
    assign ifc``.arlen = ifc``_arlen; \
    assign ifc``.arsize = ifc``_arsize; \
    assign ifc``.arburst = ifc``_arburst; \
    assign ifc``.rready = ifc``_rready; \
    assign ifc``_rvalid = ifc``.rvalid; \
    assign ifc``_rresp = ifc``.rresp; \
    assign ifc``_rdata = ifc``.rdata; \
    assign ifc``_rlast = ifc``.rlast; \
    assign ifc``_rid = ifc``.rid; \

`define AXI4_FLAT(ifc) \
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
    assign ifc``.arready = ifc``_arready; \
    assign ifc``_arvalid = ifc``.arvalid; \
    assign ifc``_araddr = ifc``.araddr; \
    assign ifc``_arid = ifc``.arid; \
    assign ifc``_arlen = ifc``.arlen; \
    assign ifc``_arsize = ifc``.arsize; \
    assign ifc``_arburst = ifc``.arburst; \
    assign ifc``_rready = ifc``.rready; \
    assign ifc``.rvalid = ifc``_rvalid; \
    assign ifc``.rresp = ifc``_rresp; \
    assign ifc``.rdata = ifc``_rdata; \
    assign ifc``.rlast = ifc``_rlast; \
    assign ifc``.rid = ifc``_rid; \

`define AXI4_CACHE(a, b, cond) \
    axi4_t now_``a; \
    axi4_t next_``a; \
    `AXI4_IF_TO_S(b, next_``a) \
    `AXI4_S_TO_IF(now_``a, a) \
    always @(posedge clk) begin \
        if (cond) next_``a <= now_``a; \
    end

`define AXI4_CONNECT(a, b) \
    axi4_t mid_``b``_``a; \
    `AXI4_IF_TO_S(b, mid_``b``_``a) \
    `AXI4_S_TO_IF(mid_``b``_``a, a) \

`define AXI4_MUTEX(a, b, cond, c) \
    axi4_t mux_``a; \
    axi4_t mux_``b; \
    axi4_t mux_``c; \
    `AXI4_IF_TO_S(c, mux_``c) \
    always_comb begin \
        mux_``c = (cond) ? mux_``a : mux_``b; \
    end \
    `AXI4_S_TO_IF(mux_``a, a) \
    `AXI4_S_TO_IF(mux_``b, b) \

`endif

