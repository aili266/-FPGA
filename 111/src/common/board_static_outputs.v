`ifndef BOARD_STATIC_OUTPUTS_V
`define BOARD_STATIC_OUTPUTS_V

module board_static_outputs (
    input  wire [19:0] led_status,
    output wire [19:0] led,
    output wire uart1_txd,
    output wire uart2_txd,
    output wire jtag_inst1_tdo,

    output wire s0_cam_scl_out,
    output wire s0_cam_scl_oe,
    output wire s0_cam_sda_out,
    output wire s0_cam_sda_oe,
    output wire s0_cam_rst_p,

    output wire mipi_rx_ck0_hs_ena,
    output wire mipi_rx_dp00_hs_ena,
    output wire mipi_rx_dp01_hs_ena,
    output wire mipi_rx_dp02_hs_ena,
    output wire mipi_rx_dp03_hs_ena,

    output wire mipi_rx_ck0_hs_term,
    output wire mipi_rx_dp00_hs_term,
    output wire mipi_rx_dp01_hs_term,
    output wire mipi_rx_dp02_hs_term,
    output wire mipi_rx_dp03_hs_term,

    output wire mipi_rx_dp00_rst,
    output wire mipi_rx_dp01_rst,
    output wire mipi_rx_dp02_rst,
    output wire mipi_rx_dp03_rst,

    output wire mipi_rx_dp00_fifo_rd,
    output wire mipi_rx_dp01_fifo_rd,
    output wire mipi_rx_dp02_fifo_rd,
    output wire mipi_rx_dp03_fifo_rd
);

// Keep unused board outputs in their inactive states from one small module.
assign led = led_status;

assign uart1_txd = 1'b1;
assign uart2_txd = 1'b1;

assign jtag_inst1_tdo = 1'b0;

assign {s0_cam_scl_out, s0_cam_scl_oe, s0_cam_sda_out, s0_cam_sda_oe, s0_cam_rst_p} = 5'b00000;

assign {mipi_rx_ck0_hs_ena,
        mipi_rx_dp00_hs_ena,
        mipi_rx_dp01_hs_ena,
        mipi_rx_dp02_hs_ena,
        mipi_rx_dp03_hs_ena} = 5'b00000;

assign {mipi_rx_ck0_hs_term,
        mipi_rx_dp00_hs_term,
        mipi_rx_dp01_hs_term,
        mipi_rx_dp02_hs_term,
        mipi_rx_dp03_hs_term} = 5'b00000;

assign {mipi_rx_dp00_rst,
        mipi_rx_dp01_rst,
        mipi_rx_dp02_rst,
        mipi_rx_dp03_rst} = 4'b0000;

assign {mipi_rx_dp00_fifo_rd,
        mipi_rx_dp01_fifo_rd,
        mipi_rx_dp02_fifo_rd,
        mipi_rx_dp03_fifo_rd} = 4'b0000;

endmodule

`endif
