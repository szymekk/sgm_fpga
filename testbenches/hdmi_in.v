//`timescale 1ns / 1ps
//-----------------------------------------------
// read from ppm
//-----------------------------------------------
module hdmi_in
(
    //hdmi outputs
    output reg hdmi_clk,
    output hdmi_de,
    output hdmi_hs,
    output hdmi_vs,
    //image data
    output [7:0]hdmi_r,
    output [7:0]hdmi_g,
    output [7:0]hdmi_b
); 
//-----------------------------------------------
// dodać 640x480 @ 60 Hz
// 64x64 piksele
//horizontal
//parameter hr  = 64; //resolution
parameter hr  = 800; //resolution
parameter hbp = 8; //back porch
parameter hfp = 8; //front porch
parameter hs  = 2;  //sync len
//vertical
//parameter vr  = 64; //resolution
parameter vr  = 300; //resolution
parameter vbp = 8; //back porch
parameter vfp = 8; //front porch
parameter vs  = 4;   //sync len
//-----------------------------------------------
reg [10:0]h_counter = 0;
//reg [10:0]v_counter = 64+1;//480+7
reg [10:0]v_counter = vr+1;//480+7
//-----------------------------------------------
reg [7:0]red;
reg [7:0]green;
reg [7:0]blue;
//reg hdmi_clk=1'b0;
//-----------------------------------------------
initial
begin
    while(1)
    begin
        #1 hdmi_clk = 1'b0;
        #1 hdmi_clk = 1'b1;
    end
end  
//-----------------------------------------------
integer rgbfile = 0, i, dummy;

//-----------------------------------------------
always @(posedge hdmi_clk)
begin
    h_counter <= h_counter+1;
    
    if((hr+hbp+hs+hfp)-1 == h_counter) 
    begin
        h_counter <= 0;
        
        if(v_counter == (vr+vbp+vs+vfp)-1) v_counter <= 0;
        else v_counter <= v_counter + 1;
    end
end
//-----------------------------------------------
wire h_enable = (h_counter<hr) ? 1'b1 : 1'b0;
wire v_enable = (v_counter<vr) ? 1'b1 : 1'b0;

wire de_enable = h_enable && v_enable;

wire h_sync = (h_counter >= (hr + hfp) && h_counter < (hr + hfp + hs)) ? 1'b0 : 1'b1;
wire v_sync = (v_counter >= (vr + vfp) && v_counter < (vr + vfp + vs)) ? 1'b0 : 1'b1;
//-----------------------------------------------

reg de_del;
reg h_sync_del;
reg v_sync_del;
always @(posedge hdmi_clk)
begin
    de_del <= de_enable;
    h_sync_del <= h_sync;
    v_sync_del <= v_sync;
end

integer pixels_read = 0;

always @(posedge hdmi_clk)
begin
    if(de_enable && rgbfile)
    begin
        red   <= $fgetc(rgbfile);
        green <= $fgetc(rgbfile);
        blue  <= $fgetc(rgbfile);
        pixels_read <= pixels_read + 1;
    end
end
//-----------------------------------------------


`include "../util/digits_b10_fun.v"
localparam hr_digits = digits_b10(hr);
localparam vr_digits = digits_b10(vr);
localparam header_length = 3 + hr_digits + 1 + hr_digits + 1 + digits_b10(255) + 1;
//localparam filename = "geirangerfjord_64.ppm";
//localparam filename = "../../../hdmi_vga_zybo_src/geirangerfjord_64.ppm";
//localparam filename = "../../../hdmi_vga_zybo_src/reka_v3_64x64.ppm";
//localparam filename = "../../../hdmi_vga_zybo_src/reka_ramki.ppm";
localparam filename = "../../../hdmi_vga_zybo_src/tank_both_0001_color.ppm";
//localparam filename = "../../../hdmi_vga_zybo_src/L0001.ppm";
//localparam filename = "../../../hdmi_vga_zybo_src/R0001.ppm";
//localparam filename = "../../../hdmi_vga_zybo_src/out_ycbcr_vivado.ppm";
//localparam filename = "../../../hdmi_vga_zybo_src/czarna_ramka.ppm";
//localparam filename = "../../../hdmi_vga_zybo_src/linie.ppm";
//localparam filename = "../../../hdmi_vga_zybo_src/kropka.ppm";
realtime time_capture = 0.0;
always @(posedge hdmi_clk)
begin
    if (v_sync_del == 1'b1 && v_sync == 1'b0) // falling v_sync
    begin
        if(v_counter==(vr+vbp))
        begin
            time_capture = $realtime;
            $display("[%t] opening input file %s for reading", time_capture, filename); 
            rgbfile = $fopen(filename, "rb");
            if(!rgbfile)
            begin
                $display("File Open Error (read)! [%t]", time_capture);
                $stop;
            end

             // read file header
            for (i=0; i<header_length; i=i+1)//13 for P6_64 64_255_
            begin
                dummy = $fgetc(rgbfile); 
            end // for	

        end//if(v_counter==(vr+vbp))
    end // if vsync falling edge
end//always
//-----------------------------------------------

assign hdmi_r = red;
assign hdmi_g = green;
assign hdmi_b = blue;

assign hdmi_de = de_del;
// invert sync signals for Zybo
assign hdmi_hs = !h_sync_del;
assign hdmi_vs = !v_sync_del;

//-----------------------------------------------
endmodule
//-----------------------------------------------
