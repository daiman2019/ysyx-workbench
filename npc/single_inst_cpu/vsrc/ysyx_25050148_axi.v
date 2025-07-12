module ysyx_25050148_axi#(ADDR_WIDTH=32,DATA_WIDTH=32)(
    input aclk,
    input aresetn,//公共复位信号，低有效

    //主机控制信号
    input rvalid,//来自CPU的读请求
    input [ADDR_WIDTH-1:0] raddr,//来自Cpu的读地址
    output [DATA_WIDTH-1:0] rdata,//返回给CPU的数据
    output rready,//返回给CPU读地址结束,ready有效时数据有效

    input wvalid,//来自CPU的写请求
    input [ADDR_WIDTH-1:0] waddr,//来自CPU的写地址
    input [3:0] wlen,//来自CPU的写长度
    input [DATA_WIDTH-1:0] wdata,//来自CPU的数据内容
    output wready,//返回给CPU数据写数据完成
    
    //写地址通道信号
    output axi_awid,//写地址ID，用于标识写地址组
    output [ADDR_WIDTH-1:0] axi_awaddr,//写地址，写突发操作中第一次数据传输的地址
    output axi_awlen,//突发长度，标识每次突发传输的传输次数
    output axi_awsize,//突发大小，这个字段表示每次突发传输的大小
    output axi_awburst,//突发类型，包括突发类型和突发大小信息，该字段决定了每次突发传输时地址的计算方法
    output axi_awlock,//锁定类型，提供关于传输时原子特性的额外信息
    output axi_awcache,//存储器类型
    output axi_awprot,//保护类型
    output axi_awqos,//服务质量，即每次写传输的QoS标识符，仅AXI4支持
    output axi_awregion,//区域标识符，允许一个从设备的单个物理接口用作多个逻辑接口，仅AXI4支持
    output axi_awuser,//用户定义信号，可选
    output reg axi_awvalid,//主设备给出的地址和相关控制信号有效
    input  axi_awready,//从设备已准备好接收地址和相关的控制信号

    //写数据通道信号
    output [DATA_WIDTH-1:0] axi_wdata,//写出的数据
    output [3:0] axi_wstrb,//数据的字节选通，数据中每8bit对应这里的1bit
    output axi_wlast,//该信号用于标识当前传输是否为突发传输中的最后一次传输
    output axi_wuser,//用户定义信号，可选
    output reg axi_wvalid,//主设备给出的数据和字节选通信号有效
    input axi_wready,//从设备已准备好接收数据选通信号

    //写响应通道信号
    input axi_bid,//写响应ID，该信号用于标识写响应传输
    input axi_bresp,//写响应，该信号表示写传输的状态
    input axi_buser,//用户定义信号，可选
    input axi_bvalid,//从设备给出的写响应信号有效
    output reg axi_bready,//主设备已准备好接收写响应信号

    //读地址通道信号
    output axi_arid,//读地址ID，该信号用于标识读地址组
    output [ADDR_WIDTH-1:0] axi_araddr,//读地址，读突发操作中第一次数据传输的地址
    output axi_arlen,//突发长度，这个字段标识每次突发传输的传输次数
    output axi_arsize,//突发大小，这个字段表示每次突发传输的大小
    output axi_arburst,//突发类型，包括突发类型和突发大小信息，该字段决定了每次突发传输时地址的计算方法
    output axi_arlock,//锁定类型，提供关于传输时原子特性的额外信息
    output axi_arcache,//存储器类型
    output axi_arprot,//保护类型
    output axi_arqos,//服务质量，即每次读传输的QoS标识符，仅AXI4支持
    output axi_arregion,//区域标识符，允许一个从设备的单个物理接口用作多个逻辑接口，仅AXI4支持
    output axi_aruser,//用户定义信号，可选
    output reg axi_arvalid,//主设备给出的地址和相关控制信号有效
    input axi_arready,//从设备已准备好接收地址和相关的控制信号

    //读数据通道
    input axi_rid,//读数据ID，该信号用于标识读数据传输
    input [DATA_WIDTH-1:0] axi_rdata,//读出的数据
    input axi_rresp,//读响应，这信号表示读传输的状态
    input axi_rlast,//该信号用于标识当前传输是否为突发传输中的最后一次传输
    input axi_ruser,//用户定义信号，可选
    input axi_rvalid,//从设备给出的数据和响应信息有效
    output reg axi_rready//主设备已准备好接收读取的数据和响应信息
);
//源端必须在令VALID信号有效之后再等待READY信号有效，一旦VALID有效，源端必须等待握手发生，即在保持VALID不变的情况下，等待目的端的READY信号有效。
//目的端可以在自身READY信号无效的情况下，等待源端的VALID信号有效，这一条规则和上一条规则必须同时遵守，否则可能造成死锁等待，同时，在VALID有效前，即使READY已经有效，也可以再次令READY无效。

