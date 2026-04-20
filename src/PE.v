module PE (
    input wire clk,
    input wire rst_n,
    
    // Data inputs
    input wire [31:0] data_in, 
    output wire in_read,
    input wire in_empty,
    input wire load_weights,
    

    // Data outputs
    output wire [31:0] psum_out,
    output wire out_valid,
    input wire out_full
);

    reg [7:0] weights [0:2];
    reg [7:0] ifmap [0:65];
    reg [31:0] partial_sums [0:63];
    
    // Computation state
    reg [5:0] compute_idx;
    reg [1:0] weight_idx;
    
    // I/O counter  
    reg [5:0] ifmap_load_cnt;
    reg [5:0] psum_out_cnt;
    reg compute_caught_up;
    
    // MAC computation
    wire [15:0] mult_result;
    wire [5:0] distance;
    // Multiplier for one weight at a time
    assign mult_result = ifmap[{1'b0, compute_idx} + weight_idx] * weights[weight_idx];
    assign psum_out = partial_sums[psum_out_cnt];
    assign out_valid = (!out_full && ((psum_out_cnt != compute_idx) || compute_caught_up));
    assign in_read = (distance < 60) && !in_empty;
    
    // State machine for computation
    localparam IDLE = 1'b0;
    localparam COMPUTE = 1'b1;
    
    reg state;

    
    assign distance = (ifmap_load_cnt - compute_idx);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ifmap_load_cnt <= 0;
            psum_out_cnt <= 0;
            compute_idx <= 0;
            weight_idx <= 0;
            state <= IDLE;
            ifmap[0] <= 0;
            ifmap[65] <= 0; 
            compute_caught_up <= 0;
            
        end else begin

            // Input Logic
            if (!in_empty) begin
                // Weight loading
                if (load_weights) begin
                    weights[0] <= data_in[7:0];
                    weights[1] <= data_in[15:8];
                    weights[2] <= data_in[23:16];
                end
                // IFmap loading (4 pixels at a time)
                else if (distance < 60) begin
                    ifmap[ifmap_load_cnt + 1] <= data_in[7:0];
                    ifmap[ifmap_load_cnt + 2] <= data_in[15:8];
                    ifmap[ifmap_load_cnt + 3] <= data_in[23:16];
                    ifmap[ifmap_load_cnt + 4] <= data_in[31:24];
                    ifmap_load_cnt <= ifmap_load_cnt + 4;
                end 

            end 
            
            // Computation state machine
            case (state)
                IDLE: begin
                    compute_caught_up <= 0;
                    state <= COMPUTE;
                    if (compute_caught_up && out_full) begin
                        state <= IDLE;
                        compute_caught_up <= 1;
                    end 
                    if ((ifmap_load_cnt - compute_idx) < 3) begin
                        state <= IDLE;
                    end 
                end
                
                COMPUTE: begin
                    // Accumulate one multiply result
                    if (weight_idx == 0) begin
                        partial_sums[compute_idx] <= mult_result;
                    end else begin
                        partial_sums[compute_idx] <= partial_sums[compute_idx] + mult_result;
                    end
                    
                    // Move to next weight
                    if (weight_idx < 2) begin
                        weight_idx <= weight_idx + 1;
                    end else begin
                        if (((compute_idx + 6'b1) == psum_out_cnt) && out_full) begin
                            compute_caught_up <= 1;
                            state <= IDLE; 
                        end
                        if ((ifmap_load_cnt - compute_idx) < 3) begin
                            state <= IDLE;
                        end
                        weight_idx <= 0;
                        compute_idx <= compute_idx + 1;
                    end
                end
                
            endcase

            // Output Logic
            if (!out_full && ((psum_out_cnt != compute_idx) || compute_caught_up)) begin
                psum_out_cnt <= psum_out_cnt + 1;
            end
        end
    end

endmodule
