//`timescale 1ns / 1ps

module tb_simple_sgm(
    );

localparam HALF_IM_WIDTH = 200;

wire rx_pclk;

wire rx_de;
wire rx_hsync;
wire rx_vsync;

wire [7:0] rx_red;
wire [7:0] rx_green;
wire [7:0] rx_blue;

wire tx_pclk;
wire tx_de;
wire tx_hsync;
wire tx_vsync;

wire [7:0] tx_red;
wire [7:0] tx_green;
wire [7:0] tx_blue;



// --------------------------------------
// HDMI input
// --------------------------------------
hdmi_in file_input (
    .hdmi_clk(rx_pclk), 
    .hdmi_de(rx_de), 
    .hdmi_hs(rx_hsync), 
    .hdmi_vs(rx_vsync), 
    .hdmi_r(rx_red), 
    .hdmi_g(rx_green), 
    .hdmi_b(rx_blue)
    );
    
wire [23:0] rx_pixel = {rx_red,rx_green,rx_blue};

wire de_y;
wire hs_y;
wire vs_y;
wire [7:0] px_y;
rgb2y konwerter (//dodaæ CLK_OUT
    //inputs
    .clk        (rx_pclk),
    .de_in      (rx_de),
    .h_sync_in  (rx_hsync),
    .v_sync_in  (rx_vsync),
    .pixel_in   (rx_pixel),//3 x 8 bit
    //outputs
    .de_out     (de_y),
    .h_sync_out (hs_y),
    .v_sync_out (vs_y),
    .pixel_out  (px_y)//8 bit
);

wire pclk_test;
wire de_test;
wire hs_test;
wire vs_test;
wire [7:0] px_left;
wire [7:0] px_right;

half_img # (
    .H_SIZE(83),
    // 83 dla 64x64
    // 1664 dla 1280x720
    .HALF_IMG_W(HALF_IM_WIDTH),
    .PX_WIDTH(8)
) splitter_halfs_one_channel (
    //inputs
    .clk(rx_pclk),//dodaæ CLK_OUT konwerter
    .de_in(de_y),
    .h_sync_in(hs_y),
    .v_sync_in(vs_y),
    .pixel_in(px_y),//8 bit
    //outputs
    .clk_out(pclk_test),
    .de_out(de_test),
    .h_sync_out(hs_test),
    .v_sync_out(vs_test),
    .pixel_left(px_left),//8 bit
    .pixel_right(px_right)//8 bit
);

wire dut_pclk, dut_de, dut_hs, dut_vs;
wire [7:0] dut_px_disparity;
simple_sgm
# (
    //.DISPARITY_RANGE(8)
) DUT
(
    //inputs
    .clk(pclk_test),
    .de_in(de_test),
    .h_sync_in(hs_test),
    .v_sync_in(vs_test),
    .pixel_left(px_left),//8 bit
    .pixel_right(px_right),//8 bit
    //outputs
    .clk_out(dut_pclk),
    .de_out(dut_de),
    .h_sync_out(dut_hs),
    .v_sync_out(dut_vs),
    .pixel_disparity(dut_px_disparity)//8 bit
);


// --------------------------------------
// Output assigment
// --------------------------------------

assign {tx_pclk,tx_de,tx_hsync,tx_vsync} = {dut_pclk,dut_de,dut_hs,dut_vs};
assign {tx_red,tx_green,tx_blue} = {3{dut_px_disparity}};

// --------------------------------------
// HDMI output
// --------------------------------------
hdmi_out file_output (
    .hdmi_clk(tx_pclk), 
    .hdmi_vs(tx_vsync), 
    .hdmi_de(tx_de), 
    .hdmi_data({8'b0,tx_red,tx_green,tx_blue})
    );


endmodule
