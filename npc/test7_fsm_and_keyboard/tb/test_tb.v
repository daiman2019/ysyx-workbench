`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/26 17:39:11
// Design Name: 
// Module Name: test_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test_tb(

    );
// test1 Parameters
parameter PERIOD  = 10;


// test1 Inputs
reg                                       clk = 1;
reg                                       rst = 1;
reg   [7:0]  din                           = 0 ;
reg   [2:0]  shamt                         = 0 ;
reg   l_or_r                               = 0 ;
reg   a_or_l                               = 0 ;

// test1 Outputs
wire  [7:0]  dout                          ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst  =  0;
end

test1  u_test1 (
    .din                     ( din     [7:0] ),
    .shamt                   ( shamt   [2:0] ),
    .l_or_r                  ( l_or_r        ),
    .a_or_l                  ( a_or_l        ),

    .dout                    ( dout    [7:0] )
);


reg [7:0]   time_cnt;

always @(posedge clk) begin
    if(rst)
        time_cnt <= 0;
    else
        time_cnt <= time_cnt + 1;
end

always @(posedge clk) begin
    if(time_cnt == 10)begin
        din     <= 8'b1010_1010;
        shamt   <= 5;
        l_or_r  <= 0;
        a_or_l  <= 0;
    end
    else if(time_cnt == 11) begin
        din     <= 8'b1010_1010;
        shamt   <= 3;
        l_or_r  <= 0;
        a_or_l  <= 1;
    end
    else if(time_cnt == 12) begin
        din     <= 8'b1010_1010;
        shamt   <= 2;
        l_or_r  <= 1;
        a_or_l  <= 0;
    end
    else if(time_cnt == 13)begin
        din     <= 8'b1010_1010;
        shamt   <= 7;
        l_or_r  <= 1;
        a_or_l  <= 1;
    end

end


endmodule
