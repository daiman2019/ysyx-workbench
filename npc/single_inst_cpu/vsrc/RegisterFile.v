module RegisterFile #(ADDR_WIDTH = 1 ,DATA_WIDTH =1)(
    input clk,
    input wen,
    input [DATA_WIDTH-1:0] wdata,
    input [ADDR_WIDTH-1:0] waddr,
    input [ADDR_WIDTH-1:0] raddr1,
    input [ADDR_WIDTH-1:0] raddr2,
    output[DATA_WIDTH-1:0] rdata1,
    output[DATA_WIDTH-1:0] rdata2,
    output[DATA_WIDTH-1:0] halt_ret
    );

    reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
    always @(posedge clk) begin
        if (wen && |waddr) begin
            rf[waddr] <= wdata;
        end
    end
    assign rdata1 = rf[raddr1];
    assign rdata2 = rf[raddr2];
    assign halt_ret = rf[10];
    import "DPI-C" function void reg_values(int i,int reg_v);
    always @(posedge clk) begin
        if (wen && |waddr) begin
            reg_values({{27{1'b0}},waddr},wdata);
        end
    end

endmodule

