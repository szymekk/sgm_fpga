//`timescale 1ns / 1ps

module tb_half_img(
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

wire pclk_test;
wire de_test;
wire hs_test;
wire vs_test;
wire [23:0] px_left;
wire [23:0] px_right;

half_img # (
    .H_SIZE(83),
    // 83 dla 64x64
    // 1664 dla 1280x720
    .HALF_IMG_W(400)
//    .HALF_IMG_W(32)
) DUT (
    //inputs
    .clk(rx_pclk),
    .de_in(rx_de),
    .h_sync_in(rx_hsync),
    .v_sync_in(rx_vsync),
    .pixel_in(rx_pixel),//3 x 8 bit
    //outputs
    .clk_out(pclk_test),
    .de_out(de_test),
    .h_sync_out(hs_test),
    .v_sync_out(vs_test),
    .pixel_left(px_left),//3 x 8 bit
    .pixel_right(px_right)//3 x 8 bit
);

// --------------------------------------
// Output assigment
// --------------------------------------
assign tx_pclk = pclk_test;
assign tx_de = de_test;
assign tx_hsync = hs_test;
assign tx_vsync = vs_test;
//assign {tx_red,tx_green,tx_blue} = px_right;
assign {tx_red,tx_green,tx_blue} = px_left;

// --------------------------------------
// HDMI output
// --------------------------------------
hdmi_out file_output (
    .hdmi_clk(tx_pclk), 
    .hdmi_vs(tx_vsync), 
    .hdmi_de(tx_de), 
    .hdmi_data({8'b0,tx_red,tx_green,tx_blue})
    );
function integer digits_b10;
    input integer value;
    begin 
        for (digits_b10 = 0; value >= 1; digits_b10 = digits_b10 + 1)
        begin
            value = value/10;
        end
    end 
endfunction
reg [14:0] cnt = 0;
always @(posedge tx_pclk or negedge tx_pclk)
begin
    cnt <= cnt+1;
end
localparam testa1 = 249/10;
localparam testaa1 = 250/10;
localparam tests1 = 251/10;
localparam test1 = 254/10;
localparam test2 = 255/10;
localparam test3 = 256/10;
localparam tests4 = 259/10;
localparam testz4 = 260/10;
localparam test4 = 261/10;
wire [3:0] log10 = $log10(cnt);
wire [3:0] digits_b10_output = digits_b10(cnt);
endmodule // tb_half_img
