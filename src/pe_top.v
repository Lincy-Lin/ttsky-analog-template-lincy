module pe_top (
    input  wire        clk,
    input  wire        rst_n,

    // External data input
    input  wire [31:0] data_in,
    input  wire        load_weights,
    input  wire        wr_en,
    input  wire        rd_en,

    // External data output
    output wire [31:0] psum_out,
    output wire        empty,
    output wire        full
);

    // ------------------------------
    // INPUT FIFO (33-bit wide, depth 4)
    // ------------------------------
    wire        in_fifo_full;
    wire        in_fifo_empty;
    wire        in_fifo_rd_en;
    wire [32:0] in_fifo_dout;

    sync_fifo #(.DEPTH(4), .DWIDTH(33)) pe_input_fifo (
        .rstn   (rst_n),
        .clk    (clk),
        .wr_en  (wr_en),
        .rd_en  (in_fifo_rd_en),
        .din    ({load_weights, data_in}),
        .dout   (in_fifo_dout),
        .empty  (in_fifo_empty),
        .full   (full)
    );

    // Split out signals to PE
    wire        pe_load_weights = in_fifo_dout[32];
    wire [31:0] pe_data_in      = in_fifo_dout[31:0];

    // ------------------------------
    // OUTPUT FIFO (32-bit wide, depth 4)
    // ------------------------------
    
    wire        out_fifo_wr_en;
    wire [31:0] pe_psum_out;

    sync_fifo #(.DEPTH(4), .DWIDTH(32)) pe_output_fifo (
        .rstn   (rst_n),
        .clk    (clk),
        .wr_en  (out_fifo_wr_en),
        .rd_en  (rd_en),
        .din    (pe_psum_out),
        .dout   (psum_out),
        .empty  (empty),
        .full   (out_fifo_full)
    );

    // ------------------------------
    // PE INSTANCE
    // ------------------------------
    PE pe_inst (
        .clk          (clk),
        .rst_n        (rst_n),

        // From input FIFO
        .data_in      (pe_data_in),
        .load_weights (pe_load_weights),
        .in_empty     (in_fifo_empty),
        .in_read      (in_fifo_rd_en),

        // To output FIFO
        .psum_out     (pe_psum_out),
        .out_valid    (out_fifo_wr_en),
        .out_full     (out_fifo_full)
    );

endmodule