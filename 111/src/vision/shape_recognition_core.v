`ifndef SHAPE_RECOGNITION_CORE_V
`define SHAPE_RECOGNITION_CORE_V

module shape_recognition_core #(
    parameter VACT = 12'd1080,
    parameter [2:0] SHAPE_UNKNOWN = 3'd0,
    parameter [2:0] SHAPE_CUBE = 3'd1,
    parameter [2:0] SHAPE_CYLINDER = 3'd2,
    parameter [2:0] SHAPE_CONE = 3'd3,
    parameter [11:0] SHAPE_ROI_X_START = 12'd492,
    parameter [11:0] SHAPE_ROI_X_END = 12'd1428,
    parameter [10:0] SHAPE_ROI_Y_START = 11'd212,
    parameter [10:0] SHAPE_ROI_Y_END = 11'd868,
    parameter [9:0] SHAPE_CENTER_X = 10'd468,
    parameter [9:0] SHAPE_CENTER_LEFT_MIN = 10'd40,
    parameter [9:0] SHAPE_CENTER_RIGHT_MAX = 10'd896,
    parameter [9:0] SHAPE_CENTER_GAP = 10'd24,
    parameter [9:0] SHAPE_CENTER_MIN_ROW_WIDTH = 10'd80,
    parameter [9:0] SHAPE_INNER_SAMPLE_LEFT_X = 10'd372,
    parameter [9:0] SHAPE_INNER_SAMPLE_MID_X = 10'd468,
    parameter [9:0] SHAPE_INNER_SAMPLE_RIGHT_X = 10'd564,
    parameter [1:0] SHAPE_SEG_GAP_MAX = 2'd2,
    parameter [7:0] SHAPE_EDGE_H_THRESH = 8'd9,
    parameter [7:0] SHAPE_EDGE_V_THRESH = 8'd5,
    parameter [9:0] SHAPE_MIN_ROW_WIDTH = 10'd16,
    parameter [7:0] SHAPE_MIN_VALID_ROWS = 8'd10,
    parameter [9:0] SHAPE_MIN_BBOX_W = 10'd18,
    parameter [7:0] SHAPE_MIN_BBOX_H = 8'd18,
    parameter [5:0] SHAPE_BG_RGB_DIFF_THRESH = 6'd6,
    parameter [5:0] SHAPE_SHADOW_DROP_MIN = 6'd6,
    parameter [5:0] SHAPE_SHADOW_DROP_MAX = 6'd18,
    parameter [3:0] SHAPE_SHADOW_BALANCE_MAX = 4'd3,
    parameter [5:0] SHAPE_SHADOW_CUR_SUM_MIN = 6'd10,
    parameter [4:0] SHAPE_BG_LEARN_FRAMES = 5'd12,
    parameter [20:0] SHAPE_PAGE_BTN_DEBOUNCE_MAX = 21'd1399999,
    parameter [7:0] SHAPE_PREVIEW_W = 8'd160,
    parameter [6:0] SHAPE_PREVIEW_H = 7'd120,
    parameter [7:0] SHAPE_ROI_PREVIEW_X_START = 8'd41,
    parameter [7:0] SHAPE_ROI_PREVIEW_X_END = 8'd118,
    parameter [6:0] SHAPE_ROI_PREVIEW_Y_START = 7'd24,
    parameter [6:0] SHAPE_ROI_PREVIEW_Y_END = 7'd96,
    parameter [7:0] SHAPE_FG_GRID_X1 = 8'd67,
    parameter [7:0] SHAPE_FG_GRID_X2 = 8'd93,
    parameter [6:0] SHAPE_FG_GRID_Y1 = 7'd48,
    parameter [6:0] SHAPE_FG_GRID_Y2 = 7'd72,
    parameter [7:0] SHAPE_FG_COL_LEFT_X = 8'd60,
    parameter [7:0] SHAPE_FG_COL_MID_X = 8'd80,
    parameter [7:0] SHAPE_FG_COL_RIGHT_X = 8'd100,
    parameter [1:0] SHAPE_FG_RUN_GAP_MAX = 2'd1,
    parameter [7:0] SHAPE_WIDTH5_CYL_MIN = 8'd8,
    parameter [7:0] SHAPE_WIDTH5_CUBE_MIN = 8'd18,
    parameter [7:0] SHAPE_WIDTH5_VALID_MAX = 8'd40,
    parameter [7:0] SHAPE_WIDTH_RANGE_MAX = 8'd15,
    parameter [12:0] SHAPE_MIN_FG_PIXELS = 13'd96,
    parameter [7:0] SHAPE_MOTION_WIDTH5_DELTA = 8'd6,
    parameter [7:0] SHAPE_MOTION_BBOX_DELTA = 8'd14,
    parameter [7:0] SHAPE_MOTION_ROWS_DELTA = 8'd10,
    parameter [12:0] SHAPE_MOTION_PIXELS_DELTA = 13'd450,
    parameter ENABLE_HDMI_PREVIEW = 1'b0
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rgb_vs,
    input  wire        rgb_de,
    input  wire [47:0] rgb_datax2,
    input  wire        shape_page_button,
    input  wire        shape_timer_running,

    input  wire        hdmi_clk,
    input  wire        hdmi_rst_n,
    input  wire        shape_preview_ui_active,
    input  wire [7:0]  shape_preview_ui_x,
    input  wire [6:0]  shape_preview_ui_y,

    output reg  [2:0]  shape_id_cam,
    output reg         shape_valid_cam,
    output reg  [2:0]  shape_display_id_cam,
    output reg         shape_display_valid_cam,
    output wire        shape_page_cam,
    output wire        shape_bg_learn_cam,
    output wire        shape_bg_valid_cam,
    output wire        shape_timer_start_cam_pulse,
    output wire        shape_timer_stop_cam_pulse,
    output wire        shape_timer_cancel_cam_pulse,
    output reg  [7:0]  shape_preview_gray_hdmi,
    output reg  [7:0]  shape_contour_left_hdmi,
    output reg  [7:0]  shape_contour_right_hdmi,
    output reg  [7:0]  shape_fg_contour_left_hdmi,
    output reg  [7:0]  shape_fg_contour_right_hdmi,
    output reg         shape_bg_valid_hdmi,
    output reg         shape_bg_learn_hdmi
);
wire shape_page_enter_cam;

// Shape recognition works in the camera clock domain. It avoids a full
// frame-sized binary image: each line is scanned once, edge positions and
// simple profile features are accumulated, then the frame-end logic classifies
// cube/cylinder/cone.
reg rgb_vs_d;
reg rgb_de_d;
reg [11:0] color_x;
reg [10:0] color_y;
reg [2:0] shape_candidate_prev_cam;
reg shape_candidate_prev_valid_cam;
reg [1:0] shape_candidate_streak_cam;
reg [2:0] shape_invalid_frames_cam;
reg shape_motion_prev_valid_cam;
reg [7:0] shape_motion_prev_width5_cam;
reg [7:0] shape_motion_prev_bbox_w_cam;
reg [7:0] shape_motion_prev_bbox_h_cam;
reg [7:0] shape_motion_prev_valid_rows_cam;
reg [12:0] shape_motion_prev_pixel_count_cam;
reg [15:0] shape_gray_line_ram [0:467];
reg [7:0] shape_prev_gray_cam;
reg shape_prev_gray_valid_cam;
reg [9:0] shape_row_left_cam;
reg [9:0] shape_row_right_cam;
reg [9:0] shape_center_row_left_cam;
reg [9:0] shape_center_row_right_cam;
reg [7:0] shape_row_edge_count_cam;
reg shape_row_has_edge_cam;
reg shape_row_roi_hit_cam;
reg shape_seg_active_cam;
reg [1:0] shape_seg_gap_cam;
reg [7:0] shape_seg_rows_cam;
reg [9:0] shape_seg_min_x_cam;
reg [9:0] shape_seg_max_x_cam;
reg [9:0] shape_seg_min_y_cam;
reg [9:0] shape_seg_max_y_cam;
reg [9:0] shape_seg_width_min_cam;
reg [9:0] shape_seg_width_max_cam;
reg [9:0] shape_seg_top_width_cam;
reg [9:0] shape_seg_bottom_width_cam;
reg [7:0] shape_best_rows_cam;
reg [9:0] shape_best_min_x_cam;
reg [9:0] shape_best_max_x_cam;
reg [9:0] shape_best_min_y_cam;
reg [9:0] shape_best_max_y_cam;
reg [9:0] shape_best_width_min_cam;
reg [9:0] shape_best_width_max_cam;
reg [9:0] shape_best_top_width_cam;
reg [9:0] shape_best_bottom_width_cam;
reg [10:0] shape_frame_count_cam;
reg [10:0] shape_roi_hit_pixels_cam;
reg [10:0] shape_roi_hit_rows_cam;
reg [10:0] shape_edge_hit_pixels_cam;
reg [10:0] shape_rows_any_edge_cam;
reg [10:0] shape_rows_two_edges_cam;
reg [10:0] shape_edge_count_max_cam;
reg [7:0] shape_gray_min_cam;
reg [7:0] shape_gray_max_cam;
reg [7:0] shape_h_diff_max_cam;
reg [7:0] shape_v_diff_max_cam;
reg [7:0] shape_inner_gray_min_cam;
reg [7:0] shape_inner_gray_max_cam;
reg [9:0] shape_inner_grad_max_cam;
reg [7:0] shape_inner_lr_diff_max_cam;
reg [7:0] shape_inner_sample_rows_cam;
reg [7:0] shape_inner_cylinder_rows_cam;
reg [7:0] shape_inner_cube_rows_cam;
reg [7:0] shape_row_inner_left_gray_cam;
reg [7:0] shape_row_inner_mid_gray_cam;
reg [7:0] shape_row_inner_right_gray_cam;
reg shape_row_inner_left_valid_cam;
reg shape_row_inner_mid_valid_cam;
reg shape_row_inner_right_valid_cam;
reg [9:0] shape_min_x_cam;
reg [9:0] shape_max_x_cam;
reg [9:0] shape_min_y_cam;
reg [9:0] shape_max_y_cam;
reg [9:0] shape_width_min_cam;
reg [9:0] shape_width_max_cam;
reg [16:0] shape_width_sum_cam;
reg [16:0] shape_width_delta_sum_cam;
reg [7:0] shape_valid_rows_cam;
reg shape_metric_valid_cam;
reg [7:0] shape_valid_rows_filt_cam;
reg [9:0] shape_bbox_w_filt_cam;
reg [9:0] shape_bbox_h_filt_cam;
reg [9:0] shape_width_max_filt_cam;
reg [9:0] shape_top_width_cam;
reg [9:0] shape_bottom_width_cam;
reg [9:0] shape_prev_row_width_cam;
reg shape_prev_row_width_valid_cam;
reg [9:0] shape_top_edge_bin0_cam;
reg [9:0] shape_top_edge_bin1_cam;
reg [9:0] shape_top_edge_bin2_cam;
reg [9:0] shape_top_edge_bin3_cam;
reg [9:0] shape_top_edge_bin4_cam;
reg [9:0] shape_top_edge_bin5_cam;
reg [9:0] shape_top_edge_bin6_cam;
reg [9:0] shape_top_edge_bin7_cam;
reg [9:0] shape_top_edge_bin8_cam;
reg [9:0] shape_top_edge_bin9_cam;
// Small preview memories:
// shape_preview_ram stores a down-sampled grayscale image for the HDMI page.
// shape_bg_grid_ram stores a coarse RGB444 background model for foreground extraction.
// It is refreshed automatically for a short window after entering the shape page.
// contour RAMs save per-row left/right contour positions for overlay drawing.
reg [7:0] shape_preview_ram [0:19199];
reg [11:0] shape_bg_grid_ram [0:1199];
reg [7:0] shape_contour_left_ram [0:119];
reg [7:0] shape_contour_right_ram [0:119];
reg [7:0] shape_fg_contour_left_ram [0:119];
reg [7:0] shape_fg_contour_right_ram [0:119];
reg [2:0] shape_preview_x_div_cam;
reg [3:0] shape_preview_y_div_cam;
reg [7:0] shape_preview_wr_x_cam;
reg [6:0] shape_preview_wr_y_cam;
reg shape_preview_capture_line_cam;
reg shape_fg_addr_valid_cam;
reg shape_fg_addr_bg_valid_cam;
reg shape_fg_addr_in_roi_cam;
reg [10:0] shape_fg_addr_bg_grid_addr_cam;
reg [11:0] shape_fg_addr_rgb444_cam;
reg [7:0] shape_fg_addr_x_cam;
reg [7:0] shape_fg_addr_gray_cam;
reg shape_fg_addr_top_zone_cam;
reg shape_fg_addr_mid_zone_cam;
reg shape_fg_addr_corner_zone_cam;
reg shape_fg_addr_center_zone_cam;
reg shape_fg_addr_col_left_cam;
reg shape_fg_addr_col_mid_cam;
reg shape_fg_addr_col_right_cam;
reg shape_fg_eval_valid_cam;
reg shape_fg_eval_bg_valid_cam;
reg shape_fg_eval_in_roi_cam;
reg [11:0] shape_fg_eval_rgb444_cam;
reg [11:0] shape_fg_eval_bg_rgb444_cam;
reg [7:0] shape_fg_eval_x_cam;
reg [7:0] shape_fg_eval_gray_cam;
reg shape_fg_eval_top_zone_cam;
reg shape_fg_eval_mid_zone_cam;
reg shape_fg_eval_corner_zone_cam;
reg shape_fg_eval_center_zone_cam;
reg shape_fg_eval_col_left_cam;
reg shape_fg_eval_col_mid_cam;
reg shape_fg_eval_col_right_cam;
reg shape_fg_sample_valid_cam;
reg shape_fg_sample_pixel_cam;
reg [7:0] shape_fg_sample_x_cam;
reg [6:0] shape_fg_sample_y_cam;
reg [7:0] shape_fg_sample_gray_cam;
reg shape_fg_sample_top_zone_cam;
reg shape_fg_sample_mid_zone_cam;
reg shape_fg_sample_corner_zone_cam;
reg shape_fg_sample_center_zone_cam;
reg shape_fg_sample_col_left_cam;
reg shape_fg_sample_col_mid_cam;
reg shape_fg_sample_col_right_cam;
reg [7:0] shape_fg_row_left_cam;
reg [7:0] shape_fg_row_right_cam;
reg shape_fg_row_hit_cam;
reg [7:0] shape_fg_row_left_gray_cam;
reg [7:0] shape_fg_row_right_gray_cam;
reg [7:0] shape_fg_row_prev_gray_cam;
reg shape_fg_row_prev_hit_cam;
reg shape_fg_run_active_cam;
reg [1:0] shape_fg_run_gap_cam;
reg [7:0] shape_fg_run_left_cam;
reg [7:0] shape_fg_run_right_cam;
reg [7:0] shape_fg_run_len_cam;
reg [7:0] shape_fg_best_len_cam;
reg [7:0] shape_fg_run_left_gray_cam;
reg [7:0] shape_fg_run_right_gray_cam;
reg [7:0] shape_fg_min_x_cam;
reg [7:0] shape_fg_max_x_cam;
reg [6:0] shape_fg_min_y_cam;
reg [6:0] shape_fg_max_y_cam;
reg [7:0] shape_fg_width_min_cam;
reg [7:0] shape_fg_width_max_cam;
reg [7:0] shape_fg_top_width_cam;
reg [7:0] shape_fg_bottom_width_cam;
reg [7:0] shape_fg_valid_rows_cam;
reg [12:0] shape_fg_pixel_count_cam;
reg [7:0] shape_fg_col_left_rows_cam;
reg [7:0] shape_fg_col_mid_rows_cam;
reg [7:0] shape_fg_col_right_rows_cam;
reg [11:0] shape_fg_top_count_cam;
reg [11:0] shape_fg_mid_count_cam;
reg [11:0] shape_fg_bottom_count_cam;
reg [11:0] shape_fg_corner_count_cam;
reg [11:0] shape_fg_center_count_cam;
reg [7:0] shape_fg_gray_min_cam;
reg [7:0] shape_fg_gray_max_cam;
reg [7:0] shape_fg_grad_max_cam;
reg [7:0] shape_fg_lr_gray_diff_max_cam;
reg [10:0] shape_fg_top_width_sum_cam;
reg [2:0] shape_fg_top_width_rows_cam;
reg [7:0] shape_fg_bottom_width0_cam;
reg [7:0] shape_fg_bottom_width1_cam;
reg [7:0] shape_fg_bottom_width2_cam;
reg [7:0] shape_fg_bottom_width3_cam;
reg [7:0] shape_fg_curve_left_gray_cam;
reg [7:0] shape_fg_curve_mid_gray_cam;
reg [7:0] shape_fg_curve_right_gray_cam;
reg shape_fg_curve_left_valid_cam;
reg shape_fg_curve_mid_valid_cam;
reg shape_fg_curve_right_valid_cam;
reg [9:0] shape_fg_curve_grad_max_cam;
reg [7:0] shape_fg_curve_lr_diff_max_cam;
reg [7:0] shape_fg_curve_sample_rows_cam;
reg [14:0] shape_preview_rd_addr_hdmi;
reg shape_bg_valid_hdmi_meta;
reg shape_bg_learn_hdmi_meta;

