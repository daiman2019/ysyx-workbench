module encode83(input [7:0] x,
input ena,
output [2:0] y,
output input_flag);
assign input_flag = ~(x==8'b0);
always@(*) begin
    if(ena) begin
    casez(x)
        8'b1zzzzzzz:y=3'd7;
        8'b01zzzzzz:y=3'd6;
        8'b001zzzzz:y=3'd5;
        8'b0001zzzz:y=3'd4;
        8'b00001zzz:y=3'd3;
        8'b000001zz:y=3'd2;
        8'b0000001z:y=3'd1;
        8'b00000001:y=3'd0;
        default:y=3'bxxx;
    endcasez
    end
    else begin
        y=3'b000;
    end 
end
endmodule








