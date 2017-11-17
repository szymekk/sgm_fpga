module tb_argmin(
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

`include "../util/clog2_fun.v"
localparam EL_WIDTH = 7;//max 127
localparam WORDS = 8; // number of compared words
localparam IDX_WIDTH = clog2(WORDS);
reg [EL_WIDTH-1:0] data_memory[0:WORDS-1];

reg [IDX_WIDTH-1:0]correct_index;//3 bit
reg [EL_WIDTH-1:0]correct_min_val;//8 bit
initial begin

#1
data_memory[0] = 1;
data_memory[1] = 2;
data_memory[2] = 3;
data_memory[3] = 4;
data_memory[4] = 5;
data_memory[5] = 6;
data_memory[6] = 7;
data_memory[7] = 8;
correct_index = 0;
correct_min_val = 1;

#2
data_memory[0] = 13;
data_memory[1] = 5;
data_memory[2] = 19;
data_memory[3] = 100;
data_memory[4] = 0;
data_memory[5] = 1;
data_memory[6] = 1;
data_memory[7] = 127;
correct_index = 4;
correct_min_val = 0;

#2
data_memory[0] = 100;
data_memory[1] = 100;
data_memory[2] = 100;
data_memory[3] = 100;
data_memory[4] = 100;
data_memory[5] = 100;
data_memory[6] = 100;
data_memory[7] = 100;
correct_index = 0;
correct_min_val = 100;

#2
data_memory[0] = 100;
data_memory[1] = 100;
data_memory[2] = 100;
data_memory[3] = 100;
data_memory[4] = 100;
data_memory[5] = 100;
data_memory[6] = 100;
data_memory[7] = 100;
correct_index = 7;
correct_min_val = 100;

#2
data_memory[0] = 127;
data_memory[1] = 55;
data_memory[2] = 8;
data_memory[3] = 100;
data_memory[4] = 99;
data_memory[5] = 12;
data_memory[6] = 100;
data_memory[7] = 3;
correct_index = 7;
correct_min_val = 3;

#2
$finish;

end


localparam ARR_WIDTH = EL_WIDTH*8;
wire [ARR_WIDTH-1:0] array = {data_memory[7], data_memory[6], data_memory[5], data_memory[4],
                              data_memory[3], data_memory[2], data_memory[1], data_memory[0]};
wire [2:0]index;//3 bit
wire [EL_WIDTH-1:0]min_val;//7 bit

argmin_8 #(
    .WIDTH(EL_WIDTH)
) reference (
    //inputs
    .input_words(array),//packed array
    //outputs
    .min_value(min_val),
    .min_index(index)
);

wire [2:0]index_generic;//3 bit
wire [EL_WIDTH-1:0]min_val_generic;//7 bit
argmin #(
    .WIDTH(EL_WIDTH),
    .INPUTS(8)
) DUT (
    //inputs
    .input_words(array),//packed array
    //outputs
    .min_value(min_val_generic),
    .min_index(index_generic)
);


always @(posedge clk) begin
    if (correct_index !== index_generic)
    begin
        if (data_memory[correct_index] !== data_memory[index_generic])
        begin
            $display("[%d] ASSERTION index FAILED in %m", $time);
            $display("EXPECTED: data_memory[correct_index] === data_memory[index_generic]");
            $display("ACTUAL: data_memory[%d] !== data_memory[%d]", correct_index, index_generic);
            $display("ACTUAL: %d !== %d", data_memory[correct_index], data_memory[index_generic]);
            $finish;
//            $stop;
        end else
        begin
            $display("index [%d] selected reference is [%d] both point to the same value [%d]",
                     index_generic, correct_index, data_memory[index_generic]);
        end
    end
    
    if (correct_min_val !== min_val_generic)
    begin
        $display("ASSERTION val FAILED in %m");
        $display("EXPECTED: correct_min_val === min_val_generic");
        $display("ACTUAL: %d !== %d", correct_min_val, min_val_generic);
        $finish;
//        $stop;
    end
end

endmodule
