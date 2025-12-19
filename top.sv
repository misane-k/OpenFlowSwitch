`include "proto/type_axi4lite.svh"
`include "proto/type_axi4r.svh"
`include "proto/type_axi4w.svh"
`include "proto/type_axi4.svh"
`include "proto/type_axi4stream.svh"
`include "proto/of0.svh"
`include "proto/act0.svh"
`include "proto/pkg_hdr.svh"

parameter FREQ = 75_497_472;
// 100_663_296;

module device(
    input clk,
    input rst,
    axi4lite_if.slave axil_dev,
    output [31:0] match_addr,
    output [31:0] buffer_addr,
    output [31:0] action_addr,
    output [31:0] status,
    output reg [63:0] tick,
    input running,
    input error
);

    reg [3:0][31:0] regstack;
    reg [7:0] new_status;
    assign match_addr  = regstack[0];
    assign buffer_addr = regstack[1];
    assign action_addr = regstack[2];
    assign status      = regstack[3];
    /* verilator lint_off WIDTH */
    wire [15:0] freq = FREQ / 1_000_000;
    /* verilator lint_on WIDTH */
`ifndef DPIC
    always @(posedge clk) begin
`else
    always @(negedge clk) begin
`endif
        if (rst) begin
            regstack[3][15:8] <= 0;
        end else begin
            regstack[3][8] <= running;
            if (error) regstack[3][9] <= error;
        end
        regstack[3][7:0] <= new_status;
        regstack[3][31:16] <= freq;
    end
    
    wire [3:0][31:0] wirestack;
    always @(posedge clk) begin
        tick <= (rst) ? 0 : tick + 1;
    end

    assign wirestack[0] = tick[63:32];
    assign wirestack[1] = tick[31:0];
    // utilization, 2: tick, 3: fifo
    assign wirestack[2] = 32'h12345678;
    assign wirestack[3] = 32'hdeadbeef;


    // 假设4字节对齐，rready/bready = 1
    reg dev_rq, dev_wq;
    reg [31:0] dev_raddr, dev_waddr;
    reg [31:0] dev_rdata, dev_wdata;
    wire r_hit, w_hit;

    always @(posedge clk) begin
        if (axil_dev.rready | (dev_rq == 0)) dev_rq <= axil_dev.arvalid;
        if (axil_dev.bready | (dev_wq == 0)) dev_wq <= axil_dev.wvalid;
        // dev_rq <= axil_dev.arvalid;
        // dev_wq <= axil_dev.wvalid;
        if (axil_dev.arvalid) dev_raddr <= axil_dev.araddr;
        if (axil_dev.awvalid) dev_waddr <= axil_dev.awaddr;
        if (axil_dev.wvalid)  dev_wdata <= axil_dev.wdata;
    end

    assign r_hit = dev_raddr[15:5] == 0;
    assign w_hit = dev_waddr[15:4] == 0;
    assign dev_rdata = r_hit ? (dev_raddr[4] ? wirestack[dev_raddr[3:2]] : regstack[dev_raddr[3:2]]) : 32'h0;

`ifndef DPIC
    wire [31:0] addr_high = dev_wdata & ~32'hfff;
    always @(posedge clk) begin
        if (rst == 0) begin
            if (dev_wq & w_hit) begin
                case (dev_waddr[3:2])
                    0, 1, 2: begin regstack[dev_waddr[3:2]] <= addr_high; end
                    3: begin new_status <= dev_wdata[7:0]; end
                endcase
            end
        end else begin
            new_status <= 0;
        end
    end
`else
        import "DPI-C" function int  dev_read (int raddr);
        import "DPI-C" function void dev_write(int waddr, int wdata);

        always @(negedge clk) begin
            regstack[0] <= dev_read(0);
            regstack[1] <= dev_read(4);
            regstack[2] <= dev_read(8);
            /* verilator lint_off WIDTH */
            new_status <= (rst) ? 0 : dev_read(12);
            /* verilator lint_on WIDTH */
            dev_write(12, regstack[3]);
            dev_write(16, wirestack[0]);
            dev_write(20, wirestack[1]);
            dev_write(24, wirestack[2]);
            dev_write(28, wirestack[3]);
        end
`endif

    assign axil_dev.arready = 1'b1;
    assign axil_dev.rdata   = dev_rdata;
    assign axil_dev.rresp   = r_hit ? 2'b00 : 2'b11;
    assign axil_dev.rvalid  = dev_rq;
    assign axil_dev.awready = 1'b1;
    assign axil_dev.wready  = 1'b1;
    assign axil_dev.bresp   = w_hit ? 2'b00 : 2'b11;
    assign axil_dev.bvalid  = dev_wq;
endmodule


