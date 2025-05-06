`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/26 18:24:40
// Design Name: 
// Module Name: test_linearfeedbackshift
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


module test_linearfeedbackshift(

    );

    // top_module Parameters
parameter PERIOD  = 10;


// top_module Inputs
reg   clk                                  = 0 ;
reg   rst                                  = 1 ;
reg   [7:0]  init                          = 1 ;

// top_module Outputs
wire  [7:0]  data                          ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst  =  0;
end

top_module  u_top_module (
    .clk                     ( clk          ),
    .reset                   ( rst        ),
    .init                    ( init   [7:0] ),

    .data                    ( data   [7:0] )
);

endmodule
