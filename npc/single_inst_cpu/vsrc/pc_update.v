module pc_update  #(ADDR_WIDTH =32,DATA_WIDTH=32)(
    input clk,
    input rst,
    input [31:0] instruction,
    input [DATA_WIDTH-1:0] offset,
    input [2:0] jump_flag,
    input [DATA_WIDTH-1:0] src1,
    input branch_or_not,
    input [DATA_WIDTH-1:0] csr_pc,
    output reg [DATA_WIDTH-1:0] pc,
    output [DATA_WIDTH-1:0] npc
);
reg [DATA_WIDTH-1:0] next_pc;
wire [DATA_WIDTH-1:0] jal_pc;
wire [DATA_WIDTH-1:0] jalr_pc;
wire [DATA_WIDTH-1:0] branch_pc;
assign jal_pc = pc+offset;
assign jalr_pc = (src1 + offset)&(32'hfffffffe);
assign branch_pc = branch_or_not?(pc+offset):(pc + (ADDR_WIDTH>>3));
MuxKeyWithDefault #(4, 3, 32) pc_result(
    .out(next_pc),
    .key(jump_flag),
    .default_out(pc + (ADDR_WIDTH>>3)),
    .lut({3'b000,jal_pc,3'b001,jalr_pc,3'b010,branch_pc,3'b011,csr_pc}));
always@(posedge clk) begin
    if(rst)
        pc<=32'h80000000;
    else
        pc<=pc;
end
assign npc=next_pc;
//for ftrace
// import "DPI-C" function void trace_func_ret(int pc_now);
// import "DPI-C" function void trace_func_call(int pc_now,int target_addr);
// always@(posedge clk)begin
//     if(jump_flag==0)
//         trace_func_call(pc,jal_pc);
//     else if(jump_flag==1 && instruction==32'h00008067)//ret
//         trace_func_ret(pc);
//     else if(jump_flag==1 && instruction!=32'h00008067)
//         trace_func_call(pc,jalr_pc);
//     else
//         ;
// end

endmodule
