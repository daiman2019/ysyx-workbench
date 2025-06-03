module pc_update  #(ADDR_WIDTH =32,DATA_WIDTH=32)(
    input clk,
    input rst,
    input [31:0] instruction,
    input [DATA_WIDTH-1:0] offset,
    input [1:0] jump_flag,
    input [DATA_WIDTH-1:0] src1,
    output reg [DATA_WIDTH-1:0] pc
);
reg [DATA_WIDTH-1:0] next_pc;
wire [DATA_WIDTH-1:0] jal_pc;
wire [DATA_WIDTH-1:0] jalr_pc;
assign jal_pc = pc+offset;
assign jalr_pc = (src1 + offset)&(32'hfffffffe);
MuxKeyWithDefault #(2, 2, 32) pc_result(
    .out(next_pc),
    .key(jump_flag),
    .default_out(pc + (ADDR_WIDTH>>3)),
    .lut({2'b00,jal_pc,2'b01,jalr_pc}));
always@(posedge clk) begin
    if(rst)
        pc<=32'h80000000;
    else
        pc<= next_pc;
end

//for ftrace
import "DPI-C" function void trace_func_ret(int pc_now);
import "DPI-C" function void trace_func_call(int pc_now,int target_addr);
always@(posedge clk)begin
    if(jump_flag==0)
        trace_func_call(pc,jal_pc);
    else if(jump_flag==1 && instruction==32'h00008067)//ret
        trace_func_ret(pc);
    else if(jump_flag==1 && instruction!=32'h00008067)
        trace_func_call(pc,jalr_pc);
    else
        ;
end

endmodule