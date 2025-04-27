module top(
    input clk,
    input rst,
    input [7:0] init,
    output [13:0] hout
);
    wire [7:0] lfsr_out;
    lfsr_8bits lfsr_test(
    .clk(clk),
    .rst(rst),
    .init(init),
    .lfsr_out(lfsr_out));

    data2seg show_low(.data(lfsr_out[3:0]),
    .neg_show(1'b0),
    .hout(hout[6:0]));

    data2seg show_high(.data(lfsr_out[7:4]),
    .neg_show(1'b0),
    .hout(hout[13:7]));

endmodule
