module lfsr_8bits(
    input clk,
    input rst,
    input [7:0] init,
    output reg [7:0] lfsr_out
);
    always @(posedge clk) begin
        if (rst) begin
            lfsr_out <= init;
        end else begin
            if (init == 8'b0) begin
                lfsr_out <= 8'b1; // Initialize LFSR to a non-zero value
            end else begin
                lfsr_out <= {lfsr_out[0] ^ lfsr_out[2] ^ lfsr_out[3] ^ lfsr_out[4],lfsr_out[7:1]};
            end
        end
    end
endmodule
