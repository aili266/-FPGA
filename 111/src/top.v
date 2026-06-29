/*
 * top.v
 *
 * Project top level.
 * Main data path:
 *   MIPI camera -> frame_buffer/DDR -> debayer -> RGB stream
 *   RGB stream  -> color/shape recognition -> HDMI debug/result UI
 *
 * Switch usage in the current version:
 *   i_sw[0]: global PLL/reset release
 *   i_sw[1]: toggle UI/recognition mode on each press
 *   i_sw[2]: reserved
 * Shape background learning is triggered automatically when entering shape page.
 */
`define FRAME_BUFFER
`define T35_RESOURCE_TRIM
`ifndef T35_RESOURCE_TRIM
`define HDMI_OUT_EN
`endif

`include "common/system_startup_ctrl.v"
`include "common/board_static_outputs.v"
`include "common/cdc_bus_handshake.v"
`ifdef HDMI_OUT_EN
`include "dvi_tx/hdmi_timing_640x480.v"
`include "dvi_tx/ui_mode_latch.v"
`include "dvi_tx/hdmi_result_ui.v"
`endif
`include "vision/color_detector.v"
`include "vision/shape_scanner.v"
`include "vision/shape_classifier.v"
`include "vision/shape_page_ctrl.v"
`include "vision/shape_recognition_core.v"

// Top-level parameters mainly describe AXI width, frame-buffer geometry,
// and the video timing used by the DDR readout side.
module top #(
parameter AXI_DATA_WIDTH = 512,

parameter I_VID_WIDTH    = 32,
parameter O_VID_WIDTH    = 16,
parameter AXI_ADDR_WIDTH = 33,
parameter WR_FIFO_DEPTH	 = 256,    
parameter RD_FIFO_DEPTH  = 256,
parameter MAX_VID_WIDTH	 = 1920 ,//video width 
parameter MAX_VID_HIGHT	 = 1080 ,//wideo height
parameter START_ADDR     = 33'h000000000,
parameter FB_NUM		 = 3,//2 buffer ,3 buffer   
parameter BURST_LEN      = 63,
parameter   AXI_ID_WIDTH    = 8,
parameter   S_COUNT 					= 1,
parameter   M_COUNT 					= 1,  
// parameter HACT		     = 13'd3840,
parameter PACK_BIT          = 40,
parameter	HACT		    = 12'd1920,
parameter	VACT		    = 12'd1080,
parameter	HSP				= 8'd4,
parameter	HBP				= 8'd88,
parameter	HFP				= 8'd120,
parameter	VSP				= 6'd2,
parameter	VBP				= 6'd20,
parameter	VFP				= 6'd20


)(
  // These ports are generated around the Efinity peripheral interfaces:
  // clocks/PLL lock signals, DDR AXI pins, MIPI D-PHY RX pins, HDMI pins,
  // camera I2C pins, JTAG debug pins, LEDs, and UART pins.
  (* syn_peri_port = 0 *) input mipi_clk,
  (* syn_peri_port = 0 *) input clk_74p25m,
  (* syn_peri_port = 0 *) input ddr_clk_ref,
  (* syn_peri_port = 0 *) input [2:0] i_sw,
  (* syn_peri_port = 0 *) input sys_pll_lock,
  (* syn_peri_port = 0 *) input ddr_pll_lock,
  (* syn_peri_port = 0 *) input fb_pll_locked,
  (* syn_peri_port = 0 *) input pll_byteclk_locked,
  (* syn_peri_port = 0 *) input hdmi_pll_locked,
  (* syn_peri_port = 0 *) input hdmi_tx_fast_clk,
  (* syn_peri_port = 0 *) input CLK_5M,
  (* syn_peri_port = 0 *) input i_sysclk_div2,
  (* syn_peri_port = 0 *) input pll_inst1_CLKOUT0,
  (* syn_peri_port = 0 *) input mipi0_ref_clk,
  (* syn_peri_port = 0 *) input hdmi_tx_slow_clk,
  (* syn_peri_port = 0 *) input pll_inst2_CLKOUT0,
  (* syn_peri_port = 0 *) input axi0_ACLK,
  (* syn_peri_port = 0 *) input mipi_rx_ck0_CLKOUT,
  (* syn_peri_port = 0 *) input mipi_rx_ck1_CLKOUT,
  (* syn_peri_port = 0 *) input gpio_clk_50m,
  (* syn_peri_port = 0 *) input i_fb_clk,
  (* syn_peri_port = 0 *) input jtag_inst1_CAPTURE,
  (* syn_peri_port = 0 *) input jtag_inst1_DRCK,
  (* syn_peri_port = 0 *) input jtag_inst1_RESET,
  (* syn_peri_port = 0 *) input jtag_inst1_RUNTEST,
  (* syn_peri_port = 0 *) input jtag_inst1_SEL,
  (* syn_peri_port = 0 *) input jtag_inst1_SHIFT,
  (* syn_peri_port = 0 *) input jtag_inst1_TCK,
  (* syn_peri_port = 0 *) input jtag_inst1_TDI,
  (* syn_peri_port = 0 *) input jtag_inst1_TMS,
  (* syn_peri_port = 0 *) input jtag_inst1_UPDATE,
  (* syn_peri_port = 0 *) input axi0_ARREADY,
  (* syn_peri_port = 0 *) input axi1_ARREADY,
  (* syn_peri_port = 0 *) input axi0_AWREADY,
  (* syn_peri_port = 0 *) input axi1_AWREADY,
  (* syn_peri_port = 0 *) input [5:0] axi0_BID,
  (* syn_peri_port = 0 *) input [5:0] axi1_BID,
  (* syn_peri_port = 0 *) input [1:0] axi0_BRESP,
  (* syn_peri_port = 0 *) input [1:0] axi1_BRESP,
  (* syn_peri_port = 0 *) input axi0_BVALID,
  (* syn_peri_port = 0 *) input axi1_BVALID,
  (* syn_peri_port = 0 *) input ddr_inst_CFG_DONE,
  (* syn_peri_port = 0 *) input [511:0] axi0_RDATA,
  (* syn_peri_port = 0 *) input [511:0] axi1_RDATA,
  (* syn_peri_port = 0 *) input [5:0] axi0_RID,
  (* syn_peri_port = 0 *) input [5:0] axi1_RID,
  (* syn_peri_port = 0 *) input axi0_RLAST,
  (* syn_peri_port = 0 *) input axi1_RLAST,
  (* syn_peri_port = 0 *) input [1:0] axi0_RRESP,
  (* syn_peri_port = 0 *) input [1:0] axi1_RRESP,
  (* syn_peri_port = 0 *) input axi0_RVALID,
  (* syn_peri_port = 0 *) input axi1_RVALID,
  (* syn_peri_port = 0 *) input axi0_WREADY,
  (* syn_peri_port = 0 *) input axi1_WREADY,
  (* syn_peri_port = 0 *) input S0_io_cam_scl_IN,
  (* syn_peri_port = 0 *) input S0_io_cam_sda_IN,
  (* syn_peri_port = 0 *) input S1_io_cam_scl_IN,
  (* syn_peri_port = 0 *) input S1_io_cam_sda_IN,
  (* syn_peri_port = 0 *) input clk_25m,
 
  (* syn_peri_port = 0 *) output sys_pll_rstn,
  (* syn_peri_port = 0 *) output ddr_pll_rstn,
  (* syn_peri_port = 0 *) output fb_pll_rstn,
  (* syn_peri_port = 0 *) output pll_byteclk_rstn,
  (* syn_peri_port = 0 *) output jtag_inst1_TDO,
  (* syn_peri_port = 0 *) output [32:0] axi0_ARADDR,
  (* syn_peri_port = 0 *) output [32:0] axi1_ARADDR,
  (* syn_peri_port = 0 *) output axi0_ARAPCMD,
  (* syn_peri_port = 0 *) output axi1_ARAPCMD,
  (* syn_peri_port = 0 *) output [1:0] axi0_ARBURST,
  (* syn_peri_port = 0 *) output [1:0] axi1_ARBURST,
  (* syn_peri_port = 0 *) output [5:0] axi0_ARID,
  (* syn_peri_port = 0 *) output [5:0] axi1_ARID,
  (* syn_peri_port = 0 *) output [7:0] axi0_ARLEN,
  (* syn_peri_port = 0 *) output [7:0] axi1_ARLEN,
  (* syn_peri_port = 0 *) output axi0_ARLOCK,
  (* syn_peri_port = 0 *) output axi1_ARLOCK,
  (* syn_peri_port = 0 *) output axi0_ARQOS,
  (* syn_peri_port = 0 *) output axi1_ARQOS,
  (* syn_peri_port = 0 *) output [2:0] axi0_ARSIZE,
  (* syn_peri_port = 0 *) output [2:0] axi1_ARSIZE,
  (* syn_peri_port = 0 *) output axi0_ARESETn,
  (* syn_peri_port = 0 *) output axi1_ARESETn,
  (* syn_peri_port = 0 *) output axi0_ARVALID,
  (* syn_peri_port = 0 *) output axi1_ARVALID,
  (* syn_peri_port = 0 *) output [32:0] axi0_AWADDR,
  (* syn_peri_port = 0 *) output [32:0] axi1_AWADDR,
  (* syn_peri_port = 0 *) output axi0_AWALLSTRB,
  (* syn_peri_port = 0 *) output axi1_AWALLSTRB,
  (* syn_peri_port = 0 *) output axi0_AWAPCMD,
  (* syn_peri_port = 0 *) output axi1_AWAPCMD,
  (* syn_peri_port = 0 *) output [1:0] axi0_AWBURST,
  (* syn_peri_port = 0 *) output [1:0] axi1_AWBURST,
  (* syn_peri_port = 0 *) output [3:0] axi0_AWCACHE,
  (* syn_peri_port = 0 *) output [3:0] axi1_AWCACHE,
  (* syn_peri_port = 0 *) output axi0_AWCOBUF,
  (* syn_peri_port = 0 *) output axi1_AWCOBUF,
  (* syn_peri_port = 0 *) output [5:0] axi0_AWID,
  (* syn_peri_port = 0 *) output [5:0] axi1_AWID,
  (* syn_peri_port = 0 *) output [7:0] axi0_AWLEN,
  (* syn_peri_port = 0 *) output [7:0] axi1_AWLEN,
  (* syn_peri_port = 0 *) output axi0_AWLOCK,
  (* syn_peri_port = 0 *) output axi1_AWLOCK,
  (* syn_peri_port = 0 *) output axi0_AWQOS,
  (* syn_peri_port = 0 *) output axi1_AWQOS,
  (* syn_peri_port = 0 *) output [2:0] axi0_AWSIZE,
  (* syn_peri_port = 0 *) output [2:0] axi1_AWSIZE,
  (* syn_peri_port = 0 *) output axi0_AWVALID,
  (* syn_peri_port = 0 *) output axi1_AWVALID,
  (* syn_peri_port = 0 *) output axi0_BREADY,
  (* syn_peri_port = 0 *) output axi1_BREADY,
  (* syn_peri_port = 0 *) output ddr_inst_CFG_RST,
  (* syn_peri_port = 0 *) output ddr_inst_CFG_SEL,
  (* syn_peri_port = 0 *) output ddr_inst_CFG_START,
  (* syn_peri_port = 0 *) output axi0_RREADY,
  (* syn_peri_port = 0 *) output axi1_RREADY,
  (* syn_peri_port = 0 *) output [511:0] axi0_WDATA,
  (* syn_peri_port = 0 *) output [511:0] axi1_WDATA,
  (* syn_peri_port = 0 *) output axi0_WLAST,
  (* syn_peri_port = 0 *) output axi1_WLAST,
  (* syn_peri_port = 0 *) output [63:0] axi0_WSTRB,
  (* syn_peri_port = 0 *) output [63:0] axi1_WSTRB,
  (* syn_peri_port = 0 *) output axi0_WVALID,
  (* syn_peri_port = 0 *) output axi1_WVALID,
  (* syn_peri_port = 0 *) output tmds_clk_TX_OE,
  (* syn_peri_port = 0 *) output [9:0] tmds_clk_TX_DATA,
  (* syn_peri_port = 0 *) output tmds_clk_TX_RST,
  (* syn_peri_port = 0 *) output tmds_data0_TX_OE,
  (* syn_peri_port = 0 *) output [9:0] tmds_data0_TX_DATA,
  (* syn_peri_port = 0 *) output tmds_data0_TX_RST,
  (* syn_peri_port = 0 *) output tmds_data1_TX_OE,
  (* syn_peri_port = 0 *) output [9:0] tmds_data1_TX_DATA,
  (* syn_peri_port = 0 *) output tmds_data1_TX_RST,
  (* syn_peri_port = 0 *) output tmds_data2_TX_OE,
  (* syn_peri_port = 0 *) output [9:0] tmds_data2_TX_DATA,
  (* syn_peri_port = 0 *) output tmds_data2_TX_RST,
  (* syn_peri_port = 0 *) output S0_io_cam_scl_OUT,
  (* syn_peri_port = 0 *) output S0_io_cam_scl_OE,
  (* syn_peri_port = 0 *) output S0_io_cam_sda_OUT,
  (* syn_peri_port = 0 *) output S0_io_cam_sda_OE,
  (* syn_peri_port = 0 *) output S0_o_cam_rst_p,
  (* syn_peri_port = 0 *) output S1_io_cam_scl_OUT,
  (* syn_peri_port = 0 *) output S1_io_cam_scl_OE,
  (* syn_peri_port = 0 *) output S1_io_cam_sda_OUT,
  (* syn_peri_port = 0 *) output S1_io_cam_sda_OE,
  (* syn_peri_port = 0 *) output S1_o_cam_rst_p,
  // Board LEDs and dual UART ports are currently held idle later in the file.
  (* syn_peri_port = 0 *) output [19:0] led,  // 扩展到20个LED (LED12,13,16-33)
  // UART双串口
  (* syn_peri_port = 0 *) input  uart1_rxd,   // UART1 RX (从PC接收)
  (* syn_peri_port = 0 *) output uart1_txd,   // UART1 TX (发送到PC)
  (* syn_peri_port = 0 *) input  uart2_rxd,   // UART2 RX (从外设接收)
  (* syn_peri_port = 0 *) output uart2_txd,   // UART2 TX (发送到外设)
  //mipi rx
  (* syn_peri_port = 0 *) output mipi_rx_ck0_HS_ENA,
  (* syn_peri_port = 0 *) output mipi_rx_dp00_HS_ENA,
  (* syn_peri_port = 0 *) output mipi_rx_dp01_HS_ENA,
  (* syn_peri_port = 0 *) output mipi_rx_dp02_HS_ENA,
  (* syn_peri_port = 0 *) output mipi_rx_dp03_HS_ENA,

  (* syn_peri_port = 0 *) output mipi_rx_ck0_HS_TERM,
  (* syn_peri_port = 0 *) output mipi_rx_dp00_HS_TERM,
  (* syn_peri_port = 0 *) output mipi_rx_dp01_HS_TERM,
  (* syn_peri_port = 0 *) output mipi_rx_dp02_HS_TERM,
  (* syn_peri_port = 0 *) output mipi_rx_dp03_HS_TERM,
  
  
  (* syn_peri_port = 0 *) output mipi_rx_dp00_RST,
  (* syn_peri_port = 0 *) output mipi_rx_dp01_RST,
  (* syn_peri_port = 0 *) output mipi_rx_dp02_RST,
  (* syn_peri_port = 0 *) output mipi_rx_dp03_RST,


  (* syn_peri_port = 0 *) output mipi_rx_ck1_HS_ENA,
  (* syn_peri_port = 0 *) output mipi_rx_dp10_HS_ENA,
  (* syn_peri_port = 0 *) output mipi_rx_dp11_HS_ENA,
  (* syn_peri_port = 0 *) output mipi_rx_dp12_HS_ENA,
  (* syn_peri_port = 0 *) output mipi_rx_dp13_HS_ENA,

  (* syn_peri_port = 0 *) output mipi_rx_ck1_HS_TERM,
  (* syn_peri_port = 0 *) output mipi_rx_dp10_HS_TERM,
  (* syn_peri_port = 0 *) output mipi_rx_dp11_HS_TERM,
  (* syn_peri_port = 0 *) output mipi_rx_dp12_HS_TERM,
  (* syn_peri_port = 0 *) output mipi_rx_dp13_HS_TERM,
  
  
  (* syn_peri_port = 0 *) output mipi_rx_dp10_RST,
  (* syn_peri_port = 0 *) output mipi_rx_dp11_RST,
  (* syn_peri_port = 0 *) output mipi_rx_dp12_RST,
  (* syn_peri_port = 0 *) output mipi_rx_dp13_RST,

  (* syn_peri_port = 0 *) input mipi_rx_ck0_LP_N_IN,
  (* syn_peri_port = 0 *) input mipi_rx_ck0_LP_P_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp00_LP_N_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp00_LP_P_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp01_LP_N_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp01_LP_P_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp02_LP_N_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp02_LP_P_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp03_LP_N_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp03_LP_P_IN,

  (* syn_peri_port = 0 *) input [7:0] mipi_rx_dp00_HS_IN,
  (* syn_peri_port = 0 *) input [7:0] mipi_rx_dp01_HS_IN,
  (* syn_peri_port = 0 *) input [7:0] mipi_rx_dp02_HS_IN,
  (* syn_peri_port = 0 *) input [7:0] mipi_rx_dp03_HS_IN,

  (* syn_peri_port = 0 *) output mipi_rx_dp00_FIFO_RD,
  (* syn_peri_port = 0 *) output mipi_rx_dp01_FIFO_RD,
  (* syn_peri_port = 0 *) output mipi_rx_dp02_FIFO_RD,
  (* syn_peri_port = 0 *) output mipi_rx_dp03_FIFO_RD,
  (* syn_peri_port = 0 *) input mipi_rx_dp00_FIFO_EMPTY,
  (* syn_peri_port = 0 *) input mipi_rx_dp01_FIFO_EMPTY,
  (* syn_peri_port = 0 *) input mipi_rx_dp02_FIFO_EMPTY,
  (* syn_peri_port = 0 *) input mipi_rx_dp03_FIFO_EMPTY,

    (* syn_peri_port = 0 *) input [7:0] mipi_rx_dp10_HS_IN,
  (* syn_peri_port = 0 *) input [7:0] mipi_rx_dp11_HS_IN,
  (* syn_peri_port = 0 *) input [7:0] mipi_rx_dp12_HS_IN,
  (* syn_peri_port = 0 *) input [7:0] mipi_rx_dp13_HS_IN,

  (* syn_peri_port = 0 *) input mipi_rx_ck1_LP_N_IN,
  (* syn_peri_port = 0 *) input mipi_rx_ck1_LP_P_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp10_LP_N_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp10_LP_P_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp11_LP_N_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp11_LP_P_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp12_LP_N_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp12_LP_P_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp13_LP_N_IN,
  (* syn_peri_port = 0 *) input mipi_rx_dp13_LP_P_IN,



  (* syn_peri_port = 0 *) output mipi_rx_dp10_FIFO_RD,
  (* syn_peri_port = 0 *) output mipi_rx_dp11_FIFO_RD,
  (* syn_peri_port = 0 *) output mipi_rx_dp12_FIFO_RD,
  (* syn_peri_port = 0 *) output mipi_rx_dp13_FIFO_RD,
  (* syn_peri_port = 0 *) input mipi_rx_dp10_FIFO_EMPTY,
  (* syn_peri_port = 0 *) input mipi_rx_dp11_FIFO_EMPTY,
  (* syn_peri_port = 0 *) input mipi_rx_dp12_FIFO_EMPTY,
  (* syn_peri_port = 0 *) input mipi_rx_dp13_FIFO_EMPTY

);



