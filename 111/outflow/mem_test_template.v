
// Efinity Top-level template
// Version: 2025.2.288
// Date: 2026-06-27 14:07

// Copyright (C) 2013 - 2025 Efinix Inc. All rights reserved.

// This file may be used as a starting point for Efinity synthesis top-level target.
// The port list here matches what is expected by Efinity constraint files generated
// by the Efinity Interface Designer.

// To use this:
//     #1)  Save this file with a different name to a different directory, where source files are kept.
//              Example: you may wish to save as mem_test.v
//     #2)  Add the newly saved file into Efinity project as design file
//     #3)  Edit the top level entity in Efinity project to:  mem_test
//     #4)  Insert design content.


module mem_test
(
  (* syn_peri_port = 0 *) input AxiPllClkIn,
  (* syn_peri_port = 0 *) input DdrPllClkIn,
  (* syn_peri_port = 0 *) input [1:0] PllLocked,
  (* syn_peri_port = 0 *) input hdmi_lock_i,
  (* syn_peri_port = 0 *) input mipi_lock_i,
  (* syn_peri_port = 0 *) input mipi0_scl_i,
  (* syn_peri_port = 0 *) input mipi0_sda_i,
  (* syn_peri_port = 0 *) input mipi1_scl_i,
  (* syn_peri_port = 0 *) input mipi1_sda_i,
  (* syn_peri_port = 0 *) input uart_rxd,
  (* syn_peri_port = 0 *) input [3:0] mipi_rx_0_CNT_i,
  (* syn_peri_port = 0 *) input [63:0] mipi_rx_0_DATA_i,
  (* syn_peri_port = 0 *) input [17:0] mipi_rx_0_ERROR,
  (* syn_peri_port = 0 *) input [3:0] mipi_rx_0_HSYNC_i,
  (* syn_peri_port = 0 *) input [5:0] mipi_rx_0_TYPE_i,
  (* syn_peri_port = 0 *) input [3:0] mipi_rx_0_ULPS,
  (* syn_peri_port = 0 *) input mipi_rx_0_ULPS_CLK,
  (* syn_peri_port = 0 *) input mipi_rx_0_VALID_i,
  (* syn_peri_port = 0 *) input [1:0] mipi_rx_0_VC_i,
  (* syn_peri_port = 0 *) input [3:0] mipi_rx_0_VSYNC_i,
  (* syn_peri_port = 0 *) input [3:0] mipi_rx_1_CNT_i,
  (* syn_peri_port = 0 *) input [63:0] mipi_rx_1_DATA_i,
  (* syn_peri_port = 0 *) input [17:0] mipi_rx_1_ERROR,
  (* syn_peri_port = 0 *) input [3:0] mipi_rx_1_HSYNC_i,
  (* syn_peri_port = 0 *) input [5:0] mipi_rx_1_TYPE_i,
  (* syn_peri_port = 0 *) input [3:0] mipi_rx_1_ULPS,
  (* syn_peri_port = 0 *) input mipi_rx_1_ULPS_CLK,
  (* syn_peri_port = 0 *) input mipi_rx_1_VALID_i,
  (* syn_peri_port = 0 *) input [1:0] mipi_rx_1_VC_i,
  (* syn_peri_port = 0 *) input [3:0] mipi_rx_1_VSYNC_i,
  (* syn_peri_port = 0 *) input mipi_clkesc_i,
  (* syn_peri_port = 0 *) input mipi_clkcal_i,
  (* syn_peri_port = 0 *) input mipi_pixclk_i,
  (* syn_peri_port = 0 *) input Axi0Clk,
  (* syn_peri_port = 0 *) input tx_slowclk,
  (* syn_peri_port = 0 *) input tx_fastclk,
  (* syn_peri_port = 0 *) input hdmi_clk2x_i,
  (* syn_peri_port = 0 *) input hdmi_clk5x_i,
  (* syn_peri_port = 0 *) input clk_cmos,
  (* syn_peri_port = 0 *) input hdmi_clk1x_i,
  (* syn_peri_port = 0 *) input DdrCtrl_AREADY_0,
  (* syn_peri_port = 0 *) input [7:0] DdrCtrl_BID_0,
  (* syn_peri_port = 0 *) input DdrCtrl_BVALID_0,
  (* syn_peri_port = 0 *) input [127:0] DdrCtrl_RDATA_0,
  (* syn_peri_port = 0 *) input [7:0] DdrCtrl_RID_0,
  (* syn_peri_port = 0 *) input DdrCtrl_RLAST_0,
  (* syn_peri_port = 0 *) input [1:0] DdrCtrl_RRESP_0,
  (* syn_peri_port = 0 *) input DdrCtrl_RVALID_0,
  (* syn_peri_port = 0 *) input DdrCtrl_WREADY_0,
  (* syn_peri_port = 0 *) output [7:0] led_data,
  (* syn_peri_port = 0 *) output hdmi_resetn_o,
  (* syn_peri_port = 0 *) output mipi_resetn_o,
  (* syn_peri_port = 0 *) output mipi0_scl_o,
  (* syn_peri_port = 0 *) output mipi0_scl_oe,
  (* syn_peri_port = 0 *) output mipi0_sda_o,
  (* syn_peri_port = 0 *) output mipi0_sda_oe,
  (* syn_peri_port = 0 *) output mipi1_scl_o,
  (* syn_peri_port = 0 *) output mipi1_scl_oe,
  (* syn_peri_port = 0 *) output mipi1_sda_o,
  (* syn_peri_port = 0 *) output mipi1_sda_oe,
  (* syn_peri_port = 0 *) output [1:0] mipi_trig_o,
  (* syn_peri_port = 0 *) output uart_txd,
  (* syn_peri_port = 0 *) output [4:0] hdmi_tx0_o,
  (* syn_peri_port = 0 *) output [4:0] hdmi_tx1_o,
  (* syn_peri_port = 0 *) output [4:0] hdmi_tx2_o,
  (* syn_peri_port = 0 *) output [4:0] hdmi_txc_o,
  (* syn_peri_port = 0 *) output mipi_rx_0_CLEAR,
  (* syn_peri_port = 0 *) output mipi_rx_0_DPHY_RSTN_o,
  (* syn_peri_port = 0 *) output [1:0] mipi_rx_0_LANES_o,
  (* syn_peri_port = 0 *) output mipi_rx_0_RSTN_o,
  (* syn_peri_port = 0 *) output [3:0] mipi_rx_0_VC_ENA_o,
  (* syn_peri_port = 0 *) output mipi_rx_1_CLEAR,
  (* syn_peri_port = 0 *) output mipi_rx_1_DPHY_RSTN_o,
  (* syn_peri_port = 0 *) output [1:0] mipi_rx_1_LANES_o,
  (* syn_peri_port = 0 *) output mipi_rx_1_RSTN_o,
  (* syn_peri_port = 0 *) output [3:0] mipi_rx_1_VC_ENA_o,
  (* syn_peri_port = 0 *) output [31:0] DdrCtrl_AADDR_0,
  (* syn_peri_port = 0 *) output [1:0] DdrCtrl_ABURST_0,
  (* syn_peri_port = 0 *) output [7:0] DdrCtrl_AID_0,
  (* syn_peri_port = 0 *) output [7:0] DdrCtrl_ALEN_0,
  (* syn_peri_port = 0 *) output [1:0] DdrCtrl_ALOCK_0,
  (* syn_peri_port = 0 *) output [2:0] DdrCtrl_ASIZE_0,
  (* syn_peri_port = 0 *) output DdrCtrl_ATYPE_0,
  (* syn_peri_port = 0 *) output DdrCtrl_AVALID_0,
  (* syn_peri_port = 0 *) output DdrCtrl_BREADY_0,
  (* syn_peri_port = 0 *) output DdrCtrl_CFG_SEQ_RST,
  (* syn_peri_port = 0 *) output DdrCtrl_CFG_SEQ_START,
  (* syn_peri_port = 0 *) output DdrCtrl_RREADY_0,
  (* syn_peri_port = 0 *) output DdrCtrl_RSTN,
  (* syn_peri_port = 0 *) output [127:0] DdrCtrl_WDATA_0,
  (* syn_peri_port = 0 *) output [7:0] DdrCtrl_WID_0,
  (* syn_peri_port = 0 *) output DdrCtrl_WLAST_0,
  (* syn_peri_port = 0 *) output [15:0] DdrCtrl_WSTRB_0,
  (* syn_peri_port = 0 *) output DdrCtrl_WVALID_0
);


endmodule

