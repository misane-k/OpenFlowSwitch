`ifndef TYPE_PKG_HDR_SVH
`define TYPE_PKG_HDR_SVH

typedef struct packed {
    logic  [47:0] eth_dst;
    logic  [47:0] eth_src;
    logic  [15:0] eth_type;
    logic  [15:0] vlan_id;
    logic  [7:0]  vlan_pcp;
    logic  [7:0]  ip_tos;
    logic  [7:0]  ip_proto;
    logic  [31:0] ipv4_src;
    logic  [31:0] ipv4_dst;
    logic  [15:0] tp_src;
    logic  [15:0] tp_dst;
    logic  [15:0] in_port;
    logic  [15:0] pkg_bytes;
} pkg_hdr_t;

`endif