/////////////////////////////////////////////////////////////////////////////
// Internal logic is arranged in these blocks:
// 1. DDR/AXI reset and frame-buffer wiring.
// 2. Camera RGB pixel analysis for color and shape recognition.
// 3. Cross-clock transfer from camera clock to HDMI clock.
// 4. HDMI result page generation.

wire        arst_n;
wire        sys_rst_n;
wire        ddr_cfg_ok;


// AXI wires connect frame_buffer to the external DDR AXI port. Only one
// frame-buffer master is enabled now, but the bus vectors keep the mux-style
// structure so more channels can be restored later.
// Slave Interface Write Address Ports
wire [AXI_ID_WIDTH-1:0]           s_axi_awid;
wire [AXI_ADDR_WIDTH-1:0]         s_axi_awaddr;
wire [7:0]                        s_axi_awlen;
wire [2:0]                        s_axi_awsize;
wire [1:0]                        s_axi_awburst;
wire [0:0]                        s_axi_awlock;
wire [3:0]                        s_axi_awcache;
wire [2:0]                        s_axi_awprot;
wire                              s_axi_awvalid;
wire                              s_axi_awready;
// Slave Interface Write Data Ports
wire [AXI_DATA_WIDTH-1:0]         s_axi_wdata;
wire [(AXI_DATA_WIDTH/8)-1:0]     s_axi_wstrb;
wire                              s_axi_wlast;
wire                              s_axi_wvalid;
wire                              s_axi_wready;
// Slave Interface Write Response Ports
wire                              s_axi_bready;
wire [AXI_ID_WIDTH-1:0]           s_axi_bid;
wire [1:0]                        s_axi_bresp;
wire                              s_axi_bvalid;
// Slave Interface Read Address Ports
wire [AXI_ID_WIDTH-1:0]           s_axi_arid;
wire [AXI_ADDR_WIDTH-1:0]         s_axi_araddr;
wire [7:0]                        s_axi_arlen;
wire [2:0]                        s_axi_arsize;
wire [1:0]                        s_axi_arburst;
wire [0:0]                        s_axi_arlock;
wire [3:0]                        s_axi_arcache;
wire [2:0]                        s_axi_arprot;
wire                              s_axi_arvalid;
wire                              s_axi_arready;
// Slave Interface Read Data Ports
wire                              s_axi_rready;
wire [AXI_ID_WIDTH-1:0]           s_axi_rid;
wire [AXI_DATA_WIDTH-1:0]         s_axi_rdata;
wire [1:0]                        s_axi_rresp;
wire                              s_axi_rlast;
wire                              s_axi_rvalid;

  wire    [S_COUNT*AXI_ID_WIDTH-1:0]  axi_m_awid;        //
  wire    [S_COUNT*AXI_ADDR_WIDTH-1:0]axi_m_awaddr;
  wire    [S_COUNT*8-1:0]         		axi_m_awlen;
  wire    [S_COUNT*3-1:0]         		axi_m_awsize;
  wire    [S_COUNT*2-1:0]         		axi_m_awburst;
  wire    [S_COUNT-1:0]           		axi_m_awlock;
  wire    [S_COUNT*4-1:0]         		axi_m_awcache;
  wire    [S_COUNT*3-1:0]         		axi_m_awprot;
  wire    [S_COUNT-1:0]           		axi_m_awvalid;
  wire    [S_COUNT-1:0]           		axi_m_awready;
  wire		[S_COUNT*AXI_ID_WIDTH-1:0]	axi_m_wid;
  wire    [S_COUNT*AXI_DATA_WIDTH-1:0]  axi_m_wdata;
  wire    [S_COUNT*(AXI_DATA_WIDTH/8)-1:0]  axi_m_wstrb;
  wire    [S_COUNT-1:0]           		axi_m_wlast;
  wire    [S_COUNT-1:0]           		axi_m_wvalid;
  wire    [S_COUNT-1:0]           		axi_m_wready;
  wire    [S_COUNT*AXI_ID_WIDTH-1:0]  axi_m_bid;
  wire    [S_COUNT*2-1:0]         		axi_m_bresp;
  wire    [S_COUNT-1:0]           		axi_m_bvalid;
  wire    [S_COUNT-1:0]           		axi_m_bready;
  wire    [S_COUNT*AXI_ID_WIDTH-1:0]  axi_m_arid;
  wire    [S_COUNT*AXI_ADDR_WIDTH-1:0]axi_m_araddr;
  wire    [S_COUNT*8-1:0]         		axi_m_arlen;
  wire    [S_COUNT*3-1:0]         		axi_m_arsize;
  wire    [S_COUNT*2-1:0]         		axi_m_arburst;
  wire    [S_COUNT-1:0]           		axi_m_arlock;
  wire    [S_COUNT-1:0]           		axi_m_arvalid;
  wire    [S_COUNT-1:0]           		axi_m_arready;
  wire    [S_COUNT*AXI_ID_WIDTH-1:0]  axi_m_rid;
  wire    [S_COUNT*AXI_DATA_WIDTH-1:0]axi_m_rdata;
  wire    [S_COUNT*2-1:0]         		axi_m_rresp;
  wire    [S_COUNT-1:0]           		axi_m_rlast;
  wire    [S_COUNT-1:0]           		axi_m_rvalid;
  wire    [S_COUNT-1:0]          			axi_m_rready;// 
  reg  out_sync;
