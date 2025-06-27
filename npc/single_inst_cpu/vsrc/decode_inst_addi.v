module decode_inst_addi(
    input [31:0] instruction,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output reg [31:0] imm,
    output [2:0] pc_jump,
    output reg [1:0] left_opt,//0:src1,1:pc,2:imm 3:0
    output reg [1:0] right_opt,//0:imm,1:4,2:src2,3:0
    output [1:0] load_store_flag, //0:load 1:store 
    output [3:0] wmask,
    output reg_wen,
    output mem_wen,
    output csr_wen,
    output csr_type,
    output ecall,
    output mret,
    output [11:0] csr_raddr,
    output [11:0] csr_waddr1,
    output [11:0] csr_waddr2,
    output [3:0] alu_opt,
    output [2:0] inst_type,
    output [2:0] func3,
    output [6:0] func7
);
//rd = instruction[11:7] for R/I/U/J type
//rs1 = instruction[19:15] for R/I/S/B type
//rs2 = instruction[24:20] for R/S/B
import "DPI-C" function void finish_sim ();
wire Rtype,Itype,Stype,Btype,Utype,Jtype;
wire lui,auipc;
wire [6:0] opcode;
wire I_immtype;
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
assign rs1 = ecall?5'd15:instruction[19:15];//just for now, to match cte.c
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

assign mem_wen = Stype;
assign reg_wen = ~Stype & ~Btype & ~mret & ~ecall;
assign csr_wen = csr_type;
assign csr_raddr = ecall?12'h305:mret?12'h341:instruction[31:20];
assign csr_waddr1 = ecall?12'h342:mret?12'h342:instruction[31:20];
assign csr_waddr2 = ecall?12'h341:0;
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

endmodule
