module ysyx_25050148_ifu#(ADDR_WIDTH = 32 ,DATA_WIDTH =32)(
    input clk,
    input rst,
    input ifu_req,//ifu有读请求,此时pc有效
    input idu_ready,//idu准备好接收指令
    input exu_valid,
    input [ADDR_WIDTH-1:0] next_pc,//exu_valid有效时，next_pc有效
    output reg ifu_valid,//ifu输出指令有效
    output reg [ADDR_WIDTH-1:0] pc,
    output reg [DATA_WIDTH-1:0] inst,
    //AXI4-LITE INTERFACE
    output arvalid,
    output [ADDR_WIDTH-1:0] araddr,
    output arprot,
    input arready,
    //读数据通道
    input rvalid,
    input [DATA_WIDTH-1:0] rdata,
    input [1:0] rresp,
    output rready,
    //写地址通道
    output awvalid,
    output [ADDR_WIDTH-1:0] awaddr,
    output awprot,
    input awready,
    //写数据通道
    output wvalid,
    output [DATA_WIDTH-1:0] wdata,
    output [(DATA_WIDTH>>3)-1:0] wstrb,
    input wready,
    //写响应通道
    input bvalid,
    input [1:0] bresp,
    output bready
);
//update pc and fetch inst from inst mem/sram
//update pc
reg [1:0] state,next;
parameter idle=0,fetch_addr=1,fetch_data=2;
always@(posedge clk) begin
    if(rst)
        state<=idle;
    else
        state<=next;
end
always@(*)begin
    case(state)
        idle:begin
            if(ifu_req) 
                next=fetch_addr;
            else
                next=idle;
        end
        fetch_addr:begin
            if(arready&&arvalid)//本次读地址操作成功
                next=fetch_data;
            else
                next=fetch_addr;
        end
        fetch_data:begin
            if(rready&&rvalid)//本次读操作成功
                next=idle;
            else
                next=fetch_data;
        end
        default:next=idle;
    endcase
end
always@(posedge clk) begin
    if(rst)
        pc<=32'h80000000;
    else if(exu_valid)
        pc<=next_pc;
    else
        pc<=pc;
end
always@(posedge clk) begin
    if(rst)
        araddr<=32'd0;
    else if(ifu_req)
        araddr<=pc;
    else
        araddr<=araddr;
end
assign arvalid = (state==fetch_addr);
assign rready = (state==fetch_data);
//assign ifu_valid = rvalid&&rready;
always@(posedge clk)begin
    if(rvalid&&rready) begin
        inst<=rdata;
        ifu_valid<=1;
    end
    else if(idu_ready) begin
        inst<=32'd0;
        ifu_valid<=0;
    end
    else begin
        inst<=inst;
        ifu_valid<=ifu_valid;
    end
end
assign arprot = 0;
// not use write channels
assign awvalid = 1'b0;
assign awaddr = 0;
assign awprot = 0;
assign wvalid = 0;
assign wdata = 0;
assign wstrb = 0;
assign bready =0;
//fetch inst form inst mem
// ysyx_25050148_sram #(32,32) inst_sram(
//     .clk(clk),
//     .rst(rst),
//     //AXI4-lite
//     //读地址通道
//     .arvalid(arvalid),
//     .araddr(read_addr),
//     .arprot(1'b0),
//     .arready(arready),
//     //读数据通道
//     .rvalid(rvalid),
//     .rdata(fetch_inst),
//     .rresp(),
//     .rready(rready),
//     //写地址通道
//     .awvalid(1'b0),
//     .awaddr(32'd0),
//     .awprot(1'b0),
//     .awready(),
//     //写数据通道
//     .wvalid(1'b0),
//     .wdata(32'd0),
//     .wstrb(0),
//     .wready(),
//     //写响应通道
//     .bvalid(),
//     .bresp(),
//     .bready(1'b0)
// );
endmodule

