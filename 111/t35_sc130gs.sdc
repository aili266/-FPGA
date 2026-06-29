


# Efinity Interface Designer SDC
# Version: 2022.1.226.4.3
# Date: 2022-12-31 11:58

# Copyright (C) 2017 - 2022 Efinix Inc. All rights reserved.

# Device: T35F324
# Project: T35_Sensor_DDR3_LCD_Test
# Timing Model: C4 (final)
#
# NOTE: filename is legacy ("sc130gs"); the active design uses an SC2210 sensor
# (4-lane, 1920x1080, I2C dev 0x60) on MIPI0. Constraints here are sensor-
# agnostic. HDMI clocks retuned to 25.2 MHz for the 640x480 result UI.


# Set Clock Groups
set_clock_groups -group {mipi_clkesc_i mipi_clkcal_i}
set_clock_groups -group {mipi_pixclk_i}
set_clock_groups -group {Axi0Clk}
set_clock_groups -group {clk_cmos}
set_clock_groups -group {hdmi_clk1x_i hdmi_clk2x_i hdmi_clk5x_i}
set_clock_groups -group {tx_slowclk tx_fastclk}

# PLL Constraints
#################
create_clock -period 50.0000 mipi_clkesc_i
create_clock -period 10.0000 mipi_clkcal_i
create_clock -period 10 mipi_pixclk_i
# create_clock -period 2.5063 Axi0Clk
create_clock -period 37.5940 clk_cmos
# HDMI re-tuned to a 640x480@60 pixel clock (25.2 MHz) for hdmi_result_ui.
# Enter in Efinity HdmiPLL (PLL_BR1): ref=tx_slowclk(48MHz), mult=21, pre=1,
# post=4, out_div 1x=10 / 2x=5 / 5x=2  -> 25.2 / 50.4 / 126 MHz (VCO=1008MHz).
# (Assumes tx_slowclk stays 48MHz on the new board; re-check after crystal map.)
create_clock -period 39.6825 hdmi_clk1x_i
create_clock -period 19.8413 hdmi_clk2x_i
create_clock -waveform {1.9841 5.9524} -period 7.9365 hdmi_clk5x_i
create_clock -period 10.4167 Axi0Clk
create_clock -period 20.8333 tx_slowclk
create_clock -waveform {1.4881 4.4643} -period 5.9524 tx_fastclk

# The I2C controller runs on Axi0Clk and only crosses into the MIPI domain
# through explicit synchronizer registers in top_t35.
set_false_path -from [get_clocks Axi0Clk] -to [get_clocks mipi_pixclk_i]
set_false_path -from [get_clocks mipi_pixclk_i] -to [get_clocks Axi0Clk]


# GPIO Constraints
####################
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {AxiPllClkIn}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {AxiPllClkIn}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_pclk}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_pclk}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {DdrPllClkIn}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {DdrPllClkIn}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {LED[0]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {LED[0]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {LED[1]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {LED[1]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {LED[2]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {LED[2]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {LED[3]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {LED[3]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {LED[4]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {LED[4]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {LED[5]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {LED[5]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {LED[6]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {LED[6]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {LED[7]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {LED[7]}]

# LVDS RX GPIO Constraints
############################
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {lcd_pwm}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {lcd_pwm}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {mipi_trig_o[0]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {mipi_trig_o[0]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {mipi_trig_o[1]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {mipi_trig_o[1]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {mipi0_scl_i}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {mipi0_scl_i}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {mipi0_scl_o}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {mipi0_scl_o}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {mipi0_scl_oe}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {mipi0_scl_oe}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {mipi0_sda_i}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {mipi0_sda_i}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {mipi0_sda_o}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {mipi0_sda_o}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {mipi0_sda_oe}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {mipi0_sda_oe}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {mipi1_scl_i}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {mipi1_scl_i}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {mipi1_scl_o}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {mipi1_scl_o}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {mipi1_scl_oe}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {mipi1_scl_oe}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {mipi1_sda_i}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {mipi1_sda_i}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {mipi1_sda_o}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {mipi1_sda_o}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {mipi1_sda_oe}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {mipi1_sda_oe}]

# LVDS Rx Constraints
####################

# LVDS TX GPIO Constraints
############################
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_data[0]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_data[0]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_data[1]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_data[1]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_data[2]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_data[2]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_data[3]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_data[3]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_data[4]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_data[4]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_data[5]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_data[5]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_data[6]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_data[6]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_data[7]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_data[7]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_href}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_href}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_vsync}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_vsync}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_ctl0}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_ctl0}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_ctl1}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_ctl1}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_ctl2}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_ctl2}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_ctl3}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_ctl3}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_sclk}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_sclk}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_sdat_IN}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_sdat_IN}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_sdat_OUT}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_sdat_OUT}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cmos_sdat_OE}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cmos_sdat_OE}]

