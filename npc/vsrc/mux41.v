module mux41(input [1:0] Y,
input [1:0] X0,X1,X2,X3,
output[1:0] F);
MuxKeyWithDefault #(4,2,2) mux_2bits(
    .out         	(F          ),
    .key         	(Y          ),
    .default_out 	(1'b0  ),
    .lut         	({2'b00,X0,2'b01,X1,2'b10,X2,2'b11,X3})
);
endmodule








