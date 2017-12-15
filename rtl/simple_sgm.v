module simple_sgm
# (
    localparam USE_RANK_TRANSFORM_COST = 1,
//    localparam TOTAL_LINE_WIDTH = (800 + 8 + 8 + 2), // simulation 800
    localparam TOTAL_LINE_WIDTH = 1650, // synthesis 1280
//    localparam HALF_IMG_WIDTH = 400,
    localparam HALF_IMG_WIDTH = 640, // 1280/2
//    localparam DISPARITY_RANGE = 128
//    localparam DISPARITY_RANGE = 64
    localparam DISPARITY_RANGE = 32
)
(
    //inputs
    input clk,
    input de_in,
    input h_sync_in,
    input v_sync_in,
    input [7:0] pixel_left,//8 bit
    input [7:0] pixel_right,//8 bit
    //outputs
    output clk_out,
    output de_out,
    output h_sync_out,
    output v_sync_out,
    output [7:0] pixel_disparity//8 bit
);
localparam MAX_DISP = DISPARITY_RANGE - 1;

wire cost_de;
wire cost_h_sync;
wire cost_v_sync;

//localparam COST_BITS = 8;
localparam COST_BITS = 6;
//absolute difference calculation
localparam [COST_BITS-1:0] THRESHOLD = {COST_BITS{1'b1}};
//localparam MAX_COST = 255;
localparam MAX_COST = THRESHOLD; // todo for rank transform

wire [COST_BITS-1:0] matching_cost [0:MAX_DISP];
generate
if (USE_RANK_TRANSFORM_COST) begin
    wire [COST_BITS-1:0] rank_transform_left;
    wire [COST_BITS-1:0] rank_transform_right;
    wire left_rank_de;
    wire left_rank_h_sync;
    wire left_rank_v_sync;

    assign {cost_de, cost_h_sync, cost_v_sync} = {left_rank_de, left_rank_h_sync, left_rank_v_sync};
    rank_transform
    # (
//            localparam WINDOW_SIZE = 7,
        .OUTPUT_WIDTH(COST_BITS),
        .TOTAL_LINE_W(TOTAL_LINE_WIDTH)
    ) rank_transform_calculator_left (
        //inputs
        .clk(clk),
        .de_in(de_in),
        .h_sync_in(h_sync_in),
        .v_sync_in(v_sync_in),
        .pixel_in(pixel_left),//8 bit
        //outputs
        .clk_out(),
        .de_out(left_rank_de),
        .h_sync_out(left_rank_h_sync),
        .v_sync_out(left_rank_v_sync),
        .rank_transform_out(rank_transform_left) // 8
    );
    rank_transform
    # (
//            localparam WINDOW_SIZE = 7,
        .OUTPUT_WIDTH(COST_BITS),
        .TOTAL_LINE_W(TOTAL_LINE_WIDTH)
    ) rank_transform_calculator_right (
        //inputs
        .clk(clk),
        .de_in(de_in),
        .h_sync_in(h_sync_in),
        .v_sync_in(v_sync_in),
        .pixel_in(pixel_right),//8 bit
        //outputs
        .clk_out(),
        .de_out(),
        .h_sync_out(),
        .v_sync_out(),
        .rank_transform_out(rank_transform_right) // 8
    );

    reg [COST_BITS-1:0] byte_shift_reg[0:MAX_DISP-1];
    always @(posedge clk) begin : right_rank_transform_delay
        integer i;
        //byte shift register
        byte_shift_reg[0] <= rank_transform_right;
        for(i=0; i<MAX_DISP-1; i=i+1) begin
            byte_shift_reg[i+1] <= byte_shift_reg[i];
        end
    end
    wire [COST_BITS-1:0] right_arr [0:MAX_DISP];
    assign right_arr[0] = rank_transform_right;
    genvar i;
    //generate
    for (i=0; i<MAX_DISP; i=i+1) begin : assign_delay
        assign right_arr[i+1] = byte_shift_reg[i];
    end
    //endgenerate
    wire [COST_BITS-1:0] rank_transform_abs_diff [0:MAX_DISP];
    for (i=0; i<=MAX_DISP; i=i+1) begin : calculate_abs_diff
        assign rank_transform_abs_diff[i] = (rank_transform_left > right_arr[i]) ? (rank_transform_left - right_arr[i]) : (right_arr[i] - rank_transform_left);
        assign matching_cost[i] = rank_transform_abs_diff[i];
    end

