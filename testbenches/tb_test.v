//`timescale 1ns / 1ps

module tb_test(
    );
	 

wire rx_pclk;

wire rx_de;
wire rx_hsync;
wire rx_vsync;

wire [7:0] rx_red;
wire [7:0] rx_green;
wire [7:0] rx_blue;


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

wire de_test;
wire hs_test;
wire vs_test;
wire [23:0] px_left;
wire [23:0] px_right;

half_img # (
    .H_SIZE(83)
    // 83 dla 64x64
    // 1664 dla 1280x720
) splitter_halfs (
    //inputs
    .clk(rx_pclk),
    .de_in(rx_de),
    .h_sync_in(rx_hsync),
    .v_sync_in(rx_vsync),
    .pixel_in(rx_pixel),//3 x 8 bit
    //outputs
    .de_out(de_test),
    .h_sync_out(hs_test),
    .v_sync_out(vs_test),
    .pixel_left(px_left),//3 x 8 bit
    .pixel_right(px_right)//3 x 8 bit
);



wire de_y;
wire hs_y;
wire vs_y;
wire [7:0] px_y;
rgb2y konwerter (
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





// --------------------------------------
// Output assigment
// --------------------------------------

/*
assign tx_de = rx_de;
assign tx_hsync = rx_hsync;
assign tx_vsync = rx_vsync;
assign tx_red = rx_red;
assign tx_green = rx_green;
assign tx_blue = rx_blue;
*/
/*
assign tx_de = de_test;
assign tx_hsync = hs_test;
assign tx_vsync = vs_test;
//assign {tx_red,tx_green,tx_blue} = px_right;
assign {tx_red,tx_green,tx_blue} = px_left;
*/

assign {tx_de,tx_hsync,tx_vsync} = {de_y,hs_y,vs_y};
assign {tx_red,tx_green,tx_blue} = {3{px_y}};

// --------------------------------------
// HDMI output
// --------------------------------------
hdmi_out file_output (
    .hdmi_clk(rx_pclk), 
    .hdmi_vs(tx_vsync), 
    .hdmi_de(tx_de), 
    .hdmi_data({8'b0,tx_red,tx_green,tx_blue})
    );


endmodule