// Utility helpers for the sequential shape accumulators and HDMI preview RAM
// addressing. Pixel scan math lives in shape_scanner.
function [7:0] abs_diff_u8;
input [7:0] a;
input [7:0] b;
begin
    abs_diff_u8 = (a > b) ? (a - b) : (b - a);
end
endfunction

function [9:0] abs_diff_u10;
input [9:0] a;
input [9:0] b;
begin
    abs_diff_u10 = (a > b) ? (a - b) : (b - a);
end
endfunction

function [3:0] abs_diff_u4;
input [3:0] a;
input [3:0] b;
begin
    abs_diff_u4 = (a > b) ? (a - b) : (b - a);
end
endfunction

function [5:0] rgb444_diff_sum;
input [11:0] a;
input [11:0] b;
begin
    rgb444_diff_sum =
        {2'd0, abs_diff_u4(a[11:8], b[11:8])} +
        {2'd0, abs_diff_u4(a[7:4], b[7:4])} +
        {2'd0, abs_diff_u4(a[3:0], b[3:0])};
end
endfunction

function [14:0] shape_preview_addr;
input [6:0] sample_y;
input [7:0] sample_x;
begin
    shape_preview_addr = ({8'd0, sample_y} << 7) + ({8'd0, sample_y} << 5) + {7'd0, sample_x};
end
endfunction

function [3:0] shape_x_bin;
input [9:0] sample_x;
begin
    if (sample_x < 10'd94)
        shape_x_bin = 4'd0;
    else if (sample_x < 10'd188)
        shape_x_bin = 4'd1;
    else if (sample_x < 10'd282)
        shape_x_bin = 4'd2;
    else if (sample_x < 10'd376)
        shape_x_bin = 4'd3;
    else if (sample_x < 10'd470)
        shape_x_bin = 4'd4;
    else if (sample_x < 10'd564)
        shape_x_bin = 4'd5;
    else if (sample_x < 10'd658)
        shape_x_bin = 4'd6;
    else if (sample_x < 10'd752)
        shape_x_bin = 4'd7;
    else if (sample_x < 10'd846)
        shape_x_bin = 4'd8;
    else
        shape_x_bin = 4'd9;
end
endfunction

// Combinational recognition pipeline.
// These wires describe whether the current two-pixel RGB beat is inside the
// configured ROIs, extract local coordinates, build edge/contrast features,
// and prepare the next frame-level classification candidate.
wire shape_roi_y_active;
wire pixel0_in_shape_roi;
wire pixel1_in_shape_roi;
wire line_end_pulse;
wire [9:0] roi_x0_local;
wire [9:0] roi_x1_local;
wire [9:0] roi_y_local;
wire [8:0] shape_roi_pair_x;
wire [15:0] shape_prev_gray_pair_cam;
wire [7:0] shape_gray0_cam;
wire [7:0] shape_gray1_cam;
wire [7:0] shape_roi_gray_min_pair_cam;
wire [7:0] shape_roi_gray_max_pair_cam;
wire [7:0] shape_prev_line_gray0_cam;
wire [7:0] shape_prev_line_gray1_cam;
wire [7:0] shape_h_diff0_cam;
wire [7:0] shape_h_diff1_cam;
wire [7:0] shape_v_diff0_cam;
wire [7:0] shape_v_diff1_cam;
wire shape_h_diff0_valid_cam;
wire shape_h_diff1_valid_cam;
wire shape_v_diff0_valid_cam;
wire shape_v_diff1_valid_cam;
wire [7:0] shape_h_diff_pair_max_cam;
wire [7:0] shape_v_diff_pair_max_cam;
wire shape_inner_row_sample_valid_cam;
wire [7:0] shape_inner_row_min_gray_cam;
wire [7:0] shape_inner_row_max_gray_cam;
wire [7:0] shape_inner_row_lc_diff_cam;
wire [7:0] shape_inner_row_cr_diff_cam;
wire [7:0] shape_inner_row_lr_diff_cam;
wire [9:0] shape_inner_row_grad_sum_cam;
wire shape_inner_row_cylinder_center_like_cam;
wire shape_inner_row_cylinder_like_cam;
wire shape_inner_row_cube_like_cam;
wire shape_h_edge0_cam;
wire shape_h_edge1_cam;
wire shape_v_edge0_cam;
wire shape_v_edge1_cam;
wire [1:0] shape_roi_pixel_inc_cam;
wire [1:0] shape_h_edge_inc_cam;
wire [2:0] shape_edge_hit_inc_cam;
wire [9:0] shape_h_edge_left_x_cam;
wire [9:0] shape_h_edge_right_x_cam;
wire shape_row_valid_eval_cam;
wire [9:0] shape_row_width_eval_cam;
wire shape_h_edge0_center_left_cam;
wire shape_h_edge1_center_left_cam;
wire shape_h_edge0_center_right_cam;
wire shape_h_edge1_center_right_cam;
wire [9:0] shape_center_row_width_eval_cam;
wire shape_center_row_valid_eval_cam;
wire [7:0] shape_valid_rows_metric_next;
wire [9:0] shape_bbox_w_metric_next;
wire [9:0] shape_bbox_h_metric_next;
wire [9:0] shape_width_max_metric_next;
wire shape_size_valid_next;
wire [2:0] shape_candidate_id_next;
wire shape_candidate_valid_next;
wire frame_done_pulse;

wire [14:0] shape_preview_wr_addr_cam;
wire [11:0] shape_preview_rgb444_cam;
wire [5:0] shape_bg_grid_x_cam;
wire [4:0] shape_bg_grid_y_cam;
wire [10:0] shape_bg_grid_addr_cam;
wire [11:0] shape_bg_grid_rgb444_cam;
wire [5:0] shape_bg_rgb_diff_cam;
wire [3:0] shape_cur_r444_cam;
wire [3:0] shape_cur_g444_cam;
wire [3:0] shape_cur_b444_cam;
wire [3:0] shape_bg_r444_cam;
wire [3:0] shape_bg_g444_cam;
wire [3:0] shape_bg_b444_cam;
wire [3:0] shape_shadow_drop_r_cam;
wire [3:0] shape_shadow_drop_g_cam;
wire [3:0] shape_shadow_drop_b_cam;
wire [5:0] shape_shadow_drop_sum_cam;
wire [5:0] shape_shadow_cur_sum_cam;
wire shape_shadow_darker_cam;
wire shape_shadow_balanced_cam;
wire shape_shadow_like_cam;
wire shape_preview_in_shape_roi_cam;
wire shape_fg_pixel_cam;
wire [5:0] shape_fg_eval_rgb_diff_cam;
wire [3:0] shape_fg_eval_cur_r444_cam;
wire [3:0] shape_fg_eval_cur_g444_cam;
wire [3:0] shape_fg_eval_cur_b444_cam;
wire [3:0] shape_fg_eval_bg_r444_cam;
wire [3:0] shape_fg_eval_bg_g444_cam;
wire [3:0] shape_fg_eval_bg_b444_cam;
wire [3:0] shape_fg_eval_shadow_drop_r_cam;
wire [3:0] shape_fg_eval_shadow_drop_g_cam;
wire [3:0] shape_fg_eval_shadow_drop_b_cam;
wire [5:0] shape_fg_eval_shadow_drop_sum_cam;
wire [5:0] shape_fg_eval_shadow_cur_sum_cam;
wire shape_fg_eval_shadow_darker_cam;
wire shape_fg_eval_shadow_balanced_cam;
wire shape_fg_eval_shadow_like_cam;
wire shape_fg_eval_pixel_next_cam;
wire [8:0] shape_fg_row_width_eval_cam;
wire [7:0] shape_fg_bbox_w_cam;
wire [7:0] shape_fg_bbox_h_cam;
wire [7:0] shape_fg_width_range_cam;
wire [7:0] shape_fg_top_bottom_delta_cam;
wire [7:0] shape_fg_col_side_min_cam;
wire [7:0] shape_fg_col_center_delta_cam;
wire [7:0] shape_fg_col_lr_diff_cam;
wire [7:0] shape_fg_gray_range_cam;
wire [7:0] shape_fg_row_lr_gray_diff_cam;
wire [8:0] shape_fg_run_len_next_cam;
wire [9:0] shape_fg_bottom_width_sum_cam;
wire [7:0] shape_fg_top_width_avg_cam;
wire [7:0] shape_fg_bottom_width_avg_cam;
wire [7:0] shape_fg_top_bottom_avg_delta_cam;
wire shape_motion_large_next;
wire [7:0] shape_fg_curve_lc_diff_cam;
wire [7:0] shape_fg_curve_cr_diff_cam;
wire [7:0] shape_fg_curve_lr_diff_cam;
wire [9:0] shape_fg_curve_grad_sum_cam;
assign shape_prev_gray_pair_cam = shape_gray_line_ram[shape_roi_pair_x];
assign shape_fg_eval_rgb_diff_cam =
    rgb444_diff_sum(shape_fg_eval_rgb444_cam, shape_fg_eval_bg_rgb444_cam);
assign shape_fg_eval_cur_r444_cam = shape_fg_eval_rgb444_cam[11:8];
assign shape_fg_eval_cur_g444_cam = shape_fg_eval_rgb444_cam[7:4];
assign shape_fg_eval_cur_b444_cam = shape_fg_eval_rgb444_cam[3:0];
assign shape_fg_eval_bg_r444_cam = shape_fg_eval_bg_rgb444_cam[11:8];
assign shape_fg_eval_bg_g444_cam = shape_fg_eval_bg_rgb444_cam[7:4];
assign shape_fg_eval_bg_b444_cam = shape_fg_eval_bg_rgb444_cam[3:0];
assign shape_fg_eval_shadow_drop_r_cam =
    (shape_fg_eval_bg_r444_cam >= shape_fg_eval_cur_r444_cam) ?
    (shape_fg_eval_bg_r444_cam - shape_fg_eval_cur_r444_cam) : 4'd0;
assign shape_fg_eval_shadow_drop_g_cam =
    (shape_fg_eval_bg_g444_cam >= shape_fg_eval_cur_g444_cam) ?
    (shape_fg_eval_bg_g444_cam - shape_fg_eval_cur_g444_cam) : 4'd0;
assign shape_fg_eval_shadow_drop_b_cam =
    (shape_fg_eval_bg_b444_cam >= shape_fg_eval_cur_b444_cam) ?
    (shape_fg_eval_bg_b444_cam - shape_fg_eval_cur_b444_cam) : 4'd0;
assign shape_fg_eval_shadow_drop_sum_cam =
    {2'd0, shape_fg_eval_shadow_drop_r_cam} +
    {2'd0, shape_fg_eval_shadow_drop_g_cam} +
    {2'd0, shape_fg_eval_shadow_drop_b_cam};
assign shape_fg_eval_shadow_cur_sum_cam =
    {2'd0, shape_fg_eval_cur_r444_cam} +
    {2'd0, shape_fg_eval_cur_g444_cam} +
    {2'd0, shape_fg_eval_cur_b444_cam};
assign shape_fg_eval_shadow_darker_cam =
    (shape_fg_eval_bg_r444_cam >= shape_fg_eval_cur_r444_cam) &&
    (shape_fg_eval_bg_g444_cam >= shape_fg_eval_cur_g444_cam) &&
    (shape_fg_eval_bg_b444_cam >= shape_fg_eval_cur_b444_cam);
assign shape_fg_eval_shadow_balanced_cam =
    (abs_diff_u4(shape_fg_eval_shadow_drop_r_cam, shape_fg_eval_shadow_drop_g_cam) <= SHAPE_SHADOW_BALANCE_MAX) &&
    (abs_diff_u4(shape_fg_eval_shadow_drop_r_cam, shape_fg_eval_shadow_drop_b_cam) <= SHAPE_SHADOW_BALANCE_MAX) &&
    (abs_diff_u4(shape_fg_eval_shadow_drop_g_cam, shape_fg_eval_shadow_drop_b_cam) <= SHAPE_SHADOW_BALANCE_MAX);
assign shape_fg_eval_shadow_like_cam =
    shape_fg_eval_shadow_darker_cam &&
    shape_fg_eval_shadow_balanced_cam &&
    (shape_fg_eval_shadow_drop_sum_cam >= SHAPE_SHADOW_DROP_MIN) &&
    (shape_fg_eval_shadow_drop_sum_cam <= SHAPE_SHADOW_DROP_MAX) &&
    (shape_fg_eval_shadow_cur_sum_cam >= SHAPE_SHADOW_CUR_SUM_MIN);
assign shape_fg_eval_pixel_next_cam =
    shape_fg_eval_bg_valid_cam &&
    shape_fg_eval_in_roi_cam &&
    (shape_fg_eval_rgb_diff_cam >= SHAPE_BG_RGB_DIFF_THRESH) &&
    (!shape_fg_eval_shadow_like_cam);

shape_scanner #(
    .SHAPE_ROI_X_START(SHAPE_ROI_X_START),
    .SHAPE_ROI_X_END(SHAPE_ROI_X_END),
    .SHAPE_ROI_Y_START(SHAPE_ROI_Y_START),
    .SHAPE_ROI_Y_END(SHAPE_ROI_Y_END),
    .SHAPE_CENTER_X(SHAPE_CENTER_X),
    .SHAPE_CENTER_LEFT_MIN(SHAPE_CENTER_LEFT_MIN),
    .SHAPE_CENTER_RIGHT_MAX(SHAPE_CENTER_RIGHT_MAX),
    .SHAPE_CENTER_GAP(SHAPE_CENTER_GAP),
    .SHAPE_CENTER_MIN_ROW_WIDTH(SHAPE_CENTER_MIN_ROW_WIDTH),
    .SHAPE_EDGE_H_THRESH(SHAPE_EDGE_H_THRESH),
    .SHAPE_EDGE_V_THRESH(SHAPE_EDGE_V_THRESH),
    .SHAPE_MIN_ROW_WIDTH(SHAPE_MIN_ROW_WIDTH),
    .SHAPE_BG_RGB_DIFF_THRESH(SHAPE_BG_RGB_DIFF_THRESH),
    .SHAPE_SHADOW_DROP_MIN(SHAPE_SHADOW_DROP_MIN),
    .SHAPE_SHADOW_DROP_MAX(SHAPE_SHADOW_DROP_MAX),
    .SHAPE_SHADOW_BALANCE_MAX(SHAPE_SHADOW_BALANCE_MAX),
    .SHAPE_SHADOW_CUR_SUM_MIN(SHAPE_SHADOW_CUR_SUM_MIN),
    .SHAPE_ROI_PREVIEW_X_START(SHAPE_ROI_PREVIEW_X_START),
    .SHAPE_ROI_PREVIEW_X_END(SHAPE_ROI_PREVIEW_X_END),
    .SHAPE_ROI_PREVIEW_Y_START(SHAPE_ROI_PREVIEW_Y_START),
    .SHAPE_ROI_PREVIEW_Y_END(SHAPE_ROI_PREVIEW_Y_END)
) u_shape_scanner (
    .rgb_de(rgb_de),
    .rgb_de_d(rgb_de_d),
    .color_x(color_x),
    .color_y(color_y),
    .rgb_datax2(rgb_datax2),
    .shape_preview_wr_x(shape_preview_wr_x_cam),
    .shape_preview_wr_y(shape_preview_wr_y_cam),
    .shape_bg_valid(shape_bg_valid_cam),
    .shape_bg_learn(shape_bg_learn_cam),
    .shape_bg_grid_rgb444(12'd0),
    .shape_prev_gray_pair(shape_prev_gray_pair_cam),
    .shape_prev_gray(shape_prev_gray_cam),
    .shape_prev_gray_valid(shape_prev_gray_valid_cam),
    .shape_row_left(shape_row_left_cam),
    .shape_row_right(shape_row_right_cam),
    .shape_row_edge_count(shape_row_edge_count_cam),
    .shape_row_has_edge(shape_row_has_edge_cam),
    .shape_center_row_left(shape_center_row_left_cam),
    .shape_center_row_right(shape_center_row_right_cam),
    .shape_row_inner_left_gray(shape_row_inner_left_gray_cam),
    .shape_row_inner_mid_gray(shape_row_inner_mid_gray_cam),
    .shape_row_inner_right_gray(shape_row_inner_right_gray_cam),
    .shape_row_inner_left_valid(shape_row_inner_left_valid_cam),
    .shape_row_inner_mid_valid(shape_row_inner_mid_valid_cam),
    .shape_row_inner_right_valid(shape_row_inner_right_valid_cam),
    .shape_fg_row_left(shape_fg_row_left_cam),
    .shape_fg_row_right(shape_fg_row_right_cam),
    .shape_fg_valid_rows(shape_fg_valid_rows_cam),
    .shape_fg_min_x(shape_fg_min_x_cam),
    .shape_fg_max_x(shape_fg_max_x_cam),
    .shape_fg_min_y(shape_fg_min_y_cam),
    .shape_fg_max_y(shape_fg_max_y_cam),
    .shape_fg_width_min(shape_fg_width_min_cam),
    .shape_fg_width_max(shape_fg_width_max_cam),
    .shape_fg_top_width(shape_fg_top_width_cam),
    .shape_fg_bottom_width(shape_fg_bottom_width_cam),
    .shape_fg_col_left_rows(shape_fg_col_left_rows_cam),
    .shape_fg_col_mid_rows(shape_fg_col_mid_rows_cam),
    .shape_fg_col_right_rows(shape_fg_col_right_rows_cam),
    .shape_fg_gray_min(shape_fg_gray_min_cam),
    .shape_fg_gray_max(shape_fg_gray_max_cam),
    .shape_fg_row_left_gray(shape_fg_row_left_gray_cam),
    .shape_fg_row_right_gray(shape_fg_row_right_gray_cam),
    .shape_fg_run_len(shape_fg_run_len_cam),
    .shape_fg_run_gap(shape_fg_run_gap_cam),
    .shape_fg_top_width_sum(shape_fg_top_width_sum_cam),
    .shape_fg_top_width_rows(shape_fg_top_width_rows_cam),
    .shape_fg_bottom_width0(shape_fg_bottom_width0_cam),
    .shape_fg_bottom_width1(shape_fg_bottom_width1_cam),
    .shape_fg_bottom_width2(shape_fg_bottom_width2_cam),
    .shape_fg_bottom_width3(shape_fg_bottom_width3_cam),
    .shape_fg_curve_left_gray(shape_fg_curve_left_gray_cam),
    .shape_fg_curve_mid_gray(shape_fg_curve_mid_gray_cam),
    .shape_fg_curve_right_gray(shape_fg_curve_right_gray_cam),
    .shape_roi_y_active(shape_roi_y_active),
    .pixel0_in_shape_roi(pixel0_in_shape_roi),
    .pixel1_in_shape_roi(pixel1_in_shape_roi),
    .line_end_pulse(line_end_pulse),
    .roi_x0_local(roi_x0_local),
    .roi_x1_local(roi_x1_local),
    .roi_y_local(roi_y_local),
    .shape_roi_pair_x(shape_roi_pair_x),
    .shape_gray0(shape_gray0_cam),
    .shape_gray1(shape_gray1_cam),
    .shape_roi_gray_min_pair(shape_roi_gray_min_pair_cam),
    .shape_roi_gray_max_pair(shape_roi_gray_max_pair_cam),
    .shape_prev_line_gray0(shape_prev_line_gray0_cam),
    .shape_prev_line_gray1(shape_prev_line_gray1_cam),
    .shape_h_diff0(shape_h_diff0_cam),
    .shape_h_diff1(shape_h_diff1_cam),
    .shape_v_diff0(shape_v_diff0_cam),
    .shape_v_diff1(shape_v_diff1_cam),
    .shape_h_diff0_valid(shape_h_diff0_valid_cam),
    .shape_h_diff1_valid(shape_h_diff1_valid_cam),
    .shape_v_diff0_valid(shape_v_diff0_valid_cam),
    .shape_v_diff1_valid(shape_v_diff1_valid_cam),
    .shape_h_diff_pair_max(shape_h_diff_pair_max_cam),
    .shape_v_diff_pair_max(shape_v_diff_pair_max_cam),
    .shape_inner_row_sample_valid(shape_inner_row_sample_valid_cam),
    .shape_inner_row_min_gray(shape_inner_row_min_gray_cam),
    .shape_inner_row_max_gray(shape_inner_row_max_gray_cam),
    .shape_inner_row_lc_diff(shape_inner_row_lc_diff_cam),
    .shape_inner_row_cr_diff(shape_inner_row_cr_diff_cam),
    .shape_inner_row_lr_diff(shape_inner_row_lr_diff_cam),
    .shape_inner_row_grad_sum(shape_inner_row_grad_sum_cam),
    .shape_inner_row_cylinder_center_like(shape_inner_row_cylinder_center_like_cam),
    .shape_inner_row_cylinder_like(shape_inner_row_cylinder_like_cam),
    .shape_inner_row_cube_like(shape_inner_row_cube_like_cam),
    .shape_h_edge0(shape_h_edge0_cam),
    .shape_h_edge1(shape_h_edge1_cam),
    .shape_v_edge0(shape_v_edge0_cam),
    .shape_v_edge1(shape_v_edge1_cam),
    .shape_roi_pixel_inc(shape_roi_pixel_inc_cam),
    .shape_h_edge_inc(shape_h_edge_inc_cam),
    .shape_edge_hit_inc(shape_edge_hit_inc_cam),
    .shape_h_edge_left_x(shape_h_edge_left_x_cam),
    .shape_h_edge_right_x(shape_h_edge_right_x_cam),
    .shape_h_edge0_center_left(shape_h_edge0_center_left_cam),
    .shape_h_edge1_center_left(shape_h_edge1_center_left_cam),
    .shape_h_edge0_center_right(shape_h_edge0_center_right_cam),
    .shape_h_edge1_center_right(shape_h_edge1_center_right_cam),
    .shape_row_width_eval(shape_row_width_eval_cam),
    .shape_row_valid_eval(shape_row_valid_eval_cam),
    .shape_center_row_width_eval(shape_center_row_width_eval_cam),
    .shape_center_row_valid_eval(shape_center_row_valid_eval_cam),
    .shape_preview_wr_addr(shape_preview_wr_addr_cam),
    .shape_preview_rgb444(shape_preview_rgb444_cam),
    .shape_bg_grid_x(shape_bg_grid_x_cam),
    .shape_bg_grid_y(shape_bg_grid_y_cam),
    .shape_bg_grid_addr(shape_bg_grid_addr_cam),
    .shape_bg_rgb_diff(shape_bg_rgb_diff_cam),
    .shape_cur_r444(shape_cur_r444_cam),
    .shape_cur_g444(shape_cur_g444_cam),
    .shape_cur_b444(shape_cur_b444_cam),
    .shape_bg_r444(shape_bg_r444_cam),
    .shape_bg_g444(shape_bg_g444_cam),
    .shape_bg_b444(shape_bg_b444_cam),
    .shape_shadow_drop_r(shape_shadow_drop_r_cam),
    .shape_shadow_drop_g(shape_shadow_drop_g_cam),
    .shape_shadow_drop_b(shape_shadow_drop_b_cam),
    .shape_shadow_drop_sum(shape_shadow_drop_sum_cam),
    .shape_shadow_cur_sum(shape_shadow_cur_sum_cam),
    .shape_shadow_darker(shape_shadow_darker_cam),
    .shape_shadow_balanced(shape_shadow_balanced_cam),
    .shape_shadow_like(shape_shadow_like_cam),
    .shape_preview_in_shape_roi(shape_preview_in_shape_roi_cam),
    .shape_fg_pixel(shape_fg_pixel_cam),
    .shape_fg_row_width_eval(shape_fg_row_width_eval_cam),
    .shape_fg_bbox_w(shape_fg_bbox_w_cam),
    .shape_fg_bbox_h(shape_fg_bbox_h_cam),
    .shape_fg_width_range(shape_fg_width_range_cam),
    .shape_fg_top_bottom_delta(shape_fg_top_bottom_delta_cam),
    .shape_fg_col_side_min(shape_fg_col_side_min_cam),
    .shape_fg_col_center_delta(shape_fg_col_center_delta_cam),
    .shape_fg_col_lr_diff(shape_fg_col_lr_diff_cam),
    .shape_fg_gray_range(shape_fg_gray_range_cam),
    .shape_fg_row_lr_gray_diff(shape_fg_row_lr_gray_diff_cam),
    .shape_fg_run_len_next(shape_fg_run_len_next_cam),
    .shape_fg_bottom_width_sum(shape_fg_bottom_width_sum_cam),
    .shape_fg_top_width_avg(shape_fg_top_width_avg_cam),
    .shape_fg_bottom_width_avg(shape_fg_bottom_width_avg_cam),
    .shape_fg_top_bottom_avg_delta(shape_fg_top_bottom_avg_delta_cam),
    .shape_fg_curve_lc_diff(shape_fg_curve_lc_diff_cam),
    .shape_fg_curve_cr_diff(shape_fg_curve_cr_diff_cam),
    .shape_fg_curve_lr_diff(shape_fg_curve_lr_diff_cam),
    .shape_fg_curve_grad_sum(shape_fg_curve_grad_sum_cam)
);

shape_classifier #(
    .SHAPE_MIN_VALID_ROWS(SHAPE_MIN_VALID_ROWS),
    .SHAPE_MIN_ROW_WIDTH(SHAPE_MIN_ROW_WIDTH),
    .SHAPE_MIN_BBOX_W(SHAPE_MIN_BBOX_W),
    .SHAPE_MIN_BBOX_H(SHAPE_MIN_BBOX_H),
    .SHAPE_WIDTH5_CYL_MIN(SHAPE_WIDTH5_CYL_MIN),
    .SHAPE_WIDTH5_CUBE_MIN(SHAPE_WIDTH5_CUBE_MIN),
    .SHAPE_WIDTH5_VALID_MAX(SHAPE_WIDTH5_VALID_MAX),
    .SHAPE_WIDTH_RANGE_MAX(SHAPE_WIDTH_RANGE_MAX),
    .SHAPE_MIN_FG_PIXELS(SHAPE_MIN_FG_PIXELS),
    .SHAPE_MOTION_WIDTH5_DELTA(SHAPE_MOTION_WIDTH5_DELTA),
    .SHAPE_MOTION_BBOX_DELTA(SHAPE_MOTION_BBOX_DELTA),
    .SHAPE_MOTION_ROWS_DELTA(SHAPE_MOTION_ROWS_DELTA),
    .SHAPE_MOTION_PIXELS_DELTA(SHAPE_MOTION_PIXELS_DELTA)
) u_shape_classifier (
    .shape_bg_valid(shape_bg_valid_cam),
    .shape_bg_learn(shape_bg_learn_cam),
    .shape_metric_valid(shape_metric_valid_cam),
    .shape_valid_rows_filt(shape_valid_rows_filt_cam),
    .shape_bbox_w_filt(shape_bbox_w_filt_cam),
    .shape_bbox_h_filt(shape_bbox_h_filt_cam),
    .shape_width_max_filt(shape_width_max_filt_cam),
    .shape_seg_rows(shape_seg_rows_cam),
    .shape_seg_min_x(shape_seg_min_x_cam),
    .shape_seg_max_x(shape_seg_max_x_cam),
    .shape_seg_min_y(shape_seg_min_y_cam),
    .shape_seg_max_y(shape_seg_max_y_cam),
    .shape_seg_width_max(shape_seg_width_max_cam),
    .shape_best_rows(shape_best_rows_cam),
    .shape_best_min_x(shape_best_min_x_cam),
    .shape_best_max_x(shape_best_max_x_cam),
    .shape_best_min_y(shape_best_min_y_cam),
    .shape_best_max_y(shape_best_max_y_cam),
    .shape_best_width_max(shape_best_width_max_cam),
    .shape_motion_prev_valid(shape_motion_prev_valid_cam),
    .shape_motion_prev_width5(shape_motion_prev_width5_cam),
    .shape_motion_prev_bbox_w(shape_motion_prev_bbox_w_cam),
    .shape_motion_prev_bbox_h(shape_motion_prev_bbox_h_cam),
    .shape_motion_prev_valid_rows(shape_motion_prev_valid_rows_cam),
    .shape_motion_prev_pixel_count(shape_motion_prev_pixel_count_cam),
    .shape_fg_valid_rows(shape_fg_valid_rows_cam),
    .shape_fg_bbox_w(shape_fg_bbox_w_cam),
    .shape_fg_bbox_h(shape_fg_bbox_h_cam),
    .shape_fg_pixel_count(shape_fg_pixel_count_cam),
    .shape_fg_width_range(shape_fg_width_range_cam),
    .shape_fg_top_width_avg(shape_fg_top_width_avg_cam),
    .shape_size_valid(shape_size_valid_next),
    .shape_valid_rows_metric(shape_valid_rows_metric_next),
    .shape_bbox_w_metric(shape_bbox_w_metric_next),
    .shape_bbox_h_metric(shape_bbox_h_metric_next),
    .shape_width_max_metric(shape_width_max_metric_next),
    .shape_motion_large(shape_motion_large_next),
    .shape_candidate_id(shape_candidate_id_next),
    .shape_candidate_valid(shape_candidate_valid_next)
);

shape_page_ctrl #(
    .BUTTON_DEBOUNCE_MAX(SHAPE_PAGE_BTN_DEBOUNCE_MAX),
    .BG_LEARN_FRAMES(SHAPE_BG_LEARN_FRAMES)
) u_shape_page_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .frame_done(frame_done_pulse),
    .shape_page_button(shape_page_button),
    .shape_page(shape_page_cam),
    .shape_page_enter(shape_page_enter_cam),
    .bg_learn(shape_bg_learn_cam),
    .bg_valid(shape_bg_valid_cam)
);

assign frame_done_pulse = ({rgb_vs_d, rgb_vs} == 2'b01);
assign shape_timer_start_cam_pulse =
    shape_page_cam &&
    shape_fg_sample_valid_cam &&
    shape_fg_sample_pixel_cam &&
    !shape_timer_running &&
    !shape_valid_cam;
assign shape_timer_stop_cam_pulse =
    frame_done_pulse &&
    shape_timer_running &&
    shape_candidate_valid_next;
assign shape_timer_cancel_cam_pulse =
    frame_done_pulse &&
    shape_timer_running &&
    !shape_candidate_valid_next;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rgb_vs_d <= 1'b0;
        rgb_de_d <= 1'b0;
        color_x <= 12'd0;
        color_y <= 11'd0;
        shape_id_cam <= SHAPE_UNKNOWN;
        shape_valid_cam <= 1'b0;
        shape_display_id_cam <= SHAPE_UNKNOWN;
        shape_display_valid_cam <= 1'b0;
        shape_candidate_prev_cam <= SHAPE_UNKNOWN;
        shape_candidate_prev_valid_cam <= 1'b0;
        shape_candidate_streak_cam <= 2'd0;
        shape_invalid_frames_cam <= 3'd0;
        shape_motion_prev_valid_cam <= 1'b0;
        shape_motion_prev_width5_cam <= 8'd0;
        shape_motion_prev_bbox_w_cam <= 8'd0;
        shape_motion_prev_bbox_h_cam <= 8'd0;
        shape_motion_prev_valid_rows_cam <= 8'd0;
        shape_motion_prev_pixel_count_cam <= 13'd0;
        shape_prev_gray_cam <= 8'd0;
        shape_prev_gray_valid_cam <= 1'b0;
        shape_row_left_cam <= 10'h3FF;
        shape_row_right_cam <= 10'd0;
        shape_center_row_left_cam <= 10'h3FF;
        shape_center_row_right_cam <= 10'd0;
        shape_row_edge_count_cam <= 8'd0;
        shape_row_has_edge_cam <= 1'b0;
        shape_row_roi_hit_cam <= 1'b0;
        shape_seg_active_cam <= 1'b0;
        shape_seg_gap_cam <= 2'd0;
        shape_seg_rows_cam <= 8'd0;
        shape_seg_min_x_cam <= 10'h3FF;
        shape_seg_max_x_cam <= 10'd0;
        shape_seg_min_y_cam <= 10'h3FF;
        shape_seg_max_y_cam <= 10'd0;
        shape_seg_width_min_cam <= 10'h3FF;
        shape_seg_width_max_cam <= 10'd0;
        shape_seg_top_width_cam <= 10'd0;
        shape_seg_bottom_width_cam <= 10'd0;
        shape_best_rows_cam <= 8'd0;
        shape_best_min_x_cam <= 10'h3FF;
        shape_best_max_x_cam <= 10'd0;
        shape_best_min_y_cam <= 10'h3FF;
        shape_best_max_y_cam <= 10'd0;
        shape_best_width_min_cam <= 10'h3FF;
        shape_best_width_max_cam <= 10'd0;
        shape_best_top_width_cam <= 10'd0;
        shape_best_bottom_width_cam <= 10'd0;
        shape_frame_count_cam <= 11'd0;
        shape_roi_hit_pixels_cam <= 11'd0;
        shape_roi_hit_rows_cam <= 11'd0;
        shape_edge_hit_pixels_cam <= 11'd0;
        shape_rows_any_edge_cam <= 11'd0;
        shape_rows_two_edges_cam <= 11'd0;
        shape_edge_count_max_cam <= 11'd0;
        shape_gray_min_cam <= 8'hFF;
        shape_gray_max_cam <= 8'd0;
        shape_h_diff_max_cam <= 8'd0;
        shape_v_diff_max_cam <= 8'd0;
        shape_inner_gray_min_cam <= 8'hFF;
        shape_inner_gray_max_cam <= 8'd0;
        shape_inner_grad_max_cam <= 10'd0;
        shape_inner_lr_diff_max_cam <= 8'd0;
        shape_inner_sample_rows_cam <= 8'd0;
        shape_inner_cylinder_rows_cam <= 8'd0;
        shape_inner_cube_rows_cam <= 8'd0;
        shape_row_inner_left_gray_cam <= 8'd0;
        shape_row_inner_mid_gray_cam <= 8'd0;
        shape_row_inner_right_gray_cam <= 8'd0;
        shape_row_inner_left_valid_cam <= 1'b0;
        shape_row_inner_mid_valid_cam <= 1'b0;
        shape_row_inner_right_valid_cam <= 1'b0;
        shape_min_x_cam <= 10'h3FF;
        shape_max_x_cam <= 10'd0;
        shape_min_y_cam <= 10'h3FF;
        shape_max_y_cam <= 10'd0;
        shape_width_min_cam <= 10'h3FF;
        shape_width_max_cam <= 10'd0;
        shape_width_sum_cam <= 17'd0;
        shape_width_delta_sum_cam <= 17'd0;
        shape_valid_rows_cam <= 8'd0;
        shape_metric_valid_cam <= 1'b0;
        shape_valid_rows_filt_cam <= 8'd0;
        shape_bbox_w_filt_cam <= 10'd0;
        shape_bbox_h_filt_cam <= 10'd0;
        shape_width_max_filt_cam <= 10'd0;
        shape_top_width_cam <= 10'd0;
        shape_bottom_width_cam <= 10'd0;
        shape_prev_row_width_cam <= 10'd0;
        shape_prev_row_width_valid_cam <= 1'b0;
        shape_top_edge_bin0_cam <= 10'h3FF;
        shape_top_edge_bin1_cam <= 10'h3FF;
        shape_top_edge_bin2_cam <= 10'h3FF;
        shape_top_edge_bin3_cam <= 10'h3FF;
        shape_top_edge_bin4_cam <= 10'h3FF;
        shape_top_edge_bin5_cam <= 10'h3FF;
        shape_top_edge_bin6_cam <= 10'h3FF;
        shape_top_edge_bin7_cam <= 10'h3FF;
        shape_top_edge_bin8_cam <= 10'h3FF;
        shape_top_edge_bin9_cam <= 10'h3FF;
        shape_preview_x_div_cam <= 3'd0;
        shape_preview_y_div_cam <= 4'd0;
        shape_preview_wr_x_cam <= 8'd0;
        shape_preview_wr_y_cam <= 7'd0;
        shape_preview_capture_line_cam <= 1'b1;
        shape_fg_addr_valid_cam <= 1'b0;
        shape_fg_addr_bg_valid_cam <= 1'b0;
        shape_fg_addr_in_roi_cam <= 1'b0;
        shape_fg_addr_bg_grid_addr_cam <= 11'd0;
        shape_fg_addr_rgb444_cam <= 12'd0;
        shape_fg_addr_x_cam <= 8'd0;
        shape_fg_addr_gray_cam <= 8'd0;
        shape_fg_addr_top_zone_cam <= 1'b0;
        shape_fg_addr_mid_zone_cam <= 1'b0;
        shape_fg_addr_corner_zone_cam <= 1'b0;
        shape_fg_addr_center_zone_cam <= 1'b0;
        shape_fg_addr_col_left_cam <= 1'b0;
        shape_fg_addr_col_mid_cam <= 1'b0;
        shape_fg_addr_col_right_cam <= 1'b0;
        shape_fg_eval_valid_cam <= 1'b0;
        shape_fg_eval_bg_valid_cam <= 1'b0;
        shape_fg_eval_in_roi_cam <= 1'b0;
        shape_fg_eval_rgb444_cam <= 12'd0;
        shape_fg_eval_bg_rgb444_cam <= 12'd0;
        shape_fg_eval_x_cam <= 8'd0;
        shape_fg_eval_gray_cam <= 8'd0;
        shape_fg_eval_top_zone_cam <= 1'b0;
        shape_fg_eval_mid_zone_cam <= 1'b0;
        shape_fg_eval_corner_zone_cam <= 1'b0;
        shape_fg_eval_center_zone_cam <= 1'b0;
        shape_fg_eval_col_left_cam <= 1'b0;
        shape_fg_eval_col_mid_cam <= 1'b0;
        shape_fg_eval_col_right_cam <= 1'b0;
        shape_fg_sample_valid_cam <= 1'b0;
        shape_fg_sample_pixel_cam <= 1'b0;
        shape_fg_sample_x_cam <= 8'd0;
        shape_fg_sample_y_cam <= 7'd0;
        shape_fg_sample_gray_cam <= 8'd0;
        shape_fg_sample_top_zone_cam <= 1'b0;
        shape_fg_sample_mid_zone_cam <= 1'b0;
        shape_fg_sample_corner_zone_cam <= 1'b0;
        shape_fg_sample_center_zone_cam <= 1'b0;
        shape_fg_sample_col_left_cam <= 1'b0;
        shape_fg_sample_col_mid_cam <= 1'b0;
        shape_fg_sample_col_right_cam <= 1'b0;
        shape_fg_row_left_cam <= 8'hFF;
        shape_fg_row_right_cam <= 8'd0;
        shape_fg_row_hit_cam <= 1'b0;
        shape_fg_row_left_gray_cam <= 8'd0;
        shape_fg_row_right_gray_cam <= 8'd0;
        shape_fg_row_prev_gray_cam <= 8'd0;
        shape_fg_row_prev_hit_cam <= 1'b0;
        shape_fg_run_active_cam <= 1'b0;
        shape_fg_run_gap_cam <= 2'd0;
        shape_fg_run_left_cam <= 8'd0;
        shape_fg_run_right_cam <= 8'd0;
        shape_fg_run_len_cam <= 8'd0;
        shape_fg_best_len_cam <= 8'd0;
        shape_fg_run_left_gray_cam <= 8'd0;
        shape_fg_run_right_gray_cam <= 8'd0;
        shape_fg_min_x_cam <= 8'hFF;
        shape_fg_max_x_cam <= 8'd0;
        shape_fg_min_y_cam <= 7'h7F;
        shape_fg_max_y_cam <= 7'd0;
        shape_fg_width_min_cam <= 8'hFF;
        shape_fg_width_max_cam <= 8'd0;
        shape_fg_top_width_cam <= 8'd0;
        shape_fg_bottom_width_cam <= 8'd0;
        shape_fg_valid_rows_cam <= 8'd0;
        shape_fg_pixel_count_cam <= 13'd0;
        shape_fg_col_left_rows_cam <= 8'd0;
        shape_fg_col_mid_rows_cam <= 8'd0;
        shape_fg_col_right_rows_cam <= 8'd0;
        shape_fg_top_count_cam <= 12'd0;
        shape_fg_mid_count_cam <= 12'd0;
        shape_fg_bottom_count_cam <= 12'd0;
        shape_fg_corner_count_cam <= 12'd0;
        shape_fg_center_count_cam <= 12'd0;
        shape_fg_gray_min_cam <= 8'hFF;
        shape_fg_gray_max_cam <= 8'd0;
        shape_fg_grad_max_cam <= 8'd0;
        shape_fg_lr_gray_diff_max_cam <= 8'd0;
        shape_fg_top_width_sum_cam <= 11'd0;
        shape_fg_top_width_rows_cam <= 3'd0;
        shape_fg_bottom_width0_cam <= 8'd0;
        shape_fg_bottom_width1_cam <= 8'd0;
        shape_fg_bottom_width2_cam <= 8'd0;
        shape_fg_bottom_width3_cam <= 8'd0;
        shape_fg_curve_left_gray_cam <= 8'd0;
        shape_fg_curve_mid_gray_cam <= 8'd0;
        shape_fg_curve_right_gray_cam <= 8'd0;
        shape_fg_curve_left_valid_cam <= 1'b0;
        shape_fg_curve_mid_valid_cam <= 1'b0;
        shape_fg_curve_right_valid_cam <= 1'b0;
        shape_fg_curve_grad_max_cam <= 10'd0;
        shape_fg_curve_lr_diff_max_cam <= 8'd0;
        shape_fg_curve_sample_rows_cam <= 8'd0;
    end else begin
        // Main camera-domain recognition process.
        // While rgb_de is high it scans the current frame once:
        // - updates grayscale/edge statistics inside SHAPE_ROI
        // - writes the small HDMI preview RAM
        // At frame_done_pulse it freezes the frame metrics, applies temporal
        // stability checks, and clears accumulators for the next frame.
        rgb_vs_d <= rgb_vs;
        rgb_de_d <= rgb_de;

        if (frame_done_pulse) begin
            if (shape_frame_count_cam >= 11'd999)
                shape_frame_count_cam <= 11'd0;
            else
                shape_frame_count_cam <= shape_frame_count_cam + 11'd1;

            if (shape_page_enter_cam || shape_bg_learn_cam) begin
                shape_motion_prev_valid_cam <= 1'b0;
                shape_motion_prev_width5_cam <= 8'd0;
                shape_motion_prev_bbox_w_cam <= 8'd0;
                shape_motion_prev_bbox_h_cam <= 8'd0;
                shape_motion_prev_valid_rows_cam <= 8'd0;
                shape_motion_prev_pixel_count_cam <= 13'd0;
            end else begin
                shape_motion_prev_valid_cam <= shape_bg_valid_cam;
                shape_motion_prev_width5_cam <= shape_fg_top_width_avg_cam;
                shape_motion_prev_bbox_w_cam <= shape_fg_bbox_w_cam;
                shape_motion_prev_bbox_h_cam <= shape_fg_bbox_h_cam;
                shape_motion_prev_valid_rows_cam <= shape_fg_valid_rows_cam;
                shape_motion_prev_pixel_count_cam <= shape_fg_pixel_count_cam;
            end

            if (shape_size_valid_next) begin
                shape_metric_valid_cam <= 1'b1;
                shape_valid_rows_filt_cam <= shape_valid_rows_metric_next;
                shape_bbox_w_filt_cam <= shape_bbox_w_metric_next;
                shape_bbox_h_filt_cam <= shape_bbox_h_metric_next;
                shape_width_max_filt_cam <= shape_width_max_metric_next;
            end else if (shape_invalid_frames_cam >= 3'd7) begin
                shape_metric_valid_cam <= 1'b0;
                shape_valid_rows_filt_cam <= 8'd0;
                shape_bbox_w_filt_cam <= 10'd0;
                shape_bbox_h_filt_cam <= 10'd0;
                shape_width_max_filt_cam <= 10'd0;
            end

            // Fast shape result follows metric 5 directly for latency timing.
            if (shape_candidate_valid_next) begin
                shape_id_cam <= shape_candidate_id_next;
                shape_valid_cam <= 1'b1;
            end else begin
                shape_id_cam <= SHAPE_UNKNOWN;
                shape_valid_cam <= 1'b0;
            end

            // HDMI shape result waits for three matching frames.
            // This stabilizes only the visible result; the latency timer stays on the fast path above.
            if (shape_candidate_valid_next) begin
                shape_invalid_frames_cam <= 3'd0;
                if (shape_candidate_prev_valid_cam &&
                    (shape_candidate_id_next == shape_candidate_prev_cam)) begin
                    if (shape_candidate_streak_cam >= 2'd2) begin
                        shape_display_id_cam <= shape_candidate_id_next;
                        shape_display_valid_cam <= 1'b1;
                    end
                    if (shape_candidate_streak_cam != 2'd3)
                        shape_candidate_streak_cam <= shape_candidate_streak_cam + 2'd1;
                end else begin
                    shape_candidate_streak_cam <= 2'd1;
                end
                shape_candidate_prev_cam <= shape_candidate_id_next;
                shape_candidate_prev_valid_cam <= 1'b1;
            end else begin
                shape_candidate_prev_valid_cam <= 1'b0;
                shape_candidate_streak_cam <= 2'd0;
                if (shape_motion_large_next || (shape_invalid_frames_cam >= 3'd1)) begin
                    shape_display_id_cam <= SHAPE_UNKNOWN;
                    shape_display_valid_cam <= 1'b0;
                end
                if (shape_motion_large_next)
                    shape_invalid_frames_cam <= 3'd2;
                else if (shape_invalid_frames_cam != 3'd7)
                    shape_invalid_frames_cam <= shape_invalid_frames_cam + 3'd1;
            end

            color_x <= 12'd0;
            color_y <= 11'd0;
            shape_prev_gray_valid_cam <= 1'b0;
            shape_row_left_cam <= 10'h3FF;
            shape_row_right_cam <= 10'd0;
            shape_center_row_left_cam <= 10'h3FF;
            shape_center_row_right_cam <= 10'd0;
            shape_row_edge_count_cam <= 8'd0;
            shape_row_has_edge_cam <= 1'b0;
            shape_row_roi_hit_cam <= 1'b0;
            shape_seg_active_cam <= 1'b0;
            shape_seg_gap_cam <= 2'd0;
            shape_seg_rows_cam <= 8'd0;
            shape_seg_min_x_cam <= 10'h3FF;
            shape_seg_max_x_cam <= 10'd0;
            shape_seg_min_y_cam <= 10'h3FF;
            shape_seg_max_y_cam <= 10'd0;
            shape_seg_width_min_cam <= 10'h3FF;
            shape_seg_width_max_cam <= 10'd0;
            shape_seg_top_width_cam <= 10'd0;
            shape_seg_bottom_width_cam <= 10'd0;
            shape_best_rows_cam <= 8'd0;
            shape_best_min_x_cam <= 10'h3FF;
            shape_best_max_x_cam <= 10'd0;
            shape_best_min_y_cam <= 10'h3FF;
            shape_best_max_y_cam <= 10'd0;
            shape_best_width_min_cam <= 10'h3FF;
            shape_best_width_max_cam <= 10'd0;
            shape_best_top_width_cam <= 10'd0;
            shape_best_bottom_width_cam <= 10'd0;
            shape_roi_hit_pixels_cam <= 11'd0;
            shape_roi_hit_rows_cam <= 11'd0;
            shape_edge_hit_pixels_cam <= 11'd0;
            shape_rows_any_edge_cam <= 11'd0;
            shape_rows_two_edges_cam <= 11'd0;
            shape_edge_count_max_cam <= 11'd0;
            shape_gray_min_cam <= 8'hFF;
            shape_gray_max_cam <= 8'd0;
            shape_h_diff_max_cam <= 8'd0;
            shape_v_diff_max_cam <= 8'd0;
            shape_inner_gray_min_cam <= 8'hFF;
            shape_inner_gray_max_cam <= 8'd0;
            shape_inner_grad_max_cam <= 10'd0;
            shape_inner_lr_diff_max_cam <= 8'd0;
            shape_inner_sample_rows_cam <= 8'd0;
            shape_inner_cylinder_rows_cam <= 8'd0;
            shape_inner_cube_rows_cam <= 8'd0;
            shape_row_inner_left_gray_cam <= 8'd0;
            shape_row_inner_mid_gray_cam <= 8'd0;
            shape_row_inner_right_gray_cam <= 8'd0;
            shape_row_inner_left_valid_cam <= 1'b0;
            shape_row_inner_mid_valid_cam <= 1'b0;
            shape_row_inner_right_valid_cam <= 1'b0;
            shape_min_x_cam <= 10'h3FF;
            shape_max_x_cam <= 10'd0;
            shape_min_y_cam <= 10'h3FF;
            shape_max_y_cam <= 10'd0;
            shape_width_min_cam <= 10'h3FF;
            shape_width_max_cam <= 10'd0;
            shape_width_sum_cam <= 17'd0;
            shape_width_delta_sum_cam <= 17'd0;
            shape_valid_rows_cam <= 8'd0;
            shape_top_width_cam <= 10'd0;
            shape_bottom_width_cam <= 10'd0;
            shape_prev_row_width_cam <= 10'd0;
            shape_prev_row_width_valid_cam <= 1'b0;
            shape_top_edge_bin0_cam <= 10'h3FF;
            shape_top_edge_bin1_cam <= 10'h3FF;
            shape_top_edge_bin2_cam <= 10'h3FF;
            shape_top_edge_bin3_cam <= 10'h3FF;
            shape_top_edge_bin4_cam <= 10'h3FF;
            shape_top_edge_bin5_cam <= 10'h3FF;
            shape_top_edge_bin6_cam <= 10'h3FF;
            shape_top_edge_bin7_cam <= 10'h3FF;
            shape_top_edge_bin8_cam <= 10'h3FF;
            shape_top_edge_bin9_cam <= 10'h3FF;
            shape_preview_x_div_cam <= 3'd0;
            shape_preview_y_div_cam <= 4'd0;
            shape_preview_wr_x_cam <= 8'd0;
            shape_preview_wr_y_cam <= 7'd0;
            shape_preview_capture_line_cam <= 1'b1;
            shape_fg_addr_valid_cam <= 1'b0;
            shape_fg_addr_bg_valid_cam <= 1'b0;
            shape_fg_addr_in_roi_cam <= 1'b0;
            shape_fg_addr_bg_grid_addr_cam <= 11'd0;
            shape_fg_addr_rgb444_cam <= 12'd0;
            shape_fg_addr_x_cam <= 8'd0;
            shape_fg_addr_gray_cam <= 8'd0;
            shape_fg_addr_top_zone_cam <= 1'b0;
            shape_fg_addr_mid_zone_cam <= 1'b0;
            shape_fg_addr_corner_zone_cam <= 1'b0;
            shape_fg_addr_center_zone_cam <= 1'b0;
            shape_fg_addr_col_left_cam <= 1'b0;
            shape_fg_addr_col_mid_cam <= 1'b0;
            shape_fg_addr_col_right_cam <= 1'b0;
            shape_fg_eval_valid_cam <= 1'b0;
            shape_fg_eval_bg_valid_cam <= 1'b0;
            shape_fg_eval_in_roi_cam <= 1'b0;
            shape_fg_eval_rgb444_cam <= 12'd0;
            shape_fg_eval_bg_rgb444_cam <= 12'd0;
            shape_fg_eval_x_cam <= 8'd0;
            shape_fg_eval_gray_cam <= 8'd0;
            shape_fg_eval_top_zone_cam <= 1'b0;
            shape_fg_eval_mid_zone_cam <= 1'b0;
            shape_fg_eval_corner_zone_cam <= 1'b0;
            shape_fg_eval_center_zone_cam <= 1'b0;
            shape_fg_eval_col_left_cam <= 1'b0;
            shape_fg_eval_col_mid_cam <= 1'b0;
            shape_fg_eval_col_right_cam <= 1'b0;
            shape_fg_sample_valid_cam <= 1'b0;
            shape_fg_sample_pixel_cam <= 1'b0;
            shape_fg_sample_x_cam <= 8'd0;
            shape_fg_sample_y_cam <= 7'd0;
            shape_fg_sample_gray_cam <= 8'd0;
            shape_fg_sample_top_zone_cam <= 1'b0;
            shape_fg_sample_mid_zone_cam <= 1'b0;
            shape_fg_sample_corner_zone_cam <= 1'b0;
            shape_fg_sample_center_zone_cam <= 1'b0;
            shape_fg_sample_col_left_cam <= 1'b0;
            shape_fg_sample_col_mid_cam <= 1'b0;
            shape_fg_sample_col_right_cam <= 1'b0;
            shape_fg_row_left_cam <= 8'hFF;
            shape_fg_row_right_cam <= 8'd0;
            shape_fg_row_hit_cam <= 1'b0;
            shape_fg_row_left_gray_cam <= 8'd0;
            shape_fg_row_right_gray_cam <= 8'd0;
            shape_fg_row_prev_gray_cam <= 8'd0;
            shape_fg_row_prev_hit_cam <= 1'b0;
            shape_fg_run_active_cam <= 1'b0;
            shape_fg_run_gap_cam <= 2'd0;
            shape_fg_run_left_cam <= 8'd0;
            shape_fg_run_right_cam <= 8'd0;
            shape_fg_run_len_cam <= 8'd0;
            shape_fg_best_len_cam <= 8'd0;
            shape_fg_run_left_gray_cam <= 8'd0;
            shape_fg_run_right_gray_cam <= 8'd0;
            shape_fg_min_x_cam <= 8'hFF;
            shape_fg_max_x_cam <= 8'd0;
            shape_fg_min_y_cam <= 7'h7F;
            shape_fg_max_y_cam <= 7'd0;
            shape_fg_width_min_cam <= 8'hFF;
            shape_fg_width_max_cam <= 8'd0;
            shape_fg_top_width_cam <= 8'd0;
            shape_fg_bottom_width_cam <= 8'd0;
            shape_fg_valid_rows_cam <= 8'd0;
            shape_fg_pixel_count_cam <= 13'd0;
            shape_fg_col_left_rows_cam <= 8'd0;
            shape_fg_col_mid_rows_cam <= 8'd0;
            shape_fg_col_right_rows_cam <= 8'd0;
            shape_fg_top_count_cam <= 12'd0;
            shape_fg_mid_count_cam <= 12'd0;
            shape_fg_bottom_count_cam <= 12'd0;
            shape_fg_corner_count_cam <= 12'd0;
            shape_fg_center_count_cam <= 12'd0;
            shape_fg_gray_min_cam <= 8'hFF;
            shape_fg_gray_max_cam <= 8'd0;
            shape_fg_grad_max_cam <= 8'd0;
            shape_fg_lr_gray_diff_max_cam <= 8'd0;
            shape_fg_top_width_sum_cam <= 11'd0;
            shape_fg_top_width_rows_cam <= 3'd0;
            shape_fg_bottom_width0_cam <= 8'd0;
            shape_fg_bottom_width1_cam <= 8'd0;
            shape_fg_bottom_width2_cam <= 8'd0;
            shape_fg_bottom_width3_cam <= 8'd0;
            shape_fg_curve_left_gray_cam <= 8'd0;
            shape_fg_curve_mid_gray_cam <= 8'd0;
            shape_fg_curve_right_gray_cam <= 8'd0;
            shape_fg_curve_left_valid_cam <= 1'b0;
            shape_fg_curve_mid_valid_cam <= 1'b0;
            shape_fg_curve_right_valid_cam <= 1'b0;
            shape_fg_curve_grad_max_cam <= 10'd0;
            shape_fg_curve_lr_diff_max_cam <= 8'd0;
            shape_fg_curve_sample_rows_cam <= 8'd0;
        end else begin
            shape_fg_addr_valid_cam <= 1'b0;
            shape_fg_eval_valid_cam <= 1'b0;
            shape_fg_sample_valid_cam <= 1'b0;

            if (shape_fg_sample_valid_cam) begin
                if (shape_fg_sample_pixel_cam) begin
                    if (!shape_fg_run_active_cam) begin
                        shape_fg_run_active_cam <= 1'b1;
                        shape_fg_run_gap_cam <= 2'd0;
                        shape_fg_run_left_cam <= shape_fg_sample_x_cam;
                        shape_fg_run_right_cam <= shape_fg_sample_x_cam;
                        shape_fg_run_len_cam <= 8'd1;
                        shape_fg_run_left_gray_cam <= shape_fg_sample_gray_cam;
                        shape_fg_run_right_gray_cam <= shape_fg_sample_gray_cam;
                        if ((!shape_fg_row_hit_cam) || (shape_fg_best_len_cam == 8'd0)) begin
                            shape_fg_row_hit_cam <= 1'b1;
                            shape_fg_best_len_cam <= 8'd1;
                            shape_fg_row_left_cam <= shape_fg_sample_x_cam;
                            shape_fg_row_right_cam <= shape_fg_sample_x_cam;
                            shape_fg_row_left_gray_cam <= shape_fg_sample_gray_cam;
                            shape_fg_row_right_gray_cam <= shape_fg_sample_gray_cam;
                        end
                    end else begin
                        shape_fg_run_gap_cam <= 2'd0;
                        shape_fg_run_right_cam <= shape_fg_sample_x_cam;
                        shape_fg_run_right_gray_cam <= shape_fg_sample_gray_cam;
                        shape_fg_run_len_cam <= shape_fg_run_len_next_cam[7:0];
                        if (shape_fg_run_len_next_cam > {1'b0, shape_fg_best_len_cam}) begin
                            shape_fg_row_hit_cam <= 1'b1;
                            shape_fg_best_len_cam <= shape_fg_run_len_next_cam[7:0];
                            shape_fg_row_left_cam <= shape_fg_run_left_cam;
                            shape_fg_row_right_cam <= shape_fg_sample_x_cam;
                            shape_fg_row_left_gray_cam <= shape_fg_run_left_gray_cam;
                            shape_fg_row_right_gray_cam <= shape_fg_sample_gray_cam;
                        end
                    end
                    if (shape_fg_row_prev_hit_cam &&
                        (abs_diff_u8(shape_fg_sample_gray_cam, shape_fg_row_prev_gray_cam) > shape_fg_grad_max_cam))
                        shape_fg_grad_max_cam <= abs_diff_u8(shape_fg_sample_gray_cam, shape_fg_row_prev_gray_cam);
                    shape_fg_row_prev_gray_cam <= shape_fg_sample_gray_cam;
                    shape_fg_row_prev_hit_cam <= 1'b1;
                    if (shape_fg_sample_col_left_cam) begin
                        shape_fg_curve_left_gray_cam <= shape_fg_sample_gray_cam;
                        shape_fg_curve_left_valid_cam <= 1'b1;
                    end
                    if (shape_fg_sample_col_mid_cam) begin
                        shape_fg_curve_mid_gray_cam <= shape_fg_sample_gray_cam;
                        shape_fg_curve_mid_valid_cam <= 1'b1;
                    end
                    if (shape_fg_sample_col_right_cam) begin
                        shape_fg_curve_right_gray_cam <= shape_fg_sample_gray_cam;
                        shape_fg_curve_right_valid_cam <= 1'b1;
                    end
                    if (shape_fg_pixel_count_cam != 13'h1FFF)
                        shape_fg_pixel_count_cam <= shape_fg_pixel_count_cam + 13'd1;
                    if (shape_fg_sample_gray_cam < shape_fg_gray_min_cam)
                        shape_fg_gray_min_cam <= shape_fg_sample_gray_cam;
                    if (shape_fg_sample_gray_cam > shape_fg_gray_max_cam)
                        shape_fg_gray_max_cam <= shape_fg_sample_gray_cam;
                    if (shape_fg_sample_top_zone_cam &&
                        (shape_fg_top_count_cam != 12'hFFF))
                        shape_fg_top_count_cam <= shape_fg_top_count_cam + 12'd1;
                    else if (shape_fg_sample_mid_zone_cam &&
                             (shape_fg_mid_count_cam != 12'hFFF))
                        shape_fg_mid_count_cam <= shape_fg_mid_count_cam + 12'd1;
                    else if (shape_fg_bottom_count_cam != 12'hFFF)
                        shape_fg_bottom_count_cam <= shape_fg_bottom_count_cam + 12'd1;
                    if (shape_fg_sample_corner_zone_cam &&
                        (shape_fg_corner_count_cam != 12'hFFF))
                        shape_fg_corner_count_cam <= shape_fg_corner_count_cam + 12'd1;
                    if (shape_fg_sample_center_zone_cam &&
                        (shape_fg_center_count_cam != 12'hFFF))
                        shape_fg_center_count_cam <= shape_fg_center_count_cam + 12'd1;
                end else if (shape_fg_run_active_cam) begin
                    if (shape_fg_run_gap_cam < SHAPE_FG_RUN_GAP_MAX) begin
                        shape_fg_run_gap_cam <= shape_fg_run_gap_cam + 2'd1;
                    end else begin
                        shape_fg_run_active_cam <= 1'b0;
                        shape_fg_run_gap_cam <= 2'd0;
                        shape_fg_run_len_cam <= 8'd0;
                    end
                end
            end

            if (shape_fg_addr_valid_cam) begin
                shape_fg_eval_valid_cam <= 1'b1;
                shape_fg_eval_bg_valid_cam <= shape_fg_addr_bg_valid_cam;
                shape_fg_eval_in_roi_cam <= shape_fg_addr_in_roi_cam;
                shape_fg_eval_rgb444_cam <= shape_fg_addr_rgb444_cam;
                shape_fg_eval_bg_rgb444_cam <= shape_bg_grid_ram[shape_fg_addr_bg_grid_addr_cam];
                shape_fg_eval_x_cam <= shape_fg_addr_x_cam;
                shape_fg_eval_gray_cam <= shape_fg_addr_gray_cam;
                shape_fg_eval_top_zone_cam <= shape_fg_addr_top_zone_cam;
                shape_fg_eval_mid_zone_cam <= shape_fg_addr_mid_zone_cam;
                shape_fg_eval_corner_zone_cam <= shape_fg_addr_corner_zone_cam;
                shape_fg_eval_center_zone_cam <= shape_fg_addr_center_zone_cam;
                shape_fg_eval_col_left_cam <= shape_fg_addr_col_left_cam;
                shape_fg_eval_col_mid_cam <= shape_fg_addr_col_mid_cam;
                shape_fg_eval_col_right_cam <= shape_fg_addr_col_right_cam;
            end

            if (shape_fg_eval_valid_cam) begin
                shape_fg_sample_valid_cam <= 1'b1;
                shape_fg_sample_pixel_cam <= shape_fg_eval_pixel_next_cam;
                shape_fg_sample_x_cam <= shape_fg_eval_x_cam;
                shape_fg_sample_gray_cam <= shape_fg_eval_gray_cam;
                shape_fg_sample_top_zone_cam <= shape_fg_eval_top_zone_cam;
                shape_fg_sample_mid_zone_cam <= shape_fg_eval_mid_zone_cam;
                shape_fg_sample_corner_zone_cam <= shape_fg_eval_corner_zone_cam;
                shape_fg_sample_center_zone_cam <= shape_fg_eval_center_zone_cam;
                shape_fg_sample_col_left_cam <= shape_fg_eval_col_left_cam;
                shape_fg_sample_col_mid_cam <= shape_fg_eval_col_mid_cam;
                shape_fg_sample_col_right_cam <= shape_fg_eval_col_right_cam;
            end

            if (line_end_pulse) begin
                // End of one active video line: commit row-level measurements
                // into frame-level counters and reset row trackers.
                if (shape_row_roi_hit_cam) begin
                    if (shape_roi_hit_rows_cam != 11'd999)
                        shape_roi_hit_rows_cam <= shape_roi_hit_rows_cam + 11'd1;
                end
                if (shape_row_has_edge_cam) begin
                    if (shape_rows_any_edge_cam != 11'd2047)
                        shape_rows_any_edge_cam <= shape_rows_any_edge_cam + 11'd1;
                    if (shape_row_edge_count_cam > shape_edge_count_max_cam[7:0])
                        shape_edge_count_max_cam <= {3'd0, shape_row_edge_count_cam};
                end
                if (shape_row_edge_count_cam >= 8'd2) begin
                    if (shape_rows_two_edges_cam != 11'd2047)
                        shape_rows_two_edges_cam <= shape_rows_two_edges_cam + 11'd1;
                end

                if (shape_row_valid_eval_cam) begin
                    if (shape_valid_rows_cam == 8'd0) begin
                        shape_top_width_cam <= shape_row_width_eval_cam;
                        shape_min_y_cam <= roi_y_local;
                        shape_max_y_cam <= roi_y_local;
                    end else begin
                        if (roi_y_local < shape_min_y_cam)
                            shape_min_y_cam <= roi_y_local;
                        if (roi_y_local > shape_max_y_cam)
                            shape_max_y_cam <= roi_y_local;
                    end

                    shape_bottom_width_cam <= shape_row_width_eval_cam;
                    shape_valid_rows_cam <= shape_valid_rows_cam + 8'd1;
                    shape_width_sum_cam <= shape_width_sum_cam + {8'd0, shape_row_width_eval_cam};

                    if (shape_prev_row_width_valid_cam)
                        shape_width_delta_sum_cam <= shape_width_delta_sum_cam +
                            {7'd0, abs_diff_u10(shape_row_width_eval_cam, shape_prev_row_width_cam)};
                    shape_prev_row_width_cam <= shape_row_width_eval_cam;
                    shape_prev_row_width_valid_cam <= 1'b1;

                    if (shape_row_left_cam < shape_min_x_cam)
                        shape_min_x_cam <= shape_row_left_cam;
                    if (shape_row_right_cam > shape_max_x_cam)
                        shape_max_x_cam <= shape_row_right_cam;
                    if (shape_row_width_eval_cam < shape_width_min_cam)
                        shape_width_min_cam <= shape_row_width_eval_cam;
                    if (shape_row_width_eval_cam > shape_width_max_cam)
                        shape_width_max_cam <= shape_row_width_eval_cam;
                end

                if (shape_center_row_valid_eval_cam) begin
                    if (!shape_seg_active_cam) begin
                        shape_seg_active_cam <= 1'b1;
                        shape_seg_gap_cam <= 2'd0;
                        shape_seg_rows_cam <= 8'd1;
                        shape_seg_min_x_cam <= shape_center_row_left_cam;
                        shape_seg_max_x_cam <= shape_center_row_right_cam;
                        shape_seg_min_y_cam <= roi_y_local;
                        shape_seg_max_y_cam <= roi_y_local;
                        shape_seg_width_min_cam <= shape_center_row_width_eval_cam;
                        shape_seg_width_max_cam <= shape_center_row_width_eval_cam;
                        shape_seg_top_width_cam <= shape_center_row_width_eval_cam;
                        shape_seg_bottom_width_cam <= shape_center_row_width_eval_cam;
                    end else begin
                        shape_seg_gap_cam <= 2'd0;
                        if (shape_seg_rows_cam != 8'hFF)
                            shape_seg_rows_cam <= shape_seg_rows_cam + 8'd1;
                        if (shape_center_row_left_cam < shape_seg_min_x_cam)
                            shape_seg_min_x_cam <= shape_center_row_left_cam;
                        if (shape_center_row_right_cam > shape_seg_max_x_cam)
                            shape_seg_max_x_cam <= shape_center_row_right_cam;
                        if (roi_y_local < shape_seg_min_y_cam)
                            shape_seg_min_y_cam <= roi_y_local;
                        if (roi_y_local > shape_seg_max_y_cam)
                            shape_seg_max_y_cam <= roi_y_local;
                        if (shape_center_row_width_eval_cam < shape_seg_width_min_cam)
                            shape_seg_width_min_cam <= shape_center_row_width_eval_cam;
                        if (shape_center_row_width_eval_cam > shape_seg_width_max_cam)
                            shape_seg_width_max_cam <= shape_center_row_width_eval_cam;
                        shape_seg_bottom_width_cam <= shape_center_row_width_eval_cam;
                    end
                end else if (shape_seg_active_cam) begin
                    if (shape_seg_gap_cam < SHAPE_SEG_GAP_MAX) begin
                        shape_seg_gap_cam <= shape_seg_gap_cam + 2'd1;
                    end else begin
                        if (shape_seg_rows_cam > shape_best_rows_cam) begin
                            shape_best_rows_cam <= shape_seg_rows_cam;
                            shape_best_min_x_cam <= shape_seg_min_x_cam;
                            shape_best_max_x_cam <= shape_seg_max_x_cam;
                            shape_best_min_y_cam <= shape_seg_min_y_cam;
                            shape_best_max_y_cam <= shape_seg_max_y_cam;
                            shape_best_width_min_cam <= shape_seg_width_min_cam;
                            shape_best_width_max_cam <= shape_seg_width_max_cam;
                            shape_best_top_width_cam <= shape_seg_top_width_cam;
                            shape_best_bottom_width_cam <= shape_seg_bottom_width_cam;
                        end
                        shape_seg_active_cam <= 1'b0;
                        shape_seg_gap_cam <= 2'd0;
                        shape_seg_rows_cam <= 8'd0;
                        shape_seg_min_x_cam <= 10'h3FF;
                        shape_seg_max_x_cam <= 10'd0;
                        shape_seg_min_y_cam <= 10'h3FF;
                        shape_seg_max_y_cam <= 10'd0;
                        shape_seg_width_min_cam <= 10'h3FF;
                        shape_seg_width_max_cam <= 10'd0;
                        shape_seg_top_width_cam <= 10'd0;
                        shape_seg_bottom_width_cam <= 10'd0;
                    end
                end

                if (shape_center_row_valid_eval_cam && shape_inner_row_sample_valid_cam) begin
                    if (shape_inner_sample_rows_cam == 8'd0) begin
                        shape_inner_gray_min_cam <= shape_inner_row_min_gray_cam;
                        shape_inner_gray_max_cam <= shape_inner_row_max_gray_cam;
                    end else begin
                        if (shape_inner_row_min_gray_cam < shape_inner_gray_min_cam)
                            shape_inner_gray_min_cam <= shape_inner_row_min_gray_cam;
                        if (shape_inner_row_max_gray_cam > shape_inner_gray_max_cam)
                            shape_inner_gray_max_cam <= shape_inner_row_max_gray_cam;
                    end
                    if (shape_inner_row_grad_sum_cam > shape_inner_grad_max_cam)
                        shape_inner_grad_max_cam <= shape_inner_row_grad_sum_cam;
                    if (shape_inner_row_lr_diff_cam > shape_inner_lr_diff_max_cam)
                        shape_inner_lr_diff_max_cam <= shape_inner_row_lr_diff_cam;
                    if (shape_inner_sample_rows_cam != 8'hFF)
                        shape_inner_sample_rows_cam <= shape_inner_sample_rows_cam + 8'd1;
                    if (shape_inner_row_cylinder_like_cam && (shape_inner_cylinder_rows_cam != 8'hFF))
                        shape_inner_cylinder_rows_cam <= shape_inner_cylinder_rows_cam + 8'd1;
                    if (shape_inner_row_cube_like_cam && (shape_inner_cube_rows_cam != 8'hFF))
                        shape_inner_cube_rows_cam <= shape_inner_cube_rows_cam + 8'd1;
                end

                shape_row_left_cam <= 10'h3FF;
                shape_row_right_cam <= 10'd0;
                shape_center_row_left_cam <= 10'h3FF;
                shape_center_row_right_cam <= 10'd0;
                shape_row_edge_count_cam <= 8'd0;
                shape_row_has_edge_cam <= 1'b0;
                shape_row_roi_hit_cam <= 1'b0;
                shape_row_inner_left_valid_cam <= 1'b0;
                shape_row_inner_mid_valid_cam <= 1'b0;
                shape_row_inner_right_valid_cam <= 1'b0;
                shape_prev_gray_valid_cam <= 1'b0;
                shape_preview_x_div_cam <= 3'd0;
                shape_preview_wr_x_cam <= 8'd0;
                if (shape_preview_capture_line_cam && (shape_preview_wr_y_cam < (SHAPE_PREVIEW_H - 1'b1)))
                    shape_preview_wr_y_cam <= shape_preview_wr_y_cam + 7'd1;
                if (shape_preview_capture_line_cam) begin
                    if (ENABLE_HDMI_PREVIEW) begin
                        if (shape_center_row_valid_eval_cam) begin
                            shape_contour_left_ram[shape_preview_wr_y_cam] <=
                                (SHAPE_ROI_X_START + {2'd0, shape_center_row_left_cam}) / 12'd12;
                            shape_contour_right_ram[shape_preview_wr_y_cam] <=
                                (SHAPE_ROI_X_START + {2'd0, shape_center_row_right_cam}) / 12'd12;
                        end else begin
                            shape_contour_left_ram[shape_preview_wr_y_cam] <= 8'hFF;
                            shape_contour_right_ram[shape_preview_wr_y_cam] <= 8'hFF;
                        end
                        if (shape_fg_row_hit_cam) begin
                            shape_fg_contour_left_ram[shape_preview_wr_y_cam] <= shape_fg_row_left_cam;
                            shape_fg_contour_right_ram[shape_preview_wr_y_cam] <= shape_fg_row_right_cam;
                        end else begin
                            shape_fg_contour_left_ram[shape_preview_wr_y_cam] <= 8'hFF;
                            shape_fg_contour_right_ram[shape_preview_wr_y_cam] <= 8'hFF;
                        end
                    end
                    if (shape_fg_row_hit_cam) begin
                        if (shape_fg_valid_rows_cam == 8'd0) begin
                            shape_fg_top_width_cam <= shape_fg_row_width_eval_cam[7:0];
                            shape_fg_min_y_cam <= shape_preview_wr_y_cam;
                            shape_fg_max_y_cam <= shape_preview_wr_y_cam;
                        end else begin
                            if (shape_preview_wr_y_cam < shape_fg_min_y_cam)
                                shape_fg_min_y_cam <= shape_preview_wr_y_cam;
                            if (shape_preview_wr_y_cam > shape_fg_max_y_cam)
                                shape_fg_max_y_cam <= shape_preview_wr_y_cam;
                        end
                        shape_fg_bottom_width_cam <= shape_fg_row_width_eval_cam[7:0];
                        if (shape_fg_valid_rows_cam != 8'hFF)
                            shape_fg_valid_rows_cam <= shape_fg_valid_rows_cam + 8'd1;
                        if (shape_fg_row_left_cam < shape_fg_min_x_cam)
                            shape_fg_min_x_cam <= shape_fg_row_left_cam;
                        if (shape_fg_row_right_cam > shape_fg_max_x_cam)
                            shape_fg_max_x_cam <= shape_fg_row_right_cam;
                        if (shape_fg_row_width_eval_cam[7:0] < shape_fg_width_min_cam)
                            shape_fg_width_min_cam <= shape_fg_row_width_eval_cam[7:0];
                        if (shape_fg_row_width_eval_cam[7:0] > shape_fg_width_max_cam)
                            shape_fg_width_max_cam <= shape_fg_row_width_eval_cam[7:0];
                        if (shape_fg_top_width_rows_cam < 3'd4) begin
                            shape_fg_top_width_sum_cam <=
                                shape_fg_top_width_sum_cam + {3'd0, shape_fg_row_width_eval_cam[7:0]};
                            shape_fg_top_width_rows_cam <= shape_fg_top_width_rows_cam + 3'd1;
                        end
                        shape_fg_bottom_width3_cam <= shape_fg_bottom_width2_cam;
                        shape_fg_bottom_width2_cam <= shape_fg_bottom_width1_cam;
                        shape_fg_bottom_width1_cam <= shape_fg_bottom_width0_cam;
                        shape_fg_bottom_width0_cam <= shape_fg_row_width_eval_cam[7:0];
                        if ((shape_fg_row_left_cam <= SHAPE_FG_COL_LEFT_X) &&
                            (shape_fg_row_right_cam >= SHAPE_FG_COL_LEFT_X) &&
                            (shape_fg_col_left_rows_cam != 8'hFF))
                            shape_fg_col_left_rows_cam <= shape_fg_col_left_rows_cam + 8'd1;
                        if ((shape_fg_row_left_cam <= SHAPE_FG_COL_MID_X) &&
                            (shape_fg_row_right_cam >= SHAPE_FG_COL_MID_X) &&
                            (shape_fg_col_mid_rows_cam != 8'hFF))
                            shape_fg_col_mid_rows_cam <= shape_fg_col_mid_rows_cam + 8'd1;
                        if ((shape_fg_row_left_cam <= SHAPE_FG_COL_RIGHT_X) &&
                            (shape_fg_row_right_cam >= SHAPE_FG_COL_RIGHT_X) &&
                            (shape_fg_col_right_rows_cam != 8'hFF))
                            shape_fg_col_right_rows_cam <= shape_fg_col_right_rows_cam + 8'd1;
                        if (shape_fg_row_lr_gray_diff_cam > shape_fg_lr_gray_diff_max_cam)
                            shape_fg_lr_gray_diff_max_cam <= shape_fg_row_lr_gray_diff_cam;
                    end
                    if (shape_fg_row_hit_cam &&
                        (shape_fg_row_left_cam <= SHAPE_FG_COL_LEFT_X) &&
                        (shape_fg_row_right_cam >= SHAPE_FG_COL_RIGHT_X) &&
                        shape_fg_curve_left_valid_cam &&
                        shape_fg_curve_mid_valid_cam &&
                        shape_fg_curve_right_valid_cam) begin
                        if (shape_fg_curve_grad_sum_cam > shape_fg_curve_grad_max_cam)
                            shape_fg_curve_grad_max_cam <= shape_fg_curve_grad_sum_cam;
                        if (shape_fg_curve_lr_diff_cam > shape_fg_curve_lr_diff_max_cam)
                            shape_fg_curve_lr_diff_max_cam <= shape_fg_curve_lr_diff_cam;
                        if (shape_fg_curve_sample_rows_cam != 8'hFF)
                            shape_fg_curve_sample_rows_cam <= shape_fg_curve_sample_rows_cam + 8'd1;
                    end
                end
                shape_fg_row_left_cam <= 8'hFF;
                shape_fg_row_right_cam <= 8'd0;
                shape_fg_row_hit_cam <= 1'b0;
                shape_fg_row_left_gray_cam <= 8'd0;
                shape_fg_row_right_gray_cam <= 8'd0;
                shape_fg_row_prev_gray_cam <= 8'd0;
                shape_fg_row_prev_hit_cam <= 1'b0;
                shape_fg_run_active_cam <= 1'b0;
                shape_fg_run_gap_cam <= 2'd0;
                shape_fg_run_left_cam <= 8'd0;
                shape_fg_run_right_cam <= 8'd0;
                shape_fg_run_len_cam <= 8'd0;
                shape_fg_best_len_cam <= 8'd0;
                shape_fg_run_left_gray_cam <= 8'd0;
                shape_fg_run_right_gray_cam <= 8'd0;
                shape_fg_curve_left_valid_cam <= 1'b0;
                shape_fg_curve_mid_valid_cam <= 1'b0;
                shape_fg_curve_right_valid_cam <= 1'b0;
                if (shape_preview_y_div_cam == 4'd8) begin
                    shape_preview_y_div_cam <= 4'd0;
                    shape_preview_capture_line_cam <= 1'b1;
                end else begin
                    shape_preview_y_div_cam <= shape_preview_y_div_cam + 4'd1;
                    shape_preview_capture_line_cam <= 1'b0;
                end
            end

            if (rgb_de) begin
                // Active pixels: update x/y position, preview down-sampling,
                // shape edge/gray features, and color ROI accumulators.
                if (!rgb_de_d) begin
                    color_x <= 12'd0;
                    shape_preview_x_div_cam <= 3'd0;
                    shape_preview_wr_x_cam <= 8'd0;
                end else
                    color_x <= color_x + 12'd2;

                if (shape_preview_capture_line_cam) begin
                    if (shape_preview_x_div_cam == 3'd0) begin
                        if (ENABLE_HDMI_PREVIEW)
                            shape_preview_ram[shape_preview_wr_addr_cam] <= shape_gray0_cam;
                        if (shape_bg_learn_cam) begin
                            shape_bg_grid_ram[shape_bg_grid_addr_cam] <= shape_preview_rgb444_cam;
                        end else begin
                            shape_fg_addr_valid_cam <= 1'b1;
                            shape_fg_addr_bg_valid_cam <= shape_bg_valid_cam;
                            shape_fg_addr_in_roi_cam <= shape_preview_in_shape_roi_cam;
                            shape_fg_addr_bg_grid_addr_cam <= shape_bg_grid_addr_cam;
                            shape_fg_addr_rgb444_cam <= shape_preview_rgb444_cam;
                            shape_fg_addr_x_cam <= shape_preview_wr_x_cam;
                            shape_fg_addr_gray_cam <= shape_gray0_cam;
                            shape_fg_addr_top_zone_cam <=
                                (shape_preview_wr_y_cam < SHAPE_FG_GRID_Y1);
                            shape_fg_addr_mid_zone_cam <=
                                (shape_preview_wr_y_cam >= SHAPE_FG_GRID_Y1) &&
                                (shape_preview_wr_y_cam < SHAPE_FG_GRID_Y2);
                            shape_fg_addr_corner_zone_cam <=
                                ((shape_preview_wr_y_cam < SHAPE_FG_GRID_Y1) ||
                                 (shape_preview_wr_y_cam >= SHAPE_FG_GRID_Y2)) &&
                                ((shape_preview_wr_x_cam < SHAPE_FG_GRID_X1) ||
                                 (shape_preview_wr_x_cam >= SHAPE_FG_GRID_X2));
                            shape_fg_addr_center_zone_cam <=
                                (shape_preview_wr_y_cam >= SHAPE_FG_GRID_Y1) &&
                                (shape_preview_wr_y_cam < SHAPE_FG_GRID_Y2) &&
                                (shape_preview_wr_x_cam >= SHAPE_FG_GRID_X1) &&
                                (shape_preview_wr_x_cam < SHAPE_FG_GRID_X2);
                            shape_fg_addr_col_left_cam <=
                                (shape_preview_wr_x_cam == SHAPE_FG_COL_LEFT_X);
                            shape_fg_addr_col_mid_cam <=
                                (shape_preview_wr_x_cam == SHAPE_FG_COL_MID_X);
                            shape_fg_addr_col_right_cam <=
                                (shape_preview_wr_x_cam == SHAPE_FG_COL_RIGHT_X);
                        end
                        if (shape_preview_wr_x_cam < (SHAPE_PREVIEW_W - 1'b1))
                            shape_preview_wr_x_cam <= shape_preview_wr_x_cam + 8'd1;
                    end

                    if (shape_preview_x_div_cam == 3'd5)
                        shape_preview_x_div_cam <= 3'd0;
                    else
                        shape_preview_x_div_cam <= shape_preview_x_div_cam + 3'd1;
                end

                if (shape_roi_y_active) begin
                    if (pixel0_in_shape_roi || pixel1_in_shape_roi) begin
                        shape_gray_line_ram[shape_roi_pair_x] <= {shape_gray1_cam, shape_gray0_cam};
                        shape_row_roi_hit_cam <= 1'b1;

                        if (shape_roi_hit_pixels_cam >= (11'd999 - {9'd0, shape_roi_pixel_inc_cam}))
                            shape_roi_hit_pixels_cam <= 11'd999;
                        else
                            shape_roi_hit_pixels_cam <= shape_roi_hit_pixels_cam + {9'd0, shape_roi_pixel_inc_cam};

                        if (shape_roi_gray_min_pair_cam < shape_gray_min_cam)
                            shape_gray_min_cam <= shape_roi_gray_min_pair_cam;
                        if (shape_roi_gray_max_pair_cam > shape_gray_max_cam)
                            shape_gray_max_cam <= shape_roi_gray_max_pair_cam;
                        if (shape_h_diff_pair_max_cam > shape_h_diff_max_cam)
                            shape_h_diff_max_cam <= shape_h_diff_pair_max_cam;
                        if (shape_v_diff_pair_max_cam > shape_v_diff_max_cam)
                            shape_v_diff_max_cam <= shape_v_diff_pair_max_cam;

                        if (pixel0_in_shape_roi) begin
                            if (roi_x0_local == SHAPE_INNER_SAMPLE_LEFT_X) begin
                                shape_row_inner_left_gray_cam <= shape_gray0_cam;
                                shape_row_inner_left_valid_cam <= 1'b1;
                            end
                            if (roi_x0_local == SHAPE_INNER_SAMPLE_MID_X) begin
                                shape_row_inner_mid_gray_cam <= shape_gray0_cam;
                                shape_row_inner_mid_valid_cam <= 1'b1;
                            end
                            if (roi_x0_local == SHAPE_INNER_SAMPLE_RIGHT_X) begin
                                shape_row_inner_right_gray_cam <= shape_gray0_cam;
                                shape_row_inner_right_valid_cam <= 1'b1;
                            end
                        end

                        if (pixel1_in_shape_roi) begin
                            if (roi_x1_local == SHAPE_INNER_SAMPLE_LEFT_X) begin
                                shape_row_inner_left_gray_cam <= shape_gray1_cam;
                                shape_row_inner_left_valid_cam <= 1'b1;
                            end
                            if (roi_x1_local == SHAPE_INNER_SAMPLE_MID_X) begin
                                shape_row_inner_mid_gray_cam <= shape_gray1_cam;
                                shape_row_inner_mid_valid_cam <= 1'b1;
                            end
                            if (roi_x1_local == SHAPE_INNER_SAMPLE_RIGHT_X) begin
                                shape_row_inner_right_gray_cam <= shape_gray1_cam;
                                shape_row_inner_right_valid_cam <= 1'b1;
                            end
                        end

                        if (shape_edge_hit_inc_cam != 3'd0) begin
                            if (shape_edge_hit_pixels_cam >= (11'd2047 - {8'd0, shape_edge_hit_inc_cam}))
                                shape_edge_hit_pixels_cam <= 11'd2047;
                            else
                                shape_edge_hit_pixels_cam <= shape_edge_hit_pixels_cam + {8'd0, shape_edge_hit_inc_cam};
                        end

                        if (shape_h_edge_inc_cam != 2'd0) begin
                            shape_row_has_edge_cam <= 1'b1;
                            shape_row_edge_count_cam <= shape_row_edge_count_cam + {{6{1'b0}}, shape_h_edge_inc_cam};
                            if ((!shape_row_has_edge_cam) || (shape_h_edge_left_x_cam < shape_row_left_cam))
                                shape_row_left_cam <= shape_h_edge_left_x_cam;
                            if ((!shape_row_has_edge_cam) || (shape_h_edge_right_x_cam > shape_row_right_cam))
                                shape_row_right_cam <= shape_h_edge_right_x_cam;
                        end

                        if (shape_h_edge0_center_left_cam &&
                            (shape_center_row_left_cam == 10'h3FF || roi_x0_local < shape_center_row_left_cam))
                            shape_center_row_left_cam <= roi_x0_local;
                        if (shape_h_edge1_center_left_cam &&
                            (shape_center_row_left_cam == 10'h3FF || roi_x1_local < shape_center_row_left_cam))
                            shape_center_row_left_cam <= roi_x1_local;
                        if (shape_h_edge0_center_right_cam &&
                            (roi_x0_local > shape_center_row_right_cam))
                            shape_center_row_right_cam <= roi_x0_local;
                        if (shape_h_edge1_center_right_cam &&
                            (roi_x1_local > shape_center_row_right_cam))
                            shape_center_row_right_cam <= roi_x1_local;

                        if (shape_v_edge0_cam) begin
                            case (shape_x_bin(roi_x0_local))
                                4'd0: if (roi_y_local < shape_top_edge_bin0_cam) shape_top_edge_bin0_cam <= roi_y_local;
                                4'd1: if (roi_y_local < shape_top_edge_bin1_cam) shape_top_edge_bin1_cam <= roi_y_local;
                                4'd2: if (roi_y_local < shape_top_edge_bin2_cam) shape_top_edge_bin2_cam <= roi_y_local;
                                4'd3: if (roi_y_local < shape_top_edge_bin3_cam) shape_top_edge_bin3_cam <= roi_y_local;
                                4'd4: if (roi_y_local < shape_top_edge_bin4_cam) shape_top_edge_bin4_cam <= roi_y_local;
                                4'd5: if (roi_y_local < shape_top_edge_bin5_cam) shape_top_edge_bin5_cam <= roi_y_local;
                                4'd6: if (roi_y_local < shape_top_edge_bin6_cam) shape_top_edge_bin6_cam <= roi_y_local;
                                4'd7: if (roi_y_local < shape_top_edge_bin7_cam) shape_top_edge_bin7_cam <= roi_y_local;
                                4'd8: if (roi_y_local < shape_top_edge_bin8_cam) shape_top_edge_bin8_cam <= roi_y_local;
                                4'd9: if (roi_y_local < shape_top_edge_bin9_cam) shape_top_edge_bin9_cam <= roi_y_local;
                                default: ;
                            endcase
                        end

                        if (shape_v_edge1_cam) begin
                            case (shape_x_bin(roi_x1_local))
                                4'd0: if (roi_y_local < shape_top_edge_bin0_cam) shape_top_edge_bin0_cam <= roi_y_local;
                                4'd1: if (roi_y_local < shape_top_edge_bin1_cam) shape_top_edge_bin1_cam <= roi_y_local;
                                4'd2: if (roi_y_local < shape_top_edge_bin2_cam) shape_top_edge_bin2_cam <= roi_y_local;
                                4'd3: if (roi_y_local < shape_top_edge_bin3_cam) shape_top_edge_bin3_cam <= roi_y_local;
                                4'd4: if (roi_y_local < shape_top_edge_bin4_cam) shape_top_edge_bin4_cam <= roi_y_local;
                                4'd5: if (roi_y_local < shape_top_edge_bin5_cam) shape_top_edge_bin5_cam <= roi_y_local;
                                4'd6: if (roi_y_local < shape_top_edge_bin6_cam) shape_top_edge_bin6_cam <= roi_y_local;
                                4'd7: if (roi_y_local < shape_top_edge_bin7_cam) shape_top_edge_bin7_cam <= roi_y_local;
                                4'd8: if (roi_y_local < shape_top_edge_bin8_cam) shape_top_edge_bin8_cam <= roi_y_local;
                                4'd9: if (roi_y_local < shape_top_edge_bin9_cam) shape_top_edge_bin9_cam <= roi_y_local;
                                default: ;
                            endcase
                        end

                        shape_prev_gray_cam <= pixel1_in_shape_roi ? shape_gray1_cam : shape_gray0_cam;
                        shape_prev_gray_valid_cam <= 1'b1;
                    end else begin
                        shape_prev_gray_valid_cam <= 1'b0;
                    end
                end else begin
                    shape_prev_gray_valid_cam <= 1'b0;
                end

            end else begin
                color_x <= 12'd0;
                if (rgb_de_d && (color_y < VACT - 1'b1))
                    color_y <= color_y + 11'd1;
            end
        end
    end
end

generate
if (ENABLE_HDMI_PREVIEW) begin : g_hdmi_preview_reader
    always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
        // This debug preview is a camera-domain RAM sampled by HDMI. Keep this
        // path disabled unless it is rebuilt as a proper dual-port/handshaked
        // frame buffer for production timing closure.
        if(!hdmi_rst_n) begin
            shape_preview_rd_addr_hdmi <= 15'd0;
            shape_preview_gray_hdmi <= 8'd0;
            shape_contour_left_hdmi <= 8'hFF;
            shape_contour_right_hdmi <= 8'hFF;
            shape_fg_contour_left_hdmi <= 8'hFF;
            shape_fg_contour_right_hdmi <= 8'hFF;
            shape_bg_valid_hdmi_meta <= 1'b0;
            shape_bg_valid_hdmi <= 1'b0;
            shape_bg_learn_hdmi_meta <= 1'b0;
            shape_bg_learn_hdmi <= 1'b0;
        end else begin
            shape_bg_valid_hdmi_meta <= shape_bg_valid_cam;
            shape_bg_valid_hdmi <= shape_bg_valid_hdmi_meta;
            shape_bg_learn_hdmi_meta <= shape_bg_learn_cam;
            shape_bg_learn_hdmi <= shape_bg_learn_hdmi_meta;
            if(shape_preview_ui_active) begin
                shape_preview_rd_addr_hdmi <= shape_preview_addr(shape_preview_ui_y, shape_preview_ui_x);
                shape_contour_left_hdmi <= shape_contour_left_ram[shape_preview_ui_y];
                shape_contour_right_hdmi <= shape_contour_right_ram[shape_preview_ui_y];
                shape_fg_contour_left_hdmi <= shape_fg_contour_left_ram[shape_preview_ui_y];
                shape_fg_contour_right_hdmi <= shape_fg_contour_right_ram[shape_preview_ui_y];
            end else begin
                shape_preview_rd_addr_hdmi <= 15'd0;
                shape_contour_left_hdmi <= 8'hFF;
                shape_contour_right_hdmi <= 8'hFF;
                shape_fg_contour_left_hdmi <= 8'hFF;
                shape_fg_contour_right_hdmi <= 8'hFF;
            end
            shape_preview_gray_hdmi <= shape_preview_ram[shape_preview_rd_addr_hdmi];
        end
    end
end else begin : g_hdmi_preview_disabled
    always @(posedge hdmi_clk or negedge hdmi_rst_n) begin
        if(!hdmi_rst_n) begin
            shape_preview_rd_addr_hdmi <= 15'd0;
            shape_preview_gray_hdmi <= 8'd0;
            shape_contour_left_hdmi <= 8'hFF;
            shape_contour_right_hdmi <= 8'hFF;
            shape_fg_contour_left_hdmi <= 8'hFF;
            shape_fg_contour_right_hdmi <= 8'hFF;
            shape_bg_valid_hdmi_meta <= 1'b0;
            shape_bg_valid_hdmi <= 1'b0;
            shape_bg_learn_hdmi_meta <= 1'b0;
            shape_bg_learn_hdmi <= 1'b0;
        end else begin
            shape_preview_rd_addr_hdmi <= 15'd0;
            shape_preview_gray_hdmi <= 8'd0;
            shape_contour_left_hdmi <= 8'hFF;
            shape_contour_right_hdmi <= 8'hFF;
            shape_fg_contour_left_hdmi <= 8'hFF;
            shape_fg_contour_right_hdmi <= 8'hFF;
            shape_bg_valid_hdmi_meta <= shape_bg_valid_cam;
            shape_bg_valid_hdmi <= shape_bg_valid_hdmi_meta;
            shape_bg_learn_hdmi_meta <= shape_bg_learn_cam;
            shape_bg_learn_hdmi <= shape_bg_learn_hdmi_meta;
        end
    end
end
endgenerate
endmodule

`endif
