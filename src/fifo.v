module fifo #(
    parameter FIFO_DATA_WIDTH  = 32,
    parameter FIFO_BUFFER_SIZE = 1024
) (
    input  wire                       reset,
    input  wire                       wr_clk,
    input  wire                       wr_en,
    input  wire [FIFO_DATA_WIDTH-1:0] din,
    output reg                        full,
    input  wire                       rd_clk,
    input  wire                       rd_en,
    output reg  [FIFO_DATA_WIDTH-1:0] dout,
    output reg                        empty
);

    // Buffer streaming data and provide flow control between producer and consumer

    // $clog2 is supported in Verilog-2001; add 1 for full/empty disambiguation
    localparam FIFO_ADDR_WIDTH = $clog2(FIFO_BUFFER_SIZE) + 1;

    reg [FIFO_DATA_WIDTH-1:0] fifo_buf [0:FIFO_BUFFER_SIZE-1];
    reg [FIFO_ADDR_WIDTH-1:0] wr_addr;
    reg [FIFO_ADDR_WIDTH-1:0] rd_addr;

    wire [FIFO_ADDR_WIDTH-1:0] wr_addr_t;
    wire [FIFO_ADDR_WIDTH-1:0] rd_addr_t;
    wire                       full_t;
    wire                       empty_t;

    // Write buffer
    always @(posedge wr_clk) begin
        if (wr_en == 1'b1 && full_t == 1'b0)
            fifo_buf[wr_addr[FIFO_ADDR_WIDTH-2:0]] <= din;
    end

    // Write address
    always @(posedge wr_clk or posedge reset) begin
        if (reset == 1'b1) wr_addr <= {FIFO_ADDR_WIDTH{1'b0}};
        else               wr_addr <= wr_addr_t;
    end

    // Read buffer
    always @(posedge rd_clk) begin
        dout <= fifo_buf[rd_addr_t[FIFO_ADDR_WIDTH-2:0]];
    end

    // Read address
    always @(posedge rd_clk or posedge reset) begin
        if (reset == 1'b1) rd_addr <= {FIFO_ADDR_WIDTH{1'b0}};
        else               rd_addr <= rd_addr_t;
    end

    // Empty flag
    always @(posedge rd_clk or posedge reset) begin
        if (reset == 1'b1) empty <= 1'b1;
        else               empty <= (wr_addr == rd_addr_t) ? 1'b1 : 1'b0;
    end

    assign rd_addr_t = (rd_en == 1'b1 && empty_t == 1'b0) ? (rd_addr + 1'b1) : rd_addr;
    assign wr_addr_t = (wr_en == 1'b1 && full_t  == 1'b0) ? (wr_addr + 1'b1) : wr_addr;
    assign empty_t   = (wr_addr == rd_addr) ? 1'b1 : 1'b0;
    assign full_t    = (wr_addr[FIFO_ADDR_WIDTH-2:0] == rd_addr[FIFO_ADDR_WIDTH-2:0]) &&
                       (wr_addr[FIFO_ADDR_WIDTH-1]   != rd_addr[FIFO_ADDR_WIDTH-1])   ? 1'b1 : 1'b0;
    assign full      = full_t;

endmodule
