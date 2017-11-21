`timescale 1ns / 1ps
//-----------------------------------------------
// write to pgm
//-----------------------------------------------
module grayscale_out #(
    parameter hr = 800,
    parameter vr = 300
)
(
    input hdmi_clk,
    input hdmi_vs,
    input hdmi_de,
    input [7:0] grayscale_data
);
//-----------------------------------------------
integer out_file = 0;

wire w_hdmi_vs_i = !hdmi_vs;
reg [7:0]vs_count = 8'h0;
reg hdmi_vs_i_del = 1;
//-----------------------------------------------
integer pixels_written_to_file = 0;

realtime time_capture = 0.0;
`include "../util/write_int_b10_to_file_task.v"
always @(posedge hdmi_clk)
begin
    hdmi_vs_i_del <= w_hdmi_vs_i;

    if ((hdmi_vs_i_del == 1'b1) && (w_hdmi_vs_i == 1'b0) && out_file)
    begin

        time_capture = $realtime;
        $display("[%t] closing output file [descriptor: %d] [%d px written]", time_capture, out_file, pixels_written_to_file);

        $fclose(out_file);
        $stop;
    end

    if((hdmi_vs_i_del == 1'b0) && (w_hdmi_vs_i == 1'b1))
    begin
    
        time_capture = $realtime;
        out_file = $fopen({"out_",vs_count[5:0]/10+8'h30,vs_count[5:0]%10+8'h30,".pgm"}, "wb");
        if(!out_file)
        begin
            $display("File Open Error (write)! [%t]", time_capture);
            $stop;
        end
        pixels_written_to_file = 0;
        $display("[%t] opened output file out%02d.pgm for writing, [descriptor: %d]", time_capture, vs_count, out_file);
//        $fwrite(out_file, "P5\n64 64\n255\n");
        $fwrite(out_file, "P5\n");
        write_int_b10_to_file(hr, out_file);
        $fwrite(out_file, " ");
        write_int_b10_to_file(vr, out_file);
        $fwrite(out_file, "\n255\n");

        vs_count <= vs_count + 1;
    end
    else
    begin
        if(hdmi_de && out_file)
        begin
            $fwrite(out_file,"%c", {grayscale_data[7:0]});
            pixels_written_to_file = pixels_written_to_file + 1;
        end
    end
end
//-----------------------------------------------
endmodule
//-----------------------------------------------
