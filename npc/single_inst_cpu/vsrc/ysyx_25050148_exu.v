module ysyx_25050148_exu#(DATA_WIDTH = 32)(
    input clk,
    input rst,
    input [31:0] instruction,
    input idu_valid,//来自idu的数据有效
    input lsu_ready,//LSU已经准备就绪
    input ifu_valid,//来自IFU的数据有效，此时PC有效
    input [1:0] alu_left_opt,//from idu
    input [1:0] alu_right_opt,//from idu
    input [31:0] pc,//from ifu
    input [DATA_WIDTH-1:0] reg_src1,//from idu
    input [DATA_WIDTH-1:0] reg_src2,//from idu
    input [31:0] imm,//from idu
    input [3:0] alu_opt,//from idu
    input [2:0] idu_pc_jump_flag,//from idu
    input [31:0] idu_csr_pc,//from idu
    input [2:0] idu_inst_type,//from idu 0:Btype 1:Rtype 2:Itype
    input [2:0] idu_func3,//from idu
    input [6:0] idu_func7,//from idu
    output exu_ready,//EXU准备就绪，可以接收来自IDU的数据
    output exu_valid,//传输给LSU的数据有效
    output reg [DATA_WIDTH-1:0] exu_alu_out,
    output reg [31:0] next_pc_addr_r);
parameter idle=0,exu=1,exu_send=3;
reg [1:0] state,next;
reg [31:0] current_pc;
reg [31:0] idu_out_src1,idu_out_src2,imm_data,csr_pc;
reg [1:0] idu_left_opt,idu_right_opt;
reg [3:0] opt;
reg [2:0] pc_jump_flag,inst_type,func3;
reg [6:0] func7;
reg [DATA_WIDTH-1:0] alu_result;
wire [31:0] next_pc_addr;
always@(posedge clk)begin
    if(rst)
        current_pc<=32'h80000000;
    else if(ifu_valid)
        current_pc<=pc;
    else
        current_pc<=current_pc;
end
always@(posedge clk)begin
    if(rst) begin
        idu_left_opt<=0;
        idu_right_opt<=0;
        idu_out_src1<=0;
        idu_out_src2<=0;
        imm_data<=0;
        opt<=0;
        pc_jump_flag<=0;
        csr_pc<=0;
        inst_type<=0;
        func3<=0;
        func7<=0;
    end  
    else if(idu_valid&&exu_ready) begin
        idu_left_opt<=alu_left_opt;
        idu_right_opt<=alu_right_opt;
        idu_out_src1<=reg_src1;
        idu_out_src2<=reg_src2;
        imm_data<=imm;
        opt<=alu_opt;
        pc_jump_flag<=idu_pc_jump_flag;
        csr_pc<=idu_csr_pc;
        inst_type<=idu_inst_type;
        func3<=idu_func3;
        func7<=idu_func7;
    end
    else begin
        idu_left_opt<=idu_left_opt;
        idu_right_opt<=idu_right_opt;
        idu_out_src1<=idu_out_src1;
        idu_out_src2<=idu_out_src2;
        imm_data<=imm_data;
        opt<=opt;
        pc_jump_flag<=pc_jump_flag;
        csr_pc<=csr_pc;
        inst_type<=inst_type;
        func3<=func3;
        func7<=func7;
    end
end
always@(posedge clk)begin
    if(rst)
        state<=idle;
    else
        state<=next;
end
always@(*)begin
    case(state)
    idle:begin
        if(idu_valid)
            next=exu;
        else
            next=idle;
    end
    exu:begin
        next=exu_send;
    end
    exu_send:begin
        if(lsu_ready)
            next=idle;
        else
            next=exu_send;
    end
    endcase
end
assign exu_ready=(state==idle);
assign exu_valid=(state==exu_send);

wire [31:0] src1,src2;
assign src1 = (idu_left_opt==0)?idu_out_src1:(idu_left_opt==1)?current_pc:(idu_left_opt==2)?imm_data:0;
assign src2 = (idu_right_opt==0)?imm_data:(idu_right_opt==1)?4:(idu_right_opt==2)?idu_out_src2:0;
//ALU
//opt: 
//0000:add;0001:sub;0010 not;0011:and;0100:or;0101 xor;0110 src1<src2?;0111:src1==src2
//1000:shift left,1001:shift right 
//1111:do nothing
wire alu_branch_flag;
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
//pc addr calculation
wire [DATA_WIDTH-1:0] jal_pc;
wire [DATA_WIDTH-1:0] jalr_pc;
wire [DATA_WIDTH-1:0] branch_pc;
wire alu_branch_flag;
assign alu_branch_flag = (inst_type==0)?(func3==0)?equal_flag:
                                            (func3==1)?~equal_flag:
                                            (func3==4)?less_flag:
                                            (func3==5)?~less_flag:
                                            (func3==6)?(src1<src2):
                                            (func3==7)?(src1>=src2):0:0;
assign jal_pc = current_pc+imm_data;
assign jalr_pc = (idu_out_src1 + imm_data)&(32'hfffffffe);
assign branch_pc = alu_branch_flag?(current_pc + imm_data):(current_pc + 4);
MuxKeyWithDefault #(4, 3, 32) pc_result(
    .out(next_pc_addr),
    .key(pc_jump_flag),
    .default_out(current_pc + 4),
    .lut({3'b000,jal_pc,3'b001,jalr_pc,3'b010,branch_pc,3'b011,csr_pc}));
reg pc_valid;
always@(posedge clk)begin
    pc_valid<=(idu_valid&exu_ready);
end
always@(posedge clk)begin
    if(pc_valid) begin
        next_pc_addr_r<=next_pc_addr;
        exu_alu_out<= alu_result;
    end
    else begin
        next_pc_addr_r<=next_pc_addr_r;
        exu_alu_out<=exu_alu_out;
    end
end

//for ftrace
import "DPI-C" function void trace_func_ret(int pc_now);
import "DPI-C" function void trace_func_call(int pc_now,int target_addr);
always@(posedge clk)begin
    if(pc_jump_flag==0)
        trace_func_call(current_pc,jal_pc);
    else if(pc_jump_flag==1 && instruction==32'h00008067)//ret
        trace_func_ret(current_pc);
    else if(pc_jump_flag==1 && instruction!=32'h00008067)
        trace_func_call(current_pc,jalr_pc);
    else
        ;
end

endmodule
