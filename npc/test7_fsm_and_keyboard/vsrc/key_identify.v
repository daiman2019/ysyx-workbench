module key_counter(
        input clk,
        input resetn,
        input[7:0] data,
        output reg[7:0] counter
    );

always@(posedge clk)begin
    if(resetn==1'b0)begin
        counter<=8'b0;
    end
    else begin
        if(data==8'hf0)begin
            counter<=counter+1'b1;
        end
    end
end


endmodule
