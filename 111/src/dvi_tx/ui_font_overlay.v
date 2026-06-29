`ifndef UI_FONT_OVERLAY_V
`define UI_FONT_OVERLAY_V

module ui_font_overlay #(
    parameter UI_MODE_COLOR = 1'b0,
    parameter UI_MODE_SHAPE = 1'b1,
    parameter [2:0] SHAPE_UNKNOWN = 3'd0,
    parameter [2:0] SHAPE_CUBE = 3'd1,
    parameter [2:0] SHAPE_CYLINDER = 3'd2,
    parameter [2:0] SHAPE_CONE = 3'd3
) (
    input  wire        clk,
    input  wire        arst_n,
    input  wire [11:0] h_cnt,
    input  wire [11:0] v_cnt,
    input  wire        ui_mode,
    input  wire [2:0]  shape_display_id,
    input  wire [23:0] timer_display_us_hdmi_clamped,
    input  wire [23:0] shape_latency_display_us_hdmi_clamped,
    input  wire [23:0] latency_highlight_color_hdmi,
    input  wire [23:0] latency_unit_color_hdmi,
    output reg         font_pixel_en,
    output reg  [23:0] font_pixel_color
);

localparam [23:0] UI_LATENCY_ON   = 24'hFFD060;
localparam [23:0] UI_LABEL_COLOR  = 24'h555566;
localparam [23:0] UI_CUBE_THEME   = 24'hF3A847;
localparam [23:0] UI_CYL_THEME    = 24'h62CC73;
localparam [23:0] UI_CONE_THEME   = 24'h58D7D0;
localparam [23:0] UI_PULSE_COLOR  = 24'h30D070;
localparam [11:0] UI_CAND_Y       = 12'd398;
localparam [11:0] SH_CAND_W       = 12'd170;
localparam [11:0] SH_CAND_GAP     = 12'd18;

reg [8:0] font_addr;
wire [7:0] font_row_bits;
reg [4:0] font_char_idx;
reg [4:0] font_char_code;
reg [4:0] font_row_idx;
reg [2:0] font_col_idx;
reg [8:0] font_x_offset;
reg [23:0] timer_text_color;
reg [3:0] disp_color_latency_digit_5;
reg [3:0] disp_color_latency_digit_4;
reg [3:0] disp_color_latency_digit_3;
reg [3:0] disp_color_latency_digit_2;
reg [3:0] disp_color_latency_digit_1;
reg [3:0] disp_color_latency_digit_0;
reg [3:0] disp_shape_latency_digit_5;
reg [3:0] disp_shape_latency_digit_4;
reg [3:0] disp_shape_latency_digit_3;
reg [3:0] disp_shape_latency_digit_2;
reg [3:0] disp_shape_latency_digit_1;
reg [3:0] disp_shape_latency_digit_0;

