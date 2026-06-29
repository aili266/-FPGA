`ifndef SYSTEM_STARTUP_CTRL_V
`define SYSTEM_STARTUP_CTRL_V

module system_startup_ctrl (
    input  wire clk,
    input  wire manual_enable,
    input  wire sys_pll_lock,
    input  wire ddr_pll_lock,
    input  wire pll_byteclk_locked,
    input  wire fb_pll_locked,
    input  wire ddr_cfg_done,

    output wire sys_pll_rstn,
    output wire ddr_pll_rstn,
    output wire fb_pll_rstn,
    output wire pll_byteclk_rstn,
    output wire arst_n,
    output wire sys_rst_n,
    output wire ddr_cfg_ok,
    output wire ddr_cfg_start,
    output wire ddr_cfg_rst,
    output wire ddr_cfg_sel,
    output wire axi0_aresetn,
    output wire axi1_aresetn
);

localparam [1:0] IDLE      = 2'b00;
localparam [1:0] CFG_START = 2'b01;
localparam [1:0] CFG_DONE  = 2'b11;

reg [1:0] cfg_st;
reg [1:0] cfg_next;
reg [7:0] cfg_count;
reg [20:0] rst_cnt = 21'd0;

assign sys_pll_rstn     = manual_enable;
assign ddr_pll_rstn     = manual_enable;
assign fb_pll_rstn      = manual_enable;
assign pll_byteclk_rstn = manual_enable;

assign arst_n = sys_pll_lock & ddr_pll_lock & pll_byteclk_locked & fb_pll_locked;

always @(posedge clk or negedge arst_n) begin
    if (!arst_n)
        rst_cnt <= 21'd0;
    else
        rst_cnt <= rst_cnt[20] ? rst_cnt : rst_cnt + 1'b1;
end

wire startup_rst_n = rst_cnt[20];

always @(posedge clk or negedge startup_rst_n) begin
    if (!startup_rst_n) begin
        cfg_st <= IDLE;
        cfg_count <= 8'd0;
    end else begin
        cfg_st <= cfg_next;

        if (cfg_st == IDLE)
            cfg_count <= cfg_count + 1'b1;
        else
            cfg_count <= 8'd0;
    end
end

always @(*) begin
    cfg_next = cfg_st;
    case (cfg_st)
    IDLE:
        if (cfg_count == 8'hff)
            cfg_next = CFG_START;
        else
            cfg_next = IDLE;
    CFG_START:
        if (ddr_cfg_done)
            cfg_next = CFG_DONE;
        else
            cfg_next = CFG_START;
    CFG_DONE:
        cfg_next = CFG_DONE;
    default:
        cfg_next = IDLE;
    endcase
end

assign ddr_cfg_start = (cfg_st != IDLE);
assign ddr_cfg_ok    = (cfg_st == CFG_DONE);
assign ddr_cfg_rst   = (cfg_st == IDLE);
assign ddr_cfg_sel   = 1'b0;
assign axi0_aresetn  = ddr_cfg_ok;
assign axi1_aresetn  = ddr_cfg_ok;
assign sys_rst_n     = ddr_cfg_ok;

endmodule

`endif
