`ifndef COLOR_DETECTOR_V
`define COLOR_DETECTOR_V

module color_detector #(
    parameter HACT = 12'd1920,
    parameter VACT = 11'd1080,
    parameter [11:0] COLOR_ROI_X_START = 12'd880,
    parameter [11:0] COLOR_ROI_X_END   = 12'd1040,
    parameter [10:0] COLOR_ROI_Y_START = 11'd480,
    parameter [10:0] COLOR_ROI_Y_END   = 11'd600,
    parameter [11:0] FAST_COLOR_ROI_X_START = 12'd880,
    parameter [11:0] FAST_COLOR_ROI_X_END   = 12'd1040,
    parameter [10:0] FAST_COLOR_ROI_Y_START = 11'd480,
    parameter [10:0] FAST_COLOR_ROI_Y_END   = 11'd600,
    parameter [17:0] VOTE_MIN_COUNT = 18'd96,
    parameter [17:0] VOTE_MARGIN = 18'd32,
    parameter [17:0] FAST_VOTE_MIN_COUNT = 18'd96,
    parameter [17:0] FAST_VOTE_MARGIN = 18'd32,
    parameter [3:0] FAST_LOCK_LINE_STREAK_NEW = 4'd8,
    parameter [3:0] FAST_LOCK_LINE_STREAK_SWITCH = 4'd8
) (
    input  wire clk,
    input  wire rst_n,
    input  wire rgb_vs,
    input  wire rgb_de,
    input  wire [47:0] rgb_datax2,
    input  wire timer_running,
    input  wire fast_timer_running,

    output reg  [2:0] color_id,
    output reg        color_valid,
    output wire [2:0] fast_color_id_out,
    output wire       fast_color_valid_out,
    output wire       color_timer_start_pulse,
    output wire       color_timer_stop_pulse,
    output wire       color_timer_cancel_pulse,
    output wire       fast_color_timer_start_pulse,
    output wire       fast_color_timer_stop_pulse,
    output wire       fast_color_timer_cancel_pulse
);

localparam [2:0] COLOR_UNKNOWN = 3'd0;
localparam [2:0] COLOR_BLACK   = 3'd1;
localparam [2:0] COLOR_WHITE   = 3'd2;
localparam [2:0] COLOR_RED     = 3'd3;
localparam [2:0] COLOR_BLUE    = 3'd4;
localparam [2:0] COLOR_YELLOW  = 3'd5;

localparam [2:0] COLOR_EVAL_IDLE   = 3'd0;
localparam [2:0] COLOR_EVAL_RED    = 3'd1;
localparam [2:0] COLOR_EVAL_BLUE   = 3'd2;
localparam [2:0] COLOR_EVAL_YELLOW = 3'd3;
localparam [2:0] COLOR_EVAL_WHITE  = 3'd4;
localparam [2:0] COLOR_EVAL_BLACK  = 3'd5;
localparam [2:0] COLOR_EVAL_DONE   = 3'd6;

reg rgb_vs_d;
reg rgb_de_d;
reg [11:0] color_x;
reg [10:0] color_y;
reg [2:0] color_candidate_prev;
reg color_candidate_prev_valid;
reg [1:0] color_invalid_frames;
reg [2:0] fast_color_id;
reg fast_color_valid;
reg [2:0] fast_color_candidate_prev;
reg fast_color_candidate_prev_valid;
reg [3:0] fast_color_candidate_streak;
reg [17:0] roi_vote_red;
reg [17:0] roi_vote_blue;
reg [17:0] roi_vote_yellow;
reg [17:0] roi_vote_white;
reg [17:0] roi_vote_black;
reg [17:0] fast_vote_red;
reg [17:0] fast_vote_blue;
reg [17:0] fast_vote_yellow;
reg [17:0] fast_vote_white;
reg [17:0] fast_vote_black;
reg [2:0] color_eval_state;
reg [2:0] color_eval_best_color;
reg [17:0] color_eval_best_count;
reg [17:0] color_eval_second_count;
reg [17:0] color_eval_vote_red;
reg [17:0] color_eval_vote_blue;
reg [17:0] color_eval_vote_yellow;
reg [17:0] color_eval_vote_white;
reg [17:0] color_eval_vote_black;

