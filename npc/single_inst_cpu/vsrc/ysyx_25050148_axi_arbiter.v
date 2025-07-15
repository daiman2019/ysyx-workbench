module ysyx_25050148_axi_arbiter #(parameter ADDR_WIDTH=32,DATA_WIDTH=32)(
    input clk,
    input rst,
    //IFU master interface
    //读地址通道
    input ifu_arvalid,
    input [ADDR_WIDTH-1:0] ifu_araddr,
    input ifu_arprot,
    output ifu_arready,
    //读数据通道
    output ifu_rvalid,
    output reg [DATA_WIDTH-1:0] ifu_rdata,
    output [1:0] ifu_rresp,
    input ifu_rready,
    //写地址通道
    input ifu_awvalid,
    input [ADDR_WIDTH-1:0] ifu_awaddr,
    input ifu_awprot,
    output ifu_awready,
    //写数据通道
    input ifu_wvalid,
    input [DATA_WIDTH-1:0] ifu_wdata,
    input [(DATA_WIDTH>>3)-1:0] ifu_wstrb,
    output ifu_wready,
    //写响应通道
    output ifu_bvalid,
    output [1:0] ifu_bresp,
    input ifu_bready,
    //LSU master interface
    input lsu_arvalid,
    input [ADDR_WIDTH-1:0] lsu_araddr,
    input lsu_arprot,
    output lsu_arready,
    //读数据通道
    output lsu_rvalid,
    output reg [DATA_WIDTH-1:0] lsu_rdata,
    output [1:0] lsu_rresp,
    input lsu_rready,
    //写地址通道
    input lsu_awvalid,
    input [ADDR_WIDTH-1:0] lsu_awaddr,
    input lsu_awprot,
    output lsu_awready,
    //写数据通道
    input lsu_wvalid,
    input [DATA_WIDTH-1:0] lsu_wdata,
    input [(DATA_WIDTH>>3)-1:0] lsu_wstrb,
    output lsu_wready,
    //写响应通道
    output lsu_bvalid,
    output [1:0] lsu_bresp,
    input lsu_bready,
    //sram slave interface
    //读地址通道
    output sram_arvalid,
    output [ADDR_WIDTH-1:0] sram_araddr,
    output sram_arprot,
    input sram_arready,
    //读数据通道
    input sram_rvalid,
    input [DATA_WIDTH-1:0] sram_rdata,
    input [1:0] sram_rresp,
    output sram_rready,
    //写地址通道
    output sram_awvalid,
    output [ADDR_WIDTH-1:0] sram_awaddr,
    output sram_awprot,
    input  sram_awready,
    //写数据通道
    output sram_wvalid,
    output [DATA_WIDTH-1:0] sram_wdata,
    output [(DATA_WIDTH>>3)-1:0] sram_wstrb,
    input sram_wready,
    //写响应通道
    input sram_bvalid,
    input [1:0] sram_bresp,
    output sram_bready
);
parameter IDLE=0,IFU_ACTIVE=1,LSU_ACTIVE=2;
reg [1:0] state,next;
reg is_read,is_write;
reg latched_awprot,latched_arprot;
reg [ADDR_WIDTH-1:0] latched_awaddr,latched_araddr;
always@(posedge clk)begin
    if(rst)
        state<=IDLE;
    else
        state<=next;
end
always@(*)begin
    case(state)
        IDLE:begin
            if(ifu_arvalid || ifu_awvalid)
                next=IFU_ACTIVE;
            else if(lsu_arvalid || lsu_awvalid)
                next=LSU_ACTIVE;
            else
                next=IDLE;
        end
        IFU_ACTIVE:begin
            if((is_write && sram_bvalid && sram_bready) || //如果已经完成IFU写
                (is_read && sram_rvalid && sram_rready)) begin//或者如果已经完成IFU读
                //检查是否有新请求
                if(ifu_awvalid || ifu_arvalid)
                    next = IFU_ACTIVE;
                else if(lsu_awvalid || lsu_arvalid)
                    next = LSU_ACTIVE;
                else
                    next = IDLE;
            end
            else
                next = IFU_ACTIVE;
        end
        LSU_ACTIVE:begin
            if((is_write && sram_bvalid && sram_bready) || //如果已经完成LSU写
                (is_read && sram_rvalid && sram_rready)) begin//或者如果已经完成LSU读
                //检查是否有新请求
                if(ifu_awvalid || ifu_arvalid)
                    next = IFU_ACTIVE;
                else if(lsu_awvalid || lsu_arvalid)
                    next = LSU_ACTIVE;
                else
                    next = IDLE;
            end
            else
                next = LSU_ACTIVE;
        end
    endcase
