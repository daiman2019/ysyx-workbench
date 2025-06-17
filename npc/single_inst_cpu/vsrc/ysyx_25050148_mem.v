module ysyx_25050148_mem(
    input clk,
    input read_valid,
    input write_valid,
    input [31:0] raddr,
    input [2:0] func3,
    input wen,
    input [31:0] waddr,
    input [3:0] wmask,
    input [31:0] wdata,
    output [31:0] read_data);

wire [31:0] wdata_len;
wire [2:0] read_len;
reg [31:0] rdata;
assign wdata_len = (wmask==4'b0000)?0:
                                (wmask==4'b0001)?1:
                                (wmask==4'b0011)?2:
                                (wmask==4'b1111)?4:0;
wire [31:0] pmemread_len = {{29{1'b0}},read_len};
assign read_len = (func3==3'b000)?1://lb
                  (func3==3'b001)?2://lh
                  (func3==3'b010)?4://lw        
                  (func3==3'b100)?1://lbu
                  (func3==3'b101)?2://lhu
                  (func3==3'b110)?4:4;//lwu
assign read_data = (func3==3'b000)?{{24{rdata[7]}},rdata[7:0]}://lb
                   (func3==3'b001)?{{16{rdata[15]}},rdata[15:0]}://lh
                   (func3==3'b010)?rdata://lw
                   (func3==3'b100)?{{24{1'b0}},rdata[7:0]}://lbu
                   (func3==3'b101)?{{16{1'b0}},rdata[15:0]}://lhu
                   (func3==3'b110)?rdata:rdata;//lwu
import "DPI-C" function int pmem_read(input int raddr,input int len);
import "DPI-C" function void pmem_write(int waddr,int wdata,int len);
always@(*) begin
    if(read_valid) begin
        rdata = pmem_read(raddr,pmemread_len);
    end
    else begin
        rdata = 0;
    end
end
always@(posedge clk) begin
    if(write_valid & wen) begin
        pmem_write(waddr,wdata,wdata_len);
    end
end

endmodule 