end // if
else begin
    wire [7:0] pixelwise_abs_diff [0:MAX_DISP];
    //no delay introduced
    assign {cost_de, cost_h_sync, cost_v_sync} = {de_in, h_sync_in, v_sync_in};
    reg [7:0] byte_shift_reg[0:MAX_DISP-1];
    always @(posedge clk) begin : right_img_delay
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
    //generate
    for (i=0; i<MAX_DISP; i=i+1) begin : assign_delay
        assign right_arr[i+1] = byte_shift_reg[i];
    end
    //endgenerate

    for (i=0; i<=MAX_DISP; i=i+1) begin : calculate_abs_diff
        assign pixelwise_abs_diff[i] = (pixel_left > right_arr[i]) ? (pixel_left - right_arr[i]) : (right_arr[i] - pixel_left);
    //    assign matching_cost[i] = pixelwise_abs_diff[i];
        // truncated matching cost
        assign matching_cost[i] = (pixelwise_abs_diff[i] > THRESHOLD) ? THRESHOLD : pixelwise_abs_diff[i];
    end
end // else
endgenerate

localparam ARR_WIDTH = COST_BITS*DISPARITY_RANGE;
wire [ARR_WIDTH-1:0] matching_costs_array;//todo
genvar d;
generate
for (d = 0; d <= MAX_DISP; d = d + 1) begin : pack_path_costs_to_array
    assign matching_costs_array[COST_BITS*d + (COST_BITS-1) : COST_BITS*d] = matching_cost[d];
end
endgenerate

wire [9:0] row;//todo size clog2
wire [10:0] col;//todo size clog2
img_coordinates_counter #(
    .ROW_WIDTH(10),
    .COL_WIDTH(11)
) coordinates_counter (
    //inputs
    .clk(clk),
    .de_in(cost_de),
    .h_sync_in(h_sync_in),
    .v_sync_in(v_sync_in),
    //outputs
    .row_out(row),
    .col_out(col)
);

wire half_img_de = cost_de && (col >= HALF_IMG_WIDTH);

wire horizontal_beginning = (0 + HALF_IMG_WIDTH == col);

localparam [7:0] MAX_P1 = 8'd15;
localparam [7:0] MAX_P2 = 8'd64;
localparam MAX_ACC_COST = MAX_COST + MAX_P2;
localparam ACC_COST_BITS = clog2(MAX_ACC_COST + 1);
//localparam ACC_COST_BITS = COST_BITS + 1;
localparam PATH_COST_ARR_WIDTH = ACC_COST_BITS*DISPARITY_RANGE;

wire [PATH_COST_ARR_WIDTH-1:0] L_array_horizontal;
path_cost_calculator #(
    .DISPARITY_LEVELS(DISPARITY_RANGE),
    .COST_BITS(COST_BITS),
    .ACC_COST_BITS(ACC_COST_BITS),
    .PATH_DELAY(1)
) horizontal (
    //inputs
    //.in_de(half_img_de), // todo remove?
    .in_path_beginning(horizontal_beginning),
    .in_clk(clk),
    .in_P1(MAX_P1),
    .in_P2(MAX_P2), // todo P2 calculation
    .in_C_arr(matching_costs_array), // width = COST_BITS*(MAX_DISP + 1)
    //outputs
    .out_L_arr(L_array_horizontal) // width = ACC_COST_BITS*(MAX_DISP + 1)
);


wire top_to_bottom_beginning = (0 == row);
wire diagonal_left_to_right_beginning = horizontal_beginning || top_to_bottom_beginning;
wire diagonal_right_to_left_beginning = (2*HALF_IMG_WIDTH - 1 == col) || top_to_bottom_beginning;

reg delayed_half_img_de = 0;
always @(posedge clk)
begin : de_delay_by_one
    delayed_half_img_de <= half_img_de;
end
wire extended_half_img_de = delayed_half_img_de || half_img_de;

wire [PATH_COST_ARR_WIDTH-1:0] L_array_left_to_right;
path_cost_calculator #(
    .DISPARITY_LEVELS(DISPARITY_RANGE),
    .COST_BITS(COST_BITS),
    .ACC_COST_BITS(ACC_COST_BITS),
//    401 effective (402 - 1) ram depth will be used, 400 for top, 401 for l2r, 399 for r2l
    .PATH_DELAY(HALF_IMG_WIDTH + 2)
) diagonal_left_to_right (//check path_costs_delayer for .DELAY(PATH_DELAY - 1) <- effective DELAY should be 400 for top, 399 for r2l(<--), 401 for l2r (-->)
    //inputs
    .in_de(extended_half_img_de), // extended de signal
    .in_path_beginning(diagonal_left_to_right_beginning), // 402 (401 effective)
    .in_clk(clk),
    .in_P1(MAX_P1),
    .in_P2(MAX_P2), // todo P2 calculation
    .in_C_arr(matching_costs_array), // width = COST_BITS*(MAX_DISP + 1)
    //outputs
    .out_L_arr(L_array_left_to_right) // width = ACC_COST_BITS*(MAX_DISP + 1)
);


wire [PATH_COST_ARR_WIDTH-1:0] L_array_top_to_bottom;
path_cost_calculator #(// WORKING
    .DISPARITY_LEVELS(DISPARITY_RANGE),
    .COST_BITS(COST_BITS),
    .ACC_COST_BITS(ACC_COST_BITS),
