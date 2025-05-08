module counter(
    input clk,
    input clrn,
    input [7:0] code,
    input data_valid,
    output reg [7:0] number
);
always @(posedge clk) begin
    if(~clrn)
        number<=0;
    else
        if(data_valid && (code==8'hF0))
            number<=number+1;
        else
            number<=number;
end
endmodule

