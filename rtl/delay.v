//module delay
//# (
//    parameter N = 3
//)
//(
//    input clk,
//    input ce,
//    input [N-1:0]d,
//    output [N-1:0]q
//);
//reg [N-1:0]val=0;

//always @(posedge clk)
//begin
//    if(ce) val<=d;
//    else val<=val;
//end

//assign q=val;

//endmodule

module delay
# (
    parameter N = 3
)
(
    input clk,
    input ce,
    input [N-1:0]d,
    output reg [N-1:0]q
);

always @(posedge clk)
begin
    if(ce) begin q<=d; end
    else begin q<=q; end
end


endmodule