wire color_roi_y_active;
wire fast_color_roi_y_active;
wire pixel0_in_color_roi;
wire pixel1_in_color_roi;
wire pixel0_in_fast_color_roi;
wire pixel1_in_fast_color_roi;
wire [2:0] pixel0_color_vote;
wire [2:0] pixel1_color_vote;
wire frame_done_pulse;
wire line_end_pulse;
wire [17:0] roi_vote_red_live;
wire [17:0] roi_vote_blue_live;
wire [17:0] roi_vote_yellow_live;
wire [17:0] roi_vote_white_live;
wire [17:0] roi_vote_black_live;
wire [17:0] fast_vote_red_live;
wire [17:0] fast_vote_blue_live;
wire [17:0] fast_vote_yellow_live;
wire [17:0] fast_vote_white_live;
wire [17:0] fast_vote_black_live;
wire [2:0] roi_color_candidate;
wire roi_color_candidate_valid;
wire [2:0] roi_color_candidate_live;
wire roi_color_candidate_live_valid;
wire [2:0] fast_color_candidate_live;
wire fast_color_candidate_live_valid;
wire [3:0] fast_color_lock_required_streak;
wire fast_color_lock_pulse;

assign fast_color_id_out = COLOR_UNKNOWN;
assign fast_color_valid_out = 1'b0;

reg [1:0] vote_inc_red;
reg [1:0] vote_inc_blue;
reg [1:0] vote_inc_yellow;
reg [1:0] vote_inc_white;
reg [1:0] vote_inc_black;
reg [1:0] fast_vote_inc_red;
reg [1:0] fast_vote_inc_blue;
reg [1:0] fast_vote_inc_yellow;
reg [1:0] fast_vote_inc_white;
reg [1:0] fast_vote_inc_black;
reg [2:0] roi_color_candidate_vote;
reg roi_color_candidate_valid_vote;
reg [17:0] roi_vote_winner_count;
reg [17:0] roi_vote_second_count;
reg [2:0] roi_color_candidate_live_vote;
reg roi_color_candidate_valid_live_vote;
reg [17:0] roi_vote_live_winner_count;
reg [17:0] roi_vote_live_second_count;
reg [2:0] fast_color_candidate_live_vote;
reg fast_color_candidate_valid_live_vote;
reg [17:0] fast_vote_live_winner_count;
reg [17:0] fast_vote_live_second_count;

