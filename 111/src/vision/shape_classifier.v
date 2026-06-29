`ifndef SHAPE_CLASSIFIER_V
`define SHAPE_CLASSIFIER_V

module shape_classifier #(
    parameter [7:0]  SHAPE_MIN_VALID_ROWS = 8'd10,
    parameter [9:0]  SHAPE_MIN_ROW_WIDTH = 10'd16,
    parameter [9:0]  SHAPE_MIN_BBOX_W = 10'd18,
    parameter [7:0]  SHAPE_MIN_BBOX_H = 8'd18,
    parameter [7:0]  SHAPE_WIDTH5_CYL_MIN = 8'd8,
    parameter [7:0]  SHAPE_WIDTH5_CUBE_MIN = 8'd18,
    parameter [7:0]  SHAPE_WIDTH5_VALID_MAX = 8'd40,
    parameter [7:0]  SHAPE_WIDTH_RANGE_MAX = 8'd15,
    parameter [12:0] SHAPE_MIN_FG_PIXELS = 13'd96,
    parameter [7:0]  SHAPE_MOTION_WIDTH5_DELTA = 8'd6,
    parameter [7:0]  SHAPE_MOTION_BBOX_DELTA = 8'd14,
    parameter [7:0]  SHAPE_MOTION_ROWS_DELTA = 8'd10,
    parameter [12:0] SHAPE_MOTION_PIXELS_DELTA = 13'd450
) (
    input  wire        shape_bg_valid,
    input  wire        shape_bg_learn,
    input  wire        shape_metric_valid,
    input  wire [7:0]  shape_valid_rows_filt,
    input  wire [9:0]  shape_bbox_w_filt,
    input  wire [9:0]  shape_bbox_h_filt,
    input  wire [9:0]  shape_width_max_filt,

    input  wire [7:0]  shape_seg_rows,
    input  wire [9:0]  shape_seg_min_x,
    input  wire [9:0]  shape_seg_max_x,
    input  wire [9:0]  shape_seg_min_y,
    input  wire [9:0]  shape_seg_max_y,
    input  wire [9:0]  shape_seg_width_max,
    input  wire [7:0]  shape_best_rows,
    input  wire [9:0]  shape_best_min_x,
    input  wire [9:0]  shape_best_max_x,
    input  wire [9:0]  shape_best_min_y,
    input  wire [9:0]  shape_best_max_y,
    input  wire [9:0]  shape_best_width_max,

    input  wire        shape_motion_prev_valid,
    input  wire [7:0]  shape_motion_prev_width5,
    input  wire [7:0]  shape_motion_prev_bbox_w,
    input  wire [7:0]  shape_motion_prev_bbox_h,
    input  wire [7:0]  shape_motion_prev_valid_rows,
    input  wire [12:0] shape_motion_prev_pixel_count,

    input  wire [7:0]  shape_fg_valid_rows,
    input  wire [7:0]  shape_fg_bbox_w,
    input  wire [7:0]  shape_fg_bbox_h,
    input  wire [12:0] shape_fg_pixel_count,
    input  wire [7:0]  shape_fg_width_range,
    input  wire [7:0]  shape_fg_top_width_avg,

    output wire        shape_size_valid,
    output wire [7:0]  shape_valid_rows_metric,
    output wire [9:0]  shape_bbox_w_metric,
    output wire [9:0]  shape_bbox_h_metric,
    output wire [9:0]  shape_width_max_metric,
    output wire        shape_motion_large,
    output wire [2:0]  shape_candidate_id,
    output wire        shape_candidate_valid
);

localparam [2:0] SHAPE_UNKNOWN  = 3'd0;
localparam [2:0] SHAPE_CUBE     = 3'd1;
localparam [2:0] SHAPE_CYLINDER = 3'd2;
localparam [2:0] SHAPE_CONE     = 3'd3;

wire shape_use_seg;
wire [7:0] shape_body_valid_rows;
wire [9:0] shape_body_min_x;
wire [9:0] shape_body_max_x;
wire [9:0] shape_body_min_y;
wire [9:0] shape_body_max_y;
wire [9:0] shape_body_width_max;
wire shape_bbox_valid;
wire [9:0] shape_bbox_w;
wire [9:0] shape_bbox_h;
wire [8:0] shape_valid_rows_metric_sum;
wire [10:0] shape_bbox_w_metric_sum;
wire [10:0] shape_bbox_h_metric_sum;
wire [10:0] shape_width_max_metric_sum;
wire shape_fg_complete;
wire shape_width_range_ok;
wire [2:0] shape_width5_base_id;
wire [7:0] shape_motion_width5_delta;
wire [7:0] shape_motion_bbox_w_delta;
wire [7:0] shape_motion_bbox_h_delta;
wire [7:0] shape_motion_valid_rows_delta;
wire [12:0] shape_motion_pixel_count_delta;

function [7:0] abs_diff_u8;
input [7:0] a;
input [7:0] b;
begin
    abs_diff_u8 = (a > b) ? (a - b) : (b - a);
end
endfunction