end
always@(posedge clk)begin
    if(rst) begin
        is_read<=0;
        is_write<=0;
    end
    else if(state==IDLE && next == IFU_ACTIVE) begin
        is_read <= ifu_arvalid;
        is_write <= ifu_awvalid;
    end
    else if(state==IDLE && next == LSU_ACTIVE)begin
        is_read <= lsu_arvalid;
        is_write <= lsu_awvalid;
    end
end
always@(posedge clk)begin
    if(state == IDLE && next == IFU_ACTIVE && ifu_awvalid) begin
        latched_awaddr <= ifu_awaddr;    
        latched_awprot <= ifu_awprot;    
    end
    if(state == IDLE && next == IFU_ACTIVE && ifu_arvalid)begin
        latched_araddr <= ifu_araddr;
        latched_arprot <= ifu_arprot;
    end
    //锁存LSU 地址、数据
    if(state == IDLE && next == LSU_ACTIVE && lsu_awvalid) begin
        latched_awaddr <= lsu_awaddr;    
        latched_awprot <= lsu_awprot;    
    end
    if(state == IDLE && next == LSU_ACTIVE && lsu_arvalid)begin
        latched_araddr <= lsu_araddr;
        latched_arprot <= lsu_arprot;
    end
end
//读地址通道
assign sram_arvalid = (state == IFU_ACTIVE && is_read)?ifu_arvalid :
                        (state == LSU_ACTIVE && is_read)?lsu_arvalid : 1'b0;
assign sram_araddr = (state == IFU_ACTIVE || state == LSU_ACTIVE)?latched_araddr:{ADDR_WIDTH{1'b0}};
assign sram_arprot = (state == IFU_ACTIVE || state == LSU_ACTIVE)?latched_arprot:0;
assign ifu_arready = (state == IFU_ACTIVE && is_read)?sram_arready:1'b0;
assign lsu_arready = (state == LSU_ACTIVE && is_read)?sram_arready:1'b0;
//读数据通道
assign ifu_rvalid = (state == IFU_ACTIVE && is_read)?sram_rvalid:0;
assign lsu_rvalid = (state == LSU_ACTIVE && is_read)?sram_rvalid:0;
assign ifu_rdata = sram_rdata;
assign lsu_rdata = sram_rdata;
assign ifu_rresp = sram_rresp;
assign lsu_rresp = sram_rresp;
assign sram_rready = (state == IFU_ACTIVE && is_read)?ifu_rready:
                        (state == LSU_ACTIVE && is_read)?lsu_rready:1'b0;
//写地址通道
assign sram_awvalid = (state == IFU_ACTIVE && is_write)?ifu_awvalid :
                        (state == LSU_ACTIVE && is_write)?lsu_awvalid : 1'b0;
assign sram_awaddr = (state == IFU_ACTIVE || state == LSU_ACTIVE)?latched_awaddr:{ADDR_WIDTH{1'b0}};
assign sram_awprot = (state == IFU_ACTIVE || state == LSU_ACTIVE)?latched_awprot:0;
assign ifu_awready = (state == IFU_ACTIVE && is_write)?sram_awready:1'b0;
assign lsu_awready = (state == LSU_ACTIVE && is_write)?sram_awready:1'b0;
//写数据通道
assign sram_wvalid = (state == IFU_ACTIVE && is_write)?ifu_wvalid :
                        (state == LSU_ACTIVE && is_write)?lsu_wvalid : 1'b0;
assign sram_wdata = (state == IFU_ACTIVE && ifu_wvalid && is_write)?ifu_wdata:
                    (state == LSU_ACTIVE && lsu_wvalid && is_write)?lsu_wdata:{DATA_WIDTH{1'b0}};
assign sram_wstrb = (state == IFU_ACTIVE && ifu_wvalid && is_write)?ifu_wstrb:
                    (state == LSU_ACTIVE && lsu_wvalid && is_write)?lsu_wstrb:{(DATA_WIDTH>>3){1'b0}};
assign ifu_wready = (state == IFU_ACTIVE && is_write)?sram_wready:1'b0;
assign lsu_wready = (state == LSU_ACTIVE && is_write)?sram_wready:1'b0;
//写响应通道
assign ifu_bvalid = (state == IFU_ACTIVE && is_write)?sram_bvalid:1'b0;
assign lsu_bvalid = (state == LSU_ACTIVE && is_write)?sram_bvalid:1'b0;
assign ifu_bresp = sram_bresp;
assign lsu_bresp = sram_bresp;
assign sram_bready = (state == IFU_ACTIVE && is_write)?ifu_bready:
                        (state == LSU_ACTIVE && is_write)?lsu_bready:1'b0;

endmodule
