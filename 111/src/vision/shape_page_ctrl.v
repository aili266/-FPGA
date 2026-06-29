`ifndef SHAPE_PAGE_CTRL_V
`define SHAPE_PAGE_CTRL_V

module shape_page_ctrl #(
    parameter [20:0] BUTTON_DEBOUNCE_MAX = 21'd1399999,
    parameter [4:0]  BG_LEARN_FRAMES = 5'd12
) (
    input  wire clk,
    input  wire rst_n,
    input  wire frame_done,
    input  wire shape_page_button,

    output reg  shape_page,
    output wire shape_page_enter,
    output wire bg_learn,
    output reg  bg_valid
);

reg [1:0] button_sync;
reg [20:0] button_debounce_cnt;
reg button_level;
reg button_level_d;
reg shape_page_prev;
reg [4:0] bg_learn_frames;

assign shape_page_enter = shape_page && !shape_page_prev;
assign bg_learn = (bg_learn_frames != 5'd0);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        button_sync <= 2'b00;
        button_debounce_cnt <= 21'd0;
        button_level <= 1'b0;
        button_level_d <= 1'b0;
        shape_page <= 1'b0;
        shape_page_prev <= 1'b0;
        bg_learn_frames <= 5'd0;
        bg_valid <= 1'b0;
    end else begin
        button_sync <= {button_sync[0], shape_page_button};
        button_level_d <= button_level;

        if (button_sync[1] == button_level) begin
            button_debounce_cnt <= 21'd0;
        end else if (button_debounce_cnt >= BUTTON_DEBOUNCE_MAX) begin
            button_debounce_cnt <= 21'd0;
            button_level <= button_sync[1];
        end else begin
            button_debounce_cnt <= button_debounce_cnt + 21'd1;
        end

        if (button_level && !button_level_d)
            shape_page <= ~shape_page;

        if (frame_done) begin
            shape_page_prev <= shape_page;
            if (shape_page_enter) begin
                bg_learn_frames <= BG_LEARN_FRAMES;
                bg_valid <= 1'b1;
            end else if (bg_learn_frames != 5'd0) begin
                bg_learn_frames <= bg_learn_frames - 5'd1;
                bg_valid <= 1'b1;
            end
        end
    end
end

endmodule

`endif
