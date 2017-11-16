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

//`include "functions.v"
/*
module argmin_8
# (
//    parameter INPUTS = 8,
    parameter WIDTH = 2,
    
    localparam INPUTS = 8,
    localparam INPUT_ARR_WIDTH = INPUTS*WIDTH,
//    localparam INDEX_BITS = functions.clog2(INPUTS)
    //localparam INDEX_BITS = functions_copy.clog2(INPUTS)
    localparam INDEX_BITS = 3
)
(
    //inputs
    input [INPUT_ARR_WIDTH-1:0] data,//packed array
    //outputs
    output [WIDTH-1:0] min_value,
    output [INDEX_BITS:0] min_index
);
*/
// old style interface definition to workaround unsupported hierarchical names in Vivado synthesis
// can't use functions.clog2 in synthesis
module argmin_8
(
    //inputs
    data,//packed array
    //outputs
    min_value,
    min_index
);
function integer clog2;
    input integer value;
    begin 
        value = value - 1;
        for (clog2 = 0; value > 0; clog2 = clog2 + 1)
            value = value >> 1;
    end 
endfunction

parameter WIDTH = 2;
localparam INPUTS = 8;
localparam INPUT_ARR_WIDTH = INPUTS*WIDTH;
localparam INDEX_BITS = clog2(INPUTS);
//localparam INDEX_BITS = functions.clog2(INPUTS);
//localparam INDEX_BITS = 3;

//inputs
input [INPUT_ARR_WIDTH-1:0] data;//packed array
//outputs
output [WIDTH-1:0] min_value;
output [INDEX_BITS-1:0] min_index;
//--------------------end interface----------------

//--------------------beg_assert----------------
generate
if (0 >= WIDTH /* WIDTH should be greater than zero */ ) begin : assertion
    WIDTH_should_be_greater_than_zero non_existing_module();
end
endgenerate
generate
//if (functions.clog2(INPUTS + 1) <= functions.clog2(INPUTS) /* INPUTS is a power of two */ ) begin : assertion
if (clog2(INPUTS + 1) <= clog2(INPUTS) /* INPUTS is a power of two */ ) begin : assertion_number_of_inputs_is_a_power_of_two
    for_now_input_should_be_a_power_of_two non_existing_module();
end
endgenerate
//--------------------end_assert----------------

wire [WIDTH-1:0] array [0:INPUTS-1];
genvar unpk_idx;
generate
for (unpk_idx=0; unpk_idx<(INPUTS); unpk_idx=unpk_idx+1) begin : unpack_to_array
    assign array[unpk_idx][((WIDTH)-1):0] = data[((WIDTH)*unpk_idx+(WIDTH-1)):((WIDTH)*unpk_idx)];
end
endgenerate


wire [WIDTH-1:0] value_l1[0:3];
wire [INDEX_BITS-1:0] index_l1[0:3];

genvar i;
generate // INPUTS/(2^(lvl-1)) = INPUTS/1 = 8
for (i=0; i<INPUTS; i=i+2) begin :gen_comps_lvl1
    //wire [i:0]a = i;
    localparam [INDEX_BITS-1:0] INPUT_INDEX = i; // cast from 32 bit
    sel_key_with_min_val #(
        .VALUE_WIDTH(WIDTH),
        .KEY_WIDTH(INDEX_BITS)
    ) clvl1 (
        .x1_val(array[i]),
        .x1_key(INPUT_INDEX),
        .x2_val(array[i+1]),
        .x2_key(INPUT_INDEX + 1),
        .min_val(value_l1[i/2]),
        .min_key(index_l1[i/2])
    );
end
endgenerate

wire [WIDTH-1:0] value_l2[0:1];
wire [INDEX_BITS-1:0] index_l2[0:1];
generate // INPUTS/(2^(lvl-1)) = INPUTS/2 = 4
for (i=0; i<INPUTS/2; i=i+2) begin :gen_comps_lvl2
    sel_key_with_min_val #(
        .VALUE_WIDTH(WIDTH),
        .KEY_WIDTH(INDEX_BITS)
    ) clvl2 (
        .x1_val(value_l1[i]),
        .x1_key(index_l1[i]),
        .x2_val(value_l1[i+1]),
        .x2_key(index_l1[i+1]),
        .min_val(value_l2[i/2]),
        .min_key(index_l2[i/2])
    );
end
endgenerate

wire [WIDTH-1:0] value_l3[0:0];
wire [INDEX_BITS-1:0] index_l3[0:0];
generate // INPUTS/(2^(lvl-1)) = INPUTS/4 = 2
for (i=0; i<INPUTS/4; i=i+2) begin :gen_comps_lvl3
    sel_key_with_min_val #(
       .VALUE_WIDTH(WIDTH),
       .KEY_WIDTH(INDEX_BITS)
       
    ) clvl3 (
        .x1_val(value_l2[i]),
        .x1_key(index_l2[i]),
        .x2_val(value_l2[i+1]),
        .x2_key(index_l2[i+1]),
        .min_val(value_l3[i/2]),
        .min_key(index_l3[i/2])
);
end
endgenerate

assign min_index = index_l3[0];
assign min_value = value_l3[0];

endmodule // argmin
