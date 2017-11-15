//`timescale 1ns / 1ps
// test ppm read and write
module tb_file_io(
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
hdmi_in file_input (//DUT_1
    .hdmi_clk(rx_pclk), 
    .hdmi_de(rx_de), 
    .hdmi_hs(rx_hsync), 
    .hdmi_vs(rx_vsync), 
    .hdmi_r(rx_red), 
    .hdmi_g(rx_green), 
    .hdmi_b(rx_blue)
    );

// --------------------------------------
// Output assigment
// --------------------------------------
assign tx_de = rx_de;
assign tx_hsync = rx_hsync;
assign tx_vsync = rx_vsync;
assign tx_red = rx_red;
assign tx_green = rx_green;
assign tx_blue = rx_blue;

// --------------------------------------
// HDMI output
// --------------------------------------
hdmi_out file_output (//DUT_2
    .hdmi_clk(rx_pclk), 
    .hdmi_vs(tx_vsync), 
    .hdmi_de(tx_de), 
    .hdmi_data({8'b0,tx_red,tx_green,tx_blue})
    );

endmodule // tb_file_io
