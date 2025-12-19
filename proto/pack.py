src = """
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
    logic  [15:0]  pad2;
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
"""

total = 0
extra = ""
for line in src.splitlines():
    if not line.strip():
        continue
    while "  " in line:
        line = line.replace("  ", " ")
    typ, width, name = line.strip().split(" ")
    width = 1 + int(width.replace("[", "").replace(":0]", ""))
    name = name.replace(";", "").replace(",", "")
    # print(name, width)
    # print(f"assign new_flow[i].{name.ljust(12)}  = buf[BASE + {total-1+width} : BASE + {total}]; \\")
    print(f"assign FLOW.{name.ljust(12)}  = BUF[BASE + {total-1+width} : BASE + {total}]; \\")
    extra += f"`define of0_{name} {total//8}\n"
    total += width

print(f"\n{extra}")
print(f"// {total} bit, {total // 8} byte")