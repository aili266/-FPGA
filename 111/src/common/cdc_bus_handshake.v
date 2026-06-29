`ifndef CDC_BUS_HANDSHAKE_V
`define CDC_BUS_HANDSHAKE_V

module cdc_bus_handshake #(
    parameter WIDTH = 8
) (
    input  wire             src_clk,
    input  wire             src_rst_n,
    input  wire             src_update,
    input  wire [WIDTH-1:0] src_data,
    output wire             src_ready,

    input  wire             dst_clk,
    input  wire             dst_rst_n,
    output reg              dst_pulse,
    output reg  [WIDTH-1:0] dst_data
);

reg [WIDTH-1:0] src_data_hold;
reg src_req_toggle;
(* async_reg = "true" *) reg [2:0] src_ack_sync;

(* async_reg = "true" *) reg [2:0] dst_req_sync;
reg dst_ack_toggle;

assign src_ready = (src_req_toggle == src_ack_sync[2]);

always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
        src_data_hold <= {WIDTH{1'b0}};
        src_req_toggle <= 1'b0;
        src_ack_sync <= 3'b000;
    end else begin
        src_ack_sync <= {src_ack_sync[1:0], dst_ack_toggle};

        if (src_update && src_ready) begin
            src_data_hold <= src_data;
            src_req_toggle <= ~src_req_toggle;
        end
    end
end

always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
        dst_req_sync <= 3'b000;
        dst_ack_toggle <= 1'b0;
        dst_pulse <= 1'b0;
        dst_data <= {WIDTH{1'b0}};
    end else begin
        dst_req_sync <= {dst_req_sync[1:0], src_req_toggle};
        dst_pulse <= 1'b0;

        if (dst_req_sync[2] != dst_ack_toggle) begin
            dst_data <= src_data_hold;
            dst_ack_toggle <= dst_req_sync[2];
            dst_pulse <= 1'b1;
        end
    end
end

endmodule

`endif
