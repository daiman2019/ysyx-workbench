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
wire reg_wen,csr_wen,mem_wen,mem_read_en,mem_read_flag;
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
wire [31:0] mem_wdata_len,mem_read_data;
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

//for pipeline
//IF_ID_regs
reg [31:0] IF_ID_pc,IF_ID_inst;
//ID_EX_regs
reg [31:0] ID_EX_pc,ID_EX_src1,ID_EX_src2,ID_EX_imm;
reg [3:0] ID_EX_alu_opt;
reg [1:0] ID_EX_alu_left_opt,ID_EX_alu_right_opt;
reg [2:0] ID_EX_pc_jump_flag,ID_EX_inst_type,ID_EX_func3;
reg [6:0] ID_EX_func7;
reg [31:0] ID_EX_csr_regdata,ID_EX_mem_write_len,ID_EX_csr_wdata1,ID_EX_csr_wdata2;
reg [11:0] ID_EX_csr_waddr1,ID_EX_csr_waddr2;
reg [1:0] ID_EX_regdata_flag,ID_EX_mem_read_len;
reg ID_EX_mem_read_flag,ID_EX_mem_read_en,ID_EX_mem_write_en,ID_EX_write_reg_en,ID_EX_csr_wen;
reg [4:0] ID_EX_write_reg_addr;
//EX_MEM_regs
reg [31:0] EX_MEM_alu_result,EX_MEM_pc;
//from ID_EX to MEM_WB
reg [31:0] EX_MEM_mem_read_addr,EX_MEM_mem_write_addr,EX_MEM_mem_write_data,EX_MEM_mem_write_len;
reg [1:0] EX_MEM_regdata_flag,EX_MEM_mem_read_len;
reg EX_MEM_mem_read_flag,EX_MEM_mem_read_en,EX_MEM_mem_write_en,EX_MEM_write_reg_en,EX_MEM_csr_wen;
reg [31:0] EX_MEM_csr_regdata,EX_MEM_csr_wdata1,EX_MEM_csr_wdata2;
reg [4:0] EX_MEM_write_reg_addr;
reg [11:0] EX_MEM_csr_waddr1,EX_MEM_csr_waddr2;
//MEM_WB_regs
reg [1:0] MEM_WB_regdata_flag;
reg [31:0] MEM_WB_csr_regdata,MEM_WB_alu_result,MEM_WB_mem_read_data,MEM_WB_csr_wdata1,MEM_WB_csr_wdata2;
reg MEM_WB_write_reg_en,MEM_WB_csr_wen;
reg [11:0] MEM_WB_csr_waddr1,MEM_WB_csr_waddr2;
reg [4:0] MEM_WB_write_reg_addr;
reg rst_t;
always@(posedge clk)begin
    rst_t<=rst;
