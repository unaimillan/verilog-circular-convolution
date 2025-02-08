module fpga_top(
	input 		          		MAX10_CLK1_50,

	output		    [12:0]		DRAM_ADDR,
	output		     [1:0]		DRAM_BA,
	output		          		DRAM_CAS_N,
	output		          		DRAM_CKE,
	output		          		DRAM_CLK,
	output		          		DRAM_CS_N,
	inout 		    [15:0]		DRAM_DQ,
	output		          		DRAM_LDQM,
	output		          		DRAM_RAS_N,
	output		          		DRAM_UDQM,
	output		          		DRAM_WE_N,

	output		     [7:0]		HEX0,
	output		     [7:0]		HEX1,
	output		     [7:0]		HEX2,
	output		     [7:0]		HEX3,
	output		     [7:0]		HEX4,
	output		     [7:0]		HEX5,

	input 		     [1:0]		KEY,
	output		     [9:0]		LEDR,
	input 		     [9:0]		SW,

	output		          		VGA_VS,
	output		          		VGA_HS,
	output		     [3:0]		VGA_R,
	output		     [3:0]		VGA_G,
	output		     [3:0]		VGA_B,

	output		          		GSENSOR_CS_N,
	input 		     [2:1]		GSENSOR_INT,
	output		          		GSENSOR_SCLK,
	inout 		          		GSENSOR_SDI,
	inout 		          		GSENSOR_SDO,
	inout 		    [15:0]		ARDUINO_IO,
	inout 		          		ARDUINO_RESET_N,
	
	inout 		    [35:0]		GPIO
);
	wire clk = MAX10_CLK1_50;
	wire rst = SW[9];

	localparam XLEN  = 16,
			   WIDTH = 128;
	
	logic in_valid, out_valid;
	logic [WIDTH - 1:0][XLEN - 1:0] in_data, out_data;

    serial_to_parallel #(
		.XLEN  ( XLEN  ),
		.WIDTH ( WIDTH )
	) i_stp (
		.clk ( clk ),
		.rst ( rst ),

		.serial_valid   ( KEY  [0]    ),
		.serial_data    ( GPIO [15:0] ),

		.parallel_valid ( in_valid ),
		.parallel_data  ( in_data  ),
    );

	circular_convolution #( .QLEN(XLEN), .WINDOW_SIZE(WIDTH) ) i_cc
	(
		.clk ( clk ),
    	.rst ( rst ),

		.weights  ( { 16'hA, 16'h1, 16'hF, 16'h5, 16'hA, 16'h1, 16'hF, 16'h5, 16'hA, 16'h1, 16'hF, 16'h5, 16'hA, 16'h1, 16'hF, 16'h5,
					  16'h1, 16'hF, 16'h5, 16'hA, 16'h1, 16'hF, 16'h5, 16'hA, 16'h1, 16'hF, 16'h5, 16'hA, 16'h1, 16'hF, 16'h5, 16'hA, 
					  16'hF, 16'h5, 16'hA, 16'h1, 16'hF, 16'h5, 16'hA, 16'h1, 16'hF, 16'h5, 16'hA, 16'h1, 16'hF, 16'h5, 16'hA, 16'h1,
					  16'h5, 16'hA, 16'h1, 16'hF, 16'h5, 16'hA, 16'h1, 16'hF, 16'h5, 16'hA, 16'h1, 16'hF, 16'h5, 16'hA, 16'h1, 16'hF,
				  } ),

		.in_valid ( in_valid ),
    	.in_data  ( in_data  ),
    
		.out_valid ( out_valid ),
    	.out_data  ( out_data  )
	);
	
    parallel_to_serial #(
		.XLEN  ( XLEN  ),
		.WIDTH ( WIDTH )
	) i_pts (
		.clk ( clk ),
		.rst ( rst ),

		.parallel_valid ( out_valid ),
		.parallel_data  ( out_data  ),

		.serial_valid   ( LEDR[0] ),
		.serial_data    ( { HEX1, HEX0 } ),
    );

endmodule
