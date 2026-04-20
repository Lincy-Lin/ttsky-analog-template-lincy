module top_level_design (
    input  wire        clk,
    input  wire        rst_n,

    // Inputs
    input  wire [31:0] data_in,
    input  wire        wr_en,
    output wire        full,

    // Outputs 
    output wire [31:0] data_out,
    input  wire        rd_en,
    output wire        empty
);

    // ============================================================================
    // Input Fifo
    // ============================================================================

    // Input FIFO wires
    wire [31:0] in_fifo_dout;
    wire        in_fifo_empty;
    reg         in_fifo_rd_en;

    // Instantiate input FIFO
    sync_fifo #(
        .DEPTH  (4),
        .DWIDTH (32)
    ) input_fifo (
        .rstn   (rst_n),
        .clk    (clk),
        .din    (data_in),
        .wr_en  (wr_en),
        .rd_en  (in_fifo_rd_en),
        .dout   (in_fifo_dout),
        .empty  (in_fifo_empty),
        .full   (full)
    );

    // ============================================================================
    // Input State Machine
    // ============================================================================

    // Input State Machine Counter & Control
    reg [5:0] row_counter;
    reg [3:0] col_counter;
    reg [1:0] weight_counter;
    reg counter_enable;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_counter <= 2'd0;
            row_counter <= 6'd0;
            col_counter <= 6'd0;
        end else if (counter_enable) begin
            if (weight_counter < 2'd3) begin
                weight_counter <= weight_counter + 1;
            end 
            else begin
                if (col_counter == 6'd15) begin
                    row_counter <= row_counter + 1;
                    if (row_counter == 6'd63) begin
                        weight_counter <= weight_counter + 1;
                    end
                end
                col_counter <= col_counter + 1;
            end
        end
    end

    // PE Input Wires
    reg         pe_load_weights [1:3];
    wire        pe_full [1:9];
    reg  [31:0] pe_data_in [1:9];
    reg         pe_wr_en [1:9];

    integer j;
    always @(*) begin
        // Default Values
        counter_enable = 1'b0;
        pe_load_weights[1] = 1'b0;
        pe_load_weights[2] = 1'b0;
        pe_load_weights[3] = 1'b0;
        for (j = 1; j <= 9; j = j + 1) begin
            pe_data_in[j] = in_fifo_dout;
        end
        for (j = 1; j <= 9; j = j + 1) begin
            pe_wr_en[j] = 0;
        end

        case (weight_counter)
            2'd0: begin
                // WEIGHT LOAD STATE 0
                counter_enable = !in_fifo_empty && !pe_full[1] && !pe_full[2] && !pe_full[3];
                if (counter_enable) begin
                    pe_load_weights[1] = 1'b1;
                    pe_wr_en[1] = 1'b1;
                    pe_wr_en[2] = 1'b1;
                    pe_wr_en[3] = 1'b1;
                end
            end
            
            2'd1: begin
                // WEIGHT LOAD STATE 1
                counter_enable = !in_fifo_empty && !pe_full[4] && !pe_full[5] && !pe_full[6];
                if (counter_enable) begin
                    pe_load_weights[2] = 1'b1;
                    pe_wr_en[4] = 1'b1;
                    pe_wr_en[5] = 1'b1;
                    pe_wr_en[6] = 1'b1;
                end
            end
            
            2'd2: begin
                // WEIGHT LOAD STATE 2
                counter_enable = !in_fifo_empty && !pe_full[7] && !pe_full[8] && !pe_full[9];
                if (counter_enable) begin
                    pe_load_weights[3] = 1'b1;
                    pe_wr_en[7] = 1'b1;
                    pe_wr_en[8] = 1'b1;
                    pe_wr_en[9] = 1'b1;
                end
            end
            
            2'd3: begin
                // DATA PROCESSING STATES (based on row_counter % 3)
                case (row_counter % 3)
                    2'd0: begin
                        // ROW STATE 0 (row_counter mod 3 = 0)
                        if (row_counter == 6'd0) begin
                            counter_enable = !in_fifo_empty && !pe_full[1] && !pe_full[4] && !pe_full[3];
                            pe_data_in[3] = 32'd0;
                            if (counter_enable) begin
                                pe_wr_en[1] = 1'b1;
                                pe_wr_en[4] = 1'b1;
                                pe_wr_en[3] = 1'b1;
                            end
                        end else if (row_counter == 6'd63) begin
                            counter_enable = !in_fifo_empty && !pe_full[8] && !pe_full[4] && !pe_full[7];
                            pe_data_in[8] = 32'd0;
                            if (counter_enable) begin
                                pe_wr_en[8] = 1'b1;
                                pe_wr_en[4] = 1'b1;
                                pe_wr_en[7] = 1'b1;
                            end
                        end else begin
                            counter_enable = !in_fifo_empty && !pe_full[1] && !pe_full[4] && !pe_full[7];
                            if (counter_enable) begin
                                pe_wr_en[1] = 1'b1;
                                pe_wr_en[4] = 1'b1;
                                pe_wr_en[7] = 1'b1;
                            end
                        end
                    end
                    
                    2'd1: begin
                        // ROW STATE 1 (row_counter mod 3 = 1)
                        counter_enable = !in_fifo_empty && !pe_full[2] && !pe_full[5] && !pe_full[8];
                        if (counter_enable) begin
                            pe_wr_en[2] = 1'b1;
                            pe_wr_en[5] = 1'b1;
                            pe_wr_en[8] = 1'b1;
                        end
                    end
                    
                    2'd2: begin
                        // ROW STATE 2 (row_counter mod 3 = 2)
                        counter_enable = !in_fifo_empty && !pe_full[3] && !pe_full[6] && !pe_full[9];
                        if (counter_enable) begin
                            pe_wr_en[3] = 1'b1;
                            pe_wr_en[6] = 1'b1;
                            pe_wr_en[9] = 1'b1;
                        end
                    end
                endcase
            end
        endcase
        in_fifo_rd_en = counter_enable;
    end

    // ============================================================================
    // PE Array
    // ============================================================================

    // PE output wires - arrays for all 9 PEs
    wire [31:0] pe_psum_out [1:9];
    wire        pe_out_empty [1:9];
    wire        pe_rd_en [1:9];

    // Generate 9 PE instances
    genvar i;
    generate
        for (i = 1; i <= 9; i = i + 1) begin : pe_array
            pe_top pe_inst (
                .clk          (clk),
                .rst_n        (rst_n),
                .data_in      (pe_data_in[i]),
                .load_weights (pe_load_weights[(i-1)/3 + 1]),
                .wr_en        (pe_wr_en[i]),
                .rd_en        (pe_rd_en[i]),
                .psum_out     (pe_psum_out[i]),
                .empty        (pe_out_empty[i]),
                .full         (pe_full[i])
            );
        end
    endgenerate

    // ============================================================================
    // Adder Instances
    // ============================================================================

    // Adder Outputs
    wire [31:0] adder_sum_out [1:3];
    wire        adder_empty [1:3];
    reg         adder_rd_en [1:3];

    // Instantiate Adder 1: PE1, PE5, PE9
    triple_fifo_adder adder1 (
        .clk          (clk),
        .rst_n        (rst_n),
        // FIFO A <- PE1
        .fifoA_dout   (pe_psum_out[1]),
        .fifoA_empty  (pe_out_empty[1]),
        .fifoA_rd_en  (pe_rd_en[1]),
        // FIFO B <- PE5
        .fifoB_dout   (pe_psum_out[5]),
        .fifoB_empty  (pe_out_empty[5]),
        .fifoB_rd_en  (pe_rd_en[5]),
        // FIFO C <- PE9
        .fifoC_dout   (pe_psum_out[9]),
        .fifoC_empty  (pe_out_empty[9]),
        .fifoC_rd_en  (pe_rd_en[9]),
        // Output
        .rd_en        (adder_rd_en[1]),
        .sum_out      (adder_sum_out[1]),
        .empty        (adder_empty[1])
    );

    // Instantiate Adder 2: PE2, PE6, PE7
    triple_fifo_adder adder2 (
        .clk          (clk),
        .rst_n        (rst_n),
        // FIFO A <- PE2
        .fifoA_dout   (pe_psum_out[2]),
        .fifoA_empty  (pe_out_empty[2]),
        .fifoA_rd_en  (pe_rd_en[2]),
        // FIFO B <- PE6
        .fifoB_dout   (pe_psum_out[6]),
        .fifoB_empty  (pe_out_empty[6]),
        .fifoB_rd_en  (pe_rd_en[6]),
        // FIFO C <- PE7
        .fifoC_dout   (pe_psum_out[7]),
        .fifoC_empty  (pe_out_empty[7]),
        .fifoC_rd_en  (pe_rd_en[7]),
        // Output
        .rd_en        (adder_rd_en[2]),
        .sum_out      (adder_sum_out[2]),
        .empty        (adder_empty[2])
    );

    // Instantiate Adder 3: PE3, PE4, PE8
    triple_fifo_adder adder3 (
        .clk          (clk),
        .rst_n        (rst_n),
        // FIFO A <- PE3
        .fifoA_dout   (pe_psum_out[3]),
        .fifoA_empty  (pe_out_empty[3]),
        .fifoA_rd_en  (pe_rd_en[3]),
        // FIFO B <- PE4
        .fifoB_dout   (pe_psum_out[4]),
        .fifoB_empty  (pe_out_empty[4]),
        .fifoB_rd_en  (pe_rd_en[4]),
        // FIFO C <- PE8
        .fifoC_dout   (pe_psum_out[8]),
        .fifoC_empty  (pe_out_empty[8]),
        .fifoC_rd_en  (pe_rd_en[8]),
        // Output
        .rd_en        (adder_rd_en[3]),
        .sum_out      (adder_sum_out[3]),
        .empty        (adder_empty[3])
    );

    // ============================================================================
    // OUTPUT STATE MACHINE
    // ============================================================================
    
    // Input State Machine Counter & Control 
    reg [5:0] out_counter;
    reg [1:0] out_adder;
    reg out_counter_enable;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_counter <= 6'd0;
            out_adder <= 2'd2;
        end else if (out_counter_enable) begin
            if (out_counter == 6'd63) begin
                if (out_adder < 2'd2) begin
                    out_adder <= out_adder + 1;
                end else begin
                    out_adder <= 0;
                end
            end
            out_counter <= out_counter + 1;
        end
    end

    // Output FIFO wires
    reg  [31:0] out_fifo_din;
    reg         out_fifo_wr_en;
    wire        out_fifo_full;
    
    always @(*) begin
        out_counter_enable = 1'b0;
        adder_rd_en[1] = 1'b0;
        adder_rd_en[2] = 1'b0;
        adder_rd_en[3] = 1'b0;
        
        // State decoding based on out_adder
        case (out_adder)
            2'd0: begin
                // OUTPUT STATE 0 - Read from Adder 1
                out_fifo_din = adder_sum_out[1];
                out_counter_enable = !adder_empty[1] && !out_fifo_full;
                if (out_counter_enable) begin
                    adder_rd_en[1] = 1'b1;
                end
            end
            
            2'd1: begin
                // OUTPUT STATE 1 - Read from Adder 2
                out_fifo_din = adder_sum_out[2];
                out_counter_enable = !adder_empty[2] && !out_fifo_full;
                if (out_counter_enable) begin
                    adder_rd_en[2] = 1'b1;
                end
            end
            
            2'd2: begin
                // OUTPUT STATE 2 - Read from Adder 3
                out_fifo_din = adder_sum_out[3];
                out_counter_enable = !adder_empty[3] && !out_fifo_full;
                if (out_counter_enable) begin
                    adder_rd_en[3] = 1'b1;
                end
            end
        endcase
        out_fifo_wr_en = out_counter_enable;
    end

    // ============================================================================
    // Output Fifo
    // ============================================================================

    // Instantiate output FIFO
    sync_fifo #(
        .DEPTH  (4),
        .DWIDTH (32)
    ) output_fifo (
        .rstn   (rst_n),
        .clk    (clk),
        .din    (out_fifo_din),
        .wr_en  (out_fifo_wr_en),
        .rd_en  (rd_en),
        .dout   (data_out),
        .empty  (empty),
        .full   (out_fifo_full)
    );

endmodule