function [2:0] classify_shape_width5;
input [9:0] width5;
begin
    classify_shape_width5 =
        ((width5 == 10'd0) || (width5 > {2'd0, SHAPE_WIDTH5_VALID_MAX})) ? SHAPE_UNKNOWN :
        (width5 <= {2'd0, SHAPE_WIDTH5_CYL_MIN}) ? SHAPE_CONE :
        ((width5 > {2'd0, SHAPE_WIDTH5_CYL_MIN}) &&
         (width5 < {2'd0, SHAPE_WIDTH5_CUBE_MIN})) ? SHAPE_CYLINDER :
        (width5 >= {2'd0, SHAPE_WIDTH5_CUBE_MIN}) ? SHAPE_CUBE :
        SHAPE_UNKNOWN;
end
endfunction

assign shape_use_seg = (shape_seg_rows >= shape_best_rows);
assign shape_body_valid_rows = shape_use_seg ? shape_seg_rows : shape_best_rows;
assign shape_body_min_x = shape_use_seg ? shape_seg_min_x : shape_best_min_x;
assign shape_body_max_x = shape_use_seg ? shape_seg_max_x : shape_best_max_x;
assign shape_body_min_y = shape_use_seg ? shape_seg_min_y : shape_best_min_y;
assign shape_body_max_y = shape_use_seg ? shape_seg_max_y : shape_best_max_y;
assign shape_body_width_max = shape_use_seg ? shape_seg_width_max : shape_best_width_max;

assign shape_bbox_valid =
    (shape_body_valid_rows >= SHAPE_MIN_VALID_ROWS) &&
    (shape_body_min_x <= shape_body_max_x) &&
    (shape_body_min_y <= shape_body_max_y);
assign shape_bbox_w =
    shape_bbox_valid ? (shape_body_max_x - shape_body_min_x + 10'd1) : 10'd0;
assign shape_bbox_h =
    shape_bbox_valid ? (shape_body_max_y - shape_body_min_y + 10'd1) : 10'd0;

assign shape_valid_rows_metric_sum = {1'b0, shape_valid_rows_filt} + {1'b0, shape_body_valid_rows};
assign shape_bbox_w_metric_sum = {1'b0, shape_bbox_w_filt} + {1'b0, shape_bbox_w};
assign shape_bbox_h_metric_sum = {1'b0, shape_bbox_h_filt} + {1'b0, shape_bbox_h};
assign shape_width_max_metric_sum = {1'b0, shape_width_max_filt} + {1'b0, shape_body_width_max};
assign shape_valid_rows_metric =
    shape_metric_valid ? shape_valid_rows_metric_sum[8:1] : shape_body_valid_rows;
assign shape_bbox_w_metric =
    shape_metric_valid ? shape_bbox_w_metric_sum[10:1] : shape_bbox_w;
assign shape_bbox_h_metric =
    shape_metric_valid ? shape_bbox_h_metric_sum[10:1] : shape_bbox_h;
assign shape_width_max_metric =
    shape_metric_valid ? shape_width_max_metric_sum[10:1] : shape_body_width_max;

assign shape_size_valid =
    shape_bbox_valid &&
    (shape_bbox_w >= SHAPE_MIN_BBOX_W) &&
    (shape_bbox_h >= SHAPE_MIN_BBOX_H) &&
    (shape_body_width_max >= SHAPE_MIN_ROW_WIDTH);

assign shape_motion_width5_delta =
    abs_diff_u8(shape_fg_top_width_avg, shape_motion_prev_width5);
assign shape_motion_bbox_w_delta =
    abs_diff_u8(shape_fg_bbox_w, shape_motion_prev_bbox_w);
assign shape_motion_bbox_h_delta =
    abs_diff_u8(shape_fg_bbox_h, shape_motion_prev_bbox_h);
assign shape_motion_valid_rows_delta =
    abs_diff_u8(shape_fg_valid_rows, shape_motion_prev_valid_rows);
assign shape_motion_pixel_count_delta =
    (shape_fg_pixel_count >= shape_motion_prev_pixel_count) ?
    (shape_fg_pixel_count - shape_motion_prev_pixel_count) :
    (shape_motion_prev_pixel_count - shape_fg_pixel_count);
assign shape_motion_large =
    shape_motion_prev_valid &&
    ((shape_motion_width5_delta >= SHAPE_MOTION_WIDTH5_DELTA) ||
     (shape_motion_bbox_w_delta >= SHAPE_MOTION_BBOX_DELTA) ||
     (shape_motion_bbox_h_delta >= SHAPE_MOTION_BBOX_DELTA) ||
     (shape_motion_valid_rows_delta >= SHAPE_MOTION_ROWS_DELTA) ||
     (shape_motion_pixel_count_delta >= SHAPE_MOTION_PIXELS_DELTA));

assign shape_fg_complete =
    shape_bg_valid &&
    (!shape_bg_learn) &&
    (shape_fg_valid_rows >= SHAPE_MIN_VALID_ROWS) &&
    ({2'd0, shape_fg_bbox_w} >= SHAPE_MIN_BBOX_W) &&
    (shape_fg_bbox_h >= SHAPE_MIN_BBOX_H) &&
    (shape_fg_pixel_count >= SHAPE_MIN_FG_PIXELS);
assign shape_width_range_ok = (shape_fg_width_range <= SHAPE_WIDTH_RANGE_MAX);
assign shape_width5_base_id =
    !shape_fg_complete ? SHAPE_UNKNOWN :
    ((shape_fg_top_width_avg != 8'd0) &&
     (shape_fg_top_width_avg <= SHAPE_WIDTH5_CYL_MIN)) ? SHAPE_CONE :
    !shape_width_range_ok ? SHAPE_UNKNOWN :
    classify_shape_width5({2'd0, shape_fg_top_width_avg});
assign shape_candidate_id =
    shape_motion_large ? SHAPE_UNKNOWN : shape_width5_base_id;
assign shape_candidate_valid = (shape_candidate_id != SHAPE_UNKNOWN);

endmodule

`endif
