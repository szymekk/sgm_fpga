module rank_transform
# (
    localparam WINDOW_SIZE = 7,
    parameter OUTPUT_WIDTH = 8,
//    parameter TOTAL_LINE_W = (800 + 8 + 8 + 2)
    parameter TOTAL_LINE_W = 1650
)
(
    //inputs
    input clk,
    input de_in,
    input h_sync_in,
    input v_sync_in,
    input [7:0] pixel_in,//8 bit
    //outputs
    output clk_out,
    output de_out,
    output h_sync_out,
    output v_sync_out,
    output [OUTPUT_WIDTH-1 : 0] rank_transform_out
);

localparam WINDOW_ELEMENTS = WINDOW_SIZE * WINDOW_SIZE;

//--------------------beg_assert----------------
localparam MAX_RANK_TRANSFORM_VALUE = WINDOW_ELEMENTS; // could be one less
`include "clog2_fun.v"
localparam MIN_RANK_TRANSFORM_WIDTH = clog2(MAX_RANK_TRANSFORM_VALUE);
generate /* output should be wide enough for the calculated value */
if (OUTPUT_WIDTH < MIN_RANK_TRANSFORM_WIDTH ) begin : assertion_rank_transform_fits_into_output_bits
    OUTPUT_WIDTH_is_to_small non_existing_module();
end
endgenerate
//--------------------end_assert----------------

wire [9:0] row;//todo size clog2
wire [10:0] col;//todo size clog2
img_coordinates_counter #(
    .ROW_WIDTH(10),
    .COL_WIDTH(11)
) coordinates_counter ( // todo remove module
    //inputs
    .clk(clk),
    .de_in(de_in),
    .h_sync_in(h_sync_in),
    .v_sync_in(v_sync_in),
    //outputs
    .row_out(row),
    .col_out(col)
);

// delay lines
//    localparam WIDTH = PIXEL + DE + HSYNC + VSYNC;
localparam WIDTH = 8 + 1 + 1 + 1; // todo
localparam DELAY_INPUT_ROWS = WINDOW_SIZE - 1;
localparam INPUT_WIDTH = DELAY_INPUT_ROWS * WIDTH;

`include "div_round_up_fun.v"
localparam DATA_BUS_WIDTH = 18;
localparam INSTANCES = div_round_up(INPUT_WIDTH, DATA_BUS_WIDTH);
localparam TOTAL_DATA_BUS_WIDTH = DATA_BUS_WIDTH * INSTANCES;
localparam PADDING_BITS = TOTAL_DATA_BUS_WIDTH - INPUT_WIDTH;

wire [TOTAL_DATA_BUS_WIDTH-1:0] delay_input;
wire [TOTAL_DATA_BUS_WIDTH-1:0] delay_output;

wire [INPUT_WIDTH-1 : 0] packed_context_in;
wire [INPUT_WIDTH-1 : 0] packed_context_out;
// if needed pad input with zeros to match combined width of all instances
assign delay_input = (PADDING_BITS > 0) ? { {PADDING_BITS{1'b0}}, packed_context_in } : packed_context_in;
assign packed_context_out = delay_output[INPUT_WIDTH-1:0];
ram_delay_line // WORKING
#(
    .DATA_WIDTH(DATA_BUS_WIDTH),
    .DELAY(TOTAL_LINE_W - WINDOW_SIZE)
) context_delayer [1:INSTANCES] (
    .clk(clk),
    .ce(1'b1),
    .rst(1'b0),
    .data_in(delay_input),// pad with zeros to match total width of all instances
    //outputs
    .data_out(delay_output)
);
//------------------------------------------------------------------------------
reg [WIDTH-1:0] context [0 : WINDOW_ELEMENTS-1];

always @(posedge clk) begin
    context[0] <= {pixel_in, de_in, h_sync_in, v_sync_in};
end

localparam ROWS = WINDOW_SIZE;
localparam COLS = WINDOW_SIZE;

localparam FIRST_ROW = 0;
localparam LAST_ROW = ROWS-1;
genvar r, c;
generate for(r = 0; r < ROWS; r = r + 1) begin : context_delays
    for(c = 0; c < COLS-1; c = c + 1) begin : inter_context_delays
        localparam el = r*COLS + c;
        always @(posedge clk) context[el + 1] <= context[el];
    end // for inter_context_delays

    localparam FIRST_IN_ROW = r*COLS;
    localparam LAST_IN_ROW  = r*COLS + (COLS-1);
    if (FIRST_ROW != r) begin// except first row
        always @(posedge clk) context[FIRST_IN_ROW] <= packed_context_out[WIDTH*(r-1) +: WIDTH];
    end
    if (LAST_ROW != r) begin // except last row
        assign packed_context_in[WIDTH*r +: WIDTH] = context[LAST_IN_ROW];
    end
end // for rows
endgenerate

//------------------------------------------------------------------------------
//rank transform calculation
reg [WINDOW_ELEMENTS-1:0] less_than_center;
localparam MIDDLE_INDEX = (WINDOW_ELEMENTS-1) / 2; // zero based
wire [7:0] center_pixel;
wire [2:0] control_signals;
assign {center_pixel, control_signals} = context[MIDDLE_INDEX];
genvar el;
generate
    for (el = 0; el < WINDOW_ELEMENTS; el = el + 1) begin : check_less_than_center
        always @(posedge clk) less_than_center[el] <= context[el][WIDTH-1 -: 8] < center_pixel;
    end
endgenerate

reg [OUTPUT_WIDTH-1:0] count_ones;
integer idx;
always @* begin
    count_ones = {OUTPUT_WIDTH{1'b0}};
    for( idx = 0; idx<WINDOW_ELEMENTS; idx = idx + 1) begin
        count_ones = count_ones + less_than_center[idx];
    end
end

reg [2:0] control_signals_del;
always @(posedge clk) control_signals_del <= control_signals;

assign rank_transform_out = count_ones;
assign {de_out, h_sync_out, v_sync_out} = control_signals_del;
assign clk_out = clk;

endmodule
