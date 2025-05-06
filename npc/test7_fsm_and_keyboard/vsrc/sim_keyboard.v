`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/27 22:51:42
// Design Name: 
// Module Name: sim_keyboard
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


module keyboard_sim;

/* parameter */
parameter [31:0] clock_period = 10;

/* ps2_keyboard interface signals */
reg clk,clrn;
wire [7:0] data;
wire [7:0] data_my;
wire ready,overflow;
wire ready_my,overflow_my;
wire kbd_clk, kbd_data;
reg nextdata_n;
wire [7:0] number;
wire [41:0] hout;
ps2_keyboard_model model(
    .ps2_clk(kbd_clk),
    .ps2_data(kbd_data)
);

// ps2_keyboard inst(
//     .clk(clk),
//     .clrn(clrn),
//     .ps2_clk(kbd_clk),
//     .ps2_data(kbd_data),
//     .data(data),
//     .ready(ready),
//     .nextdata_n(nextdata_n),
//     .overflow(overflow)
// );
top_module  top_module_i (
    .clk               (clk),
    .clrn              (clrn),
    .ps2_clk           (kbd_clk),
    .ps2_data          (kbd_data),
    .data              (data_my),
    .ready             (ready_my),
    .overflow          (overflow_my),
    .sampling           (sampling_my),
    .number            (number),
    .hout               (hout)
);
initial begin /* clock driver */
    clk = 0;
    forever
        #(clock_period/2) clk = ~clk;
end

initial begin
    clrn = 1'b0;  #20;
    clrn = 1'b1;  #20;
    model.kbd_sendcode(8'h1C); // press 'A'
    #20 nextdata_n =1'b0; #20 nextdata_n =1'b1;//read data
    model.kbd_sendcode(8'hF0); // break code
    #20 nextdata_n =1'b0; #20 nextdata_n =1'b1; //read data
    model.kbd_sendcode(8'h1C); // release 'A'
    #20 nextdata_n =1'b0; #20 nextdata_n =1'b1; //read data
    model.kbd_sendcode(8'h1B); // press 'S'
    #20 model.kbd_sendcode(8'h1B); // keep pressing 'S'
    #20 model.kbd_sendcode(8'h1B); // keep pressing 'S'
    model.kbd_sendcode(8'hF0); // break code
    model.kbd_sendcode(8'h1B); // release 'S'
    #20;
    $stop;
end

endmodule