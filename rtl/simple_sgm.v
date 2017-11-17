module simple_sgm
# (
    // 83 dla 64x64
    // 1664 dla 1280x720
    localparam DISPARITY_RANGE = 8
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

localparam COST_BITS = 8;
//absolute difference calculation
wire [COST_BITS-1:0] matching_cost [0:MAX_DISP];
generate
for (i=0; i<=MAX_DISP; i=i+1) begin : calculate_abs_diff
    assign matching_cost[i] = (pixel_left > right_arr[i]) ? (pixel_left - right_arr[i]) : (right_arr[i] - pixel_left);
end
endgenerate

localparam ARR_WIDTH = COST_BITS*DISPARITY_RANGE;
wire [ARR_WIDTH-1:0] array = {matching_cost[7], matching_cost[6], matching_cost[5], matching_cost[4],
                              matching_cost[3], matching_cost[2], matching_cost[1], matching_cost[0]};

`include "../util/clog2_fun.v"
localparam INDEX_BITS = clog2(COST_BITS);
wire [INDEX_BITS-1:0]index;//3 bit
wire [COST_BITS-1:0]min_val;//8 bit
argmin #(
    .WIDTH(COST_BITS),//
    .INPUTS(8)    
) disparity_selector (
    //inputs
    .input_words(array), // packed array of words to be compared
    //outputs
    .min_value(min_val),
    .min_index(index)
);


assign {clk_out,de_out,h_sync_out,v_sync_out} = {clk,de_in,h_sync_in,v_sync_in};
assign pixel_disparity = right_arr[5];//TODO CHANGE
//assign pixel_disparity = right_arr[0];//TODO CHANGE


endmodule
