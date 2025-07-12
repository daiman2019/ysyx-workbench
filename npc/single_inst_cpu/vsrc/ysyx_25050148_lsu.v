module ysyx_25050148_lsu(
    input clk,
    input rst,
    input exu_valid,//EXU模块发送数据有效
    input wbu_ready,//WBU模块准备就绪
    input [1:0] ls_flag,//0:load,1:store,2:others
    input [1:0] read_len,//0:1,1:2,2:4
    input read_flag,//0:unsigned 1:signed
    input [31:0] raddr,
    input [31:0] waddr,
    input [3:0] wmask,
    input [31:0] wdata_in,
    output lsu_ready,//LSU模块准备就绪
    output lsu_valid,//LSU模块发送数据有效
    output [31:0] mem_read_data);

parameter idle=0,read_addr=1,read_data=2,write_addr=3,write_data=4,write_rsp=5;
reg [2:0] state,next;
wire arvalid,arready,rvalid,rready,awvalid,awready,wvalid,wready,bvalid,bready;
reg [31:0] araddr,awaddr,wdata;
wire [31:0] rdata;
always@(posedge clk)begin
    if(rst)
        state<=idle;
    else
        state<=next;
end
always@(*)begin
    case(state)
    idle:begin
        if(exu_valid && (ls_flag==0))
            next=read_addr;
        else if(exu_valid && (ls_flag==1))
            next=write_addr;
        else
            next=idle;
    end
    read_addr:begin
        if(arvalid&&arready)//读地址传输成功
            next=read_data;
        else
            next=read_addr;
    end
    read_data:begin
        if(rvalid&rready)//数据传输成功
            next=idle;
        else
            next=read_data;
    end
    write_addr:begin
        if(awvalid&&awready)
            next=write_data;
        else
            next=write_addr;
    end
    write_data:begin
        if(wvalid&&wready)
            next=write_rsp;
        else
            next=write_data;
    end
    write_rsp:begin
        if(bvalid&&bready)
            next=idle;
        else
            next=write_rsp;
    end
    endcase
end

assign arvalid=(state==read_addr);
assign rready = (state==read_data);
assign awvalid=(state==write_addr);
assign wvalid=(state==write_data);
assign bready = (state==write_rsp);
always@(posedge clk)begin
    if(rst)
        araddr<=0;
    else if(exu_valid)
        araddr<=raddr;
    else
        araddr<=araddr;
end
always@(posedge clk)begin
    if(rst)
        awaddr<=0;
    else if(exu_valid)
        awaddr<=waddr;
    else
        awaddr<=awaddr;
end
always@(posedge clk)begin
    if(rst)
        wdata<=0;
    else if(exu_valid)
        wdata<=wdata_in;
    else
        wdata<=wdata;
end

ysyx_25050148_sram #(32,32) lsu_sram(
    .clk(clk),
    .rst(rst),
    //AXI4-lite
    //读地址通道
    .arvalid(arvalid),
    .araddr(araddr),
    .arprot(1'b0),
    .arready(arready),
    //读数据通道
    .rvalid(rvalid),
    .rdata(rdata),
    .rresp(),
    .rready(rready),
    //写地址通道
    .awvalid(awvalid),
    .awaddr(awaddr),
    .awprot(1'b0),
    .awready(awready),
    //写数据通道
    .wvalid(wvalid),
    .wdata(wdata),
    .wstrb(wmask),
    .wready(wready),
    //写响应通道
    .bvalid(bvalid),
    .bresp(),
    .bready(bready)
);
assign mem_read_data = (read_len==0 && read_flag==1)?{{24{rdata[7]}},rdata[7:0]}://lb
                   (read_len==1 && read_flag==1)?{{16{rdata[15]}},rdata[15:0]}://lh
                   (read_len==2 && read_flag==1)?rdata://lw
                   (read_len==0 && read_flag==0)?{{24{1'b0}},rdata[7:0]}://lbu
                   (read_len==1 && read_flag==0)?{{16{1'b0}},rdata[15:0]}://lhu
                   (read_len==2 && read_flag==0)?rdata:rdata;//lwu

endmodule 