//=========================================================================
//signal define
//=========================================================================

/////////////////////////////////////////////////////////////////////////////
// Reset, PLL release, and DDR configuration live in a small startup module.
system_startup_ctrl u_system_startup_ctrl (
    .clk(i_fb_clk),
    .manual_enable(i_sw[0]),
    .sys_pll_lock(sys_pll_lock),
    .ddr_pll_lock(ddr_pll_lock),
    .pll_byteclk_locked(pll_byteclk_locked),
    .fb_pll_locked(fb_pll_locked),
    .ddr_cfg_done(ddr_inst_CFG_DONE),
    .sys_pll_rstn(sys_pll_rstn),
    .ddr_pll_rstn(ddr_pll_rstn),
    .fb_pll_rstn(fb_pll_rstn),
    .pll_byteclk_rstn(pll_byteclk_rstn),
    .arst_n(arst_n),
    .sys_rst_n(sys_rst_n),
    .ddr_cfg_ok(ddr_cfg_ok),
    .ddr_cfg_start(ddr_inst_CFG_START),
    .ddr_cfg_rst(ddr_inst_CFG_RST),
    .ddr_cfg_sel(ddr_inst_CFG_SEL),
    .axi0_aresetn(axi0_ARESETn),
    .axi1_aresetn(axi1_ARESETn)
);

`ifndef T35_RESOURCE_TRIM
(* syn_keep = "true", syn_preserve = "true", mark_debug = "true" *) reg [31:0] dbg_system_startup_sticky = 32'd0;
reg [15:0] dbg_system_startup_sample_d = 16'd0;
reg dbg_system_startup_sample_valid = 1'b0;
wire [15:0] dbg_system_startup_sample = {
    1'b0,
    i_sw[0],
    axi0_ARESETn,
    ddr_cfg_ok,
    sys_rst_n,
    arst_n,
    pll_byteclk_rstn,
    fb_pll_rstn,
    ddr_pll_rstn,
    sys_pll_rstn,
    ddr_inst_CFG_DONE,
    hdmi_pll_locked,
    pll_byteclk_locked,
    fb_pll_locked,
    ddr_pll_lock,
    sys_pll_lock
};
wire dbg_system_startup_any_input_change =
    dbg_system_startup_sample_valid &&
    (dbg_system_startup_sample[5:0] != dbg_system_startup_sample_d[5:0]);
wire dbg_system_startup_any_output_change =
    dbg_system_startup_sample_valid &&
    (dbg_system_startup_sample[13:6] != dbg_system_startup_sample_d[13:6]);

// Sticky debug bits for startup-only signals. Pull i_sw[0] low to clear.
always @(posedge i_fb_clk or negedge i_sw[0]) begin
    if (!i_sw[0]) begin
        dbg_system_startup_sticky <= 32'd0;
        dbg_system_startup_sample_d <= 16'd0;
        dbg_system_startup_sample_valid <= 1'b0;
    end else begin
        dbg_system_startup_sticky[0]  <= dbg_system_startup_sticky[0]  | sys_pll_lock;
        dbg_system_startup_sticky[1]  <= dbg_system_startup_sticky[1]  | ddr_pll_lock;
        dbg_system_startup_sticky[2]  <= dbg_system_startup_sticky[2]  | fb_pll_locked;
        dbg_system_startup_sticky[3]  <= dbg_system_startup_sticky[3]  | pll_byteclk_locked;
        dbg_system_startup_sticky[4]  <= dbg_system_startup_sticky[4]  | hdmi_pll_locked;
        dbg_system_startup_sticky[5]  <= dbg_system_startup_sticky[5]  | ddr_inst_CFG_DONE;
        dbg_system_startup_sticky[6]  <= dbg_system_startup_sticky[6]  | sys_pll_rstn;
        dbg_system_startup_sticky[7]  <= dbg_system_startup_sticky[7]  | ddr_pll_rstn;
        dbg_system_startup_sticky[8]  <= dbg_system_startup_sticky[8]  | fb_pll_rstn;
        dbg_system_startup_sticky[9]  <= dbg_system_startup_sticky[9]  | pll_byteclk_rstn;
        dbg_system_startup_sticky[10] <= dbg_system_startup_sticky[10] | arst_n;
        dbg_system_startup_sticky[11] <= dbg_system_startup_sticky[11] | sys_rst_n;
        dbg_system_startup_sticky[12] <= dbg_system_startup_sticky[12] | ddr_cfg_ok;
        dbg_system_startup_sticky[13] <= dbg_system_startup_sticky[13] | axi0_ARESETn;
        dbg_system_startup_sticky[14] <= dbg_system_startup_sticky[14] | dbg_system_startup_any_input_change;
        dbg_system_startup_sticky[15] <= dbg_system_startup_sticky[15] | dbg_system_startup_any_output_change;
        dbg_system_startup_sample_d <= dbg_system_startup_sample;
        dbg_system_startup_sample_valid <= 1'b1;
    end
end
`endif

wire [2:0] color_id_cam;
wire color_valid_cam;
wire [2:0] fast_color_id_cam;
wire fast_color_valid_cam;
wire        rgb_vs;
wire        rgb_hs;
wire        rgb_de;
wire        rgb_valid;
wire [47:0] rgb_datax2;

// Shape recognition core outputs. The core owns the camera-domain scanner,
// frame statistics, background/preview RAMs, and shape-page control.
wire [2:0] shape_id_cam;
wire shape_valid_cam;
wire [2:0] shape_display_id_cam;
wire shape_display_valid_cam;
wire shape_page_cam;
wire shape_bg_learn_cam;
wire shape_bg_valid_cam;
wire [7:0] shape_preview_gray_hdmi;
wire [7:0] shape_contour_left_hdmi;
wire [7:0] shape_contour_right_hdmi;
wire [7:0] shape_fg_contour_left_hdmi;
wire [7:0] shape_fg_contour_right_hdmi;
wire shape_bg_valid_hdmi;
wire shape_bg_learn_hdmi;
// Camera/RGB-domain result values are transferred into HDMI as one coherent
// snapshot through a toggle/ack CDC bridge. This avoids sampling related
// multi-bit fields on different HDMI cycles.
localparam RESULT_CDC_WIDTH = 112;
wire result_cdc_src_ready;
wire result_cdc_update_cam;
wire result_cdc_pulse_hdmi;
wire [RESULT_CDC_WIDTH-1:0] result_cdc_data_cam;
wire [RESULT_CDC_WIDTH-1:0] result_cdc_data_hdmi;
reg [2:0] color_id_hdmi;
reg color_valid_hdmi;
reg [2:0] shape_id_hdmi;
reg shape_valid_hdmi;
reg [2:0] shape_display_id_hdmi_reg;
reg shape_display_valid_hdmi_reg;
reg timer_running_hdmi;
reg timer_result_valid_hdmi;
reg [23:0] timer_elapsed_us_hdmi;
reg [23:0] timer_live_us_hdmi;
reg [23:0] timer_display_hold_us_hdmi;
reg [2:0] timer_display_color_id_hdmi;
reg shape_timer_running_hdmi;
reg shape_timer_result_valid_hdmi;
reg [23:0] shape_timer_elapsed_us_hdmi;
reg [23:0] shape_timer_live_us_hdmi;
reg [23:0] shape_timer_display_hold_us_hdmi;
reg [2:0] shape_latency_display_id_hdmi;
reg shape_latency_display_valid_hdmi;
reg [23:0] shape_latency_display_us_hdmi;
// Recognition IDs and ROI geometry.
// The ROI constants are in the 1920x1080 camera coordinate system. The preview
// constants are the same regions mapped into the smaller 160x120 debug image.
localparam [2:0] COLOR_UNKNOWN = 3'd0;
localparam [2:0] COLOR_BLACK   = 3'd1;
localparam [2:0] COLOR_WHITE   = 3'd2;
localparam [2:0] COLOR_RED     = 3'd3;
localparam [2:0] COLOR_BLUE    = 3'd4;
localparam [2:0] COLOR_YELLOW  = 3'd5;
localparam [2:0] SHAPE_UNKNOWN  = 3'd0;
localparam [2:0] SHAPE_CUBE     = 3'd1;
localparam [2:0] SHAPE_CYLINDER = 3'd2;
localparam [2:0] SHAPE_CONE     = 3'd3;

