module serial_to_parallel
# (
    parameter XLEN  = 8,
              WIDTH = 16
)
(
    input                                  clk,
    input                                  rst,

    input                                  serial_valid,
    input                     [XLEN - 1:0] serial_data,

    output logic                           parallel_valid,
    output logic [WIDTH - 1:0][XLEN - 1:0] parallel_data
);
    localparam PTR_W   = $clog2 (WIDTH),
               MAX_PTR = PTR_W' (WIDTH - 1);

    logic [PTR_W - 1:0] ptr;

    always_ff @ (posedge clk)
        if (rst)
            ptr <= '0;
        else if (serial_valid)
            ptr <= (ptr == MAX_PTR) ? '0 : ptr + 1'b1;

    always_ff @ (posedge clk)
        if (rst)
            parallel_valid <= 1'b0;
        else
            parallel_valid <= serial_valid & (ptr == MAX_PTR);

    always_ff @ (posedge clk)
        if (serial_valid)
            parallel_data [ptr] <= serial_data;

endmodule
