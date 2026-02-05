module top #(DATA_WIDTH =32)(
    input clk,
    input rst,
    output reg [DATA_WIDTH-1:0] current_pc,
    output reg [DATA_WIDTH-1:0] npc,
    output [DATA_WIDTH-1:0] halt_ret,
    output reg difftest_en_t
);
wire [31:0] instruction;
wire [31:0] pc;
wire reg_wen,csr_wen,mem_read_flag;
wire [2:0] pc_jump;
wire [DATA_WIDTH-1:0] immdata;
wire [DATA_WIDTH-1:0] alu_result;
wire [DATA_WIDTH-1:0] reg_write_data;
wire [4:0] rs1;
wire [4:0] rs2;
wire [DATA_WIDTH-1:0] src1;
wire [DATA_WIDTH-1:0] src2;
wire [31:0] imm;
wire [4:0] rd;
wire [1:0] reg_data_flag;
wire [1:0] alu_left_opt,alu_right_opt;
wire [3:0] wmask;
wire [31:0] mem_read_data;
wire [1:0] mem_read_len,csr_wdata1_choice;
wire [3:0] alu_opt;
wire alu_branch_flag;
wire [2:0] inst_type;//0:Btype 1:Rtype 2:Itype
wire [2:0] func3;
wire [6:0] func7;
wire [31:0] next_pc_addr;
wire [11:0] csr_raddr;
wire [11:0] csr_waddr1;
wire [11:0] csr_waddr2;
wire [31:0] csr_wdata1;
wire [31:0] csr_wdata2;
wire [31:0] csr_rdata;
reg rst_t=1,ifu_req;
wire ifu_valid,idu_ready,idu_valid,exu_ready,exu_valid,lsu_ready,lsu_valid,wbu_ready,wbu_valid;
wire write_reg_en,write_csr_en;
wire [1:0] ls_flag;
//for axi
wire ifu_arvalid,ifu_arprot,ifu_arready,ifu_rvalid,ifu_rready,ifu_awvalid,ifu_awready,ifu_wvalid,ifu_wready,ifu_bvalid,ifu_bready;
wire [31:0] ifu_araddr,ifu_awaddr;
wire [DATA_WIDTH-1:0] ifu_rdata,ifu_wdata;
wire [1:0] ifu_rresp,ifu_bresp;
wire ifu_awprot;
wire [(DATA_WIDTH>>3)-1:0] ifu_wstrb;
wire lsu_arvalid,lsu_arprot,lsu_arready,lsu_rvalid,lsu_rready,lsu_awvalid,lsu_awprot,lsu_awready,lsu_wvalid,lsu_wready,lsu_bvalid,lsu_bready;
wire [31:0] lsu_araddr,lsu_awaddr;
wire [1:0] lsu_rresp,lsu_bresp;
wire [DATA_WIDTH-1:0] lsu_rdata,lsu_wdata;
wire [(DATA_WIDTH>>3)-1:0] lsu_wstrb;
//axi4-lite sram interface
wire sram_arvalid,sram_arprot,sram_arready,sram_rvalid,sram_rready,sram_awvalid,sram_awready,sram_wvalid,sram_wready,sram_bvalid,sram_bready;
wire [31:0] sram_araddr,sram_awaddr;
wire [DATA_WIDTH-1:0] sram_rdata,sram_wdata;
wire [1:0] sram_rresp,sram_bresp;
wire [(DATA_WIDTH>>3)-1:0] sram_wstrb;
wire sram_awprot;
//axi4-lite uart interface
wire device_arvalid,device_arprot,device_arready,device_rvalid,device_rready,device_awvalid,device_awready,device_wvalid,device_wready,device_bvalid,device_bready;
wire [31:0] device_araddr,device_awaddr;
wire [DATA_WIDTH-1:0] device_rdata,device_wdata;
wire [1:0] device_rresp,device_bresp;
wire [(DATA_WIDTH>>3)-1:0] device_wstrb;
wire device_awprot;
//axi4-lite arbiter slave interface
wire s_axi_arvalid,s_axi_arprot,s_axi_arready,s_axi_rvalid,s_axi_rready,s_axi_awvalid,s_axi_awready,s_axi_wvalid,s_axi_wready,s_axi_bvalid,s_axi_bready;
wire [31:0] s_axi_araddr,s_axi_awaddr;
wire [DATA_WIDTH-1:0] s_axi_rdata,s_axi_wdata;
wire [1:0] s_axi_rresp,s_axi_bresp;
wire [(DATA_WIDTH>>3)-1:0] s_axi_wstrb;
wire s_axi_awprot;
always@(posedge clk)begin
    rst_t<=rst;
