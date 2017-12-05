// old style interface definition to workaround unsupported hierarchical names in Vivado synthesis
// can't use functions.clog2 in synthesis
module ram_inference
(
    clk,
    en,
    we,
    addr,
    di,
    do
);
    `include "clog2_fun.v"
    parameter DATA_WIDTH = 4;
    parameter RAM_DEPTH = 5;
//    parameter DATA_WIDTH = 256;
//    parameter RAM_DEPTH = 640;
    localparam ADDRESS_BITS = clog2(RAM_DEPTH);

    input clk;
    input en;
    input we;
    input  [ADDRESS_BITS-1:0] addr;
    input  [DATA_WIDTH-1:0] di;
//    output [DATA_WIDTH-1:0] do;
//    output reg [DATA_WIDTH-1:0] do;
    output [DATA_WIDTH-1:0] do;
//--------------------end interface----------------

reg [DATA_WIDTH-1:0] ram [RAM_DEPTH-1:0];
reg [DATA_WIDTH-1:0] reg_do;
reg [DATA_WIDTH-1:0] reg_do_0;
assign do = reg_do;
always @(posedge clk) begin
    if (en)
    begin
        if (we)
            ram[addr] <= di;

        reg_do_0 <= ram[addr];
        reg_do <= reg_do_0;
    end
end

endmodule
