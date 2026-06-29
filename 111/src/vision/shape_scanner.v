`ifndef SHAPE_SCANNER_V
`define SHAPE_SCANNER_V

// Combinational scan math for the shape recognition path.
// The top level still owns the line/background RAMs and frame accumulators;
// this module turns the current RGB beat plus those state values into
// foreground, edge, and row-feature wires.
module shape_scanner #(
    parameter [11:0] SHAPE_ROI_X_START = 12'd492,
    parameter [11:0] SHAPE_ROI_X_END = 12'd1428,
    parameter [10:0] SHAPE_ROI_Y_START = 11'd212,
    parameter [10:0] SHAPE_ROI_Y_END = 11'd868,
    parameter [9:0]  SHAPE_CENTER_X = 10'd468,
    parameter [9:0]  SHAPE_CENTER_LEFT_MIN = 10'd40,
    parameter [9:0]  SHAPE_CENTER_RIGHT_MAX = 10'd896,
    parameter [9:0]  SHAPE_CENTER_GAP = 10'd24,
    parameter [9:0]  SHAPE_CENTER_MIN_ROW_WIDTH = 10'd80,
    parameter [7:0]  SHAPE_EDGE_H_THRESH = 8'd9,
    parameter [7:0]  SHAPE_EDGE_V_THRESH = 8'd5,
    parameter [9:0]  SHAPE_MIN_ROW_WIDTH = 10'd16,
    parameter [5:0]  SHAPE_BG_RGB_DIFF_THRESH = 6'd6,
    parameter [5:0]  SHAPE_SHADOW_DROP_MIN = 6'd6,
    parameter [5:0]  SHAPE_SHADOW_DROP_MAX = 6'd18,
    parameter [3:0]  SHAPE_SHADOW_BALANCE_MAX = 4'd3,
    parameter [5:0]  SHAPE_SHADOW_CUR_SUM_MIN = 6'd10,
    parameter [7:0]  SHAPE_ROI_PREVIEW_X_START = 8'd41,
    parameter [7:0]  SHAPE_ROI_PREVIEW_X_END = 8'd118,
    parameter [6:0]  SHAPE_ROI_PREVIEW_Y_START = 7'd24,
    parameter [6:0]  SHAPE_ROI_PREVIEW_Y_END = 7'd96
) (
    input  wire        rgb_de,
    input  wire        rgb_de_d,
    input  wire [11:0] color_x,
    input  wire [10:0] color_y,
    input  wire [47:0] rgb_datax2,

    input  wire [7:0]  shape_preview_wr_x,
    input  wire [6:0]  shape_preview_wr_y,
    input  wire        shape_bg_valid,
    input  wire        shape_bg_learn,
    input  wire [11:0] shape_bg_grid_rgb444,

    input  wire [15:0] shape_prev_gray_pair,
    input  wire [7:0]  shape_prev_gray,
    input  wire        shape_prev_gray_valid,

    input  wire [9:0]  shape_row_left,
    input  wire [9:0]  shape_row_right,
    input  wire [7:0]  shape_row_edge_count,
    input  wire        shape_row_has_edge,
    input  wire [9:0]  shape_center_row_left,
    input  wire [9:0]  shape_center_row_right,
    input  wire [7:0]  shape_row_inner_left_gray,
    input  wire [7:0]  shape_row_inner_mid_gray,
    input  wire [7:0]  shape_row_inner_right_gray,
    input  wire        shape_row_inner_left_valid,
    input  wire        shape_row_inner_mid_valid,
    input  wire        shape_row_inner_right_valid,

    input  wire [7:0]  shape_fg_row_left,
    input  wire [7:0]  shape_fg_row_right,
    input  wire [7:0]  shape_fg_valid_rows,
    input  wire [7:0]  shape_fg_min_x,
    input  wire [7:0]  shape_fg_max_x,
    input  wire [6:0]  shape_fg_min_y,
    input  wire [6:0]  shape_fg_max_y,
    input  wire [7:0]  shape_fg_width_min,
    input  wire [7:0]  shape_fg_width_max,
    input  wire [7:0]  shape_fg_top_width,
    input  wire [7:0]  shape_fg_bottom_width,
    input  wire [7:0]  shape_fg_col_left_rows,
    input  wire [7:0]  shape_fg_col_mid_rows,
    input  wire [7:0]  shape_fg_col_right_rows,
    input  wire [7:0]  shape_fg_gray_min,
    input  wire [7:0]  shape_fg_gray_max,
    input  wire [7:0]  shape_fg_row_left_gray,
    input  wire [7:0]  shape_fg_row_right_gray,
    input  wire [7:0]  shape_fg_run_len,
    input  wire [1:0]  shape_fg_run_gap,
    input  wire [10:0] shape_fg_top_width_sum,
    input  wire [2:0]  shape_fg_top_width_rows,
    input  wire [7:0]  shape_fg_bottom_width0,
    input  wire [7:0]  shape_fg_bottom_width1,
    input  wire [7:0]  shape_fg_bottom_width2,
    input  wire [7:0]  shape_fg_bottom_width3,
    input  wire [7:0]  shape_fg_curve_left_gray,
    input  wire [7:0]  shape_fg_curve_mid_gray,
    input  wire [7:0]  shape_fg_curve_right_gray,

    output wire        shape_roi_y_active,
    output wire        pixel0_in_shape_roi,
    output wire        pixel1_in_shape_roi,
    output wire        line_end_pulse,
    output wire [9:0]  roi_x0_local,
    output wire [9:0]  roi_x1_local,
    output wire [9:0]  roi_y_local,
    output wire [8:0]  shape_roi_pair_x,
    output wire [7:0]  shape_gray0,
    output wire [7:0]  shape_gray1,
    output wire [7:0]  shape_roi_gray_min_pair,
    output wire [7:0]  shape_roi_gray_max_pair,
    output wire [7:0]  shape_prev_line_gray0,
    output wire [7:0]  shape_prev_line_gray1,
    output wire [7:0]  shape_h_diff0,
    output wire [7:0]  shape_h_diff1,
    output wire [7:0]  shape_v_diff0,
    output wire [7:0]  shape_v_diff1,
    output wire        shape_h_diff0_valid,
    output wire        shape_h_diff1_valid,
    output wire        shape_v_diff0_valid,
    output wire        shape_v_diff1_valid,
    output wire [7:0]  shape_h_diff_pair_max,
    output wire [7:0]  shape_v_diff_pair_max,
    output wire        shape_inner_row_sample_valid,
    output wire [7:0]  shape_inner_row_min_gray,
    output wire [7:0]  shape_inner_row_max_gray,
    output wire [7:0]  shape_inner_row_lc_diff,
    output wire [7:0]  shape_inner_row_cr_diff,
    output wire [7:0]  shape_inner_row_lr_diff,
    output wire [9:0]  shape_inner_row_grad_sum,
    output wire        shape_inner_row_cylinder_center_like,
    output wire        shape_inner_row_cylinder_like,
    output wire        shape_inner_row_cube_like,
    output wire        shape_h_edge0,
    output wire        shape_h_edge1,
    output wire        shape_v_edge0,
    output wire        shape_v_edge1,
    output wire [1:0]  shape_roi_pixel_inc,
    output wire [1:0]  shape_h_edge_inc,
    output wire [2:0]  shape_edge_hit_inc,
    output wire [9:0]  shape_h_edge_left_x,
    output wire [9:0]  shape_h_edge_right_x,
    output wire        shape_h_edge0_center_left,
    output wire        shape_h_edge1_center_left,
    output wire        shape_h_edge0_center_right,
    output wire        shape_h_edge1_center_right,
    output wire [9:0]  shape_row_width_eval,
    output wire        shape_row_valid_eval,
    output wire [9:0]  shape_center_row_width_eval,
    output wire        shape_center_row_valid_eval,

    output wire [14:0] shape_preview_wr_addr,
    output wire [11:0] shape_preview_rgb444,
    output wire [5:0]  shape_bg_grid_x,
    output wire [4:0]  shape_bg_grid_y,
    output wire [10:0] shape_bg_grid_addr,
    output wire [5:0]  shape_bg_rgb_diff,
    output wire [3:0]  shape_cur_r444,
    output wire [3:0]  shape_cur_g444,
    output wire [3:0]  shape_cur_b444,
    output wire [3:0]  shape_bg_r444,
    output wire [3:0]  shape_bg_g444,
    output wire [3:0]  shape_bg_b444,
    output wire [3:0]  shape_shadow_drop_r,
    output wire [3:0]  shape_shadow_drop_g,
    output wire [3:0]  shape_shadow_drop_b,
    output wire [5:0]  shape_shadow_drop_sum,
    output wire [5:0]  shape_shadow_cur_sum,
    output wire        shape_shadow_darker,
    output wire        shape_shadow_balanced,
    output wire        shape_shadow_like,
    output wire        shape_preview_in_shape_roi,
    output wire        shape_fg_pixel,
    output wire [8:0]  shape_fg_row_width_eval,
    output wire [7:0]  shape_fg_bbox_w,
    output wire [7:0]  shape_fg_bbox_h,
    output wire [7:0]  shape_fg_width_range,
    output wire [7:0]  shape_fg_top_bottom_delta,
    output wire [7:0]  shape_fg_col_side_min,
    output wire [7:0]  shape_fg_col_center_delta,
    output wire [7:0]  shape_fg_col_lr_diff,
    output wire [7:0]  shape_fg_gray_range,
    output wire [7:0]  shape_fg_row_lr_gray_diff,
    output wire [8:0]  shape_fg_run_len_next,
    output wire [9:0]  shape_fg_bottom_width_sum,
    output wire [7:0]  shape_fg_top_width_avg,
    output wire [7:0]  shape_fg_bottom_width_avg,
    output wire [7:0]  shape_fg_top_bottom_avg_delta,
    output wire [7:0]  shape_fg_curve_lc_diff,
    output wire [7:0]  shape_fg_curve_cr_diff,
    output wire [7:0]  shape_fg_curve_lr_diff,
    output wire [9:0]  shape_fg_curve_grad_sum
);

