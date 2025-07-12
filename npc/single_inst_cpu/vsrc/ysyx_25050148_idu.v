module ysyx_25050148_idu(
    input clk,
    input rst,
    input ifu_valid,//此时指令和地址有效
    input [31:0] instruction,
    input exu_ready,//EXU就绪

    output idu_ready,//idu此时准备好接收指令
    output idu_valid,//此时IDU发给EXU的数据有效

    output reg [4:0] rs1_r,
    output reg [4:0] rs2_r,
    output reg [31:0] imm_r,
    output reg [4:0] rd_r,
    output reg [1:0] reg_data_flag_r,
    output reg [2:0] pc_jump_r,
    output reg [1:0] left_opt_r,//0:src1,1:pc,2:imm 3:0
    output reg [1:0] right_opt_r,//0:imm,1:4,2:src2,3:0
    output reg [3:0] wmask_r,
    output reg [1:0] mem_read_len_r,
    output reg mem_read_flag_r,
    output reg reg_wen_r,
    output reg load_store_flag_r,//0:load 1:store 
    output reg [11:0] csr_raddr_r,
    output reg csr_wen_r,
    output reg [11:0] csr_waddr1_r,
    output reg [11:0] csr_waddr2_r,
    output reg [3:0] alu_opt_r,
    output reg [2:0] inst_type_r,
    output reg [2:0] func3_r,
    output reg [6:0] func7_r
);
//read and write registers and generate imm
import "DPI-C" function void finish_sim ();
always@(*)begin
    if(instruction==32'h00100073)//ebreak
        finish_sim(); 
end
wire Rtype,Itype,Stype,Btype,Utype,Jtype;
wire lui,auipc;
wire [6:0] opcode;
wire I_immtype,csr_type;
wire [31:0] csr_mstatus;
wire ecall,mret;
wire read_reg_en;
// parameter idle=0,decode=1,send_to_exu=2,wait_exu_ready=3;
// reg [1:0] state,next;
// always@(posedge clk)begin
//     if(rst)
//         state<=idle;
//     else
//         state<=next;
// end
// always@(*)begin
//     case(state)
//     idle:begin
//         if(ifu_valid)
//             next=decode;
//         else
//             next=idle;
//     end
//     decode:
//         next=send_to_exu;
//     send_to_exu:
//         next=wait_exu_ready;
//     wait_exu_ready:
//         if(exu_ready)
//             next=idle;
//         else
//             next=wait_exu_ready;
//     endcase
// end
// assign idu_valid = (state==send_to_exu)|(state==wait_exu_ready);
// assign idu_ready = (state==idle);
always@(posedge clk)begin
    if(rst) begin
        idu_ready<=1;
        idu_valid<=0;
    end 
    else if(ifu_valid&idu_ready) begin
        idu_valid<=1;
        idu_ready<=0;
    end
    else if(idu_valid&exu_ready)begin
       idu_ready<=1;
       idu_valid<=0; 
    end
    else begin
        idu_ready<=idu_ready;
        idu_valid<=idu_valid;
    end
end
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
//assign mem_wen = Stype;
//assign mem_read_en = load_store_flag==0;
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
//for reg write back
assign reg_wen = (~Stype & ~Btype & ~mret & ~ecall);
assign reg_data_flag = csr_type?0:load_store_flag==0?1:2;
//for csr reg write back
assign csr_wen = csr_type;
assign csr_raddr = ecall?12'h305:mret?12'h341:instruction[31:20];
assign csr_waddr1 = ecall?12'h342:mret?12'h342:instruction[31:20];
assign csr_waddr2 = ecall?12'h341:0;

always@(posedge clk)begin
    if(ifu_valid&idu_ready) begin//inst有效
        rs1_r               <=  rs1            ;
        rs2_r               <=  rs2            ;
        imm_r               <=  imm            ;
        rd_r                <=  rd             ;
        reg_data_flag_r     <=  reg_data_flag  ;
        pc_jump_r           <=  pc_jump        ;
        left_opt_r          <=  left_opt       ;
        right_opt_r         <=  right_opt      ;
        wmask_r             <=  wmask          ;
        mem_read_len_r      <=  mem_read_len   ;
        mem_read_flag_r     <=  mem_read_flag  ;
        reg_wen_r           <=  reg_wen        ;
        load_store_flag_r   <=  load_store_flag;
        csr_raddr_r         <=  csr_raddr      ;
        csr_wen_r           <=  csr_wen        ;
        csr_waddr1_r        <=  csr_waddr1     ;
        csr_waddr2_r        <=  csr_waddr2     ;
        alu_opt_r           <=  alu_opt        ;
        inst_type_r         <=  inst_type      ;
        func3_r             <=  func3          ;
        func7_r             <=  func7          ;
        
    end
end


endmodule
