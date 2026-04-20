module triple_fifo_adder (
    input  wire        clk,
    input  wire        rst_n,

    // FIFO A input interface
    input  wire [31:0] fifoA_dout,
    input  wire        fifoA_empty,
    output wire        fifoA_rd_en,

    // FIFO B input interface
    input  wire [31:0] fifoB_dout,
    input  wire        fifoB_empty,
    output wire        fifoB_rd_en,

    // FIFO C input interface
    input  wire [31:0] fifoC_dout,
    input  wire        fifoC_empty,
    output wire        fifoC_rd_en,

    // External read-out
    input  wire        rd_en,
    output wire [31:0] sum_out,
    output wire        empty
);

    // ----------------------------------
    // INTERNAL ADDER OUTPUT FIFO
    // ----------------------------------
    wire        add_fifo_wr_en;
    wire        add_fifo_full;
    wire [31:0] adder_sum;

    sync_fifo #(.DEPTH(4), .DWIDTH(32)) add_fifo (
        .rstn   (rst_n),
        .clk    (clk),
        .wr_en  (add_fifo_wr_en),
        .rd_en  (rd_en),
        .din    (adder_sum),
        .dout   (sum_out),
        .empty  (empty),
        .full   (add_fifo_full)
    );

    // ------------------------------
    // READ ENABLE LOGIC
    // ------------------------------
    // Only read when:
    //  - all 3 input FIFOs have data
    //  - internal output FIFO is not full
    //  - adder stage not stalled
    // ------------------------------
    wire all_have_data = !fifoA_empty && !fifoB_empty && !fifoC_empty;
    assign fifoA_rd_en = all_have_data && !add_fifo_full;
    assign fifoB_rd_en = all_have_data && !add_fifo_full;
    assign fifoC_rd_en = all_have_data && !add_fifo_full;

    // ------------------------------
    // ADDER
    // ------------------------------
    assign adder_sum = fifoA_dout + fifoB_dout + fifoC_dout;

    // Write into result FIFO when we consumed inputs
    assign add_fifo_wr_en = fifoA_rd_en;

endmodule