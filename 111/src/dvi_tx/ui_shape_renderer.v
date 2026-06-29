`ifndef UI_SHAPE_RENDERER_V
`define UI_SHAPE_RENDERER_V

module ui_shape_renderer #(
    parameter [2:0] SHAPE_UNKNOWN = 3'd0,
    parameter [2:0] SHAPE_CUBE = 3'd1,
    parameter [2:0] SHAPE_CYLINDER = 3'd2,
    parameter [2:0] SHAPE_CONE = 3'd3
) (
    input  wire [11:0] h_cnt,
    input  wire [11:0] v_cnt,
    input  wire [2:0]  shape_display_id,
    input  wire [23:0] shape_rgb,
    output reg         badge_pixel_en,
    output reg  [23:0] badge_pixel_rgb,
    output reg         main_pixel_en,
    output reg  [23:0] main_pixel_rgb,
    output reg         candidate_pixel_en,
    output reg  [23:0] candidate_pixel_rgb
);

localparam [23:0] UI_CAND_BG      = 24'h16161E;
localparam [23:0] UI_CAND_BORDER  = 24'h22222A;
localparam [23:0] UI_LABEL_COLOR  = 24'h555566;
localparam [23:0] UI_CUBE_THEME   = 24'hF3A847;
localparam [23:0] UI_CYL_THEME    = 24'h62CC73;
localparam [23:0] UI_CONE_THEME   = 24'h58D7D0;
localparam [23:0] UI_CUBE_BG      = 24'h3D2E21;
localparam [23:0] UI_CYL_BG       = 24'h203D29;
localparam [23:0] UI_CONE_BG      = 24'h1E4041;
localparam [23:0] UI_CUBE_CAND_BG = 24'h554129;
localparam [23:0] UI_CYL_CAND_BG  = 24'h2B4D35;
localparam [23:0] UI_CONE_CAND_BG = 24'h2A5151;

localparam [11:0] SHAPE_CX        = 12'd320;
localparam [11:0] SHAPE_CY        = 12'd210;
localparam [11:0] CUBE_SZ         = 12'd140;
localparam [11:0] CUBE_D          = 12'd36;
localparam [11:0] CYL_W           = 12'd110;
localparam [11:0] CYL_H           = 12'd200;
localparam [11:0] CYL_R           = 12'd16;
localparam [11:0] CONE_BASE       = 12'd230;
localparam [11:0] CONE_H          = 12'd240;
localparam [11:0] CONE_BASE_D     = 12'd16;
localparam [11:0] UI_CAND_Y       = 12'd398;
localparam [11:0] SH_CAND_W       = 12'd170;
localparam [11:0] SH_CAND_H       = 12'd32;
localparam [11:0] SH_CAND_GAP     = 12'd18;

function [7:0] rgb_add_sat8;
input [7:0] value;
input [7:0] delta;
reg [8:0] sum;
begin
    sum = {1'b0, value} + {1'b0, delta};
    rgb_add_sat8 = sum[8] ? 8'hFF : sum[7:0];
end
endfunction

function [7:0] rgb_sub_sat8;
input [7:0] value;
input [7:0] delta;
begin
    rgb_sub_sat8 = (value > delta) ? (value - delta) : 8'h00;
end
endfunction

function [23:0] rgb_add_sat24;
input [23:0] color;
input [7:0] delta;
begin
    rgb_add_sat24 = {
        rgb_add_sat8(color[23:16], delta),
        rgb_add_sat8(color[15:8],  delta),
        rgb_add_sat8(color[7:0],   delta)
    };
end
endfunction

function [23:0] rgb_sub_sat24;
input [23:0] color;
input [7:0] delta;
begin
    rgb_sub_sat24 = {
        rgb_sub_sat8(color[23:16], delta),
        rgb_sub_sat8(color[15:8],  delta),
        rgb_sub_sat8(color[7:0],   delta)
    };
end
endfunction

