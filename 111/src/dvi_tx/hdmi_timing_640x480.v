`ifndef HDMI_TIMING_640X480_V
`define HDMI_TIMING_640X480_V

module hdmi_timing_640x480 (
    input  wire clk,
    input  wire rst_n,
    output reg  [11:0] h_cnt,
    output reg  [11:0] v_cnt,
    output reg  hs,
    output reg  vs,
    output reg  de
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        h_cnt <= 12'd0;
        v_cnt <= 12'd0;
        hs <= 1'b0;
        vs <= 1'b0;
        de <= 1'b0;
    end else begin
        // 640x480@60 timing: H total 800, V total 525.
        if (h_cnt < 12'd799) begin
            h_cnt <= h_cnt + 1'b1;
        end else begin
            h_cnt <= 12'd0;
            if (v_cnt < 12'd524)
                v_cnt <= v_cnt + 1'b1;
            else
                v_cnt <= 12'd0;
        end

        hs <= ~((h_cnt >= 12'd656) && (h_cnt < 12'd752));
        vs <= ~((v_cnt >= 12'd490) && (v_cnt < 12'd492));
        de <= (h_cnt < 12'd640) && (v_cnt < 12'd480);
    end
end

endmodule

`endif
