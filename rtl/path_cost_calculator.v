module path_cost_calculator
# (
//    localparam DISPARITY_LEVELS = 64,
//    localparam COST_BITS = 6,
//    localparam ACC_COST_BITS = 8,
    parameter DISPARITY_LEVELS = 64,
    parameter COST_BITS = 6,
    parameter ACC_COST_BITS = 8,
    parameter PATH_DELAY = 1600,
    localparam ACC_COST_ARRAY_BITS = ACC_COST_BITS * DISPARITY_LEVELS
)
(
    //inputs
    input in_de,
    input in_path_beginning,
    input in_clk,
    input [7:0] in_P1,//todo size
    input [7:0] in_P2,//todo size
    input [COST_BITS*DISPARITY_LEVELS-1:0] in_C_arr, // width = COST_BITS*(MAX_DISP + 1)
    //outputs
    output [ACC_COST_ARRAY_BITS-1:0] out_L_arr
);
localparam MAX_DISP = DISPARITY_LEVELS - 1;

//--------------------beg_assert----------------
generate /* path costs width should be at least as big as local cost width */
if (ACC_COST_BITS < COST_BITS ) begin : assertion_acc_cost_greater_than_or_equal_to_local_cost
    ACC_COST_BITS_should_not_be_less_than_COST_BITS non_existing_module();
end
endgenerate

generate /* path delay should be at least one */
if (PATH_DELAY <= 0 ) begin : assertion_path_delay_should_be_greater_than_zero
    PATH_DELAY_should_be_greater_than_zero non_existing_module();
end
endgenerate
//--------------------end_assert----------------

wire [COST_BITS-1:0] local_costs [0:MAX_DISP]; // array of local matching costs for each candidate disparity

genvar d;
generate
for (d = 0; d <= MAX_DISP; d = d + 1) begin : unpack_input_costs_to_array
    assign local_costs[d][COST_BITS-1 : 0] = in_C_arr[COST_BITS*d + (COST_BITS-1) : COST_BITS*d];
end
endgenerate

reg [ACC_COST_BITS-1:0] path_costs [0:MAX_DISP]; // array of path costs for each candidate disparity
wire [ACC_COST_BITS-1:0] min_prev_path_cost;
wire [ACC_COST_BITS-1:0] smoothness_term [0:MAX_DISP]; // todo size (bit width)

always @(posedge in_clk)
begin : path_cost_calculation
    integer d;
    for (d = 0; d <= MAX_DISP; d = d + 1) begin : accumulate_costs
        if (in_path_beginning)
            path_costs[d] <= local_costs[d];
        else
            path_costs[d] <= local_costs[d] + smoothness_term[d] - min_prev_path_cost;
    end
end

wire [ACC_COST_ARRAY_BITS-1:0] packed_path_costs; // packed array of path costs for delay
wire [ACC_COST_ARRAY_BITS-1:0] packed_prev_path_costs;
generate
for (d = 0; d <= MAX_DISP; d = d + 1) begin : pack_path_costs_to_array_for_delay
    assign packed_path_costs[ACC_COST_BITS*d + (ACC_COST_BITS-1) : ACC_COST_BITS*d] = path_costs[d];
