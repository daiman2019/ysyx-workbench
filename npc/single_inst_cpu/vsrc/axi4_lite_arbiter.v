module axi4_lite_arbiter #(
    parameter ADDR_WIDTH = 32,  // 地址位宽
    parameter DATA_WIDTH = 32    // 数据位宽
)(
    input         ACLK,
    input         ARESETn,
    
    // Master 0 Interface
    input [ADDR_WIDTH-1:0]  m0_axi_awaddr,
    input                   m0_axi_awvalid,
    output reg              m0_axi_awready,
    input [DATA_WIDTH-1:0]  m0_axi_wdata,
    input [(DATA_WIDTH/8)-1:0] m0_axi_wstrb,
    input                   m0_axi_wvalid,
    output reg              m0_axi_wready,
    output reg              m0_axi_bvalid,
    input                   m0_axi_bready,
    output [1:0]            m0_axi_bresp,
    input [ADDR_WIDTH-1:0]  m0_axi_araddr,
    input                   m0_axi_arvalid,
    output reg              m0_axi_arready,
    output reg              m0_axi_rvalid,
    input                   m0_axi_rready,
    output [DATA_WIDTH-1:0] m0_axi_rdata,
    output [1:0]            m0_axi_rresp,
    
    // Master 1 Interface
    input [ADDR_WIDTH-1:0]  m1_axi_awaddr,
    input                   m1_axi_awvalid,
    output reg              m1_axi_awready,
    input [DATA_WIDTH-1:0]  m1_axi_wdata,
    input [(DATA_WIDTH/8)-1:0] m1_axi_wstrb,
    input                   m1_axi_wvalid,
    output reg              m1_axi_wready,
    output reg              m1_axi_bvalid,
    input                   m1_axi_bready,
    output [1:0]            m1_axi_bresp,
    input [ADDR_WIDTH-1:0]  m1_axi_araddr,
    input                   m1_axi_arvalid,
    output reg              m1_axi_arready,
    output reg              m1_axi_rvalid,
    input                   m1_axi_rready,
    output [DATA_WIDTH-1:0] m1_axi_rdata,
    output [1:0]            m1_axi_rresp,
    
    // Slave Interface
    output reg [ADDR_WIDTH-1:0] s_axi_awaddr,
    output reg                  s_axi_awvalid,
    input                       s_axi_awready,
    output reg [DATA_WIDTH-1:0] s_axi_wdata,
    output reg [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    output reg                  s_axi_wvalid,
    input                       s_axi_wready,
    input [1:0]                 s_axi_bresp,
    input                       s_axi_bvalid,
    output reg                  s_axi_bready,
    output reg [ADDR_WIDTH-1:0] s_axi_araddr,
    output reg                  s_axi_arvalid,
    input                       s_axi_arready,
    input [DATA_WIDTH-1:0]      s_axi_rdata,
    input [1:0]                 s_axi_rresp,
    input                       s_axi_rvalid,
    output reg                  s_axi_rready
);

// 本地计算参数
localparam STRB_WIDTH = DATA_WIDTH/8;

// 状态定义
localparam IDLE    = 2'b00;
localparam GRANTED = 2'b01;
reg [1:0] state;
reg [1:0] next_state;

reg selected_master; // 0: Master0, 1: Master1
reg active_transaction; // 0: 读事务, 1: 写事务

// 同步复位状态机
always @(posedge ACLK) begin
    if (!ARESETn) begin
        state <= IDLE;
        active_transaction <= 1'b0;
    end else begin
        state <= next_state;
        
        // 记录当前活动事务类型
        if (state == IDLE && next_state == GRANTED) begin
            // 优先判断写请求
            if ((selected_master == 0 && m0_axi_awvalid) || (selected_master == 1 && m1_axi_awvalid)) begin
                active_transaction <= 1'b1; // 写事务
            end else begin
                active_transaction <= 1'b0; // 读事务
            end
        end
    end
end

// 仲裁逻辑
always @(*) begin
    next_state = state;
    selected_master = 1'b0;
    
    case (state)
        IDLE: begin
            // 优先级：Master0 > Master1
            if (m0_axi_awvalid || m0_axi_arvalid) begin
                next_state = GRANTED;
                selected_master = 1'b0;
            end else if (m1_axi_awvalid || m1_axi_arvalid) begin
                next_state = GRANTED;
                selected_master = 1'b1;
            end
        end
        GRANTED: begin
            // 等待事务完成 - 根据当前事务类型判断
            if (active_transaction) begin
                // 写事务完成条件：收到写响应
                if (s_axi_bvalid && s_axi_bready) begin
                    next_state = IDLE;
                end
            end else begin
                // 读事务完成条件：返回所有数据
                if (s_axi_rvalid && s_axi_rready) begin
                    next_state = IDLE;
                end
            end
        end
        default: begin
            next_state = IDLE;
        end
    endcase
end

// 地址/数据通道路由
always @(*) begin
    // 默认值
    s_axi_awvalid = 1'b0;
    s_axi_awaddr  = {ADDR_WIDTH{1'b0}};
    s_axi_arvalid = 1'b0;
    s_axi_araddr  = {ADDR_WIDTH{1'b0}};
    s_axi_wvalid  = 1'b0;
    s_axi_wdata   = {DATA_WIDTH{1'b0}};
    s_axi_wstrb   = {STRB_WIDTH{1'b0}};
    
    m0_axi_awready = 1'b0;
    m0_axi_arready = 1'b0;
    m0_axi_wready  = 1'b0;
    m1_axi_awready = 1'b0;
    m1_axi_arready = 1'b0;
    m1_axi_wready  = 1'b0;
    
    if (state == GRANTED) begin
        if (selected_master == 1'b0) begin // Master0
            // 地址通道
            s_axi_awvalid = m0_axi_awvalid;
            s_axi_awaddr  = m0_axi_awaddr;
            m0_axi_awready = s_axi_awready;
            
            s_axi_arvalid = m0_axi_arvalid;
            s_axi_araddr  = m0_axi_araddr;
            m0_axi_arready = s_axi_arready;
            
            // 写通道
            s_axi_wvalid = m0_axi_wvalid;
            s_axi_wdata  = m0_axi_wdata;
            s_axi_wstrb  = m0_axi_wstrb;
            m0_axi_wready = s_axi_wready;
        end
        else begin // Master1
            // 地址通道
            s_axi_awvalid = m1_axi_awvalid;
            s_axi_awaddr  = m1_axi_awaddr;
            m1_axi_awready = s_axi_awready;
            
            s_axi_arvalid = m1_axi_arvalid;
            s_axi_araddr  = m1_axi_araddr;
            m1_axi_arready = s_axi_arready;
            
            // 写通道
            s_axi_wvalid = m1_axi_wvalid;
            s_axi_wdata  = m1_axi_wdata;
            s_axi_wstrb  = m1_axi_wstrb;
            m1_axi_wready = s_axi_wready;
        end
    end
end

// ====== 修复的响应通道控制 ======
// 直接连接READY信号
assign s_axi_bready = (selected_master == 1'b0) ? m0_axi_bready : m1_axi_bready;
assign s_axi_rready = (selected_master == 1'b0) ? m0_axi_rready : m1_axi_rready;

// 响应VALID信号控制
always @(posedge ACLK) begin
    if (!ARESETn) begin
        m0_axi_bvalid <= 1'b0;
        m1_axi_bvalid <= 1'b0;
        m0_axi_rvalid <= 1'b0;
        m1_axi_rvalid <= 1'b0;
    end else begin
        // 写响应
        if (s_axi_bvalid && s_axi_bready) begin
            if (selected_master == 1'b0) begin
                m0_axi_bvalid <= 1'b1;
                m1_axi_bvalid <= 1'b0;
            end else begin
                m1_axi_bvalid <= 1'b1;
                m0_axi_bvalid <= 1'b0;
            end
        end else begin
            if (m0_axi_bready) m0_axi_bvalid <= 1'b0;
            if (m1_axi_bready) m1_axi_bvalid <= 1'b0;
        end
        
        // 读响应
        if (s_axi_rvalid && s_axi_rready) begin
            if (selected_master == 1'b0) begin
                m0_axi_rvalid <= 1'b1;
                m1_axi_rvalid <= 1'b0;
            end else begin
                m1_axi_rvalid <= 1'b1;
                m0_axi_rvalid <= 1'b0;
            end
        end else begin
            if (m0_axi_rready) m0_axi_rvalid <= 1'b0;
            if (m1_axi_rready) m1_axi_rvalid <= 1'b0;
        end
    end
end

// 响应信号直连
assign m0_axi_bresp = s_axi_bresp;
assign m1_axi_bresp = s_axi_bresp;
assign m0_axi_rresp = s_axi_rresp;
assign m1_axi_rresp = s_axi_rresp;
assign m0_axi_rdata = s_axi_rdata;
assign m1_axi_rdata = s_axi_rdata;

endmodule