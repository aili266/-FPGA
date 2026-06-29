`ifndef UI_COLOR_RENDERER_V
`define UI_COLOR_RENDERER_V

module ui_color_renderer #(
    parameter [2:0] COLOR_UNKNOWN = 3'd0,
    parameter [2:0] COLOR_BLACK = 3'd1,
    parameter [2:0] COLOR_WHITE = 3'd2,
    parameter [2:0] COLOR_RED = 3'd3,
    parameter [2:0] COLOR_BLUE = 3'd4,
    parameter [2:0] COLOR_YELLOW = 3'd5
) (
    input  wire [11:0] h_cnt,
    input  wire [11:0] v_cnt,
    input  wire [2:0]  color_id,
    input  wire        color_valid,
    input  wire [23:0] color_rgb,
    output reg         main_pixel_en,
    output reg  [23:0] main_pixel_rgb,
    output reg         candidate_pixel_en,
    output reg  [23:0] candidate_pixel_rgb
);

localparam [23:0] UI_CAND_BG      = 24'h16161E;
localparam [23:0] UI_CAND_BORDER  = 24'h22222A;
localparam [23:0] UI_PULSE_COLOR  = 24'h30D070;

localparam [11:0] UI_CAND_Y       = 12'd398;
localparam [11:0] COL_CAND_W      = 12'd88;
localparam [11:0] COL_CAND_H      = 12'd32;
localparam [11:0] COL_CAND_GAP    = 12'd12;
localparam [11:0] COL_BLOCK_X0    = 12'd184;
localparam [11:0] COL_BLOCK_X1    = 12'd456;
localparam [11:0] COL_BLOCK_Y0    = 12'd66;
localparam [11:0] COL_BLOCK_Y1    = 12'd338;
localparam [11:0] COL_BORDER_X0   = 12'd178;
localparam [11:0] COL_BORDER_X1   = 12'd462;
localparam [11:0] COL_BORDER_Y0   = 12'd60;
localparam [11:0] COL_BORDER_Y1   = 12'd344;