localparam [11:0] COLOR_ROI_X_START = 12'd880;
localparam [11:0] COLOR_ROI_X_END   = 12'd1040;
localparam [10:0] COLOR_ROI_Y_START = 11'd480;
localparam [10:0] COLOR_ROI_Y_END   = 11'd600;
// UI-facing middle-speed color path: faster than frame-end stability, but
// wider and stricter than the ultra-fast ROI to reduce flicker.
localparam [11:0] FAST_COLOR_ROI_X_START = 12'd880;
localparam [11:0] FAST_COLOR_ROI_X_END   = 12'd1040;
localparam [10:0] FAST_COLOR_ROI_Y_START = 11'd480;
localparam [10:0] FAST_COLOR_ROI_Y_END   = 11'd600;
localparam [11:0] SHAPE_ROI_X_START = 12'd492;
localparam [11:0] SHAPE_ROI_X_END   = 12'd1428;
localparam [10:0] SHAPE_ROI_Y_START = 11'd212;
localparam [10:0] SHAPE_ROI_Y_END   = 11'd868;
localparam [9:0] SHAPE_CENTER_X = 10'd468;
localparam [9:0] SHAPE_CENTER_LEFT_MIN = 10'd40;
localparam [9:0] SHAPE_CENTER_RIGHT_MAX = 10'd896;
localparam [9:0] SHAPE_CENTER_GAP = 10'd24;
localparam [9:0] SHAPE_CENTER_MIN_ROW_WIDTH = 10'd80;
localparam [9:0] SHAPE_INNER_SAMPLE_LEFT_X = 10'd372;
localparam [9:0] SHAPE_INNER_SAMPLE_MID_X = 10'd468;
localparam [9:0] SHAPE_INNER_SAMPLE_RIGHT_X = 10'd564;
localparam [1:0] SHAPE_SEG_GAP_MAX = 2'd2;
localparam [17:0] VOTE_MIN_COUNT = 18'd96;
localparam [17:0] VOTE_MARGIN    = 18'd32;
localparam [17:0] FAST_VOTE_MIN_COUNT = 18'd96;
localparam [17:0] FAST_VOTE_MARGIN    = 18'd32;
localparam [3:0] FAST_LOCK_LINE_STREAK_NEW = 4'd8;
localparam [3:0] FAST_LOCK_LINE_STREAK_SWITCH = 4'd8;
localparam [7:0] SHAPE_EDGE_H_THRESH = 8'd9;
localparam [7:0] SHAPE_EDGE_V_THRESH = 8'd5;
localparam [9:0] SHAPE_MIN_ROW_WIDTH = 10'd16;
localparam [7:0] SHAPE_MIN_VALID_ROWS = 8'd10;
localparam [9:0] SHAPE_MIN_BBOX_W = 10'd18;
localparam [7:0] SHAPE_MIN_BBOX_H = 8'd18;
localparam [5:0] SHAPE_BG_RGB_DIFF_THRESH = 6'd6;
localparam [5:0] SHAPE_SHADOW_DROP_MIN = 6'd6;
localparam [5:0] SHAPE_SHADOW_DROP_MAX = 6'd18;
localparam [3:0] SHAPE_SHADOW_BALANCE_MAX = 4'd3;
localparam [5:0] SHAPE_SHADOW_CUR_SUM_MIN = 6'd10;
localparam [4:0] SHAPE_BG_LEARN_FRAMES = 5'd12;
localparam [20:0] SHAPE_PAGE_BTN_DEBOUNCE_MAX = 21'd1399999;
localparam [23:0] COLOR_TIMER_MAX_US = 24'd1000000;
localparam [23:0] COLOR_TIMER_DISPLAY_MAX_US = 24'd999999;
localparam [7:0] SHAPE_PREVIEW_W = 8'd160;
localparam [6:0] SHAPE_PREVIEW_H = 7'd120;
localparam [7:0] SHAPE_ROI_PREVIEW_X_START = 8'd41;
localparam [7:0] SHAPE_ROI_PREVIEW_X_END   = 8'd118;
localparam [6:0] SHAPE_ROI_PREVIEW_Y_START = 7'd24;
localparam [6:0] SHAPE_ROI_PREVIEW_Y_END   = 7'd96;
localparam [7:0] SHAPE_FG_GRID_X1 = 8'd67;
localparam [7:0] SHAPE_FG_GRID_X2 = 8'd93;
localparam [6:0] SHAPE_FG_GRID_Y1 = 7'd48;
localparam [6:0] SHAPE_FG_GRID_Y2 = 7'd72;
localparam [7:0] SHAPE_FG_COL_LEFT_X  = 8'd60;
localparam [7:0] SHAPE_FG_COL_MID_X   = 8'd80;
localparam [7:0] SHAPE_FG_COL_RIGHT_X = 8'd100;
localparam [1:0] SHAPE_FG_RUN_GAP_MAX = 2'd1;
localparam [7:0] SHAPE_WIDTH5_CYL_MIN  = 8'd8;
localparam [7:0] SHAPE_WIDTH5_CUBE_MIN = 8'd18;
localparam [7:0] SHAPE_WIDTH5_VALID_MAX = 8'd40;
localparam [7:0] SHAPE_WIDTH_RANGE_MAX = 8'd75;
localparam [12:0] SHAPE_MIN_FG_PIXELS = 13'd96;
localparam [7:0] SHAPE_MOTION_WIDTH5_DELTA = 8'd6;
localparam [7:0] SHAPE_MOTION_BBOX_DELTA = 8'd14;
localparam [7:0] SHAPE_MOTION_ROWS_DELTA = 8'd10;
localparam [12:0] SHAPE_MOTION_PIXELS_DELTA = 13'd450;

wire [2:0] shape_display_id_hdmi;

wire color_timer_start_cam_pulse;
wire color_timer_stop_cam_pulse;
wire color_timer_cancel_cam_pulse;
wire fast_color_timer_start_cam_pulse;
wire fast_color_timer_stop_cam_pulse;
wire fast_color_timer_cancel_cam_pulse;
wire timer_running_cam;
wire timer_done_cam;
wire timer_result_valid_cam;
wire [23:0] timer_elapsed_us_cam;
wire [23:0] timer_live_us_cam;
wire fast_timer_running_cam;
wire fast_timer_done_cam;
wire fast_timer_result_valid_cam;
wire [23:0] fast_timer_elapsed_us_cam;
wire [23:0] fast_timer_live_us_cam;
wire color_latency_known_hdmi;
wire timer_display_active_hdmi;
wire [23:0] timer_display_us_hdmi;
wire [23:0] timer_display_us_hdmi_clamped;
wire shape_timer_start_cam_pulse;
wire shape_timer_stop_cam_pulse;
wire shape_timer_cancel_cam_pulse;
wire shape_timer_running_cam;
wire shape_timer_done_cam;
wire shape_timer_result_valid_cam;
wire [23:0] shape_timer_elapsed_us_cam;
wire [23:0] shape_timer_live_us_cam;
wire [23:0] shape_latency_display_us_hdmi_clamped;
wire shape_latency_sample_valid_hdmi;
wire [23:0] shape_latency_sample_us_hdmi;
wire shape_preview_ui_active;
wire [7:0] shape_preview_ui_x;
wire [6:0] shape_preview_ui_y;

assign result_cdc_data_cam = {
    shape_timer_live_us_cam,
    shape_timer_elapsed_us_cam,
    shape_timer_result_valid_cam,
    shape_timer_running_cam,
    fast_timer_live_us_cam,
    fast_timer_elapsed_us_cam,
    fast_timer_result_valid_cam,
    fast_timer_running_cam,
    shape_display_valid_cam,
    shape_display_id_cam,
    shape_valid_cam,
    shape_id_cam,
    fast_color_valid_cam,
    fast_color_id_cam
};
assign result_cdc_update_cam = result_cdc_src_ready;

cdc_bus_handshake #(
    .WIDTH(RESULT_CDC_WIDTH)
) u_result_cdc (
    .src_clk(i_sysclk_div2),
    .src_rst_n(arst_n),
    .src_update(result_cdc_update_cam),
    .src_data(result_cdc_data_cam),
    .src_ready(result_cdc_src_ready),
    .dst_clk(hdmi_tx_slow_clk),
    .dst_rst_n(sys_rst_n),
    .dst_pulse(result_cdc_pulse_hdmi),
    .dst_data(result_cdc_data_hdmi)
);

shape_recognition_core #(
    .VACT(VACT),
    .SHAPE_UNKNOWN(SHAPE_UNKNOWN),
    .SHAPE_CUBE(SHAPE_CUBE),
    .SHAPE_CYLINDER(SHAPE_CYLINDER),
    .SHAPE_CONE(SHAPE_CONE),
    .SHAPE_ROI_X_START(SHAPE_ROI_X_START),
    .SHAPE_ROI_X_END(SHAPE_ROI_X_END),
    .SHAPE_ROI_Y_START(SHAPE_ROI_Y_START),
    .SHAPE_ROI_Y_END(SHAPE_ROI_Y_END),
    .SHAPE_CENTER_X(SHAPE_CENTER_X),
    .SHAPE_CENTER_LEFT_MIN(SHAPE_CENTER_LEFT_MIN),
    .SHAPE_CENTER_RIGHT_MAX(SHAPE_CENTER_RIGHT_MAX),
    .SHAPE_CENTER_GAP(SHAPE_CENTER_GAP),
    .SHAPE_CENTER_MIN_ROW_WIDTH(SHAPE_CENTER_MIN_ROW_WIDTH),
    .SHAPE_INNER_SAMPLE_LEFT_X(SHAPE_INNER_SAMPLE_LEFT_X),
    .SHAPE_INNER_SAMPLE_MID_X(SHAPE_INNER_SAMPLE_MID_X),
    .SHAPE_INNER_SAMPLE_RIGHT_X(SHAPE_INNER_SAMPLE_RIGHT_X),
    .SHAPE_SEG_GAP_MAX(SHAPE_SEG_GAP_MAX),
    .SHAPE_EDGE_H_THRESH(SHAPE_EDGE_H_THRESH),
    .SHAPE_EDGE_V_THRESH(SHAPE_EDGE_V_THRESH),
    .SHAPE_MIN_ROW_WIDTH(SHAPE_MIN_ROW_WIDTH),
    .SHAPE_MIN_VALID_ROWS(SHAPE_MIN_VALID_ROWS),
    .SHAPE_MIN_BBOX_W(SHAPE_MIN_BBOX_W),
    .SHAPE_MIN_BBOX_H(SHAPE_MIN_BBOX_H),
    .SHAPE_BG_RGB_DIFF_THRESH(SHAPE_BG_RGB_DIFF_THRESH),
    .SHAPE_SHADOW_DROP_MIN(SHAPE_SHADOW_DROP_MIN),
    .SHAPE_SHADOW_DROP_MAX(SHAPE_SHADOW_DROP_MAX),
    .SHAPE_SHADOW_BALANCE_MAX(SHAPE_SHADOW_BALANCE_MAX),
    .SHAPE_SHADOW_CUR_SUM_MIN(SHAPE_SHADOW_CUR_SUM_MIN),
    .SHAPE_BG_LEARN_FRAMES(SHAPE_BG_LEARN_FRAMES),
    .SHAPE_PAGE_BTN_DEBOUNCE_MAX(SHAPE_PAGE_BTN_DEBOUNCE_MAX),
    .SHAPE_PREVIEW_W(SHAPE_PREVIEW_W),
    .SHAPE_PREVIEW_H(SHAPE_PREVIEW_H),
    .SHAPE_ROI_PREVIEW_X_START(SHAPE_ROI_PREVIEW_X_START),
    .SHAPE_ROI_PREVIEW_X_END(SHAPE_ROI_PREVIEW_X_END),
    .SHAPE_ROI_PREVIEW_Y_START(SHAPE_ROI_PREVIEW_Y_START),
    .SHAPE_ROI_PREVIEW_Y_END(SHAPE_ROI_PREVIEW_Y_END),
    .SHAPE_FG_GRID_X1(SHAPE_FG_GRID_X1),
    .SHAPE_FG_GRID_X2(SHAPE_FG_GRID_X2),
    .SHAPE_FG_GRID_Y1(SHAPE_FG_GRID_Y1),
    .SHAPE_FG_GRID_Y2(SHAPE_FG_GRID_Y2),
    .SHAPE_FG_COL_LEFT_X(SHAPE_FG_COL_LEFT_X),
    .SHAPE_FG_COL_MID_X(SHAPE_FG_COL_MID_X),
    .SHAPE_FG_COL_RIGHT_X(SHAPE_FG_COL_RIGHT_X),
    .SHAPE_FG_RUN_GAP_MAX(SHAPE_FG_RUN_GAP_MAX),
    .SHAPE_WIDTH5_CYL_MIN(SHAPE_WIDTH5_CYL_MIN),
    .SHAPE_WIDTH5_CUBE_MIN(SHAPE_WIDTH5_CUBE_MIN),
    .SHAPE_WIDTH5_VALID_MAX(SHAPE_WIDTH5_VALID_MAX),
    .SHAPE_WIDTH_RANGE_MAX(SHAPE_WIDTH_RANGE_MAX),
    .SHAPE_MIN_FG_PIXELS(SHAPE_MIN_FG_PIXELS),
    .SHAPE_MOTION_WIDTH5_DELTA(SHAPE_MOTION_WIDTH5_DELTA),
    .SHAPE_MOTION_BBOX_DELTA(SHAPE_MOTION_BBOX_DELTA),
    .SHAPE_MOTION_ROWS_DELTA(SHAPE_MOTION_ROWS_DELTA),
    .SHAPE_MOTION_PIXELS_DELTA(SHAPE_MOTION_PIXELS_DELTA),
    .ENABLE_HDMI_PREVIEW(1'b0)
) u_shape_recognition_core (
    .clk(i_sysclk_div2),
    .rst_n(arst_n),
    .rgb_vs(rgb_vs),
    .rgb_de(rgb_de),
    .rgb_datax2(rgb_datax2),
    .shape_page_button(i_sw[1]),
    .shape_timer_running(shape_timer_running_cam),
    .hdmi_clk(hdmi_tx_slow_clk),
    .hdmi_rst_n(sys_rst_n),
    .shape_preview_ui_active(shape_preview_ui_active),
    .shape_preview_ui_x(shape_preview_ui_x),
    .shape_preview_ui_y(shape_preview_ui_y),
    .shape_id_cam(shape_id_cam),
    .shape_valid_cam(shape_valid_cam),
    .shape_display_id_cam(shape_display_id_cam),
    .shape_display_valid_cam(shape_display_valid_cam),
    .shape_page_cam(shape_page_cam),
    .shape_bg_learn_cam(shape_bg_learn_cam),
    .shape_bg_valid_cam(shape_bg_valid_cam),
    .shape_timer_start_cam_pulse(shape_timer_start_cam_pulse),
    .shape_timer_stop_cam_pulse(shape_timer_stop_cam_pulse),
    .shape_timer_cancel_cam_pulse(shape_timer_cancel_cam_pulse),
    .shape_preview_gray_hdmi(shape_preview_gray_hdmi),
    .shape_contour_left_hdmi(shape_contour_left_hdmi),
    .shape_contour_right_hdmi(shape_contour_right_hdmi),
    .shape_fg_contour_left_hdmi(shape_fg_contour_left_hdmi),
    .shape_fg_contour_right_hdmi(shape_fg_contour_right_hdmi),
    .shape_bg_valid_hdmi(shape_bg_valid_hdmi),
    .shape_bg_learn_hdmi(shape_bg_learn_hdmi)
);
assign shape_display_id_hdmi =
    shape_display_valid_hdmi_reg ? shape_display_id_hdmi_reg : SHAPE_UNKNOWN;

