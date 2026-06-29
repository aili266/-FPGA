`ifndef UI_MODE_LATCH_V
`define UI_MODE_LATCH_V

module ui_mode_latch #(
    parameter UI_MODE_COLOR = 1'b0
) (
    input  wire clk,
    input  wire rst_n,
    input  wire frame_start,
    input  wire shape_page_cam,
    output reg  ui_mode
);

reg [1:0] ui_mode_sync;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ui_mode_sync <= 2'b00;
        ui_mode <= UI_MODE_COLOR;
    end else begin
        ui_mode_sync <= {ui_mode_sync[0], shape_page_cam};
        if (frame_start)
            ui_mode <= ui_mode_sync[1];
    end
end

endmodule

`endif
