module ysyx_25050148_clint_axi_lite #(ADDR_WIDTH = 32 ,DATA_WIDTH =32,ADDR_MTIME_HI = 32'ha000004c,ADDR_MTIME_LO=32'h0xa0000048)
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
wire ar_handshake;
wire r_handshake;

always@(posedge clk) begin
    if(rst)
        mtime<=64'h0;
    else
        mtime<=mtime+64'h1;
end
assign s_axi_awready = 1'b0;
assign s_axi_wready = 1'b0;
assign s_axi_bvalid = 1'b0;
assign s_axi_bresp = 2'b0;

assign ar_handshake = s_axi_arvalid && s_axi_arready;
assign r_handshake = s_axi_rvalid && s_axi_rready;

always@(posdege clk)begin
    if(rst)
end

endmodule