function [2:0] classify_pixel_color;
input [7:0] pixel_r;
input [7:0] pixel_g;
input [7:0] pixel_b;
reg [7:0] diff_rg;
reg [7:0] diff_rb;
reg [7:0] diff_gb;
reg [7:0] max_c;
reg [7:0] min_c;
reg is_true_white;
begin
    diff_rg = (pixel_r > pixel_g) ? (pixel_r - pixel_g) : (pixel_g - pixel_r);
    diff_rb = (pixel_r > pixel_b) ? (pixel_r - pixel_b) : (pixel_b - pixel_r);
    diff_gb = (pixel_g > pixel_b) ? (pixel_g - pixel_b) : (pixel_b - pixel_g);
    max_c = pixel_r;
    if (pixel_g > max_c)
        max_c = pixel_g;
    if (pixel_b > max_c)
        max_c = pixel_b;
    min_c = pixel_r;
    if (pixel_g < min_c)
        min_c = pixel_g;
    if (pixel_b < min_c)
        min_c = pixel_b;
    // Current real white can be dim and green-biased, but still has both G/B
    // high enough to separate it from the lower-saturation background.
    is_true_white = (pixel_g >= 8'd137) &&
                    (pixel_r >= 8'd96) &&
                    (pixel_b >= 8'd71) &&
                    (pixel_g >= pixel_r) &&
                    (diff_rg <= 8'd72) &&
                    (diff_rb <= 8'd60) &&
                    (diff_gb <= 8'd132) &&
                    (({1'b0, diff_rg} + 9'd16) >= {1'b0, diff_rb});

    // Red: R must clearly dominate G/B.
    if ((pixel_r > pixel_g + 8'd18) &&
        (pixel_r > pixel_b + 8'd22) &&
        (pixel_r > 8'd48))
        classify_pixel_color = COLOR_RED;
    // Blue object in this camera pipeline appears as G/B higher than R.
    else if ((pixel_g > pixel_r + 8'd12) &&
             (pixel_b > pixel_r + 8'd10) &&
             ({1'b0, pixel_g} + {1'b0, pixel_b} > ({1'b0, pixel_r, 1'b0} + 9'd20)) &&
             (pixel_b > 8'd30))
        classify_pixel_color = COLOR_BLUE;
    // Rescue dim true-white samples such as R124/G182/B92.
    else if (is_true_white)
        classify_pixel_color = COLOR_WHITE;
    // Yellow: B must stay low, while R/G are both far above B.
    else if ((diff_rg < 8'd40) &&
             (pixel_b <= 8'd58) &&
             (pixel_r > pixel_b + 8'd50) &&
             (pixel_g > pixel_b + 8'd70) &&
             (pixel_r > 8'd108) &&
             (pixel_g > 8'd125) &&
             (({1'b0, diff_rg} + 9'd16) < {1'b0, diff_rb}) &&
             (({1'b0, diff_rg} + 9'd16) < {1'b0, diff_gb}))
        classify_pixel_color = COLOR_YELLOW;
    // Black: all channels are dark and close together.
    else if ((max_c < 8'd52) &&
             ((max_c - min_c) < 8'd20))
        classify_pixel_color = COLOR_BLACK;
    else
        classify_pixel_color = COLOR_UNKNOWN;
end
endfunction

assign color_roi_y_active = (color_y >= COLOR_ROI_Y_START) && (color_y < COLOR_ROI_Y_END);
assign fast_color_roi_y_active = (color_y >= FAST_COLOR_ROI_Y_START) && (color_y < FAST_COLOR_ROI_Y_END);
assign pixel0_in_color_roi = rgb_de && color_roi_y_active &&
                             (color_x >= COLOR_ROI_X_START) && (color_x < COLOR_ROI_X_END);
assign pixel1_in_color_roi = rgb_de && color_roi_y_active &&
                             ((color_x + 12'd1) >= COLOR_ROI_X_START) &&
                             ((color_x + 12'd1) < COLOR_ROI_X_END);
assign pixel0_in_fast_color_roi = rgb_de && fast_color_roi_y_active &&
                                  (color_x >= FAST_COLOR_ROI_X_START) &&
                                  (color_x < FAST_COLOR_ROI_X_END);
assign pixel1_in_fast_color_roi = rgb_de && fast_color_roi_y_active &&
                                  ((color_x + 12'd1) >= FAST_COLOR_ROI_X_START) &&
                                  ((color_x + 12'd1) < FAST_COLOR_ROI_X_END);
assign pixel0_color_vote = classify_pixel_color(rgb_datax2[31:24], rgb_datax2[39:32], rgb_datax2[47:40]);
assign pixel1_color_vote = classify_pixel_color(rgb_datax2[7:0], rgb_datax2[15:8], rgb_datax2[23:16]);
assign line_end_pulse = rgb_de_d && !rgb_de;
assign frame_done_pulse = ({rgb_vs_d, rgb_vs} == 2'b01);

always @* begin
    vote_inc_red = 2'd0;
    vote_inc_blue = 2'd0;
    vote_inc_yellow = 2'd0;
    vote_inc_white = 2'd0;
    vote_inc_black = 2'd0;

    if (pixel0_in_color_roi) begin
        case (pixel0_color_vote)
            COLOR_RED:    vote_inc_red = vote_inc_red + 2'd1;
            COLOR_BLUE:   vote_inc_blue = vote_inc_blue + 2'd1;
            COLOR_YELLOW: vote_inc_yellow = vote_inc_yellow + 2'd1;
            COLOR_WHITE:  vote_inc_white = vote_inc_white + 2'd1;
            COLOR_BLACK:  vote_inc_black = vote_inc_black + 2'd1;
            default: ;
        endcase
    end

    if (pixel1_in_color_roi) begin
        case (pixel1_color_vote)
            COLOR_RED:    vote_inc_red = vote_inc_red + 2'd1;
            COLOR_BLUE:   vote_inc_blue = vote_inc_blue + 2'd1;
            COLOR_YELLOW: vote_inc_yellow = vote_inc_yellow + 2'd1;
            COLOR_WHITE:  vote_inc_white = vote_inc_white + 2'd1;
            COLOR_BLACK:  vote_inc_black = vote_inc_black + 2'd1;
            default: ;
        endcase
    end
end

always @* begin
    fast_vote_inc_red = 2'd0;
    fast_vote_inc_blue = 2'd0;
    fast_vote_inc_yellow = 2'd0;
    fast_vote_inc_white = 2'd0;
    fast_vote_inc_black = 2'd0;

    if (pixel0_in_fast_color_roi) begin
        case (pixel0_color_vote)
            COLOR_RED:    fast_vote_inc_red = fast_vote_inc_red + 2'd1;
            COLOR_BLUE:   fast_vote_inc_blue = fast_vote_inc_blue + 2'd1;
            COLOR_YELLOW: fast_vote_inc_yellow = fast_vote_inc_yellow + 2'd1;
            COLOR_WHITE:  fast_vote_inc_white = fast_vote_inc_white + 2'd1;
            COLOR_BLACK:  fast_vote_inc_black = fast_vote_inc_black + 2'd1;
            default: ;
        endcase
    end

    if (pixel1_in_fast_color_roi) begin
        case (pixel1_color_vote)
            COLOR_RED:    fast_vote_inc_red = fast_vote_inc_red + 2'd1;
            COLOR_BLUE:   fast_vote_inc_blue = fast_vote_inc_blue + 2'd1;
            COLOR_YELLOW: fast_vote_inc_yellow = fast_vote_inc_yellow + 2'd1;
            COLOR_WHITE:  fast_vote_inc_white = fast_vote_inc_white + 2'd1;
            COLOR_BLACK:  fast_vote_inc_black = fast_vote_inc_black + 2'd1;
            default: ;
        endcase
    end
end

assign roi_vote_red_live = roi_vote_red + {{16{1'b0}}, vote_inc_red};
assign roi_vote_blue_live = roi_vote_blue + {{16{1'b0}}, vote_inc_blue};
assign roi_vote_yellow_live = roi_vote_yellow + {{16{1'b0}}, vote_inc_yellow};
assign roi_vote_white_live = roi_vote_white + {{16{1'b0}}, vote_inc_white};
assign roi_vote_black_live = roi_vote_black + {{16{1'b0}}, vote_inc_black};
assign fast_vote_red_live = fast_vote_red + {{16{1'b0}}, fast_vote_inc_red};
assign fast_vote_blue_live = fast_vote_blue + {{16{1'b0}}, fast_vote_inc_blue};
assign fast_vote_yellow_live = fast_vote_yellow + {{16{1'b0}}, fast_vote_inc_yellow};
assign fast_vote_white_live = fast_vote_white + {{16{1'b0}}, fast_vote_inc_white};
assign fast_vote_black_live = fast_vote_black + {{16{1'b0}}, fast_vote_inc_black};

always @* begin
    roi_color_candidate_vote = COLOR_UNKNOWN;
    roi_vote_winner_count = 18'd0;
    roi_vote_second_count = 18'd0;

    if (roi_vote_red > roi_vote_winner_count) begin
        roi_vote_second_count = roi_vote_winner_count;
        roi_vote_winner_count = roi_vote_red;
        roi_color_candidate_vote = COLOR_RED;
    end else if (roi_vote_red > roi_vote_second_count) begin
        roi_vote_second_count = roi_vote_red;
    end

    if (roi_vote_blue > roi_vote_winner_count) begin
        roi_vote_second_count = roi_vote_winner_count;
        roi_vote_winner_count = roi_vote_blue;
        roi_color_candidate_vote = COLOR_BLUE;
    end else if (roi_vote_blue > roi_vote_second_count) begin
        roi_vote_second_count = roi_vote_blue;
    end

    if (roi_vote_yellow > roi_vote_winner_count) begin
        roi_vote_second_count = roi_vote_winner_count;
        roi_vote_winner_count = roi_vote_yellow;
        roi_color_candidate_vote = COLOR_YELLOW;
    end else if (roi_vote_yellow > roi_vote_second_count) begin
        roi_vote_second_count = roi_vote_yellow;
    end

    if (roi_vote_white > roi_vote_winner_count) begin
        roi_vote_second_count = roi_vote_winner_count;
        roi_vote_winner_count = roi_vote_white;
        roi_color_candidate_vote = COLOR_WHITE;
    end else if (roi_vote_white > roi_vote_second_count) begin
        roi_vote_second_count = roi_vote_white;
    end

    if (roi_vote_black > roi_vote_winner_count) begin
        roi_vote_second_count = roi_vote_winner_count;
        roi_vote_winner_count = roi_vote_black;
        roi_color_candidate_vote = COLOR_BLACK;
    end else if (roi_vote_black > roi_vote_second_count) begin
        roi_vote_second_count = roi_vote_black;
    end

    roi_color_candidate_valid_vote =
        (roi_color_candidate_vote != COLOR_UNKNOWN) &&
        (roi_vote_winner_count >= VOTE_MIN_COUNT) &&
        (roi_vote_winner_count > (roi_vote_second_count + VOTE_MARGIN));
end

always @* begin
    roi_color_candidate_live_vote = COLOR_UNKNOWN;
    roi_vote_live_winner_count = 18'd0;
    roi_vote_live_second_count = 18'd0;

    if (roi_vote_red > roi_vote_live_winner_count) begin
        roi_vote_live_second_count = roi_vote_live_winner_count;
        roi_vote_live_winner_count = roi_vote_red;
        roi_color_candidate_live_vote = COLOR_RED;
    end else if (roi_vote_red > roi_vote_live_second_count) begin
        roi_vote_live_second_count = roi_vote_red;
    end

    if (roi_vote_blue > roi_vote_live_winner_count) begin
        roi_vote_live_second_count = roi_vote_live_winner_count;
        roi_vote_live_winner_count = roi_vote_blue;
        roi_color_candidate_live_vote = COLOR_BLUE;
    end else if (roi_vote_blue > roi_vote_live_second_count) begin
        roi_vote_live_second_count = roi_vote_blue;
    end

    if (roi_vote_yellow > roi_vote_live_winner_count) begin
        roi_vote_live_second_count = roi_vote_live_winner_count;
        roi_vote_live_winner_count = roi_vote_yellow;
        roi_color_candidate_live_vote = COLOR_YELLOW;
    end else if (roi_vote_yellow > roi_vote_live_second_count) begin
        roi_vote_live_second_count = roi_vote_yellow;
    end

    if (roi_vote_white > roi_vote_live_winner_count) begin
        roi_vote_live_second_count = roi_vote_live_winner_count;
        roi_vote_live_winner_count = roi_vote_white;
        roi_color_candidate_live_vote = COLOR_WHITE;
    end else if (roi_vote_white > roi_vote_live_second_count) begin
        roi_vote_live_second_count = roi_vote_white;
    end

    if (roi_vote_black > roi_vote_live_winner_count) begin
        roi_vote_live_second_count = roi_vote_live_winner_count;
        roi_vote_live_winner_count = roi_vote_black;
        roi_color_candidate_live_vote = COLOR_BLACK;
    end else if (roi_vote_black > roi_vote_live_second_count) begin
        roi_vote_live_second_count = roi_vote_black;
    end

    roi_color_candidate_valid_live_vote =
        (roi_color_candidate_live_vote != COLOR_UNKNOWN) &&
        (roi_vote_live_winner_count >= VOTE_MIN_COUNT) &&
        (roi_vote_live_winner_count > (roi_vote_live_second_count + VOTE_MARGIN));
end

always @* begin
    fast_color_candidate_live_vote = COLOR_UNKNOWN;
    fast_vote_live_winner_count = 18'd0;
    fast_vote_live_second_count = 18'd0;

    if (fast_vote_red > fast_vote_live_winner_count) begin
        fast_vote_live_second_count = fast_vote_live_winner_count;
        fast_vote_live_winner_count = fast_vote_red;
        fast_color_candidate_live_vote = COLOR_RED;
    end else if (fast_vote_red > fast_vote_live_second_count) begin
        fast_vote_live_second_count = fast_vote_red;
    end

    if (fast_vote_blue > fast_vote_live_winner_count) begin
        fast_vote_live_second_count = fast_vote_live_winner_count;
        fast_vote_live_winner_count = fast_vote_blue;
        fast_color_candidate_live_vote = COLOR_BLUE;
    end else if (fast_vote_blue > fast_vote_live_second_count) begin
        fast_vote_live_second_count = fast_vote_blue;
    end

    if (fast_vote_yellow > fast_vote_live_winner_count) begin
        fast_vote_live_second_count = fast_vote_live_winner_count;
        fast_vote_live_winner_count = fast_vote_yellow;
        fast_color_candidate_live_vote = COLOR_YELLOW;
    end else if (fast_vote_yellow > fast_vote_live_second_count) begin
        fast_vote_live_second_count = fast_vote_yellow;
    end

    if (fast_vote_white > fast_vote_live_winner_count) begin
        fast_vote_live_second_count = fast_vote_live_winner_count;
        fast_vote_live_winner_count = fast_vote_white;
        fast_color_candidate_live_vote = COLOR_WHITE;
    end else if (fast_vote_white > fast_vote_live_second_count) begin
        fast_vote_live_second_count = fast_vote_white;
    end

    if (fast_vote_black > fast_vote_live_winner_count) begin
        fast_vote_live_second_count = fast_vote_live_winner_count;
        fast_vote_live_winner_count = fast_vote_black;
        fast_color_candidate_live_vote = COLOR_BLACK;
    end else if (fast_vote_black > fast_vote_live_second_count) begin
        fast_vote_live_second_count = fast_vote_black;
    end

    fast_color_candidate_valid_live_vote =
        (fast_color_candidate_live_vote != COLOR_UNKNOWN) &&
        (fast_vote_live_winner_count >= FAST_VOTE_MIN_COUNT) &&
        (fast_vote_live_winner_count > (fast_vote_live_second_count + FAST_VOTE_MARGIN));
end

assign roi_color_candidate = roi_color_candidate_vote;
assign roi_color_candidate_valid = roi_color_candidate_valid_vote;
assign roi_color_candidate_live = roi_color_candidate_live_vote;
assign roi_color_candidate_live_valid = roi_color_candidate_valid_live_vote;
assign fast_color_candidate_live = fast_color_candidate_live_vote;
assign fast_color_candidate_live_valid = fast_color_candidate_valid_live_vote;
assign fast_color_lock_required_streak =
    (!fast_color_valid || (fast_color_id == COLOR_UNKNOWN)) ?
    FAST_LOCK_LINE_STREAK_NEW : FAST_LOCK_LINE_STREAK_SWITCH;
assign fast_color_lock_pulse = 1'b0;

assign color_timer_start_pulse = 1'b0;
assign color_timer_stop_pulse = 1'b0;
assign color_timer_cancel_pulse = 1'b0;
assign fast_color_timer_start_pulse = 1'b0;
assign fast_color_timer_stop_pulse = 1'b0;
assign fast_color_timer_cancel_pulse = 1'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rgb_vs_d <= 1'b0;
        rgb_de_d <= 1'b0;
        color_x <= 12'd0;
        color_y <= 11'd0;
        color_id <= COLOR_UNKNOWN;
        color_valid <= 1'b0;
        color_candidate_prev <= COLOR_UNKNOWN;
        color_candidate_prev_valid <= 1'b0;
        color_invalid_frames <= 2'd0;
        fast_color_id <= COLOR_UNKNOWN;
        fast_color_valid <= 1'b0;
        fast_color_candidate_prev <= COLOR_UNKNOWN;
        fast_color_candidate_prev_valid <= 1'b0;
        fast_color_candidate_streak <= 4'd0;
        roi_vote_red <= 18'd0;
        roi_vote_blue <= 18'd0;
        roi_vote_yellow <= 18'd0;
        roi_vote_white <= 18'd0;
        roi_vote_black <= 18'd0;
        color_eval_state <= COLOR_EVAL_IDLE;
        color_eval_best_color <= COLOR_UNKNOWN;
        color_eval_best_count <= 18'd0;
        color_eval_second_count <= 18'd0;
        color_eval_vote_red <= 18'd0;
        color_eval_vote_blue <= 18'd0;
        color_eval_vote_yellow <= 18'd0;
        color_eval_vote_white <= 18'd0;
        color_eval_vote_black <= 18'd0;
        fast_vote_red <= 18'd0;
        fast_vote_blue <= 18'd0;
        fast_vote_yellow <= 18'd0;
        fast_vote_white <= 18'd0;
        fast_vote_black <= 18'd0;
    end else begin
        rgb_vs_d <= rgb_vs;
        rgb_de_d <= rgb_de;

        if (frame_done_pulse) begin
            color_eval_vote_red <= roi_vote_red;
            color_eval_vote_blue <= roi_vote_blue;
            color_eval_vote_yellow <= roi_vote_yellow;
            color_eval_vote_white <= roi_vote_white;
            color_eval_vote_black <= roi_vote_black;
            color_eval_state <= COLOR_EVAL_RED;
            color_x <= 12'd0;
            color_y <= 11'd0;
            roi_vote_red <= 18'd0;
            roi_vote_blue <= 18'd0;
            roi_vote_yellow <= 18'd0;
            roi_vote_white <= 18'd0;
            roi_vote_black <= 18'd0;
            fast_vote_red <= 18'd0;
            fast_vote_blue <= 18'd0;
            fast_vote_yellow <= 18'd0;
            fast_vote_white <= 18'd0;
            fast_vote_black <= 18'd0;
            fast_color_candidate_prev <= COLOR_UNKNOWN;
            fast_color_candidate_prev_valid <= 1'b0;
            fast_color_candidate_streak <= 4'd0;
            if (!fast_color_candidate_live_valid) begin
                fast_color_id <= COLOR_UNKNOWN;
                fast_color_valid <= 1'b0;
            end
        end else begin
            case (color_eval_state)
                COLOR_EVAL_RED: begin
                    color_eval_best_color <= COLOR_RED;
                    color_eval_best_count <= color_eval_vote_red;
                    color_eval_second_count <= 18'd0;
                    color_eval_state <= COLOR_EVAL_BLUE;
                end
                COLOR_EVAL_BLUE: begin
                    if (color_eval_vote_blue > color_eval_best_count) begin
                        color_eval_second_count <= color_eval_best_count;
                        color_eval_best_count <= color_eval_vote_blue;
                        color_eval_best_color <= COLOR_BLUE;
                    end else if (color_eval_vote_blue > color_eval_second_count) begin
                        color_eval_second_count <= color_eval_vote_blue;
                    end
                    color_eval_state <= COLOR_EVAL_YELLOW;
                end
                COLOR_EVAL_YELLOW: begin
                    if (color_eval_vote_yellow > color_eval_best_count) begin
                        color_eval_second_count <= color_eval_best_count;
                        color_eval_best_count <= color_eval_vote_yellow;
                        color_eval_best_color <= COLOR_YELLOW;
                    end else if (color_eval_vote_yellow > color_eval_second_count) begin
                        color_eval_second_count <= color_eval_vote_yellow;
                    end
                    color_eval_state <= COLOR_EVAL_WHITE;
                end
                COLOR_EVAL_WHITE: begin
                    if (color_eval_vote_white > color_eval_best_count) begin
                        color_eval_second_count <= color_eval_best_count;
                        color_eval_best_count <= color_eval_vote_white;
                        color_eval_best_color <= COLOR_WHITE;
                    end else if (color_eval_vote_white > color_eval_second_count) begin
                        color_eval_second_count <= color_eval_vote_white;
                    end
                    color_eval_state <= COLOR_EVAL_BLACK;
                end
                COLOR_EVAL_BLACK: begin
                    if (color_eval_vote_black > color_eval_best_count) begin
                        color_eval_second_count <= color_eval_best_count;
                        color_eval_best_count <= color_eval_vote_black;
                        color_eval_best_color <= COLOR_BLACK;
                    end else if (color_eval_vote_black > color_eval_second_count) begin
                        color_eval_second_count <= color_eval_vote_black;
                    end
                    color_eval_state <= COLOR_EVAL_DONE;
                end
                COLOR_EVAL_DONE: begin
                    if ((color_eval_best_count >= VOTE_MIN_COUNT) &&
                        (color_eval_best_count > (color_eval_second_count + VOTE_MARGIN))) begin
                        color_invalid_frames <= 2'd0;
                        if (color_candidate_prev_valid &&
                            (color_eval_best_color == color_candidate_prev)) begin
                            color_id <= color_eval_best_color;
                            color_valid <= 1'b1;
                        end
                        color_candidate_prev <= color_eval_best_color;
                        color_candidate_prev_valid <= 1'b1;
                    end else begin
                        color_candidate_prev_valid <= 1'b0;
                        if (color_invalid_frames >= 2'd1) begin
                            color_id <= COLOR_UNKNOWN;
                            color_valid <= 1'b0;
                        end
                        if (color_invalid_frames != 2'd3)
                            color_invalid_frames <= color_invalid_frames + 2'd1;
                    end
                    color_eval_state <= COLOR_EVAL_IDLE;
                end
                default: begin
                    color_eval_state <= COLOR_EVAL_IDLE;
                end
            endcase

            if (line_end_pulse) begin
                if (fast_color_candidate_live_valid) begin
                    if (fast_color_candidate_prev_valid &&
                        (fast_color_candidate_live == fast_color_candidate_prev)) begin
                        if (fast_color_candidate_streak < FAST_LOCK_LINE_STREAK_SWITCH)
                            fast_color_candidate_streak <= fast_color_candidate_streak + 4'd1;
                    end else begin
                        fast_color_candidate_prev <= fast_color_candidate_live;
                        fast_color_candidate_prev_valid <= 1'b1;
                        fast_color_candidate_streak <= 4'd1;
                    end

                    if (fast_color_lock_pulse) begin
                        fast_color_id <= fast_color_candidate_live;
                        fast_color_valid <= 1'b1;
                    end
                end else begin
                    fast_color_candidate_prev <= COLOR_UNKNOWN;
                    fast_color_candidate_prev_valid <= 1'b0;
                    fast_color_candidate_streak <= 4'd0;
                end
            end

            if (rgb_de) begin
                if (!rgb_de_d)
                    color_x <= 12'd0;
                else
                    color_x <= color_x + 12'd2;

                if (color_roi_y_active) begin
                    roi_vote_red <= roi_vote_red + vote_inc_red;
                    roi_vote_blue <= roi_vote_blue + vote_inc_blue;
                    roi_vote_yellow <= roi_vote_yellow + vote_inc_yellow;
                    roi_vote_white <= roi_vote_white + vote_inc_white;
                    roi_vote_black <= roi_vote_black + vote_inc_black;
                end

                if (fast_color_roi_y_active) begin
                    fast_vote_red <= fast_vote_red + fast_vote_inc_red;
                    fast_vote_blue <= fast_vote_blue + fast_vote_inc_blue;
                    fast_vote_yellow <= fast_vote_yellow + fast_vote_inc_yellow;
                    fast_vote_white <= fast_vote_white + fast_vote_inc_white;
                    fast_vote_black <= fast_vote_black + fast_vote_inc_black;
                end
            end else begin
                color_x <= 12'd0;
                if (rgb_de_d && (color_y < VACT - 1'b1))
                    color_y <= color_y + 11'd1;
            end
        end
    end
end

endmodule

`endif
