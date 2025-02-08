module parallel_to_serial
# (
    parameter XLEN  = 8,
              WIDTH = 16
)
(
    input                                  clk,
    input                                  rst,

    input                                  parallel_valid,
    input        [WIDTH - 1:0][XLEN - 1:0] parallel_data,

    output logic                           serial_valid,
    output logic              [XLEN - 1:0] serial_data
);

    localparam PTR_W   = $clog2 (WIDTH),
               MAX_PTR = PTR_W' (WIDTH - 1);

    logic [PTR_W - 1:0] ptr;
    
    logic [WIDTH - 1:0][XLEN - 1:0] parallel_data_r;

    always_ff @ (posedge clk)
        if (parallel_valid)
            parallel_data_r <= parallel_data;

    always_ff @ (posedge clk)
        if (rst)
            ptr <= '0;
        else if (parallel_valid | ptr != '0)
            ptr <= (ptr == MAX_PTR) ? '0 : ptr + 1'b1;
    
    assign serial_valid = parallel_valid | ptr != '0;
    assign serial_data  = parallel_data_r[ptr];

endmodule
