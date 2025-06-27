module csr_reg (
    input clk,
    input rst,
    input wen,
    input [31:0] wdata1,
    input [11:0] csr_waddr1,
    input [31:0] wdata2,
    input [11:0] csr_waddr2,
    input [11:0] csr_raddr,
    output[31:0] rdata
);
    reg [31:0] csr_rf [7:0];//0:mstatus;1:mtvec;2:mepc;3:mcause 7:not valid
    wire [2:0] waddr1;
    wire [2:0] waddr2;
    wire [2:0] raddr;
    assign waddr1 = (csr_waddr1==12'h300) ? 3'b000:
                                                    (csr_waddr1==12'h305)?3'b001:
                                                    (csr_waddr1==12'h341)?3'b010:
                                                    (csr_waddr1==12'h342)?3'b011:3'b111;
    assign waddr2 = (csr_waddr2==12'h300) ? 0:
                                                    (csr_waddr2==12'h305)?1:
                                                    (csr_waddr2==12'h341)?2:
                                                    (csr_waddr2==12'h342)?3:7;
    assign raddr = (csr_raddr==12'h300) ? 0:
                                                    (csr_raddr==12'h305)?1:
                                                    (csr_raddr==12'h341)?2:
                                                    (csr_raddr==12'h342)?3:7;
    always @(posedge clk) begin
        if (rst)
            csr_rf[0]=32'h00001800;//mstatus=0x1800;
        else if (wen) begin
            csr_rf[waddr1] <= wdata1;
            csr_rf[waddr2] <= wdata2;
        end
    end
    assign rdata = csr_rf[raddr];
// import "DPI-C" function int csr_read(input int raddr,input int len,int flag);
// import "DPI-C" function void csr_write(int waddr,int wdata,int len);

// always@(posedge clk) begin
//     if(wen) begin
//         pmem_write(waddr,wdata,wdata_len);
//     end
// end
endmodule

