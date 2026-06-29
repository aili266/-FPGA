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

    // HDMI TMDS out via the board's serialization=5 LVDS (hdmi_tx*_o[4:0]).
    // Pins/serializer already match the VF-T35F324 board in mem_test.peri.xml
    // (GPIOB_TX08/07/06/09). The 10-bit TMDS from hdmi_result_ui is geared
    // down 10->5 on hdmi_clk2x exactly like the official SC2210-HDMI reference.
    output [4:0]    hdmi_tx0_o,
    output [4:0]    hdmi_tx1_o,
    output [4:0]    hdmi_tx2_o,
    output [4:0]    hdmi_txc_o,

    // Reserved 1 Mbps UART (8N1) for later host / robot-arm comms.
    output          uart_txd,
    input           uart_rxd,

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
localparam [1:0] MIPI_4LANE = 2'd3;
localparam ENABLE_COLOR_DETECT = 1'b1;

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
assign mipi_rx_0_LANES_o = MIPI_4LANE;
assign mipi_rx_1_VC_ENA_o = 4'b0000;  // RX1 unused (single SC2210 on MIPI0)
assign mipi_rx_1_LANES_o = 2'd0;
assign mipi_rx_0_CLEAR = 1'b0;
assign mipi_rx_1_CLEAR = 1'b0;

assign mipi1_scl_o = 1'b1;
assign mipi1_scl_oe = 1'b0;
assign mipi1_sda_o = 1'b1;
assign mipi1_sda_oe = 1'b0;

wire [8:0] i2c_config_index;
wire [23:0] i2c_config_data;
wire [8:0] i2c_config_size;
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

