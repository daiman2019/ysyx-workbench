module top(
    input clk,clrn,ps2_clk,ps2_data,
    input nextdata_n,
    output [7:0] data,
    output reg ready,
    output reg overflow,     // fifo overflow
    output [41:0] hout
);
    wire [7:0] counter;
    wire [7:0] ascii;
    wire [7:0] data;
    wire nextdata_n;
    //接受键盘送来的数据
    ps2_keyboard keyboard(.clk(clk),
                .clrn(clrn),
                .ps2_clk(ps2_clk),
                .ps2_data(ps2_data),
                .data(data),
                .ready(ready),
                .nextdata_n(nextdata_n),
                .overflow(overflow));
    assign data = ready?data:8'b0;

    always@(posedge clk)begin
        if(ready&&~overflow)
            nextdata_n<=0;
        else
            nextdata_n<=1;
    end

    //统计按键次数
    key_counter counter_numbers(
        .clk(clk),
        .resetn(clrn),
        .data(data),
        .counter(counter)
    );
    
    //将扫描码转换为ASCII码
    scan_code2ascii(
    .data(data),
    .ascii(ascii));
    //显示按键
    data2seg show_first(.data(data[3:0]),
    .neg_show(1'b0),
    .hout(hout[6:0]));

    data2seg show_second(.data(data[7:4]),
    .neg_show(1'b0),
    .hout(hout[13:7]));

    //ASCII
    data2seg show_third(.data(ascii[3:0]),
    .neg_show(1'b0),
    .hout(hout[20:14]));

    data2seg show_forth(.data(ascii[7:4]),
    .neg_show(1'b0),
    .hout(hout[27:21]));

    //show key numbers
    data2seg show_fifth(.data(counter[3:0]),
    .neg_show(1'b0),
    .hout(hout[34:28]));

    data2seg show_sixth(.data(counter[7:4]),
    .neg_show(1'b0),
    .hout(hout[41:35]));

endmodule
