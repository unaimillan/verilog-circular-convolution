module fxp_mult
# (
    parameter int QLEN = 16,
              int FRAC_SIZE = 12,
              int INT_SIZE  = QLEN - FRAC_SIZE
)
(
    input  signed [QLEN-1:0] a,
    input  signed [QLEN-1:0] b,
    output signed [QLEN-1:0] res
);

    logic signed [2*QLEN-1:0] mult;
    
    assign mult = a * b;
    assign res = mult[2*QLEN - 1 - INT_SIZE -: QLEN];
    // assign res = mult[FRAC_SIZE +: QLEN];

endmodule
