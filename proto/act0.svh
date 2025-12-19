`ifndef TYPE_ACT0_SVH
`define TYPE_ACT0_SVH

`define OFPAT_OUTPUT        0
`define OFPAT_SET_VLAN_VID  1
`define OFPAT_SET_VLAN_PCP  2
`define OFPAT_STRIP_VLAN    3
`define OFPAT_SET_ETH_SRC   4
`define OFPAT_SET_ETH_DST   5
`define OFPAT_SET_IP_SRC    6
`define OFPAT_SET_IP_DST    7
`define OFPAT_SET_IP_TOS    8
`define OFPAT_SET_TP_SRC    9
`define OFPAT_SET_TP_DST    10
`define OFPAT_EOF        16'hcccc

typedef struct packed {
    logic  [10:0] opcode;
    logic  [31:0] pkg_dst;
    logic  [7:0]  vlan_pcp;
    logic  [15:0] vlan_id;
    logic  [47:0] eth_src;
    logic  [47:0] eth_dst;
    logic  [31:0] ipv4_src;
    logic  [31:0] ipv4_dst;
    logic  [7:0]  ip_tos;
    logic  [15:0] tp_src;
    logic  [15:0] tp_dst;
} act0_t;

`endif