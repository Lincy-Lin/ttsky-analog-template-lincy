module grayscale (
    input  wire        clock,
    input  wire        reset,

    output reg         rgb_rd_en,
    input  wire [23:0] rgb_dout,
    input  wire        rgb_empty,

    output reg         gray_wr_en,
    output reg  [7:0]  gray_din,
    input  wire        gray_full
);

    // Convert an input RGB pixel into a grayscale pixel

    // State encoding: READ=0, WRITE=1
    localparam READ  = 1'b0;
    localparam WRITE = 1'b1;

    reg        cur_state, next_state;
    reg [7:0]  grayscale, grayscale_t;

    // Sequential block
    always @(posedge clock or posedge reset) begin
        if (reset == 1'b1) begin
            grayscale <= 8'b0;
            cur_state <= READ;
        end
        else begin
            grayscale <= grayscale_t;
            cur_state <= next_state;
        end
    end

    // Combinational block
    always @(*) begin
        rgb_rd_en   = 1'b0;
        gray_wr_en  = 1'b0;
        gray_din    = 8'b0;
        grayscale_t = grayscale;
        next_state  = cur_state;

        case (cur_state)
            READ: begin
                if (rgb_empty == 1'b0) begin
                    rgb_rd_en   = 1'b1;
                    // Average of R, G, B channels; truncate to COLOR_WIDTH bits
                    grayscale_t = ((rgb_dout[23:16] + rgb_dout[15:8] + rgb_dout[7:0]) * 8'd85) >> 8;;
                    next_state  = WRITE;
                end
            end

            WRITE: begin
                if (gray_full == 1'b0) begin
                    gray_wr_en = 1'b1;
                    gray_din   = grayscale;
                    next_state = READ;
                end
            end

            default: ;
        endcase
    end

endmodule
