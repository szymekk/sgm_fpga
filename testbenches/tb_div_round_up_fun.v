//`timescale 1ns / 1ps

module tb_div_round_up_fun(

    );

reg clk = 1'b0;
initial
begin
    while(1)
    begin
        #1 clk = 1'b0;
        #1 clk = 1'b1;
    end
end
//-----------------------------------------------

localparam BITS = 10;
reg [BITS-1:0] counter = 0;
always @(posedge clk)
begin
    counter <= counter + 1;
    if (600 == counter)
        $stop;
end

`include "div_round_up_fun.v"

wire [BITS-1:0] out_1 = div_round_up(counter, 0);
wire [BITS-1:0] out_2 = div_round_up(counter, 1);
wire [BITS-1:0] out_3 = div_round_up(counter, 18);
wire [BITS-1:0] out_4 = div_round_up(counter, 10);

endmodule // tb_div_round_up_fun
