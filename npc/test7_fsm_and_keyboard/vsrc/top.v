module top (
    input clk,
    input clrn,   // Synchronous reset
    input ps2_clk,
    input ps2_data,
    output [7:0] data,
    output ready,
    output overflow,
    output sampling,
    output [7:0] number,
    output [41:0] hout
);
    reg [7:0] out_data;
    reg nextdata_n;
    reg data_valid;
    wire [7:0] ascii;
    reg ready_before;
    ps2_keyboard  ps2_keyboard_i (
    .clk               (clk),
    .clrn              (clrn),
    .ps2_clk           (ps2_clk),
    .ps2_data          (ps2_data),
    .nextdata_n        (nextdata_n),
    .ready             (ready),
    .data              (data),
    .overflow          (overflow),
    .sampling           (sampling)
);
    always@(posedge clk)begin
        if(~ready_before & ready)
            data_valid<=1;
        else
            data_valid<=0;
    end   

    always@(posedge clk)begin
        if(~ready_before & ready)
            out_data<=data;
        else
            out_data<=0;//out_data
    end
    always@(posedge clk)begin
        ready_before<=ready;
    end
    always@(posedge clk)begin
        if(~ready_before & ready)
            nextdata_n<=0;
        else
            nextdata_n<=1;
    end

    // scan code to ascii
    scan_code2ascii transfer(
    .data(out_data),
    .ascii(ascii));
    //counter
    counter  counter_i (
    .clk               (clk),
    .clrn              (clrn),
    .code              (out_data),
    .data_valid        (data_valid),
    .number            (number)
);
    //show
    data2seg show_first(.data(out_data[3:0]),
    .neg_show(1'b0),
    .hout(hout[6:0]));

    data2seg show_second(.data(out_data[7:4]),
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
    data2seg show_fifth(.data(number[3:0]),
    .neg_show(1'b0),
    .hout(hout[34:28]));

    data2seg show_sixth(.data(number[7:4]),
    .neg_show(1'b0),
    .hout(hout[41:35]));

endmodule