//写地址通道
//主设备仅当输出有效的地址和控制信息时才能使能AWVALID信号，在从设备的AWREADY信号有效后的第一个时钟上升沿，主设备的AWVALID信号必须保持有效。
//AWREADY信号的默认状态可以为高也可以为低电平，规范推荐默认状态为高电平。当该信号为高电平时，意味着从设备一定可以接受任何有效的地址。
//注意：规范不推荐AWREADY信号默认为低电平是因为这会强制使传输周期拉长到至少两个时钟周期，一个周期用于使能AWVALID信号，另一个周期则用于使能AWREADY信号。
always@(posedge aclk)begin
    if(~aresetn)
        axi_awvalid<=0;
    else if(wvalid) 
        axi_awvalid<=1;
    else if(axi_awvalid && axi_awready)//握手成功后拉低
        axi_awvalid<=0;
    else
        axi_awvalid<=0;
end
assign axi_waddr = waddr;
//写数据通道
//在写突发过程中，主设备可以仅当它输出有效数据时才使能WVALID信号，同样的，该信号必须在从设备WREADY信号有效后的第一个时钟上升沿保持有效。
//WREADY信号默认可以为高电平，但这意味着从设备总是可以在一个时钟周期内接收待写入的数据。
//主设备在进行突发事务中的最后一次写传输时，必须令WLAST信号有效。
assign axi_wdata=wdata;
assign axi_wstrb = wlen==1?4'b0001:wlen==2?4'b0011:4'b1111;
always@(posedge aclk)begin
    if(~aresetn)
        axi_wvalid<=0;
    else if(wvalid)
        axi_wvalid<=1;
    else if(axi_wvalid&& axi_wready)
        axi_wvalid<=0;
    else
        axi_wvalid<=0;
end
assign wready=axi_wvalid&axi_wready;
//写响应通道
//从设备输出有效的写响应信号后才能驱动BVALID信号，该信号在BREADY信号有效后的第一个时钟上升沿保持有效。
//BREADY信号默认可以为高电平，但此时主设备必须总能在一个时钟周期内接收写响应。
// OKAY：一般访问成功。该信号表示一个一般访问成功，也表示一个独占访问失败。
// EXOKAY：独占访问成功。
// SLVERR：从设备错误。该信号表示向从设备的访问已成功，但从设备希望向原始主设备返回一个错误条件。
// DECERR：译码错误。通常由互联器生成，表示根据给定的事务地址找不到从设备。
always @(posedge aclk) begin
    if (~aresetn) begin
        axi_bready <= 1'b0;
    end else if (wvalid & ~axi_bready) begin  
        axi_bready <= 1'b1;
    end else begin 
        axi_bready<= 1'b0;
    end
end
//读地址通道
//主设备仅当输出有效的地址和控制信息时才能使能ARVALID信号，在从设备的AWREADY信号有效后的第一个时钟上升沿，主设备的ARVALID信号必须保持有效。
//ARREADY信号的默认状态可以为高也可以为低电平，规范推荐默认状态为高电平。当该信号为高电平时，意味着从设备一定可以接受任何有效的地址。
always@(posedge aclk)begin
    if(~aresetn)
        axi_arvalid<=0;
    else if(rvalid) 
        axi_arvalid<=1;
    else if(axi_arvalid && axi_arready)//握手成功后拉低
        axi_arvalid<=0;
    else
        axi_arvalid<=0;
end
assign axi_araddr = raddr;
//读数据通道
//从设备只有在输出有效读数据时才能使能RVALID信号，同时在主设备的RREADY信号有效后的第一个时钟上升沿必须保持有效。即使从设备只有一个读数据源，它也必须在收到数据请求时才令RVALID信号有效。
//主接口使用RREADY信号表示它可以接收数据，RREADY信号默认可以为高电平，但此时主设备启动读事务时必须能立即接收数据。
//从设备在进行突发传输事务中的最后一次传输时必须使能RLAST信号。
always@(posedge aclk)begin
    if(~aresetn)
        axi_rready<=0;
    else if(rvalid && axi_rvalid)
        axi_rready<=1;
    else
        axi_rready<=0;
end
assign rdata=axi_rdata;
assign rready=axi_rvalid&axi_rready;

endmodule
