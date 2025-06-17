module ysyx_25050148_alu#(DATA_WIDTH = 32)(
    input [DATA_WIDTH-1:0] src1,
    input [DATA_WIDTH-1:0] src2,
    input [3:0] opt,
    input [2:0] inst_type,//0:Btype 1:Rtype 2:Itype
    input [2:0] func3,
    input [6:0] func7,
    output reg [DATA_WIDTH-1:0] alu_result,
    output alu_branch_flag);
//opt: 
//0000:add;0001:sub;0010 not;0011:and;0100:or;0101 xor;0110 src1<src2?;0111:src1==src2
//1000:shift left,1001:shift right
    wire carry_out,less_flag,equal_flag,zero_flag;
    wire [DATA_WIDTH-1:0] result;
    wire overflow;
    wire cin; // 0:add 1:sub
    wire [31:0] temp;
    assign cin = (opt==4'b0110 || opt==4'b0111 || opt==4'b0001)?1'b1:1'b0;
    assign temp = ({32{cin}}^src2);//cin=0,temp=src2;cin=1,temp=~src2;
    //assign {carry_out, result} = (opt==4'b1000)? src1<<src2:(opt==4'b1001)?src1>>src2:src1 + temp + {31'b0,cin};
    assign {carry_out, result} = src1 + temp + {31'b0,cin};
    assign overflow =(src1[31]==temp[31]) &&(src1[31]!=result[31]);
    assign zero_flag = ~(|result);
    assign less_flag = (opt==4'b0110)?(overflow ^ result[31]):1'b0;
    assign equal_flag = (opt==4'b0111)?zero_flag:1'b0;

    assign alu_branch_flag = (inst_type==0)?(func3==0)?equal_flag:
                                            (func3==1)?~equal_flag:
                                            (func3==4)?less_flag:
                                            (func3==5)?~less_flag:
                                            (func3==6)?(src1<src2):
                                            (func3==7)?(src1>=src2):0:0;

    wire [63:0] right_shift_u = {{32{1'b0}},src1}>>src2[4:0];
    wire [63:0] right_shift_s = {{32{src1[31]}},src1}>>src2[4:0];
    always@(*)begin
        case(opt)
        4'b0000://add
            alu_result = result;
        4'b0001://sub
            alu_result = result;
        4'b0011://and
            alu_result = src1 & src2;
        4'b0100://or
            alu_result = src1 | src2;
        4'b0101://xor
            alu_result = src1 ^ src2;
        4'b0110://less than
            if(func3==3'b010)
                alu_result = {{31{1'b0}},less_flag};
            else if(func3==3'b011)
                alu_result = {{31{1'b0}},src1<src2};
            else
                alu_result = 0;
        4'b1000:
                alu_result = src1<<(src2[4:0]);//sll or slli
        4'b1001:
            if(func7[5]==0)
                alu_result = right_shift_u[31:0];
            else
                alu_result = right_shift_s[31:0];
        default:
            alu_result = 0;
        endcase
    end
endmodule