I2C_SC2210_19201080_4Lanes_Config u_i2c_sc2210_config (
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
// MIPI RX1 is unused (single camera on MIPI0) -> hold it in reset.
assign mipi_rx_1_RSTN_o = 1'b0;
assign mipi_rx_1_DPHY_RSTN_o = 1'b0;

wire rgb_vs_r;
wire rgb_de_r;
wire [47:0] rgb_datax2_r;
wire [7:0] shape_gray0_r = rgb_datax2_r[39:32];
wire [7:0] shape_gray1_r = rgb_datax2_r[15:8];
wire [47:0] shape_rgb_datax2_r = {
    shape_gray0_r, shape_gray0_r, shape_gray0_r,
    shape_gray1_r, shape_gray1_r, shape_gray1_r
};
wire mipi0_frame_valid;
wire raw_pixel_de;
wire mipi_frame_toggle;
wire raw_fifo_prog_full;
wire raw_fifo_full;
wire raw_fifo_overflow;
wire raw_fifo_underflow;

sc2210_raw8_to_rgbx2 #(
    .IMG_HDISP(14'd1920),
    .IMG_VDISP(14'd1080),
    .BAYER_MIRROR(2'b00)
) u_sc2210_raw8_to_rgbx2 (
    .clk(mipi_pixclk_i),
    .rst_n(mipi_rst_n),
    .mipi_hsync(mipi_rx_0_HSYNC_i[0]),
    .mipi_valid(mipi_rx_0_VALID_i),
    .mipi_data(mipi_rx_0_DATA_i),
    .rgb_vs(rgb_vs_r),
    .rgb_de(rgb_de_r),
    .rgb_datax2(rgb_datax2_r),
    .raw_frame_valid(mipi0_frame_valid),
    .raw_pixel_de(raw_pixel_de),
    .frame_toggle(mipi_frame_toggle),
    .fifo_prog_full(raw_fifo_prog_full),
    .fifo_full(raw_fifo_full),
    .fifo_overflow(raw_fifo_overflow),
    .fifo_underflow(raw_fifo_underflow)
);

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
        .VACT(11'd1080),
        .COLOR_ROI_X_START(12'd880),
        .COLOR_ROI_X_END(12'd1040),
        .COLOR_ROI_Y_START(11'd480),
        .COLOR_ROI_Y_END(11'd600),
        .FAST_COLOR_ROI_X_START(12'd880),
        .FAST_COLOR_ROI_X_END(12'd1040),
        .FAST_COLOR_ROI_Y_START(11'd480),
        .FAST_COLOR_ROI_Y_END(11'd600),
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
    .VACT(12'd1080),
    .SHAPE_ROI_X_START(12'd492),
    .SHAPE_ROI_X_END(12'd1428),
    .SHAPE_ROI_Y_START(11'd212),
    .SHAPE_ROI_Y_END(11'd868),
    .SHAPE_PAGE_BTN_DEBOUNCE_MAX(21'd32),
    .ENABLE_HDMI_PREVIEW(1'b0)
) u_shape_recognition_core (
    .clk(mipi_pixclk_i),
    .rst_n(mipi_rst_n),
    .rgb_vs(rgb_vs_r),
    .rgb_de(rgb_de_r),
    .rgb_datax2(shape_rgb_datax2_r),
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

wire color_sort_match_cam = color_valid_cam && (color_id_cam != COLOR_UNKNOWN);
wire shape_cube_match_cam = shape_valid_cam && (shape_id_cam == SHAPE_CUBE);
wire shape_reject_match_cam = shape_valid_cam && (shape_id_cam != SHAPE_CUBE);
wire competition_sort_enable_cam = color_sort_match_cam && shape_cube_match_cam;

assign led_data = {
    raw_fifo_overflow | raw_fifo_underflow | raw_fifo_full | mipi_frame_toggle,
    i2c_config_done,
    shape_bg_valid_cam,
    shape_reject_match_cam,
    competition_sort_enable_cam,
    shape_cube_match_cam,
    color_sort_match_cam,
    rgb_de_r | raw_pixel_de
};

// ============================================================================
// HDMI result-UI display path (board-independent core)
//
// Runs entirely on the pixel clock hdmi_clk1x_i. hdmi_result_ui renders the
// 640x480 color/shape result UI and emits 4x 10-bit TMDS words, which feed the
// Trion LVDS hard serializers (serializer + pin config in mem_test.peri.xml,
// finalized against the VF-T35F324 HDK in Track B).
//
// NOTE: hdmi_result_ui drives true 640x480@60 timing (needs ~25.175 MHz on
// hdmi_clk1x_i). HdmiPLL must be re-tuned to 25.175 MHz (task A2) before a
// monitor will lock; the RTL below is correct independent of that frequency.
//
// Recognition results are produced in the mipi_pixclk_i domain; cross them into
// the hdmi_clk1x_i domain with simple 2-FF synchronizers (slow-changing display
// status, glitch-tolerant), mirroring the WZZY top.v meta/sync pattern.
// shape_page_cam is passed through and re-synchronized inside ui_mode_latch.
// ============================================================================
(* async_reg = "true" *) reg [2:0] color_id_meta         = COLOR_UNKNOWN;
(* async_reg = "true" *) reg [2:0] color_id_hdmi         = COLOR_UNKNOWN;
(* async_reg = "true" *) reg       color_valid_meta      = 1'b0;
(* async_reg = "true" *) reg       color_valid_hdmi      = 1'b0;
(* async_reg = "true" *) reg [2:0] shape_disp_meta       = COLOR_UNKNOWN;
(* async_reg = "true" *) reg [2:0] shape_display_id_hdmi = COLOR_UNKNOWN;

always @(posedge hdmi_clk1x_i) begin
    color_id_meta         <= color_id_cam;
    color_id_hdmi         <= color_id_meta;
    color_valid_meta      <= color_valid_cam;
    color_valid_hdmi      <= color_valid_meta;
    shape_disp_meta       <= shape_display_id_cam;
    shape_display_id_hdmi <= shape_disp_meta;
end

wire [9:0] w_hdmi_txd0, w_hdmi_txd1, w_hdmi_txd2, w_hdmi_txc;

hdmi_result_ui u_hdmi_result_ui (
    .hdmi_tx_slow_clk                     (hdmi_clk1x_i),
    .sys_rst_n                            (1'b1),
    .hdmi_pll_locked                      (hdmi_lock_i),
    .shape_page_cam                       (shape_page_cam),
    .color_id_hdmi                        (color_id_hdmi),
    .color_valid_hdmi                     (color_valid_hdmi),
    .shape_display_id_hdmi                (shape_display_id_hdmi),
    // No timer/latency subsystem in this top yet -> tie display inputs off.
    .timer_running_hdmi                   (1'b0),
    .timer_result_valid_hdmi              (1'b0),
    .timer_display_active_hdmi            (1'b0),
    .timer_display_us_hdmi                (24'd0),
    .timer_display_us_hdmi_clamped        (24'd0),
    .timer_display_hold_us_hdmi           (24'd0),
    .shape_latency_display_valid_hdmi     (1'b0),
    .shape_latency_display_us_hdmi        (24'd0),
    .shape_latency_display_us_hdmi_clamped(24'd0),
    .shape_preview_ui_active              (),
    .shape_preview_ui_x                   (),
    .shape_preview_ui_y                   (),
    // 10-bit TMDS (channel0=blue, 1=green, 2=red, clk) -> board gearbox below.
    .tmds_data0_TX_DATA                   (w_hdmi_txd0),
    .tmds_data1_TX_DATA                   (w_hdmi_txd1),
    .tmds_data2_TX_DATA                   (w_hdmi_txd2),
    .tmds_clk_TX_DATA                     (w_hdmi_txc),
    .tmds_data0_TX_OE                     (),
    .tmds_data1_TX_OE                     (),
    .tmds_data2_TX_OE                     (),
    .tmds_clk_TX_OE                       (),
    .tmds_data0_TX_RST                    (),
    .tmds_data1_TX_RST                    (),
    .tmds_data2_TX_RST                    (),
    .tmds_clk_TX_RST                      ()
);

// 10:5 TMDS gearbox feeding the serialization=5 LVDS, copied verbatim from the
// official VF-T35F324 SC2210-HDMI reference (rgb2dvi output stage). Runs on the
// 2x pixel clock: load the full 10-bit word, then shift down 5 for the 2nd half.
reg       rc_hdmi_tx   = 1'b0;
reg [9:0] r_hdmi_txc_o = 10'd0;
reg [9:0] r_hdmi_tx0_o = 10'd0;
reg [9:0] r_hdmi_tx1_o = 10'd0;
reg [9:0] r_hdmi_tx2_o = 10'd0;

always @(posedge hdmi_clk2x_i) begin
    rc_hdmi_tx <= ~rc_hdmi_tx;
    if (rc_hdmi_tx) begin
        r_hdmi_txc_o <= w_hdmi_txc;
        r_hdmi_tx0_o <= w_hdmi_txd0;
        r_hdmi_tx1_o <= w_hdmi_txd1;
        r_hdmi_tx2_o <= w_hdmi_txd2;
    end else begin
        r_hdmi_txc_o <= r_hdmi_txc_o >> 5;
        r_hdmi_tx0_o <= r_hdmi_tx0_o >> 5;
        r_hdmi_tx1_o <= r_hdmi_tx1_o >> 5;
        r_hdmi_tx2_o <= r_hdmi_tx2_o >> 5;
    end
end

assign hdmi_txc_o = r_hdmi_txc_o[4:0];
assign hdmi_tx0_o = r_hdmi_tx0_o[4:0];
assign hdmi_tx1_o = r_hdmi_tx1_o[4:0];
assign hdmi_tx2_o = r_hdmi_tx2_o[4:0];

// ============================================================================
// Reserved UART: 1 Mbps 8N1 on Axi0Clk (96 MHz -> 96 clks/bit, exact baud).
// TX currently emits a periodic 0xAA heartbeat as a power-on link self-test;
// swap tx_data/tx_start for the real payload once the protocol is defined.
// RX bytes are exposed on uart_rx_data/uart_rx_valid for later use.
// ============================================================================
wire [7:0] uart_rx_data;
wire       uart_rx_valid;
wire       uart_tx_busy;
reg        uart_tx_start = 1'b0;
reg [23:0] uart_hb_cnt   = 24'd0;

always @(posedge Axi0Clk or negedge user_rst_n) begin
    if (!user_rst_n) begin
        uart_hb_cnt   <= 24'd0;
        uart_tx_start <= 1'b0;
    end else begin
        uart_tx_start <= 1'b0;
        uart_hb_cnt   <= uart_hb_cnt + 24'd1;
        if (uart_hb_cnt == 24'd0 && !uart_tx_busy)
            uart_tx_start <= 1'b1;   // ~one 0xAA every 2^24 Axi0Clk (~175 ms)
    end
end

simple_uart #(
    .CLK_FREQ (96_000_000),
    .BAUD_RATE(1_000_000)
) u_uart_reserved (
    .clk      (Axi0Clk),
    .rst_n    (user_rst_n),
    .rx       (uart_rxd),
    .tx       (uart_txd),
    .rx_data  (uart_rx_data),
    .rx_valid (uart_rx_valid),
    .tx_data  (8'hAA),
    .tx_start (uart_tx_start),
    .tx_busy  (uart_tx_busy)
);

endmodule
