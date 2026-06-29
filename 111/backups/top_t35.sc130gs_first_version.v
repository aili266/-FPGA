`timescale 1ns / 1ps

module top_t35 (
    input           AxiPllClkIn,
    input           DdrPllClkIn,
    input           Axi0Clk,

    output          hdmi_resetn_o,
    output          mipi_resetn_o,

    input           mipi_clkcal_i,
    input           mipi_clkesc_i,
    input           mipi_pixclk_i,
    input           hdmi_clk1x_i,
    input           hdmi_clk2x_i,
    input           hdmi_clk5x_i,

    input           tx_slowclk,
    input           tx_fastclk,
    input  [1:0]    PllLocked,
    input           hdmi_lock_i,
    input           mipi_lock_i,

    output          DdrCtrl_RSTN,
    output          DdrCtrl_CFG_SEQ_RST,
    output          DdrCtrl_CFG_SEQ_START,

    output [7:0]    DdrCtrl_AID_0,
    output [31:0]   DdrCtrl_AADDR_0,
    output [7:0]    DdrCtrl_ALEN_0,
    output [2:0]    DdrCtrl_ASIZE_0,
    output [1:0]    DdrCtrl_ABURST_0,
    output [1:0]    DdrCtrl_ALOCK_0,
    output          DdrCtrl_AVALID_0,
    input           DdrCtrl_AREADY_0,
    output          DdrCtrl_ATYPE_0,

    output [7:0]    DdrCtrl_WID_0,
    output [127:0]  DdrCtrl_WDATA_0,
    output [15:0]   DdrCtrl_WSTRB_0,
    output          DdrCtrl_WLAST_0,
    output          DdrCtrl_WVALID_0,
    input           DdrCtrl_WREADY_0,

    input  [7:0]    DdrCtrl_RID_0,
    input  [127:0]  DdrCtrl_RDATA_0,
    input           DdrCtrl_RLAST_0,
    input           DdrCtrl_RVALID_0,
    output          DdrCtrl_RREADY_0,
    input  [1:0]    DdrCtrl_RRESP_0,

    input  [7:0]    DdrCtrl_BID_0,
    input           DdrCtrl_BVALID_0,
    output          DdrCtrl_BREADY_0,

    output [7:0]    led_data,

    output [4:0]    hdmi_tx0_o,
    output [4:0]    hdmi_tx1_o,
    output [4:0]    hdmi_tx2_o,
    output [4:0]    hdmi_txc_o,

    input           mipi0_scl_i,
    output          mipi0_scl_o,
    output          mipi0_scl_oe,

    input           mipi0_sda_i,
    output          mipi0_sda_o,
    output          mipi0_sda_oe,

    input           mipi1_scl_i,
    output          mipi1_scl_o,
    output          mipi1_scl_oe,

    input           mipi1_sda_i,
    output          mipi1_sda_o,
    output          mipi1_sda_oe,

    output [1:0]    mipi_trig_o,

    output          mipi_rx_0_RSTN_o,
    output          mipi_rx_0_DPHY_RSTN_o,
    output [3:0]    mipi_rx_0_VC_ENA_o,
    output [1:0]    mipi_rx_0_LANES_o,

    output          mipi_rx_1_RSTN_o,
    output          mipi_rx_1_DPHY_RSTN_o,
    output [3:0]    mipi_rx_1_VC_ENA_o,
    output [1:0]    mipi_rx_1_LANES_o,

    input  [1:0]    mipi_rx_0_VC_i,
    input  [3:0]    mipi_rx_0_VSYNC_i,
    input  [3:0]    mipi_rx_0_HSYNC_i,
    input  [63:0]   mipi_rx_0_DATA_i,
    input  [3:0]    mipi_rx_0_CNT_i,
    input  [5:0]    mipi_rx_0_TYPE_i,
    input           mipi_rx_0_VALID_i,

    input  [1:0]    mipi_rx_1_VC_i,
    input  [3:0]    mipi_rx_1_VSYNC_i,
    input  [3:0]    mipi_rx_1_HSYNC_i,
    input  [63:0]   mipi_rx_1_DATA_i,
    input  [3:0]    mipi_rx_1_CNT_i,
    input  [5:0]    mipi_rx_1_TYPE_i,
    input           mipi_rx_1_VALID_i,

    input  [3:0]    mipi_rx_0_ULPS,
    input           mipi_rx_0_ULPS_CLK,
    output          mipi_rx_0_CLEAR,
    input  [17:0]   mipi_rx_0_ERROR,

    input  [3:0]    mipi_rx_1_ULPS,
    input           mipi_rx_1_ULPS_CLK,
    output          mipi_rx_1_CLEAR,
    input  [17:0]   mipi_rx_1_ERROR
);

localparam CLOCK_MAIN = 100_000000;
localparam [1:0] MIPI_1LANE = 2'd0;
localparam ENABLE_COLOR_DETECT = 1'b0;

localparam [2:0] COLOR_UNKNOWN = 3'd0;
localparam [2:0] SHAPE_CUBE = 3'd1;

wire user_pll_locked = PllLocked[1];

reg [7:0] power_on_reset_cnt = 8'd0;
reg [2:0] reset_shift_reg = 3'd0;

always @(posedge Axi0Clk or negedge user_pll_locked) begin
    if (!user_pll_locked) begin
        power_on_reset_cnt <= 8'd0;
        reset_shift_reg <= 3'd0;
    end else begin
        if (!(&power_on_reset_cnt))
            power_on_reset_cnt <= power_on_reset_cnt + 8'd1;
        reset_shift_reg <= {reset_shift_reg[1:0], &power_on_reset_cnt};
    end
end

wire user_rst_n = reset_shift_reg[2];

assign hdmi_resetn_o = user_pll_locked;
assign mipi_resetn_o = user_pll_locked;

assign hdmi_tx0_o = 5'd0;
assign hdmi_tx1_o = 5'd0;
assign hdmi_tx2_o = 5'd0;
assign hdmi_txc_o = 5'd0;

assign DdrCtrl_RSTN = 1'b0;
assign DdrCtrl_CFG_SEQ_RST = 1'b1;
assign DdrCtrl_CFG_SEQ_START = 1'b0;
assign DdrCtrl_AID_0 = 8'd0;
assign DdrCtrl_AADDR_0 = 32'd0;
assign DdrCtrl_ALEN_0 = 8'd0;
assign DdrCtrl_ASIZE_0 = 3'd0;
assign DdrCtrl_ABURST_0 = 2'd0;
assign DdrCtrl_ALOCK_0 = 2'd0;
assign DdrCtrl_AVALID_0 = 1'b0;
assign DdrCtrl_ATYPE_0 = 1'b0;
assign DdrCtrl_WID_0 = 8'd0;
assign DdrCtrl_WDATA_0 = 128'd0;
assign DdrCtrl_WSTRB_0 = 16'd0;
assign DdrCtrl_WLAST_0 = 1'b0;
assign DdrCtrl_WVALID_0 = 1'b0;
assign DdrCtrl_RREADY_0 = 1'b0;
assign DdrCtrl_BREADY_0 = 1'b0;

assign mipi_trig_o = 2'b11;
assign mipi_rx_0_VC_ENA_o = 4'b1111;
assign mipi_rx_0_LANES_o = MIPI_1LANE;
assign mipi_rx_1_VC_ENA_o = 4'b1111;
assign mipi_rx_1_LANES_o = MIPI_1LANE;
assign mipi_rx_0_CLEAR = 1'b0;
assign mipi_rx_1_CLEAR = 1'b0;

assign mipi1_scl_o = 1'b1;
assign mipi1_scl_oe = 1'b0;
assign mipi1_sda_o = 1'b1;
assign mipi1_sda_oe = 1'b0;

wire [7:0] i2c_config_index;
wire [23:0] i2c_config_data;
wire [7:0] i2c_config_size;
wire i2c_config_done;

i2c_timing_ctrl_reg16_dat8_wronly #(
    .CLK_FREQ(CLOCK_MAIN),
    .I2C_FREQ(10_000)
) u_i2c_timing_ctrl_reg16_dat8_wronly (
    .clk(Axi0Clk),
    .rst_n(user_rst_n),
    .i2c_sclk(mipi0_scl_o),
    .i2c_sdat_IN(mipi0_sda_i),
    .i2c_sdat_OUT(mipi0_sda_o),
    .i2c_sdat_OE(mipi0_sda_oe),
    .i2c_config_size(i2c_config_size),
    .i2c_config_index(i2c_config_index),
    .i2c_config_data({8'h60, i2c_config_data}),
    .i2c_config_done(i2c_config_done)
);

assign mipi0_scl_oe = 1'b1;

I2C_SC130GS_12801024_1Lanes_Config u_i2c_sc130gs_config (
    .LUT_INDEX(i2c_config_index),
    .LUT_DATA(i2c_config_data),
    .LUT_SIZE(i2c_config_size)
);

reg [1:0] i2c_done_mipi = 2'b00;
always @(posedge mipi_pixclk_i or negedge mipi_lock_i) begin
    if (!mipi_lock_i)
        i2c_done_mipi <= 2'b00;
    else
        i2c_done_mipi <= {i2c_done_mipi[0], i2c_config_done};
end

wire mipi_rst_n = mipi_lock_i & i2c_done_mipi[1];

assign mipi_rx_0_RSTN_o = mipi_rst_n;
assign mipi_rx_0_DPHY_RSTN_o = mipi_rst_n;
assign mipi_rx_1_RSTN_o = 1'b0;
assign mipi_rx_1_DPHY_RSTN_o = 1'b0;

wire mipi0_frame_valid = mipi_rx_0_VSYNC_i[0];
wire mipi0_line_valid = mipi_rx_0_HSYNC_i[0];
wire mipi0_word_valid = mipi_rst_n & mipi0_line_valid & mipi_rx_0_VALID_i;
wire [63:0] mipi0_word_data = {
    mipi_rx_0_DATA_i[7:0],
    mipi_rx_0_DATA_i[15:8],
    mipi_rx_0_DATA_i[23:16],
    mipi_rx_0_DATA_i[31:24],
    mipi_rx_0_DATA_i[39:32],
    mipi_rx_0_DATA_i[47:40],
    mipi_rx_0_DATA_i[55:48],
    mipi_rx_0_DATA_i[63:56]
};

function [47:0] pack_gray_pair;
    input [7:0] g0;
    input [7:0] g1;
begin
    pack_gray_pair = {g0, g0, g0, g1, g1, g1};
end
endfunction

function [47:0] expand_raw8_word;
    input [63:0] raw_word;
    input [2:0] step;
    reg [7:0] b0;
    reg [7:0] b1;
    reg [7:0] b2;
    reg [7:0] b3;
    reg [7:0] b4;
    reg [7:0] b5;
    reg [7:0] b6;
    reg [7:0] b7;
begin
    b0 = raw_word[63:56];
    b1 = raw_word[55:48];
    b2 = raw_word[47:40];
    b3 = raw_word[39:32];
    b4 = raw_word[31:24];
    b5 = raw_word[23:16];
    b6 = raw_word[15:8];
    b7 = raw_word[7:0];
    case (step)
        3'd0: expand_raw8_word = pack_gray_pair(b0, b0);
        3'd1: expand_raw8_word = pack_gray_pair(b1, b2);
        3'd2: expand_raw8_word = pack_gray_pair(b2, b3);
        3'd3: expand_raw8_word = pack_gray_pair(b4, b4);
        3'd4: expand_raw8_word = pack_gray_pair(b5, b6);
        default: expand_raw8_word = pack_gray_pair(b6, b7);
    endcase
end
endfunction

reg [63:0] expand_word = 64'd0;
reg [2:0] expand_step = 3'd0;
reg expand_busy = 1'b0;
reg expand_overrun = 1'b0;
reg rgb_de_r = 1'b0;
reg [47:0] rgb_datax2_r = 48'd0;
reg rgb_vs_r = 1'b0;
reg mipi_frame_valid_d = 1'b0;
reg mipi_frame_toggle = 1'b0;

always @(posedge mipi_pixclk_i or negedge mipi_rst_n) begin
    if (!mipi_rst_n) begin
        expand_word <= 64'd0;
        expand_step <= 3'd0;
        expand_busy <= 1'b0;
        expand_overrun <= 1'b0;
        rgb_de_r <= 1'b0;
        rgb_datax2_r <= 48'd0;
        rgb_vs_r <= 1'b0;
        mipi_frame_valid_d <= 1'b0;
        mipi_frame_toggle <= 1'b0;
    end else begin
        rgb_vs_r <= mipi0_frame_valid;
        mipi_frame_valid_d <= mipi0_frame_valid;
        if (!mipi_frame_valid_d && mipi0_frame_valid)
            mipi_frame_toggle <= ~mipi_frame_toggle;

        if (mipi0_word_valid && expand_busy)
            expand_overrun <= 1'b1;

        if (!expand_busy) begin
            if (mipi0_word_valid) begin
                expand_word <= mipi0_word_data;
                expand_step <= 3'd1;
                expand_busy <= 1'b1;
                rgb_de_r <= 1'b1;
                rgb_datax2_r <= expand_raw8_word(mipi0_word_data, 3'd0);
            end else begin
                rgb_de_r <= 1'b0;
                rgb_datax2_r <= 48'd0;
            end
        end else begin
            rgb_de_r <= 1'b1;
            rgb_datax2_r <= expand_raw8_word(expand_word, expand_step);
            if (expand_step == 3'd5) begin
                expand_step <= 3'd0;
                expand_busy <= 1'b0;
            end else begin
                expand_step <= expand_step + 3'd1;
            end
        end

        if (!mipi0_frame_valid)
            expand_busy <= 1'b0;
    end
end

reg [9:0] shape_button_cnt = 10'd0;
always @(posedge mipi_pixclk_i or negedge mipi_rst_n) begin
    if (!mipi_rst_n)
        shape_button_cnt <= 10'd0;
    else if (shape_button_cnt != 10'h3FF)
        shape_button_cnt <= shape_button_cnt + 10'd1;
end

wire shape_page_button_auto =
    (shape_button_cnt >= 10'd64) && (shape_button_cnt < 10'd160);

wire [2:0] color_id_cam;
wire color_valid_cam;
wire [2:0] fast_color_id_cam;
wire fast_color_valid_cam;

generate
if (ENABLE_COLOR_DETECT) begin : g_color_detect
    color_detector #(
        .HACT(12'd1920),
        .VACT(11'd1024),
        .COLOR_ROI_Y_START(11'd455),
        .COLOR_ROI_Y_END(11'd569),
        .FAST_COLOR_ROI_Y_START(11'd455),
        .FAST_COLOR_ROI_Y_END(11'd569),
        .FAST_LOCK_LINE_STREAK_NEW(4'd4),
        .FAST_LOCK_LINE_STREAK_SWITCH(4'd4)
    ) u_color_detector (
        .clk(mipi_pixclk_i),
        .rst_n(mipi_rst_n),
        .rgb_vs(rgb_vs_r),
        .rgb_de(rgb_de_r),
        .rgb_datax2(rgb_datax2_r),
        .timer_running(1'b0),
        .fast_timer_running(1'b0),
        .color_id(color_id_cam),
        .color_valid(color_valid_cam),
        .fast_color_id_out(fast_color_id_cam),
        .fast_color_valid_out(fast_color_valid_cam),
        .color_timer_start_pulse(),
        .color_timer_stop_pulse(),
        .color_timer_cancel_pulse(),
        .fast_color_timer_start_pulse(),
        .fast_color_timer_stop_pulse(),
        .fast_color_timer_cancel_pulse()
    );
end else begin : g_no_color_detect
    assign color_id_cam = COLOR_UNKNOWN;
    assign color_valid_cam = 1'b0;
    assign fast_color_id_cam = COLOR_UNKNOWN;
    assign fast_color_valid_cam = 1'b0;
end
endgenerate

wire [2:0] shape_id_cam;
wire shape_valid_cam;
wire [2:0] shape_display_id_cam;
wire shape_display_valid_cam;
wire shape_page_cam;
wire shape_bg_learn_cam;
wire shape_bg_valid_cam;

shape_recognition_core #(
    .VACT(12'd1024),
    .SHAPE_ROI_Y_START(11'd201),
    .SHAPE_ROI_Y_END(11'd823),
    .SHAPE_PAGE_BTN_DEBOUNCE_MAX(21'd32),
    .ENABLE_HDMI_PREVIEW(1'b0)
) u_shape_recognition_core (
    .clk(mipi_pixclk_i),
    .rst_n(mipi_rst_n),
    .rgb_vs(rgb_vs_r),
    .rgb_de(rgb_de_r),
    .rgb_datax2(rgb_datax2_r),
    .shape_page_button(shape_page_button_auto),
    .shape_timer_running(1'b0),
    .hdmi_clk(mipi_pixclk_i),
    .hdmi_rst_n(mipi_rst_n),
    .shape_preview_ui_active(1'b0),
    .shape_preview_ui_x(8'd0),
    .shape_preview_ui_y(7'd0),
    .shape_id_cam(shape_id_cam),
    .shape_valid_cam(shape_valid_cam),
    .shape_display_id_cam(shape_display_id_cam),
    .shape_display_valid_cam(shape_display_valid_cam),
    .shape_page_cam(shape_page_cam),
    .shape_bg_learn_cam(shape_bg_learn_cam),
    .shape_bg_valid_cam(shape_bg_valid_cam),
    .shape_timer_start_cam_pulse(),
    .shape_timer_stop_cam_pulse(),
    .shape_timer_cancel_cam_pulse(),
    .shape_preview_gray_hdmi(),
    .shape_contour_left_hdmi(),
    .shape_contour_right_hdmi(),
    .shape_fg_contour_left_hdmi(),
    .shape_fg_contour_right_hdmi(),
    .shape_bg_valid_hdmi(),
    .shape_bg_learn_hdmi()
);

wire color_sort_match_cam = fast_color_valid_cam && (fast_color_id_cam != COLOR_UNKNOWN);
wire shape_cube_match_cam = shape_valid_cam && (shape_id_cam == SHAPE_CUBE);
wire shape_reject_match_cam = shape_valid_cam && (shape_id_cam != SHAPE_CUBE);
wire competition_sort_enable_cam = color_sort_match_cam && shape_cube_match_cam;

assign led_data = {
    expand_overrun | mipi_frame_toggle,
    i2c_config_done,
    shape_bg_valid_cam,
    shape_reject_match_cam,
    competition_sort_enable_cam,
    shape_cube_match_cam,
    color_sort_match_cam,
    rgb_de_r
};

endmodule
