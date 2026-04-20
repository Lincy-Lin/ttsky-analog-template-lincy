module sync_fifo #(parameter DEPTH=8, DWIDTH=16)
    (
        input                	 rstn,
                                 clk,
                                 wr_en,
                                 rd_en,
        input       [DWIDTH-1:0] din,
        output wire [DWIDTH-1:0] dout,
        output                 	 empty,
                                 full
    );

    reg [$clog2(DEPTH)-1:0] wptr;
    reg [$clog2(DEPTH)-1:0] rptr;
    reg wrapped;
    reg [DWIDTH-1:0] fifo[0:DEPTH-1];

    assign dout = fifo[rptr];

    always @ (posedge clk) begin
        if (!rstn) begin
            wptr <= 0;
            rptr <= 0;
            wrapped <= 0;
        end else begin
            case ({wr_en & !full, rd_en & !empty})
                2'b10: begin 
                    fifo[wptr] <= din;
                    wptr <= wptr + 1;
                    if (wptr + 2'b1 == rptr) begin
                        wrapped <= 1;
                    end
                end
                
                2'b01: begin 
                    rptr <= rptr + 1;
                    wrapped <= 0;
                end
                
                2'b11: begin 
                    fifo[wptr] <= din;
                    wptr <= wptr + 1;
                    rptr <= rptr + 1;
                end
            endcase
        end
    end

    assign full  = (wptr == rptr) && wrapped;
    assign empty = (wptr == rptr) && !wrapped;
    
endmodule