end
endgenerate
//---------------------------------------------------------------------
//---------------------------------------------------------------------
generate
if (PATH_DELAY == 1) begin : choose_delay_line
    delay_line #(
        .N(ACC_COST_ARRAY_BITS),
        .DELAY(PATH_DELAY - 1) // register delay by one already
    ) path_costs_delayer (
        //inputs
        .clk(in_clk),
        .ce(1'b1), // todo skip invalid image (blanking etc) and lower DELAY
        .idata(packed_path_costs),
        //outputs
        .odata(packed_prev_path_costs)
    );
end
else // ram delay line
begin
    //---------------------------------------------------------------------
    /*
    ram_delay_line
    #(
        //.DATA_WIDTH(ACC_COST_BITS*DISPARITY_LEVELS),
        .DATA_WIDTH(64),
        .DELAY(PATH_DELAY - 1)
    //) path_costs_delayer (
    ) path_costs_delayer [1:9] (//9 bit acc_disp
        .clk(in_clk),
        .ce(1'b1),
        .rst(1'b0),
        .data_in(packed_path_costs),
        //outputs
        .data_out(packed_prev_path_costs)
    );
    */
    /*
    ram_delay_line // WORKING
    #(
        //.DATA_WIDTH(ACC_COST_BITS*DISPARITY_LEVELS),
        .DATA_WIDTH(18),
        .DELAY(PATH_DELAY - 1) // IMG_WIDTH - ram depth, not delay
    ) path_costs_delayer [1:32] (//test infer 18 bits x 720 depth ???
        .clk(in_clk),
        .ce(in_de),
        .rst(1'b0),
    //    .data_in({ {24{1'b0}}, packed_path_costs }),//32 inst x 18 DATA_WIDTH = 576 total width packed_path_costs is 576 bits wide so no extend
        .data_in(packed_path_costs),//32 inst x 18 DATA_WIDTH = 576 total width packed_path_costs is 576 bits wide so no extend
        //outputs
        .data_out(packed_prev_path_costs)
    );
    */

    `include "div_round_up_fun.v"
    localparam DATA_BUS_WIDTH = 18;
    localparam INSTANCES = div_round_up(ACC_COST_ARRAY_BITS, DATA_BUS_WIDTH);
    localparam TOTAL_DATA_BUS_WIDTH = DATA_BUS_WIDTH * INSTANCES;
    localparam PADDING_BITS = TOTAL_DATA_BUS_WIDTH - ACC_COST_ARRAY_BITS;

    wire [TOTAL_DATA_BUS_WIDTH-1:0] delay_input;
    wire [TOTAL_DATA_BUS_WIDTH-1:0] delay_output;
    // if needed pad input with zeros to match combined width of all instances
    assign delay_input = (PADDING_BITS > 0) ? { {PADDING_BITS{1'b0}}, packed_path_costs } : packed_path_costs;
    assign packed_prev_path_costs = delay_output[ACC_COST_ARRAY_BITS-1:0];
    ram_delay_line // WORKING
    #(
        .DATA_WIDTH(DATA_BUS_WIDTH),
        .DELAY(PATH_DELAY - 1) // IMG_WIDTH - ram depth, not delay
    ) path_costs_delayer [1:INSTANCES] (
        .clk(in_clk),
        .ce(in_de),
        .rst(1'b0),
        .data_in(delay_input),// pad with zeros to match total width of all instances
        //outputs
        .data_out(delay_output)
    );
    //---------------------------------------------------------------------
end
endgenerate

//---------------------------------------------------------------------

wire [ACC_COST_BITS-1:0] prev_path_costs [0:MAX_DISP]; // array of delayed path costs for each candidate disparity
generate
for (d = 0; d <= MAX_DISP; d = d + 1) begin : unpack_path_costs_to_array
    assign prev_path_costs[d][ACC_COST_BITS-1 : 0] = packed_prev_path_costs[ACC_COST_BITS*d + (ACC_COST_BITS-1) : ACC_COST_BITS*d];
end
endgenerate

/*
reg [7:0] byte_shift_reg[0:MAX_DISP-1];
always @(posedge clk)
begin : right_img_delay
    integer i;
    //byte shift register
    byte_shift_reg[0] <= pixel_right;
    for(i=0; i<MAX_DISP-1; i=i+1) begin
        byte_shift_reg[i+1] <= byte_shift_reg[i];
    end
end

wire [7:0] right_arr [0:MAX_DISP];
assign right_arr[0] = pixel_right;
genvar i;
generate
for (i=0; i<MAX_DISP; i=i+1) begin : assign_delay
    assign right_arr[i+1] = byte_shift_reg[i];
end
endgenerate
*/

// todo - use module without min_index
`include "clog2_fun.v"
localparam DUMMY_INDEX_BITS = clog2(DISPARITY_LEVELS);
wire [DUMMY_INDEX_BITS-1:0] unused_wire_index;
argmin #(
    .WIDTH(ACC_COST_BITS),//
    .INPUTS(DISPARITY_LEVELS)
) min_prev_path_cost_selector (
    //inputs
    .input_words(packed_prev_path_costs), // packed array of words to be compared
    //outputs
    .min_value(min_prev_path_cost),
    .min_index(unused_wire_index)
);

//assign smoothness_term[0] = (prev_path_costs[0] < prev_path_costs[1]) ? prev_path_costs[0] : prev_path_costs[1];

always @(*) begin : smoothness_term_for_zero_disparity
    integer min;
    min = prev_path_costs[0];
    if (prev_path_costs[1] + in_P1 < min)
        min = prev_path_costs[1] + in_P1;
    if (min_prev_path_cost + in_P2 < min)
        min = min_prev_path_cost + in_P2;
end
assign smoothness_term[0] = smoothness_term_for_zero_disparity.min;

generate
for (d = 1; d < MAX_DISP; d = d + 1) begin : smoothness_term_for_middle_disparities
    integer min;
    always @(*) begin
        min = prev_path_costs[d];
        if (prev_path_costs[d - 1] + in_P1 < min)
            min = prev_path_costs[d - 1] + in_P1;
        if (prev_path_costs[d + 1] + in_P1 < min)
            min = prev_path_costs[d + 1] + in_P1;
        if (min_prev_path_cost + in_P2 < min)
            min = min_prev_path_cost + in_P2;
    end
    assign smoothness_term[d] = min;
end
endgenerate

always @(*) begin : smoothness_term_for_max_disparity
    integer min;
    min = prev_path_costs[MAX_DISP];
    if (prev_path_costs[MAX_DISP - 1] + in_P1 < min)
        min = prev_path_costs[MAX_DISP - 1] + in_P1;
    if (min_prev_path_cost + in_P2 < min)
        min = min_prev_path_cost + in_P2;
end
assign smoothness_term[MAX_DISP] = smoothness_term_for_max_disparity.min;

assign out_L_arr = packed_path_costs;

endmodule
