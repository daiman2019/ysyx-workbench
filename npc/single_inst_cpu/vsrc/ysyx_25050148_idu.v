module ysyx_25050148_idu(
    input clk,
    input rst,
    input [31:0] pc,
    input [31:0] instruction,
    input write_reg_en,
    input [31:0] write_reg_data,
    input [4:0] write_reg_addr,
    input csr_wbu_en,
    input [31:0] csr_wbu_data1,
    input [11:0] csr_wbu_addr1,
    input [31:0] csr_wbu_data2,
    input [11:0] csr_wbu_addr2,

    output reg [31:0] src1,
    output reg [31:0] src2,
    output reg [31:0] imm,
    output [4:0] rd,
    output [1:0] reg_data_flag,
    output [31:0] halt_ret,
    output [2:0] pc_jump,
    output reg [1:0] left_opt,//0:src1,1:pc,2:imm 3:0
    output reg [1:0] right_opt,//0:imm,1:4,2:src2,3:0
    output [31:0] mem_wdata_len,
    output [1:0] mem_read_len,
    output mem_read_flag,
    output reg_wen,
    output mem_wen,
    output mem_read_en,
    output csr_wen,
    output [31:0] csr_rdata,
    output [11:0] csr_waddr1,
    output [31:0] csr_wdata1,
    output [11:0] csr_waddr2,
    output [31:0] csr_wdata2,
    output [3:0] alu_opt,
    output [2:0] inst_type,
    output [2:0] func3,
    output [6:0] func7
);
//read and write registers and generate imm
import "DPI-C" function void finish_sim ();
wire [3:0] wmask;
wire Rtype,Itype,Stype,Btype,Utype,Jtype;
wire lui,auipc;
wire [6:0] opcode;
wire [4:0] rs1,rs2;
wire I_immtype,csr_type;
wire [1:0] load_store_flag;//0:load 1:store 
wire [31:0] csr_mstatus;
wire ecall,mret;
wire [11:0] csr_raddr;
assign opcode = instruction[6:0];
assign rs2 = instruction[24:20];
assign rd = instruction[11:7];
assign func3 = instruction[14:12];
//Rtype func7 rs2 rs1 func3 rd opcode
assign Rtype = (opcode==7'b0110011)?1:0;
assign func7 = instruction[31:25];
//Itype imm rs1 func3 rd opcode
assign load_store_flag = (opcode == 7'b0000011)?0: (opcode ==7'b0100011)?1:2;
assign I_immtype = opcode == 7'b0010011;
assign csr_type = opcode ==7'b1110011;
assign ecall = (instruction == 32'h00000073);
assign rs1 = ecall?5'd15:instruction[19:15];//just for now, to match cte.c and inst.c for difftest
assign mret  = (instruction == 32'h30200073);
assign Itype = (opcode ==7'b1100111)|(load_store_flag==0)|I_immtype|csr_type;//jalr load 
//Stype imm rs2 rs1 func3 imm opcode
assign Stype = load_store_flag==1;
//Btype imm rs2 rs2 func3 imm opcode
assign Btype = opcode == 7'b1100011;
//Utype imm rd opcode
assign lui = opcode == 7'b0110111;
assign auipc = opcode ==7'b0010111;
assign Utype = lui |auipc;
//Jtype imm rd opcode only jal
assign Jtype = opcode == 7'b1101111;//jal
assign pc_jump = (opcode == 7'b1101111)?0: (opcode ==7'b1100111)?1:Btype?2:(ecall|mret)?3:4;//0:jal 1:jarl 2:branch 3:ecall or mret 4:others

assign inst_type = (Btype)?0:(Rtype)?1:(Itype)?2:3;

always @(*)begin
    if(instruction == 32'h00100073)//ebreak Itype
        finish_sim();
end
assign imm = ({32{Utype}} & {instruction[31:12],{12{1'b0}}} ) | 
             ({32{Itype}} & {{20{instruction[31]}},instruction[31:20]}) |
             ({32{Stype}} & {{20{instruction[31]}},instruction[31:25],instruction[11:7]})|
             ({32{Jtype}} & {{12{instruction[31]}},instruction[19:12],instruction[20],instruction[30:21],1'b0})|
             ({32{Btype}} & {{20{instruction[31]}},instruction[7],instruction[30:25],instruction[11:8],1'b0}) |
             32'b0;
//control signal generation for ALU
assign wmask = Stype?(func3==3'b000)?4'b0001://sb
                     (func3==3'b001)?4'b0011://sh
                     (func3==3'b010)?4'b1111:4'b0000:4'b0000;//sw

assign alu_opt = Rtype?(func3==3'b000)?(func7[5]==0)?0:1://add or sub
                       (func3==3'b001)?8://sll src1<<src2
                       (func3==3'b010)?6://slt (sword_t)src1 < (sword_t)src2 ? 1:0
                       (func3==3'b011)?6://sltu src1 < src2 ? 1:0
                       (func3==3'b100)?5://xor R(rd) = src1 ^ src2
                       (func3==3'b101)?9://srl/sra,
                       (func3==3'b110)?4://or,R(rd) = src1 | src2
                       (func3==3'b111)?3:0://and,R(rd) = src1 & src2
                 Btype?(func3==3'b000)?7://beq if(src1 == src2) s->dnpc = s->pc + imm
                       (func3==3'b001)?7://bne if(src1 != src2) s->dnpc = s->pc + imm
                       (func3==3'b100)?6://blt if((sword_t)src1 < (sword_t)src2) s->dnpc = s->pc + imm
                       (func3==3'b101)?6://bge if((sword_t)src1 >= (sword_t)src2) s->dnpc = s->pc + imm
                       (func3==3'b110)?6://bltu if(src1 < src2) s->dnpc = s->pc + imm
                       (func3==3'b111)?6:0://bgeu if(src1 >= src2) s->dnpc = s->pc + imm
                I_immtype?(func3==3'b000)?0://addi src1+imm
                          (func3==3'b001)?8://slli sr1<<(imm&0x3f)
                          (func3==3'b010)?6://slti (sword_t)src1<(sword_t)imm ? 1:0
                          (func3==3'b011)?6://sltiu R(rd) = src1<imm ? 1:0 
                          (func3==3'b100)?5://xori src1^imm
                          (func3==3'b101)?9://srai srli
                          (func3==3'b110)?4://ori src1|imm
                          (func3==3'b111)?3:0://andi scr1&imm
                (pc_jump==1)?0://add R(rd) = s->pc +4
                Jtype?0://add R(rd) = s->pc +4;
                load_store_flag==0?0://add R(rd) = Mr(src1+imm)
                lui?0://R(rd)=imm+0
                auipc?0://R(rd) = s->pc + imm
                Stype?0:15;//src1+imm

always @(*)begin//for Rtype
    if(Rtype) begin //src1 src2
        left_opt = 0;right_opt=2;
    end
    else if(Btype) begin //src1 src2
        left_opt = 0;right_opt=2;
    end
    else if(I_immtype) begin // src1 imm
        left_opt = 0;right_opt=0;
    end
    else if((pc_jump==3'b001)||(pc_jump==3'b000)) begin // pc 4
        left_opt = 1;right_opt=1;
    end
    else if(load_store_flag==0) begin //src1 imm
        left_opt = 0;right_opt=0;
    end
    else if(lui) begin //imm 0
        left_opt =2;right_opt=3;
    end
    else if(auipc) begin //pc imm
        left_opt =1;right_opt=0;
    end
    else if(Stype) begin //src1 imm
        left_opt = 0;right_opt=0;
    end
    else begin
        left_opt = 0;right_opt=0;
    end
    end
//for wbu mem_read and mem_write
assign mem_wen = Stype;
assign mem_read_en = load_store_flag==0;
assign mem_read_len = (func3==3'b000)?0://lb
                  (func3==3'b001)?1://lh
                  (func3==3'b010)?2://lw        
                  (func3==3'b100)?0://lbu
                  (func3==3'b101)?1://lhu
                  (func3==3'b110)?2:2;//lwu
assign mem_read_flag = (func3==3'b000)?1://lb
                   (func3==3'b001)?1://lh
                   (func3==3'b010)?1://lw
                   (func3==3'b100)?0://lbu
                   (func3==3'b101)?0://lhu
                   (func3==3'b110)?0:0;//lwu
assign mem_wdata_len = (wmask==4'b0000)?0:
                                (wmask==4'b0001)?1:
                                (wmask==4'b0011)?2:
                                (wmask==4'b1111)?4:0;

//for reg write back
assign reg_wen = (~Stype & ~Btype & ~mret & ~ecall);
assign reg_data_flag = csr_type?0:load_store_flag==0?1:2;
//for csr reg write back
assign csr_wen = csr_type;
assign csr_raddr = ecall?12'h305:mret?12'h341:instruction[31:20];
assign csr_waddr1 = ecall?12'h342:mret?12'h342:instruction[31:20];
assign csr_waddr2 = ecall?12'h341:0;
assign csr_mstatus = {csr_rdata[31:13],2'b00,csr_rdata[10:8],1'b1,csr_rdata[6:4],csr_rdata[7],csr_rdata[2:0]};
assign csr_wdata1 = func3 == 3'b010 ? (csr_rdata | src1):
                    func3 == 3'b001 ? src1:
                    ecall? src1 :
                    mret ? csr_mstatus:0;
assign csr_wdata2 = ecall? pc:0;
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
endmodule
