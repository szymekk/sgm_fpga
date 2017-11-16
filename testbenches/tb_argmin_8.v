/*
`ifndef ARRAY_PACK_UNPACK_V
`ifdef PACK_ARRAY
$finish; // macro PACK_ARRAY already exists. refusing to redefine.
`endif
`ifdef UNPACK_ARRAY
$finish; // macro UNPACK_ARRAY already exists. refusing to redefine.
`endif

`define ARRAY_PACK_UNPACK_V 1
`define PACK_ARRAY(PK_WIDTH,PK_LEN,PK_SRC,PK_DEST) genvar pk_idx; generate for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) begin; assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; end; endgenerate
`define UNPACK_ARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC) genvar unpk_idx; generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) begin; assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; end; endgenerate

`endif
//////////////////////////////////////
module example (
    input  [63:0] pack_4_16_in,
    output [31:0] pack_16_2_out
    );

wire [3:0] in [0:15];
`UNPACK_ARRAY(4,16,in,pack_4_16_in)

wire [15:0] out [0:1];
`PACK_ARRAY(16,2,in,pack_16_2_out)


// useful code goes here

endmodule // example
*/

module tb_argmin_8(
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

localparam EL_WIDTH = 7;//max 127
reg [EL_WIDTH-1:0] data_memory[0:7];

reg [2:0]correct_index;//3 bit
reg [7:0]correct_min_val;//8 bit
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
) DUT (
    //inputs
    .data(array),//packed array
    //outputs
    .min_value(min_val),
    .min_index(index)
);


always @(posedge clk) begin
    if (correct_index !== index)
    begin
        if (data_memory[correct_index] !== data_memory[index])
        begin
            $display("[%d] ASSERTION index FAILED in %m", $time);
            $finish;
//            $stop;
        end else
        begin
            $display("index [%d] selected reference is [%d] both point to the same value [%d]",
                     index, correct_index, data_memory[index]);
        end
    end
    
    if (correct_min_val !== min_val)
    begin
        $display("ASSERTION val FAILED in %m");
        $finish;
//        $stop;
    end
end

endmodule
