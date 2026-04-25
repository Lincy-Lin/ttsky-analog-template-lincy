module tt_um_motion_detect #(
    parameter THRESHOLD        = 50,
    parameter FIFO_BUFFER_SIZE = 32
) (
    input  wire        VGND,
    input  wire        VDPWR,

    input  wire        clock,
    input  wire        reset,

    input  wire        frame_wr_en,
    input  wire [23:0] frame_din,
    output reg         frame_full,

    input  wire        background_wr_en,
    input  wire [23:0] background_din,
    output reg         background_full,

    input  wire        output_rd_en,
    output reg  [23:0] output_dout,
    output reg         output_empty
);

    wire       frame_gray_rd_en;
    wire [7:0] frame_gray_dout;
    wire       frame_gray_empty;

    wire       background_gray_rd_en;
    wire [7:0] background_gray_dout;
    wire       background_gray_empty;

    wire       subtract_rd_en;
    wire [7:0] subtract_dout;
    wire       subtract_empty;
    wire       subtract_frame_full;
    wire       subtract_background_full;

    wire       highlight_diff_full;
    wire       highlight_frame_full;

    wire _unused = &{VGND, VDPWR};

    // Grayscale for Frame (RGB -> gray)
    grayscale_top #(
        .FIFO_BUFFER_SIZE (FIFO_BUFFER_SIZE)
    ) grayscale_top_frame_inst (
        .clock      (clock),
        .reset      (reset),
        .rgb_wr_en  (frame_wr_en),
        .rgb_din    (frame_din),
        .rgb_full   (frame_full),
        .gray_rd_en (frame_gray_rd_en),
        .gray_dout  (frame_gray_dout),
        .gray_empty (frame_gray_empty)
    );

    // Grayscale for Background (RGB -> gray)
    grayscale_top #(
        .FIFO_BUFFER_SIZE (FIFO_BUFFER_SIZE)
    ) grayscale_top_background_inst (
        .clock      (clock),
        .reset      (reset),
        .rgb_wr_en  (background_wr_en),
        .rgb_din    (background_din),
        .rgb_full   (background_full),
        .gray_rd_en (background_gray_rd_en),
        .gray_dout  (background_gray_dout),
        .gray_empty (background_gray_empty)
    );

    // Background Subtraction (gray frame - gray background -> diff gray)
    background_subtract_top #(
        .FIFO_BUFFER_SIZE (FIFO_BUFFER_SIZE)
    ) background_subtract_top_inst (
        .clock            (clock),
        .reset            (reset),
        .frame_wr_en      (frame_gray_rd_en),
        .frame_din        (frame_gray_dout),
        .frame_full       (subtract_frame_full),
        .background_wr_en (background_gray_rd_en),
        .background_din   (background_gray_dout),
        .background_full  (subtract_background_full),
        .diff_rd_en       (subtract_rd_en),
        .diff_dout        (subtract_dout),
        .diff_empty       (subtract_empty)
    );

    // Highlight (diff gray + original RGB frame -> highlighted RGB)
    highlight_top #(
        .THRESHOLD        (THRESHOLD),
        .FIFO_BUFFER_SIZE (2*FIFO_BUFFER_SIZE)
    ) highlight_top_inst (
        .clock           (clock),
        .reset           (reset),
        .diff_wr_en      (subtract_rd_en),
        .diff_din        (subtract_dout),
        .diff_full       (highlight_diff_full),
        .frame_wr_en     (frame_wr_en),
        .frame_din       (frame_din),
        .frame_full      (highlight_frame_full),
        .highlight_rd_en (output_rd_en),
        .highlight_dout  (output_dout),
        .highlight_empty (output_empty)
    );

    // Only pop grayscale outputs when background_subtract input FIFOs can accept
    assign frame_gray_rd_en      = !subtract_frame_full      && !frame_gray_empty;
    assign background_gray_rd_en = !subtract_background_full && !background_gray_empty;

    // Only pop background_subtraction output when highlight_diff FIFO can accept
    assign subtract_rd_en        = !highlight_diff_full      && !subtract_empty;

endmodule
