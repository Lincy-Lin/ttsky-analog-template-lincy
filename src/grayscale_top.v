module grayscale_top #(
    parameter FIFO_BUFFER_SIZE = 32
) (
    input  wire        clock,
    input  wire        reset,

    input  wire        rgb_wr_en,
    input  wire [23:0] rgb_din,
    output reg         rgb_full,

    input  wire        gray_rd_en,
    output reg  [7:0]  gray_dout,
    output reg         gray_empty
);

    // Manage RGB-to-grayscale conversion with input and output FIFOs

    wire        fifo_rgb_rd_en;
    wire [23:0] fifo_rgb_dout;
    wire        fifo_rgb_empty;

    wire        fifo_gray_wr_en;
    wire [7:0]  fifo_gray_din;
    wire        fifo_gray_full;

    grayscale grayscale_inst (
        .clock      (clock),
        .reset      (reset),
        .rgb_rd_en  (fifo_rgb_rd_en),
        .rgb_dout   (fifo_rgb_dout),
        .rgb_empty  (fifo_rgb_empty),
        .gray_wr_en (fifo_gray_wr_en),
        .gray_din   (fifo_gray_din),
        .gray_full  (fifo_gray_full)
    );

    fifo #(
        .FIFO_DATA_WIDTH  (24),
        .FIFO_BUFFER_SIZE (FIFO_BUFFER_SIZE)
    ) fifo_rgb_in (
        .reset  (reset),
        .wr_clk (clock),
        .wr_en  (rgb_wr_en),
        .din    (rgb_din),
        .full   (rgb_full),
        .rd_clk (clock),
        .rd_en  (fifo_rgb_rd_en),
        .dout   (fifo_rgb_dout),
        .empty  (fifo_rgb_empty)
    );

    fifo #(
        .FIFO_DATA_WIDTH  (8),
        .FIFO_BUFFER_SIZE (FIFO_BUFFER_SIZE)
    ) fifo_gray_out (
        .reset  (reset),
        .wr_clk (clock),
        .wr_en  (fifo_gray_wr_en),
        .din    (fifo_gray_din),
        .full   (fifo_gray_full),
        .rd_clk (clock),
        .rd_en  (gray_rd_en),
        .dout   (gray_dout),
        .empty  (gray_empty)
    );

endmodule