# LVDS Tx Constraints
####################
set_output_delay -clock hdmi_clk2x_i -max -4.230 [get_ports {hdmi_tx0_o[4] hdmi_tx0_o[3] hdmi_tx0_o[2] hdmi_tx0_o[1] hdmi_tx0_o[0]}]
set_output_delay -clock hdmi_clk2x_i -min -2.235 [get_ports {hdmi_tx0_o[4] hdmi_tx0_o[3] hdmi_tx0_o[2] hdmi_tx0_o[1] hdmi_tx0_o[0]}]
set_output_delay -clock hdmi_clk2x_i -max -4.230 [get_ports {hdmi_tx1_o[4] hdmi_tx1_o[3] hdmi_tx1_o[2] hdmi_tx1_o[1] hdmi_tx1_o[0]}]
set_output_delay -clock hdmi_clk2x_i -min -2.235 [get_ports {hdmi_tx1_o[4] hdmi_tx1_o[3] hdmi_tx1_o[2] hdmi_tx1_o[1] hdmi_tx1_o[0]}]
set_output_delay -clock hdmi_clk2x_i -max -4.230 [get_ports {hdmi_tx2_o[4] hdmi_tx2_o[3] hdmi_tx2_o[2] hdmi_tx2_o[1] hdmi_tx2_o[0]}]
set_output_delay -clock hdmi_clk2x_i -min -2.235 [get_ports {hdmi_tx2_o[4] hdmi_tx2_o[3] hdmi_tx2_o[2] hdmi_tx2_o[1] hdmi_tx2_o[0]}]
set_output_delay -clock hdmi_clk2x_i -max -4.230 [get_ports {hdmi_txc_o[4] hdmi_txc_o[3] hdmi_txc_o[2] hdmi_txc_o[1] hdmi_txc_o[0]}]
set_output_delay -clock hdmi_clk2x_i -min -2.235 [get_ports {hdmi_txc_o[4] hdmi_txc_o[3] hdmi_txc_o[2] hdmi_txc_o[1] hdmi_txc_o[0]}]