end
always@(posedge clk) begin
    if(rst_t) begin
        IF_ID_pc<=32'h80000000;
        IF_ID_inst<=0;
        //ID阶段
        ID_EX_pc<=32'h80000000;
        ID_EX_src1<=0;
        ID_EX_src2<=0;
        ID_EX_imm<=0;
        ID_EX_alu_opt<=0;
        ID_EX_alu_left_opt<=0;
        ID_EX_alu_right_opt<=0;
        ID_EX_pc_jump_flag<=0;
        ID_EX_inst_type<=0;
        ID_EX_func3<=0;
        ID_EX_func7<=0;
        ID_EX_regdata_flag<=0;
        ID_EX_csr_regdata<=0;
        ID_EX_mem_read_en<=0;
        ID_EX_mem_read_len<=0;
        ID_EX_mem_read_flag<=0;
        ID_EX_mem_write_len<=0;
        ID_EX_mem_write_en<=0;
        ID_EX_write_reg_en<=0;
        ID_EX_write_reg_addr<=0;
        ID_EX_csr_wen<=0;
        ID_EX_csr_wdata1<=0;
        ID_EX_csr_waddr1<=0;
        ID_EX_csr_wdata2<=0;
        ID_EX_csr_waddr2<=0;   
        //EX阶段
        EX_MEM_pc<=32'h80000000;
        EX_MEM_regdata_flag<= 0;
        EX_MEM_csr_regdata<=0;
        EX_MEM_alu_result<=0;
        //from exu to mem
        EX_MEM_mem_read_en<=0;
        EX_MEM_mem_read_flag<=0;
        EX_MEM_mem_read_len<=0;
        EX_MEM_mem_read_addr<=0;
        EX_MEM_mem_write_len<=0;
        EX_MEM_mem_write_en<=0;
        EX_MEM_write_reg_en<=0;
        EX_MEM_write_reg_addr<=0;
        EX_MEM_csr_wen<=0;
        EX_MEM_csr_wdata1<=0;
        EX_MEM_csr_waddr1<=0;
        EX_MEM_csr_wdata2<=0;
        EX_MEM_csr_waddr2<=0;
        //MEM阶段
        MEM_WB_regdata_flag<=0;
        MEM_WB_csr_regdata<=0;
        MEM_WB_alu_result<=0;
        MEM_WB_mem_read_data<=0;
        //from mem to wbu
        MEM_WB_write_reg_en<=0;
        MEM_WB_write_reg_addr<=0;
        MEM_WB_csr_wen<=0;
        MEM_WB_csr_wdata1<=0;
        MEM_WB_csr_waddr1<=0;
        MEM_WB_csr_wdata2<=0;
        MEM_WB_csr_waddr2<=0;
        //WB阶段
        //write_reg_data<=0;
        //write_reg_en<=0;
        //write_reg_addr<=0;
    end
    else begin
        //IF阶段
        IF_ID_pc<=pc;
        IF_ID_inst<=instruction;
        //ID阶段
        ID_EX_pc<=IF_ID_pc;
        ID_EX_src1<=src1;
        ID_EX_src2<=src2;
        ID_EX_imm<=imm;
        ID_EX_alu_opt<=alu_opt;
        ID_EX_alu_left_opt<=alu_left_opt;
        ID_EX_alu_right_opt<=alu_right_opt;
        ID_EX_pc_jump_flag<=pc_jump;
        ID_EX_inst_type<=inst_type;
        ID_EX_func3<=func3;
        ID_EX_func7<=func7;
        ID_EX_regdata_flag<=reg_data_flag;
        ID_EX_csr_regdata<=csr_rdata;
        ID_EX_mem_read_en<=mem_read_en;
        ID_EX_mem_read_len<=mem_read_len;
        ID_EX_mem_read_flag<=mem_read_flag;
        ID_EX_mem_write_len<=mem_wdata_len;
        ID_EX_mem_write_en<=mem_wen;
        ID_EX_write_reg_en<=reg_wen;
        ID_EX_write_reg_addr<=rd;
        ID_EX_csr_wen<=csr_wen;
        ID_EX_csr_wdata1<=csr_wdata1;
        ID_EX_csr_waddr1<=csr_waddr1;
        ID_EX_csr_wdata2<=csr_wdata2;
        ID_EX_csr_waddr2<=csr_waddr2;
        
        //EX阶段
        EX_MEM_pc<=next_pc_addr;
        EX_MEM_regdata_flag<= ID_EX_regdata_flag;
        EX_MEM_csr_regdata<=ID_EX_csr_regdata;
        EX_MEM_alu_result<=alu_result;
        //from exu to mem
        EX_MEM_mem_write_len<=ID_EX_mem_write_len;
        EX_MEM_mem_write_en<=ID_EX_mem_write_en;
        EX_MEM_mem_write_addr<=alu_result;
        EX_MEM_mem_write_data<=ID_EX_src2;
        EX_MEM_mem_read_en<=ID_EX_mem_read_en;
        EX_MEM_mem_read_len<=ID_EX_mem_read_len;
        EX_MEM_mem_read_flag<=ID_EX_mem_read_flag;
        EX_MEM_mem_read_addr<=alu_result;
        EX_MEM_write_reg_en<=ID_EX_write_reg_en;
        EX_MEM_write_reg_addr<=ID_EX_write_reg_addr;
        EX_MEM_csr_wen<=ID_EX_csr_wen;
        EX_MEM_csr_wdata1<=ID_EX_csr_wdata1;
        EX_MEM_csr_waddr1<=ID_EX_csr_waddr1;
        EX_MEM_csr_wdata2<=ID_EX_csr_wdata2;
        EX_MEM_csr_waddr2<=ID_EX_csr_waddr2;
        //MEM阶段
        MEM_WB_regdata_flag<=EX_MEM_regdata_flag;
        MEM_WB_csr_regdata<=EX_MEM_csr_regdata;
        MEM_WB_alu_result<=EX_MEM_alu_result;
        MEM_WB_mem_read_data<=mem_read_data;
        //from mem to wbu
        MEM_WB_write_reg_en<=EX_MEM_write_reg_en;
        MEM_WB_write_reg_addr<=EX_MEM_write_reg_addr;
        MEM_WB_csr_wen<=EX_MEM_csr_wen;
        MEM_WB_csr_wdata1<=EX_MEM_csr_wdata1;
        MEM_WB_csr_waddr1<=EX_MEM_csr_waddr1;
        MEM_WB_csr_wdata2<=EX_MEM_csr_wdata2;
        MEM_WB_csr_waddr2<=EX_MEM_csr_waddr2;
        //WB阶段
        //write_reg_data<=reg_write_data;
        //write_reg_en<=MEM_WB_write_reg_en;
        //write_reg_addr<=MEM_WB_write_reg_addr;
    end