wire [11:0] sh_cand_total_w = SH_CAND_W * 12'd3 + SH_CAND_GAP * 12'd2;
wire [11:0] sh_cand_x0 = (12'd640 - sh_cand_total_w) >> 1;

function [8:0] font_base_for_code;
input [4:0] code;
begin
    case (code)
        5'd0:  font_base_for_code = 9'h000; // 0
        5'd1:  font_base_for_code = 9'h010; // 1
        5'd2:  font_base_for_code = 9'h020; // 2
        5'd3:  font_base_for_code = 9'h030; // 3
        5'd4:  font_base_for_code = 9'h040; // 4
        5'd5:  font_base_for_code = 9'h050; // 5
        5'd6:  font_base_for_code = 9'h060; // 6
        5'd7:  font_base_for_code = 9'h070; // 7
        5'd8:  font_base_for_code = 9'h080; // 8
        5'd9:  font_base_for_code = 9'h090; // 9
        5'd10: font_base_for_code = 9'h0A0; // :
        5'd11: font_base_for_code = 9'h0B0; // R
        5'd12: font_base_for_code = 9'h0C0; // G
        5'd13: font_base_for_code = 9'h0D0; // B
        5'd14: font_base_for_code = 9'h0E0; // C
        5'd15: font_base_for_code = 9'h0F0; // S
        5'd16: font_base_for_code = 9'h100; // L
        5'd17: font_base_for_code = 9'h110; // A
        5'd18: font_base_for_code = 9'h120; // T
        5'd19: font_base_for_code = 9'h130; // E
        5'd20: font_base_for_code = 9'h140; // N
        5'd21: font_base_for_code = 9'h150; // Y
        5'd22: font_base_for_code = 9'h160; // U
        5'd23: font_base_for_code = 9'h170; // O
        5'd24: font_base_for_code = 9'h180; // K
        5'd25: font_base_for_code = 9'h190; // H
        5'd26: font_base_for_code = 9'h1A0; // I
        5'd27: font_base_for_code = 9'h1B0; // D
        5'd28: font_base_for_code = 9'h1C0; // W
        5'd29: font_base_for_code = 9'h1D0; // SP
        5'd30: font_base_for_code = 9'h1E0; // P
        5'd31: font_base_for_code = 9'h1F0; // .
        default: font_base_for_code = 9'h1D0;
    endcase
end
endfunction


// Convert binary result/debug values to decimal digits once per HDMI frame.
// font drawing below consumes these packed digits.
always @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
        disp_color_latency_digit_5 <= 4'd0;
        disp_color_latency_digit_4 <= 4'd0;
        disp_color_latency_digit_3 <= 4'd0;
        disp_color_latency_digit_2 <= 4'd0;
        disp_color_latency_digit_1 <= 4'd0;
        disp_color_latency_digit_0 <= 4'd0;
        disp_shape_latency_digit_5 <= 4'd0;
        disp_shape_latency_digit_4 <= 4'd0;
        disp_shape_latency_digit_3 <= 4'd0;
        disp_shape_latency_digit_2 <= 4'd0;
        disp_shape_latency_digit_1 <= 4'd0;
        disp_shape_latency_digit_0 <= 4'd0;
    end else if ((h_cnt == 12'd0) && (v_cnt == 12'd0)) begin
        disp_color_latency_digit_5 <= timer_display_us_hdmi_clamped / 24'd100000;
        disp_color_latency_digit_4 <= (timer_display_us_hdmi_clamped / 24'd10000) % 10;
        disp_color_latency_digit_3 <= (timer_display_us_hdmi_clamped / 24'd1000) % 10;
        disp_color_latency_digit_2 <= (timer_display_us_hdmi_clamped / 24'd100) % 10;
        disp_color_latency_digit_1 <= (timer_display_us_hdmi_clamped / 24'd10) % 10;
        disp_color_latency_digit_0 <= timer_display_us_hdmi_clamped % 10;
        disp_shape_latency_digit_5 <= shape_latency_display_us_hdmi_clamped / 24'd100000;
        disp_shape_latency_digit_4 <= (shape_latency_display_us_hdmi_clamped / 24'd10000) % 10;
        disp_shape_latency_digit_3 <= (shape_latency_display_us_hdmi_clamped / 24'd1000) % 10;
        disp_shape_latency_digit_2 <= (shape_latency_display_us_hdmi_clamped / 24'd100) % 10;
        disp_shape_latency_digit_1 <= (shape_latency_display_us_hdmi_clamped / 24'd10) % 10;
        disp_shape_latency_digit_0 <= shape_latency_display_us_hdmi_clamped % 10;
    end
end


// New unified font renderer for the redesigned UI.
always @(*) begin
    font_addr = 9'd0;
    font_pixel_en = 1'b0;
    font_pixel_color = 24'hFFFFFF;
    font_char_idx = 5'd0;
    font_char_code = 5'd29; // SP
    font_row_idx = 5'd0;
    font_col_idx = 3'd0;
    font_x_offset = 9'd0;
    timer_text_color = UI_LATENCY_ON;

    // --- Top bar center: page title, 2x bitmap scale ---
    if (v_cnt >= 12'd7 && v_cnt < 12'd23 &&
        h_cnt >= 12'd184 && h_cnt < 12'd456) begin
        font_x_offset = h_cnt - 12'd184;
        font_char_idx = font_x_offset >> 4;
        font_row_idx = (v_cnt - 12'd7) >> 1;
        font_col_idx = font_x_offset[3:1];
        font_pixel_color = (ui_mode == UI_MODE_SHAPE) ? 24'h6CB4EE : UI_PULSE_COLOR;
        if (ui_mode == UI_MODE_SHAPE) begin
            case (font_char_idx)
                5'd0:  font_char_code = 5'd15; // S
                5'd1:  font_char_code = 5'd25; // H
                5'd2:  font_char_code = 5'd17; // A
                5'd3:  font_char_code = 5'd30; // P
                5'd4:  font_char_code = 5'd19; // E
                5'd5:  font_char_code = 5'd29; // SP
                5'd6:  font_char_code = 5'd11; // R
                5'd7:  font_char_code = 5'd19; // E
                5'd8:  font_char_code = 5'd14; // C
                5'd9:  font_char_code = 5'd23; // O
                5'd10: font_char_code = 5'd12; // G
                5'd11: font_char_code = 5'd20; // N
                5'd12: font_char_code = 5'd26; // I
                5'd13: font_char_code = 5'd18; // T
                5'd14: font_char_code = 5'd26; // I
                5'd15: font_char_code = 5'd23; // O
                5'd16: font_char_code = 5'd20; // N
                default: font_char_code = 5'd29;
            endcase
        end else begin
            case (font_char_idx)
                5'd0:  font_char_code = 5'd14; // C
                5'd1:  font_char_code = 5'd23; // O
                5'd2:  font_char_code = 5'd16; // L
                5'd3:  font_char_code = 5'd23; // O
                5'd4:  font_char_code = 5'd11; // R
                5'd5:  font_char_code = 5'd29; // SP
                5'd6:  font_char_code = 5'd11; // R
                5'd7:  font_char_code = 5'd19; // E
                5'd8:  font_char_code = 5'd14; // C
                5'd9:  font_char_code = 5'd23; // O
                5'd10: font_char_code = 5'd12; // G
                5'd11: font_char_code = 5'd20; // N
                5'd12: font_char_code = 5'd26; // I
                5'd13: font_char_code = 5'd18; // T
                5'd14: font_char_code = 5'd26; // I
                5'd15: font_char_code = 5'd23; // O
                5'd16: font_char_code = 5'd20; // N
                default: font_char_code = 5'd29;
            endcase
        end
        font_addr = font_base_for_code(font_char_code) + font_row_idx;
        font_pixel_en = font_row_bits[7 - font_col_idx];
    end

    // --- Top bar right badge text, shape page only ---
    if ((ui_mode == UI_MODE_SHAPE) && (shape_display_id != SHAPE_UNKNOWN) &&
        (v_cnt >= 12'd7) && (v_cnt < 12'd23)) begin
        case (shape_display_id)
            SHAPE_CUBE: begin
                if (h_cnt >= 12'd525 && h_cnt < 12'd589) begin
                    font_x_offset = h_cnt - 12'd525;
                    font_char_idx = font_x_offset >> 4;
                    font_row_idx = (v_cnt - 12'd7) >> 1;
                    font_col_idx = font_x_offset[3:1];
                    font_pixel_color = UI_CUBE_THEME;
                    case (font_char_idx)
                        5'd0: font_char_code = 5'd14; // C
                        5'd1: font_char_code = 5'd22; // U
                        5'd2: font_char_code = 5'd13; // B
                        5'd3: font_char_code = 5'd19; // E
                        default: font_char_code = 5'd29;
                    endcase
                    font_addr = font_base_for_code(font_char_code) + font_row_idx;
                    font_pixel_en = font_row_bits[7 - font_col_idx];
                end
            end
            SHAPE_CYLINDER: begin
                if (h_cnt >= 12'd493 && h_cnt < 12'd621) begin
                    font_x_offset = h_cnt - 12'd493;
                    font_char_idx = font_x_offset >> 4;
                    font_row_idx = (v_cnt - 12'd7) >> 1;
                    font_col_idx = font_x_offset[3:1];
                    font_pixel_color = UI_CYL_THEME;
                    case (font_char_idx)
                        5'd0: font_char_code = 5'd14; // C
                        5'd1: font_char_code = 5'd21; // Y
                        5'd2: font_char_code = 5'd16; // L
                        5'd3: font_char_code = 5'd26; // I
                        5'd4: font_char_code = 5'd20; // N
                        5'd5: font_char_code = 5'd27; // D
                        5'd6: font_char_code = 5'd19; // E
                        5'd7: font_char_code = 5'd11; // R
                        default: font_char_code = 5'd29;
                    endcase
                    font_addr = font_base_for_code(font_char_code) + font_row_idx;
                    font_pixel_en = font_row_bits[7 - font_col_idx];
                end
            end
            SHAPE_CONE: begin
                if (h_cnt >= 12'd525 && h_cnt < 12'd589) begin
                    font_x_offset = h_cnt - 12'd525;
                    font_char_idx = font_x_offset >> 4;
                    font_row_idx = (v_cnt - 12'd7) >> 1;
                    font_col_idx = font_x_offset[3:1];
                    font_pixel_color = UI_CONE_THEME;
                    case (font_char_idx)
                        5'd0: font_char_code = 5'd14; // C
                        5'd1: font_char_code = 5'd23; // O
                        5'd2: font_char_code = 5'd20; // N
                        5'd3: font_char_code = 5'd19; // E
                        default: font_char_code = 5'd29;
                    endcase
                    font_addr = font_base_for_code(font_char_code) + font_row_idx;
                    font_pixel_en = font_row_bits[7 - font_col_idx];
                end
            end
        endcase
    end

    // --- Shape candidate labels, 2x bitmap scale ---
    if ((ui_mode == UI_MODE_SHAPE) &&
        (v_cnt >= UI_CAND_Y + 12'd8) && (v_cnt < UI_CAND_Y + 12'd24)) begin
        if (h_cnt >= sh_cand_x0 + 12'd54 && h_cnt < sh_cand_x0 + 12'd118) begin
            font_x_offset = h_cnt - (sh_cand_x0 + 12'd54);
            font_char_idx = font_x_offset >> 4;
            font_row_idx = (v_cnt - (UI_CAND_Y + 12'd8)) >> 1;
            font_col_idx = font_x_offset[3:1];
            font_pixel_color = (shape_display_id == SHAPE_CUBE) ? UI_CUBE_THEME : UI_LABEL_COLOR;
            case (font_char_idx)
                5'd0: font_char_code = 5'd14; // C
                5'd1: font_char_code = 5'd22; // U
                5'd2: font_char_code = 5'd13; // B
                5'd3: font_char_code = 5'd19; // E
                default: font_char_code = 5'd29;
            endcase
            font_addr = font_base_for_code(font_char_code) + font_row_idx;
            font_pixel_en = font_row_bits[7 - font_col_idx];
        end else if (h_cnt >= sh_cand_x0 + SH_CAND_W + SH_CAND_GAP + 12'd38 &&
                     h_cnt <  sh_cand_x0 + SH_CAND_W + SH_CAND_GAP + 12'd166) begin
            font_x_offset = h_cnt - (sh_cand_x0 + SH_CAND_W + SH_CAND_GAP + 12'd38);
            font_char_idx = font_x_offset >> 4;
            font_row_idx = (v_cnt - (UI_CAND_Y + 12'd8)) >> 1;
            font_col_idx = font_x_offset[3:1];
            font_pixel_color = (shape_display_id == SHAPE_CYLINDER) ? UI_CYL_THEME : UI_LABEL_COLOR;
            case (font_char_idx)
                5'd0: font_char_code = 5'd14; // C
                5'd1: font_char_code = 5'd21; // Y
                5'd2: font_char_code = 5'd16; // L
                5'd3: font_char_code = 5'd26; // I
                5'd4: font_char_code = 5'd20; // N
                5'd5: font_char_code = 5'd27; // D
                5'd6: font_char_code = 5'd19; // E
                5'd7: font_char_code = 5'd11; // R
                default: font_char_code = 5'd29;
            endcase
            font_addr = font_base_for_code(font_char_code) + font_row_idx;
            font_pixel_en = font_row_bits[7 - font_col_idx];
        end else if (h_cnt >= sh_cand_x0 + 12'd2*(SH_CAND_W + SH_CAND_GAP) + 12'd54 &&
                     h_cnt <  sh_cand_x0 + 12'd2*(SH_CAND_W + SH_CAND_GAP) + 12'd118) begin
            font_x_offset = h_cnt - (sh_cand_x0 + 12'd2*(SH_CAND_W + SH_CAND_GAP) + 12'd54);
            font_char_idx = font_x_offset >> 4;
            font_row_idx = (v_cnt - (UI_CAND_Y + 12'd8)) >> 1;
            font_col_idx = font_x_offset[3:1];
            font_pixel_color = (shape_display_id == SHAPE_CONE) ? UI_CONE_THEME : UI_LABEL_COLOR;
            case (font_char_idx)
                5'd0: font_char_code = 5'd14; // C
                5'd1: font_char_code = 5'd23; // O
                5'd2: font_char_code = 5'd20; // N
                5'd3: font_char_code = 5'd19; // E
                default: font_char_code = 5'd29;
            endcase
            font_addr = font_base_for_code(font_char_code) + font_row_idx;
            font_pixel_en = font_row_bits[7 - font_col_idx];
        end
    end

    // --- Bottom: latency "LATENCY" label ---
    if (v_cnt >= 12'd452 && v_cnt < 12'd460 &&
        h_cnt >= 12'd40 && h_cnt < 12'd96) begin
        font_x_offset = h_cnt - 12'd40;
        font_char_idx = font_x_offset >> 3;
        font_row_idx = v_cnt - 12'd452;
        font_col_idx = font_x_offset[2:0];
        font_pixel_color = 24'h444455;
        case (font_char_idx)
            5'd0: font_char_code = 5'd16; // L
            5'd1: font_char_code = 5'd17; // A
            5'd2: font_char_code = 5'd18; // T
            5'd3: font_char_code = 5'd19; // E
            5'd4: font_char_code = 5'd20; // N
            5'd5: font_char_code = 5'd14; // C
            5'd6: font_char_code = 5'd21; // Y
            default: font_char_code = 5'd29;
        endcase
        font_addr = font_base_for_code(font_char_code) + font_row_idx;
        font_pixel_en = font_row_bits[7 - font_col_idx];
    end

    // --- Bottom: latency digits, 2x bitmap scale ---
    if (v_cnt >= 12'd452 && v_cnt < 12'd468 &&
        h_cnt >= 12'd110 && h_cnt < 12'd206) begin
        font_x_offset = h_cnt - 12'd110;
        font_char_idx = font_x_offset >> 4;
        font_row_idx = (v_cnt - 12'd452) >> 1;
        font_col_idx = font_x_offset[3:1];
        font_pixel_color = latency_highlight_color_hdmi;
        if (ui_mode == UI_MODE_SHAPE) begin
            case (font_char_idx)
                5'd0: font_char_code = {1'b0, disp_shape_latency_digit_5};
                5'd1: font_char_code = {1'b0, disp_shape_latency_digit_4};
                5'd2: font_char_code = {1'b0, disp_shape_latency_digit_3};
                5'd3: font_char_code = {1'b0, disp_shape_latency_digit_2};
                5'd4: font_char_code = {1'b0, disp_shape_latency_digit_1};
                5'd5: font_char_code = {1'b0, disp_shape_latency_digit_0};
                default: font_char_code = 5'd29;
            endcase
        end else begin
            case (font_char_idx)
                5'd0: font_char_code = {1'b0, disp_color_latency_digit_5};
                5'd1: font_char_code = {1'b0, disp_color_latency_digit_4};
                5'd2: font_char_code = {1'b0, disp_color_latency_digit_3};
                5'd3: font_char_code = {1'b0, disp_color_latency_digit_2};
                5'd4: font_char_code = {1'b0, disp_color_latency_digit_1};
                5'd5: font_char_code = {1'b0, disp_color_latency_digit_0};
                default: font_char_code = 5'd29;
            endcase
        end
        font_addr = font_base_for_code(font_char_code) + font_row_idx;
        font_pixel_en = font_row_bits[7 - font_col_idx];
    end

    // --- Bottom: "us" unit ---
    if (v_cnt >= 12'd456 && v_cnt < 12'd464 &&
        h_cnt >= 12'd245 && h_cnt < 12'd261) begin
        font_x_offset = h_cnt - 12'd245;
        font_char_idx = font_x_offset >> 3;
        font_row_idx = v_cnt - 12'd456;
        font_col_idx = font_x_offset[2:0];
        font_pixel_color = latency_unit_color_hdmi;
        case (font_char_idx)
            5'd0: font_char_code = 5'd22; // U
            5'd1: font_char_code = 5'd15; // S
            default: font_char_code = 5'd29;
        endcase
        font_addr = font_base_for_code(font_char_code) + font_row_idx;
        font_pixel_en = font_row_bits[7 - font_col_idx];
    end
end

font_rom_ui font_rom_ui_inst (
    .addr(font_addr),
    .data(font_row_bits)
);

endmodule

`endif
