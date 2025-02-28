module circular_convolution #(
    parameter QLEN        = 16,
              FRAC_SIZE   = 12,
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

    typedef enum logic[2:0] { 
        ST_IDLE     = 3'd0,
        ST_LOAD_ARG = 3'd1,
        ST_COMPUTE  = 3'd2
        // ST_FINISH   = 3'd3
    } state_t;
    state_t state, next_state;

    localparam PTR_W   = $clog2 (WINDOW_SIZE);
    localparam MAX_PTR = PTR_W' (WINDOW_SIZE - 1);

    logic [PTR_W - 1: 0]              result_ptr;
    logic                             finished;
    
    logic [WINDOW_SIZE-1:0][QLEN-1:0] shifted_data;

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
            // default: $error("illegal state %d", state);
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
        if (next_state == ST_LOAD_ARG)
            shifted_data <= in_data;
        else if (next_state == ST_COMPUTE)
            shifted_data <= { shifted_data[0], shifted_data[WINDOW_SIZE - 1: 1] };
    end

    //-----------------------------------------------------------------------------

    state_t              state_stage;
    logic [PTR_W - 1: 0] result_ptr_stage;
    logic                finished_stage;
    
    localparam SUM_SLICE_CNT = 16;
    localparam SUM_SLICE_SIZE = WINDOW_SIZE / SUM_SLICE_CNT;

    logic                    [QLEN-1:0] result;
    logic [SUM_SLICE_CNT-1:0][QLEN-1:0] sum_stage_r, sum_stage;

    // Immidiate check that window size is be greater or equal 
    // to the accumulator size
    // assert (SUM_SLICE_CNT <= WINDOW_SIZE);
    // assert (WINDOW_SIZE % SUM_SLICE_CNT == 0);

    logic signed [2*QLEN-1:0] wide_mult;
    logic signed [QLEN-1:0] sweight, sdata;

    always_comb
    begin
        for (int i = 0; i < SUM_SLICE_CNT; i ++)
        begin
            sum_stage[i] = '0;
            for (int j = 0; j < SUM_SLICE_SIZE; j += SUM_SLICE_CNT)
            begin
                sweight = $signed (weights[j]);
                sdata   = $signed (shifted_data[j]);
                wide_mult = sweight * sdata;
                sum_stage[i] += wide_mult[FRAC_SIZE +: QLEN];
            end
        end
    end

    always_ff @ (posedge clk)
    begin
        sum_stage_r <= sum_stage;
    end

    always_comb
    begin
        result = '0;
        for (int i = 0; i < SUM_SLICE_CNT; i ++)
        begin
            result += sum_stage_r[i];
        end
    end

    always_ff @ (posedge clk)
    begin
        if (rst)
        begin
            state_stage      <= ST_IDLE;
            result_ptr_stage <= '0;
            finished_stage   <= '0;
        end
        else
        begin
            state_stage      <= state;
            result_ptr_stage <= result_ptr;
            finished_stage   <= finished;
        end
    end

    always_ff @ (posedge clk)
    begin
        if (state_stage == ST_COMPUTE)
            out_data[result_ptr_stage] <= result;
    end

    always_ff @ (posedge clk)
    begin
        if (rst)
            out_valid <= '0;
        else
            out_valid <= finished_stage;        
    end

endmodule
