module ysyx_25050148_clint_axi_lite #(ADDR_WIDTH = 32 ,DATA_WIDTH =32,ADDR_MTIME_HI = 32'ha000004c,ADDR_MTIME_LO=32'ha0000048)
(
    input clk,
    input rst,
    //AXI4-lite slave
    //读地址通道
    input s_axi_arvalid,
    input [ADDR_WIDTH-1:0] s_axi_araddr,
    input s_axi_arprot,
    output s_axi_arready,
    //读数据通道
    output s_axi_rvalid,
    output reg [DATA_WIDTH-1:0] s_axi_rdata,
    output [1:0] s_axi_rresp,
    input s_axi_rready,
    //写地址通道
    input s_axi_awvalid,
    input [ADDR_WIDTH-1:0] s_axi_awaddr,
    input s_axi_awprot,
    output s_axi_awready,
    //写数据通道
    input s_axi_wvalid,
    input [DATA_WIDTH-1:0] s_axi_wdata,
    input [(DATA_WIDTH>>3)-1:0] s_axi_wstrb,
    output s_axi_wready,
    //写响应通道
    output s_axi_bvalid,
    output [1:0] s_axi_bresp,
    input s_axi_bready
);
reg [63:0] mtime;
reg [31:0] latched_addr;
reg state,next;
parameter IDLE=0,READ_ADDR=1,READ_DATA=2;
always@(posedge clk) begin
    if(rst)
        mtime<=64'h0;
    else
        mtime<=mtime+64'h1;
end
//写通道全部置为0
assign s_axi_awready = 1'b0;
assign s_axi_wready = 1'b0;
assign s_axi_bvalid = 1'b0;
assign s_axi_bresp = 2'b0;

always@(posedge clk)begin
    if(rst)
        state<=IDLE;
    else
        state<=next;
end

always @(*) begin
    case(state)
        IDLE:begin
            if(s_axi_arvalid)
                next=READ_ADDR;
            else
                next=IDLE;
        end
        READ_ADDR:begin
            if(s_axi_arvalid&s_axi_rready)
                next=READ_DATA;
            else
                next=READ_ADDR;
        end
        READ_DATA:begin
            if(s_axi_rready&s_axi_rvalid)
                if(s_axi_arvalid)
                    next=READ_ADDR;
                else
                    next=IDLE;
            else
                next=READ_DATA;
        end
    endcase
end
always @(posedge clk) begin
    if(rst) 
        latched_addr<=0;
    else if(s_axi_arready&s_axi_arvalid)
        latched_addr<=s_axi_araddr;
    else
        latched_addr<=latched_addr;
end
assign s_axi_arready = (state==READ_ADDR);
assign s_axi_rvalid = (state==READ_DATA);
always@(*)begin
    if(state==READ_DATA) begin
        if(latched_addr == ADDR_MTIME_HI) begin
            s_axi_rdata = mtime[63:32];
            s_axi_rresp = 2'b00;
        end
        else if(latched_addr == ADDR_MTIME_LO) begin
            s_axi_rdata = mtime[31:0];
            s_axi_rresp = 2'b00;
        end
        else begin
            s_axi_rdata = 32'h0;
            s_axi_rresp = 2'b01;
        end
    end
    else begin
        s_axi_rdata = 32'h0;
        s_axi_rresp = 2'b01;
    end
end

endmodule
