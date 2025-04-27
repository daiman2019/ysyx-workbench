module top(
    input clk,
    input rst,
    input [7:0] init,
    output [6:0] hout
);
    wire [7:0] lfsr_out;
    lfsr_8bits lfsr_test(
    .clk(clk),
    .rst(rst),
    .init(init),
    .lfsr_out(lfsr_out));

    data2seg show(.data(lfsr_out),
    .neg_show(1'b1),
    .hout(hout));

endmodule
