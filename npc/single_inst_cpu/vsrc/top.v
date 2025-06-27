module top #(DATA_WIDTH =32)(
    input clk,
    input rst,
    input [31:0] instruction,
    output reg [DATA_WIDTH-1:0] pc,
    output reg [DATA_WIDTH-1:0] npc,
    output [DATA_WIDTH-1:0] halt_ret
);

wire read_valid;
wire write_valid;
wire reg_wen;
wire mem_wen;
wire [31:0] mem_rdata;
wire [3:0] wmask;
wire [1:0] load_store_flag;
wire [2:0] pc_jump;
wire [DATA_WIDTH-1:0] immdata;
wire [DATA_WIDTH-1:0] alu_result;
wire [DATA_WIDTH-1:0] reg_write_data;
wire [4:0] rs1;
wire [4:0] rs2;
wire [DATA_WIDTH-1:0] src1;
wire [DATA_WIDTH-1:0] src2;
wire [4:0] rd;
wire [1:0] alu_left_opt;//0:src1,1:pc,other:0
wire [1:0] alu_right_opt;//0:imm,1:4,other:0
wire [DATA_WIDTH-1:0] adder_src_left;
wire [DATA_WIDTH-1:0] adder_src_right;
wire [3:0] alu_opt;
wire alu_branch_flag;
wire [2:0] inst_type;//0:Btype 1:Rtype 2:Itype
wire [2:0] func3;
wire [6:0] func7;
wire csr_wen;
wire csr_type;
wire ecall;
wire mret;
wire [11:0] csr_raddr;
wire [11:0] csr_waddr1;
wire [11:0] csr_waddr2;
wire [31:0] csr_wdata1;
wire [31:0] csr_wdata2;
wire [31:0] csr_rdata;
wire [31:0] csr_mstatus;
wire [DATA_WIDTH-1:0] csr_pc;
reg rst_t;
always@(posedge clk)begin
    rst_t<=rst;
end
pc_update #(32) npc_pc_update(
    .clk(clk),
    .rst(rst_t),
    .instruction(instruction),
    .offset (immdata),
    .jump_flag (pc_jump),
    .src1(src1),
    .branch_or_not(alu_branch_flag),
    .csr_pc(csr_rdata),
    .pc(pc),
    .npc(npc)
);
//寄存器堆
RegisterFile #(5,32) regfiles(
    .clk(clk),
    .wen(reg_wen),
    .wdata(reg_write_data),
    .waddr(rd),
    .raddr1(rs1),
    .raddr2(rs2),
    .rdata1(src1),
    .rdata2(src2),
    .halt_ret(halt_ret));

//CSR registers
assign csr_mstatus = {csr_rdata[31:13],2'b00,csr_rdata[10:8],1'b1,csr_rdata[6:4],csr_rdata[7],csr_rdata[2:0]};
assign csr_wdata1 = func3 == 3'b010 ? (csr_rdata | src1):
                    func3 == 3'b001 ? src1:
                    ecall? src1 :
                    mret ? csr_mstatus:0;
assign csr_wdata2 = ecall? pc:0;
csr_reg ysyx_25050148_csr(
    .clk(clk),
    .rst(rst_t),
    .wen(csr_wen),
    .wdata1(csr_wdata1),
    .csr_waddr1(csr_waddr1),
    .wdata2(csr_wdata2),
    .csr_waddr2(csr_waddr2),
    .csr_raddr(csr_raddr),
    .rdata(csr_rdata)
    );
//指令译码IDU
//decode addi instruction and sext imm
decode_inst_addi ysyx_25050148_IDU(
    .instruction(instruction),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .imm(immdata),
    .pc_jump(pc_jump),
    .left_opt(alu_left_opt),
    .right_opt(alu_right_opt),
    .load_store_flag(load_store_flag),
    .wmask(wmask),
    .reg_wen(reg_wen),
    .mem_wen(mem_wen),
    .alu_opt(alu_opt),
    .csr_wen(csr_wen),
    .csr_type(csr_type),
    .ecall(ecall),
    .mret(mret),
    .csr_raddr(csr_raddr),
    .csr_waddr1(csr_waddr1),
    .csr_waddr2(csr_waddr2),
    .inst_type(inst_type),
    .func3(func3),
    .func7(func7)
);  

assign adder_src_left = (alu_left_opt==0)?src1:(alu_left_opt==1)?pc:(alu_left_opt==2)?immdata:0;
assign adder_src_right = (alu_right_opt==0)?immdata:(alu_right_opt==1)?4:(alu_right_opt==2)?src2:0;
//alu_control
//ALU执行指令
ysyx_25050148_alu #(32) alu(
    .src1(adder_src_left),
    .src2(adder_src_right),
    .opt(alu_opt),//000:add;001:sub;010 not;011:and;100:or;101 xor;110 src1<src2?;111:src1==src2
    .inst_type(inst_type),
    .func3(func3),
    .func7(func7),
    .alu_result(alu_result),
    .alu_branch_flag(alu_branch_flag)
);
// exec_addi #(32) ysyx_25050148_EXU(
//     .imm(immdata),
//     .src1(src1),
//     .pc(pc),
//     .adder_left_opt(adder_left_opt),
//     .adder_right_opt(adder_right_opt),
//     .result(result)
// );
//data memory
assign read_valid = load_store_flag==0?1:0;
assign write_valid = load_store_flag==1?1:0;
assign reg_write_data = csr_type?csr_rdata:(load_store_flag==0)?mem_rdata:alu_result;
ysyx_25050148_mem npc_mem(
    .clk(clk),
    .read_valid(read_valid),
    .write_valid(write_valid),
    .raddr(alu_result),
    .func3(func3),
    .wen(mem_wen),
    .waddr(alu_result),
    .wmask(wmask),
    .wdata(src2),
    .read_data(mem_rdata));
endmodule
