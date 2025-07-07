module ysyx_25050148_ifu#(ADDR_WIDTH = 32 ,DATA_WIDTH =32)(
    input clk,
    input rst,
    input [ADDR_WIDTH-1:0] next_pc,
    output reg [ADDR_WIDTH-1:0] pc,
    output [DATA_WIDTH-1:0] inst,
    output reg difftest_en
);
//update pc and fetch inst from inst mem/sram
//update pc
always@(posedge clk) begin
    if(rst)
        pc<=32'h80000000;
    else
        pc<=next_pc;
end
always@(posedge clk) begin
    if(pc!=next_pc)
        difftest_en<=1;
    else
        difftest_en<=0;
end
//fetch inst form inst mem
reg [DATA_WIDTH-1:0] sram_mem [2**ADDR_WIDTH-1:0];
import "DPI-C" function int pmem_read(input int raddr,input int len,int flag);
always@(*) begin
    inst = pmem_read(pc,4,2);
end
endmodule
