`timescale 1ns / 1ps
//-----------------------------------------------
// Company: agh
// Engineer: komorkiewicz
// Create Date:    11:41:13 05/10/2011 
// Description: log image to ppm file
//-----------------------------------------------
module hdmi_out
(
  input hdmi_clk,
  input hdmi_vs,
  input hdmi_de,
  input [31:0] hdmi_data
);
//-----------------------------------------------
integer out_file = 0;

// TK invert du to Zybo
wire w_hdmi_vs_i = !hdmi_vs;
reg [7:0]vs_count = 8'h0;
reg hdmi_vs_i_del = 1;
//-----------------------------------------------
//reg [12:0] pixels_written_to_file = 13'd0;
integer pixels_written_to_file = 0;


reg[15*8:0] string;
reg[10*8:0] num = 5;
wire [3*8:0] str1 = "abc";
wire[3*8:0] str2 = "xyz";

localparam hr = 800;
localparam vr = 300;
integer i, j, temp;
realtime time_capture = 0.0;
`include "../util/write_int_b10_to_file_task.v"
always @(posedge hdmi_clk)
begin
    hdmi_vs_i_del <= w_hdmi_vs_i;
    
    if ((hdmi_vs_i_del == 1'b1) && (w_hdmi_vs_i == 1'b0) && out_file)
    begin

        $sformat(string,"_%s_%0d_%s_",str1,num,str2);
        $display("string is: [%s]", string);
        
        time_capture = $realtime;
        $display("%t", time_capture);
        $display("[%t] closing output file [descriptor: %d] [%d px written]", time_capture, out_file, pixels_written_to_file);
        
        $fclose(out_file);
        $stop;
    end
    
    if((hdmi_vs_i_del == 1'b0) && (w_hdmi_vs_i == 1'b1))
    begin
    
        time_capture = $realtime;
        out_file = $fopen({"out_",vs_count[5:0]/10+8'h30,vs_count[5:0]%10+8'h30,".ppm"}, "wb");
        if(!out_file)
        begin
            $display("File Open Error (write)! [%t]", time_capture);
            $stop;
        end
        pixels_written_to_file = 0;
        $display("[%t] opened output file out%02d.ppm for writing, [descriptor: %d]", time_capture, vs_count, out_file);
        // 10 to LF
//        $fwrite(out_file, "P6%c64 64%c255\n", 10, 10);
        $fwrite(out_file, "P6%c", 10);
        write_int_b10_to_file(hr, out_file);
        $fwrite(out_file, " ");
        write_int_b10_to_file(vr, out_file);
        $fwrite(out_file, "%c255\n", 10);
    
        vs_count <= vs_count + 1;
    end
    else
    begin
        if(hdmi_de && out_file)
        begin
            $fwrite(out_file,"%c", {hdmi_data[23:16]});
            $fwrite(out_file,"%c", {hdmi_data[15:8]});
            $fwrite(out_file,"%c", {hdmi_data[7:0]});
            pixels_written_to_file = pixels_written_to_file + 1;
        end
    end
end
//-----------------------------------------------
endmodule
//-----------------------------------------------
