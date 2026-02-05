module ysyx_25050148_sram #(ADDR_WIDTH=32,DATA_WIDTH=32)
(
    input clk,
    input rst,
    //AXI4-lite
    //读地址通道
    input arvalid,
    input [ADDR_WIDTH-1:0] araddr,
    input arprot,
    output arready,
    //读数据通道
    output rvalid,
    output reg [DATA_WIDTH-1:0] rdata,
    output [1:0] rresp,
    input rready,
    //写地址通道
    input awvalid,
    input [ADDR_WIDTH-1:0] awaddr,
    input awprot,
    output awready,
    //写数据通道
    input wvalid,
    input [DATA_WIDTH-1:0] wdata,
    input [(DATA_WIDTH>>3)-1:0] wstrb,
    output wready,
    //写响应通道
    output bvalid,
    output [1:0] bresp,
    input bready
);
wire [5:0] delay=2;
reg [5:0] read_cnt,write_cnt;
reg [31:0] sram_mem [2**32-1:0];
parameter IDLE = 0,READ_ADDR=1,READ_DATA =2,WRITE_ADDR=3,WRITE_DATA=4,WRITE_RSP=5,RD_DELAY=6,WR_DELAY=7;
reg [2:0] state,next;
reg [ADDR_WIDTH-1:0] read_addr,write_addr;
// reg [(DATA_WIDTH>>3)-1] write_len;
wire [31:0] write_len;
always@(posedge clk)begin
    if(rst)
        state<=IDLE;
    else
        state<=next;
end
always@(posedge clk)begin
    if(rst) begin
        read_cnt<=0;
        write_cnt<=0;
    end
    else if(state==RD_DELAY) begin
        read_cnt<=read_cnt+1;
    end
    else if(state==WR_DELAY) begin
        write_cnt<=write_cnt+1;
    end
    else begin
        read_cnt<=0;
        write_cnt<=0;
    end
end
always@(posedge clk)begin
    if(rst) begin
        read_addr<=0;
        write_addr<=0;
    end
    else begin
        if(arvalid&arready)
            read_addr<=araddr;
        if(awvalid&awready) begin
            write_addr<=awaddr;
            // write_data<=wdata;
            // if(wstrb==4'b0001)
            //     write_len<=1;
            // else if(wstrb==4'b0011)
            //     write_len<=2;
            // else
            //     write_len<=4;
        end 
    end
end
assign write_len = (wstrb==4'b0001)?1:(wstrb==4'b0011)?2:4;
//状态转移
always@(*)begin
    case(state)
        IDLE:begin
            if(arvalid)
                next=READ_ADDR;
            else if(awvalid)
                next=WRITE_ADDR;
            else
                next=IDLE;
        end
        READ_ADDR:begin
            if(arready&&arvalid)//读地址完成
                next=RD_DELAY;//READ_DATA
            else
                next=READ_ADDR;
        end
        READ_DATA:begin
            if(rvalid&rready) begin//读数据完成
                if(awvalid)
                    next=WRITE_ADDR;
                else 
                    next=IDLE;
            end
            else
                next=READ_DATA;
        end
        RD_DELAY:begin
            if(read_cnt==delay-1)
                next=READ_DATA;
            else
                next=RD_DELAY;
        end
        WRITE_ADDR:begin
            if(awready && awvalid) begin//写地址完成
                next=WRITE_DATA;
            end
            else
                next=WRITE_ADDR;
        end
        WRITE_DATA:begin
            if(wready && wvalid)
                next=WR_DELAY;//WRITE_RSP
            else
                next=WRITE_DATA;
        end
        WR_DELAY:begin
            if(write_cnt==delay-1)
                next=WRITE_RSP;
            else
                next=WR_DELAY;
        end
        WRITE_RSP:begin
            if(bvalid&bready) begin
                if(arvalid)
                    next=READ_ADDR;
                else
                    next=IDLE;
            end
            else
                next=WRITE_RSP;
        end
    endcase
end
always@(posedge clk)begin
    if(rst)
        wready<=0;
    else if(awready&awvalid)
        wready<=1;
    else if(wready&wvalid)
        wready<=0;
    else 
        wready<=wready;
end
//AXI4-lite响应信号
assign arready = (state==READ_ADDR);
assign rvalid = (state==READ_DATA);
assign rresp = 2'b00;//OK响应
assign awready = (state==WRITE_ADDR);
//assign wready = (state==WRITE_DATA);
assign bvalid = (state==WRITE_RSP);
assign bresp = 2'b00;

import "DPI-C" function int pmem_read(input int raddr,input int len,int flag);
import "DPI-C" function void pmem_write(int waddr,int wdata,int len);

always@(*)begin
    if(rvalid&rready)
        rdata = pmem_read(read_addr,4,2);
    else
        rdata = 0;
end
always@(posedge clk)begin
    if(wvalid&wready)
        pmem_write(write_addr,wdata,write_len);
end
endmodule
