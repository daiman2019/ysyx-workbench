module ysyx_25050148_uart #(ADDR_WIDTH=32,DATA_WIDTH=32)(
    //slave
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
//uart reg addr:0xa00003f8
parameter IDLE=0,WRITE_ADDR=1,WRITE_DATA=2,WRITE_RSP=3;
reg [1:0] state,next;
always@(posedge clk)begin
    if(rst)
        state<=IDLE;
    else
        state<=next;
end
always@(*) begin
    case(state)
    IDLE:begin
        if(awvalid)
            next=WRITE_ADDR;
        else
            next=IDLE;
    end
    WRITE_ADDR:
        if(awready && awvalid)
            next=WRITE_DATA;
        else
            next=WRITE_ADDR;
    WRITE_DATA:
        if(wready&&wvalid)
            next=WRITE_RSP;
        else
            next=WRITE_DATA;
    WRITE_RSP:
        if(bready&&bvalid)
            next=IDLE;
        else
            next=WRITE_RSP;
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
assign arready = 0;
assign rvalid = 0;
assign rresp = 2'b00;//OK响应
assign awready = (state==WRITE_ADDR);
//assign wready = (state==WRITE_DATA);
assign bvalid = (state==WRITE_RSP);
assign bresp = 2'b00;
always@(posedge clk)begin
    if(wvalid&&wready)
        $write("%c",wdata[7:0]);
end
endmodule
