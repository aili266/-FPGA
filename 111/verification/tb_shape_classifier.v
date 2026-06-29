`timescale 1ns/1ps

module tb_shape_classifier;

localparam [2:0] SHAPE_UNKNOWN  = 3'd0;
localparam [2:0] SHAPE_CUBE     = 3'd1;
localparam [2:0] SHAPE_CYLINDER = 3'd2;
localparam [2:0] SHAPE_CONE     = 3'd3;

reg shape_bg_valid;
reg shape_bg_learn;
reg shape_metric_valid;
reg [7:0] shape_valid_rows_filt;
reg [9:0] shape_bbox_w_filt;
reg [9:0] shape_bbox_h_filt;
reg [9:0] shape_width_max_filt;

reg [7:0] shape_seg_rows;
reg [9:0] shape_seg_min_x;
reg [9:0] shape_seg_max_x;
reg [9:0] shape_seg_min_y;
reg [9:0] shape_seg_max_y;
reg [9:0] shape_seg_width_max;
reg [7:0] shape_best_rows;
reg [9:0] shape_best_min_x;
reg [9:0] shape_best_max_x;
reg [9:0] shape_best_min_y;
reg [9:0] shape_best_max_y;
reg [9:0] shape_best_width_max;

reg shape_motion_prev_valid;
reg [7:0] shape_motion_prev_width5;
reg [7:0] shape_motion_prev_bbox_w;
reg [7:0] shape_motion_prev_bbox_h;
reg [7:0] shape_motion_prev_valid_rows;
reg [12:0] shape_motion_prev_pixel_count;

reg [7:0] shape_fg_valid_rows;
reg [7:0] shape_fg_bbox_w;
reg [7:0] shape_fg_bbox_h;
reg [12:0] shape_fg_pixel_count;
reg [7:0] shape_fg_width_range;
reg [7:0] shape_fg_top_width_avg;

wire shape_size_valid;
wire [7:0] shape_valid_rows_metric;
wire [9:0] shape_bbox_w_metric;
wire [9:0] shape_bbox_h_metric;
wire [9:0] shape_width_max_metric;
wire shape_motion_large;
wire [2:0] shape_candidate_id;
wire shape_candidate_valid;

integer failures = 0;

shape_classifier dut (
    .shape_bg_valid(shape_bg_valid),
    .shape_bg_learn(shape_bg_learn),
    .shape_metric_valid(shape_metric_valid),
    .shape_valid_rows_filt(shape_valid_rows_filt),
    .shape_bbox_w_filt(shape_bbox_w_filt),
    .shape_bbox_h_filt(shape_bbox_h_filt),
    .shape_width_max_filt(shape_width_max_filt),
    .shape_seg_rows(shape_seg_rows),
    .shape_seg_min_x(shape_seg_min_x),
    .shape_seg_max_x(shape_seg_max_x),
    .shape_seg_min_y(shape_seg_min_y),
    .shape_seg_max_y(shape_seg_max_y),
    .shape_seg_width_max(shape_seg_width_max),
    .shape_best_rows(shape_best_rows),
    .shape_best_min_x(shape_best_min_x),
    .shape_best_max_x(shape_best_max_x),
    .shape_best_min_y(shape_best_min_y),
    .shape_best_max_y(shape_best_max_y),
    .shape_best_width_max(shape_best_width_max),
    .shape_motion_prev_valid(shape_motion_prev_valid),
    .shape_motion_prev_width5(shape_motion_prev_width5),
    .shape_motion_prev_bbox_w(shape_motion_prev_bbox_w),
    .shape_motion_prev_bbox_h(shape_motion_prev_bbox_h),
    .shape_motion_prev_valid_rows(shape_motion_prev_valid_rows),
    .shape_motion_prev_pixel_count(shape_motion_prev_pixel_count),
    .shape_fg_valid_rows(shape_fg_valid_rows),
    .shape_fg_bbox_w(shape_fg_bbox_w),
    .shape_fg_bbox_h(shape_fg_bbox_h),
    .shape_fg_pixel_count(shape_fg_pixel_count),
    .shape_fg_width_range(shape_fg_width_range),
    .shape_fg_top_width_avg(shape_fg_top_width_avg),
    .shape_size_valid(shape_size_valid),
    .shape_valid_rows_metric(shape_valid_rows_metric),
    .shape_bbox_w_metric(shape_bbox_w_metric),
    .shape_bbox_h_metric(shape_bbox_h_metric),
    .shape_width_max_metric(shape_width_max_metric),
    .shape_motion_large(shape_motion_large),
    .shape_candidate_id(shape_candidate_id),
    .shape_candidate_valid(shape_candidate_valid)
);

task set_common_shape;
begin
    shape_bg_valid = 1'b1;
    shape_bg_learn = 1'b0;
    shape_metric_valid = 1'b0;
    shape_valid_rows_filt = 8'd0;
    shape_bbox_w_filt = 10'd0;
    shape_bbox_h_filt = 10'd0;
    shape_width_max_filt = 10'd0;

    shape_seg_rows = 8'd24;
    shape_seg_min_x = 10'd10;
    shape_seg_max_x = 10'd39;
    shape_seg_min_y = 10'd20;
    shape_seg_max_y = 10'd49;
    shape_seg_width_max = 10'd30;
    shape_best_rows = 8'd18;
    shape_best_min_x = 10'd12;
    shape_best_max_x = 10'd37;
    shape_best_min_y = 10'd22;
    shape_best_max_y = 10'd47;
    shape_best_width_max = 10'd28;

    shape_motion_prev_valid = 1'b0;
    shape_motion_prev_width5 = 8'd0;
    shape_motion_prev_bbox_w = 8'd0;
    shape_motion_prev_bbox_h = 8'd0;
    shape_motion_prev_valid_rows = 8'd0;
    shape_motion_prev_pixel_count = 13'd0;

    shape_fg_valid_rows = 8'd24;
    shape_fg_bbox_w = 8'd30;
    shape_fg_bbox_h = 8'd30;
    shape_fg_pixel_count = 13'd600;
    shape_fg_width_range = 8'd10;
    shape_fg_top_width_avg = 8'd0;
end
endtask

task expect_shape;
input [2:0] expected_id;
input expected_valid;
input [8*32-1:0] label;
begin
    #1;
    if ((shape_candidate_id !== expected_id) ||
        (shape_candidate_valid !== expected_valid)) begin
        $display("FAIL: %0s expected valid=%0b id=%0d, got valid=%0b id=%0d motion=%0b size_valid=%0b",
                 label, expected_valid, expected_id,
                 shape_candidate_valid, shape_candidate_id,
                 shape_motion_large, shape_size_valid);
        failures = failures + 1;
    end else begin
        $display("PASS: %0s valid=%0b id=%0d motion=%0b size_valid=%0b",
                 label, shape_candidate_valid, shape_candidate_id,
                 shape_motion_large, shape_size_valid);
    end
end
endtask

initial begin
    $dumpfile("verification/results/shape_classifier.vcd");
    $dumpvars(0, tb_shape_classifier);

    set_common_shape();
    shape_fg_top_width_avg = 8'd5;
    expect_shape(SHAPE_CONE, 1'b1, "cone width5=5");

    set_common_shape();
    shape_fg_top_width_avg = 8'd12;
    expect_shape(SHAPE_CYLINDER, 1'b1, "cylinder width5=12");

    set_common_shape();
    shape_fg_top_width_avg = 8'd24;
    expect_shape(SHAPE_CUBE, 1'b1, "cube width5=24");

    set_common_shape();
    shape_motion_prev_valid = 1'b1;
    shape_motion_prev_width5 = 8'd24;
    shape_motion_prev_bbox_w = 8'd30;
    shape_motion_prev_bbox_h = 8'd30;
    shape_motion_prev_valid_rows = 8'd24;
    shape_motion_prev_pixel_count = 13'd600;
    shape_fg_top_width_avg = 8'd5;
    expect_shape(SHAPE_UNKNOWN, 1'b0, "large motion reject");

    if (failures == 0)
        $display("SHAPE_CLASSIFIER_TEST PASS");
    else
        $display("SHAPE_CLASSIFIER_TEST FAIL failures=%0d", failures);

    $finish;
end

endmodule
