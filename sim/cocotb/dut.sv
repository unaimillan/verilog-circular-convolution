`timescale 1ns / 1ps

module dut
#(
    parameter XLEN  = 8,
              WIDTH = 16
)
(
    input                            clk,
    input                            rst,

    input [WIDTH - 1:0][XLEN - 1:0]  weights,

    input                            up_valid,
    input               [XLEN - 1:0] up_data,

    output                           down_valid,
    output              [XLEN - 1:0] down_data
);

    initial $dumpvars;

    logic in_valid, out_valid;
    logic [WIDTH - 1:0][XLEN - 1:0] in_data, out_data;

    serial_to_parallel #(
        .XLEN  ( XLEN  ),
        .WIDTH ( WIDTH )
    ) i_stp (
        .clk ( clk ),
        .rst ( rst ),

        .serial_valid   ( up_valid ),
        .serial_data    ( up_data  ),

        .parallel_valid ( in_valid ),
        .parallel_data  ( in_data  )
    );

    circular_convolution #( .QLEN(XLEN), .WINDOW_SIZE(WIDTH) ) i_cc
    (
        .clk ( clk ),
        .rst ( rst ),

        .weights  ( weights ),

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

        .serial_valid   ( down_valid ),
        .serial_data    ( down_data  )
    );

endmodule
