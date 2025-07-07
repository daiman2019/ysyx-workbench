module ysyx_25050148_wbu(
    input [1:0] reg_data_flag,//0:from csr reg 1:from mem 2:from alu
    input [31:0] csr_regdata,
    input [31:0] alu_result,
    input [31:0] mem_read_data,
    output [31:0] reg_write_data
);
assign reg_write_data = reg_data_flag==0?csr_regdata:reg_data_flag==1?mem_read_data:alu_result;

endmodule