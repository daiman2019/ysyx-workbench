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
    assign {carry_out, result} = A + temp + {3'b0,cin};
    assign overflow =(A[3]==temp[3]) &&(A[3]!=result[3]);
    assign zero_flag = ~(|result);
    assign less_flag = (opt==3'b110)?(overflow ^ result[3]):1'b0;
    assign equal_flag = (opt==3'b111)?zero_flag:1'b0;

endmodule



// module alu_signed_4bits(
//     input [3:0] A,
//     input [3:0] B,
//     input [2:0] opt,
//     output reg [3:0] result,
//     output reg less_flag,
//     output reg equal_flag,
//     output reg carry_out,
//     output reg overflow,
//     output reg zero_flag);
//     reg [3:0] temp;
//     always @(*) begin
//         result = 4'b0000;carry_out = 0;overflow = 0;zero_flag = 0;equal_flag = 0;less_flag = 0;temp=4'b0000;
//         case (opt) 
//             3'b000: begin // ADD
//                 {carry_out, result} = A + B;
//                 overflow = (A[3] == B[3]) && (result[3] != A[3]);
//                 zero_flag = ~(|result);
//             end
//             3'b001: begin // SUB
//                 temp = ({4{1'b1}}^B); 
//                 {carry_out, result} = A + temp + 1'b1;
//                 overflow = (A[3] == temp[3]) && (result[3] != A[3]);
//                 zero_flag = ~(|result);
//             end
//             3'b010: begin // NOT A
//                 result = ~A;
//                 zero_flag = ~(|result);
//             end
//             3'b011: begin // A AND B
//                 result = A & B;
//                 zero_flag = ~(|result);
//             end
//             3'b100: begin // A or B
//                 result = A | B;
//                 zero_flag = ~(|result);
//             end
//             3'b101: begin // A XOR B
//                 result = A ^ B;
//                 zero_flag = ~(|result);
//             end
//             3'b110:begin //A<B
//                 temp = ({4{1'b1}}^B)+1'b1; //B -> -B
//                 {carry_out, result} = A + temp;
//                 overflow = (A[3] == temp[3]) && (result[3] != A[3]);
//                 less_flag = overflow ^ result[3];
//                 zero_flag = ~(|result);
//             end
//             3'b111:begin //A==B
//                 temp = ({4{1'b1}}^B)+1'b1; //B -> -B
//                 {carry_out, result} = A + temp;
//                 overflow = (A[3] == temp[3]) && (result[3] != A[3]);
//                 equal_flag = ~(|result);
//             end
//             default: begin
//                 result = 4'b0000;carry_out = 0;
//                 overflow = 0;zero_flag = 0;
//                 equal_flag = 0;less_flag = 0;
//             end
//         endcase
//     end
// endmodule










