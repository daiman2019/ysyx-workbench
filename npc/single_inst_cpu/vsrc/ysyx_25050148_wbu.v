module ysyx_25050148_wbu(
    input clk,
    input rst,
    input ifu_valid,
    input idu_valid,
    input lsu_valid,
    input exu_valid,
    input reg_wen,//from idu
    input csr_wen,//from idu
    input [1:0] csr_wdata1_choice,
    input [31:0] pc,//from ifu
    input [31:0] src1,//from idu
    input [1:0] reg_data_flag,//from idu 0:from csr reg 1:from mem 2:from alu
    input [31:0] csr_rdata,//from idu
    input [31:0] alu_result,//from exu
    input [31:0] mem_read_data,//from lsu
    output reg write_reg_en,
    output reg write_csr_en,
    output wbu_ready,
    output reg wbu_valid,
    output reg [31:0] reg_write_data_r,
    output reg [31:0] csr_wdata1_r,
    output reg [31:0] csr_wdata2_r
);

reg [1:0] write_which_data,csr_wdata1_choice_r;
wire [31:0] reg_write_data,csr_mstatus,csr_wdata1,csr_wdata2;
reg [31:0] csr_rdata_r;
reg [31:0] alu_result_r,src1_r;
reg [31:0] pc_in_use;
always@(posedge clk) begin
    if(rst)
        pc_in_use<=32'h80000000;
    else if(ifu_valid)
        pc_in_use<=pc;
    else
        pc_in_use<=pc_in_use;
end
always@(posedge clk)begin
    if(rst) begin
        wbu_valid<=0;
    end
    else if(lsu_valid&&wbu_ready) begin
        wbu_valid<=1;
    end
    else
        wbu_valid<=0;
end
assign wbu_ready=~wbu_valid;
always@(posedge clk)begin
    if(idu_valid) begin
        write_which_data<=reg_data_flag;
        write_reg_en<=reg_wen;
        write_csr_en<=csr_wen;
        csr_rdata_r<=csr_rdata;
        csr_wdata1_choice_r<=csr_wdata1_choice;
        src1_r<=src1;
        end
    else begin
        write_which_data<=write_which_data;
        write_csr_en<=write_csr_en;
        write_reg_en<=write_reg_en;
        csr_rdata_r<=csr_rdata_r;
        csr_wdata1_choice_r<=csr_wdata1_choice_r;
        src1_r<=src1_r;
    end
end
always@(posedge clk)begin
    if(exu_valid)
        alu_result_r<=alu_result;
    else 
        alu_result_r<=alu_result_r; 
end
assign reg_write_data = write_which_data==0?csr_rdata_r:write_which_data==1?mem_read_data:alu_result_r;

assign csr_mstatus = {csr_rdata_r[31:13],2'b00,csr_rdata_r[10:8],1'b1,csr_rdata_r[6:4],csr_rdata_r[7],csr_rdata_r[2:0]};
assign csr_wdata1 = csr_wdata1_choice_r==0 ? (csr_rdata_r | src1_r):
                    csr_wdata1_choice_r==1 ? src1_r:
                    csr_wdata1_choice_r==2 ? src1_r :
                    csr_wdata1_choice_r==3 ? csr_mstatus:0;
assign csr_wdata2 = csr_wdata1_choice_r==2? pc_in_use:0;

always@(posedge clk)begin
    if(wbu_ready&&lsu_valid) begin
        reg_write_data_r<=reg_write_data;
        csr_wdata1_r<=csr_wdata1;
        csr_wdata2_r<=csr_wdata2;
    end
end

endmodule