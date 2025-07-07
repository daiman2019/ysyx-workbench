module ysyx_25050148_mem(
    input clk,
    input read_en,
    input write_en,
    input [1:0] read_len,//0:1,1:2,2:4
    input read_flag,//0:unsigned 1:signed
    input [31:0] raddr,
    input [31:0] waddr,
    input [31:0] wdata_len,
    input [31:0] wdata,
    output [31:0] mem_read_data);
reg [31:0] sram_mem [2**32-1:0];
reg [31:0] rdata;
reg [1:0] read_len_t;
reg read_flag_t;
wire [31:0] pmemread_len;
assign pmemread_len = read_len==0?1:read_len==1?2:4;
import "DPI-C" function int pmem_read(input int raddr,input int len,int flag);
import "DPI-C" function void pmem_write(int waddr,int wdata,int len);
always@(*) begin
    if(read_en) begin
        rdata = pmem_read(raddr,pmemread_len,2);
    end
    else begin
        rdata = 0;
    end
end
// always@(posedge clk)begin
//     read_len_t<=read_len;
//     read_flag_t<=read_flag;
// end
assign mem_read_data = (read_len==0 && read_flag==1)?{{24{rdata[7]}},rdata[7:0]}://lb
                   (read_len==1 && read_flag==1)?{{16{rdata[15]}},rdata[15:0]}://lh
                   (read_len==2 && read_flag==1)?rdata://lw
                   (read_len==0 && read_flag==0)?{{24{1'b0}},rdata[7:0]}://lbu
                   (read_len==1 && read_flag==0)?{{16{1'b0}},rdata[15:0]}://lhu
                   (read_len==2 && read_flag==0)?rdata:rdata;//lwu
always@(posedge clk) begin
    if(write_en) begin
        pmem_write(waddr,wdata,wdata_len);
    end
end
endmodule 
