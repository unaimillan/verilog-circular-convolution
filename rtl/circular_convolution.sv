module circular_convolution #(
    parameter QLEN        = 16,
              WINDOW_SIZE = 16
)
(
    input                                    clk,
    input                                    rst,

    input        [WINDOW_SIZE-1:0][QLEN-1:0] weights,

    input                                    in_valid,
    input        [WINDOW_SIZE-1:0][QLEN-1:0] in_data,

    output logic                             out_valid,
    output logic [WINDOW_SIZE-1:0][QLEN-1:0] out_data
);

    //-----------------------------------------------------------------------------
    // Definitions
    //-----------------------------------------------------------------------------

    enum logic[2:0] { 
        ST_IDLE     = 3'd0,
        ST_LOAD_ARG = 3'd1,
        ST_COMPUTE  = 3'd2
        // ST_FINISH   = 3'd3
    } state, next_state;

    localparam PTR_W = $clog2(WINDOW_SIZE);
    localparam MAX_PTR = PTR_W' (WINDOW_SIZE - 1);

    logic [PTR_W - 1: 0]              result_ptr;
    logic                             finished;
    
    logic [WINDOW_SIZE-1:0][QLEN-1:0] shifted_data;
    logic                  [QLEN-1:0] cur_result;

    //-----------------------------------------------------------------------------
    // Control FSM
    //-----------------------------------------------------------------------------

    always_comb begin
        next_state = state;

        case (state)
            ST_IDLE: 
            begin
                if (in_valid)
                    next_state = ST_LOAD_ARG;
            end
            ST_LOAD_ARG:
            begin
                next_state = ST_COMPUTE;
            end
            ST_COMPUTE:
            begin
                if (finished)
                    next_state = ST_IDLE;
            end
        endcase
    end

    always_ff @ (posedge clk)
        if (rst)
            state <= ST_IDLE;
        else
            state <= next_state;

    //-----------------------------------------------------------------------------
    // Circular Convolution
    //-----------------------------------------------------------------------------

    always_ff @ (posedge clk) begin
        if (rst)
            result_ptr <= '0;
        else if (state == ST_COMPUTE)
            result_ptr <= (result_ptr == MAX_PTR) ? '0 : result_ptr + 1'b1;
    end

    assign finished = result_ptr == MAX_PTR;

    //-----------------------------------------------------------------------------

    always_ff @ (posedge clk) begin
        if (in_valid & next_state == ST_COMPUTE)
            shifted_data <= in_data;
        else if (next_state == ST_COMPUTE)
            shifted_data <= { shifted_data[0], shifted_data[WINDOW_SIZE - 1: 1] };
    end

    //-----------------------------------------------------------------------------

    always_comb begin
        cur_result = '0;

        for (int i = 0; i < WINDOW_SIZE; i ++)
            cur_result += weights[i] * shifted_data[i];
    end

    always_ff @ (posedge clk) begin
        if (next_state == ST_COMPUTE)
            out_data[result_ptr] <= cur_result;
    end

    always_ff @ (posedge clk) begin
        if (rst)
            out_valid <= '0;
        else
            out_valid <= finished;        
    end

endmodule