//    400 effective (401 - 1) ram depth will be used, 400 for top, 401 for l2r, 399 for r2l
    .PATH_DELAY(HALF_IMG_WIDTH + 1)
) top_to_bottom (//check path_costs_delayer for .DELAY(PATH_DELAY - 1) <- effective DELAY should be 400 for top, 399 for r2l(<--), 401 for l2r (-->)
    //inputs
    .in_de(extended_half_img_de), // test extended de signal
    .in_path_beginning(top_to_bottom_beginning), // 401 (400 effective)
    .in_clk(clk),
    .in_P1(MAX_P1),
    .in_P2(MAX_P2), // todo P2 calculation
    .in_C_arr(matching_costs_array), // width = COST_BITS*(MAX_DISP + 1)
    //outputs
    .out_L_arr(L_array_top_to_bottom) // width = ACC_COST_BITS*(MAX_DISP + 1)
);


wire [PATH_COST_ARR_WIDTH-1:0] L_array_right_to_left;
path_cost_calculator #(// WORKING
    .DISPARITY_LEVELS(DISPARITY_RANGE),
    .COST_BITS(COST_BITS),
    .ACC_COST_BITS(ACC_COST_BITS),
//    399 effective (400 - 1) ram depth will be used, 400 for top, 401 for l2r, 399 for r2l
    .PATH_DELAY(HALF_IMG_WIDTH + 0)
) diagonal_right_to_left (//check path_costs_delayer for .DELAY(PATH_DELAY - 1) <- effective DELAY should be 400 for top, 399 for r2l(<--), 401 for l2r (-->)
    //inputs
    .in_de(extended_half_img_de), // extended de signal
    .in_path_beginning(diagonal_right_to_left_beginning), // 400 (399 effective)
    .in_clk(clk),
    .in_P1(MAX_P1),
    .in_P2(MAX_P2), // todo P2 calculation
    .in_C_arr(matching_costs_array), // width = COST_BITS*(MAX_DISP + 1)
    //outputs
    .out_L_arr(L_array_right_to_left) // width = ACC_COST_BITS*(MAX_DISP + 1)
);


// path_cost_calculator #(.PATH_DELAY(1665)) diagonal_left_to_right ()
// path_cost_calculator #(.PATH_DELAY(1664)) top_to_bottom ()
// path_cost_calculator #(.PATH_DELAY(1663)) diagonal_right_to_left ()

//localparam TOTAL_COST_BITS = ACC_COST_BITS; // 1 path
//localparam TOTAL_COST_BITS = ACC_COST_BITS + 1; // 2 paths
localparam TOTAL_COST_BITS = ACC_COST_BITS + 2; // 3-4 paths
localparam TOTAL_COST_ARR_WIDTH = TOTAL_COST_BITS*DISPARITY_RANGE;
wire [TOTAL_COST_ARR_WIDTH-1:0] S_array_total;
generate
for (d = 0; d <= MAX_DISP; d = d + 1) begin : sum_path_costs
    assign S_array_total[TOTAL_COST_BITS*d + (TOTAL_COST_BITS-1) : TOTAL_COST_BITS*d] =
        L_array_horizontal   [ACC_COST_BITS*d + (ACC_COST_BITS-1) : ACC_COST_BITS*d] +
        L_array_left_to_right[ACC_COST_BITS*d + (ACC_COST_BITS-1) : ACC_COST_BITS*d] +
        L_array_top_to_bottom[ACC_COST_BITS*d + (ACC_COST_BITS-1) : ACC_COST_BITS*d] +
        L_array_right_to_left[ACC_COST_BITS*d + (ACC_COST_BITS-1) : ACC_COST_BITS*d];
end
endgenerate

`include "clog2_fun.v"
localparam INDEX_BITS = clog2(DISPARITY_RANGE);
wire [INDEX_BITS-1:0]index;//5 bit for 32 disparities, 6 bit for 64
wire [TOTAL_COST_BITS-1:0]min_val;//10 bit
argmin #(
    .WIDTH(TOTAL_COST_BITS),
    .INPUTS(DISPARITY_RANGE)
) disparity_selector (
    //inputs
    .input_words(S_array_total), // packed array of words to be compared
    //outputs
    .min_value(min_val),
    .min_index(index)
);

reg reg_de = 0;
reg reg_h_sync = 0;
reg reg_v_sync = 0;
always @(posedge clk) begin : control_signals_delay // cost aggregation introduces a one cycle delay
    {reg_de, reg_h_sync, reg_v_sync} <= {cost_de, cost_h_sync, cost_v_sync};
end
assign {clk_out, de_out, h_sync_out, v_sync_out} = {clk, reg_de, reg_h_sync, reg_v_sync};
assign pixel_disparity = index;


endmodule