function [6:0] ellipse_w55_for_dy;
input [4:0] dy_abs;
begin
    case (dy_abs)
        5'd0:  ellipse_w55_for_dy = 7'd55;
        5'd1:  ellipse_w55_for_dy = 7'd55;
        5'd2:  ellipse_w55_for_dy = 7'd55;
        5'd3:  ellipse_w55_for_dy = 7'd54;
        5'd4:  ellipse_w55_for_dy = 7'd53;
        5'd5:  ellipse_w55_for_dy = 7'd52;
        5'd6:  ellipse_w55_for_dy = 7'd51;
        5'd7:  ellipse_w55_for_dy = 7'd49;
        5'd8:  ellipse_w55_for_dy = 7'd47;
        5'd9:  ellipse_w55_for_dy = 7'd45;
        5'd10: ellipse_w55_for_dy = 7'd43;
        5'd11: ellipse_w55_for_dy = 7'd40;
        5'd12: ellipse_w55_for_dy = 7'd36;
        5'd13: ellipse_w55_for_dy = 7'd32;
        5'd14: ellipse_w55_for_dy = 7'd26;
        5'd15: ellipse_w55_for_dy = 7'd18;
        default: ellipse_w55_for_dy = 7'd0;
    endcase
end
endfunction

function [7:0] ellipse_w115_for_dy;
input [4:0] dy_abs;
begin
    case (dy_abs)
        5'd0:  ellipse_w115_for_dy = 8'd115;
        5'd1:  ellipse_w115_for_dy = 8'd115;
        5'd2:  ellipse_w115_for_dy = 8'd114;
        5'd3:  ellipse_w115_for_dy = 8'd113;
        5'd4:  ellipse_w115_for_dy = 8'd112;
        5'd5:  ellipse_w115_for_dy = 8'd110;
        5'd6:  ellipse_w115_for_dy = 8'd107;
        5'd7:  ellipse_w115_for_dy = 8'd104;
        5'd8:  ellipse_w115_for_dy = 8'd100;
        5'd9:  ellipse_w115_for_dy = 8'd95;
        5'd10: ellipse_w115_for_dy = 8'd89;
        5'd11: ellipse_w115_for_dy = 8'd82;
        5'd12: ellipse_w115_for_dy = 8'd74;
        5'd13: ellipse_w115_for_dy = 8'd64;
        5'd14: ellipse_w115_for_dy = 8'd50;
        5'd15: ellipse_w115_for_dy = 8'd34;
        default: ellipse_w115_for_dy = 8'd0;
    endcase
end
endfunction


// ============================================================
// 3D shape geometry hit-test signals (for new UI rendering)
// ============================================================
// ---- Cube ----
wire [11:0] cube_sz_half = CUBE_SZ >> 1;
wire [11:0] cube_fx0 = SHAPE_CX - cube_sz_half;
wire [11:0] cube_fx1 = SHAPE_CX + cube_sz_half;
wire [11:0] cube_fy0 = SHAPE_CY - cube_sz_half + (CUBE_D >> 1) + 12'd10;
wire [11:0] cube_fy1 = SHAPE_CY + cube_sz_half + (CUBE_D >> 1) + 12'd10;
wire cube_front_hit = (h_cnt >= cube_fx0) && (h_cnt < cube_fx1) &&
                      (v_cnt >= cube_fy0) && (v_cnt < cube_fy1);
wire cube_front_contour = cube_front_hit &&
    ((h_cnt < cube_fx0 + 12'd3) || (h_cnt >= cube_fx1 - 12'd3) ||
     (v_cnt < cube_fy0 + 12'd3) || (v_cnt >= cube_fy1 - 12'd3));
// Top face: 45-degree parallelogram, using only add/subtract/compare.
wire [11:0] cube_top_y_off = cube_fy0 - v_cnt;
wire [11:0] cube_top_x_min = cube_fx0 + cube_top_y_off;
wire [11:0] cube_top_x_max = cube_fx1 + cube_top_y_off;
wire cube_top_face = (v_cnt >= cube_fy0 - CUBE_D) && (v_cnt < cube_fy0) &&
                     (h_cnt >= cube_top_x_min) && (h_cnt < cube_top_x_max);
wire cube_top_contour = cube_top_face &&
    ((v_cnt < cube_fy0 - CUBE_D + 12'd3) || (v_cnt >= cube_fy0 - 12'd3) ||
     (h_cnt < cube_top_x_min + 12'd3) || (h_cnt >= cube_top_x_max - 12'd3));
// Right face
wire [11:0] cube_right_x_off = h_cnt - cube_fx1;
wire [11:0] cube_right_y_min = cube_fy0 - cube_right_x_off;
wire [11:0] cube_right_y_max = cube_fy1 - cube_right_x_off;
wire cube_right_face = (h_cnt >= cube_fx1) && (h_cnt < cube_fx1 + CUBE_D) &&
                       (v_cnt >= cube_right_y_min) && (v_cnt < cube_right_y_max);
