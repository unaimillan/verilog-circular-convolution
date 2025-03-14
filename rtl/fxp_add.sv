module fxp_add# (
     parameter  QLEN = 16,
                FRAC_SIZE = 12,
                INT_SIZE  = QLEN - FRAC_SIZE
)
(
    input  signed [QLEN-1:0] a,
    input  signed [QLEN-1:0] b,
    output signed [QLEN-1:0] res
);
    
    assign res = a + b;

endmodule