end

//IFU
ysyx_25050148_ifu #(32,32) pipeline_ifu(
    .clk(clk),
    .rst(rst_t),
    .next_pc(EX_MEM_pc),
    .pc(pc),
    .inst(instruction),
    .difftest_en(difftest_en)
);
always@(posedge clk) begin
    difftest_en_t<=difftest_en;
end
//指令译码IDU
//decode addi instruction and sext imm
ysyx_25050148_idu pipeline_idu(
    .clk(clk),
    .rst(rst_t),
    .pc(IF_ID_pc),
    .instruction(IF_ID_inst),
    .write_reg_en(MEM_WB_write_reg_en),
    .write_reg_data(reg_write_data),
    .write_reg_addr(MEM_WB_write_reg_addr),
    .csr_wbu_en(MEM_WB_csr_wen),
    .csr_wbu_data1(MEM_WB_csr_wdata1),
    .csr_wbu_addr1(MEM_WB_csr_waddr1),
    .csr_wbu_data2(MEM_WB_csr_wdata2),
    .csr_wbu_addr2(MEM_WB_csr_waddr2),
    .src1(src1),//outputEX_MEM_mem_read_flag
    .src2(src2),
    .imm(imm),
    .rd(rd),
    .reg_data_flag(reg_data_flag),
    .halt_ret(halt_ret),
    .pc_jump(pc_jump),
    .left_opt(alu_left_opt),
    .right_opt(alu_right_opt),
    .mem_wdata_len(mem_wdata_len),
    .mem_read_len(mem_read_len),
    .mem_read_flag(mem_read_flag),
    .reg_wen(reg_wen),
    .mem_wen(mem_wen),
    .mem_read_en(mem_read_en),
    .csr_wen(csr_wen),
    .csr_rdata(csr_rdata),
    .csr_waddr1(csr_waddr1),
    .csr_wdata1(csr_wdata1),
    .csr_waddr2(csr_waddr2),
    .csr_wdata2(csr_wdata2),
    .alu_opt(alu_opt),
    .inst_type(inst_type),
    .func3(func3),
    .func7(func7)
);
//EXU
ysyx_25050148_exu#(32) pipeline_exu(
    .alu_left_opt(ID_EX_alu_left_opt),
    .alu_right_opt(ID_EX_alu_right_opt),
    .pc(ID_EX_pc),
    .reg_src1(ID_EX_src1),
    .reg_src2(ID_EX_src2),
    .imm_data(ID_EX_imm),
    .opt(ID_EX_alu_opt),
    .pc_jump_flag(ID_EX_pc_jump_flag),
    .csr_pc(ID_EX_csr_regdata),
    .inst_type(ID_EX_inst_type),//0:Btype 1:Rtype 2:Itype
    .func3(ID_EX_func3),
    .func7(ID_EX_func7),
    .alu_result(alu_result),
    .next_pc_addr(next_pc_addr));

//MEM
ysyx_25050148_mem pipeline_datamem(
    .clk(clk),
    .read_en(EX_MEM_mem_read_en),
    .write_en(EX_MEM_mem_write_en),
    .read_len(EX_MEM_mem_read_len),//0:1,1:2,2:4
    .read_flag(EX_MEM_mem_read_flag),//0:unsigned 1:signed
    .raddr(EX_MEM_mem_read_addr),
    .waddr(EX_MEM_mem_write_addr),
    .wdata_len(EX_MEM_mem_write_len),
    .wdata(EX_MEM_mem_write_data),
    .mem_read_data(mem_read_data));
//WBU
ysyx_25050148_wbu pipeline_wbu(
    .reg_data_flag(MEM_WB_regdata_flag),
    .csr_regdata(MEM_WB_csr_regdata),
    .alu_result(MEM_WB_alu_result),
    .mem_read_data(MEM_WB_mem_read_data),
    .reg_write_data(reg_write_data));
endmodule