module burst_match #(
    parameter CNT = 1024,
    parameter BYT_MAT = 128
) (
    input clk,
    input rst,
    axi4r_if.master axir_mat,
    input runnable,
    input [31:0] match_addr,
    output buf_valid,
    output [BYT_MAT*8-1:0] buff,
    output reg [19:0] mat_ind,
    output error,
    output running
);
    genvar i;

    reg state;
    always @(posedge clk) begin
        if (rst) begin
            state <= 1'b0;
        end else begin
            case (state)
                1'b0: begin state <= (runnable) ? 1'b1 : state; end
                1'b1: begin state <= (axir_mat.rlast) ? 1'b0 : state; end
            endcase
        end
    end
    // test
    reg arvalid;
    always @(posedge clk) begin
        if (rst) begin
            arvalid <= 1'b0;
        end else begin
            case (arvalid)
                1'b0: arvalid <= (state == 0) & runnable;
                1'b1: arvalid <= ~axir_mat.arready;
            endcase
        end
    end

    reg [7:0] bst_cnt;
    // mat_ind: 当前match规则ind
    wire buf_finish = (axir_mat.rvalid) & (bst_cnt == BYT_MAT/8-1);
    assign buf_valid = buf_finish;
    // assign buf_valid = bst_cnt >= 88;
    always @(posedge clk) begin
        bst_cnt <= (rst | axir_mat.rlast) ? 0 : (axir_mat.rvalid) ? ((bst_cnt == BYT_MAT/8-1) ? 0 : bst_cnt+1) : bst_cnt;
        mat_ind <= (rst)                  ? 0 : (buf_finish)      ? ((mat_ind == CNT-1)       ? 0 : mat_ind+1) : mat_ind;
    end

    /* Debug */
    (* keep = "true" *) wire arready = axir_mat.arready;
    wire [63:0] b0 = pbuf[0];
    wire [63:0] b1 = pbuf[1];
    wire [63:0] b2 = pbuf[2];
    wire [63:0] b3 = pbuf[3];

    reg [BYT_MAT/8-1:0][63:0] pbuf;
    always @(posedge clk) begin
        if (axir_mat.rvalid) pbuf[bst_cnt] <= axir_mat.rdata;
    end
    generate
        for (i=0; i < BYT_MAT/8; i++) begin: split_pbuf
            localparam low = i*64;
            assign buff[low+63:low] = pbuf[i];
        end
    endgenerate

    /* verilator lint_off WIDTH */
    wire [31:0] offset = (mat_ind >> 3) << 10;
    /* verilator lint_on WIDTH */
    assign axir_mat.arvalid = (state == 1'b1) & arvalid;
    assign axir_mat.araddr  = match_addr + offset;
    assign error = (axir_mat.rresp == 2'b10) | (axir_mat.rresp == 2'b11);
    assign axir_mat.rready  = 1'b1;
    // 128 * 8 = 1k
    assign axir_mat.arid    = 0;
    assign axir_mat.arburst = 2'b01;         // BURST_INCR
    assign axir_mat.arsize  = 3'b011;        // 8 byte
    assign axir_mat.arlen   = 127;           // 128
    assign running = state == 1'b1;
endmodule


module fifo_match #(
    CNT = 1024,
    FIFO_LEN = 50,
    BYT_MAT = 128
) (
    input clk,
    input rst,
    input [63:0] tick,
    
    input pkg_in_once,
    input pkg_hdr_t pkg_in,
    input [19:0] ddr_in_ind,
    
    input buf_valid,
    input [BYT_MAT*8-1:0] buff,
    input [19:0] mat_ind,

    output inv_valid,
    output [19:0] inv_ind,

    output fifo_ready,
    output fifo_valid,
    input fifo_next,
    output [19:0] fifo_ind,
    output pkg_hdr_t pkg_out,
    output [19:0] ddr_out_ind
);
    genvar i;

    // 每次匹配1项，一共8项
    of0_t new_flow;
    reg  [19:0] last_ind;
    wire [19:0] new_ind   = mat_ind;
    wire [15:0] new_prior = new_flow.prior;
    wire [31:0] ip_src_mask = ~((1 << (new_flow.wildcards[12:8] )) - 1);
    wire [31:0] ip_dst_mask = ~((1 << (new_flow.wildcards[18:14])) - 1);
    wire timeout = (new_flow.idle_time != 0) & (new_flow.hard_time != 0) & (
                   (new_flow.last_tick > (FREQ * new_flow.idle_time)) |
                   (new_flow.insert_tick > (FREQ * new_flow.hard_time)) );
    wire flow_enable = new_flow.status[0];
    assign inv_valid = buf_valid & timeout;
    assign inv_ind = mat_ind;
    always @(posedge clk) begin
        if (buf_valid) last_ind <= new_ind;
    end
    `OF0_UNPACK(new_flow, buff, 0)


    /* Debug */
    wire [31:0] wildcards = new_flow.wildcards;
    wire [31:0] dst1 = new_flow.ipv4_dst;
    wire [31:0] dst2 = pkgs[0].ipv4_dst;
    wire [47:0] dst3 = new_flow.eth_dst;
    wire [47:0] dst4 = pkgs[0].eth_dst;

    // 解析flow，pkgs全部匹配
    wire      [FIFO_LEN-1:0] new_match;
    reg       [FIFO_LEN-1:0] pkg_process;
    pkg_hdr_t [FIFO_LEN-1:0] pkgs;
    generate
        for (i=0; i < FIFO_LEN; i++) begin : match_all
            assign new_match[i] = flow_enable & ~timeout & pkg_process[i] &
                (new_flow.wildcards[0] | (new_flow.in_port == pkgs[i].in_port)) &
                (new_flow.wildcards[1] | (new_flow.vlan_id == pkgs[i].vlan_id)) &
                (new_flow.wildcards[2] | (new_flow.eth_src == pkgs[i].eth_src)) &
                (new_flow.wildcards[3] | (new_flow.eth_dst == pkgs[i].eth_dst)) &
                (new_flow.wildcards[4] | (new_flow.eth_type == pkgs[i].eth_type)) &
                (new_flow.wildcards[5] | (new_flow.ip_proto == pkgs[i].ip_proto)) &
                (new_flow.wildcards[6] | (new_flow.tp_src == pkgs[i].tp_src)) &
                (new_flow.wildcards[7] | (new_flow.tp_dst == pkgs[i].tp_dst)) &
                (new_flow.wildcards[13] | ((ip_src_mask & new_flow.ipv4_src) == (ip_src_mask & pkgs[i].ipv4_src))) &
                (new_flow.wildcards[19] | ((ip_dst_mask & new_flow.ipv4_dst) == (ip_dst_mask & pkgs[i].ipv4_dst))) &
                (new_flow.wildcards[20] | (new_flow.vlan_pcp == pkgs[i].vlan_pcp)) &
                (new_flow.wildcards[21] | (new_flow.ip_tos == pkgs[i].ip_tos));
        end
    endgenerate


    // FIFO
    wire empty, full;
    (* keep = "true" *) reg [$clog2(FIFO_LEN)-1:0] ptr_pre, ptr_last;
    reg [FIFO_LEN-1:0] match;
    reg [FIFO_LEN-1:0][19:0] ind;
    reg [FIFO_LEN-1:0][19:0] start_ind;
    reg [FIFO_LEN-1:0][15:0] prior;
    reg [FIFO_LEN-1:0][19:0] ddr_ind;

    always @(posedge clk) begin
        if (rst) begin
            ptr_pre <= 0;
            ptr_last <= 0;
        end else begin
            if (~full & pkg_in_once) begin
                ptr_pre <= (ptr_pre >= FIFO_LEN-1) ? 0 : ptr_pre+1;
            end
            // 没匹配任何规则丢弃
            if (~empty & (fifo_next | ~match[ptr_last])) begin
                ptr_last <= (ptr_last >= FIFO_LEN-1) ? 0 : ptr_last+1;
                `ifdef DPIC
                    if (~match[ptr_last]) $display("pkg drop at %d", tick*2);
                `endif
            end
        end
    end
    wire fifo_drop = ~empty & ~match[ptr_last];
    
    always @(posedge clk) begin
        if (rst) begin
            pkg_process <= 0;
        end else begin
            for (int k=0; k < FIFO_LEN; k++) begin
                if (buf_valid & (start_ind[k] == new_ind)) begin
                    pkg_process[k] <= 1'b0;
                end
            end
            if (pkg_in_once) begin
                pkg_process[ptr_pre] <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        for (int k=0; k < FIFO_LEN; k++) begin
            if (pkg_process[k] & buf_valid & new_match[k] & (prior[k] <= new_prior)) begin
                match[k] <= new_match[k];
                ind[k] <= new_ind;
                prior[k] <= new_prior;
            end
        end
        if (pkg_in_once) begin
            pkgs[ptr_pre] <= pkg_in;
            match[ptr_pre] <= 1'b0;
            start_ind[ptr_pre] <= last_ind;
            prior[ptr_pre] <= 0;
            ddr_ind[ptr_pre] <= ddr_in_ind;
        end
    end

    assign fifo_valid = ~empty & match[ptr_last];
    assign empty = (ptr_last == ptr_pre) | pkg_process[ptr_last];
    assign full = (ptr_last == ptr_pre+1) | ((ptr_last == 0) & (ptr_pre == FIFO_LEN-1));
    assign fifo_ready = ~full;

    // fifo_ind: 匹配到的ind
    assign fifo_ind = ind[ptr_last];
    assign pkg_out = pkgs[ptr_last];
    assign ddr_out_ind = ddr_ind[ptr_last];
endmodule


module flow_invalid #(
    BYT_MAT = 128
) (
    input clk,
    input rst,
    input inv_valid,
    input [19:0] inv_ind,
    input [31:0] match_addr,
    axi4lite_if.master axil_inv,
    output running
);

    reg last_valid;
    always @(posedge clk) begin
        last_valid <= inv_valid;
    end
    wire valid_once = ~last_valid & inv_valid;
    
    reg [2:0] state;
    always @(posedge clk) begin
        if (rst) begin
            state <= 0;
        end else begin
            if (axil_inv.awready) begin
                state[0] <= 1'b0;
            end
            if (axil_inv.wready) begin
                state[1] <= 1'b0;
            end
            if (axil_inv.bvalid) begin
                state[2] <= 1'b0;
            end
            if ((state == 0) & valid_once) begin
                state <= 3'b111;
            end
        end
    end

    assign axil_inv.awvalid = state[0];
    assign axil_inv.awaddr = match_addr + inv_ind * BYT_MAT + `of0_status;
    assign axil_inv.wvalid = state[1];
    assign axil_inv.wdata = 32'h0;
    assign axil_inv.wstrb = 4'b0001 << (`of0_status % 4);
    assign axil_inv.bready = 1'b1;
    assign running = (state != 0) | valid_once;
endmodule


