// old style interface definition to workaround unsupported hierarchical names in Vivado synthesis
// can't use functions.clog2 in synthesis
module argmin
(
    //inputs
    input_words, // packed array of words to be compared
    //outputs
    min_value, // minimal word
    min_index // index of minimal word
);
`include "../util/clog2_fun.v"
parameter WIDTH = 2; // width of compared words
parameter INPUTS = 8;
localparam INPUT_ARR_WIDTH = INPUTS*WIDTH;
localparam INDEX_BITS = clog2(INPUTS);

//inputs
input [INPUT_ARR_WIDTH-1:0] input_words;//packed array
//outputs
output [WIDTH-1:0] min_value;
output [INDEX_BITS-1:0] min_index;
//--------------------end interface----------------

//--------------------beg_assert----------------
generate
if (0 >= WIDTH /* WIDTH should be greater than zero */ ) begin : assertion_width_is_greater_than_zero
    WIDTH_should_be_greater_than_zero non_existing_module();
end
endgenerate
generate
if (clog2(INPUTS + 1) <= clog2(INPUTS) /* INPUTS should be a power of two */ ) begin : assertion_number_of_inputs_is_a_power_of_two
    for_now_input_should_be_a_power_of_two non_existing_module();
end
endgenerate
//--------------------end_assert----------------

wire [WIDTH-1:0] array [1:(2*INPUTS)-1]; // array of compared words
wire [INDEX_BITS-1:0] indexes [1:(2*INPUTS)-1]; // array of associated indexes

genvar i;
generate
for (i = 0; i < INPUTS; i = i + 1) begin : unpack_inputs_to_array
    localparam [INDEX_BITS-1:0] INPUT_INDEX = i; // cast from 32 bit
    assign array[i + INPUTS][(WIDTH-1):0] = input_words[(WIDTH*i + (WIDTH-1)):(WIDTH*i)];
    assign indexes[i + INPUTS][(INDEX_BITS-1):0] = INPUT_INDEX;
end
endgenerate

generate
for (i = 1; i < INPUTS; i = i + 1) begin : gen_comparators
    sel_key_with_min_val #(
        .VALUE_WIDTH(WIDTH),
        .KEY_WIDTH(INDEX_BITS)
    ) comparator (
        .x1_val(array[2*i]),
        .x1_key(indexes[2*i]),
        .x2_val(array[2*i + 1]),
        .x2_key(indexes[2*i + 1]),
        .min_val(array[i]),
        .min_key(indexes[i])
    );
end
endgenerate

assign min_index = indexes[1];
assign min_value = array[1];

endmodule // argmin