wire [11:0] col_cand_total_w = COL_CAND_W * 12'd5 + COL_CAND_GAP * 12'd4;
wire [11:0] col_cand_x0 = (12'd640 - col_cand_total_w) >> 1;
wire col_cand0_hit = (h_cnt >= col_cand_x0) && (h_cnt < col_cand_x0 + COL_CAND_W) &&
                     (v_cnt >= UI_CAND_Y) && (v_cnt < UI_CAND_Y + COL_CAND_H);
wire col_cand1_hit = (h_cnt >= col_cand_x0 + COL_CAND_W + COL_CAND_GAP) &&
                     (h_cnt < col_cand_x0 + 12'd2*COL_CAND_W + COL_CAND_GAP) &&
                     (v_cnt >= UI_CAND_Y) && (v_cnt < UI_CAND_Y + COL_CAND_H);
wire col_cand2_hit = (h_cnt >= col_cand_x0 + 12'd2*(COL_CAND_W + COL_CAND_GAP)) &&
                     (h_cnt < col_cand_x0 + 12'd3*COL_CAND_W + 12'd2*COL_CAND_GAP) &&
                     (v_cnt >= UI_CAND_Y) && (v_cnt < UI_CAND_Y + COL_CAND_H);
wire col_cand3_hit = (h_cnt >= col_cand_x0 + 12'd3*(COL_CAND_W + COL_CAND_GAP)) &&
                     (h_cnt < col_cand_x0 + 12'd4*COL_CAND_W + 12'd3*COL_CAND_GAP) &&
                     (v_cnt >= UI_CAND_Y) && (v_cnt < UI_CAND_Y + COL_CAND_H);
wire col_cand4_hit = (h_cnt >= col_cand_x0 + 12'd4*(COL_CAND_W + COL_CAND_GAP)) &&
                     (h_cnt < col_cand_x0 + 12'd5*COL_CAND_W + 12'd4*COL_CAND_GAP) &&
                     (v_cnt >= UI_CAND_Y) && (v_cnt < UI_CAND_Y + COL_CAND_H);

always @(*) begin
    main_pixel_en = 1'b0;
    main_pixel_rgb = 24'h000000;

    if (h_cnt >= COL_BORDER_X0 && h_cnt < COL_BORDER_X1 &&
        v_cnt >= COL_BORDER_Y0 && v_cnt < COL_BORDER_Y1) begin
        main_pixel_en = 1'b1;
        main_pixel_rgb = 24'hFFFFFF;
    end

    if (h_cnt >= COL_BLOCK_X0 && h_cnt < COL_BLOCK_X1 &&
        v_cnt >= COL_BLOCK_Y0 && v_cnt < COL_BLOCK_Y1) begin
        main_pixel_en = 1'b1;
        if (color_valid && color_id != COLOR_UNKNOWN)
            main_pixel_rgb = color_rgb;
        else
            main_pixel_rgb = 24'h505050;
    end
end

always @(*) begin
    candidate_pixel_en = 1'b0;
    candidate_pixel_rgb = 24'h000000;

    if (col_cand0_hit) begin
        candidate_pixel_en = 1'b1;
        candidate_pixel_rgb = UI_CAND_BG;
        if (h_cnt >= col_cand_x0 + 12'd4 && h_cnt < col_cand_x0 + COL_CAND_W - 12'd4 &&
            v_cnt >= UI_CAND_Y + 12'd4 && v_cnt < UI_CAND_Y + 12'd28)
            candidate_pixel_rgb = 24'h000000;
        if (h_cnt < col_cand_x0 + 12'd2 || h_cnt >= col_cand_x0 + COL_CAND_W - 12'd2 ||
            v_cnt < UI_CAND_Y + 12'd2 || v_cnt >= UI_CAND_Y + COL_CAND_H - 12'd2)
            candidate_pixel_rgb = (color_id == COLOR_BLACK) ? UI_PULSE_COLOR : UI_CAND_BORDER;
    end else if (col_cand1_hit) begin
        candidate_pixel_en = 1'b1;
        candidate_pixel_rgb = UI_CAND_BG;
        if (h_cnt >= col_cand_x0 + COL_CAND_W + COL_CAND_GAP + 12'd4 &&
            h_cnt <  col_cand_x0 + COL_CAND_W + COL_CAND_GAP + COL_CAND_W - 12'd4 &&
            v_cnt >= UI_CAND_Y + 12'd4 && v_cnt < UI_CAND_Y + 12'd28)
            candidate_pixel_rgb = 24'hFFFFFF;
        if (h_cnt < col_cand_x0 + COL_CAND_W + COL_CAND_GAP + 12'd2 ||
            h_cnt >= col_cand_x0 + 12'd2*COL_CAND_W + COL_CAND_GAP - 12'd2 ||
            v_cnt < UI_CAND_Y + 12'd2 || v_cnt >= UI_CAND_Y + COL_CAND_H - 12'd2)
            candidate_pixel_rgb = (color_id == COLOR_WHITE) ? UI_PULSE_COLOR : UI_CAND_BORDER;
    end else if (col_cand2_hit) begin
        candidate_pixel_en = 1'b1;
        candidate_pixel_rgb = UI_CAND_BG;
        if (h_cnt >= col_cand_x0 + 12'd2*(COL_CAND_W + COL_CAND_GAP) + 12'd4 &&
            h_cnt <  col_cand_x0 + 12'd3*COL_CAND_W + 12'd2*COL_CAND_GAP - 12'd4 &&
            v_cnt >= UI_CAND_Y + 12'd4 && v_cnt < UI_CAND_Y + 12'd28)
            candidate_pixel_rgb = 24'hFF2020;
        if (h_cnt < col_cand_x0 + 12'd2*(COL_CAND_W + COL_CAND_GAP) + 12'd2 ||
            h_cnt >= col_cand_x0 + 12'd3*COL_CAND_W + 12'd2*COL_CAND_GAP - 12'd2 ||
            v_cnt < UI_CAND_Y + 12'd2 || v_cnt >= UI_CAND_Y + COL_CAND_H - 12'd2)
            candidate_pixel_rgb = (color_id == COLOR_RED) ? UI_PULSE_COLOR : UI_CAND_BORDER;
    end else if (col_cand3_hit) begin
        candidate_pixel_en = 1'b1;
        candidate_pixel_rgb = UI_CAND_BG;
        if (h_cnt >= col_cand_x0 + 12'd3*(COL_CAND_W + COL_CAND_GAP) + 12'd4 &&
            h_cnt <  col_cand_x0 + 12'd4*COL_CAND_W + 12'd3*COL_CAND_GAP - 12'd4 &&
            v_cnt >= UI_CAND_Y + 12'd4 && v_cnt < UI_CAND_Y + 12'd28)
            candidate_pixel_rgb = 24'h2050FF;
        if (h_cnt < col_cand_x0 + 12'd3*(COL_CAND_W + COL_CAND_GAP) + 12'd2 ||
            h_cnt >= col_cand_x0 + 12'd4*COL_CAND_W + 12'd3*COL_CAND_GAP - 12'd2 ||
            v_cnt < UI_CAND_Y + 12'd2 || v_cnt >= UI_CAND_Y + COL_CAND_H - 12'd2)
            candidate_pixel_rgb = (color_id == COLOR_BLUE) ? UI_PULSE_COLOR : UI_CAND_BORDER;
    end else if (col_cand4_hit) begin
        candidate_pixel_en = 1'b1;
        candidate_pixel_rgb = UI_CAND_BG;
        if (h_cnt >= col_cand_x0 + 12'd4*(COL_CAND_W + COL_CAND_GAP) + 12'd4 &&
            h_cnt <  col_cand_x0 + 12'd5*COL_CAND_W + 12'd4*COL_CAND_GAP - 12'd4 &&
            v_cnt >= UI_CAND_Y + 12'd4 && v_cnt < UI_CAND_Y + 12'd28)
            candidate_pixel_rgb = 24'hFFD800;
        if (h_cnt < col_cand_x0 + 12'd4*(COL_CAND_W + COL_CAND_GAP) + 12'd2 ||
            h_cnt >= col_cand_x0 + 12'd5*COL_CAND_W + 12'd4*COL_CAND_GAP - 12'd2 ||
            v_cnt < UI_CAND_Y + 12'd2 || v_cnt >= UI_CAND_Y + COL_CAND_H - 12'd2)
            candidate_pixel_rgb = (color_id == COLOR_YELLOW) ? UI_PULSE_COLOR : UI_CAND_BORDER;
    end
end

endmodule

`endif
