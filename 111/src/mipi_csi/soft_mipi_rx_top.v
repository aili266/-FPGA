
module soft_mipi_rx_top #(
  parameter ENABLE_DEBUG_STICKY = 1'b1,
  parameter PACK_BIT          = 40
) (
   input mipi_clk,
   input CLK_5M,
   input i_sysclk_div2,
   input arst_n,
   input dbg_clear_n,
   input mipi_rx_ck0_CLKOUT,

   input  io_cam_scl_IN,
   input  io_cam_sda_IN,
   output io_cam_scl_OUT,
   output io_cam_scl_OE,
   output io_cam_sda_OUT,
   output io_cam_sda_OE,
   output o_cam_rst_p,

  //mipi rx
   output mipi_rx_ck0_HS_ENA,
   output mipi_rx_dp00_HS_ENA,
   output mipi_rx_dp01_HS_ENA,
   output mipi_rx_dp02_HS_ENA,
   output mipi_rx_dp03_HS_ENA,

   output mipi_rx_ck0_HS_TERM,
   output mipi_rx_dp00_HS_TERM,
   output mipi_rx_dp01_HS_TERM,
   output mipi_rx_dp02_HS_TERM,
   output mipi_rx_dp03_HS_TERM,
  
  
   output mipi_rx_dp00_RST,
   output mipi_rx_dp01_RST,
   output mipi_rx_dp02_RST,
   output mipi_rx_dp03_RST,


   input       mipi_rx_ck0_LP_N_IN,
   input       mipi_rx_ck0_LP_P_IN,
   input       mipi_rx_dp00_LP_N_IN,
   input       mipi_rx_dp00_LP_P_IN,
   input       mipi_rx_dp01_LP_N_IN,
   input       mipi_rx_dp01_LP_P_IN,
   input       mipi_rx_dp02_LP_N_IN,
   input       mipi_rx_dp02_LP_P_IN,
   input       mipi_rx_dp03_LP_N_IN,
   input       mipi_rx_dp03_LP_P_IN,

   input [7:0] mipi_rx_dp00_HS_IN,
   input [7:0] mipi_rx_dp01_HS_IN,
   input [7:0] mipi_rx_dp02_HS_IN,
   input [7:0] mipi_rx_dp03_HS_IN,

   output      mipi_rx_dp00_FIFO_RD,
   output      mipi_rx_dp01_FIFO_RD,
   output      mipi_rx_dp02_FIFO_RD,
   output      mipi_rx_dp03_FIFO_RD,
   input       mipi_rx_dp00_FIFO_EMPTY,
   input       mipi_rx_dp01_FIFO_EMPTY,
   input       mipi_rx_dp02_FIFO_EMPTY,
   input       mipi_rx_dp03_FIFO_EMPTY,

   output      rx_out_de,
   output      rx_out_hs,
   output      rx_out_vs,
   output      [PACK_BIT-1:0] rx_out_data,
   output      [31:0] dbg_mipi_startup_sticky,
   output      [95:0] dbg_i2c_detail




);



//========================================================================== 
// csi 
//========================================================================== 
wire mipi_dphy_rx_reset_byte_HS_n;
wire reset_pixel_n;
wire [5:0] datatype;
wire [15:0] word_count;
wire dbg_i2c_init_done;
wire dbg_i2c_wr_en;
wire dbg_i2c_rd_en;
wire dbg_i2c_wr_done;
wire dbg_i2c_rd_done;
wire [15:0] dbg_i2c_reg_addr;
wire [7:0] dbg_i2c_reg_data;
wire dbg_vid_frame_stable;
    
reset
#(
	.IN_RST_ACTIVE	("LOW"),
	.OUT_RST_ACTIVE	("LOW"),
	.CYCLE			(3)
)
inst_rx_byteclk_rst
(
	.i_arst	(arst_n),
	.i_clk	(mipi_rx_ck0_CLKOUT),
	.o_srst	(mipi_dphy_rx_reset_byte_HS_n)
);

reset
#(
	.IN_RST_ACTIVE	("LOW"),
	.OUT_RST_ACTIVE	("LOW"),
	.CYCLE			(3)
)
inst_pixel_clk_rst
(
	.i_arst	(arst_n),
	.i_clk	(i_sysclk_div2),//pixel_clk
	.o_srst	(reset_pixel_n)
);
    



