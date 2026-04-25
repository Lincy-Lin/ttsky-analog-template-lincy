module background_subtract (
    input  wire       clock,
    input  wire       reset,

    output reg        frame_rd_en,
    input  wire [7:0] frame_dout,
    input  wire       frame_empty,

    output reg        background_rd_en,
    input  wire [7:0] background_dout,
    input  wire       background_empty,

    output reg        diff_wr_en,
    output reg  [7:0] diff_din,
    input  wire       diff_full
);

    // Compute the absolute difference between frame and background grayscale pixels

    // State encoding: READ=0, WRITE=1
    localparam READ  = 1'b0;
    localparam WRITE = 1'b1;

    reg       cur_state, next_state;
    reg [7:0] difference, difference_t;

    // Sequential block
    always @(posedge clock or posedge reset) begin
        if (reset == 1'b1) begin
            difference <= 8'b0;
            cur_state  <= READ;
        end
        else begin
            difference <= difference_t;
            cur_state  <= next_state;
        end
    end

    // Combinational block
    always @(*) begin
        frame_rd_en      = 1'b0;
        background_rd_en = 1'b0;
        diff_wr_en       = 1'b0;
        diff_din         = 8'b0;
        difference_t     = difference;
        next_state       = cur_state;

        case (cur_state)
            READ: begin
                if (frame_empty == 1'b0 && background_empty == 1'b0) begin
                    frame_rd_en      = 1'b1;
                    background_rd_en = 1'b1;
                    difference_t     = (frame_dout > background_dout) ?
                                       (frame_dout - background_dout) :
                                       (background_dout - frame_dout);
                    next_state       = WRITE;
                end
            end

            WRITE: begin
                if (diff_full == 1'b0) begin
                    diff_wr_en = 1'b1;
                    diff_din   = difference;
                    next_state = READ;
                end
            end

            default: ;
        endcase
    end

endmodule
