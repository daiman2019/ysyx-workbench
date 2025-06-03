module exec_addi #(DATA_WIDTH = 32)(
    input [DATA_WIDTH-1:0] imm,
    input [DATA_WIDTH-1:0] src1,
    input [DATA_WIDTH-1:0] pc,
    input [1:0] adder_left_opt,//0:src1,1:pc,other:0
    input [1:0] adder_right_opt,//0:imm,1:4,other:0
    output [DATA_WIDTH-1:0] result
);
wire [DATA_WIDTH-1:0] left;
wire [DATA_WIDTH-1:0] right;
assign left = (adder_left_opt==0)?src1:(adder_left_opt==1)?pc:0;
assign right = (adder_right_opt==0)?imm:(adder_right_opt==1)?4:0;
assign result = left + right;
endmodule
