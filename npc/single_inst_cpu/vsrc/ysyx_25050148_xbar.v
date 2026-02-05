module ysyx_25050148_xbar #(parameter UART_ADDR = 32'ha00003f8)
(
    // 系统信号
    input  wire        clk,
    input  wire        rst,
    
    // AXI4-Lite主设备接口（来自Arbiter）
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awprot,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    
    input  wire [31:0] s_axi_wdata,
    input  wire [ 3:0] s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    
    output wire [ 1:0] s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    
    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // UART从设备接口
    output wire [31:0] device_awaddr,
    output wire        device_awprot,
    output wire        device_awvalid,
    input  wire        device_awready,
    
    output wire [31:0] device_wdata,
    output wire [ 3:0] device_wstrb,
    output wire        device_wvalid,
    input  wire        device_wready,
    
    input  wire [ 1:0] device_bresp,
    input  wire        device_bvalid,
    output wire        device_bready,
    
    output wire [31:0] device_araddr,
    output wire        device_arprot,
    output wire        device_arvalid,
    input  wire        device_arready,
    
    input  wire [31:0] device_rdata,
    input  wire [ 1:0] device_rresp,
    input  wire        device_rvalid,
    output wire        device_rready,
    
    // SRAM从设备接口
    output wire [31:0] sram_awaddr,
    output wire        sram_awprot,
    output wire        sram_awvalid,
    input  wire        sram_awready,
    
    output wire [31:0] sram_wdata,
    output wire [ 3:0] sram_wstrb,
    output wire        sram_wvalid,
    input  wire        sram_wready,
    
    input  wire [ 1:0] sram_bresp,
    input  wire        sram_bvalid,
    output wire        sram_bready,
    
    output wire [31:0] sram_araddr,
    output wire        sram_arprot,
    output wire        sram_arvalid,
    input  wire        sram_arready,
    
    input  wire [31:0] sram_rdata,
    input  wire [ 1:0] sram_rresp,
    input  wire        sram_rvalid,
    output wire        sram_rready
);

    parameter  IDLE = 0,WRITE_ADDR=1,WRITE_DATA=2,WRITE_RESP=3,READ_ADDR=4,READ_DATA=5;
    
    // 状态寄存器
    reg [2:0] state, next_state;
    
     // 地址锁存
    reg [31:0] locked_awaddr;
    reg [31:0] locked_araddr;
    reg        write_active;   // 写事务活跃标志
    reg        read_active;    // 读事务活跃标志
    
    // 选择信号
    wire uart_write_select;
    wire sram_write_select;
    wire uart_read_select;
    wire sram_read_select;
    
    // 事务完成标志
    wire write_transaction_done;
    wire read_transaction_done;
    
    // 地址锁存 - 与握手信号同步
    always @(posedge clk) begin
        if (rst) begin
            locked_awaddr  <= 32'h0;
            locked_araddr  <= 32'h0;
            write_active   <= 1'b0;
            read_active    <= 1'b0;
        end else begin
            // 写地址锁存
            if (s_axi_awvalid && s_axi_awready) begin
                locked_awaddr <= s_axi_awaddr;
                write_active  <= 1'b1;
            end else if (write_transaction_done) begin
                write_active  <= 1'b0;
            end
            
            // 读地址锁存
            if (s_axi_arvalid && s_axi_arready) begin
                locked_araddr <= s_axi_araddr;
                read_active   <= 1'b1;
            end else if (read_transaction_done) begin
                read_active   <= 1'b0;
            end
        end
    end
    
    // 状态机
    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 状态转移逻辑
    always @(*) begin
        case (state)
            IDLE:
                if (s_axi_awvalid)
                    next_state = WRITE_ADDR;
                else if (s_axi_arvalid)
                    next_state = READ_ADDR;
                else
                    next_state = IDLE;
                    
            WRITE_ADDR:
                if (s_axi_awready)
                    next_state = WRITE_DATA;
                else
                    next_state = WRITE_ADDR;
                    
            WRITE_DATA:
                if (s_axi_wvalid && s_axi_wready)
                    next_state = WRITE_RESP;
                else
                    next_state = WRITE_DATA;
                    
            WRITE_RESP:
                if (s_axi_bvalid && s_axi_bready)
                    next_state = IDLE;
                else
                    next_state = WRITE_RESP;
                    
            READ_ADDR:
                if (s_axi_arready)
                    next_state = READ_DATA;
                else
                    next_state = READ_ADDR;
                    
            READ_DATA:
                if (s_axi_rvalid && s_axi_rready)
                    next_state = IDLE;
                else
                    next_state = READ_DATA;
                    
            default:
                next_state = IDLE;
        endcase
    end
    
    // 事务完成标志
    assign write_transaction_done = (state == WRITE_RESP) && s_axi_bvalid && s_axi_bready;
    assign read_transaction_done  = (state == READ_DATA) && s_axi_rvalid && s_axi_rready;
    
    // 地址解码逻辑
    // 写事务：在握手时使用当前地址，握手后使用锁存地址
    // assign uart_write_select = 0;
    // assign sram_write_select = ((state == WRITE_ADDR))|| (write_active );
    // assign uart_read_select = 0;
                             
    // assign sram_read_select = ((state == READ_ADDR))||(read_active );


    assign uart_write_select = ((state == WRITE_ADDR)&&((s_axi_awaddr) == UART_ADDR))
                            || (write_active && ((locked_awaddr) == UART_ADDR));
                              
    assign sram_write_select = ((state == WRITE_ADDR)&&((s_axi_awaddr) != UART_ADDR))
                             || (write_active && ((locked_awaddr) != UART_ADDR));
                              
    //读事务：在握手时使用当前地址，握手后使用锁存地址
    assign uart_read_select = ((state == READ_ADDR) && ((s_axi_araddr) == UART_ADDR))||
                                (read_active && ((locked_araddr) == UART_ADDR));
                             
    assign sram_read_select = ((state == READ_ADDR) && ((s_axi_araddr) != UART_ADDR))||
                                (read_active && ((locked_araddr) != UART_ADDR));
    
    // 写地址通道路由
    assign device_awaddr  = s_axi_awaddr;  // 直接使用当前地址，确保握手时地址正确
    assign device_awprot  = s_axi_awprot;
    assign device_awvalid = s_axi_awvalid && uart_write_select;
    
    assign sram_awaddr  = s_axi_awaddr;  // 直接使用当前地址，确保握手时地址正确
    assign sram_awprot  = s_axi_awprot;
    assign sram_awvalid = s_axi_awvalid && sram_write_select;
    
    assign s_axi_awready = (uart_write_select && device_awready) || (sram_write_select && sram_awready);
    
    // 写数据通道路由
    assign device_wdata  = s_axi_wdata;
    assign device_wstrb  = s_axi_wstrb;
    assign device_wvalid = (state == WRITE_DATA) && s_axi_wvalid && write_active && uart_write_select;
    
    assign sram_wdata  = s_axi_wdata;
    assign sram_wstrb  = s_axi_wstrb;
    assign sram_wvalid = (state == WRITE_DATA) && s_axi_wvalid && write_active && sram_write_select;
    
    assign s_axi_wready = (uart_write_select && device_wready) || (sram_write_select && sram_wready);
    
    // 写响应通道路由
    assign s_axi_bresp  = uart_write_select ? device_bresp : sram_bresp;
    assign s_axi_bvalid = (state == WRITE_RESP) && ((uart_write_select && device_bvalid) || (sram_write_select && sram_bvalid));
    
    assign device_bready = (state == WRITE_RESP) && s_axi_bready && uart_write_select;
    assign sram_bready = (state == WRITE_RESP) && s_axi_bready && sram_write_select;
    
    // 读地址通道路由
    assign device_araddr  = s_axi_araddr;  // 直接使用当前地址，确保握手时地址正确
    assign device_arprot  = s_axi_arprot;
    assign device_arvalid = s_axi_arvalid && uart_read_select;
    
    assign sram_araddr  = s_axi_araddr;  // 直接使用当前地址，确保握手时地址正确
    assign sram_arprot  = s_axi_arprot;
    assign sram_arvalid = s_axi_arvalid && sram_read_select;
    
    assign s_axi_arready = (uart_read_select && device_arready) || (sram_read_select && sram_arready);
    
    // 读数据通道路由
    assign s_axi_rdata  = uart_read_select ? device_rdata : sram_rdata;
    assign s_axi_rresp  = uart_read_select ? device_rresp : sram_rresp;
    assign s_axi_rvalid = (state == READ_DATA) && ((uart_read_select && device_rvalid) || (sram_read_select && sram_rvalid));
    
    assign device_rready = (state == READ_DATA) && uart_read_select && s_axi_rready;
    assign sram_rready = (state == READ_DATA) && sram_read_select && s_axi_rready;

endmodule