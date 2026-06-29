/*-------------------------------------------------------------------------
CONFIDENTIAL IN CONFIDENCE
This confidential and proprietary software may be only used as authorized
by a licensing agreement from CrazyBingo (Thereturnofbingo).
In the event of publication, the following notice is applicable:
Copyright (C) 2011-201x CrazyBingo Corporation
The entire notice above must be reproduced on all authorized copies.
Author				:		CrazyBingo
Technology blogs 	: 		www.crazyfpga.com
Eamil Address 		: 		crazyfpga@qq.com
Filename			:		sensor_frame_count.v
Date				:		2019-06-01
Version				:		1.0
Description			:		Detect the frame rate of sensor
Modification History	:
Date			By			Version		Change Description
===========================================================================
19/06/01		CrazyBingo	1.0			Original
--------------------------------------------------------------------------*/
`timescale 1ns/1ns
module  sensor_frame_count
#(
	parameter			CLOCK_MAIN  =	100_000000														
)
(
	//global clock
	input				clk,			    //System Main clock
	input				rst_n,				//global reset
    
    //sensor frame signal
    input               cmos_vsync,
    
    //sensor frame count
    output  reg [7:0]   cmos_fps_rate
);

//-----------------------------------------------------
//Sensor HS & VS Vaild Capture
/**************************************************					       
         _________________________________
VS______|                                 |________
	            _______	 	     _______
HS_____________|       |__...___|       |____________
**************************************************/
//-------------------------------------------------------------
//sync the frame vsync and href signal and generate frame begin & end signal
reg	[1:0]	cmos_vsync_r;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		cmos_vsync_r <= 0;
	else
		cmos_vsync_r <= {cmos_vsync_r[0], cmos_vsync};
end
//wire	cmos_vsync_begin 	= 	(~cmos_vsync_r[1] & cmos_vsync_r[0]) ? 1'b1 : 1'b0;	
wire	cmos_vsync_end 		= 	(cmos_vsync_r[1] & ~cmos_vsync_r[0]) ? 1'b1 : 1'b0;	


//----------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------
//Delay 2s for cmos fps counter
localparam	DELAY_TOP = 2 * CLOCK_MAIN;	//2s delay
reg	[27:0]	delay_cnt;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		delay_cnt <= 0;
	else if(delay_cnt < DELAY_TOP - 1'b1)
		delay_cnt <= delay_cnt + 1'b1;
	else
		delay_cnt <= 0;
end
wire	delay_2s = (delay_cnt == DELAY_TOP - 1'b1) ? 1'b1 : 1'b0;

//-------------------------------------
//cmos image output rate counter
reg	[8:0]	cmos_fps_cnt;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		cmos_fps_cnt <= 0;
		cmos_fps_rate <= 0;
		end
	else if(delay_2s == 1'b0)	//time is not reached
		begin
		cmos_fps_cnt <= cmos_vsync_end ? cmos_fps_cnt + 1'b1 : cmos_fps_cnt;
		cmos_fps_rate <= cmos_fps_rate;
		end
	else	//time up
		begin
		cmos_fps_cnt <= 0;
		cmos_fps_rate <= cmos_fps_cnt[8:1];	//divide by 2
		end
end

endmodule
