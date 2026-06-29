`ifndef HDMI_RESULT_UI_V
`define HDMI_RESULT_UI_V

`include "ui_color_renderer.v"
`include "ui_shape_renderer.v"
`include "ui_font_overlay.v"

module hdmi_result_ui #(
    parameter [2:0] COLOR_UNKNOWN = 3'd0,
    parameter [2:0] COLOR_BLACK = 3'd1,
    parameter [2:0] COLOR_WHITE = 3'd2,
    parameter [2:0] COLOR_RED = 3'd3,
    parameter [2:0] COLOR_BLUE = 3'd4,
    parameter [2:0] COLOR_YELLOW = 3'd5,
    parameter [2:0] SHAPE_UNKNOWN = 3'd0,
    parameter [2:0] SHAPE_CUBE = 3'd1,
    parameter [2:0] SHAPE_CYLINDER = 3'd2,
    parameter [2:0] SHAPE_CONE = 3'd3
) (
    input  wire        hdmi_tx_slow_clk,
    input  wire        sys_rst_n,
    input  wire        hdmi_pll_locked,
    input  wire        shape_page_cam,
    input  wire [2:0]  color_id_hdmi,
    input  wire        color_valid_hdmi,
    input  wire [2:0]  shape_display_id_hdmi,
    input  wire        timer_running_hdmi,
    input  wire        timer_result_valid_hdmi,
    input  wire        timer_display_active_hdmi,
    input  wire [23:0] timer_display_us_hdmi,
    input  wire [23:0] timer_display_us_hdmi_clamped,
    input  wire [23:0] timer_display_hold_us_hdmi,
    input  wire        shape_latency_display_valid_hdmi,
    input  wire [23:0] shape_latency_display_us_hdmi,
    input  wire [23:0] shape_latency_display_us_hdmi_clamped,

    output wire        shape_preview_ui_active,
    output wire [7:0]  shape_preview_ui_x,
    output wire [6:0]  shape_preview_ui_y,
    output wire [9:0]  tmds_data0_TX_DATA,
    output wire [9:0]  tmds_data1_TX_DATA,
    output wire [9:0]  tmds_data2_TX_DATA,
    output wire [9:0]  tmds_clk_TX_DATA,
    output wire        tmds_data0_TX_OE,
    output wire        tmds_data1_TX_OE,
    output wire        tmds_data2_TX_OE,
    output wire        tmds_clk_TX_OE,
    output wire        tmds_data0_TX_RST,
    output wire        tmds_data1_TX_RST,
    output wire        tmds_data2_TX_RST,
    output wire        tmds_clk_TX_RST
);

localparam UI_MODE_COLOR = 1'b0;
localparam UI_MODE_SHAPE = 1'b1;

localparam [23:0] UI_BG_COLOR      = 24'h181820;
localparam [23:0] UI_BAR_COLOR     = 24'h101018;
localparam [23:0] UI_SEP_COLOR     = 24'h1A1A28;
localparam [23:0] UI_LATENCY_ON    = 24'hFFD060;
localparam [23:0] UI_LATENCY_OFF   = 24'h333344;
localparam [23:0] UI_LATENCY_UNIT  = 24'h806830;
localparam [23:0] UI_PULSE_COLOR   = 24'h30D070;
localparam [23:0] UI_PULSE_HALO    = 24'h1B3428;
localparam [11:0] UI_TOP_BAR_Y     = 12'd30;
localparam [11:0] UI_BOTTOM_Y      = 12'd390;
localparam [11:0] UI_LAT_Y         = 12'd440;
localparam [11:0] LAT_BAR_X        = 12'd280;
localparam [11:0] LAT_BAR_Y        = 12'd466;
localparam [11:0] LAT_BAR_W        = 12'd320;
localparam [11:0] LAT_BAR_H        = 12'd4;
localparam [23:0] LAT_COLOR_LIMIT_US = 24'd1000;
localparam [23:0] LAT_SHAPE_LIMIT_US = 24'd16000;

wire reset_request_n = sys_rst_n & hdmi_pll_locked;
reg [2:0] hdmi_rst_sync = 3'b000;
wire hdmi_rst_n = hdmi_rst_sync[2];

wire [11:0] test_h_cnt;
wire [11:0] test_v_cnt;
wire test_hs;
wire test_vs;
wire test_de;
reg [23:0] test_rgb;
reg rgb_vs_r;
reg rgb_hs_r;
reg rgb_de_r;
reg [23:0] rgb_datax1;
wire ui_mode_hdmi;

wire color_main_pixel_en;
wire [23:0] color_main_pixel_rgb;
wire color_candidate_pixel_en;
wire [23:0] color_candidate_pixel_rgb;
wire shape_badge_pixel_en;
wire [23:0] shape_badge_pixel_rgb;
wire shape_main_pixel_en;
wire [23:0] shape_main_pixel_rgb;
wire shape_candidate_pixel_en;
wire [23:0] shape_candidate_pixel_rgb;
wire font_pixel_en;
wire [23:0] font_pixel_color;

function [23:0] color_to_rgb24;
input [2:0] color_id;
begin
    case (color_id)
        COLOR_BLACK:  color_to_rgb24 = 24'h000000;
        COLOR_WHITE:  color_to_rgb24 = 24'hFFFFFF;
        COLOR_RED:    color_to_rgb24 = 24'hFF2020;
        COLOR_BLUE:   color_to_rgb24 = 24'h2050FF;
        COLOR_YELLOW: color_to_rgb24 = 24'hFFD800;
        default:      color_to_rgb24 = 24'h606060;
    endcase
end
endfunction

hdmi_timing_640x480 u_hdmi_ui_timing (
    .clk(hdmi_tx_slow_clk),
    .rst_n(hdmi_rst_n),
    .h_cnt(test_h_cnt),
    .v_cnt(test_v_cnt),
    .hs(test_hs),
    .vs(test_vs),
    .de(test_de)
);

ui_mode_latch #(
    .UI_MODE_COLOR(UI_MODE_COLOR)
) u_ui_mode_latch (
    .clk(hdmi_tx_slow_clk),
    .rst_n(hdmi_rst_n),
    .frame_start((test_h_cnt == 12'd0) && (test_v_cnt == 12'd0)),
    .shape_page_cam(shape_page_cam),
    .ui_mode(ui_mode_hdmi)
);

ui_color_renderer #(
    .COLOR_UNKNOWN(COLOR_UNKNOWN),
    .COLOR_BLACK(COLOR_BLACK),
    .COLOR_WHITE(COLOR_WHITE),
    .COLOR_RED(COLOR_RED),
    .COLOR_BLUE(COLOR_BLUE),
    .COLOR_YELLOW(COLOR_YELLOW)
) u_ui_color_renderer (
    .h_cnt(test_h_cnt),
    .v_cnt(test_v_cnt),
    .color_id(color_id_hdmi),
    .color_valid(color_valid_hdmi),
    .color_rgb(color_to_rgb24(color_id_hdmi)),
    .main_pixel_en(color_main_pixel_en),
    .main_pixel_rgb(color_main_pixel_rgb),
    .candidate_pixel_en(color_candidate_pixel_en),
    .candidate_pixel_rgb(color_candidate_pixel_rgb)
);

ui_shape_renderer #(
    .SHAPE_UNKNOWN(SHAPE_UNKNOWN),
    .SHAPE_CUBE(SHAPE_CUBE),
    .SHAPE_CYLINDER(SHAPE_CYLINDER),
    .SHAPE_CONE(SHAPE_CONE)
) u_ui_shape_renderer (
    .h_cnt(test_h_cnt),
    .v_cnt(test_v_cnt),
    .shape_display_id(shape_display_id_hdmi),
    .shape_rgb(color_to_rgb24(color_id_hdmi)),
    .badge_pixel_en(shape_badge_pixel_en),
    .badge_pixel_rgb(shape_badge_pixel_rgb),
    .main_pixel_en(shape_main_pixel_en),
    .main_pixel_rgb(shape_main_pixel_rgb),
    .candidate_pixel_en(shape_candidate_pixel_en),
    .candidate_pixel_rgb(shape_candidate_pixel_rgb)
);

wire [23:0] latency_display_us_hdmi =
    (ui_mode_hdmi == UI_MODE_SHAPE) ? shape_latency_display_us_hdmi : timer_display_us_hdmi;
wire latency_running_hdmi =
    (ui_mode_hdmi == UI_MODE_SHAPE) ? 1'b0 : timer_running_hdmi;
wire latency_display_active_hdmi =
    (ui_mode_hdmi == UI_MODE_SHAPE) ? shape_latency_display_valid_hdmi : timer_display_active_hdmi;
wire latency_confirmed_hdmi =
    (ui_mode_hdmi == UI_MODE_SHAPE) ?
    (shape_latency_display_valid_hdmi && (shape_latency_display_us_hdmi != 24'd0)) :
    (!timer_running_hdmi && (timer_result_valid_hdmi || (timer_display_hold_us_hdmi != 24'd0)));
wire [23:0] latency_limit_us_hdmi =
    (ui_mode_hdmi == UI_MODE_SHAPE) ? LAT_SHAPE_LIMIT_US : LAT_COLOR_LIMIT_US;
wire latency_zero_hdmi = (latency_display_us_hdmi == 24'd0);
wire latency_good_hdmi = latency_display_active_hdmi && latency_confirmed_hdmi &&
                         !latency_zero_hdmi &&
                         (latency_display_us_hdmi <= latency_limit_us_hdmi);
wire latency_orange_hdmi = latency_running_hdmi || latency_confirmed_hdmi ||
                           !latency_display_active_hdmi || latency_zero_hdmi;
wire [23:0] latency_clamped_color_hdmi =
    (latency_display_us_hdmi > LAT_COLOR_LIMIT_US) ? LAT_COLOR_LIMIT_US : latency_display_us_hdmi;
wire [23:0] latency_clamped_shape_hdmi =
    (latency_display_us_hdmi > LAT_SHAPE_LIMIT_US) ? LAT_SHAPE_LIMIT_US : latency_display_us_hdmi;
wire [23:0] lat_bar_fill_color_raw = (latency_clamped_color_hdmi >> 2) +
                                     (latency_clamped_color_hdmi >> 4) +
                                     (latency_clamped_color_hdmi >> 7) +
                                     (latency_clamped_color_hdmi >> 9);
wire [23:0] lat_bar_fill_shape_raw = (latency_clamped_shape_hdmi >> 6) +
                                     (latency_clamped_shape_hdmi >> 8) +
                                     (latency_clamped_shape_hdmi >> 11) +
                                     (latency_clamped_shape_hdmi >> 13);
wire [23:0] lat_bar_fill_raw =
    (ui_mode_hdmi == UI_MODE_SHAPE) ? lat_bar_fill_shape_raw : lat_bar_fill_color_raw;
wire [23:0] lat_bar_fill = (lat_bar_fill_raw > {12'd0, LAT_BAR_W}) ? {12'd0, LAT_BAR_W} : lat_bar_fill_raw;
wire [23:0] latency_highlight_color_hdmi =
    latency_good_hdmi ? UI_PULSE_COLOR : (latency_orange_hdmi ? UI_LATENCY_ON : UI_LATENCY_OFF);
wire [23:0] latency_unit_color_hdmi =
    latency_good_hdmi ? UI_PULSE_COLOR : (latency_orange_hdmi ? UI_LATENCY_UNIT : 24'h2A2A32);
wire lat_bar_hit = (test_h_cnt >= LAT_BAR_X) && (test_h_cnt < LAT_BAR_X + LAT_BAR_W) &&
                   (test_v_cnt >= LAT_BAR_Y) && (test_v_cnt < LAT_BAR_Y + LAT_BAR_H);
wire lat_bar_fill_hit = lat_bar_hit && ({12'd0, test_h_cnt - LAT_BAR_X} < lat_bar_fill);

wire [12:0] pulse_abs_dx = (test_h_cnt >= 12'd610) ? ({1'b0, test_h_cnt} - 13'd610) :
                           (13'd610 - {1'b0, test_h_cnt});
wire [12:0] pulse_abs_dy = (test_v_cnt >= 12'd462) ? ({1'b0, test_v_cnt} - 13'd462) :
                           (13'd462 - {1'b0, test_v_cnt});
wire pulse_inner = (pulse_abs_dx <= 13'd4) && (pulse_abs_dy <= 13'd4);
wire pulse_outer = (pulse_abs_dx <= 13'd10) && (pulse_abs_dy <= 13'd10) &&
                   ((pulse_abs_dx + pulse_abs_dy) <= 13'd14);

ui_font_overlay #(
    .UI_MODE_COLOR(UI_MODE_COLOR),
    .UI_MODE_SHAPE(UI_MODE_SHAPE),
    .SHAPE_UNKNOWN(SHAPE_UNKNOWN),
    .SHAPE_CUBE(SHAPE_CUBE),
    .SHAPE_CYLINDER(SHAPE_CYLINDER),
    .SHAPE_CONE(SHAPE_CONE)
) u_ui_font_overlay (
    .clk(hdmi_tx_slow_clk),
    .arst_n(hdmi_rst_n),
    .h_cnt(test_h_cnt),
    .v_cnt(test_v_cnt),
    .ui_mode(ui_mode_hdmi),
    .shape_display_id(shape_display_id_hdmi),
    .timer_display_us_hdmi_clamped(timer_display_us_hdmi_clamped),
    .shape_latency_display_us_hdmi_clamped(shape_latency_display_us_hdmi_clamped),
    .latency_highlight_color_hdmi(latency_highlight_color_hdmi),
    .latency_unit_color_hdmi(latency_unit_color_hdmi),
    .font_pixel_en(font_pixel_en),
    .font_pixel_color(font_pixel_color)
);

assign shape_preview_ui_active = 1'b0;
assign shape_preview_ui_x = 8'd0;
assign shape_preview_ui_y = 7'd0;

always @(posedge hdmi_tx_slow_clk) begin
    if (!reset_request_n)
        hdmi_rst_sync <= 3'b000;
    else
        hdmi_rst_sync <= {hdmi_rst_sync[1:0], 1'b1};
end

always @(posedge hdmi_tx_slow_clk) begin
    if (!hdmi_rst_n) begin
        test_rgb <= 24'h000000;
    end else if (!test_de) begin
        test_rgb <= 24'h000000;
    end else begin
        test_rgb <= UI_BG_COLOR;

        if (test_v_cnt < UI_TOP_BAR_Y) begin
            test_rgb <= UI_BAR_COLOR;
            if (ui_mode_hdmi == UI_MODE_SHAPE && shape_badge_pixel_en)
                test_rgb <= shape_badge_pixel_rgb;
            if (font_pixel_en)
                test_rgb <= font_pixel_color;
        end else if (ui_mode_hdmi == UI_MODE_SHAPE && test_v_cnt >= 12'd36 && test_v_cnt < 12'd385) begin
            if (shape_main_pixel_en)
                test_rgb <= shape_main_pixel_rgb;
            if (font_pixel_en)
                test_rgb <= font_pixel_color;
        end else if (ui_mode_hdmi == UI_MODE_COLOR && test_v_cnt >= 12'd36 && test_v_cnt < 12'd385) begin
            if (color_main_pixel_en)
                test_rgb <= color_main_pixel_rgb;
            if (font_pixel_en)
                test_rgb <= font_pixel_color;
        end else if (test_v_cnt >= UI_BOTTOM_Y && test_v_cnt < UI_BOTTOM_Y + 12'd1) begin
            test_rgb <= UI_SEP_COLOR;
        end else if (test_v_cnt > UI_BOTTOM_Y && test_v_cnt < UI_LAT_Y) begin
            test_rgb <= UI_BAR_COLOR;
            if (ui_mode_hdmi == UI_MODE_SHAPE) begin
                if (shape_candidate_pixel_en)
                    test_rgb <= shape_candidate_pixel_rgb;
            end else begin
                if (color_candidate_pixel_en)
                    test_rgb <= color_candidate_pixel_rgb;
            end
            if (font_pixel_en)
                test_rgb <= font_pixel_color;
        end else if (test_v_cnt >= UI_LAT_Y) begin
            test_rgb <= UI_BAR_COLOR;
            if (test_v_cnt == UI_LAT_Y)
                test_rgb <= UI_SEP_COLOR;
            if (lat_bar_hit) begin
                test_rgb <= 24'h1A1A22;
                if (lat_bar_fill_hit)
                    test_rgb <= latency_highlight_color_hdmi;
            end
            if (latency_running_hdmi || latency_good_hdmi) begin
                if (pulse_inner)
                    test_rgb <= UI_PULSE_COLOR;
                else if (pulse_outer)
                    test_rgb <= UI_PULSE_HALO;
            end
            if (font_pixel_en)
                test_rgb <= font_pixel_color;
        end
    end
end

always @(posedge hdmi_tx_slow_clk) begin
    rgb_vs_r <= test_vs;
    rgb_hs_r <= test_hs;
    rgb_de_r <= test_de;
    rgb_datax1 <= test_rgb;
end

hdmi_top hdmi_top_inst (
    .hdmi_tx_locked(hdmi_pll_locked),
    .i_hs(rgb_hs_r),
    .i_vs(rgb_vs_r),
    .i_de(rgb_de_r),
    .i_rdata(rgb_datax1[23:16]),
    .i_gdata(rgb_datax1[15:8]),
    .i_bdata(rgb_datax1[7:0]),
    .hdmi_tx_slow_clk(hdmi_tx_slow_clk),
    .tmds_data0_o(tmds_data0_TX_DATA),
    .tmds_data1_o(tmds_data1_TX_DATA),
    .tmds_data2_o(tmds_data2_TX_DATA),
    .tmds_clk_o(tmds_clk_TX_DATA),
    .tmds_data0_TX_OE(tmds_data0_TX_OE),
    .tmds_data1_TX_OE(tmds_data1_TX_OE),
    .tmds_data2_TX_OE(tmds_data2_TX_OE),
    .tmds_clk_TX_OE(tmds_clk_TX_OE),
    .tmds_data0_TX_RST(tmds_data0_TX_RST),
    .tmds_data1_TX_RST(tmds_data1_TX_RST),
    .tmds_data2_TX_RST(tmds_data2_TX_RST),
    .tmds_clk_TX_RST(tmds_clk_TX_RST)
);

endmodule

`endif