# MIPI RX Constraints
#####################################
set_output_delay -clock mipi_pixclk_i -max -3.746 [get_ports {mipi_rx_0_VC_ENA_o[3] mipi_rx_0_VC_ENA_o[2] mipi_rx_0_VC_ENA_o[1] mipi_rx_0_VC_ENA_o[0]}]
set_output_delay -clock mipi_pixclk_i -min -2.223 [get_ports {mipi_rx_0_VC_ENA_o[3] mipi_rx_0_VC_ENA_o[2] mipi_rx_0_VC_ENA_o[1] mipi_rx_0_VC_ENA_o[0]}]
set_output_delay -clock mipi_pixclk_i -max -4.197 [get_ports {mipi_rx_0_CLEAR}]
set_output_delay -clock mipi_pixclk_i -min -2.311 [get_ports {mipi_rx_0_CLEAR}]
set_input_delay -clock mipi_pixclk_i -max 5.394 [get_ports {mipi_rx_0_VSYNC_i[3] mipi_rx_0_VSYNC_i[2] mipi_rx_0_VSYNC_i[1] mipi_rx_0_VSYNC_i[0]}]
set_input_delay -clock mipi_pixclk_i -min 2.697 [get_ports {mipi_rx_0_VSYNC_i[3] mipi_rx_0_VSYNC_i[2] mipi_rx_0_VSYNC_i[1] mipi_rx_0_VSYNC_i[0]}]
set_input_delay -clock mipi_pixclk_i -max 5.388 [get_ports {mipi_rx_0_HSYNC_i[3] mipi_rx_0_HSYNC_i[2] mipi_rx_0_HSYNC_i[1] mipi_rx_0_HSYNC_i[0]}]
set_input_delay -clock mipi_pixclk_i -min 2.694 [get_ports {mipi_rx_0_HSYNC_i[3] mipi_rx_0_HSYNC_i[2] mipi_rx_0_HSYNC_i[1] mipi_rx_0_HSYNC_i[0]}]
set_input_delay -clock mipi_pixclk_i -max 5.242 [get_ports {mipi_rx_0_VALID_i}]
set_input_delay -clock mipi_pixclk_i -min 2.621 [get_ports {mipi_rx_0_VALID_i}]
set_input_delay -clock mipi_pixclk_i -max 5.312 [get_ports {mipi_rx_0_CNT_i[3] mipi_rx_0_CNT_i[2] mipi_rx_0_CNT_i[1] mipi_rx_0_CNT_i[0]}]
set_input_delay -clock mipi_pixclk_i -min 2.656 [get_ports {mipi_rx_0_CNT_i[3] mipi_rx_0_CNT_i[2] mipi_rx_0_CNT_i[1] mipi_rx_0_CNT_i[0]}]
set_input_delay -clock mipi_pixclk_i -max 5.340 [get_ports {mipi_rx_0_DATA_i[*]}]
set_input_delay -clock mipi_pixclk_i -min 2.670 [get_ports {mipi_rx_0_DATA_i[*]}]
set_input_delay -clock mipi_pixclk_i -max 5.257 [get_ports {mipi_rx_0_ERROR[*]}]
set_input_delay -clock mipi_pixclk_i -min 2.628 [get_ports {mipi_rx_0_ERROR[*]}]
set_input_delay -clock mipi_pixclk_i -max 5.255 [get_ports {mipi_rx_0_ULPS_CLK}]
set_input_delay -clock mipi_pixclk_i -min 2.627 [get_ports {mipi_rx_0_ULPS_CLK}]
set_input_delay -clock mipi_pixclk_i -max 5.264 [get_ports {mipi_rx_0_ULPS[3] mipi_rx_0_ULPS[2] mipi_rx_0_ULPS[1] mipi_rx_0_ULPS[0]}]
set_input_delay -clock mipi_pixclk_i -min 2.632 [get_ports {mipi_rx_0_ULPS[3] mipi_rx_0_ULPS[2] mipi_rx_0_ULPS[1] mipi_rx_0_ULPS[0]}]
set_output_delay -clock mipi_pixclk_i -max -3.746 [get_ports {mipi_rx_1_VC_ENA_o[3] mipi_rx_1_VC_ENA_o[2] mipi_rx_1_VC_ENA_o[1] mipi_rx_1_VC_ENA_o[0]}]
set_output_delay -clock mipi_pixclk_i -min -2.223 [get_ports {mipi_rx_1_VC_ENA_o[3] mipi_rx_1_VC_ENA_o[2] mipi_rx_1_VC_ENA_o[1] mipi_rx_1_VC_ENA_o[0]}]
set_output_delay -clock mipi_pixclk_i -max -4.197 [get_ports {mipi_rx_1_CLEAR}]
set_output_delay -clock mipi_pixclk_i -min -2.311 [get_ports {mipi_rx_1_CLEAR}]
set_input_delay -clock mipi_pixclk_i -max 5.394 [get_ports {mipi_rx_1_VSYNC_i[3] mipi_rx_1_VSYNC_i[2] mipi_rx_1_VSYNC_i[1] mipi_rx_1_VSYNC_i[0]}]
set_input_delay -clock mipi_pixclk_i -min 2.697 [get_ports {mipi_rx_1_VSYNC_i[3] mipi_rx_1_VSYNC_i[2] mipi_rx_1_VSYNC_i[1] mipi_rx_1_VSYNC_i[0]}]
set_input_delay -clock mipi_pixclk_i -max 5.388 [get_ports {mipi_rx_1_HSYNC_i[3] mipi_rx_1_HSYNC_i[2] mipi_rx_1_HSYNC_i[1] mipi_rx_1_HSYNC_i[0]}]
set_input_delay -clock mipi_pixclk_i -min 2.694 [get_ports {mipi_rx_1_HSYNC_i[3] mipi_rx_1_HSYNC_i[2] mipi_rx_1_HSYNC_i[1] mipi_rx_1_HSYNC_i[0]}]
set_input_delay -clock mipi_pixclk_i -max 5.242 [get_ports {mipi_rx_1_VALID_i}]
set_input_delay -clock mipi_pixclk_i -min 2.621 [get_ports {mipi_rx_1_VALID_i}]
set_input_delay -clock mipi_pixclk_i -max 5.312 [get_ports {mipi_rx_1_CNT_i[3] mipi_rx_1_CNT_i[2] mipi_rx_1_CNT_i[1] mipi_rx_1_CNT_i[0]}]
set_input_delay -clock mipi_pixclk_i -min 2.656 [get_ports {mipi_rx_1_CNT_i[3] mipi_rx_1_CNT_i[2] mipi_rx_1_CNT_i[1] mipi_rx_1_CNT_i[0]}]
set_input_delay -clock mipi_pixclk_i -max 5.340 [get_ports {mipi_rx_1_DATA_i[*]}]
set_input_delay -clock mipi_pixclk_i -min 2.670 [get_ports {mipi_rx_1_DATA_i[*]}]
set_input_delay -clock mipi_pixclk_i -max 5.257 [get_ports {mipi_rx_1_ERROR[*]}]
set_input_delay -clock mipi_pixclk_i -min 2.628 [get_ports {mipi_rx_1_ERROR[*]}]
set_input_delay -clock mipi_pixclk_i -max 5.255 [get_ports {mipi_rx_1_ULPS_CLK}]
set_input_delay -clock mipi_pixclk_i -min 2.627 [get_ports {mipi_rx_1_ULPS_CLK}]
set_input_delay -clock mipi_pixclk_i -max 5.264 [get_ports {mipi_rx_1_ULPS[3] mipi_rx_1_ULPS[2] mipi_rx_1_ULPS[1] mipi_rx_1_ULPS[0]}]
set_input_delay -clock mipi_pixclk_i -min 2.632 [get_ports {mipi_rx_1_ULPS[3] mipi_rx_1_ULPS[2] mipi_rx_1_ULPS[1] mipi_rx_1_ULPS[0]}]

