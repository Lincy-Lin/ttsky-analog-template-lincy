module background_subtract_top #(
    parameter FIFO_BUFFER_SIZE = 32
) (
    input  wire       clock,
    input  wire       reset,

    input  wire       frame_wr_en,
    input  wire [7:0] frame_din,
    output reg        frame_full,

    input  wire       background_wr_en,
    input  wire [7:0] background_din,
    output reg        background_full,

    input  wire       diff_rd_en,
    output reg  [7:0] diff_dout,
    output reg        diff_empty
);

    // Perform background subtraction using FIFOs for frame and background streams

    wire       fifo_frame_rd_en;
    wire [7:0] fifo_frame_dout;
    wire       fifo_frame_empty;

    wire       fifo_background_rd_en;
    wire [7:0] fifo_background_dout;
    wire       fifo_background_empty;

    wire       fifo_diff_wr_en;
    wire [7:0] fifo_diff_din;
    wire       fifo_diff_full;

    background_subtract background_subtract_inst (
        .clock            (clock),
        .reset            (reset),
        .frame_rd_en      (fifo_frame_rd_en),
        .frame_dout       (fifo_frame_dout),
        .frame_empty      (fifo_frame_empty),
        .background_rd_en (fifo_background_rd_en),
        .background_dout  (fifo_background_dout),
        .background_empty (fifo_background_empty),
        .diff_wr_en       (fifo_diff_wr_en),
        .diff_din         (fifo_diff_din),
        .diff_full        (fifo_diff_full)
    );

    fifo #(
        .FIFO_DATA_WIDTH  (8),
        .FIFO_BUFFER_SIZE (FIFO_BUFFER_SIZE)
    ) fifo_frame_in (
        .reset  (reset),
        .wr_clk (clock),
        .wr_en  (frame_wr_en),
        .din    (frame_din),
        .full   (frame_full),
        .rd_clk (clock),
        .rd_en  (fifo_frame_rd_en),
        .dout   (fifo_frame_dout),
        .empty  (fifo_frame_empty)
    );

    fifo #(
        .FIFO_DATA_WIDTH  (8),
        .FIFO_BUFFER_SIZE (FIFO_BUFFER_SIZE)
    ) fifo_background_in (
        .reset  (reset),
        .wr_clk (clock),
        .wr_en  (background_wr_en),
        .din    (background_din),
        .full   (background_full),
        .rd_clk (clock),
        .rd_en  (fifo_background_rd_en),
        .dout   (fifo_background_dout),
        .empty  (fifo_background_empty)
    );

    fifo #(
        .FIFO_DATA_WIDTH  (8),
        .FIFO_BUFFER_SIZE (FIFO_BUFFER_SIZE)
    ) fifo_diff_out (
        .reset  (reset),
        .wr_clk (clock),
        .wr_en  (fifo_diff_wr_en),
        .din    (fifo_diff_din),
        .full   (fifo_diff_full),
        .rd_clk (clock),
        .rd_en  (diff_rd_en),
        .dout   (diff_dout),
        .empty  (diff_empty)
    );

endmodule
