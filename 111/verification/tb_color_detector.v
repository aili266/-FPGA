`timescale 1ns/1ps

module tb_color_detector;

localparam [2:0] COLOR_RED  = 3'd3;
localparam [2:0] COLOR_BLUE = 3'd4;

reg clk = 1'b0;
reg rst_n = 1'b0;
reg rgb_vs = 1'b0;
reg rgb_de = 1'b0;
reg [47:0] rgb_datax2 = 48'd0;

wire [2:0] color_id;
wire color_valid;
wire color_timer_start_pulse;
wire color_timer_stop_pulse;
wire color_timer_cancel_pulse;
wire fast_color_timer_start_pulse;
wire fast_color_timer_stop_pulse;
wire fast_color_timer_cancel_pulse;
wire stable_timer_running;
wire stable_timer_done;
wire stable_timer_result_valid;
wire [23:0] stable_timer_elapsed_us;
wire [23:0] stable_timer_live_us;
wire fast_timer_running;
wire fast_timer_done;
wire fast_timer_result_valid;
wire [23:0] fast_timer_elapsed_us;
wire [23:0] fast_timer_live_us;

integer failures = 0;
integer line_idx;
integer pair_idx;
reg [23:0] fast_red_latency_us;
reg [23:0] fast_blue_latency_us;
reg [23:0] stable_red_latency_us;
reg [23:0] stable_blue_latency_us;

always #5 clk = ~clk;

color_detector #(
    .HACT(12'd8),
    .VACT(11'd4),
    .COLOR_ROI_X_START(12'd0),
    .COLOR_ROI_X_END(12'd8),
    .COLOR_ROI_Y_START(11'd0),
    .COLOR_ROI_Y_END(11'd4),
    .FAST_COLOR_ROI_X_START(12'd0),
    .FAST_COLOR_ROI_X_END(12'd8),
    .FAST_COLOR_ROI_Y_START(11'd0),
    .FAST_COLOR_ROI_Y_END(11'd4),
    .VOTE_MIN_COUNT(18'd16),
    .VOTE_MARGIN(18'd4),
    .FAST_VOTE_MIN_COUNT(18'd8),
    .FAST_VOTE_MARGIN(18'd2),
    .FAST_LOCK_LINE_STREAK_NEW(4'd2),
    .FAST_LOCK_LINE_STREAK_SWITCH(4'd2)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .rgb_vs(rgb_vs),
    .rgb_de(rgb_de),
    .rgb_datax2(rgb_datax2),
    .timer_running(stable_timer_running),
    .fast_timer_running(fast_timer_running),
    .color_id(color_id),
    .color_valid(color_valid),
    .color_timer_start_pulse(color_timer_start_pulse),
    .color_timer_stop_pulse(color_timer_stop_pulse),
    .color_timer_cancel_pulse(color_timer_cancel_pulse),
    .fast_color_timer_start_pulse(fast_color_timer_start_pulse),
    .fast_color_timer_stop_pulse(fast_color_timer_stop_pulse),
    .fast_color_timer_cancel_pulse(fast_color_timer_cancel_pulse)
);

color_detect_timer #(
    .CLK_FREQ_HZ(1000000),
    .MAX_TIME_US(999999)
) u_stable_color_timer (
    .clk(clk),
    .rst_n(rst_n),
    .start_pulse(color_timer_start_pulse),
    .stop_pulse(color_timer_stop_pulse),
    .cancel_pulse(color_timer_cancel_pulse),
    .running(stable_timer_running),
    .done_pulse(stable_timer_done),
    .result_valid(stable_timer_result_valid),
    .elapsed_us(stable_timer_elapsed_us),
    .live_us(stable_timer_live_us)
);

color_detect_timer #(
    .CLK_FREQ_HZ(1000000),
    .MAX_TIME_US(999999)
) u_fast_color_timer (
    .clk(clk),
    .rst_n(rst_n),
    .start_pulse(fast_color_timer_start_pulse),
    .stop_pulse(fast_color_timer_stop_pulse),
    .cancel_pulse(fast_color_timer_cancel_pulse),
    .running(fast_timer_running),
    .done_pulse(fast_timer_done),
    .result_valid(fast_timer_result_valid),
    .elapsed_us(fast_timer_elapsed_us),
    .live_us(fast_timer_live_us)
);

function [47:0] pack_rgb_pair;
input [7:0] r;
input [7:0] g;
input [7:0] b;
begin
    pack_rgb_pair = {b, g, r, b, g, r};
end
endfunction

task send_frame;
input [7:0] r;
input [7:0] g;
input [7:0] b;
begin
    for (line_idx = 0; line_idx < 4; line_idx = line_idx + 1) begin
        for (pair_idx = 0; pair_idx < 4; pair_idx = pair_idx + 1) begin
            @(negedge clk);
            rgb_de = 1'b1;
            rgb_vs = 1'b0;
            rgb_datax2 = pack_rgb_pair(r, g, b);
        end

        @(negedge clk);
        rgb_de = 1'b0;
        rgb_datax2 = 48'd0;
    end

    @(negedge clk);
    rgb_vs = 1'b1;
    @(negedge clk);
    rgb_vs = 1'b0;
    repeat (2) @(negedge clk);
end
endtask

task expect_stable_color;
input [2:0] expected_id;
input [8*64-1:0] label;
begin
    if ((color_valid !== 1'b1) || (color_id !== expected_id)) begin
        $display("FAIL: %0s stable expected valid=1 id=%0d, got valid=%0b id=%0d",
                 label, expected_id, color_valid, color_id);
        failures = failures + 1;
    end else begin
        $display("PASS: %0s stable valid=1 id=%0d", label, color_id);
    end
end
endtask

task expect_fast_color;
input [2:0] expected_id;
input [8*64-1:0] label;
begin
    if ((dut.fast_color_valid !== 1'b1) || (dut.fast_color_id !== expected_id)) begin
        $display("FAIL: %0s fast expected valid=1 id=%0d, got valid=%0b id=%0d",
                 label, expected_id, dut.fast_color_valid, dut.fast_color_id);
        failures = failures + 1;
    end else begin
        $display("PASS: %0s fast valid=1 id=%0d", label, dut.fast_color_id);
    end
end
endtask

task expect_not_stable_yet;
input [2:0] old_id;
input [8*64-1:0] label;
begin
    if ((color_valid === 1'b1) && (color_id !== old_id)) begin
        $display("FAIL: %0s stable changed too early, got id=%0d", label, color_id);
        failures = failures + 1;
    end else begin
        $display("PASS: %0s stable not updated early valid=%0b id=%0d",
                 label, color_valid, color_id);
    end
end
endtask

task expect_timer_valid;
input result_valid;
input [23:0] elapsed_us;
input [8*64-1:0] label;
begin
    if ((result_valid !== 1'b1) || (elapsed_us == 24'd0)) begin
        $display("FAIL: %0s timer expected result_valid=1 elapsed_us>0, got valid=%0b elapsed_us=%0d",
                 label, result_valid, elapsed_us);
        failures = failures + 1;
    end else begin
        $display("PASS: %0s timer valid=1 elapsed_us=%0d", label, elapsed_us);
    end
end
endtask

task expect_less_than;
input [23:0] lhs;
input [23:0] rhs;
input [8*64-1:0] label;
begin
    if (!(lhs < rhs)) begin
        $display("FAIL: %0s expected %0d < %0d", label, lhs, rhs);
        failures = failures + 1;
    end else begin
        $display("PASS: %0s %0d < %0d", label, lhs, rhs);
    end
end
endtask

initial begin
    $dumpfile("verification/results/color_detector.vcd");
    $dumpvars(0, tb_color_detector);

    repeat (4) @(negedge clk);
    rst_n = 1'b1;
    repeat (2) @(negedge clk);

    send_frame(8'd200, 8'd40, 8'd25);
    expect_fast_color(COLOR_RED, "red after first frame");
    expect_not_stable_yet(COLOR_RED, "red after first frame");
    expect_timer_valid(fast_timer_result_valid, fast_timer_elapsed_us, "fast red latency");
    fast_red_latency_us = fast_timer_elapsed_us;

    send_frame(8'd200, 8'd40, 8'd25);
    expect_stable_color(COLOR_RED, "red after two matching frames");
    expect_timer_valid(stable_timer_result_valid, stable_timer_elapsed_us, "stable red latency");
    stable_red_latency_us = stable_timer_elapsed_us;
    expect_less_than(fast_red_latency_us, stable_red_latency_us, "red fast latency is shorter");

    send_frame(8'd35, 8'd130, 8'd150);
    expect_fast_color(COLOR_BLUE, "blue after first frame");
    expect_not_stable_yet(COLOR_RED, "blue after first frame");
    expect_timer_valid(fast_timer_result_valid, fast_timer_elapsed_us, "fast blue latency");
    fast_blue_latency_us = fast_timer_elapsed_us;

    send_frame(8'd35, 8'd130, 8'd150);
    expect_stable_color(COLOR_BLUE, "blue after two matching frames");
    expect_timer_valid(stable_timer_result_valid, stable_timer_elapsed_us, "stable blue latency");
    stable_blue_latency_us = stable_timer_elapsed_us;
    expect_less_than(fast_blue_latency_us, stable_blue_latency_us, "blue fast latency is shorter");

    if (failures == 0)
        $display("COLOR_DETECTOR_DUAL_PATH_TIMER_TEST PASS");
    else
        $display("COLOR_DETECTOR_DUAL_PATH_TIMER_TEST FAIL failures=%0d", failures);

    $finish;
end

endmodule
