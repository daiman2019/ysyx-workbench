module top #(DATA_WIDTH =32)(
    input clk,
    input rst,
    output [DATA_WIDTH-1:0] pc,
    output [31:0] instruction,
    output [DATA_WIDTH-1:0] npc,
    output [DATA_WIDTH-1:0] halt_ret,
    output reg difftest_en_t
);
//wire [31:0] instruction;
wire difftest_en;
wire reg_wen,csr_wen,mem_read_flag;
wire [2:0] pc_jump;
wire [DATA_WIDTH-1:0] immdata;
wire [DATA_WIDTH-1:0] alu_result;
wire [DATA_WIDTH-1:0] reg_write_data;
wire [4:0] rs1;
wire [4:0] rs2;
wire [DATA_WIDTH-1:0] src1;
wire [DATA_WIDTH-1:0] src2;
wire [31:0] imm;
wire [4:0] rd;
wire [1:0] reg_data_flag;
wire [1:0] alu_left_opt,alu_right_opt;
wire [3:0] wmask;
wire [31:0] mem_read_data;
wire [1:0] mem_read_len;
wire [3:0] alu_opt;
wire alu_branch_flag;
wire [2:0] inst_type;//0:Btype 1:Rtype 2:Itype
wire [2:0] func3;
wire [6:0] func7;
wire [31:0] next_pc_addr;
assign npc=next_pc_addr;
wire [11:0] csr_raddr;
wire [11:0] csr_waddr1;
wire [11:0] csr_waddr2;
wire [31:0] csr_wdata1;
wire [31:0] csr_wdata2;
wire [31:0] csr_rdata;

reg rst_t;
wire ifu_valid,idu_ready,idu_valid,exu_ready,exu_valid,lsu_ready,lsu_valid,wbu_ready,reg_data_valid;
wire [1:0] ls_flag;
always@(posedge clk)begin
    rst_t<=rst;
end
//IFU
ysyx_25050148_ifu #(32,32) pipeline_ifu(
    .clk(clk),
    .rst(rst_t),
    .ifu_req(1'b1),//ifu有读请求
    .idu_ready(idu_ready),//idu准备好接收指令
    .exu_valid(exu_valid),
    .next_pc(next_pc_addr),
    .ifu_valid(ifu_valid),//ifu输出指令有效
    .pc(pc),
    .inst(instruction),
    .difftest_en(difftest_en)
);
always@(posedge clk) begin
    difftest_en_t<=difftest_en;
end
//指令译码IDU
ysyx_25050148_idu pipeline_idu(
    .clk(clk),
    .rst(rst_t),
    .ifu_valid(ifu_valid),
    .instruction(instruction),
    .exu_ready(exu_ready),
    .idu_ready(idu_ready),
    .idu_valid(idu_valid),
    .rs1(rs1),//outputEX_MEM_mem_read_flag
    .rs2(rs2),
    .imm(imm),
    .rd(rd),
    .reg_data_flag(reg_data_flag),
    .pc_jump(pc_jump),
    .left_opt(alu_left_opt),
    .right_opt(alu_right_opt),
    .wmask(wmask),
    .mem_read_len(mem_read_len),
    .mem_read_flag(mem_read_flag),
    .reg_wen(reg_wen),
    .load_store_flag(ls_flag),
    .csr_raddr(csr_raddr);
    .csr_wen(csr_wen),
    .csr_waddr1(csr_waddr1),
    .csr_waddr2(csr_waddr2),
    .alu_opt(alu_opt),
    .inst_type(inst_type),
    .func3(func3),
    .func7(func7)
);
//寄存器堆
RegisterFile #(5,32) regfiles(
    .clk(clk),
    .wen(write_reg_en),
    .wdata(write_reg_data),
    .waddr(write_reg_addr),
    .raddr1(rs1),
    .raddr2(rs2),
    .rdata1(src1),
    .rdata2(src2),
    .halt_ret(halt_ret));

ysyx_25050148_csr_reg csr_regs(
    .clk(clk),
    .rst(rst),
    .wen(csr_wbu_en),
    .wdata1(csr_wbu_data1),
    .csr_waddr1(csr_wbu_addr1),
    .wdata2(csr_wbu_data2),
    .csr_waddr2(csr_wbu_addr2),
    .csr_raddr(csr_raddr),
    .rdata(csr_rdata)
    );
//EXU
ysyx_25050148_exu#(32) pipeline_exu(
    .clk(clk),
    .rst(rst_t),
    .idu_valid(idu_valid),
    .lsu_ready(lsu_ready),
    .ifu_valid(ifu_valid),
    .alu_left_opt(alu_left_opt),
    .alu_right_opt(alu_right_opt),
    .pc(pc),
    .reg_src1(src1),
    .reg_src2(src2),
    .imm(imm),
    .alu_opt(alu_opt),
    .idu_pc_jump_flag(pc_jump),
    .idu_csr_pc(csr_rdata),
    .idu_inst_type(inst_type),//0:Btype 1:Rtype 2:Itype
    .idu_func3(func3),
    .idu_func7(func7),
    .exu_ready(exu_ready),
    .exu_valid(exu_valid),
    .alu_result(alu_result),
    .next_pc_addr(next_pc_addr));
//LSU
ysyx_25050148_lsu pipeline_lsu(
    .clk(clk),
    .rst(rst_t),
    .exu_valid(exu_valid),//EXU模块发送数据有效
    .wbu_ready(wbu_ready),//WBU模块准备就绪
    .ls_flag(ls_flag),//0:load,1:store,2:others
    .read_len(mem_read_len),//0:1,1:2,2:4
    .read_flag(mem_read_flag),//0:unsigned 1:signed
    .raddr(alu_result),
    .waddr(alu_result),
    .wmask(wmask),
    .wdata_in(src2),//x[rs2] from idu
    .lsu_ready(lsu_ready),//LSU模块准备就绪
    .lsu_valid(lsu_valid),//LSU模块发送数据有效
    .mem_read_data(mem_read_data));
//WBU
ysyx_25050148_wbu pipeline_wbu(
    .clk(clk),
    .rst(rst_t),
    .lsu_valid(lsu_valid),//LSU模块发送数据有效
    .reg_data_flag(reg_data_flag),
    .csr_regdata(csr_rdata),
    .alu_result(alu_result),
    .mem_read_data(mem_read_data),
    .wbu_ready(wbu_ready),
    .reg_data_valid(reg_data_valid),
    .reg_write_data(reg_write_data));
endmodule
