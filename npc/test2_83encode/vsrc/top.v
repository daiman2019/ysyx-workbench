module top(input [7:0] x,
        input ena,
        output reg [2:0] y,
        output input_flag,
        output [6:0] hout);
 
    encode83 encoder(.x(x),
     .ena(ena),
     .y(y),
     .input_flag(input_flag)); // instantiation of encode83 module

    data2seg decoder(.data({1'b0,y}),.neg_show(1'b1),.hout(hout));


endmodule










