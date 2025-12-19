/*
 ^  output         tvalid,
 ^  input          tready,
    output  [7:0]  tdata,
    output  [0:0]  tstrb,
    output  [0:0]  tkeep,
    output         tlast,
 ^  output  [3:0]  tid,
 ^  output  [3:0]  tdest,
    output  [0:0]  tuser,
*/

`ifndef TYPE_AXI4STREAM_SVH
`define TYPE_AXI4STREAM_SVH

interface axi4stream_if (
);
    logic          tvalid;
    logic          tready;
    logic  [7:0]   tdata;
    logic  [0:0]   tstrb;
    logic  [0:0]   tkeep;
    logic          tlast;
    logic  [3:0]   tid;
    logic  [3:0]   tdest;
    logic  [0:0]   tuser;
    
    modport master (
        input  tready, 
        output tvalid, tdata, tstrb, tkeep, tlast, tid, tdest, tuser 
    );
    
    modport slave (
        input  tvalid, tdata, tstrb, tkeep, tlast, tid, tdest, tuser, 
        output tready 
    );
endinterface

typedef struct packed {
    logic          tvalid;
    logic          tready;
    logic  [7:0]   tdata;
    logic  [0:0]   tstrb;
    logic  [0:0]   tkeep;
    logic          tlast;
    logic  [3:0]   tid;
    logic  [3:0]   tdest;
    logic  [0:0]   tuser;
} axi4stream_t;

`define AXI4STREAM_MASTER(ifc)     \
    output logic         ifc``_tvalid, \
    input  logic         ifc``_tready, \
    output logic [7:0]   ifc``_tdata, \
    output logic [0:0]   ifc``_tstrb, \
    output logic [0:0]   ifc``_tkeep, \
    output logic         ifc``_tlast, \
    output logic [3:0]   ifc``_tid, \
    output logic [3:0]   ifc``_tdest, \
    output logic [0:0]   ifc``_tuser

`define AXI4STREAM_SLAVE(ifc)     \
    input  logic         ifc``_tvalid, \
    output logic         ifc``_tready, \
    input  logic [7:0]   ifc``_tdata, \
    input  logic [0:0]   ifc``_tstrb, \
    input  logic [0:0]   ifc``_tkeep, \
    input  logic         ifc``_tlast, \
    input  logic [3:0]   ifc``_tid, \
    input  logic [3:0]   ifc``_tdest, \
    input  logic [0:0]   ifc``_tuser

`define AXI4STREAM_IF_TO_S(ifc, s) \
    /*assign ifc.tvalid = s.tvalid;*/ \
    /*assign s.tready = ifc.tready;*/ \
    assign ifc.tdata = s.tdata; \
    assign ifc.tstrb = s.tstrb; \
    assign ifc.tkeep = s.tkeep; \
    assign ifc.tlast = s.tlast; \
    /*assign ifc.tid = s.tid;*/ \
    /*assign ifc.tdest = s.tdest;*/ \
    assign ifc.tuser = s.tuser; \

`define AXI4STREAM_S_TO_IF(s, ifc) \
    /*assign s.tvalid = ifc.tvalid;*/ \
    /*assign ifc.tready = s.tready;*/ \
    assign s.tdata = ifc.tdata; \
    assign s.tstrb = ifc.tstrb; \
    assign s.tkeep = ifc.tkeep; \
    assign s.tlast = ifc.tlast; \
    /*assign s.tid = ifc.tid;*/ \
    /*assign s.tdest = ifc.tdest;*/ \
    assign s.tuser = ifc.tuser; \

`define AXI4STREAM_PACK(ifc) \
    assign ifc``.tvalid = ifc``_tvalid; \
    assign ifc``_tready = ifc``.tready; \
    assign ifc``.tdata = ifc``_tdata; \
    assign ifc``.tstrb = ifc``_tstrb; \
    assign ifc``.tkeep = ifc``_tkeep; \
    assign ifc``.tlast = ifc``_tlast; \
    assign ifc``.tid = ifc``_tid; \
    assign ifc``.tdest = ifc``_tdest; \
    assign ifc``.tuser = ifc``_tuser; \

`define AXI4STREAM_FLAT(ifc) \
    assign ifc``_tvalid = ifc``.tvalid; \
    assign ifc``.tready = ifc``_tready; \
    assign ifc``_tdata = ifc``.tdata; \
    assign ifc``_tstrb = ifc``.tstrb; \
    assign ifc``_tkeep = ifc``.tkeep; \
    assign ifc``_tlast = ifc``.tlast; \
    assign ifc``_tid = ifc``.tid; \
    assign ifc``_tdest = ifc``.tdest; \
    assign ifc``_tuser = ifc``.tuser; \

`define AXI4STREAM_CACHE(a, b, cond) \
    axi4stream_t now_``a; \
    axi4stream_t next_``a; \
    `AXI4STREAM_IF_TO_S(b, next_``a) \
    `AXI4STREAM_S_TO_IF(now_``a, a) \
    always @(posedge clk) begin \
        if (cond) next_``a <= now_``a; \
    end

`define AXI4STREAM_CONNECT(a, b) \
    axi4stream_t mid_``b``_``a; \
    `AXI4STREAM_IF_TO_S(b, mid_``b``_``a) \
    `AXI4STREAM_S_TO_IF(mid_``b``_``a, a) \

`define AXI4STREAM_MUTEX(a, b, cond, c) \
    axi4stream_t mux_``a; \
    axi4stream_t mux_``b; \
    axi4stream_t mux_``c; \
    `AXI4STREAM_IF_TO_S(c, mux_``c) \
    always_comb begin \
        mux_``c = (cond) ? mux_``a : mux_``b; \
    end \
    `AXI4STREAM_S_TO_IF(mux_``a, a) \
    `AXI4STREAM_S_TO_IF(mux_``b, b) \

`endif

