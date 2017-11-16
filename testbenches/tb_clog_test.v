`timescale 1ns / 1ps

module tb_clog_test(

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

reg [8:0] counter = 0;
//reg [3:0] clog = 0;
always @(posedge clk)
begin
    counter <= counter + 1;
end

function integer clog2; 
input integer value; 
begin 
    value = value-1; 
    for (clog2=0; value>0; clog2=clog2+1) 
        value = value>>1; 
    end 
endfunction 

wire [3:0] system_clog2 = $clog2(counter);
wire [3:0] fun_clog2 = clog2(counter);

endmodule // tb_clog_test
