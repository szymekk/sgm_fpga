module delay_line #
(
    parameter N = 3,
    parameter DELAY = 5 
)
(
    input clk,
    input ce,
    input [N-1:0]idata,
    output [N-1:0]odata
);
wire [N-1:0] tdata [DELAY:0];
assign tdata[0] = idata;

genvar i;
generate
    if(0 == DELAY)
    begin
        assign odata = idata;
    end else
    begin
        for(i = 0; i < DELAY; i = i+1)
        begin
            delay #(
                .N(N)
            )
            del_i
            (
                .clk(clk),
                .ce(ce),
                .d(tdata[i]),
                .q(tdata[i+1])
            );
        end
        assign odata = tdata[DELAY];
    end // else
endgenerate

endmodule
