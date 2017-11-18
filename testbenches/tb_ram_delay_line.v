//`timescale 1ns / 1ps
module tb_ram_delay_line (
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

localparam DATA_WIDTH = 8;
localparam DELAY = 100;

reg [DATA_WIDTH-1:0] data_in = 0;
always @(posedge clk) begin

data_in <= data_in + 1;
end

initial begin
#(2*DELAY+10)
$finish;
end

wire [DATA_WIDTH-1:0] data_out;
wire [DATA_WIDTH-1:0] ff_out;

ram_delay_line
#(
    .DATA_WIDTH(DATA_WIDTH),
    .DELAY(DELAY)
) DUT (
    .clk(clk),
    .ce(1'b1),
    .rst(1'b0),
    .data_in(data_in),
    //outputs
    .data_out(data_out)
);

delay_line
#(
    .N(DATA_WIDTH),
    .DELAY(DELAY)
) reference (
    .clk(clk),
    .ce(1'b1),
    .idata(data_in),
    //outputs
    .odata(ff_out)
);

endmodule