end
always@(posedge clk)begin
    if(rst_t)
        ifu_req<=1;
    else if(wbu_valid)
        ifu_req<=1;
    else
        ifu_req<=0; 
end
always@(posedge clk) begin
    if(rst_t)
        npc<=0;
    else if(exu_valid)
        npc<=next_pc_addr;
    else
        npc<=npc;
end
always@(posedge clk) begin
    if(rst_t)
        current_pc<=0;
    else if(ifu_valid)
        current_pc<=pc;
    else
        current_pc<=current_pc;
end
always@(posedge clk)begin
    if(rst_t)
        difftest_en_t<=0;
    else
        difftest_en_t<=wbu_valid; 
end
//IFU
ysyx_25050148_ifu #(32,32) pipeline_ifu(
    .clk(clk),
    .rst(rst_t),
    .ifu_req(ifu_req),//ifu有读请求
    .idu_ready(idu_ready),//idu准备好接收指令
    .exu_valid(exu_valid),
    .next_pc(next_pc_addr),
    .ifu_valid(ifu_valid),//ifu输出指令有效
    .pc(pc),
    .inst(instruction),
    //AXI4-LITE INTERFACE
    .arvalid(ifu_arvalid),
    .araddr(ifu_araddr),
    .arprot(ifu_arprot),
    .arready(ifu_arready),
    //读数据通道
    .rvalid(ifu_rvalid),
    .rdata(ifu_rdata),
    .rresp(ifu_rresp),
    .rready(ifu_rready),
    //写地址通道
    .awvalid(ifu_awvalid),
    .awaddr(ifu_awaddr),
    .awprot(ifu_awprot),
    .awready(ifu_awready),
    //写数据通道
    .wvalid(ifu_wvalid),
    .wdata(ifu_wdata),
    .wstrb(ifu_wstrb),
    .wready(ifu_wready),
    //写响应通道
    .bvalid(ifu_bvalid),
    .bresp(ifu_bresp),
    .bready(ifu_bready)
);
//指令译码IDU
ysyx_25050148_idu pipeline_idu(
    .clk(clk),
    .rst(rst_t),
    .ifu_valid(ifu_valid),
    .instruction(instruction),
    .exu_ready(exu_ready),
    .idu_ready(idu_ready),
    .idu_valid(idu_valid),
    .rs1_r(rs1),//outputEX_MEM_mem_read_flag
    .rs2_r(rs2),
    .imm_r(imm),
    .rd_r(rd),
    .reg_data_flag_r(reg_data_flag),
    .pc_jump_r(pc_jump),
    .left_opt_r(alu_left_opt),
    .right_opt_r(alu_right_opt),
    .wmask_r(wmask),
    .mem_read_len_r(mem_read_len),
    .mem_read_flag_r(mem_read_flag),
    .reg_wen_r(reg_wen),
    .load_store_flag_r(ls_flag),
    .csr_raddr_r(csr_raddr),
    .csr_wen_r(csr_wen),
    .csr_wdata1_choice_r(csr_wdata1_choice),
    .csr_waddr1_r(csr_waddr1),
    .csr_waddr2_r(csr_waddr2),
    .alu_opt_r(alu_opt),
    .inst_type_r(inst_type),
    .func3_r(func3),
    .func7_r(func7)
);
//寄存器堆
RegisterFile #(5,32) regfiles(
    .clk(clk),
    .wen(write_reg_en&wbu_valid),
    .wdata(reg_write_data),
    .waddr(rd),
    .raddr1(rs1),
    .raddr2(rs2),
    .rdata1(src1),
    .rdata2(src2),
    .halt_ret(halt_ret));

ysyx_25050148_csr_reg csr_regs(
    .clk(clk),
    .rst(rst_t),
    .wen(write_csr_en&wbu_valid),
    .wdata1(csr_wdata1),
    .csr_waddr1(csr_waddr1),
    .wdata2(csr_wdata2),
    .csr_waddr2(csr_waddr2),
    .csr_raddr(csr_raddr),
    .rdata(csr_rdata)
    );
//EXU
ysyx_25050148_exu#(32) pipeline_exu(
    .clk(clk),
    .rst(rst_t),
    .instruction(instruction),
    .idu_valid(idu_valid),
    .lsu_ready(lsu_ready),
    .ifu_valid(ifu_valid),
    .alu_left_opt(alu_left_opt),
    .alu_right_opt(alu_right_opt),
    .pc(pc),
    .reg_src1(src1),
    .reg_src2(src2),
    .imm(imm),
    .alu_opt(alu_opt),
    .idu_pc_jump_flag(pc_jump),
    .idu_csr_pc(csr_rdata),
    .idu_inst_type(inst_type),//0:Btype 1:Rtype 2:Itype
    .idu_func3(func3),
    .idu_func7(func7),
    .exu_ready(exu_ready),
    .exu_valid(exu_valid),
    .exu_alu_out(alu_result),
    .next_pc_addr_r(next_pc_addr));
