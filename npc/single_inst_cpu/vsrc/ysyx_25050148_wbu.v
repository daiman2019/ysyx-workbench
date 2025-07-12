module ysyx_25050148_wbu(
    input clk,
    input rst,
    input lsu_valid,
    input [1:0] reg_data_flag,//0:from csr reg 1:from mem 2:from alu
    input [31:0] csr_regdata,
    input [31:0] alu_result,
    input [31:0] mem_read_data,
    output wbu_ready,
    output reg_data_valid,
    output [31:0] reg_write_data
);
parameter idle=0,write=1,confirm=2;
reg [1:0] state,next;
always@(posedge clk)begin
    if(rst)
        state<=idle;
    else
        state<=next;
end
always@(*)begin
    case(state)
    idle:begin
        if(lsu_valid)
            next=write;
        else
            next=idle;
    end
    write://写回寄存器
        next=confirm;
    confirm://写完成后回到空闲状态
        next=idle;
    endcase
end
assign wbu_ready = (state==idle);
assign reg_data_valid = (state==write);
assign reg_write_data = reg_data_flag==0?csr_regdata:reg_data_flag==1?mem_read_data:alu_result;

assign csr_mstatus = {csr_rdata[31:13],2'b00,csr_rdata[10:8],1'b1,csr_rdata[6:4],csr_rdata[7],csr_rdata[2:0]};
assign csr_wdata1 = func3 == 3'b010 ? (csr_rdata | src1):
                    func3 == 3'b001 ? src1:
                    ecall? src1 :
                    mret ? csr_mstatus:0;
assign csr_wdata2 = ecall? pc:0;
endmodule