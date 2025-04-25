module alu_signed_4bits(
    input [3:0] A,
    input [3:0] B,
    input [2:0] opt,
    output reg [3:0] result,
    output reg less_flag,
    output reg equal_flag,
    output reg carry_out,
    output reg overflow,
    output reg zero_flag);

    wire cin; // 0:add 1:sub
    wire [3:0] temp;
    assign cin = (opt==3'b110 || opt==3'b111 || opt==3'b001)?1'b1:1'b0;
    assign temp = ({4{cin}}^B);
    assign {carry_out, result} = A + temp + cin;
    assign overflow =(A[3]==temp[3]) &&(A[3]!=result[3]);
    assign zero_flag = ~(|result);
    assign less_flag = (opt==3'b110)?(overflow ^ result[3]):1'b0;
    assign equal_flag = (opt==3'b111)?zero_flag:1'b0;

endmodule
