module decode_inst_addi(
    input [31:0] instruction,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output reg [31:0] imm,
    output [1:0] jal_or_jalr,
    output reg [1:0] adder_left_opt,//0:src1,1:pc,other:0
    output reg [1:0] adder_right_opt//0:imm,1:4,other:0
);
//rd = instruction[11:7] for R/I/U/J type
//rs1 = instruction[19:15] for R/I/S/B type
//rs2 = instruction[24:20] for R/S/B
import "DPI-C" function void ebreak ();
wire [6:0] opcode;
assign opcode = instruction[6:0];
assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign rd = instruction[11:7];
always @(*)begin
    if(instruction == 32'h00100073)
        ebreak();
end
always @(*)begin
    case(opcode)
    7'b0010111:imm = {instruction[31:12],{12{1'b0}}}; //U type auipc
    7'b0010011:imm = {{20{instruction[31]}},instruction[31:20]};//I type addi
    7'b1101111:imm = {{11{instruction[31]}},instruction[31],instruction[19:12],instruction[20],instruction[30:21],1'b0};//j type jal
    7'b1100111:imm = {{20{instruction[31]}},instruction[31:20]};//I type jalr
    7'b0110111:imm = {instruction[31:12],{12{1'b0}}}; //U type lui
    default: imm = 0;
    endcase
end
assign jal_or_jalr = (opcode == 7'b1101111)?0: (opcode ==7'b1100111)?1:2;
//control signal generation for ALU

always @(*)begin
    case(opcode)
    7'b0010111:adder_left_opt = 2'b01; //U type auipc 
    7'b0010011:adder_left_opt = 2'b00;//I type addi
    7'b1101111:adder_left_opt = 2'b01;//j type jal
    7'b1100111:adder_left_opt = 2'b01;//I type jalr
    7'b0110111:adder_left_opt = 2'b10; //U type lui
    default: adder_left_opt = 2'b00;
    endcase
end

always @(*)begin
    case(opcode)
    7'b0010111:adder_right_opt = 2'b00; //U type auipc 
    7'b0010011:adder_right_opt = 2'b00;//I type addi
    7'b1101111:adder_right_opt = 2'b01;//j type jal
    7'b1100111:adder_right_opt = 2'b01;//I type jalr
    7'b0110111:adder_right_opt = 2'b00; //U type lui
    default: adder_right_opt = 2'b00;
    endcase
end

endmodule