// Color latency display consumes the detector result synchronized into HDMI.
assign color_latency_known_hdmi = color_valid_hdmi && (color_id_hdmi != COLOR_UNKNOWN);
assign timer_display_active_hdmi = color_latency_known_hdmi;
assign timer_display_us_hdmi =
    color_latency_known_hdmi ? timer_display_hold_us_hdmi : 24'd0;
assign timer_display_us_hdmi_clamped =
    (timer_display_us_hdmi > COLOR_TIMER_DISPLAY_MAX_US) ?
    COLOR_TIMER_DISPLAY_MAX_US : timer_display_us_hdmi;
assign shape_latency_sample_valid_hdmi =
    (shape_timer_display_hold_us_hdmi != 24'd0) ||
    shape_timer_result_valid_hdmi ||
    (shape_timer_running_hdmi && (shape_timer_live_us_hdmi != 24'd0));
assign shape_latency_sample_us_hdmi =
    (shape_timer_display_hold_us_hdmi != 24'd0) ? shape_timer_display_hold_us_hdmi :
    shape_timer_result_valid_hdmi ? shape_timer_elapsed_us_hdmi :
    (shape_timer_running_hdmi ? shape_timer_live_us_hdmi : 24'd0);
assign shape_latency_display_us_hdmi_clamped =
    (shape_latency_display_us_hdmi > COLOR_TIMER_DISPLAY_MAX_US) ?
    COLOR_TIMER_DISPLAY_MAX_US : shape_latency_display_us_hdmi;

// First T35 migration result gate: only a valid cube can request sorting.
// Other recognized shapes remain valid internally but are rejected here.
wire color_sort_match_cam = fast_color_valid_cam && (fast_color_id_cam != COLOR_UNKNOWN);
wire shape_cube_match_cam = shape_valid_cam && (shape_id_cam == SHAPE_CUBE);
wire shape_reject_match_cam = shape_valid_cam && (shape_id_cam != SHAPE_CUBE);
wire competition_sort_enable_cam = color_sort_match_cam && shape_cube_match_cam;
wire [19:0] recognition_led_status = {
    {12{1'b1}},
    ~shape_reject_match_cam,
    ~competition_sort_enable_cam,
    ~shape_cube_match_cam,
    ~color_sort_match_cam,
    shape_reject_match_cam,
    competition_sort_enable_cam,
    shape_cube_match_cam,
    color_sort_match_cam
};

// LED status is used as the first migration-visible sort/debug result.
// LED[2] and LED[6] indicate the final "sort allowed" gate.
board_static_outputs u_board_static_outputs (
    .led_status(recognition_led_status),
    .led(led),
    .uart1_txd(uart1_txd),
    .uart2_txd(uart2_txd),
    .jtag_inst1_tdo(jtag_inst1_TDO),
    .s0_cam_scl_out(S0_io_cam_scl_OUT),
    .s0_cam_scl_oe(S0_io_cam_scl_OE),
    .s0_cam_sda_out(S0_io_cam_sda_OUT),
    .s0_cam_sda_oe(S0_io_cam_sda_OE),
    .s0_cam_rst_p(S0_o_cam_rst_p),
    .mipi_rx_ck0_hs_ena(mipi_rx_ck0_HS_ENA),
    .mipi_rx_dp00_hs_ena(mipi_rx_dp00_HS_ENA),
    .mipi_rx_dp01_hs_ena(mipi_rx_dp01_HS_ENA),
    .mipi_rx_dp02_hs_ena(mipi_rx_dp02_HS_ENA),
    .mipi_rx_dp03_hs_ena(mipi_rx_dp03_HS_ENA),
    .mipi_rx_ck0_hs_term(mipi_rx_ck0_HS_TERM),
    .mipi_rx_dp00_hs_term(mipi_rx_dp00_HS_TERM),
    .mipi_rx_dp01_hs_term(mipi_rx_dp01_HS_TERM),
    .mipi_rx_dp02_hs_term(mipi_rx_dp02_HS_TERM),
    .mipi_rx_dp03_hs_term(mipi_rx_dp03_HS_TERM),
    .mipi_rx_dp00_rst(mipi_rx_dp00_RST),
    .mipi_rx_dp01_rst(mipi_rx_dp01_RST),
    .mipi_rx_dp02_rst(mipi_rx_dp02_RST),
    .mipi_rx_dp03_rst(mipi_rx_dp03_RST),
    .mipi_rx_dp00_fifo_rd(mipi_rx_dp00_FIFO_RD),
    .mipi_rx_dp01_fifo_rd(mipi_rx_dp01_FIFO_RD),
    .mipi_rx_dp02_fifo_rd(mipi_rx_dp02_FIFO_RD),
    .mipi_rx_dp03_fifo_rd(mipi_rx_dp03_FIFO_RD)
);

color_detector #(
    .HACT(HACT),
    .VACT(VACT),
    .COLOR_ROI_X_START(COLOR_ROI_X_START),
    .COLOR_ROI_X_END(COLOR_ROI_X_END),
    .COLOR_ROI_Y_START(COLOR_ROI_Y_START),
    .COLOR_ROI_Y_END(COLOR_ROI_Y_END),
    .FAST_COLOR_ROI_X_START(FAST_COLOR_ROI_X_START),
    .FAST_COLOR_ROI_X_END(FAST_COLOR_ROI_X_END),
    .FAST_COLOR_ROI_Y_START(FAST_COLOR_ROI_Y_START),
    .FAST_COLOR_ROI_Y_END(FAST_COLOR_ROI_Y_END),
    .VOTE_MIN_COUNT(VOTE_MIN_COUNT),
    .VOTE_MARGIN(VOTE_MARGIN),
    .FAST_VOTE_MIN_COUNT(FAST_VOTE_MIN_COUNT),
    .FAST_VOTE_MARGIN(FAST_VOTE_MARGIN),
    .FAST_LOCK_LINE_STREAK_NEW(FAST_LOCK_LINE_STREAK_NEW),
    .FAST_LOCK_LINE_STREAK_SWITCH(FAST_LOCK_LINE_STREAK_SWITCH)
) u_color_detector (
    .clk(i_sysclk_div2),
    .rst_n(arst_n),
    .rgb_vs(rgb_vs),
    .rgb_de(rgb_de),
    .rgb_datax2(rgb_datax2),
    .timer_running(timer_running_cam),
    .fast_timer_running(fast_timer_running_cam),
    .color_id(color_id_cam),
    .color_valid(color_valid_cam),
    .fast_color_id_out(fast_color_id_cam),
    .fast_color_valid_out(fast_color_valid_cam),
    .color_timer_start_pulse(color_timer_start_cam_pulse),
    .color_timer_stop_pulse(color_timer_stop_cam_pulse),
    .color_timer_cancel_pulse(color_timer_cancel_cam_pulse),
    .fast_color_timer_start_pulse(fast_color_timer_start_cam_pulse),
    .fast_color_timer_stop_pulse(fast_color_timer_stop_cam_pulse),
    .fast_color_timer_cancel_pulse(fast_color_timer_cancel_cam_pulse)
);

// 当前主线不用串口透传，TX 保持空闲高电平。

// Measures the color recognition response time in the camera/RGB clock domain.
// The displayed value is synchronized to HDMI later.
color_detect_timer #(
    .CLK_FREQ_HZ(74250000),
    .MAX_TIME_US(COLOR_TIMER_MAX_US)
) u_color_detect_timer (
    .clk(i_sysclk_div2),
    .rst_n(arst_n),
    .start_pulse(color_timer_start_cam_pulse),
    .stop_pulse(color_timer_stop_cam_pulse),
    .cancel_pulse(color_timer_cancel_cam_pulse),
    .running(timer_running_cam),
    .done_pulse(timer_done_cam),
    .result_valid(timer_result_valid_cam),
    .elapsed_us(timer_elapsed_us_cam),
    .live_us(timer_live_us_cam)
);

// Fast path timer: starts from the first fast-ROI live evidence and stops on
// the line-based fast lock, so it measures the sub-frame recognition path.
color_detect_timer #(
    .CLK_FREQ_HZ(74250000),
    .MAX_TIME_US(COLOR_TIMER_MAX_US)
) u_fast_color_detect_timer (
    .clk(i_sysclk_div2),
    .rst_n(arst_n),
    .start_pulse(fast_color_timer_start_cam_pulse),
    .stop_pulse(fast_color_timer_stop_cam_pulse),
    .cancel_pulse(fast_color_timer_cancel_cam_pulse),
    .running(fast_timer_running_cam),
    .done_pulse(fast_timer_done_cam),
    .result_valid(fast_timer_result_valid_cam),
    .elapsed_us(fast_timer_elapsed_us_cam),
    .live_us(fast_timer_live_us_cam)
);

// Measures the shape recognition response time in the camera/RGB clock domain.
color_detect_timer #(
    .CLK_FREQ_HZ(74250000),
    .MAX_TIME_US(COLOR_TIMER_MAX_US)
) u_shape_detect_timer (
    .clk(i_sysclk_div2),
    .rst_n(arst_n),
    .start_pulse(shape_timer_start_cam_pulse),
    .stop_pulse(shape_timer_stop_cam_pulse),
    .cancel_pulse(shape_timer_cancel_cam_pulse),
    .running(shape_timer_running_cam),
    .done_pulse(shape_timer_done_cam),
    .result_valid(shape_timer_result_valid_cam),
    .elapsed_us(shape_timer_elapsed_us_cam),
    .live_us(shape_timer_live_us_cam)
);

//========================================================================== 
// csi 
//========================================================================== 
    // Camera input section. soft_mipi_rx_top configures the first camera over
    // I2C, receives MIPI CSI data, and outputs packed RAW pixels.
    wire		       w_mipi_rx_vs1;
    wire		       w_mipi_rx_hs1;
    wire	         w_mipi_rx_de1;
    wire	[63:0]	 w_mipi_rx_data1	;

wire rx_out_de;
wire rx_out_hs;
wire rx_out_vs;
wire [PACK_BIT-1:0] rx_out_data;
wire [31:0] dbg_mipi_startup_sticky;
wire [95:0] dbg_i2c_detail;
`ifndef T35_RESOURCE_TRIM
(* syn_keep = "true", syn_preserve = "true" *) reg [31:0] dbg_mipi_startup_sync1 = 32'd0;
(* syn_keep = "true", syn_preserve = "true" *) reg [31:0] dbg_mipi_startup_sync2 = 32'd0;
(* syn_keep = "true", syn_preserve = "true", mark_debug = "true" *) reg [31:0] dbg_mipi_startup_fb_sticky = 32'd0;
(* syn_keep = "true", syn_preserve = "true" *) reg [95:0] dbg_i2c_detail_sync1 = 96'd0;
(* syn_keep = "true", syn_preserve = "true", mark_debug = "true" *) reg [95:0] dbg_i2c_detail_fb = 96'd0;
`endif

wire rx_out_de1;
wire rx_out_hs1;
wire rx_out_vs1;
wire [PACK_BIT-1:0] rx_out_data1;

`ifndef T35_RESOURCE_TRIM
// Bring the MIPI debug sticky flags into the fb clock domain so the Debug
// Wizard can probe one stable, single-clock bus.
always @(posedge i_fb_clk or negedge i_sw[0]) begin
    if (!i_sw[0]) begin
        dbg_mipi_startup_sync1 <= 32'd0;
        dbg_mipi_startup_sync2 <= 32'd0;
        dbg_mipi_startup_fb_sticky <= 32'd0;
        dbg_i2c_detail_sync1 <= 96'd0;
        dbg_i2c_detail_fb <= 96'd0;
    end else begin
        dbg_mipi_startup_sync1 <= dbg_mipi_startup_sticky;
        dbg_mipi_startup_sync2 <= dbg_mipi_startup_sync1;
        dbg_mipi_startup_fb_sticky <= dbg_mipi_startup_fb_sticky | dbg_mipi_startup_sync2;
        dbg_i2c_detail_sync1 <= dbg_i2c_detail;
        dbg_i2c_detail_fb <= dbg_i2c_detail_sync1;
    end
end
`endif

// HDMI-domain state derived from coherent camera/RGB-domain CDC snapshots.
always @(posedge hdmi_tx_slow_clk or negedge arst_n) begin
    if (!arst_n) begin
        color_id_hdmi <= COLOR_UNKNOWN;
        color_valid_hdmi <= 1'b0;
        shape_id_hdmi <= SHAPE_UNKNOWN;
        shape_valid_hdmi <= 1'b0;
        shape_display_id_hdmi_reg <= SHAPE_UNKNOWN;
        shape_display_valid_hdmi_reg <= 1'b0;
        timer_running_hdmi <= 1'b0;
        timer_result_valid_hdmi <= 1'b0;
        timer_elapsed_us_hdmi <= 24'd0;
        timer_live_us_hdmi <= 24'd0;
        timer_display_hold_us_hdmi <= 24'd0;
        timer_display_color_id_hdmi <= COLOR_UNKNOWN;
        shape_timer_running_hdmi <= 1'b0;
        shape_timer_result_valid_hdmi <= 1'b0;
        shape_timer_elapsed_us_hdmi <= 24'd0;
        shape_timer_live_us_hdmi <= 24'd0;
        shape_timer_display_hold_us_hdmi <= 24'd0;
        shape_latency_display_id_hdmi <= SHAPE_UNKNOWN;
        shape_latency_display_valid_hdmi <= 1'b0;
        shape_latency_display_us_hdmi <= 24'd0;
    end else begin
        if (result_cdc_pulse_hdmi) begin
            {
                shape_timer_live_us_hdmi,
                shape_timer_elapsed_us_hdmi,
                shape_timer_result_valid_hdmi,
                shape_timer_running_hdmi,
                timer_live_us_hdmi,
                timer_elapsed_us_hdmi,
                timer_result_valid_hdmi,
                timer_running_hdmi,
                shape_display_valid_hdmi_reg,
                shape_display_id_hdmi_reg,
                shape_valid_hdmi,
                shape_id_hdmi,
                color_valid_hdmi,
                color_id_hdmi
            } <= result_cdc_data_hdmi;
        end

        if (!color_latency_known_hdmi) begin
            timer_display_hold_us_hdmi <= 24'd0;
            timer_display_color_id_hdmi <= COLOR_UNKNOWN;
        end else if ((timer_display_color_id_hdmi != color_id_hdmi) && timer_result_valid_hdmi) begin
            timer_display_hold_us_hdmi <=
                (timer_elapsed_us_hdmi > COLOR_TIMER_DISPLAY_MAX_US) ?
                COLOR_TIMER_DISPLAY_MAX_US : timer_elapsed_us_hdmi;
            timer_display_color_id_hdmi <= color_id_hdmi;
        end

        if (!shape_valid_hdmi || (shape_id_hdmi == SHAPE_UNKNOWN)) begin
            shape_timer_display_hold_us_hdmi <= 24'd0;
        end else if (shape_timer_running_hdmi && (shape_timer_live_us_hdmi != 24'd0)) begin
            shape_timer_display_hold_us_hdmi <=
                (shape_timer_live_us_hdmi > COLOR_TIMER_DISPLAY_MAX_US) ?
                COLOR_TIMER_DISPLAY_MAX_US : shape_timer_live_us_hdmi;
        end else if (shape_timer_result_valid_hdmi) begin
            shape_timer_display_hold_us_hdmi <=
                (shape_timer_elapsed_us_hdmi > COLOR_TIMER_DISPLAY_MAX_US) ?
                COLOR_TIMER_DISPLAY_MAX_US : shape_timer_elapsed_us_hdmi;
        end

        if (shape_display_id_hdmi == SHAPE_UNKNOWN) begin
            shape_latency_display_id_hdmi <= SHAPE_UNKNOWN;
            shape_latency_display_valid_hdmi <= 1'b0;
            shape_latency_display_us_hdmi <= 24'd0;
        end else if ((!shape_latency_display_valid_hdmi) ||
                     (shape_latency_display_id_hdmi != shape_display_id_hdmi)) begin
            shape_latency_display_id_hdmi <= shape_display_id_hdmi;
            shape_latency_display_valid_hdmi <= 1'b1;
            shape_latency_display_us_hdmi <=
                shape_latency_sample_valid_hdmi ? shape_latency_sample_us_hdmi : 24'd0;
        end else if ((shape_latency_display_us_hdmi == 24'd0) &&
                     shape_latency_sample_valid_hdmi) begin
            shape_latency_display_us_hdmi <= shape_latency_sample_us_hdmi;
        end
    end
end

  // Camera receiver is routed through the reserved second MIPI/S1 interface.
  soft_mipi_rx_top # (
    .ENABLE_DEBUG_STICKY(1'b0),
    .PACK_BIT(PACK_BIT)
  )
  soft_mipi_rx_top_inst (
    .mipi_clk                   (   mipi_clk                   ),
    .CLK_5M                     (   CLK_5M                     ),
    .i_sysclk_div2              (   i_sysclk_div2              ),
    .arst_n                     (   arst_n                     ),
    .dbg_clear_n                (   i_sw[0]                    ),
    .mipi_rx_ck0_CLKOUT         (   mipi_rx_ck1_CLKOUT         ),
    .io_cam_scl_IN              (   S1_io_cam_scl_IN           ),
    .io_cam_sda_IN              (   S1_io_cam_sda_IN           ),
    .io_cam_scl_OUT             (   S1_io_cam_scl_OUT          ),
    .io_cam_scl_OE              (   S1_io_cam_scl_OE           ),
    .io_cam_sda_OUT             (   S1_io_cam_sda_OUT          ),
    .io_cam_sda_OE              (   S1_io_cam_sda_OE           ),
    .o_cam_rst_p                (   S1_o_cam_rst_p             ),
    .mipi_rx_ck0_HS_ENA         (   mipi_rx_ck1_HS_ENA         ),
    .mipi_rx_dp00_HS_ENA        (   mipi_rx_dp10_HS_ENA        ),
    .mipi_rx_dp01_HS_ENA        (   mipi_rx_dp11_HS_ENA        ),
    .mipi_rx_dp02_HS_ENA        (   mipi_rx_dp12_HS_ENA        ),
    .mipi_rx_dp03_HS_ENA        (   mipi_rx_dp13_HS_ENA        ),
    .mipi_rx_ck0_HS_TERM        (   mipi_rx_ck1_HS_TERM        ),
    .mipi_rx_dp00_HS_TERM       (   mipi_rx_dp10_HS_TERM       ),
    .mipi_rx_dp01_HS_TERM       (   mipi_rx_dp11_HS_TERM       ),
    .mipi_rx_dp02_HS_TERM       (   mipi_rx_dp12_HS_TERM       ),
    .mipi_rx_dp03_HS_TERM       (   mipi_rx_dp13_HS_TERM       ),
    .mipi_rx_dp00_RST           (   mipi_rx_dp10_RST           ),
    .mipi_rx_dp01_RST           (   mipi_rx_dp11_RST           ),
    .mipi_rx_dp02_RST           (   mipi_rx_dp12_RST           ),
    .mipi_rx_dp03_RST           (   mipi_rx_dp13_RST           ),
    .mipi_rx_ck0_LP_N_IN        (   mipi_rx_ck1_LP_N_IN        ),
    .mipi_rx_ck0_LP_P_IN        (   mipi_rx_ck1_LP_P_IN        ),
    .mipi_rx_dp00_LP_N_IN       (   mipi_rx_dp10_LP_N_IN       ),
    .mipi_rx_dp00_LP_P_IN       (   mipi_rx_dp10_LP_P_IN       ),
    .mipi_rx_dp01_LP_N_IN       (   mipi_rx_dp11_LP_N_IN       ),
    .mipi_rx_dp01_LP_P_IN       (   mipi_rx_dp11_LP_P_IN       ),
    .mipi_rx_dp02_LP_N_IN       (   mipi_rx_dp12_LP_N_IN       ),
    .mipi_rx_dp02_LP_P_IN       (   mipi_rx_dp12_LP_P_IN       ),
    .mipi_rx_dp03_LP_N_IN       (   mipi_rx_dp13_LP_N_IN       ),
    .mipi_rx_dp03_LP_P_IN       (   mipi_rx_dp13_LP_P_IN       ),
    .mipi_rx_dp00_HS_IN         (   mipi_rx_dp10_HS_IN         ),
    .mipi_rx_dp01_HS_IN         (   mipi_rx_dp11_HS_IN         ),
    .mipi_rx_dp02_HS_IN         (   mipi_rx_dp12_HS_IN         ),
    .mipi_rx_dp03_HS_IN         (   mipi_rx_dp13_HS_IN         ),
    .mipi_rx_dp00_FIFO_RD       (   mipi_rx_dp10_FIFO_RD       ),
    .mipi_rx_dp01_FIFO_RD       (   mipi_rx_dp11_FIFO_RD       ),
    .mipi_rx_dp02_FIFO_RD       (   mipi_rx_dp12_FIFO_RD       ),
    .mipi_rx_dp03_FIFO_RD       (   mipi_rx_dp13_FIFO_RD       ),
    .mipi_rx_dp00_FIFO_EMPTY    (   mipi_rx_dp10_FIFO_EMPTY    ),
    .mipi_rx_dp01_FIFO_EMPTY    (   mipi_rx_dp11_FIFO_EMPTY    ),
    .mipi_rx_dp02_FIFO_EMPTY    (   mipi_rx_dp12_FIFO_EMPTY    ),
    .mipi_rx_dp03_FIFO_EMPTY    (   mipi_rx_dp13_FIFO_EMPTY    ),
    .rx_out_de                  (   rx_out_de                  ),
    .rx_out_hs                  (   rx_out_hs                  ),
    .rx_out_vs                  (   rx_out_vs                  ),
    .rx_out_data                (   rx_out_data                ),
    .dbg_mipi_startup_sticky    (   dbg_mipi_startup_sticky    ),
    .dbg_i2c_detail             (   dbg_i2c_detail             )
  );

  // 第二路摄像头链路当前不参与综合，保留源码文件，后续需要时可恢复。
`ifdef  FRAME_BUFFER

//============================================================================================ 
//frame_buffer 0 
//============================================================================================	
// Frame buffer writes the incoming camera stream to DDR and reads it back with
// stable 1080p timing. This decouples MIPI timing jitter from the recognition
// and HDMI display pipeline.
  
  wire [7:0] 	ch0_r;
  wire [7:0]    ch0_g;
  wire [7:0]    ch0_b;
  wire ch0_vs;
  wire ch0_hs;
  wire ch0_de;
frame_buffer #(
.AXI_DATA_WIDTH ( AXI_DATA_WIDTH	),
.I_VID_WIDTH    ( I_VID_WIDTH       ),
.O_VID_WIDTH    ( O_VID_WIDTH       ),
.FB_NUM         ( FB_NUM            ),
.BURST_LEN      ( BURST_LEN         ),
.MAX_VID_WIDTH 	( MAX_VID_WIDTH     ),
.MAX_VID_HIGHT 	( MAX_VID_HIGHT     ),
.AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH	),
.WR_FIFO_DEPTH	( WR_FIFO_DEPTH		),    
.RD_FIFO_DEPTH 	( RD_FIFO_DEPTH 	),
.START_ADDR		(	START_ADDR		)
)u_frame_buffer(
    .axi_clk(axi0_ACLK),
    .rst_n(sys_rst_n),
    // .i_clk  (i_sys_clk) ,
    // .i_vs   (vs) , 
    // .i_de   (de) , 
    // .vin   ({r_data,g_data,b_data}) ,// ({24'habcdef}),//

/*i*/.i_clk			(i_sysclk_div2      ),
/*i*/.i_vs			(rx_out_vs	),
/*i*/.i_de			(rx_out_de 	),
/*i*/.vin 			({rx_out_data[39:32],rx_out_data[29:22],rx_out_data[19:12],rx_out_data[9:2]}	),

    .o_clk  (i_sysclk_div2) ,
    // .o_hs   (fb_ch0_hs) ,
    // .o_vs   (fb_ch0_vs) ,
    // .o_de   (fb_ch0_de) ,
    // .vout   ({fb_ch0_dout}) ,

    /*i*/.o_hs    		(ch0_hs		),			
/*i*/.o_vs    		(ch0_vs		),			
/*i*/.o_de    		(ch0_de		),			
/*i*/.vout    		({ch0_g,ch0_b}	),//ch0_r,

    .H_FRONT_PORCH 	(HFP/2	    ),
    .H_SYNC 		(HSP/2	    ),	
    .H_VALID 		(HACT/2	    ),
    .H_BACK_PORCH 	(HBP/2	    ),
    .V_FRONT_PORCH 	(VFP		),
    .V_SYNC 		(VSP		),	
    .V_VALID 		(VACT	    ),
    .V_BACK_PORCH 	(VBP		),
    .out_sync         (out_sync),
    .awid       (axi_m_awid   [1*AXI_ID_WIDTH-1   : 0]),
    .awaddr     (axi_m_awaddr [1*AXI_ADDR_WIDTH-1 : 0]),
    .awlen      (axi_m_awlen  [1*8-1              : 0]),
    .awsize     (axi_m_awsize [1*3-1              : 0]),
    .awburst    (axi_m_awburst[1*2-1              : 0]),
    .awcache    (),
    .awlock     (axi_m_awlock [1*1-1              : 0]),
    .awvalid    (axi_m_awvalid[1*1-1              : 0]),
    .awcobuf    (),
    .awapcmd    (),
    .awallstrb  (),
    .awready    (axi_m_awready[1*1-1              : 0]),
    .awqos      (),
    .arid       (axi_m_arid   [1*AXI_ID_WIDTH-1   : 0]),
    .araddr     (axi_m_araddr [1*AXI_ADDR_WIDTH-1 : 0]),
    .arlen      (axi_m_arlen  [1*8-1              : 0]),
    .arsize     (axi_m_arsize [1*3-1              : 0]),
    .arburst    (axi_m_arburst[1*2-1              : 0]),
    .arlock     (axi_m_arlock [1*1-1              : 0]),
    .arvalid    (axi_m_arvalid[1*1-1              : 0]),
    .arapcmd    (),
    .arready    (axi_m_arready[1*1-1              : 0]),
    .arqos      (),
    .wdata      (axi_m_wdata  [1*AXI_DATA_WIDTH-1 : 0]),
    .wstrb      (axi_m_wstrb  [1*(AXI_DATA_WIDTH/8)-1 : 0]),
    .wlast      (axi_m_wlast  [1*1-1              : 0]),
    .wvalid     (axi_m_wvalid [1*1-1              : 0]),
    .wready     (axi_m_wready [1*1-1              : 0]),
    .rid        (axi_m_rid    [1*8-1              : 0]),
    .rdata      (axi_m_rdata  [1*AXI_DATA_WIDTH-1 : 0]),
    .rlast      (axi_m_rlast  [1*1-1              : 0]),
    .rvalid     (axi_m_rvalid [1*1-1              : 0]),
    .rready     (axi_m_rready [1*1-1              : 0]),
    .rresp      (axi_m_rresp  [1*2-1              : 0]),
    .bid        (axi_m_bid    [1*8-1              : 0]),
    .bvalid     (axi_m_bvalid [1*1-1              : 0]),
    .bready     (axi_m_bready [1*1-1              : 0])
);



// color_bar_checker  #(
//     .DATA_WIDTH (O_VID_WIDTH)
// )u_color_bar_checker (
//     .clk(i_sysclk_div2),
//     .rst_n(sys_rst_n),
//     .i_hs(fb_ch0_hs),
//     .i_vs(fb_ch0_vs),
//     .i_de(fb_ch0_de),
//     .vin(fb_ch0_dout),
//     .check_fail(check_fail)
//   );

// 第二路 framebuffer 链路当前不参与综合，保留源码文件，后续需要时可恢复。

//======================================================================================================== 
// axi_interconnect
//======================================================================================================== 
// Two AXI interconnect instances are used because this local IP separates the
// write-side and read-side channel groups. Both connect the frame buffer to the
// DDR controller AXI0 port.
axi_interconnect #
(
    .S_COUNT                            (S_COUNT                            ),
    .M_COUNT                            (M_COUNT                            ),
    .DATA_WIDTH                         (AXI_DATA_WIDTH                     ),
    .ADDR_WIDTH                         (AXI_ADDR_WIDTH                     ),
    .ID_WIDTH                           (AXI_ID_WIDTH                       )
)
uw_axi_interconnect
(
    .clk                                (axi0_ACLK                            ),
    .rst                                (~sys_rst_n                             ),
//AXI slave interfaces
    .s_axi_awid                         (axi_m_awid	  [S_COUNT*AXI_ID_WIDTH-1   : 0]    ),// 
    .s_axi_awaddr                       (axi_m_awaddr [S_COUNT*AXI_ADDR_WIDTH-1 : 0]   	), 
    .s_axi_awlen                        (axi_m_awlen  [S_COUNT*8-1      : 0]   			), 
    .s_axi_awsize                       (axi_m_awsize [S_COUNT*3-1		: 0]	 		), 
    .s_axi_awburst                      (axi_m_awburst[S_COUNT*2-1      : 0]   			), 
    .s_axi_awlock                       (axi_m_awlock [S_COUNT*1-1      : 0]   			), 
    .s_axi_awcache                      (axi_m_awcache[S_COUNT*4-1      : 0]   			), 
    .s_axi_awprot                       (axi_m_awprot [S_COUNT*3-1      : 0]   			), 
    .s_axi_awvalid                      (axi_m_awvalid[S_COUNT*1-1      : 0]   			), 
    .s_axi_awready                      (axi_m_awready[S_COUNT*1-1      : 0]   			),

    .s_axi_wdata                        (axi_m_wdata  [S_COUNT*AXI_DATA_WIDTH-1 : 0]   	), 
    .s_axi_wstrb                        (axi_m_wstrb  [S_COUNT*(AXI_DATA_WIDTH/8)-1 : 0]), 
    .s_axi_wlast                        (axi_m_wlast  [S_COUNT*1-1      : 0]   			), 
    .s_axi_wvalid                       (axi_m_wvalid [S_COUNT*1-1      : 0]   			), 
    .s_axi_wready                       (axi_m_wready [S_COUNT*1-1      : 0]   			),
    .s_axi_bid                          (axi_m_bid    [S_COUNT*8-1      : 0]   			),
    .s_axi_bresp                        (axi_m_bresp  [S_COUNT*2-1      : 0]   			), 
    .s_axi_bvalid                       (axi_m_bvalid [S_COUNT*1-1      : 0]   			), 
    .s_axi_bready                       (axi_m_bready [S_COUNT*1-1      : 0]   			),
//AXI master interfaces
    .m_axi_awid                         (axi0_AWID       ), //(axi_m1_awid      ),
    .m_axi_awaddr                       (axi0_AWADDR     ), //(axi_m1_awaddr   	), 
    .m_axi_awlen                        (axi0_AWLEN      ), //(axi_m1_awlen     ), 
    .m_axi_awsize                       (axi0_AWSIZE     ), //(axi_m1_awsize    ), 
    .m_axi_awburst                      (axi0_AWBURST    ), //(axi_m1_awburst   ), 
    .m_axi_awlock                       (axi0_AWLOCK     ), //(axi_m1_awlock    ), 
    .m_axi_awcache                      (),//(axi_m1_awcache   ), 
    .m_axi_awprot                       (),//(axi0_WID        ), //(axi_m1_awprot    ), 
    .m_axi_awvalid                      (axi0_AWVALID    ), //(axi_m1_awvalid   ), 
    .m_axi_awready                      (axi0_AWREADY    ), //(axi_m1_awready   ), 
    .m_axi_wdata                        (axi0_WDATA      ), //(axi_m1_wdata     ), 
    .m_axi_wstrb                        (axi0_WSTRB      ), //(axi_m1_wstrb     ), 
    .m_axi_wlast                        (axi0_WLAST      ), //(axi_m1_wlast     ), 
    .m_axi_wvalid                       (axi0_WVALID     ), //(axi_m1_wvalid    ), 
    .m_axi_wready                       (axi0_WREADY     ), //(axi_m1_wready    ),
    .m_axi_bid                          (axi0_BID        ), //(axi_m1_bid       ),
    .m_axi_bresp                        (),//(axi_m1_bresp     ), 
    .m_axi_bvalid                       (axi0_BVALID     ), //(axi_m1_bvalid    ), 
    .m_axi_bready                       (axi0_BREADY     )//, //(axi_m1_bready    ),
);

axi_interconnect #
(
    .S_COUNT                            (S_COUNT                            ),
    .M_COUNT                            (M_COUNT                            ),
    .DATA_WIDTH                         (AXI_DATA_WIDTH                     ),
    .ADDR_WIDTH                         (AXI_ADDR_WIDTH                     ),
    .ID_WIDTH                           (AXI_ID_WIDTH                       )
)
ur_axi_interconnect
(
    .clk                                (axi0_ACLK                            ),
    .rst                                (~sys_rst_n                             ),
//AXI slave interfaces
    
    .s_axi_arid                         (axi_m_arid   [S_COUNT*AXI_ID_WIDTH-1   : 0]   	),
    .s_axi_araddr                       (axi_m_araddr [S_COUNT*AXI_ADDR_WIDTH-1 : 0]   	), 
    .s_axi_arlen                        (axi_m_arlen  [S_COUNT*8-1      : 0]   			), 
    .s_axi_arsize                       (axi_m_arsize [S_COUNT*3-1      : 0]   			), 
    .s_axi_arburst                      (axi_m_arburst[S_COUNT*2-1      : 0]   			), 
    .s_axi_arlock                       (axi_m_arlock [S_COUNT*1-1      : 0]   			), 
    .s_axi_arvalid                      (axi_m_arvalid[S_COUNT*1-1      : 0]   			), 
    .s_axi_arready                      (axi_m_arready[S_COUNT*1-1      : 0]   			),
    .s_axi_rid                          (axi_m_rid    [S_COUNT*8-1      : 0]   			),
    .s_axi_rdata                        (axi_m_rdata  [S_COUNT*AXI_DATA_WIDTH-1 : 0]   	), 
    .s_axi_rresp                        (axi_m_rresp  [S_COUNT*2-1      : 0]   			), 
    .s_axi_rlast                        (axi_m_rlast  [S_COUNT*1-1      : 0]   			), 
    .s_axi_rvalid                       (axi_m_rvalid [S_COUNT*1-1      : 0]   			), 
    .s_axi_rready                       (axi_m_rready [S_COUNT*1-1      : 0]   			),
//AXI master interfaces
   
    .m_axi_arid                         (axi0_ARID       ), //(axi_m1_arid      ),
    .m_axi_araddr                       (axi0_ARADDR     ), //(axi_m1_araddr    ), 
    .m_axi_arlen                        (axi0_ARLEN      ),  //(axi_m1_arlen     ), 
    .m_axi_arsize                       (axi0_ARSIZE     ), //(axi_m1_arsize    ), 
    .m_axi_arburst                      (axi0_ARBURST    ), //(axi_m1_arburst   ), 
    .m_axi_arlock                       (axi0_ARLOCK     ), //(axi_m1_arlock    ), 
    .m_axi_arcache                      (),//(axi_m1_arcache   ), 
    .m_axi_arprot                       (),//(axi_m1_arprot    ), 
    .m_axi_arvalid                      (axi0_ARVALID    ), //(axi_m1_arvalid   ), 
    .m_axi_arready                      (axi0_ARREADY    ), //(axi_m1_arready   ),
    .m_axi_rid                          (axi0_RID        ), //(axi_m1_rid       ),
    .m_axi_rdata                        (axi0_RDATA      ), //(axi_m1_rdata     ), 
    .m_axi_rresp                        (axi0_RRESP      ), //(axi_m1_rresp     ), 
    .m_axi_rlast                        (axi0_RLAST      ), //(axi_m1_rlast     ), 
    .m_axi_rvalid                       (axi0_RVALID     ), //(axi_m1_rvalid    ), 
    .m_axi_rready                       (axi0_RREADY     )  //(axi_m1_rready    )
);
`endif 


//***************************************************************************
// debayer
//***************************************************************************

reg [26:0] sw_cnt;
always @( posedge i_sysclk_div2)
begin
    // out_sync is a delayed enable for the frame-buffer read side.
    sw_cnt <= sw_cnt + 1'b1;
    if( sw_cnt[25] )
        out_sync <= 1'b1;
end

  // Convert two RAW Bayer pixels from the frame-buffer output into two RGB
  // pixels. rgb_datax2 is the main stream consumed by color and shape logic.
  debayer_top_2to1 debayer_top
  (
      .in_pclk		  (i_sysclk_div2),//(i_mipi_rx_pclk ),
      .in_rstn		  (sys_rst_n),
      
      .raw_vs_i		  (ch0_vs		  ),//(ch1_vs	     ),//
      .raw_hs_i		  (ch0_hs		  ),//(ch1_hs	     ),//	 
      .raw_de_i		  (ch0_de		  ),//(ch1_de	     ),//	
      .raw_valid_i	  (ch0_de	      ),//(ch1_de	     ),//	
      .raw_datax4_i	  ({ch0_b,ch0_g}  ),//
      
      .rgb_vs_o		  (rgb_vs         ),
      .rgb_hs_o		  (rgb_hs         ),
      .rgb_de_o		  (rgb_de         ),
      .rgb_valid_o	  (rgb_valid      ),
      .rgb_datax2_o   (rgb_datax2     )//b,g,r,b,g,r
  );
  // 第二路 debayer 链路当前不参与综合，保留源码文件，后续需要时可恢复。

//=============================================================================
// The second video path is not used in this build.
//=============================================================================


// HDMI result UI owns the 640x480 UI timing, drawing, font overlay, and TMDS encoder.
`ifdef HDMI_OUT_EN
hdmi_result_ui #(
    .COLOR_UNKNOWN(COLOR_UNKNOWN),
    .COLOR_BLACK(COLOR_BLACK),
    .COLOR_WHITE(COLOR_WHITE),
    .COLOR_RED(COLOR_RED),
    .COLOR_BLUE(COLOR_BLUE),
    .COLOR_YELLOW(COLOR_YELLOW),
    .SHAPE_UNKNOWN(SHAPE_UNKNOWN),
    .SHAPE_CUBE(SHAPE_CUBE),
    .SHAPE_CYLINDER(SHAPE_CYLINDER),
    .SHAPE_CONE(SHAPE_CONE)
) u_hdmi_result_ui (
    .hdmi_tx_slow_clk(hdmi_tx_slow_clk),
    .sys_rst_n(sys_rst_n),
    .hdmi_pll_locked(hdmi_pll_locked),
    .shape_page_cam(shape_page_cam),
    .color_id_hdmi(color_id_hdmi),
    .color_valid_hdmi(color_valid_hdmi),
    .shape_display_id_hdmi(shape_display_id_hdmi),
    .timer_running_hdmi(timer_running_hdmi),
    .timer_result_valid_hdmi(timer_result_valid_hdmi),
    .timer_display_active_hdmi(timer_display_active_hdmi),
    .timer_display_us_hdmi(timer_display_us_hdmi),
    .timer_display_us_hdmi_clamped(timer_display_us_hdmi_clamped),
    .timer_display_hold_us_hdmi(timer_display_hold_us_hdmi),
    .shape_latency_display_valid_hdmi(shape_latency_display_valid_hdmi),
    .shape_latency_display_us_hdmi(shape_latency_display_us_hdmi),
    .shape_latency_display_us_hdmi_clamped(shape_latency_display_us_hdmi_clamped),
    .shape_preview_ui_active(shape_preview_ui_active),
    .shape_preview_ui_x(shape_preview_ui_x),
    .shape_preview_ui_y(shape_preview_ui_y),
    .tmds_data0_TX_DATA(tmds_data0_TX_DATA),
    .tmds_data1_TX_DATA(tmds_data1_TX_DATA),
    .tmds_data2_TX_DATA(tmds_data2_TX_DATA),
    .tmds_clk_TX_DATA(tmds_clk_TX_DATA),
    .tmds_data0_TX_OE(tmds_data0_TX_OE),
    .tmds_data1_TX_OE(tmds_data1_TX_OE),
    .tmds_data2_TX_OE(tmds_data2_TX_OE),
    .tmds_clk_TX_OE(tmds_clk_TX_OE),
    .tmds_data0_TX_RST(tmds_data0_TX_RST),
    .tmds_data1_TX_RST(tmds_data1_TX_RST),
    .tmds_data2_TX_RST(tmds_data2_TX_RST),
    .tmds_clk_TX_RST(tmds_clk_TX_RST)
);
`else
assign shape_preview_ui_active = 1'b0;
assign shape_preview_ui_x = 8'd0;
assign shape_preview_ui_y = 7'd0;
assign tmds_data0_TX_DATA = 10'd0;
assign tmds_data1_TX_DATA = 10'd0;
assign tmds_data2_TX_DATA = 10'd0;
assign tmds_clk_TX_DATA = 10'd0;
assign tmds_data0_TX_OE = 1'b0;
assign tmds_data1_TX_OE = 1'b0;
assign tmds_data2_TX_OE = 1'b0;
assign tmds_clk_TX_OE = 1'b0;
assign tmds_data0_TX_RST = 1'b1;
assign tmds_data1_TX_RST = 1'b1;
assign tmds_data2_TX_RST = 1'b1;
assign tmds_clk_TX_RST = 1'b1;
`endif

endmodule
