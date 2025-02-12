`timescale 1ns / 1ps

module dut();

    initial $dumpvars;

    localparam int QLEN = 16;
    localparam int FRAC_SIZE = 12;
    localparam int INT_SIZE  = QLEN - FRAC_SIZE;

    logic [QLEN-1:0] a;
    logic [QLEN-1:0] b;
    logic [QLEN-1:0] res;

    logic [QLEN-1:0] expected_res = '0;
    
    fxp_mult # (
        .QLEN( QLEN ),
        .FRAC_SIZE( FRAC_SIZE )
    ) i_mult 
    (
        .a( a ),
        .b( b ),
        .res( res )
    );

endmodule
