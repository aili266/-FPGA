// Microsecond timer used by the color page.
// It starts on start_pulse, stops and latches elapsed_us on stop_pulse, and can
// be canceled if frame-level evidence becomes unstable before confirmation.
module color_detect_timer #(
    parameter integer CLK_FREQ_HZ = 74250000,
    parameter integer MAX_TIME_US = 999999
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start_pulse,
    input  wire        stop_pulse,
    input  wire        cancel_pulse,
    output reg         running,
    output reg         done_pulse,
    output reg         result_valid,
    output reg [23:0]  elapsed_us,
    output reg [23:0]  live_us
);

function integer clog2;
input integer value;
integer i;
begin
    value = value - 1;
    for (i = 0; value > 0; i = i + 1)
        value = value >> 1;
    clog2 = (i == 0) ? 1 : i;
end
endfunction

localparam integer US_NUMERATOR = 1000000;
localparam integer ACC_W = clog2(CLK_FREQ_HZ + US_NUMERATOR);
localparam [23:0] MAX_TIME_US_VALUE = MAX_TIME_US[23:0];

reg [ACC_W-1:0] us_accum;
wire [ACC_W:0] us_accum_next = us_accum + US_NUMERATOR;

// Fractional accumulator converts arbitrary CLK_FREQ_HZ to 1 us ticks without
// needing CLK_FREQ_HZ to divide exactly by 1 MHz.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        running      <= 1'b0;
        done_pulse   <= 1'b0;
        result_valid <= 1'b0;
        elapsed_us   <= 24'd0;
        live_us      <= 24'd0;
        us_accum     <= {ACC_W{1'b0}};
    end else begin
        done_pulse <= 1'b0;

        if (cancel_pulse) begin
            running      <= 1'b0;
            result_valid <= 1'b0;
            elapsed_us   <= 24'd0;
            live_us      <= 24'd0;
            us_accum     <= {ACC_W{1'b0}};
        end else if (start_pulse && !running) begin
            running      <= 1'b1;
            result_valid <= 1'b0;
            elapsed_us   <= 24'd0;
            live_us      <= 24'd0;
            us_accum     <= {ACC_W{1'b0}};
        end else if (running) begin
            if (stop_pulse) begin
                running      <= 1'b0;
                elapsed_us   <= live_us;
                done_pulse   <= 1'b1;
                result_valid <= 1'b1;
                us_accum     <= {ACC_W{1'b0}};
            end else if (us_accum_next >= CLK_FREQ_HZ) begin
                us_accum <= us_accum_next - CLK_FREQ_HZ;
                if (live_us < MAX_TIME_US_VALUE) begin
                    live_us <= live_us + 24'd1;
                end else begin
                    // Safety stop: avoid staying stuck at the saturation value forever.
                    running      <= 1'b0;
                    result_valid <= 1'b0;
                    elapsed_us   <= 24'd0;
                    live_us      <= 24'd0;
                    us_accum     <= {ACC_W{1'b0}};
                end
            end else begin
                us_accum <= us_accum_next[ACC_W-1:0];
            end
        end
    end
end

endmodule