# DDR Constraints
#####################
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_AADDR_0[*]}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_AADDR_0[*]}]
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_ABURST_0[1] DdrCtrl_ABURST_0[0]}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_ABURST_0[1] DdrCtrl_ABURST_0[0]}]
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_AID_0[*]}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_AID_0[*]}]
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_ALEN_0[*]}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_ALEN_0[*]}]
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_ALOCK_0[1] DdrCtrl_ALOCK_0[0]}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_ALOCK_0[1] DdrCtrl_ALOCK_0[0]}]
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_ASIZE_0[2] DdrCtrl_ASIZE_0[1] DdrCtrl_ASIZE_0[0]}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_ASIZE_0[2] DdrCtrl_ASIZE_0[1] DdrCtrl_ASIZE_0[0]}]
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_ATYPE_0}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_ATYPE_0}]
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_AVALID_0}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_AVALID_0}]
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_BREADY_0}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_BREADY_0}]
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_RREADY_0}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_RREADY_0}]
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_WDATA_0[*]}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_WDATA_0[*]}]
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_WID_0[*]}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_WID_0[*]}]
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_WLAST_0}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_WLAST_0}]
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_WSTRB_0[*]}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_WSTRB_0[*]}]
set_output_delay -clock Axi0Clk -max -1.810 [get_ports {DdrCtrl_WVALID_0}]
set_output_delay -clock Axi0Clk -min -2.655 [get_ports {DdrCtrl_WVALID_0}]
set_input_delay -clock Axi0Clk -max 7.310 [get_ports {DdrCtrl_AREADY_0}]
set_input_delay -clock Axi0Clk -min 3.655 [get_ports {DdrCtrl_AREADY_0}]
set_input_delay -clock Axi0Clk -max 7.310 [get_ports {DdrCtrl_BID_0[*]}]
set_input_delay -clock Axi0Clk -min 3.655 [get_ports {DdrCtrl_BID_0[*]}]
set_input_delay -clock Axi0Clk -max 7.310 [get_ports {DdrCtrl_BVALID_0}]
set_input_delay -clock Axi0Clk -min 3.655 [get_ports {DdrCtrl_BVALID_0}]
set_input_delay -clock Axi0Clk -max 7.310 [get_ports {DdrCtrl_RDATA_0[*]}]
set_input_delay -clock Axi0Clk -min 3.655 [get_ports {DdrCtrl_RDATA_0[*]}]
set_input_delay -clock Axi0Clk -max 7.310 [get_ports {DdrCtrl_RID_0[*]}]
set_input_delay -clock Axi0Clk -min 3.655 [get_ports {DdrCtrl_RID_0[*]}]
set_input_delay -clock Axi0Clk -max 7.310 [get_ports {DdrCtrl_RLAST_0}]
set_input_delay -clock Axi0Clk -min 3.655 [get_ports {DdrCtrl_RLAST_0}]
set_input_delay -clock Axi0Clk -max 7.310 [get_ports {DdrCtrl_RRESP_0[1] DdrCtrl_RRESP_0[0]}]
set_input_delay -clock Axi0Clk -min 3.655 [get_ports {DdrCtrl_RRESP_0[1] DdrCtrl_RRESP_0[0]}]
set_input_delay -clock Axi0Clk -max 7.310 [get_ports {DdrCtrl_RVALID_0}]
set_input_delay -clock Axi0Clk -min 3.655 [get_ports {DdrCtrl_RVALID_0}]
set_input_delay -clock Axi0Clk -max 7.310 [get_ports {DdrCtrl_WREADY_0}]
set_input_delay -clock Axi0Clk -min 3.655 [get_ports {DdrCtrl_WREADY_0}]