wire cube_right_contour = cube_right_face &&
    ((h_cnt < cube_fx1 + 12'd3) || (h_cnt >= cube_fx1 + CUBE_D - 12'd3) ||
     (v_cnt < cube_right_y_min + 12'd3) || (v_cnt >= cube_right_y_max - 12'd3));
wire [11:0] cube_hidden_y = cube_fy1 - (h_cnt - cube_fx0);
wire cube_hidden_edge =
    h_cnt[3] &&
    (((v_cnt >= cube_fy1 - CUBE_D) && (v_cnt < cube_fy1 - CUBE_D + 12'd2) &&
      (h_cnt >= cube_fx0 + CUBE_D) && (h_cnt < cube_fx1 + CUBE_D)) ||
     ((h_cnt >= cube_fx0) && (h_cnt < cube_fx0 + CUBE_D) &&
      (v_cnt >= cube_hidden_y) && (v_cnt < cube_hidden_y + 12'd2)));

// ---- Cylinder ----
wire [11:0] cyl_lx = SHAPE_CX - (CYL_W >> 1);
wire [11:0] cyl_rx = SHAPE_CX + (CYL_W >> 1);
wire [11:0] cyl_ty = SHAPE_CY - (CYL_H >> 1);
wire [11:0] cyl_by = SHAPE_CY + (CYL_H >> 1);
wire [11:0] cyl_body_ty = cyl_ty + CYL_R;
wire [11:0] cyl_body_by = cyl_by - CYL_R;
wire cyl_body_hit = (h_cnt >= cyl_lx) && (h_cnt < cyl_rx) &&
                    (v_cnt >= cyl_body_ty) && (v_cnt < cyl_body_by);
wire cyl_left_line = (h_cnt >= cyl_lx) && (h_cnt < cyl_lx + 12'd3) &&
                     (v_cnt >= cyl_body_ty) && (v_cnt <= cyl_body_by);
wire cyl_right_line = (h_cnt > cyl_rx - 12'd3) && (h_cnt <= cyl_rx) &&
                      (v_cnt >= cyl_body_ty) && (v_cnt <= cyl_body_by);
wire [12:0] cyl_abs_x = (h_cnt >= SHAPE_CX) ? ({1'b0, h_cnt} - {1'b0, SHAPE_CX}) :
                        ({1'b0, SHAPE_CX} - {1'b0, h_cnt});
wire [4:0] cyl_top_dy_abs = (v_cnt >= cyl_body_ty) ? (v_cnt - cyl_body_ty) :
                            (cyl_body_ty - v_cnt);
wire [4:0] cyl_bot_dy_abs = (v_cnt >= cyl_body_by) ? (v_cnt - cyl_body_by) :
                            (cyl_body_by - v_cnt);
wire [6:0] cyl_top_half_w = ellipse_w55_for_dy(cyl_top_dy_abs);
wire [6:0] cyl_bot_half_w = ellipse_w55_for_dy(cyl_bot_dy_abs);
wire cyl_top_ellipse_hit = (v_cnt >= cyl_body_ty - CYL_R) &&
                           (v_cnt <= cyl_body_ty + CYL_R) &&
                           (cyl_abs_x <= {6'd0, cyl_top_half_w});
wire cyl_top_ellipse_contour = cyl_top_ellipse_hit &&
    ((cyl_abs_x + 13'd3 >= {6'd0, cyl_top_half_w}) || (cyl_top_dy_abs >= 5'd14));
wire cyl_bot_ellipse_hit = (v_cnt >= cyl_body_by - CYL_R) &&
                           (v_cnt <= cyl_body_by + CYL_R) &&
                           (cyl_abs_x <= {6'd0, cyl_bot_half_w});
wire cyl_bot_ellipse_contour = cyl_bot_ellipse_hit && (v_cnt >= cyl_body_by) &&
    ((cyl_abs_x + 13'd3 >= {6'd0, cyl_bot_half_w}) || (cyl_bot_dy_abs >= 5'd14));

// ---- Cone ----
wire [11:0] cone_half_base = CONE_BASE >> 1;
wire [11:0] cone_ty = SHAPE_CY - (CONE_H >> 1) - 12'd10;
wire [11:0] cone_by = SHAPE_CY + (CONE_H >> 1) - 12'd10;
wire [11:0] cone_left_lx = SHAPE_CX - cone_half_base;
wire [11:0] cone_right_rx = SHAPE_CX + cone_half_base;
wire [12:0] cone_abs_dx = (h_cnt >= SHAPE_CX) ? ({1'b0, h_cnt} - {1'b0, SHAPE_CX}) :
                          ({1'b0, SHAPE_CX} - {1'b0, h_cnt});
wire [11:0] cone_rel_y_body = (v_cnt > cone_ty) ? (v_cnt - cone_ty) : 12'd0;
wire [11:0] cone_half_at_y_raw = cone_rel_y_body >> 1;
wire [11:0] cone_half_at_y = (cone_half_at_y_raw > cone_half_base) ? cone_half_base : cone_half_at_y_raw;
wire cone_body_hit = (v_cnt >= cone_ty) && (v_cnt < cone_by) &&
                     (h_cnt >= cone_left_lx) && (h_cnt <= cone_right_rx) &&
                     (cone_abs_dx <= {1'b0, cone_half_at_y});
// Left/right contour lines (2px wide)
wire cone_left_contour = cone_body_hit && (h_cnt <= SHAPE_CX) &&
                         ((cone_half_at_y <= 12'd3) || (cone_abs_dx + 13'd3 >= {1'b0, cone_half_at_y}));
wire cone_right_contour = cone_body_hit && (h_cnt >= SHAPE_CX) &&
                          ((cone_half_at_y <= 12'd3) || (cone_abs_dx + 13'd3 >= {1'b0, cone_half_at_y}));
wire cone_contour = cone_left_contour || cone_right_contour;
wire [4:0] cone_base_dy_abs = (v_cnt >= cone_by) ? (v_cnt - cone_by) :
                              (cone_by - v_cnt);
wire [7:0] cone_base_half_w = ellipse_w115_for_dy(cone_base_dy_abs);
wire cone_base_ellipse_hit = (v_cnt >= cone_by - CONE_BASE_D) && (v_cnt <= cone_by + CONE_BASE_D) &&
                             (cone_abs_dx <= {5'd0, cone_base_half_w});
wire cone_base_contour_ring = cone_base_ellipse_hit &&
    ((cone_abs_dx + 13'd3 >= {5'd0, cone_base_half_w}) || (cone_base_dy_abs >= 5'd14));
// Front half (y >= cone_by) solid, back half dashed
wire cone_base_contour_front = cone_base_contour_ring && (v_cnt >= cone_by);
wire cone_base_contour_back = cone_base_contour_ring && (v_cnt < cone_by) && h_cnt[2];
// Apex highlight
wire cone_apex = (v_cnt >= cone_ty - 12'd1) && (v_cnt < cone_ty + 12'd4) &&
                 (h_cnt >= SHAPE_CX - 12'd3) && (h_cnt < SHAPE_CX + 12'd3);

// ---- Gradient helpers (step-based, no multiply) ----
// Cylinder horizontal gradient: 5 steps across width
wire [11:0] cyl_rel_x = (h_cnt > cyl_lx) ? (h_cnt - cyl_lx) : 12'd0;
wire cyl_grad_step0 = (cyl_rel_x < (CYL_W >> 2));
wire cyl_grad_step1 = (cyl_rel_x < (CYL_W >> 1));
wire cyl_grad_step3 = (cyl_rel_x > (CYL_W - (CYL_W >> 2)));
// Cone vertical gradient
wire [11:0] cone_rel_y = (v_cnt > cone_ty) ? (v_cnt - cone_ty) : 12'd0;
wire cone_grad_step0 = (cone_rel_y < (CONE_H >> 3));
wire cone_grad_step3 = (cone_rel_y > (CONE_H - (CONE_H >> 3)));

// ---- Candidate box hit-tests ----
wire [11:0] sh_cand_total_w = SH_CAND_W * 12'd3 + SH_CAND_GAP * 12'd2;
wire [11:0] sh_cand_x0 = (12'd640 - sh_cand_total_w) >> 1;
wire sh_cand0_hit = (h_cnt >= sh_cand_x0) && (h_cnt < sh_cand_x0 + SH_CAND_W) &&
                    (v_cnt >= UI_CAND_Y) && (v_cnt < UI_CAND_Y + SH_CAND_H);
wire sh_cand1_hit = (h_cnt >= sh_cand_x0 + SH_CAND_W + SH_CAND_GAP) &&
                    (h_cnt < sh_cand_x0 + 12'd2*SH_CAND_W + SH_CAND_GAP) &&
                    (v_cnt >= UI_CAND_Y) && (v_cnt < UI_CAND_Y + SH_CAND_H);
wire sh_cand2_hit = (h_cnt >= sh_cand_x0 + 12'd2*(SH_CAND_W + SH_CAND_GAP)) &&
                    (h_cnt < sh_cand_x0 + 12'd3*SH_CAND_W + 12'd2*SH_CAND_GAP) &&
                    (v_cnt >= UI_CAND_Y) && (v_cnt < UI_CAND_Y + SH_CAND_H);

wire [11:0] sh_icon_y0 = UI_CAND_Y + 12'd8;
wire [11:0] sh_icon0_x0 = sh_cand_x0 + 12'd14;
wire [11:0] sh_icon1_x0 = sh_cand_x0 + SH_CAND_W + SH_CAND_GAP + 12'd14;
wire [11:0] sh_icon2_x0 = sh_cand_x0 + 12'd2*(SH_CAND_W + SH_CAND_GAP) + 12'd14;
wire sh_icon0_area = (h_cnt >= sh_icon0_x0) && (h_cnt < sh_icon0_x0 + 12'd24) &&
                     (v_cnt >= sh_icon_y0) && (v_cnt < sh_icon_y0 + 12'd22);
wire sh_icon1_area = (h_cnt >= sh_icon1_x0) && (h_cnt < sh_icon1_x0 + 12'd24) &&
                     (v_cnt >= sh_icon_y0) && (v_cnt < sh_icon_y0 + 12'd22);
wire sh_icon2_area = (h_cnt >= sh_icon2_x0) && (h_cnt < sh_icon2_x0 + 12'd24) &&
                     (v_cnt >= sh_icon_y0) && (v_cnt < sh_icon_y0 + 12'd22);
wire [4:0] sh_icon0_dx = sh_icon0_area ? (h_cnt - sh_icon0_x0) : 5'd0;
wire [4:0] sh_icon1_dx = sh_icon1_area ? (h_cnt - sh_icon1_x0) : 5'd0;
wire [4:0] sh_icon2_dx = sh_icon2_area ? (h_cnt - sh_icon2_x0) : 5'd0;
wire [4:0] sh_icon_dy = (v_cnt >= sh_icon_y0) ? (v_cnt - sh_icon_y0) : 5'd0;
wire [5:0] sh_icon0_sum = {1'b0, sh_icon0_dx} + {1'b0, sh_icon_dy};

wire sh_icon0_front_rect =
    ((sh_icon0_dx >= 5'd4) && (sh_icon0_dx <= 5'd15) &&
     ((sh_icon_dy == 5'd7) || (sh_icon_dy == 5'd17))) ||
    ((sh_icon_dy >= 5'd7) && (sh_icon_dy <= 5'd17) &&
     ((sh_icon0_dx == 5'd4) || (sh_icon0_dx == 5'd15)));
wire sh_icon0_back_rect =
    ((sh_icon0_dx >= 5'd8) && (sh_icon0_dx <= 5'd19) &&
     ((sh_icon_dy == 5'd3) || (sh_icon_dy == 5'd13))) ||
    ((sh_icon_dy >= 5'd3) && (sh_icon_dy <= 5'd13) &&
     ((sh_icon0_dx == 5'd8) || (sh_icon0_dx == 5'd19)));
wire sh_icon0_ribs =
    ((sh_icon0_dx >= 5'd4) && (sh_icon0_dx <= 5'd8) &&
     (sh_icon_dy >= 5'd3) && (sh_icon_dy <= 5'd7) &&
     (sh_icon0_sum >= 6'd11) && (sh_icon0_sum <= 6'd12)) ||
    ((sh_icon0_dx >= 5'd15) && (sh_icon0_dx <= 5'd19) &&
     (sh_icon_dy >= 5'd3) && (sh_icon_dy <= 5'd7) &&
     (sh_icon0_sum >= 6'd22) && (sh_icon0_sum <= 6'd23)) ||
    ((sh_icon0_dx >= 5'd15) && (sh_icon0_dx <= 5'd19) &&
     (sh_icon_dy >= 5'd13) && (sh_icon_dy <= 5'd17) &&
     (sh_icon0_sum >= 6'd32) && (sh_icon0_sum <= 6'd33)) ||
    ((sh_icon0_dx >= 5'd4) && (sh_icon0_dx <= 5'd8) &&
     (sh_icon_dy >= 5'd13) && (sh_icon_dy <= 5'd17) &&
     (sh_icon0_sum >= 6'd21) && (sh_icon0_sum <= 6'd22));
wire sh_icon0_cube = sh_icon0_area && (sh_icon0_front_rect || sh_icon0_back_rect || sh_icon0_ribs);

wire sh_icon1_top_ellipse =
    ((sh_icon_dy == 5'd3) && (sh_icon1_dx >= 5'd8) && (sh_icon1_dx <= 5'd14)) ||
    ((sh_icon_dy == 5'd4) &&
     (((sh_icon1_dx >= 5'd5) && (sh_icon1_dx <= 5'd8)) ||
      ((sh_icon1_dx >= 5'd14) && (sh_icon1_dx <= 5'd17)))) ||
    ((sh_icon_dy == 5'd5) &&
     (((sh_icon1_dx >= 5'd4) && (sh_icon1_dx <= 5'd6)) ||
      ((sh_icon1_dx >= 5'd16) && (sh_icon1_dx <= 5'd18)))) ||
    ((sh_icon_dy == 5'd6) &&
     (((sh_icon1_dx >= 5'd5) && (sh_icon1_dx <= 5'd8)) ||
      ((sh_icon1_dx >= 5'd14) && (sh_icon1_dx <= 5'd17)))) ||
    ((sh_icon_dy == 5'd7) && (sh_icon1_dx >= 5'd8) && (sh_icon1_dx <= 5'd14));
wire sh_icon1_sides =
    (sh_icon_dy >= 5'd5) && (sh_icon_dy <= 5'd15) &&
    (((sh_icon1_dx >= 5'd4) && (sh_icon1_dx <= 5'd5)) ||
     ((sh_icon1_dx >= 5'd17) && (sh_icon1_dx <= 5'd18)));
wire sh_icon1_bottom_arc =
    ((sh_icon_dy == 5'd15) &&
     (((sh_icon1_dx >= 5'd4) && (sh_icon1_dx <= 5'd6)) ||
      ((sh_icon1_dx >= 5'd16) && (sh_icon1_dx <= 5'd18)))) ||
    ((sh_icon_dy == 5'd16) &&
     (((sh_icon1_dx >= 5'd5) && (sh_icon1_dx <= 5'd8)) ||
      ((sh_icon1_dx >= 5'd14) && (sh_icon1_dx <= 5'd17)))) ||
    ((sh_icon_dy == 5'd17) && (sh_icon1_dx >= 5'd8) && (sh_icon1_dx <= 5'd14));
wire sh_icon1_cyl = sh_icon1_area && (sh_icon1_top_ellipse || sh_icon1_sides || sh_icon1_bottom_arc);

wire sh_icon2_side_lines =
    ((sh_icon_dy >= 5'd2) && (sh_icon_dy <= 5'd3) && (sh_icon2_dx >= 5'd10) && (sh_icon2_dx <= 5'd12)) ||
    ((sh_icon_dy >= 5'd4) && (sh_icon_dy <= 5'd5) &&
     (((sh_icon2_dx >= 5'd9) && (sh_icon2_dx <= 5'd10)) ||
      ((sh_icon2_dx >= 5'd12) && (sh_icon2_dx <= 5'd13)))) ||
    ((sh_icon_dy >= 5'd6) && (sh_icon_dy <= 5'd7) &&
     (((sh_icon2_dx >= 5'd8) && (sh_icon2_dx <= 5'd9)) ||
      ((sh_icon2_dx >= 5'd13) && (sh_icon2_dx <= 5'd14)))) ||
    ((sh_icon_dy >= 5'd8) && (sh_icon_dy <= 5'd9) &&
     (((sh_icon2_dx >= 5'd7) && (sh_icon2_dx <= 5'd8)) ||
      ((sh_icon2_dx >= 5'd14) && (sh_icon2_dx <= 5'd15)))) ||
    ((sh_icon_dy >= 5'd10) && (sh_icon_dy <= 5'd11) &&
     (((sh_icon2_dx >= 5'd6) && (sh_icon2_dx <= 5'd7)) ||
      ((sh_icon2_dx >= 5'd15) && (sh_icon2_dx <= 5'd16)))) ||
    ((sh_icon_dy >= 5'd12) && (sh_icon_dy <= 5'd13) &&
     (((sh_icon2_dx >= 5'd5) && (sh_icon2_dx <= 5'd6)) ||
      ((sh_icon2_dx >= 5'd16) && (sh_icon2_dx <= 5'd17)))) ||
    ((sh_icon_dy >= 5'd14) && (sh_icon_dy <= 5'd16) &&
     (((sh_icon2_dx >= 5'd3) && (sh_icon2_dx <= 5'd4)) ||
      ((sh_icon2_dx >= 5'd18) && (sh_icon2_dx <= 5'd19))));
wire sh_icon2_base_ellipse =
    ((sh_icon_dy == 5'd15) && (sh_icon2_dx >= 5'd5) && (sh_icon2_dx <= 5'd17) && sh_icon2_dx[2]) ||
    ((sh_icon_dy == 5'd16) &&
     (((sh_icon2_dx >= 5'd3) && (sh_icon2_dx <= 5'd6)) ||
      ((sh_icon2_dx >= 5'd16) && (sh_icon2_dx <= 5'd19)))) ||
    ((sh_icon_dy == 5'd17) && (sh_icon2_dx >= 5'd6) && (sh_icon2_dx <= 5'd16)) ||
    ((sh_icon_dy == 5'd18) && (sh_icon2_dx >= 5'd8) && (sh_icon2_dx <= 5'd14));
wire sh_icon2_cone = sh_icon2_area && (sh_icon2_side_lines || sh_icon2_base_ellipse);

always @(*) begin
    badge_pixel_en = 1'b0;
    badge_pixel_rgb = 24'h000000;

    if (shape_display_id != SHAPE_UNKNOWN &&
        h_cnt >= 12'd485 && h_cnt < 12'd630 &&
        v_cnt >= 12'd4 && v_cnt < 12'd26) begin
        badge_pixel_en = 1'b1;
        case (shape_display_id)
            SHAPE_CUBE:     badge_pixel_rgb = UI_CUBE_BG;
            SHAPE_CYLINDER: badge_pixel_rgb = UI_CYL_BG;
            SHAPE_CONE:     badge_pixel_rgb = UI_CONE_BG;
            default:        badge_pixel_rgb = 24'h101018;
        endcase
        if (h_cnt < 12'd486 || h_cnt >= 12'd629 ||
            v_cnt < 12'd5  || v_cnt >= 12'd25) begin
            case (shape_display_id)
                SHAPE_CUBE:     badge_pixel_rgb = UI_CUBE_THEME;
                SHAPE_CYLINDER: badge_pixel_rgb = UI_CYL_THEME;
                SHAPE_CONE:     badge_pixel_rgb = UI_CONE_THEME;
                default:        badge_pixel_rgb = 24'h101018;
            endcase
        end
    end
end

always @(*) begin
    main_pixel_en = 1'b0;
    main_pixel_rgb = 24'h000000;

    if (shape_display_id == SHAPE_CUBE) begin
        if (cube_front_hit) begin
            main_pixel_en = 1'b1;
            main_pixel_rgb = shape_rgb;
            if (v_cnt < cube_fy0 + (CUBE_SZ >> 2))
                main_pixel_rgb = rgb_add_sat24(shape_rgb, 8'd20);
            else if (v_cnt > cube_fy1 - (CUBE_SZ >> 3))
                main_pixel_rgb = rgb_sub_sat24(shape_rgb, 8'd26);
            if (cube_front_contour)
                main_pixel_rgb = UI_CUBE_THEME;
        end else if (cube_top_face) begin
            main_pixel_en = 1'b1;
            main_pixel_rgb = rgb_add_sat24(shape_rgb, 8'd48);
            if (cube_top_contour)
                main_pixel_rgb = UI_CUBE_THEME;
        end else if (cube_right_face) begin
            main_pixel_en = 1'b1;
            main_pixel_rgb = rgb_sub_sat24(shape_rgb, 8'd56);
            if (cube_right_contour)
                main_pixel_rgb = UI_CUBE_THEME;
        end
        if (cube_hidden_edge) begin
            main_pixel_en = 1'b1;
            main_pixel_rgb = 24'h6D5430;
        end
    end else if (shape_display_id == SHAPE_CYLINDER) begin
        if (cyl_body_hit) begin
            main_pixel_en = 1'b1;
            main_pixel_rgb = shape_rgb;
            if (cyl_grad_step0)
                main_pixel_rgb = rgb_add_sat24(shape_rgb, 8'd10);
            else if (cyl_grad_step3)
                main_pixel_rgb = rgb_sub_sat24(shape_rgb, 8'd14);
        end else if (cyl_top_ellipse_hit) begin
            main_pixel_en = 1'b1;
            main_pixel_rgb = shape_rgb;
        end else if (cyl_bot_ellipse_hit) begin
            main_pixel_en = 1'b1;
            main_pixel_rgb = rgb_sub_sat24(shape_rgb, 8'd18);
        end
        if (cyl_left_line || cyl_right_line || cyl_top_ellipse_contour || cyl_bot_ellipse_contour) begin
            main_pixel_en = 1'b1;
            main_pixel_rgb = UI_CYL_THEME;
        end
    end else if (shape_display_id == SHAPE_CONE) begin
        if (cone_body_hit) begin
            main_pixel_en = 1'b1;
            main_pixel_rgb = shape_rgb;
            if (cone_grad_step0)
                main_pixel_rgb = rgb_add_sat24(shape_rgb, 8'd46);
            else if (cone_grad_step3)
                main_pixel_rgb = rgb_sub_sat24(shape_rgb, 8'd26);
        end else if (cone_base_ellipse_hit) begin
            main_pixel_en = 1'b1;
            main_pixel_rgb = rgb_sub_sat24(shape_rgb, 8'd42);
        end
        if (cone_contour || cone_base_contour_front || cone_base_contour_back) begin
            main_pixel_en = 1'b1;
            main_pixel_rgb = UI_CONE_THEME;
        end
        if (cone_apex) begin
            main_pixel_en = 1'b1;
            main_pixel_rgb = 24'hFFFFFF;
        end
    end
end

always @(*) begin
    candidate_pixel_en = 1'b0;
    candidate_pixel_rgb = 24'h000000;

    if (sh_cand0_hit) begin
        candidate_pixel_en = 1'b1;
        candidate_pixel_rgb = (shape_display_id == SHAPE_CUBE) ? UI_CUBE_CAND_BG : UI_CAND_BG;
        if (h_cnt < sh_cand_x0 + 12'd2 || h_cnt >= sh_cand_x0 + SH_CAND_W - 12'd2 ||
            v_cnt < UI_CAND_Y + 12'd2 || v_cnt >= UI_CAND_Y + SH_CAND_H - 12'd2)
            candidate_pixel_rgb = (shape_display_id == SHAPE_CUBE) ? UI_CUBE_THEME : UI_CAND_BORDER;
        if (sh_icon0_cube)
            candidate_pixel_rgb = (shape_display_id == SHAPE_CUBE) ? UI_CUBE_THEME : UI_LABEL_COLOR;
    end else if (sh_cand1_hit) begin
        candidate_pixel_en = 1'b1;
        candidate_pixel_rgb = (shape_display_id == SHAPE_CYLINDER) ? UI_CYL_CAND_BG : UI_CAND_BG;
        if (h_cnt < sh_cand_x0 + SH_CAND_W + SH_CAND_GAP + 12'd2 ||
            h_cnt >= sh_cand_x0 + 12'd2*SH_CAND_W + SH_CAND_GAP - 12'd2 ||
            v_cnt < UI_CAND_Y + 12'd2 || v_cnt >= UI_CAND_Y + SH_CAND_H - 12'd2)
            candidate_pixel_rgb = (shape_display_id == SHAPE_CYLINDER) ? UI_CYL_THEME : UI_CAND_BORDER;
        if (sh_icon1_cyl)
            candidate_pixel_rgb = (shape_display_id == SHAPE_CYLINDER) ? UI_CYL_THEME : UI_LABEL_COLOR;
    end else if (sh_cand2_hit) begin
        candidate_pixel_en = 1'b1;
        candidate_pixel_rgb = (shape_display_id == SHAPE_CONE) ? UI_CONE_CAND_BG : UI_CAND_BG;
        if (h_cnt < sh_cand_x0 + 12'd2*(SH_CAND_W + SH_CAND_GAP) + 12'd2 ||
            h_cnt >= sh_cand_x0 + 12'd3*SH_CAND_W + 12'd2*SH_CAND_GAP - 12'd2 ||
            v_cnt < UI_CAND_Y + 12'd2 || v_cnt >= UI_CAND_Y + SH_CAND_H - 12'd2)
            candidate_pixel_rgb = (shape_display_id == SHAPE_CONE) ? UI_CONE_THEME : UI_CAND_BORDER;
        if (sh_icon2_cone)
            candidate_pixel_rgb = (shape_display_id == SHAPE_CONE) ? UI_CONE_THEME : UI_LABEL_COLOR;
    end
end

endmodule

`endif