//LSU
ysyx_25050148_lsu #(32,32) pipeline_lsu(
    .clk(clk),
    .rst(rst_t),
    .exu_valid(exu_valid),//EXU模块发送数据有效
    .wbu_ready(wbu_ready),//WBU模块准备就绪
    .ls_flag(ls_flag),//0:load,1:store,2:others
    .read_len(mem_read_len),//0:1,1:2,2:4
    .read_flag(mem_read_flag),//0:unsigned 1:signed
    .raddr(alu_result),
    .waddr(alu_result),
    .wmask(wmask),
    .wdata_in(src2),//x[rs2] from idu
    .lsu_ready(lsu_ready),//LSU模块准备就绪
    .lsu_valid(lsu_valid),//LSU模块发送数据有效
    .mem_read_data(mem_read_data),
    //AXI4-LITE INTERFACE
    .arvalid(lsu_arvalid),
    .araddr(lsu_araddr),
    .arprot(lsu_arprot),
    .arready(lsu_arready),
    //读数据通道
    .rvalid(lsu_rvalid),
    .rdata(lsu_rdata),
    .rresp(lsu_rresp),
    .rready(lsu_rready),
    //写地址通道
    .awvalid(lsu_awvalid),
    .awaddr(lsu_awaddr),
    .awprot(lsu_awprot),
    .awready(lsu_awready),
    //写数据通道
    .wvalid(lsu_wvalid),
    .wdata(lsu_wdata),
    .wstrb(lsu_wstrb),
    .wready(lsu_wready),
    //写响应通道
    .bvalid(lsu_bvalid),
    .bresp(lsu_bresp),
    .bready(lsu_bready)
);
//WBU
ysyx_25050148_wbu pipeline_wbu(
    .clk(clk),
    .rst(rst_t),
    .ifu_valid(ifu_valid),
    .idu_valid(idu_valid),
    .lsu_valid(lsu_valid),//LSU模块发送数据有效
    .exu_valid(exu_valid),
    .reg_wen(reg_wen),
    .csr_wen(csr_wen),
    .csr_wdata1_choice(csr_wdata1_choice),
    .pc(pc),
    .src1(src1),
    .reg_data_flag(reg_data_flag),
    .csr_rdata(csr_rdata),
    .alu_result(alu_result),
    .mem_read_data(mem_read_data),
    .write_reg_en(write_reg_en),
    .write_csr_en(write_csr_en),
    .wbu_ready(wbu_ready),
    .wbu_valid(wbu_valid),
    .reg_write_data_r(reg_write_data),
    .csr_wdata1_r(csr_wdata1),
    .csr_wdata2_r(csr_wdata2)
    ); 
