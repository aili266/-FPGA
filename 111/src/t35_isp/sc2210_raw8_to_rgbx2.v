`timescale 1ns / 1ps

module sc2210_raw8_to_rgbx2 #(
    parameter [13:0] IMG_HDISP = 14'd1920,
    parameter [13:0] IMG_VDISP = 14'd1080,
    parameter [1:0]  BAYER_MIRROR = 2'b00
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        mipi_hsync,
    input  wire        mipi_valid,
    input  wire [63:0] mipi_data,

    output reg         rgb_vs,
    output reg         rgb_de,
    output reg  [47:0] rgb_datax2,

    output wire        raw_frame_valid,
    output wire        raw_pixel_de,
    output reg         frame_toggle,
    output wire        fifo_prog_full,
    output wire        fifo_full,
    output wire        fifo_overflow,
    output wire        fifo_underflow
);

reg        mipi_hsync_r;
reg        mipi_valid_r;
reg [63:0] mipi_data_r;
reg        frame_valid_r;
reg [11:0] frame_gap_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mipi_hsync_r <= 1'b0;
        mipi_valid_r <= 1'b0;
        mipi_data_r <= 64'd0;
        frame_valid_r <= 1'b0;
        frame_gap_cnt <= 12'd0;
        frame_toggle <= 1'b0;
    end else begin
        mipi_hsync_r <= mipi_hsync;
        mipi_valid_r <= mipi_valid;
        mipi_data_r <= mipi_data;

        if (mipi_hsync) begin
            if (!frame_valid_r)
                frame_toggle <= ~frame_toggle;
            frame_valid_r <= 1'b1;
            frame_gap_cnt <= 12'd0;
        end else if (frame_valid_r) begin
            frame_gap_cnt <= frame_gap_cnt + 12'd1;
            if (&frame_gap_cnt)
                frame_valid_r <= 1'b0;
        end else begin
            frame_gap_cnt <= 12'd0;
        end
    end
end

assign raw_frame_valid = frame_valid_r;

wire [63:0] mipi_data_reordered = {
    mipi_data_r[7:0],
    mipi_data_r[15:8],
    mipi_data_r[23:16],
    mipi_data_r[31:24],
    mipi_data_r[39:32],
    mipi_data_r[47:40],
    mipi_data_r[55:48],
    mipi_data_r[63:56]
};

wire        fifo_empty;
wire        fifo_almost_full;
wire        fifo_almost_empty;
wire        fifo_wr_ack;
wire        fifo_rd_valid;
wire [7:0]  fifo_rdata;
wire [9:0]  fifo_wr_datacount;
wire [12:0] fifo_rd_datacount;
wire        fifo_rst_busy;
wire        fifo_rd_en;

FIFO_W64R8 u_raw_fifo (
    .almost_full_o(fifo_almost_full),
    .prog_full_o(fifo_prog_full),
    .full_o(fifo_full),
    .overflow_o(fifo_overflow),
    .wr_ack_o(fifo_wr_ack),
    .empty_o(fifo_empty),
    .almost_empty_o(fifo_almost_empty),
    .underflow_o(fifo_underflow),
    .rd_valid_o(fifo_rd_valid),
    .rdata(fifo_rdata),
    .wr_clk_i(clk),
    .rd_clk_i(clk),
    .wr_en_i(frame_valid_r && mipi_hsync_r && mipi_valid_r && !fifo_full),
    .rd_en_i(fifo_rd_en),
    .wdata(mipi_data_reordered),
    .wr_datacount_o(fifo_wr_datacount),
    .rst_busy(fifo_rst_busy),
    .rd_datacount_o(fifo_rd_datacount),
    .a_rst_i(!rst_n)
);

reg [13:0] raw_x;
reg        raw_line_active;

wire start_raw_line = frame_valid_r && !raw_line_active && !fifo_empty && !fifo_rst_busy;
wire raw_pixel_fire = (raw_line_active || start_raw_line) && fifo_rd_valid;

assign fifo_rd_en = raw_pixel_fire;
assign raw_pixel_de = raw_pixel_fire;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        raw_x <= 14'd0;
        raw_line_active <= 1'b0;
    end else if (!frame_valid_r) begin
        raw_x <= 14'd0;
        raw_line_active <= 1'b0;
    end else if (raw_pixel_fire) begin
        raw_line_active <= 1'b1;
        if (raw_x == IMG_HDISP - 1'b1) begin
            raw_x <= 14'd0;
            raw_line_active <= 1'b0;
        end else begin
            raw_x <= raw_x + 14'd1;
        end
    end
end

wire        rgb_pixel_vs;
wire        rgb_pixel_href;
wire        rgb_pixel_hsync;
wire [7:0]  rgb_pixel_r;
wire [7:0]  rgb_pixel_g;
wire [7:0]  rgb_pixel_b;

VIP_RAW8_RGB888 #(
    .IMG_HDISP(IMG_HDISP),
    .IMG_VDISP(IMG_VDISP)
) u_bayer2rgb (
    .clk(clk),
    .rst_n(rst_n),
    .mirror(BAYER_MIRROR),
    .per_frame_vsync(frame_valid_r),
    .per_frame_href(raw_pixel_fire),
    .per_frame_hsync(raw_pixel_fire),
    .per_img_RAW(fifo_rdata),
    .post_frame_vsync(rgb_pixel_vs),
    .post_frame_href(rgb_pixel_href),
    .post_frame_hsync(rgb_pixel_hsync),
    .post_img_red(rgb_pixel_r),
    .post_img_green(rgb_pixel_g),
    .post_img_blue(rgb_pixel_b)
);

reg        pair_has_first;
reg [7:0]  pair_r0;
reg [7:0]  pair_g0;
reg [7:0]  pair_b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rgb_vs <= 1'b0;
        rgb_de <= 1'b0;
        rgb_datax2 <= 48'd0;
        pair_has_first <= 1'b0;
        pair_r0 <= 8'd0;
        pair_g0 <= 8'd0;
        pair_b0 <= 8'd0;
    end else begin
        rgb_vs <= rgb_pixel_vs;
        rgb_de <= 1'b0;

        if (!rgb_pixel_href) begin
            pair_has_first <= 1'b0;
        end else if (!pair_has_first) begin
            pair_has_first <= 1'b1;
            pair_r0 <= rgb_pixel_r;
            pair_g0 <= rgb_pixel_g;
            pair_b0 <= rgb_pixel_b;
        end else begin
            pair_has_first <= 1'b0;
            rgb_de <= 1'b1;
            rgb_datax2 <= {
                pair_b0, pair_g0, pair_r0,
                rgb_pixel_b, rgb_pixel_g, rgb_pixel_r
            };
        end
    end
end

endmodule
