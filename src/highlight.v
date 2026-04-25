module highlight #(
    parameter THRESHOLD   = 50
) (
    input  wire        clock,
    input  wire        reset,

    output reg         diff_rd_en,
    input  wire [7:0]  diff_dout,
    input  wire        diff_empty,

    output reg         frame_rd_en,
    input  wire [23:0] frame_dout,
    input  wire        frame_empty,

    output reg         highlight_wr_en,
    output reg  [23:0] highlight_din,
    input  wire        highlight_full
);

    // Highlight moving regions by comparing difference values against a threshold

    // State encoding: READ=0, WRITE=1
    localparam READ  = 1'b0;
    localparam WRITE = 1'b1;

    reg        cur_state, next_state;
    reg [23:0] pixel, pixel_t;

    // Sequential block
    always @(posedge clock or posedge reset) begin
        if (reset == 1'b1) begin
            pixel     <= 24'b0;
            cur_state <= READ;
        end
        else begin
            pixel     <= pixel_t;
            cur_state <= next_state;
        end
    end

    // Combinational block
    always @(*) begin
        diff_rd_en      = 1'b0;
        frame_rd_en     = 1'b0;
        highlight_wr_en = 1'b0;
        highlight_din   = 24'b0;
        pixel_t         = pixel;
        next_state      = cur_state;

        case (cur_state)
            READ: begin
                if (diff_empty == 1'b0 && frame_empty == 1'b0) begin
                    diff_rd_en  = 1'b1;
                    frame_rd_en = 1'b1;

                    if (diff_dout > THRESHOLD[7:0]) begin
                        // Blue highlight: R=0x00, G=0x00, B=0xFF
                        pixel_t = {8'd0, 8'd0, 8'd255};
                    end
                    else begin
                        pixel_t = frame_dout;
                    end

                    next_state = WRITE;
                end
            end

            WRITE: begin
                if (highlight_full == 1'b0) begin
                    highlight_wr_en = 1'b1;
                    highlight_din   = pixel;
                    next_state      = READ;
                end
            end

            default: ;
        endcase
    end

endmodule