ysyx_25050148_axi_arbiter #(32,32) pipeline_axi_arbiter(
    .clk(clk),
    .rst(rst_t),
    //IFU master interface
    //读地址通道
    .ifu_arvalid(ifu_arvalid),
    .ifu_araddr(ifu_araddr),
    .ifu_arprot(ifu_arprot),
    .ifu_arready(ifu_arready),
    //读数据通道
    .ifu_rvalid(ifu_rvalid),
    .ifu_rdata(ifu_rdata),
    .ifu_rresp(ifu_rresp),
    .ifu_rready(ifu_rready),
    //写地址通道
    .ifu_awvalid(ifu_awvalid),
    .ifu_awaddr(ifu_awaddr),
    .ifu_awprot(ifu_awprot),
    .ifu_awready(ifu_awready),
    //写数据通道
    .ifu_wvalid(ifu_wvalid),
    .ifu_wdata(ifu_wdata),
    .ifu_wstrb(ifu_wstrb),
    .ifu_wready(ifu_wready),
    //写响应通道
    .ifu_bvalid(ifu_bvalid),
    .ifu_bresp(ifu_bresp),
    .ifu_bready(ifu_bready),
    //LSU master interface
    .lsu_arvalid(lsu_arvalid),
    .lsu_araddr(lsu_araddr),
    .lsu_arprot(lsu_arprot),
    .lsu_arready(lsu_arready),
    //读数据通道
    .lsu_rvalid(lsu_rvalid),
    .lsu_rdata(lsu_rdata),
    .lsu_rresp(lsu_rresp),
    .lsu_rready(lsu_rready),
    //写地址通道
    .lsu_awvalid(lsu_awvalid),
    .lsu_awaddr(lsu_awaddr),
    .lsu_awprot(lsu_awprot),
    .lsu_awready(lsu_awready),
    //写数据通道
    .lsu_wvalid(lsu_wvalid),
    .lsu_wdata(lsu_wdata),
    .lsu_wstrb(lsu_wstrb),
    .lsu_wready(lsu_wready),
    //写响应通道
    .lsu_bvalid(lsu_bvalid),
    .lsu_bresp(lsu_bresp),
    .lsu_bready(lsu_bready),
    //sram slave interface
    //读地址通道
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arprot(s_axi_arprot),
    .s_axi_arready(s_axi_arready),
    //读数据通道
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rready(s_axi_rready),
    //写地址通道
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awprot(s_axi_awprot),
    .s_axi_awready(s_axi_awready),
    //写数据通道
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wready(s_axi_wready),
    //写响应通道
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_bready(s_axi_bready)
);
//xbar interconnect
ysyx_25050148_xbar pipeline_xbar(
    .clk(clk),
    .rst(rst_t),
    // Slave Interface from arbiter
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awprot(s_axi_awprot),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),

    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),

    .s_axi_araddr(s_axi_araddr),
    .s_axi_arprot(s_axi_arprot),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    //slave interface to device
    .device_awaddr(device_awaddr),
    .device_awprot(device_awprot),
    .device_awvalid(device_awvalid),
    .device_awready(device_awready),

    .device_wdata(device_wdata),
    .device_wstrb(device_wstrb),
    .device_wvalid(device_wvalid),
    .device_wready(device_wready),
    .device_bresp(device_bresp),
    .device_bvalid(device_bvalid),
    .device_bready(device_bready),
    //读地址通道
    .device_araddr(device_araddr),
    .device_arprot(device_arprot),
    .device_arvalid(device_arvalid),
    .device_arready(device_arready),
    //读数据通道
    .device_rdata(device_rdata),
    .device_rresp(device_rresp),
    .device_rvalid(device_rvalid),
    .device_rready(device_rready),
    //slave interface to sram
    .sram_awaddr(sram_awaddr),
    .sram_awprot(sram_awprot),
    .sram_awvalid(sram_awvalid),
    .sram_awready(sram_awready),
    .sram_wdata(sram_wdata),
    .sram_wstrb(sram_wstrb),
    .sram_wvalid(sram_wvalid),
    .sram_wready(sram_wready),
    .sram_bresp(sram_bresp),
    .sram_bvalid(sram_bvalid),
    .sram_bready(sram_bready),
    //读地址通道
    .sram_araddr(sram_araddr),
    .sram_arprot(sram_arprot),
    .sram_arvalid(sram_arvalid),
    .sram_arready(sram_arready),
    //读数据通道
    .sram_rdata(sram_rdata),
    .sram_rresp(sram_rresp),
    .sram_rvalid(sram_rvalid),
    .sram_rready(sram_rready)
);
//uart
ysyx_25050148_uart #(32,32) pipeline_uart 
(
    //slave
    .clk(clk),
    .rst(rst_t),
    //AXI4-lite
    //读地址通道
    .arvalid(device_arvalid),
    .araddr(device_araddr),
    .arprot(device_arprot),
    .arready(device_arready),
    //读数据通道
    .rvalid(device_rvalid),
    .rdata(device_rdata),
    .rresp(device_rresp),
    .rready(device_rready),
    //写地址通道
    .awvalid(device_awvalid),
    .awaddr(device_awaddr),
    .awprot(device_awprot),
    .awready(device_awready),
    //写数据通道
    .wvalid(device_wvalid),
    .wdata(device_wdata),
    .wstrb(device_wstrb),
    .wready(device_wready),
    //写响应通道
    .bvalid(device_bvalid),
    .bresp(device_bresp),
    .bready(device_bready)
);
//sram
ysyx_25050148_sram #(32,32) pipeline_sram(
    .clk(clk),
    .rst(rst_t),
    //AXI4-lite
    //读地址通道
    .arvalid(sram_arvalid),
    .araddr(sram_araddr),
    .arprot(sram_arprot),
    .arready(sram_arready),
    //读数据通道
    .rvalid(sram_rvalid),
    .rdata(sram_rdata),
    .rresp(sram_rresp),
    .rready(sram_rready),
    //写地址通道
    .awvalid(sram_awvalid),
    .awaddr(sram_awaddr),
    .awprot(sram_awprot),
    .awready(sram_awready),
    //写数据通道
    .wvalid(sram_wvalid),
    .wdata(sram_wdata),
    .wstrb(sram_wstrb),
    .wready(sram_wready),
    //写响应通道
    .bvalid(sram_bvalid),
    .bresp(sram_bresp),
    .bready(sram_bready)
);


endmodule
