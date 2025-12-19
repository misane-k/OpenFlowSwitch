/*
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

`ifndef TYPE_AXI4R_SVH
`define TYPE_AXI4R_SVH

/* verilator lint_off UNUSEDSIGNAL */
interface axi4r_if (
);
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
        input  arready, rvalid, rresp, rdata, rlast, rid, 
        output arvalid, araddr, arid, arlen, arsize, arburst, rready 
    );
    
    modport slave (
        input  arvalid, araddr, arid, arlen, arsize, arburst, rready, 
        output arready, rvalid, rresp, rdata, rlast, rid 
    );
endinterface

typedef struct packed {
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
} axi4r_t;

`define AXI4R_MASTER(ifc)     \
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

`define AXI4R_SLAVE(ifc)     \
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

`define AXI4R_IF_TO_S(ifc, s) \
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

`define AXI4R_S_TO_IF(s, ifc) \
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

`define AXI4R_PACK(ifc) \
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

`define AXI4R_FLAT(ifc) \
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

`define AXI4R_CACHE(a, b, cond) \
    axi4r_t now_``a; \
    axi4r_t next_``a; \
    `AXI4R_IF_TO_S(b, next_``a) \
    `AXI4R_S_TO_IF(now_``a, a) \
    always @(posedge clk) begin \
        if (cond) next_``a <= now_``a; \
    end

`define AXI4R_CONNECT(a, b) \
    axi4r_t mid_``b``_``a; \
    `AXI4R_IF_TO_S(b, mid_``b``_``a) \
    `AXI4R_S_TO_IF(mid_``b``_``a, a) \

`define AXI4R_MUTEX(a, b, cond, c) \
    axi4r_t mux_``a; \
    axi4r_t mux_``b; \
    axi4r_t mux_``c; \
    `AXI4R_IF_TO_S(c, mux_``c) \
    always_comb begin \
        mux_``c = (cond) ? mux_``a : mux_``b; \
    end \
    `AXI4R_S_TO_IF(mux_``a, a) \
    `AXI4R_S_TO_IF(mux_``b, b) \

`endif

