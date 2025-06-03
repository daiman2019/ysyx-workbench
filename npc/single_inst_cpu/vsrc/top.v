module top #(ADDR_WIDTH =32 ,DATA_WIDTH =32)(
    input clk,
    input rst,
    input [31:0] instruction,
    output reg [DATA_WIDTH-1:0] pc,
    output [DATA_WIDTH-1:0] halt_ret
);
wire [1:0] jal_or_jalr;
wire [DATA_WIDTH-1:0] immdata;
wire [DATA_WIDTH-1:0] result;
wire [4:0] rs1;
wire [4:0] rs2;
wire [DATA_WIDTH-1:0] src1;
wire [DATA_WIDTH-1:0] src2;
wire [4:0] rd;
wire [1:0] adder_left_opt;//0:src1,1:pc,other:0
wire [1:0] adder_right_opt;//0:imm,1:4,other:0
reg rst_t;
always@(posedge clk)begin
    rst_t<=rst;
end
pc_update #(32) npc_pc_update(
    .clk(clk),
    .rst(rst_t),
    .instruction(instruction),
    .offset (immdata),
    .jump_flag (jal_or_jalr),
    .src1(src1),
    .pc(pc)
);
//寄存器堆
RegisterFile #(5,32) regfiles(
    .clk(clk),
    .wen(1'b1),
    .wdata(result),
    .waddr(rd),
    .raddr1(rs1),
    .raddr2(rs2),
    .rdata1(src1),
    .rdata2(src2),
    .halt_ret(halt_ret));

//指令译码IDU
//decode addi instruction and sext imm
decode_inst_addi ysyx_25050148_IDU(
    .instruction(instruction),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .imm(immdata),
    .jal_or_jalr(jal_or_jalr),
    .adder_left_opt(adder_left_opt),
    .adder_right_opt(adder_right_opt)
);  
//执行指令
exec_addi #(32) ysyx_25050148_EXU(
    .imm(immdata),
    .src1(src1),
    .pc(pc),
    .adder_left_opt(adder_left_opt),
    .adder_right_opt(adder_right_opt),
    .result(result)
);

endmodule
