`ifndef TYPE_OF0_SVH
`define TYPE_OF0_SVH

typedef struct packed {
    logic  [31:0] wildcards;
    logic  [15:0] in_port;
    logic  [47:0] eth_src;
    logic  [47:0] eth_dst;
    logic  [15:0] vlan_id;
    logic  [7:0]  vlan_pcp;
    logic  [7:0]  status;
    logic  [15:0] eth_type;
    logic  [7:0]  ip_tos;
    logic  [7:0]  ip_proto;
    logic  [15:0] pad2;
    logic  [31:0] ipv4_src;
    logic  [31:0] ipv4_dst;
    logic  [15:0] tp_src;
    logic  [15:0] tp_dst;
    logic  [15:0] idle_time;
    logic  [15:0] hard_time;
    logic  [15:0] prior;
    logic  [15:0] flags;
    logic  [63:0] cookie;
    logic  [63:0] packet_count;
    logic  [63:0] byte_count;
    logic  [63:0] last_tick;
    logic  [63:0] insert_tick;
} of0_t;

`define OF0_UNPACK(FLOW, BUF, BASE) \
assign FLOW.wildcards     = BUF[BASE + 31 : BASE + 0]; \
assign FLOW.in_port       = BUF[BASE + 47 : BASE + 32]; \
assign FLOW.eth_src       = BUF[BASE + 95 : BASE + 48]; \
assign FLOW.eth_dst       = BUF[BASE + 143 : BASE + 96]; \
assign FLOW.vlan_id       = BUF[BASE + 159 : BASE + 144]; \
assign FLOW.vlan_pcp      = BUF[BASE + 167 : BASE + 160]; \
assign FLOW.status        = BUF[BASE + 175 : BASE + 168]; \
assign FLOW.eth_type      = BUF[BASE + 191 : BASE + 176]; \
assign FLOW.ip_tos        = BUF[BASE + 199 : BASE + 192]; \
assign FLOW.ip_proto      = BUF[BASE + 207 : BASE + 200]; \
assign FLOW.pad2          = BUF[BASE + 223 : BASE + 208]; \
assign FLOW.ipv4_src      = BUF[BASE + 255 : BASE + 224]; \
assign FLOW.ipv4_dst      = BUF[BASE + 287 : BASE + 256]; \
assign FLOW.tp_src        = BUF[BASE + 303 : BASE + 288]; \
assign FLOW.tp_dst        = BUF[BASE + 319 : BASE + 304]; \
assign FLOW.idle_time     = BUF[BASE + 335 : BASE + 320]; \
assign FLOW.hard_time     = BUF[BASE + 351 : BASE + 336]; \
assign FLOW.prior         = BUF[BASE + 367 : BASE + 352]; \
assign FLOW.flags         = BUF[BASE + 383 : BASE + 368]; \
assign FLOW.cookie        = BUF[BASE + 447 : BASE + 384]; \
assign FLOW.packet_count  = BUF[BASE + 511 : BASE + 448]; \
assign FLOW.byte_count    = BUF[BASE + 575 : BASE + 512]; \
assign FLOW.last_tick     = BUF[BASE + 639 : BASE + 576]; \
assign FLOW.insert_tick   = BUF[BASE + 703 : BASE + 640]; \

`define of0_wildcards 0
`define of0_in_port 4
`define of0_eth_src 6
`define of0_eth_dst 12
`define of0_vlan_id 18
`define of0_vlan_pcp 20
`define of0_status 21
`define of0_eth_type 22
`define of0_ip_tos 24
`define of0_ip_proto 25
`define of0_pad2 26
`define of0_ipv4_src 28
`define of0_ipv4_dst 32
`define of0_tp_src 36
`define of0_tp_dst 38
`define of0_idle_time 40
`define of0_hard_time 42
`define of0_prior 44
`define of0_flags 46
`define of0_cookie 48
`define of0_packet_count 56
`define of0_byte_count 64
`define of0_last_tick 72
`define of0_insert_tick 80

// 704 bit, 88 byte

`endif

