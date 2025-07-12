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
    output reg difftest_en
);
//update pc and fetch inst from inst mem/sram
//update pc
reg [1:0] state,next;
parameter idle=0,fetch_addr=1,fetch_data=2;
wire arvalid,arready,rready,rvalid;
wire [31:0] fetch_inst;
reg [31:0] read_addr;
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
    if(pc!=next_pc)
        difftest_en<=1;
    else
        difftest_en<=0;
end
always@(posedge clk) begin
    if(rst)
        read_addr<=32'd0;
    else if(ifu_req)
        read_addr<=pc;
    else
        read_addr<=read_addr;
end
assign arvalid = (state==fetch_addr);
assign rready = (state==fetch_data);
//assign ifu_valid = rvalid&&rready;
always@(posedge clk)begin
    if(rvalid&&rready) begin
        inst<=fetch_inst;
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
//assign inst = (ifu_valid)?fetch_inst:32'd0;
//fetch inst form inst mem
ysyx_25050148_sram #(32,32) inst_sram(
    .clk(clk),
    .rst(rst),
    //AXI4-lite
    //读地址通道
    .arvalid(arvalid),
    .araddr(read_addr),
    .arprot(1'b0),
    .arready(arready),
    //读数据通道
    .rvalid(rvalid),
    .rdata(fetch_inst),
    .rresp(),
    .rready(rready),
    //写地址通道
    .awvalid(1'b0),
    .awaddr(32'd0),
    .awprot(1'b0),
    .awready(),
    //写数据通道
    .wvalid(1'b0),
    .wdata(32'd0),
    .wstrb(0),
    .wready(),
    //写响应通道
    .bvalid(),
    .bresp(),
    .bready(1'b0)
);
endmodule