function [7:0] abs_diff_u8;
input [7:0] a;
input [7:0] b;
begin
    abs_diff_u8 = (a > b) ? (a - b) : (b - a);
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

function [7:0] shape_gray;
input [7:0] r;
input [7:0] g;
input [7:0] b;
begin
    shape_gray = {2'b00, r[7:2]} + {1'b0, g[7:1]} + {2'b00, b[7:2]};
end
endfunction

function [14:0] shape_preview_addr;
input [6:0] sample_y;
input [7:0] sample_x;
begin
    shape_preview_addr = ({8'd0, sample_y} << 7) + ({8'd0, sample_y} << 5) + {7'd0, sample_x};
end
endfunction

function [10:0] shape_bg_addr;
input [4:0] sample_y;
input [5:0] sample_x;
begin
    shape_bg_addr = ({6'd0, sample_y} << 5) + ({6'd0, sample_y} << 3) + {5'd0, sample_x};
end
endfunction

assign shape_roi_y_active = (color_y >= SHAPE_ROI_Y_START) && (color_y < SHAPE_ROI_Y_END);
assign pixel0_in_shape_roi = rgb_de && shape_roi_y_active &&
                             (color_x >= SHAPE_ROI_X_START) && (color_x < SHAPE_ROI_X_END);
assign pixel1_in_shape_roi = rgb_de && shape_roi_y_active &&
                             ((color_x + 12'd1) >= SHAPE_ROI_X_START) &&
                             ((color_x + 12'd1) < SHAPE_ROI_X_END);
assign line_end_pulse = rgb_de_d && !rgb_de;
assign roi_x0_local = pixel0_in_shape_roi ? (color_x - SHAPE_ROI_X_START) : 10'd0;
assign roi_x1_local = pixel1_in_shape_roi ? ((color_x + 12'd1) - SHAPE_ROI_X_START) : 10'd0;
assign roi_y_local = shape_roi_y_active ? (color_y - SHAPE_ROI_Y_START) : 10'd0;
assign shape_roi_pair_x = roi_x0_local[9:1];

assign shape_gray0 = shape_gray(rgb_datax2[31:24], rgb_datax2[39:32], rgb_datax2[47:40]);
assign shape_gray1 = shape_gray(rgb_datax2[7:0], rgb_datax2[15:8], rgb_datax2[23:16]);
assign shape_preview_wr_addr = shape_preview_addr(shape_preview_wr_y, shape_preview_wr_x);
assign shape_preview_rgb444 = {rgb_datax2[31:28], rgb_datax2[39:36], rgb_datax2[47:44]};
assign shape_bg_grid_x = shape_preview_wr_x[7:2];
assign shape_bg_grid_y = shape_preview_wr_y[6:2];
assign shape_bg_grid_addr = shape_bg_addr(shape_bg_grid_y, shape_bg_grid_x);
assign shape_bg_rgb_diff = rgb444_diff_sum(shape_preview_rgb444, shape_bg_grid_rgb444);

assign shape_cur_r444 = shape_preview_rgb444[11:8];
assign shape_cur_g444 = shape_preview_rgb444[7:4];
assign shape_cur_b444 = shape_preview_rgb444[3:0];
assign shape_bg_r444 = shape_bg_grid_rgb444[11:8];
assign shape_bg_g444 = shape_bg_grid_rgb444[7:4];
assign shape_bg_b444 = shape_bg_grid_rgb444[3:0];
assign shape_shadow_drop_r =
    (shape_bg_r444 >= shape_cur_r444) ? (shape_bg_r444 - shape_cur_r444) : 4'd0;
assign shape_shadow_drop_g =
    (shape_bg_g444 >= shape_cur_g444) ? (shape_bg_g444 - shape_cur_g444) : 4'd0;
assign shape_shadow_drop_b =
    (shape_bg_b444 >= shape_cur_b444) ? (shape_bg_b444 - shape_cur_b444) : 4'd0;
assign shape_shadow_drop_sum =
    {2'd0, shape_shadow_drop_r} +
    {2'd0, shape_shadow_drop_g} +
    {2'd0, shape_shadow_drop_b};
assign shape_shadow_cur_sum =
    {2'd0, shape_cur_r444} +
    {2'd0, shape_cur_g444} +
    {2'd0, shape_cur_b444};
assign shape_shadow_darker =
    (shape_bg_r444 >= shape_cur_r444) &&
    (shape_bg_g444 >= shape_cur_g444) &&
    (shape_bg_b444 >= shape_cur_b444);
assign shape_shadow_balanced =
    (abs_diff_u4(shape_shadow_drop_r, shape_shadow_drop_g) <= SHAPE_SHADOW_BALANCE_MAX) &&
    (abs_diff_u4(shape_shadow_drop_r, shape_shadow_drop_b) <= SHAPE_SHADOW_BALANCE_MAX) &&
    (abs_diff_u4(shape_shadow_drop_g, shape_shadow_drop_b) <= SHAPE_SHADOW_BALANCE_MAX);
assign shape_shadow_like =
    shape_shadow_darker &&
    shape_shadow_balanced &&
    (shape_shadow_drop_sum >= SHAPE_SHADOW_DROP_MIN) &&
    (shape_shadow_drop_sum <= SHAPE_SHADOW_DROP_MAX) &&
    (shape_shadow_cur_sum >= SHAPE_SHADOW_CUR_SUM_MIN);
assign shape_preview_in_shape_roi =
    (shape_preview_wr_x >= SHAPE_ROI_PREVIEW_X_START) &&
    (shape_preview_wr_x <= SHAPE_ROI_PREVIEW_X_END) &&
    (shape_preview_wr_y >= SHAPE_ROI_PREVIEW_Y_START) &&
    (shape_preview_wr_y <= SHAPE_ROI_PREVIEW_Y_END);
assign shape_fg_pixel =
    shape_bg_valid &&
    (!shape_bg_learn) &&
    shape_preview_in_shape_roi &&
    (shape_bg_rgb_diff >= SHAPE_BG_RGB_DIFF_THRESH) &&
    (!shape_shadow_like);

assign shape_fg_row_width_eval =
    {1'b0, shape_fg_row_right} - {1'b0, shape_fg_row_left} + 9'd1;
assign shape_fg_bbox_w =
    (shape_fg_valid_rows != 8'd0) ? (shape_fg_max_x - shape_fg_min_x + 8'd1) : 8'd0;
assign shape_fg_bbox_h =
    (shape_fg_valid_rows != 8'd0) ? (shape_fg_max_y - shape_fg_min_y + 7'd1) : 8'd0;
assign shape_fg_width_range =
    (shape_fg_width_max >= shape_fg_width_min) ?
    (shape_fg_width_max - shape_fg_width_min) : 8'd0;
assign shape_fg_top_bottom_delta =
    (shape_fg_bottom_width >= shape_fg_top_width) ?
    (shape_fg_bottom_width - shape_fg_top_width) :
    (shape_fg_top_width - shape_fg_bottom_width);
assign shape_fg_col_side_min =
    (shape_fg_col_left_rows < shape_fg_col_right_rows) ?
    shape_fg_col_left_rows : shape_fg_col_right_rows;
assign shape_fg_col_center_delta =
    (shape_fg_col_mid_rows >= shape_fg_col_side_min) ?
    (shape_fg_col_mid_rows - shape_fg_col_side_min) : 8'd0;
assign shape_fg_col_lr_diff =
    (shape_fg_col_left_rows >= shape_fg_col_right_rows) ?
    (shape_fg_col_left_rows - shape_fg_col_right_rows) :
    (shape_fg_col_right_rows - shape_fg_col_left_rows);
assign shape_fg_gray_range =
    (shape_fg_gray_max >= shape_fg_gray_min) ?
    (shape_fg_gray_max - shape_fg_gray_min) : 8'd0;
assign shape_fg_row_lr_gray_diff =
    abs_diff_u8(shape_fg_row_left_gray, shape_fg_row_right_gray);
assign shape_fg_run_len_next =
    {1'b0, shape_fg_run_len} + {7'd0, shape_fg_run_gap} + 9'd1;
assign shape_fg_bottom_width_sum =
    {2'd0, shape_fg_bottom_width0} +
    {2'd0, shape_fg_bottom_width1} +
    {2'd0, shape_fg_bottom_width2} +
    {2'd0, shape_fg_bottom_width3};
assign shape_fg_top_width_avg =
    (shape_fg_top_width_rows >= 3'd4) ? shape_fg_top_width_sum[9:2] :
    (shape_fg_top_width_rows != 3'd0) ? shape_fg_top_width : 8'd0;
assign shape_fg_bottom_width_avg =
    (shape_fg_valid_rows >= 8'd4) ? shape_fg_bottom_width_sum[9:2] :
    (shape_fg_valid_rows != 8'd0) ? shape_fg_bottom_width : 8'd0;
assign shape_fg_top_bottom_avg_delta =
    (shape_fg_bottom_width_avg >= shape_fg_top_width_avg) ?
    (shape_fg_bottom_width_avg - shape_fg_top_width_avg) :
    (shape_fg_top_width_avg - shape_fg_bottom_width_avg);
assign shape_fg_curve_lc_diff =
    abs_diff_u8(shape_fg_curve_left_gray, shape_fg_curve_mid_gray);
assign shape_fg_curve_cr_diff =
    abs_diff_u8(shape_fg_curve_mid_gray, shape_fg_curve_right_gray);
assign shape_fg_curve_lr_diff =
    abs_diff_u8(shape_fg_curve_left_gray, shape_fg_curve_right_gray);
assign shape_fg_curve_grad_sum =
    {2'd0, shape_fg_curve_lc_diff} + {2'd0, shape_fg_curve_cr_diff};

assign shape_roi_gray_min_pair =
    (pixel0_in_shape_roi && pixel1_in_shape_roi) ?
        ((shape_gray0 < shape_gray1) ? shape_gray0 : shape_gray1) :
    pixel0_in_shape_roi ? shape_gray0 : shape_gray1;
assign shape_roi_gray_max_pair =
    (pixel0_in_shape_roi && pixel1_in_shape_roi) ?
        ((shape_gray0 > shape_gray1) ? shape_gray0 : shape_gray1) :
    pixel0_in_shape_roi ? shape_gray0 : shape_gray1;
assign shape_prev_line_gray0 = shape_prev_gray_pair[7:0];
assign shape_prev_line_gray1 = shape_prev_gray_pair[15:8];
assign shape_h_diff0 = abs_diff_u8(shape_gray0, shape_prev_gray);
assign shape_h_diff1 = abs_diff_u8(shape_gray1, shape_gray0);
assign shape_v_diff0 = abs_diff_u8(shape_gray0, shape_prev_line_gray0);
assign shape_v_diff1 = abs_diff_u8(shape_gray1, shape_prev_line_gray1);
assign shape_h_diff0_valid = pixel0_in_shape_roi && shape_prev_gray_valid;
assign shape_h_diff1_valid = pixel1_in_shape_roi && pixel0_in_shape_roi;
assign shape_v_diff0_valid = pixel0_in_shape_roi && (roi_y_local != 10'd0);
assign shape_v_diff1_valid = pixel1_in_shape_roi && (roi_y_local != 10'd0);
assign shape_h_diff_pair_max =
    (shape_h_diff0_valid && shape_h_diff1_valid) ?
        ((shape_h_diff0 > shape_h_diff1) ? shape_h_diff0 : shape_h_diff1) :
    shape_h_diff0_valid ? shape_h_diff0 :
    shape_h_diff1_valid ? shape_h_diff1 : 8'd0;
assign shape_v_diff_pair_max =
    (shape_v_diff0_valid && shape_v_diff1_valid) ?
        ((shape_v_diff0 > shape_v_diff1) ? shape_v_diff0 : shape_v_diff1) :
    shape_v_diff0_valid ? shape_v_diff0 :
    shape_v_diff1_valid ? shape_v_diff1 : 8'd0;

assign shape_inner_row_sample_valid =
    shape_row_inner_left_valid &&
    shape_row_inner_mid_valid &&
    shape_row_inner_right_valid;
assign shape_inner_row_min_gray =
    (shape_row_inner_left_gray < shape_row_inner_mid_gray) ?
        ((shape_row_inner_left_gray < shape_row_inner_right_gray) ?
            shape_row_inner_left_gray : shape_row_inner_right_gray) :
        ((shape_row_inner_mid_gray < shape_row_inner_right_gray) ?
            shape_row_inner_mid_gray : shape_row_inner_right_gray);
assign shape_inner_row_max_gray =
    (shape_row_inner_left_gray > shape_row_inner_mid_gray) ?
        ((shape_row_inner_left_gray > shape_row_inner_right_gray) ?
            shape_row_inner_left_gray : shape_row_inner_right_gray) :
        ((shape_row_inner_mid_gray > shape_row_inner_right_gray) ?
            shape_row_inner_mid_gray : shape_row_inner_right_gray);
assign shape_inner_row_lc_diff =
    abs_diff_u8(shape_row_inner_left_gray, shape_row_inner_mid_gray);
assign shape_inner_row_cr_diff =
    abs_diff_u8(shape_row_inner_mid_gray, shape_row_inner_right_gray);
assign shape_inner_row_lr_diff =
    abs_diff_u8(shape_row_inner_left_gray, shape_row_inner_right_gray);
assign shape_inner_row_grad_sum =
    {2'd0, shape_inner_row_lc_diff} + {2'd0, shape_inner_row_cr_diff};
assign shape_inner_row_cylinder_center_like =
    shape_inner_row_sample_valid &&
    (shape_inner_row_grad_sum >= 10'd10) &&
    (shape_inner_row_grad_sum <= 10'd36) &&
    (shape_inner_row_lr_diff <= 8'd18);
assign shape_inner_row_cylinder_like =
    shape_inner_row_sample_valid &&
    (((shape_inner_row_grad_sum >= 10'd32) &&
      (shape_inner_row_lr_diff >= 8'd24)) ||
     shape_inner_row_cylinder_center_like);
assign shape_inner_row_cube_like =
    shape_inner_row_sample_valid &&
    (shape_inner_row_grad_sum <= 10'd28) &&
    (shape_inner_row_lr_diff <= 8'd28) &&
    (!shape_inner_row_cylinder_center_like);

assign shape_h_edge0 = shape_h_diff0_valid && (shape_h_diff0 >= SHAPE_EDGE_H_THRESH);
assign shape_h_edge1 = shape_h_diff1_valid && (shape_h_diff1 >= SHAPE_EDGE_H_THRESH);
assign shape_v_edge0 = shape_v_diff0_valid && (shape_v_diff0 >= SHAPE_EDGE_V_THRESH);
assign shape_v_edge1 = shape_v_diff1_valid && (shape_v_diff1 >= SHAPE_EDGE_V_THRESH);
assign shape_roi_pixel_inc = {1'b0, pixel0_in_shape_roi} + {1'b0, pixel1_in_shape_roi};
assign shape_h_edge_inc = {1'b0, shape_h_edge0} + {1'b0, shape_h_edge1};
assign shape_edge_hit_inc = {1'b0, shape_h_edge_inc} +
                            {{2{1'b0}}, shape_v_edge0} +
                            {{2{1'b0}}, shape_v_edge1};
assign shape_h_edge_left_x = shape_h_edge0 ? roi_x0_local : roi_x1_local;
assign shape_h_edge_right_x = shape_h_edge1 ? roi_x1_local : roi_x0_local;
assign shape_h_edge0_center_left =
    shape_h_edge0 &&
    (roi_x0_local >= SHAPE_CENTER_LEFT_MIN) &&
    (roi_x0_local + SHAPE_CENTER_GAP < SHAPE_CENTER_X);
assign shape_h_edge1_center_left =
    shape_h_edge1 &&
    (roi_x1_local >= SHAPE_CENTER_LEFT_MIN) &&
    (roi_x1_local + SHAPE_CENTER_GAP < SHAPE_CENTER_X);
assign shape_h_edge0_center_right =
    shape_h_edge0 &&
    (roi_x0_local > (SHAPE_CENTER_X + SHAPE_CENTER_GAP)) &&
    (roi_x0_local <= SHAPE_CENTER_RIGHT_MAX);
assign shape_h_edge1_center_right =
    shape_h_edge1 &&
    (roi_x1_local > (SHAPE_CENTER_X + SHAPE_CENTER_GAP)) &&
    (roi_x1_local <= SHAPE_CENTER_RIGHT_MAX);

assign shape_row_width_eval = shape_row_right - shape_row_left + 10'd1;
assign shape_row_valid_eval =
    shape_roi_y_active &&
    shape_row_has_edge &&
    (shape_row_edge_count >= 8'd2) &&
    (shape_row_right > shape_row_left) &&
    (shape_row_width_eval >= SHAPE_MIN_ROW_WIDTH);
assign shape_center_row_width_eval = shape_center_row_right - shape_center_row_left + 10'd1;
assign shape_center_row_valid_eval =
    shape_roi_y_active &&
    (shape_center_row_left != 10'h3FF) &&
    (shape_center_row_right > shape_center_row_left) &&
    (shape_center_row_width_eval >= SHAPE_CENTER_MIN_ROW_WIDTH);

endmodule

`endif
