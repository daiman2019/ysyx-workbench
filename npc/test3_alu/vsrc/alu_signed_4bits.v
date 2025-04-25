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

    reg [3:0] temp;

    always @(*) begin
        result = 4'b0000;
        carry_out = 0;
        overflow = 0;
        zero_flag = 0;
        equal_flag = 0;
        less_flag = 0;
        case (opt) 
            3'b000: begin // ADD
                {carry_out, result} = A + B;
                overflow = (A[3] == B[3]) && (result[3] != A[3]);
                zero_flag = ~(|result);
            end
            3'b001: begin // SUB
                temp = ({4{1'b1}}^B); 
                {carry_out, result} = A + temp + 1'b1;
                overflow = (A[3] == temp[3]) && (result[3] != A[3]);
                zero_flag = ~(|result);
            end
            3'b010: begin // NOT A
                result = ~A;
                zero_flag = ~(|result);
            end
            3'b011: begin // A AND B
                result = A & B;
                zero_flag = ~(|result);
            end
            3'b100: begin // A or B
                result = A | B;
                zero_flag = ~(|result);
            end
            3'b101: begin // A XOR B
                result = A ^ B;
                zero_flag = ~(|result);
            end
            3'b110:begin //A<B
                temp = ({4{1'b1}}^B)+1'b1; //B -> -B
                {carry_out, result} = A + temp;
                overflow = (A[3] == temp[3]) && (result[3] != A[3]);
                less_flag = overflow ^ result[3];
            end
            3'b111:begin //A==B
                temp = ({4{1'b1}}^B)+1'b1; //B -> -B
                {carry_out, result} = A + temp;
                overflow = (A[3] == temp[3]) && (result[3] != A[3]);
                equal_flag = ~(|result);
            end
            default: begin
                result = 4'b0000;
                carry_out = 0;
                overflow = 0;
                zero_flag = 0;
                equal_flag = 0;
                less_flag = 0;
            end
        endcase
    end
endmodule










