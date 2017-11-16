module rgb2y(
    //inputs
    input clk,
    input de_in,
    input h_sync_in,
    input v_sync_in,
    input [23:0] pixel_in,//3 x 8 bit
    //outputs
    output de_out,
    output h_sync_out,
    output v_sync_out,
    output [7:0] pixel_out//8 bit
    );

    wire signed [17:0] R, G, B;
    assign R = {10'b0,pixel_in[23:16]};
    assign G = {10'b0,pixel_in[15:8]};
    assign B = {10'b0,pixel_in[7:0]};

//-------------------------------------------------
    wire signed[35:0] out_R_Y, out_G_Y, out_B_Y;

//     R         G         B
//     0.2990    0.5870    0.1140
//001001100100010111   010010110010001011   000011101001011110
    
    // MULTIPLICATION // latency 3
    // --- --- --- Y mult --- --- ---
    // 0.2990; sign + 0 + 17 fraction
    s18_mult_s18 R_Y ( // latency 3
        //in
        .CLK(clk),
        .A(R), // 18 bit
        .B(18'b001001100100010111), // 18 bit
        //out
        .P(out_R_Y) // 36 bit
    );
     
    // 0.5870; sign + 0 + 17 fraction
    s18_mult_s18 G_Y (
        //in
        .CLK(clk),
        .A(G), // 18 bit
        .B(18'b010010110010001011), // 18 bit
        //out
        .P(out_G_Y) // 36 bit
    );
      
      // 0.1140; sign + 0 + 17 fraction
    s18_mult_s18 B_Y (
        //in
        .CLK(clk),
        .A(B), // 18 bit
        .B(18'b000011101001011110), // 18 bit
        //out
        .P(out_B_Y) // 36 bit
    );
    //-------------------------------------------------
    
    //-------------------------------------------------
    // ADDITION // latency 4
    // --- --- --- Y add --- --- ---
//    wire signed[8:0] RG_Y;
//    wire signed[8:0] BO_Y;
//    wire signed[8:0] Y;
    wire signed[8:0] RG_Y, BO_Y, Y;
    s9_add_s9 R_plus_G_Y ( // latency 2
        //in
        .A({out_R_Y[35],out_R_Y[24:17]}), // 9 bit
        .B({out_G_Y[35],out_G_Y[24:17]}), // 9 bit
        .CLK(clk),
        //out
        .S(RG_Y) // 9 bit
    );
    
    s9_add_s9 B_plus_offset_Y (
        //in
        .A({out_B_Y[35],out_B_Y[24:17]}), // 9 bit
        .B(9'b000000000), // 9 bit
        .CLK(clk),
        //out
        .S(BO_Y) // 9 bit
    );
    
    s9_add_s9 RG_plus_BO_Y ( // latency 2
        //in
        .A(RG_Y), // 9 bit
        .B(BO_Y), // 9 bit // offset Y = 0
        .CLK(clk),
        //out
        .S(Y) // 9 bit
    );
    
    //-------------------------------------------------



    //-------------------------------------------------
    assign pixel_out = Y[7:0]; // ommit sign
    // mult latency 3, add latency 4 (2+2)
    delay_line #(
        .N(3),
        .DELAY(7)
    ) signal_delayer (
        //inputs
        .clk    (clk),
        .ce     (1'b1),
        .idata  ({de_in,h_sync_in,v_sync_in}),
        //output
        .odata  ({de_out,h_sync_out,v_sync_out})
    );

endmodule //rgb2y