reg		[5:0]	r_rx_axi_araddr_1P;
reg				r_rx_axi_arvalid_1P;
wire			w_rx_axi_arready;
wire	[31:0]	w_rx_axi_rdata;
wire			w_rx_axi_rvalid;
reg				r_rx_axi_rready_1P;

  assign mipi_rx_dp00_RST = 1'b0; 
  assign mipi_rx_dp01_RST = 1'b0; 
  assign mipi_rx_dp02_RST = 1'b0; 
  assign mipi_rx_dp03_RST = 1'b0; 


csi_rx_controller inst_efx_csi2_rx
(
    .reset_n			(arst_n),
    .clk				(mipi_clk),
    .reset_byte_HS_n	(mipi_dphy_rx_reset_byte_HS_n),
    .clk_byte_HS		(mipi_rx_ck0_CLKOUT),
    .reset_pixel_n		(reset_pixel_n),
    .clk_pixel			(i_sysclk_div2),  
    // LVDS clock lane   
	.Rx_LP_CLK_P		(mipi_rx_ck0_LP_P_IN),
	.Rx_LP_CLK_N		(mipi_rx_ck0_LP_N_IN),
	.Rx_HS_enable_C		(mipi_rx_ck0_HS_ENA),
	.LVDS_termen_C		(mipi_rx_ck0_HS_TERM),
	
	// ----- DLane 0 -----------
    // LVDS data lane
    .Rx_LP_D_P			  ({mipi_rx_dp03_LP_P_IN, mipi_rx_dp02_LP_P_IN, mipi_rx_dp01_LP_P_IN, mipi_rx_dp00_LP_P_IN}),
	.Rx_LP_D_N			    ({mipi_rx_dp03_LP_N_IN, mipi_rx_dp02_LP_N_IN, mipi_rx_dp01_LP_N_IN, mipi_rx_dp00_LP_N_IN}),
	.Rx_HS_D_0			    (mipi_rx_dp00_HS_IN),
	.Rx_HS_D_1			    (mipi_rx_dp01_HS_IN),	
	.Rx_HS_D_2			    (mipi_rx_dp02_HS_IN),
	.Rx_HS_D_3			    (mipi_rx_dp03_HS_IN),
	.Rx_HS_enable_D		  ({mipi_rx_dp03_HS_ENA    , mipi_rx_dp02_HS_ENA    , mipi_rx_dp01_HS_ENA    , mipi_rx_dp00_HS_ENA    }),
	.LVDS_termen_D		  ({mipi_rx_dp03_HS_TERM   , mipi_rx_dp02_HS_TERM   , mipi_rx_dp01_HS_TERM   , mipi_rx_dp00_HS_TERM   }),
	.fifo_rd_enable     ({mipi_rx_dp03_FIFO_RD   , mipi_rx_dp02_FIFO_RD   , mipi_rx_dp01_FIFO_RD   , mipi_rx_dp00_FIFO_RD   }),
	.fifo_rd_empty      ({mipi_rx_dp03_FIFO_EMPTY, mipi_rx_dp02_FIFO_EMPTY, mipi_rx_dp01_FIFO_EMPTY, mipi_rx_dp00_FIFO_EMPTY}),
	
	.DLY_enable_D       (),
	.DLY_inc_D          (),
	.u_dly_enable_D     (),
	.u_dly_inc_D        (),
	
    //AXI4-Lite Interface
    .axi_clk		(mipi_clk), 
    .axi_reset_n	(arst_n),
    .axi_awaddr		(6'b0),//Write Address. byte address.
    .axi_awvalid	(1'b0),//Write address valid.
    .axi_awready	(),//Write address ready.
    .axi_wdata		(32'b0),//Write data bus.
    .axi_wvalid		(1'b0),//Write valid.
    .axi_wready		(),//Write ready.           
    .axi_bvalid		(),//Write response valid.
    .axi_bready		(1'b0),//Response ready.      
    .axi_araddr		(r_rx_axi_araddr_1P),//Read address. byte address.
    .axi_arvalid	(r_rx_axi_arvalid_1P),//Read address valid.
    .axi_arready	(w_rx_axi_arready),//Read address ready.
    .axi_rdata		(w_rx_axi_rdata),//Read data.
    .axi_rvalid		(w_rx_axi_rvalid),//Read valid.
//    .axi_rready		(r_rx_axi_rready_1P),//Read ready.
    .axi_rready		(1'b1),//Read ready.
	
    .hsync_vc0			(rx_out_hs),
    .hsync_vc1			(),
    .hsync_vc2			(),
    .hsync_vc3			(),
    .vsync_vc0			(rx_out_vs),
    .vsync_vc1			(),
    .vsync_vc2			(),
    .vsync_vc3			(),
    .vc					(),
	.word_count			(word_count),
	.shortpkt_data_field(),
	.datatype			(datatype),        //DATATYPE RAW8
    .pixel_per_clk		(),
	.pixel_data			(rx_out_data),
    .pixel_data_valid	(rx_out_de),
    .irq				(),
     .mipi_debug_in(),
    .mipi_debug_out()

);

wire scl_padoen_o;
wire sda_padoen_o;

wire cam_rst_p_live = ~arst_n;


reg [12:0] i2c_rst_cnt = 'd0;

always @( posedge CLK_5M or negedge reset_pixel_n )
begin
    if( !reset_pixel_n )
       i2c_rst_cnt <= 'd0;
    else 
       i2c_rst_cnt <= i2c_rst_cnt[12] ? i2c_rst_cnt : i2c_rst_cnt + 1'b1;
end
wire i2c_rst_n = i2c_rst_cnt[12];

i2c_master_ctrl_top u2_i2c_master_ctrl_top(
  /*i*/.clk			(CLK_5M		),
  /*i*/.rst_n			(i2c_rst_n		),
  /*i*/.scl_pad_i     (io_cam_scl_IN),//(1'b1),
  /*o*/.scl_pad_o     (io_cam_scl_OUT),
  /*o*/.scl_padoen_o  (scl_padoen_o),
  /*i*/.sda_pad_i     (io_cam_sda_IN),
  /*o*/.sda_pad_o     (io_cam_sda_OUT),
  /*o*/.sda_padoen_o  (sda_padoen_o),
  /*o*/.dbg_init_done (dbg_i2c_init_done),
  /*o*/.dbg_wr_en     (dbg_i2c_wr_en),
  /*o*/.dbg_rd_en     (dbg_i2c_rd_en),
  /*o*/.dbg_wr_done   (dbg_i2c_wr_done),
  /*o*/.dbg_rd_done   (dbg_i2c_rd_done),
  /*o*/.dbg_reg_addr  (dbg_i2c_reg_addr),
  /*o*/.dbg_reg_data  (dbg_i2c_reg_data),
  /*o*/.dbg_i2c_detail(dbg_i2c_detail)
  
  );
assign o_cam_rst_p = cam_rst_p_live;
assign io_cam_scl_OE = ~scl_padoen_o;
assign io_cam_sda_OE = ~sda_padoen_o;

generate
if (ENABLE_DEBUG_STICKY) begin : g_debug_sticky
(* syn_keep = "true", syn_preserve = "true" *) reg [15:0] dbg_i2c_startup_sticky = 16'd0;
(* syn_keep = "true", syn_preserve = "true" *) reg [7:0] dbg_byte_startup_sticky = 8'd0;
(* syn_keep = "true", syn_preserve = "true" *) reg [7:0] dbg_pixel_startup_sticky = 8'd0;
reg [5:0] dbg_i2c_sample_d = 6'd0;
reg [31:0] dbg_hs_sample_d = 32'd0;
reg [9:0] dbg_lp_sample_d = 10'd0;
reg [PACK_BIT-1:0] dbg_rx_data_d = {PACK_BIT{1'b0}};
reg dbg_i2c_sample_valid = 1'b0;
reg dbg_byte_sample_valid = 1'b0;
reg dbg_pixel_sample_valid = 1'b0;

wire [5:0] dbg_i2c_sample = {
  io_cam_scl_IN,
  io_cam_sda_IN,
  io_cam_scl_OUT,
  io_cam_sda_OUT,
  io_cam_scl_OE,
  io_cam_sda_OE
};
wire [31:0] dbg_hs_sample = {
  mipi_rx_dp03_HS_IN,
  mipi_rx_dp02_HS_IN,
  mipi_rx_dp01_HS_IN,
  mipi_rx_dp00_HS_IN
};
wire [9:0] dbg_lp_sample = {
  mipi_rx_ck0_LP_P_IN,
  mipi_rx_ck0_LP_N_IN,
  mipi_rx_dp00_LP_P_IN,
  mipi_rx_dp00_LP_N_IN,
  mipi_rx_dp01_LP_P_IN,
  mipi_rx_dp01_LP_N_IN,
  mipi_rx_dp02_LP_P_IN,
  mipi_rx_dp02_LP_N_IN,
  mipi_rx_dp03_LP_P_IN,
  mipi_rx_dp03_LP_N_IN
};
wire dbg_i2c_any_edge = dbg_i2c_sample_valid & |(dbg_i2c_sample ^ dbg_i2c_sample_d);
wire dbg_hs_any_edge = dbg_byte_sample_valid & |(dbg_hs_sample ^ dbg_hs_sample_d);
wire dbg_lp_any_edge = dbg_byte_sample_valid & |(dbg_lp_sample ^ dbg_lp_sample_d);
wire dbg_stream_on_write = dbg_i2c_wr_en &&
                           (dbg_i2c_reg_addr == 16'h0100) &&
                           (dbg_i2c_reg_data == 8'h01);

// Sticky debug bits. Pull i_sw[0] low at top level to clear them, then release
// it to recapture the startup sequence.
always @(posedge CLK_5M or negedge dbg_clear_n) begin
  if (!dbg_clear_n) begin
    dbg_i2c_startup_sticky <= 16'd0;
    dbg_i2c_sample_d <= 6'd0;
    dbg_i2c_sample_valid <= 1'b0;
  end else begin
    dbg_i2c_startup_sticky[0]  <= dbg_i2c_startup_sticky[0]  | i2c_rst_n;
    dbg_i2c_startup_sticky[1]  <= dbg_i2c_startup_sticky[1]  | dbg_i2c_init_done;
    dbg_i2c_startup_sticky[2]  <= dbg_i2c_startup_sticky[2]  | dbg_i2c_wr_en;
    dbg_i2c_startup_sticky[3]  <= dbg_i2c_startup_sticky[3]  | dbg_i2c_wr_done;
    dbg_i2c_startup_sticky[4]  <= dbg_i2c_startup_sticky[4]  | dbg_i2c_rd_en;
    dbg_i2c_startup_sticky[5]  <= dbg_i2c_startup_sticky[5]  | dbg_i2c_rd_done;
    dbg_i2c_startup_sticky[6]  <= dbg_i2c_startup_sticky[6]  |
                                  (dbg_i2c_sample_valid && (io_cam_scl_IN != dbg_i2c_sample_d[5]));
    dbg_i2c_startup_sticky[7]  <= dbg_i2c_startup_sticky[7]  |
                                  (dbg_i2c_sample_valid && (io_cam_sda_IN != dbg_i2c_sample_d[4]));
    dbg_i2c_startup_sticky[8]  <= dbg_i2c_startup_sticky[8]  |
                                  (dbg_i2c_sample_valid && (io_cam_scl_OE != dbg_i2c_sample_d[1]));
    dbg_i2c_startup_sticky[9]  <= dbg_i2c_startup_sticky[9]  |
                                  (dbg_i2c_sample_valid && (io_cam_sda_OE != dbg_i2c_sample_d[0]));
    dbg_i2c_startup_sticky[10] <= dbg_i2c_startup_sticky[10] | ~io_cam_scl_IN;
    dbg_i2c_startup_sticky[11] <= dbg_i2c_startup_sticky[11] | ~io_cam_sda_IN;
    dbg_i2c_startup_sticky[12] <= dbg_i2c_startup_sticky[12] | cam_rst_p_live;
    dbg_i2c_startup_sticky[13] <= dbg_i2c_startup_sticky[13] | ~cam_rst_p_live;
    dbg_i2c_startup_sticky[14] <= dbg_i2c_startup_sticky[14] | dbg_stream_on_write;
    dbg_i2c_startup_sticky[15] <= dbg_i2c_startup_sticky[15] | dbg_i2c_any_edge;
    dbg_i2c_sample_d <= dbg_i2c_sample;
    dbg_i2c_sample_valid <= 1'b1;
  end
end

always @(posedge mipi_rx_ck0_CLKOUT or negedge dbg_clear_n) begin
  if (!dbg_clear_n) begin
    dbg_byte_startup_sticky <= 8'd0;
    dbg_hs_sample_d <= 32'd0;
    dbg_lp_sample_d <= 10'd0;
    dbg_byte_sample_valid <= 1'b0;
  end else begin
    dbg_byte_startup_sticky[0] <= dbg_byte_startup_sticky[0] | mipi_dphy_rx_reset_byte_HS_n;
    dbg_byte_startup_sticky[1] <= dbg_byte_startup_sticky[1] | mipi_rx_ck0_HS_ENA;
    dbg_byte_startup_sticky[2] <= dbg_byte_startup_sticky[2] |
                                  (mipi_rx_dp00_HS_ENA | mipi_rx_dp01_HS_ENA |
                                   mipi_rx_dp02_HS_ENA | mipi_rx_dp03_HS_ENA);
    dbg_byte_startup_sticky[3] <= dbg_byte_startup_sticky[3] |
                                  (mipi_rx_ck0_HS_TERM | mipi_rx_dp00_HS_TERM |
                                   mipi_rx_dp01_HS_TERM | mipi_rx_dp02_HS_TERM |
                                   mipi_rx_dp03_HS_TERM);
    dbg_byte_startup_sticky[4] <= dbg_byte_startup_sticky[4] |
                                  ~(mipi_rx_dp00_FIFO_EMPTY & mipi_rx_dp01_FIFO_EMPTY &
                                    mipi_rx_dp02_FIFO_EMPTY & mipi_rx_dp03_FIFO_EMPTY);
    dbg_byte_startup_sticky[5] <= dbg_byte_startup_sticky[5] |
                                  (mipi_rx_dp00_FIFO_RD | mipi_rx_dp01_FIFO_RD |
                                   mipi_rx_dp02_FIFO_RD | mipi_rx_dp03_FIFO_RD);
    dbg_byte_startup_sticky[6] <= dbg_byte_startup_sticky[6] | dbg_hs_any_edge;
    dbg_byte_startup_sticky[7] <= dbg_byte_startup_sticky[7] | dbg_lp_any_edge;
    dbg_hs_sample_d <= dbg_hs_sample;
    dbg_lp_sample_d <= dbg_lp_sample;
    dbg_byte_sample_valid <= 1'b1;
  end
end

always @(posedge i_sysclk_div2 or negedge dbg_clear_n) begin
  if (!dbg_clear_n) begin
    dbg_pixel_startup_sticky <= 8'd0;
    dbg_rx_data_d <= {PACK_BIT{1'b0}};
    dbg_pixel_sample_valid <= 1'b0;
  end else begin
    dbg_pixel_startup_sticky[0] <= dbg_pixel_startup_sticky[0] | reset_pixel_n;
    dbg_pixel_startup_sticky[1] <= dbg_pixel_startup_sticky[1] | rx_out_vs;
    dbg_pixel_startup_sticky[2] <= dbg_pixel_startup_sticky[2] | rx_out_hs;
    dbg_pixel_startup_sticky[3] <= dbg_pixel_startup_sticky[3] | rx_out_de;
    dbg_pixel_startup_sticky[4] <= dbg_pixel_startup_sticky[4] | (datatype == 6'h2b);
    dbg_pixel_startup_sticky[5] <= dbg_pixel_startup_sticky[5] | (word_count != 16'd0);
    dbg_pixel_startup_sticky[6] <= dbg_pixel_startup_sticky[6] |
                                   (dbg_pixel_sample_valid && (rx_out_data != dbg_rx_data_d));
    dbg_pixel_startup_sticky[7] <= dbg_pixel_startup_sticky[7] | dbg_vid_frame_stable;
    dbg_rx_data_d <= rx_out_data;
    dbg_pixel_sample_valid <= 1'b1;
  end
end

assign dbg_mipi_startup_sticky = {
  dbg_pixel_startup_sticky,
  dbg_byte_startup_sticky,
  dbg_i2c_startup_sticky
};
end else begin : g_debug_sticky_disabled
assign dbg_mipi_startup_sticky = 32'd0;
end
endgenerate


vid_info_det # (
    .CLK_FREQ(32'd70_000_000)
  )
  vid_info_det_inst (
    .clk(i_sysclk_div2),
    .rst_n(reset_pixel_n),
    .i_vs(rx_out_vs),
    .i_hs(rx_out_hs),
    .i_de(rx_out_de),
    .frame_cnt_o(),
    .frame_stable(dbg_vid_frame_stable),
    .neg_vs_sync(),
    .neg_hs_sync(),
    .o_h_act(),
    .h_active_error(),
    .o_v_act(),
    .v_active_error(),
    .o_v_total(),
    .v_total_error(),
    .o_h_total(),
    .h_total_error(),
    .h_sync_error()
  );



endmodule
