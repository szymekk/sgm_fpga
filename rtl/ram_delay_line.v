module ram_delay_line
#(
    parameter DATA_WIDTH = 4,
    parameter DELAY = 5
)
(
    input clk,
    input ce,
    input rst,
    input  [DATA_WIDTH-1:0] data_in,
    //outputs
    output [DATA_WIDTH-1:0] data_out
);
`include "../util/clog2_fun.v"
localparam RAM_DEPTH = DELAY - 1;
localparam ADDRESS_BITS = clog2(RAM_DEPTH);


reg [ADDRESS_BITS-1:0] position = 0;
// address generator for circular register
always @(posedge clk)
begin
    if ( ce == 1'b1)
    begin
        if (rst == 1'b1)
        begin
            position <= 0;
        end
        else
        begin
            position <= position+1;
//            if (position == RAM_DEPTH-1) // currently ram has 1 latency
            if (position == RAM_DEPTH-2) // use with ram having 2 latency
            begin
                position <= 0;
            end
        end
    end
end

wire [DATA_WIDTH-1:0] w_d_in;
wire [DATA_WIDTH-1:0] w_d_out;

ram_inference #(
    .DATA_WIDTH(DATA_WIDTH),
    .RAM_DEPTH(RAM_DEPTH)
    ) memory (
    .clk(clk),
    .en(ce),
    .we(1'b1),
    .addr(position),
    .di(w_d_in),
    //outputs
    .do(w_d_out)
);

assign w_d_in[DATA_WIDTH-1:0] = data_in;
assign data_out = w_d_out[DATA_WIDTH-1:0];

endmodule
