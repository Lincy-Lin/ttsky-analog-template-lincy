module highlight_top #(
    parameter THRESHOLD        = 50,
    parameter FIFO_BUFFER_SIZE = 32
) (
    input  wire        clock,
    input  wire        reset,

    input  wire        diff_wr_en,
    input  wire [7:0]  diff_din,
    output reg         diff_full,

    input  wire        frame_wr_en,
    input  wire [23:0] frame_din,
    output reg         frame_full,

    input  wire        highlight_rd_en,
    output reg  [23:0] highlight_dout,
    output reg         highlight_empty
);

    // Generate highlighted RGB output by combining difference and original frame streams

    wire        fifo_diff_rd_en;
    wire [7:0]  fifo_diff_dout;
    wire        fifo_diff_empty;

    wire        fifo_frame_rd_en;
    wire [23:0] fifo_frame_dout;
    wire        fifo_frame_empty;

    wire        fifo_highlight_wr_en;
    wire [23:0] fifo_highlight_din;
    wire        fifo_highlight_full;

    highlight #(
        .THRESHOLD   (THRESHOLD)
    ) highlight_inst (
        .clock           (clock),
        .reset           (reset),
        .diff_rd_en      (fifo_diff_rd_en),
        .diff_dout       (fifo_diff_dout),
        .diff_empty      (fifo_diff_empty),
        .frame_rd_en     (fifo_frame_rd_en),
        .frame_dout      (fifo_frame_dout),
        .frame_empty     (fifo_frame_empty),
        .highlight_wr_en (fifo_highlight_wr_en),
        .highlight_din   (fifo_highlight_din),
        .highlight_full  (fifo_highlight_full)
    );

    fifo #(
        .FIFO_DATA_WIDTH  (8),
        .FIFO_BUFFER_SIZE (FIFO_BUFFER_SIZE)
    ) fifo_diff_in (
        .reset  (reset),
        .wr_clk (clock),
        .wr_en  (diff_wr_en),
        .din    (diff_din),
        .full   (diff_full),
        .rd_clk (clock),
        .rd_en  (fifo_diff_rd_en),
        .dout   (fifo_diff_dout),
        .empty  (fifo_diff_empty)
    );

    fifo #(
        .FIFO_DATA_WIDTH  (24),
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
        .FIFO_DATA_WIDTH  (24),
        .FIFO_BUFFER_SIZE (FIFO_BUFFER_SIZE)
    ) fifo_highlight_out (
        .reset  (reset),
        .wr_clk (clock),
        .wr_en  (fifo_highlight_wr_en),
        .din    (fifo_highlight_din),
        .full   (fifo_highlight_full),
        .rd_clk (clock),
        .rd_en  (highlight_rd_en),
        .dout   (highlight_dout),
        .empty  (highlight_empty)
    );

endmodule