module flow_update #(
    BYT_MAT = 128
) (
    input clk,
    input rst,
    input [63:0] tick,
    input fifo_valid_once,
    input [19:0] fifo_ind,
    input [31:0] match_addr,
    input [15:0] pkg_bytes,
    axi4_if.master axi_stat,
    output running
);

    reg [1:0] state;
    always @(posedge clk) begin
        if (rst) begin
            state <= 2'b00;
        end else begin
            case (state)
                2'b00: begin state <= (fifo_valid_once) ? 2'b01 : state; end
                2'b01: begin state <= (axi_stat.rlast)  ? 2'b10 : state; end
                2'b10: begin state <= (axi_stat.wlast & axi_stat.wready) ? 2'b00 : state; end
                default: begin end
            endcase
        end
    end
    reg [1:0] cnt;
    always @(posedge clk) begin
        if (((state == 2'b00) & (fifo_valid_once)) | ((state == 2'b01) & (axi_stat.rlast))) begin
            cnt <= 0;
        end else if ((state == 2'b01) & (axi_stat.rvalid)) begin
            cnt <= cnt + 1;
        end else if ((state == 2'b10) & (axi_stat.bvalid)) begin
            cnt <= cnt + 1;
        end
    end
    // test
    reg arvalid;
    always @(posedge clk) begin
        if (rst) begin
            arvalid <= 1'b0;
        end else begin
            case (arvalid)
                1'b0: arvalid <= (state == 2'b00) & fifo_valid_once;
                1'b1: arvalid <= ~axi_stat.arready;
            endcase
        end
    end
    reg awvalid;
    always @(posedge clk) begin
        if (rst) begin
            awvalid <= 1'b0;
        end else begin
            case (awvalid)
                1'b0: awvalid <= (state == 2'b01) & (axi_stat.rlast);
                1'b1: awvalid <= ~axi_stat.awready;
            endcase
        end
    end


    reg [1:0][63:0] rbuf;
    reg [2:0][63:0] wbuf;
    always @(posedge clk) begin
        if (axi_stat.rvalid) begin
            rbuf[cnt] <= axi_stat.rdata;
        end
    end
    assign wbuf[0] = rbuf[0] + 1;
    assign wbuf[1] = rbuf[1] + {48'h0, pkg_bytes};
    assign wbuf[2] = tick;


    assign axi_stat.arvalid = (state == 2'b01) & arvalid;
    assign axi_stat.araddr  = match_addr + fifo_ind * BYT_MAT + `of0_packet_count;
    assign axi_stat.rready  = 1'b1;
    assign axi_stat.arid    = 0;
    assign axi_stat.arburst = 2'b01;    // BURST_INCR
    assign axi_stat.arsize  = 3'b011;   // 8 byte
    assign axi_stat.arlen   = 1;        // 2

    assign axi_stat.awvalid = (state == 2'b10) & awvalid;
    assign axi_stat.awaddr  = match_addr + fifo_ind * BYT_MAT + `of0_packet_count;
    assign axi_stat.awid    = 0;
    assign axi_stat.awburst = 2'b01;    // BURST_INCR
    assign axi_stat.awsize  = 3'b011;   // 8 byte
    assign axi_stat.awlen   = 2;        // 3
    // assign axi_stat.wvalid  = (state == 2'b10) & ~axi_stat.bvalid;
    assign axi_stat.wvalid  = (state == 2'b10) & ~awvalid;
    assign axi_stat.wdata   = wbuf[cnt];
    assign axi_stat.wstrb   = 8'b11111111;
    assign axi_stat.wlast   = (cnt == 2);
    assign axi_stat.bready  = 1'b1;

    assign running = (state != 2'b00) | fifo_valid_once;
endmodule


module burst_action #(
    parameter BYT_ACT = 256
) (
    input clk,
    input rst,
    input runnable,
    input [31:0] action_addr,
    input fifo_valid_once,
    input fifo_next,
    input [19:0] fifo_ind,
    axi4r_if.master axir_act,
    output react_valid,
    output act0_t react,
    output running
);
    genvar i;

    // 读取act
    reg [1:0] state;
    always @(posedge clk) begin
        if (rst) begin
            state <= 2'b00;
        end else begin
            case (state)
                2'b00: begin state <= fifo_valid_once ? 2'b01 : state; end
                2'b01: begin state <= axir_act.rlast  ? 2'b10 : state; end
                2'b10: begin state <= fifo_next       ? 2'b00 : state; end
                default: begin end
            endcase
        end
    end
    // test
    reg arvalid;
    always @(posedge clk) begin
        if (rst) begin
            arvalid <= 1'b0;
        end else begin
            case (arvalid)
                1'b0: arvalid <= (state == 2'b00) & fifo_valid_once;
                1'b1: arvalid <= ~axir_act.arready;
            endcase
        end
    end

    reg cnt;
    always @(posedge clk) begin
        if (state == 2'b01) begin
            cnt <= (axir_act.rvalid) ? cnt+1 : cnt;
        end else begin
            cnt <= 0;
        end
    end

    // TODO: endian
    reg  [1:0][63:0] buff;
    wire [15:0][7:0] act_u8;
    wire [7:0][15:0] act_u16;
    reg actone;
    always @(posedge clk) begin
        actone <= (cnt == 1) & axir_act.rvalid;
    end
    generate
        for (i=0; i < 16; i++) begin: fill_u8
            localparam low = i % 8 * 8;
            assign act_u8[i] = buff[i/8][low +: 8];
        end
        for (i=0; i < 8; i++) begin: fill_u16
            localparam low = i % 4 * 16;
            assign act_u16[i] = buff[i/4][low +: 16];
        end
    endgenerate

    always @(posedge clk) begin
        if (axir_act.rvalid & (state == 2'b01)) begin
            buff[cnt] <= axir_act.rdata;
        end
    end

    assign axir_act.arvalid = (state == 2'b01) & arvalid;
    assign axir_act.araddr  = action_addr + fifo_ind * BYT_ACT;
    assign axir_act.rready  = 1'b1;
    assign axir_act.arid    = 0;
    assign axir_act.arburst = 2'b01;         // BURST_INCR
    assign axir_act.arsize  = 3'b011;        // 8 byte
    /* verilator lint_off WIDTH */
    assign axir_act.arlen   = BYT_ACT/8-1;   // 32
    /* verilator lint_on WIDTH */

    /* Debug */
    wire [10:0] opcode = react.opcode;
    wire [31:0] pkg_dst = react.pkg_dst;
    wire [15:0] u16_0 = act_u16[0];
    wire [15:0] u16_1 = act_u16[1];
    wire [15:0] u16_2 = act_u16[2];
    wire [15:0] u16_3 = act_u16[3];
    wire [15:0] u16_4 = act_u16[4];

    // 解析动作
    reg eof;
    always @(posedge clk) begin
        if (state == 2'b00) begin
            eof <= 0;
            react.opcode <= 0;
            react.pkg_dst <= 0;
        end else if (~eof & (state == 2'b01) & actone) begin
            case (act_u16[0])
                `OFPAT_OUTPUT      ,
                `OFPAT_SET_VLAN_VID,
                `OFPAT_SET_VLAN_PCP,
                `OFPAT_STRIP_VLAN  ,
                `OFPAT_SET_ETH_SRC ,
                `OFPAT_SET_ETH_DST ,
                `OFPAT_SET_IP_SRC  ,
                `OFPAT_SET_IP_DST  ,
                `OFPAT_SET_IP_TOS  ,
                `OFPAT_SET_TP_SRC  ,
                `OFPAT_SET_TP_DST  :
                /* verilator lint_off WIDTH */
                react.opcode[act_u16[0]] <= 1'b1;
                /* verilator lint_on WIDTH */
            endcase
            case (act_u16[0])
                /* verilator lint_off WIDTH */
                `OFPAT_OUTPUT      : begin react.pkg_dst[act_u16[2]] <= 1'b1; end
                /* verilator lint_on WIDTH */
                `OFPAT_SET_VLAN_VID: begin react.vlan_id  <= act_u16[2];    end
                `OFPAT_SET_VLAN_PCP: begin react.vlan_pcp <= act_u8[4];     end
                `OFPAT_STRIP_VLAN  : begin end
                `OFPAT_SET_ETH_SRC : begin react.eth_src  <= act_u8[9:4];   end
                `OFPAT_SET_ETH_DST : begin react.eth_dst  <= act_u8[9:4];   end
                `OFPAT_SET_IP_SRC  : begin react.ipv4_src <= act_u8[7:4];   end
                `OFPAT_SET_IP_DST  : begin react.ipv4_dst <= act_u8[7:4];   end
                `OFPAT_SET_IP_TOS  : begin react.ip_tos   <= act_u8[4];     end
                `OFPAT_SET_TP_SRC  : begin react.tp_src   <= act_u16[2];    end
                `OFPAT_SET_TP_DST  : begin react.tp_dst   <= act_u16[2];    end
                `OFPAT_EOF         : begin eof <= 1; end
                default: begin end
            endcase
        end
    end
    assign react_valid = state == 2'b10;
    assign running = ~fifo_valid_once & (state == 2'b00);
endmodule


module stream_in #(
    parameter FIFO_LEN = 50,
    parameter BYT_STM = 128,
    parameter BYT_MAC = 2048
) (
    input clk,
    input rst,
    axi4stream_if.slave axis_in,
    input runnable,
    input [31:0] buffer_addr,
    axi4w_if.master ddr_w,
    output pkg_in_valid,
    output pkg_hdr_t pkg_in,
    output reg [19:0] ddr_in_ind,
    input fifo_ready,
    output running,
    output error
);
    genvar i;

    // axi-stream 转 buf
    wire parse_done, save_done;
    reg mode;
    always @(posedge clk) begin
        if (rst) begin
            mode <= 1'b0;
        end else begin
            case (mode)
                1'b0: begin mode <= parse_done ? 1'b1 : mode; end
                1'b1: begin mode <= save_done  ? 1'b0 : mode; end
                default: begin end
            endcase
        end
    end

    reg [$clog2(BYT_STM):0] r_cnt;
    always @(posedge clk) begin
        if (rst) begin
            r_cnt <= 0;
        end else begin
            if (ddr_w.wlast) begin
                r_cnt <= 0;
            end else if (axis_in.tvalid & axis_in.tready) begin
                r_cnt <= r_cnt + 1;
            end else begin
                r_cnt <= r_cnt;
            end
        end
    end

    always @(posedge clk) begin
        if (rst | save_done) begin
            pkg_in.pkg_bytes <= 0;
        end else if (axis_in.tvalid & axis_in.tready) begin
            pkg_in.pkg_bytes <= pkg_in.pkg_bytes + 1;
        end
    end

    reg tlast;
    always @(posedge clk) begin
        if (rst) begin
            tlast <= 0;
        end else begin
            case (tlast)
                1'b0: begin tlast <= axis_in.tlast; end
                1'b1: begin tlast <= ~save_done; end
            endcase
        end
    end
    assign axis_in.tready = ~tlast & (r_cnt < (BYT_STM-1)) & fifo_ready;
    assign save_done = tlast & ddr_w.wlast;

    // test
    reg state;
    wire state_next = ~axis_in.tready;
    always @(posedge clk) begin
        if (rst) begin
            state <= 1'b0;
        end else begin
            case (state)
                1'b0: state <= state_next;
                1'b1: state <= ~ddr_w.wlast;
            endcase
        end
    end
    reg awvalid;
    always @(posedge clk) begin
        if (rst) begin
            awvalid <= 1'b0;
        end else begin
            case (awvalid)
                1'b0: awvalid <= (state == 1'b0) & state_next;
                1'b1: awvalid <= ~ddr_w.awvalid;
            endcase
        end
    end


    reg  [BYT_STM-1:0][7:0] rbuf;
    wire [BYT_STM/8-1:0][63:0] wbuf;
    always @(posedge clk) begin
        if (axis_in.tvalid & axis_in.tready) begin
            rbuf[r_cnt] <= axis_in.tdata;
        end
    end
    // TODO: endian
    generate
        for (i=0; i < BYT_STM; i++) begin: reshape
            localparam low = i % 8 * 8;
            assign wbuf[i/8][low +: 8] = rbuf[i];
        end
    endgenerate

    // buf 转 ddr
    always @(posedge clk) begin
        if (rst) begin
            ddr_in_ind <= 0;
        end else begin
            if (save_done) begin
                ddr_in_ind <= (ddr_in_ind >= FIFO_LEN-1) ? 0 : ddr_in_ind+1;
            end else begin
                ddr_in_ind <= ddr_in_ind;
            end
        end
    end

    reg [$clog2(BYT_STM):0] w_cnt;
    always @(posedge clk) begin
        if (~ddr_w.wvalid) begin
            w_cnt <= 0;
        end else begin
            w_cnt <= ddr_w.bvalid ? w_cnt+1 : w_cnt;
        end
    end

    reg [7:0] frag_cnt;
    always @(posedge clk) begin
        if (mode == 1'b0) begin
            frag_cnt <= 0;
        end else begin
            if (ddr_w.wlast) begin
                frag_cnt <= frag_cnt+1;
            end
        end
    end

    wire no_extra = r_cnt[2:0] == 0;
    assign ddr_w.awvalid = (state == 1'b1) & awvalid;
    assign ddr_w.awaddr  = buffer_addr + ddr_in_ind * BYT_MAC + frag_cnt * BYT_STM;
    assign ddr_w.awid    = 0;
    assign ddr_w.awburst = 2'b01;    // BURST_INCR
    assign ddr_w.awsize  = 3'b011;   // 8 byte
    /* verilator lint_off WIDTH */
    assign ddr_w.awlen   = (r_cnt >> 3) - no_extra;
    assign ddr_w.wlast   = ddr_w.wvalid & (w_cnt == ddr_w.awlen);
    /* verilator lint_on WIDTH */
    assign ddr_w.wvalid  = (state == 1'b1) & ~awvalid;
    assign ddr_w.wdata   = wbuf[w_cnt];
    assign ddr_w.wstrb   = 8'b11111111;
    assign ddr_w.bready  = 1'b1;
    assign running = axis_in.tvalid | ddr_w.wvalid;


    /* Debug */
    wire [15:0] pkg_bytes = pkg_in.pkg_bytes;
    wire [15:0] eth_type = pkg_in.eth_type;
    wire [15:0] tp_src = pkg_in.tp_src;
    wire [31:0] ipv4_src = pkg_in.ipv4_src;
    wire [31:0] ipv4_dst = pkg_in.ipv4_dst;
    wire [47:0] src_mac = pkg_in.eth_src;
    wire [47:0] dst_mac = pkg_in.eth_dst;


    // pkg 解析
    wire [7:0] tdata = axis_in.tdata;
    wire have_arp  = pkg_in.eth_type == 16'h0806;
    wire cnt2_start = r_cnt[6:0] >= 14;
    reg [3:0] ihl;
    wire [6:0] tp_off = ihl * 4;
    wire proto_valid = cnt2 > 9;
    wire cnt3_start = cnt2 >= tp_off;
    wire have_icmp = pkg_in.ip_proto == 8'h1;
    
    // FIXME: vlan/arp/icmp
    assign error = (cnt2_start & (pkg_in.eth_type != 16'h0806) & (pkg_in.eth_type != 16'h0800)) |
        (proto_valid & (pkg_in.ip_proto != 6) & (pkg_in.ip_proto != 17) & (pkg_in.ip_proto != 1));

    reg [6:0] cnt2, cnt3;
    always @(posedge clk) begin
        if (~rst & (mode == 1'b0) & cnt2_start) begin
            cnt2 <= cnt2 + 1;
        end else begin
            cnt2 <= 0;
        end

        if (~rst & (mode == 1'b0) & proto_valid & ~have_arp & cnt3_start) begin
            cnt3 <= cnt3 + 1;
        end else begin
            cnt3 <= 0;
        end
    end
    
    always @(posedge clk) begin
        /* Debug */
        if (rst | save_done) begin
            pkg_in <= 0;
        end

        if (mode == 1'b0) begin
            // if (r_cnt == 0) begin
                pkg_in.in_port <= {12'b0, axis_in.tid};
            // end

            // TODO: endian
            case (r_cnt[6:0])
                0:  pkg_in.eth_dst[47:40] <= tdata;
                1:  pkg_in.eth_dst[39:32] <= tdata;
                2:  pkg_in.eth_dst[31:24] <= tdata;
                3:  pkg_in.eth_dst[23:16] <= tdata;
                4:  pkg_in.eth_dst[15:8 ] <= tdata;
                5:  pkg_in.eth_dst[7:0  ] <= tdata;
                6 : pkg_in.eth_src[47:40] <= tdata;
                7 : pkg_in.eth_src[39:32] <= tdata;
                8 : pkg_in.eth_src[31:24] <= tdata;
                9 : pkg_in.eth_src[23:16] <= tdata;
                10: pkg_in.eth_src[15:8 ] <= tdata;
                11: pkg_in.eth_src[7:0  ] <= tdata;
                12: pkg_in.eth_type[15:8] <= tdata;
                13: pkg_in.eth_type[7:0]  <= tdata;

                // 14: vlan_buf[15:8] <= tdata;
                // 15: vlan_buf[7:0]  <= tdata;
                // 16: begin
                //     pkg_in.vlan_pcp  <= have_vlan ? {5'b0, vlan_buf[2:0]}  : 0;
                //     pkg_in.vlan_id   <= have_vlan ? {4'b0, vlan_buf[15:4]} : 0;
                // end
            endcase

            if (have_arp) begin
                case (cnt2)
                    6 : pkg_in.ip_proto <= tdata;
                    14: pkg_in.ipv4_src[31:24] <= tdata;
                    15: pkg_in.ipv4_src[23:16] <= tdata;
                    16: pkg_in.ipv4_src[15:8 ] <= tdata;
                    17: pkg_in.ipv4_src[7:0  ] <= tdata;
                    24: pkg_in.ipv4_dst[31:24] <= tdata;
                    25: pkg_in.ipv4_dst[23:16] <= tdata;
                    26: pkg_in.ipv4_dst[15:8 ] <= tdata;
                    27: pkg_in.ipv4_dst[7:0  ] <= tdata;
                endcase
            end else begin
                case (cnt2)
                    0:  ihl             <= tdata[3:0];
                    1:  pkg_in.ip_tos   <= tdata;
                    9:  pkg_in.ip_proto <= tdata;
                    12: pkg_in.ipv4_src[31:24] <= tdata;
                    13: pkg_in.ipv4_src[23:16] <= tdata;
                    14: pkg_in.ipv4_src[15:8 ] <= tdata;
                    15: pkg_in.ipv4_src[7:0  ] <= tdata;
                    16: pkg_in.ipv4_dst[31:24] <= tdata;
                    17: pkg_in.ipv4_dst[23:16] <= tdata;
                    18: pkg_in.ipv4_dst[15:8 ] <= tdata;
                    19: pkg_in.ipv4_dst[7:0  ] <= tdata;
                endcase
            end
            
            if (have_icmp) begin
                case (cnt3)
                    0: begin
                        pkg_in.tp_src[15:8]  <= 0;
                        pkg_in.tp_src[7:0 ]  <= tdata;
                    end
                    1: begin
                        pkg_in.tp_dst[15:8]  <= 0;
                        pkg_in.tp_dst[7:0 ]  <= tdata;
                    end
                endcase
            end else begin
                case (cnt3)
                    0: pkg_in.tp_src[15:8]  <= tdata;
                    1: pkg_in.tp_src[7:0 ]  <= tdata;
                    2: pkg_in.tp_dst[15:8]  <= tdata;
                    3: pkg_in.tp_dst[7:0 ]  <= tdata;
                endcase
            end
        end
    end
    assign parse_done = (cnt3 > 3) | (have_arp & (r_cnt > 27));
    // assign pkg_in_valid = mode == 1'b1;
    assign pkg_in_valid = tlast;
endmodule


module stream_out #(
    parameter BYT_MAC = 2048
) (
    input clk,
    input rst,
    output [31:0] axis_dst,
    axi4stream_if.master axis_out,
    input runnable,
    input [31:0] buffer_addr,
    axi4r_if.master ddr_r,
    input react_valid,
    input act0_t react,
    output fifo_next,
    input pkg_hdr_t pkg_out,
    input [19:0] ddr_out_ind
);
    genvar i;

    wire ddr_done;
    reg [1:0] state;
    always @(posedge clk) begin
        if (rst) begin
            state <= 2'b00;
        end else begin
            case (state)
                2'b00: begin state <= (react_valid)    ? 2'b01 : state; end
                2'b01: begin state <= (ddr_done)       ? 2'b10 : state; end
                2'b10: begin state <= (axis_out.tlast) ? 2'b00 : state; end
                default: begin end
            endcase
        end
    end
    assign fifo_next = axis_out.tlast;

    // test
    reg arvalid;
    always @(posedge clk) begin
        if (rst) begin
            arvalid <= 1'b0;
        end else begin
            case (arvalid)
                1'b0: arvalid <= (state == 2'b00) & react_valid;
                1'b1: arvalid <= ~ddr_r.arready;
            endcase
        end
    end


    // ddr 转 buf
    wire tvalid = ~ddr_done & (cnt < 8);
    reg [3:0] cnt;
    reg [$clog2(BYT_MAC)-1:0] r_cnt;
    always @(posedge clk) begin
        if (rst) begin
            cnt <= 8;
        end else begin
            if (ddr_r.rvalid & ddr_r.rready) begin
                cnt <= 0;
                buff <= ddr_r.rdata;
            end else if (tvalid) begin
                cnt <= cnt + 1;
            end
        end
    end
    always @(posedge clk) begin
        if (rst | ~react_valid) begin
            r_cnt <= 0;
        end else begin
            if (tvalid) begin
                r_cnt <= r_cnt+1;
            end
        end
    end

    /* verilator lint_off WIDTH */
    assign ddr_done = r_cnt >= pkg_out.pkg_bytes;
    /* verilator lint_on WIDTH */
    wire no_extra = pkg_out.pkg_bytes[2:0] == 0;
    assign ddr_r.arvalid = (state == 2'b01) & arvalid;
    assign ddr_r.araddr  = buffer_addr + ddr_out_ind * BYT_MAC;
    assign ddr_r.rready  = cnt == 8;
    assign ddr_r.arid    = 0;
    assign ddr_r.arburst = 2'b01;         // BURST_INCR
    assign ddr_r.arsize  = 3'b011;        // 8 byte
    /* verilator lint_off WIDTH */
    assign ddr_r.arlen   = pkg_out.pkg_bytes / 8 - no_extra;
    /* verilator lint_on WIDTH */


    // axis_out
    reg [63:0] buff;
    wire [7:0][7:0] tbuf;
    wire [7:0] tdata = tbuf[cnt];
    reg  [7:0] tout;

    generate
        // TODO: endian
        for (i=0; i < 8; i++) begin: fill_tbuf
            localparam low = i % 8 * 8;
            assign tbuf[i] = buff[low +: 8];
        end
    endgenerate
    assign axis_dst = react.pkg_dst;
    assign axis_out.tvalid = state == 2'b10;
    assign axis_out.tkeep = 1'b1;
    assign axis_out.tstrb = 1'b1;
    assign axis_out.tdata = bram[ptr_last];
    assign axis_out.tlast  = (state == 2'b10) & (ptr_last+1 == ptr_pre);
    assign axis_out.tdest  = {4{1'bx}};
    assign axis_out.tuser  = 1'bx;


    // stream 汇聚
    reg [$clog2(BYT_MAC)-1:0] ptr_pre, ptr_last;
    reg [BYT_MAC-1:0][7:0] bram;

    always @(posedge clk) begin
        if (rst | ~react_valid) begin
            ptr_pre <= 0;
            ptr_last <= 0;
        end else begin
            if (tvalid) ptr_pre <= ptr_pre+1;
            if (axis_out.tready & (state == 2'b10)) ptr_last <= ptr_last+1;
        end
    end

    always @(posedge clk) begin
        if (tvalid) begin
            bram[ptr_pre] <= tout;
        end
    end

    wire [$clog2(BYT_MAC)-1:0] w_cnt = ptr_pre;
    reg  [$clog2(BYT_MAC)-1:0] offset;

    typedef enum logic [3:0] { 
        IDLE,
        WAIT_ETH_TYPE,
        WAIT_IP_ARP,
        BAD_ETH_TYPE,
        PARSE_ARP,
        PARSE_DONE,
        WAIT_IHL,
        PARSE_IP,
        PARSE_TP,
        PARSE_ICMP,
        BAD_IP_PROTO
    } parse_t;
    
    parse_t parse;
    parse_t next_parse;
    always @(posedge clk) begin
        if (rst) begin
            parse <= IDLE;
        end else begin
            case (parse)
                IDLE: begin
                    parse <= (ddr_done) ? WAIT_ETH_TYPE : parse;
                end
                WAIT_ETH_TYPE: begin
                    if (w_cnt == 12) begin
                        parse <= BAD_ETH_TYPE;
                        if (tdata == 8'h08) parse <= WAIT_IP_ARP;
                    end
                end
                BAD_ETH_TYPE: begin end
                WAIT_IP_ARP: begin
                    parse <= BAD_ETH_TYPE;
                    if (tdata == 8'h06) parse <= PARSE_ARP;
                    if (tdata == 8'h00) parse <= WAIT_IHL;
                end
                PARSE_ARP: begin
                    parse <= (w_cnt == 41) ? PARSE_DONE : parse;
                end
                PARSE_DONE: begin end
                WAIT_IHL: begin
                    if (w_cnt == 14) begin
                        offset <= 14 + tdata[3:0]*4;
                        parse <= PARSE_IP;
                    end 
                end
                PARSE_IP: begin
                    if (w_cnt == 14+9) begin
                        next_parse <= BAD_IP_PROTO;
                        if ((tdata == 6) | (tdata == 17)) next_parse <= PARSE_TP;
                        if ((tdata == 1)) next_parse <= PARSE_ICMP;
                    end
                    parse <= (w_cnt+1 == offset) ? next_parse : parse;
                end
                BAD_IP_PROTO: begin end
                PARSE_ICMP: begin
                    parse <= (w_cnt == offset+1) ? PARSE_DONE : parse;
                end
                PARSE_TP: begin
                    parse <= (w_cnt == offset+3) ? PARSE_DONE : parse;
                end
                default: begin end
            endcase
        end
    end
    
    always_comb begin
        tout = tdata;
        if (react.opcode[`OFPAT_SET_ETH_DST]) begin
            case (w_cnt)
                0:  tout = react.eth_dst[47:40];
                1:  tout = react.eth_dst[39:32];
                2:  tout = react.eth_dst[31:24];
                3:  tout = react.eth_dst[23:16];
                4:  tout = react.eth_dst[15:8 ];
                5:  tout = react.eth_dst[7:0  ];
            endcase
        end
        if (react.opcode[`OFPAT_SET_ETH_SRC]) begin
            case (w_cnt)
                6 : tout = react.eth_src[47:40];
                7 : tout = react.eth_src[39:32];
                8 : tout = react.eth_src[31:24];
                9 : tout = react.eth_src[23:16];
                10: tout = react.eth_src[15:8 ];
                11: tout = react.eth_src[7:0  ];
            endcase
        end
        if (react.opcode[`OFPAT_SET_IP_TOS]) begin
            if (w_cnt == 14+1) tout = react.ip_tos;
        end
        if (react.opcode[`OFPAT_SET_IP_SRC]) begin
            if (parse == PARSE_ARP) begin
                case (w_cnt)
                    14+14: tout = react.ipv4_src[31:24];
                    14+15: tout = react.ipv4_src[23:16];
                    14+16: tout = react.ipv4_src[15:8 ];
                    14+17: tout = react.ipv4_src[7:0  ];
                endcase
            end
            if (parse == PARSE_IP) begin
                case (w_cnt)
                    14+12: tout = react.ipv4_src[31:24];
                    14+13: tout = react.ipv4_src[23:16];
                    14+14: tout = react.ipv4_src[15:8 ];
                    14+15: tout = react.ipv4_src[7:0  ];
                endcase
            end
        end
        if (react.opcode[`OFPAT_SET_IP_DST]) begin
            if (parse == PARSE_ARP) begin
                case (w_cnt)
                    14+24: tout = react.ipv4_dst[31:24];
                    14+25: tout = react.ipv4_dst[23:16];
                    14+26: tout = react.ipv4_dst[15:8 ];
                    14+27: tout = react.ipv4_dst[7:0  ];
                endcase
            end
            if (parse == PARSE_IP) begin
                case (w_cnt)
                    14+16: tout = react.ipv4_dst[31:24];
                    14+17: tout = react.ipv4_dst[23:16];
                    14+18: tout = react.ipv4_dst[15:8 ];
                    14+19: tout = react.ipv4_dst[7:0  ];
                endcase
            end
        end
        if (react.opcode[`OFPAT_SET_TP_SRC]) begin
            if (parse == PARSE_ICMP) begin
                if (w_cnt == offset) tout = react.tp_src[7:0];
            end
            if (parse == PARSE_TP) begin
                if (w_cnt == offset)   tout = react.tp_src[15:8];
                if (w_cnt == offset+1) tout = react.tp_src[7:0];
            end
        end
        if (react.opcode[`OFPAT_SET_TP_DST]) begin
            if (parse == PARSE_ICMP) begin
                if (w_cnt == offset+1) tout = react.tp_dst[7:0];
            end
            if (parse == PARSE_TP) begin
                if (w_cnt == offset+2) tout = react.tp_dst[15:8];
                if (w_cnt == offset+3) tout = react.tp_dst[7:0];
            end
        end
        if ((parse == BAD_ETH_TYPE) | (parse == BAD_IP_PROTO)) begin
            tout = tdata;
        end
    end

    /* Debug */
    wire [47:0] dst_mac = react.eth_dst;
    wire [47:0] src_mac = react.eth_src;
endmodule


module xbar_in (
    input clk,
    input rst,
    axi4stream_if.slave axis_in_1,
    axi4stream_if.slave axis_in_2,
    axi4stream_if.master axis_in
);
    reg [3:0] tid;
    always @(posedge clk) begin
        if (rst) begin
            tid <= 0;
        end else begin
            if (~axis_in.tvalid | axis_in.tlast) begin
                tid <= (tid >= 1) ? 0 : tid+1;
            end
        end
    end

    `AXI4STREAM_MUTEX(axis_in_1, axis_in_2, ~tid[0], axis_in)
    assign axis_in_1.tready = ~tid[0] & axis_in.tready;
    assign axis_in_2.tready =  tid[0] & axis_in.tready;
    assign axis_in.tvalid   = ~tid[0] ? axis_in_1.tvalid : axis_in_2.tvalid;
    assign axis_in.tid = tid + 1;
endmodule

module xbar_mid (
    input clk,
    input rst,
    input [31:0] axis_mid_dst,
    axi4stream_if.slave axis_mid_out,
    axi4stream_if.slave axis_in_ctl,
    output [31:0] axis_dst,
    axi4stream_if.master axis_out
);
    reg [3:0] tid;
    always @(posedge clk) begin
        if (rst) begin
            tid <= 0;
        end else begin
            if (~axis_out.tvalid | axis_out.tlast) begin
                tid <= (tid >= 1) ? 0 : tid+1;
            end
        end
    end

    `AXI4STREAM_MUTEX(axis_mid_out, axis_in_ctl, ~tid[0], axis_out)
    assign axis_mid_out.tready = ~tid[0] & axis_out.tready;
    assign axis_in_ctl.tready  =  tid[0] & axis_out.tready;
    assign axis_out.tvalid     = ~tid[0] ? axis_mid_out.tvalid : axis_in_ctl.tvalid;
    assign axis_out.tid        = ~tid[0] ? axis_mid_out.tid : 0;
    assign axis_dst = ~tid[0] ? axis_mid_dst : 32'b1111_1110;
endmodule

module xbar_out (
    input clk,
    input rst,
    axi4stream_if.slave axis_out,
    input [31:0] axis_dst,
    axi4stream_if.master axis_out_ctl,
    axi4stream_if.master axis_out_1,
    axi4stream_if.master axis_out_2
);
    // FIXME: all_ready
    wire all_ready = (~axis_dst[0] | axis_out_ctl.tready) &
                     (~axis_dst[1] | axis_out_1.tready) &
                     (~axis_dst[2] | axis_out_2.tready);
    assign axis_out.tready = all_ready;
    `AXI4STREAM_CONNECT(axis_out, axis_out_ctl)
    assign axis_out_ctl.tvalid = all_ready & axis_dst[0] & axis_out.tvalid;
    assign axis_out_ctl.tid    = axis_out.tid;
    assign axis_out_ctl.tdest  = 0;
    `AXI4STREAM_CONNECT(axis_out, axis_out_1)
    assign axis_out_1.tvalid = all_ready & axis_dst[1] & axis_out.tvalid;
    assign axis_out_1.tid    = axis_out.tid;
    assign axis_out_1.tdest  = 1;
    `AXI4STREAM_CONNECT(axis_out, axis_out_2)
    assign axis_out_2.tvalid = all_ready & axis_dst[2] & axis_out.tvalid;
    assign axis_out_2.tid    = axis_out.tid;
    assign axis_out_2.tdest  = 2;
endmodule


module OpenflowSwitch100 #(
    parameter CNT = 1024,
    parameter FIFO = 50
) (
    input clk,
    input rst,

    axi4stream_if.slave  axis_in_ctl,
    axi4stream_if.slave  axis_in_1,
    axi4stream_if.slave  axis_in_2,
    axi4stream_if.master axis_out_ctl,
    axi4stream_if.master axis_out_1,
    axi4stream_if.master axis_out_2,

    axi4lite_if.slave  axil_dev,   // 设备读写
    axi4r_if.master    axir_mat,   // 匹配DDR连续读
    axi4lite_if.master axil_inv,   // 失效DDR单写
    axi4_if.master     axi_stat,   // 统计DDR带缓存读写
    axi4r_if.master    axir_act,   // 动作DDR单读
    axi4_if.master     axi_ddr     // 包DDR连续读写
);
    parameter BYT_MAT = 128;
    parameter BYT_ACT = 256;
    parameter BYT_STM = 128;
    parameter BYT_MAC = 2048;

    // 设备寄存器
    // match: 88+pad = 128 byte, action: 16*16 = 256 byte
    wire [31:0] match_addr;
    wire [31:0] buffer_addr;
    wire [31:0] action_addr;
    wire [31:0] status;
    wire [63:0] tick;
    (* keep = "true" *) wire runnable = status[0];
    wire running, error;
    wire mat_error, in_error;
    assign error = mat_error | in_error;
    wire in_run, mat_run, inv_run, stat_run, act_run;
    assign running = in_run | mat_run | inv_run | stat_run | act_run;

    device u_dev(
        .clk(clk),
        .rst(rst),
        .axil_dev(axil_dev),
        .match_addr(match_addr),
        .buffer_addr(buffer_addr),
        .action_addr(action_addr),
        .status(status),
        .tick(tick),
        .running(running),
        .error(error)
    );


    wire [31:0] axis_mid_dst;
    wire [31:0] axis_dst;
    axi4stream_if axis_in();
    axi4stream_if axis_mid_out();
    axi4stream_if axis_out();
    
    xbar_in u_x_in(
        .clk(clk),
        .rst(rst),
        .axis_in_1(axis_in_1),
        .axis_in_2(axis_in_2),
        .axis_in(axis_in.master)
    );

    xbar_mid u_x_mid(
        .clk(clk),
        .rst(rst),
        .axis_mid_dst(axis_mid_dst),
        .axis_mid_out(axis_mid_out.slave),
        .axis_in_ctl(axis_in_ctl),
        .axis_dst(axis_dst),
        .axis_out(axis_out.master)
    );

    xbar_out u_x_out(
        .clk(clk),
        .rst(rst),
        .axis_out(axis_out.slave),
        .axis_dst(axis_dst),
        .axis_out_ctl(axis_out_ctl),
        .axis_out_1(axis_out_1),
        .axis_out_2(axis_out_2)
    );


    axi4w_if ddr_w();
    axi4r_if ddr_r();
    `AXI4W_CONNECT(ddr_w, axi_ddr)
    `AXI4R_CONNECT(ddr_r, axi_ddr)

    (* keep = "true" *) wire pkg_in_valid;
    pkg_hdr_t pkg_in;
    wire [19:0] ddr_in_ind;
    (* keep = "true" *) wire fifo_ready;
    stream_in #(FIFO, BYT_STM, BYT_MAC) u_s_in(
        .clk(clk),
        .rst(rst),
        .axis_in(axis_in.slave),
        .runnable(runnable),
        .buffer_addr(buffer_addr),
        .ddr_w(ddr_w.master),
        .pkg_in_valid(pkg_in_valid),
        .pkg_in(pkg_in),
        .ddr_in_ind(ddr_in_ind),
        .fifo_ready(fifo_ready),
        .running(in_run),
        .error(in_error)
    );

    (* keep = "true" *) wire react_valid;
    act0_t react;
    (* keep = "true" *) wire fifo_next;
    pkg_hdr_t pkg_out;
    wire [19:0] ddr_out_ind;
    stream_out #(BYT_MAC) u_s_out(
        .clk(clk),
        .rst(rst),
        .axis_dst(axis_mid_dst),
        .axis_out(axis_mid_out.master),
        .runnable(runnable),
        .buffer_addr(buffer_addr),
        .ddr_r(ddr_r.master),
        .react_valid(react_valid),
        .react(react),
        .fifo_next(fifo_next),
        .pkg_out(pkg_out),
        .ddr_out_ind(ddr_out_ind)
    );


    (* keep = "true" *) wire buf_valid;
    wire [BYT_MAT*8-1:0] buff;
    wire [19:0] mat_ind;
    burst_match #(CNT, BYT_MAT) u_bst_mat(
        .clk(clk),
        .rst(rst),
        .axir_mat(axir_mat),
        .runnable(runnable),
        .match_addr(match_addr),
        .buf_valid(buf_valid),
        .buff(buff),
        .mat_ind(mat_ind),
        .error(mat_error),
        .running(mat_run)
    );


    reg last_pkg_in_valid;
    always @(posedge clk) begin
        last_pkg_in_valid <= pkg_in_valid;
    end
    wire pkg_in_once = ~last_pkg_in_valid & pkg_in_valid;

    (* keep = "true" *) wire inv_valid;
    wire [19:0] inv_ind;
    (* keep = "true" *) wire fifo_valid;
    wire [19:0] fifo_ind;
    fifo_match #(CNT, FIFO, BYT_MAT) u_fifo(
        .clk(clk),
        .rst(rst),
        .tick(tick),
        .pkg_in_once(pkg_in_once),
        .pkg_in(pkg_in),
        .ddr_in_ind(ddr_in_ind),
        .buf_valid(buf_valid),
        .buff(buff),
        .mat_ind(mat_ind),
        .inv_valid(inv_valid),
        .inv_ind(inv_ind),
        .fifo_ready(fifo_ready),
        .fifo_valid(fifo_valid),
        .fifo_next(fifo_next),
        .fifo_ind(fifo_ind),
        .pkg_out(pkg_out),
        .ddr_out_ind(ddr_out_ind)
    );


    flow_invalid #(BYT_MAT) u_inv(
        .clk(clk),
        .rst(rst),
        .inv_valid(inv_valid),
        .inv_ind(inv_ind),
        .match_addr(match_addr),
        .axil_inv(axil_inv),
        .running(inv_run)
    );


    reg last_fifo_valid;
    always @(posedge clk) begin
        last_fifo_valid <= (fifo_valid & ~fifo_next);
    end
    wire fifo_valid_once = ~last_fifo_valid & (fifo_valid & ~fifo_next);

    flow_update #(BYT_MAT) u_stat(
        .clk(clk),
        .rst(rst),
        .tick(tick),
        .fifo_valid_once(fifo_valid_once),
        .fifo_ind(fifo_ind),
        .match_addr(match_addr),
        .pkg_bytes(pkg_out.pkg_bytes),
        .axi_stat(axi_stat),
        .running(stat_run)
    );

    burst_action #(BYT_ACT) u_bst_act(
        .clk(clk),
        .rst(rst),
        .runnable(runnable),
        .action_addr(action_addr),
        .fifo_valid_once(fifo_valid_once),
        .fifo_next(fifo_next),
        .fifo_ind(fifo_ind),
        .axir_act(axir_act),
        .react_valid(react_valid),
        .react(react),
        .running(act_run)
    );

endmodule


`ifndef DPIC
module top #(
    parameter CNT = 8,
    parameter FIFO = 5
) (
    input clock,
    input reset,

    `AXI4STREAM_SLAVE(axis_in_ctl),
    `AXI4STREAM_SLAVE(axis_in_1),
    `AXI4STREAM_SLAVE(axis_in_2),
    `AXI4STREAM_MASTER(axis_out_ctl),
    `AXI4STREAM_MASTER(axis_out_1),
    `AXI4STREAM_MASTER(axis_out_2),

    `AXI4LITE_SLAVE(axil_dev),
    `AXI4R_MASTER(axir_mat),
    `AXI4LITE_MASTER(axil_inv),
    `AXI4_MASTER(axi_stat),
    `AXI4R_MASTER(axir_act),
    `AXI4_MASTER(axi_ddr)
);

    axi4stream_if  axis_in_ctl();
    axi4stream_if  axis_in_1();
    axi4stream_if  axis_in_2();
    axi4stream_if  axis_out_ctl();
    axi4stream_if  axis_out_1();
    axi4stream_if  axis_out_2();
    axi4lite_if axil_dev();
    axi4r_if    axir_mat();
    axi4lite_if axil_inv();
    axi4_if     axi_stat();
    axi4r_if    axir_act();
    axi4_if     axi_ddr();

    `AXI4STREAM_PACK(axis_in_ctl)
    `AXI4STREAM_PACK(axis_in_1)
    `AXI4STREAM_PACK(axis_in_2)
    `AXI4STREAM_FLAT(axis_out_ctl)
    `AXI4STREAM_FLAT(axis_out_1)
    `AXI4STREAM_FLAT(axis_out_2)
    `AXI4LITE_PACK(axil_dev)
    `AXI4R_FLAT(axir_mat)
    `AXI4LITE_FLAT(axil_inv)
    `AXI4_FLAT(axi_stat)
    `AXI4R_FLAT(axir_act)
    `AXI4_FLAT(axi_ddr)

    OpenflowSwitch100 #(CNT, FIFO) u_os(
        .clk(clock),
        .rst(reset),
        .axis_in_ctl(axis_in_ctl),
        .axis_in_1(axis_in_1),
        .axis_in_2(axis_in_2),
        .axis_out_ctl(axis_out_ctl),
        .axis_out_1(axis_out_1),
        .axis_out_2(axis_out_2),
        .axil_dev(axil_dev),
        .axir_mat(axir_mat),
        .axil_inv(axil_inv),
        .axi_stat(axi_stat),
        .axir_act(axir_act),
        .axi_ddr(axi_ddr)
    );
endmodule

`else

import "DPI-C" function longint axif_read (int raddr, byte rcnt, byte rsize);
import "DPI-C" function void    axif_write(int waddr, longint wdata, byte wmask, byte wcnt, byte wsize);

module axi4f_slave_mem(
    input clk,
    input rst,
    axi4_if.slave axif
);

    reg [31:0] raddr, waddr;
    reg [2:0]  rsize, wsize;
    reg [7:0] arlen;
    reg [1:0] arburst, awburst;
    always @(posedge clk) begin
        if (axif.arvalid) raddr <= axif.araddr;
        if (axif.arvalid) rsize <= axif.arsize;
        if (axif.arvalid) arlen <= axif.arlen;
        if (axif.arvalid) arburst <= axif.arburst;
        if (axif.awvalid) waddr <= axif.awaddr;
        if (axif.awvalid) wsize <= axif.awsize;
        if (axif.awvalid) awburst <= axif.awburst;
    end

    // halt cycle ahead
    reg rvalid, wvalid;
    reg [63:0] rdata;
    reg [7:0]  rcnt, wcnt;
    always @(negedge clk) begin
        if (rst | axif.rlast | (arburst != 2'b01) | ~(axif.arvalid | axif.rvalid)) begin
            rcnt <= 0;
        end else begin
            rcnt <= (axif.rready) ? rcnt+1 : rcnt;
        end
        if (rst | axif.wlast | (awburst != 2'b01) | ~(axif.wvalid)) begin
            wcnt <= 0;
        end else begin
            wcnt <= (axif.bready) ? wcnt+1 : wcnt;
        end
    end
    always @(negedge clk) begin
        if (rst) begin
            rvalid <= 0;
            wvalid <= 0;
        end else begin
            if (axif.rlast | (rvalid == 0)) rvalid <= axif.arvalid;
            if (axif.wlast | (wvalid == 0)) wvalid <= axif.wvalid;
        end
    end
    always @(negedge clk) begin
        if (~rst & (axif.arvalid | axif.rvalid)) rdata <= axif_read(raddr, rcnt, {5'b0, rsize});
        if (~rst & (axif.wvalid)) axif_write(waddr, axif.wdata, axif.wstrb, wcnt, {5'b0, wsize});
    end

    assign axif.arready = 1'b1;
    assign axif.rvalid  = rvalid;
    assign axif.rresp   = 2'b00;
    assign axif.rdata   = rdata;
    assign axif.rlast   = rvalid & (rcnt == arlen+1);

    assign axif.awready = 1'b1;
    assign axif.wready  = 1'b1;
    assign axif.bvalid  = wvalid;
    assign axif.bresp   = 2'b00;
endmodule


import "DPI-C" function void    axis_read (byte no, byte tready, ref byte tdata, ref byte tvalid, ref byte tlast);
import "DPI-C" function void    axis_write(byte no, byte tdata,      byte tlast);

module axi4s_master_in #(
    parameter no = 0
) (
    input clk,
    input rst,
    axi4stream_if.master axis
);
    byte tready = {7'b0, axis.tready};
    byte tdata, tvalid, tlast;

    always @(negedge clk) begin
        if (~rst) axis_read(no, tready, tdata, tvalid, tlast);
    end
    assign axis.tvalid = |tvalid;
    assign axis.tdata = tdata;
    assign axis.tstrb = 1'b1;
    assign axis.tkeep = 1'b1;
    assign axis.tlast = |tlast;
    assign axis.tid   = {4{1'bx}};
    assign axis.tdest = {4{1'bx}};
    assign axis.tuser = 1'bx;
endmodule

module axi4s_slave_out #(
    parameter no = 0
) (
    input clk,
    input rst,
    axi4stream_if.slave axis
);
    byte tvalid = {7'b0, axis.tvalid};
    byte tlast  = {7'b0, axis.tlast};
    always @(posedge clk) begin
        if (~rst & axis.tvalid) begin
            axis_write(no, axis.tdata, tlast);
        end
    end
    assign axis.tready = 1'b1;
endmodule


module axilite_to_axif(
    axi4lite_if axil,
    axi4_if axif
);
    assign axif.awvalid = axil.awvalid;
    assign axif.awaddr  = axil.awaddr;
    assign axif.awid    = 0;
    assign axif.awlen   = 0;
    assign axif.awsize  = 0;
    assign axif.awburst = 0;
    assign axil.awready = axif.awready;

    assign axif.wvalid  = axil.wvalid;
    assign axif.wdata   = {32'h0, axil.wdata};
    assign axif.wstrb   = {4'h0, axil.wstrb};
    assign axif.wlast   = 0;
    assign axil.wready  = axif.wready;

    assign axil.bvalid  = axif.bvalid;
    assign axil.bresp   = axif.bresp;
    assign axif.bready  = axil.bready;

    assign axif.arvalid = axil.arvalid;
    assign axif.araddr  = axil.araddr;
    assign axif.arid    = 0;
    assign axif.arlen   = 0;
    assign axif.arsize  = 0;
    assign axif.arburst = 0;
    assign axil.arready = axif.arready;

    assign axil.rvalid  = axif.rvalid;
    assign axil.rresp   = axif.rresp;
    assign axil.rdata   = axif.rdata[31:0];
    assign axif.rready  = axil.rready;
endmodule

module axir_to_axif(
    axi4r_if axil,
    axi4_if axif
);
    assign axif.awvalid = 0;
    assign axif.awaddr  = 0;
    assign axif.awid    = 0;
    assign axif.awlen   = 0;
    assign axif.awsize  = 0;
    assign axif.awburst = 0;

    assign axif.wvalid  = 0;
    assign axif.wdata   = 0;
    assign axif.wstrb   = 0;
    assign axif.wlast   = 0;

    assign axif.bready  = 0;

    assign axif.arvalid = axil.arvalid;
    assign axif.araddr  = axil.araddr;
    assign axif.arid    = axil.arid;
    assign axif.arlen   = axil.arlen;
    assign axif.arsize  = axil.arsize;
    assign axif.arburst = axil.arburst;
    assign axil.arready = axif.arready;

    assign axil.rvalid  = axif.rvalid;
    assign axil.rresp   = axif.rresp;
    assign axil.rdata   = axif.rdata;
    assign axil.rlast   = axif.rlast;
    assign axil.rid     = axif.rid;
    assign axif.rready  = axil.rready;
endmodule

// module axiw_to_axif(
//     axi4w_if axil,
//     axi4_if axif
// );
//     assign axif.awvalid = axil.awvalid;
//     assign axif.awaddr  = axil.awaddr;
//     assign axif.awid    = axil.awid;
//     assign axif.awlen   = axil.awlen;
//     assign axif.awsize  = axil.awsize;
//     assign axif.awburst = axil.awburst;
//     assign axil.awready = axif.awready;

//     assign axif.wvalid  = axil.wvalid;
//     assign axif.wdata   = axil.wdata;
//     assign axif.wstrb   = axil.wstrb;
//     assign axif.wlast   = axil.wlast;
//     assign axil.wready  = axif.wready;

//     assign axil.bvalid  = axif.bvalid;
//     assign axil.bresp   = axif.bresp;
//     assign axil.bid     = axif.bid;
//     assign axif.bready  = axil.bready;

//     assign axif.arvalid = 0;
//     assign axif.araddr  = 0;
//     assign axif.arid    = 0;
//     assign axif.arlen   = 0;
//     assign axif.arsize  = 0;
//     assign axif.arburst = 0;

//     assign axif.rready  = 0;
// endmodule


module top #(
    parameter CNT = 8,
    parameter FIFO = 5
) (
    input clock,
    input reset
);

    axi4stream_if  axis_in_ctl();
    axi4stream_if  axis_in_1();
    axi4stream_if  axis_in_2();
    axi4stream_if  axis_out_ctl();
    axi4stream_if  axis_out_1();
    axi4stream_if  axis_out_2();

    axi4lite_if axil_dev();
    axi4r_if    axir_mat();
    axi4lite_if axil_inv();
    axi4r_if    axir_act();
    axi4_if     axi_ddr();

    axi4_if axi_mat();
    axi4_if axi_inv();
    axi4_if axi_stat();
    axi4_if axi_act();

    axir_to_axif    u_aa0(axir_mat, axi_mat  );
    axilite_to_axif u_aa1(axil_inv, axi_inv  );
    axir_to_axif    u_aa2(axir_act, axi_act  );

    axi4s_master_in #(0) u_i0 (clock, reset, axis_in_ctl);
    axi4s_master_in #(1) u_i1 (clock, reset, axis_in_1 );
    axi4s_master_in #(2) u_i2 (clock, reset, axis_in_2 );
    axi4s_slave_out #(0) u_o0 (clock, reset, axis_out_ctl);
    axi4s_slave_out #(1) u_o1 (clock, reset, axis_out_1);
    axi4s_slave_out #(2) u_o2 (clock, reset, axis_out_2);

    axi4f_slave_mem u_mat (clock, reset, axi_mat );
    axi4f_slave_mem u_inv (clock, reset, axi_inv );
    axi4f_slave_mem u_stat(clock, reset, axi_stat);
    axi4f_slave_mem u_act (clock, reset, axi_act );
    axi4f_slave_mem u_ddr (clock, reset, axi_ddr );


    OpenflowSwitch100 #(CNT, FIFO) u_os(
        .clk(clock),
        .rst(reset),
        .axis_in_ctl,
        .axis_in_1,
        .axis_in_2,
        .axis_out_ctl,
        .axis_out_1,
        .axis_out_2,
        .axil_dev,
        .axir_mat,
        .axil_inv,
        .axi_stat,
        .axir_act,
        .axi_ddr
    );
endmodule

`endif
