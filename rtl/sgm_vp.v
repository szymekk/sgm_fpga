`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module sgm_vp(
    //inputs
    input clk,
    input [23:0] pixel_in,//3 x 8 bit
    input h_sync_in,
    input v_sync_in,
    input de_in,
    input [3:0] sw,// 16 opcji
    //outputs
    output de_out,
    output h_sync_out,
    output v_sync_out,
    output [23:0] pixel_out//3 x 8 bit
    );
// 1664 dla 1280x720
localparam IMG_WIDTH = 1280;
localparam HALF_IMG_WIDTH = IMG_WIDTH/2;

// multiplexer
wire [23:0]rgb_mux[15:0];
wire de_mux[15:0];
wire hsync_mux[15:0];
wire vsync_mux[15:0];

//--------------------------------------
// input assignment
//--------------------------------------

assign rgb_mux[0] = pixel_in;
assign de_mux[0] = de_in;
assign hsync_mux[0] = h_sync_in;
assign vsync_mux[0] = v_sync_in;

//--------------------------------------
// RGB -> Y (to grayscale)
//--------------------------------------

wire [7:0] pixel_y;
wire de_y;
wire hs_y;
wire vs_y;
rgb2y converter (
    //inputs
    .clk        (clk),
    .de_in      (de_in),
    .h_sync_in  (h_sync_in),
    .v_sync_in  (v_sync_in),
    .pixel_in   (pixel_in),//3 x 8 bit
    //outputs
    .de_out     (de_y),
    .h_sync_out (hs_y),
    .v_sync_out (vs_y),
    .pixel_out  (pixel_y)//8 bit
);

assign rgb_mux[1] = {3{pixel_y}};
assign de_mux[1] = de_in;
assign hsync_mux[1] = h_sync_in;
assign vsync_mux[1] = v_sync_in;

//--------------------------------------
// split into two images
//--------------------------------------

wire pclk_split;
wire de_split;
wire hs_split;
wire vs_split;
wire [7:0] px_left;
wire [7:0] px_right;

half_img # (
    // 1664 dla 1280x720
    .HALF_IMG_W(HALF_IMG_WIDTH),
    .PX_WIDTH(8)
) splitter_halfs_one_channel (
    //inputs
    .clk(clk),//dodaæ CLK_OUT konwerter
    .de_in(de_y),
    .h_sync_in(hs_y),
    .v_sync_in(vs_y),
    .pixel_in(pixel_y),//8 bit
    //outputs
    .clk_out(pclk_split),
    .de_out(de_split),
    .h_sync_out(hs_split),
    .v_sync_out(vs_split),
    .pixel_left(px_left),//8 bit
    .pixel_right(px_right)//8 bit
);

assign rgb_mux[2] = {3{px_left}};
assign de_mux[2] = de_split;
assign hsync_mux[2] = hs_split;
assign vsync_mux[2] = vs_split;

assign rgb_mux[3] = {3{px_right}};
assign de_mux[3] = de_split;
assign hsync_mux[3] = hs_split;
assign vsync_mux[3] = vs_split;

//--------------------------------------
// sgm
//--------------------------------------

wire sgm_pclk,sgm_de, sgm_hs, sgm_vs;
wire [7:0] sgm_px_disparity;
simple_sgm
# (
    //.DISPARITY_RANGE(64) // todo parametrize
) disparity_generator
(
    //inputs
    .clk(pclk_split),
    .de_in(de_split),
    .h_sync_in(hs_split),
    .v_sync_in(vs_split),
    .pixel_left(px_left),//8 bit
    .pixel_right(px_right),//8 bit
    //outputs
    .clk_out(sgm_pclk),
    .de_out(sgm_de),
    .h_sync_out(sgm_hs),
    .v_sync_out(sgm_vs),
    .pixel_disparity(sgm_px_disparity)//8 bit
);

localparam PIXEL_INTENSITY_LEVELS = 256;
localparam DISPARITY_RANGE = 64;
localparam SCALE_FACTOR = PIXEL_INTENSITY_LEVELS/DISPARITY_RANGE;

wire [7:0] scaled_out_px_disparity = SCALE_FACTOR*sgm_px_disparity;

assign rgb_mux[4] = {3{scaled_out_px_disparity}};
assign de_mux[4] = sgm_de;
assign hsync_mux[4] = sgm_hs;
assign vsync_mux[4] = sgm_vs;

//--------------------------------------
// unused
//--------------------------------------
generate
genvar i;
for (i = 5; i < 16; i = i + 1) begin : assign_unused_switches
    assign rgb_mux[i]  = pixel_in;
    assign de_mux[i] = de_in;
    assign hsync_mux[i] = h_sync_in;
    assign vsync_mux[i] = v_sync_in;
end
endgenerate

//--------------------------------------
// output assignment
//--------------------------------------

assign de_out = de_mux[sw];
assign h_sync_out = hsync_mux[sw];
assign v_sync_out = vsync_mux[sw];
assign pixel_out = rgb_mux[sw];
    
endmodule
