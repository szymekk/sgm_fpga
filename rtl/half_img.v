module half_img
# (
    parameter H_SIZE = 83,
    parameter HALF_IMG_W = 32,
    // 83 dla 64x64
    // 1664 dla 1280x720
    parameter PX_WIDTH = 24//8
)
(
    //inputs
    input clk,
    input de_in,
    input h_sync_in,
    input v_sync_in,
    input [PX_WIDTH-1:0] pixel_in,//3 x 8 bit
    //outputs
    output clk_out,
    output de_out,
    output h_sync_out,
    output v_sync_out,
    output [PX_WIDTH-1:0] pixel_right,//3 x 8 bit
    output [PX_WIDTH-1:0] pixel_left//3 x 8 bit
);

    wire [PX_WIDTH-1:0] pixel_del;
    
    delay_line #(
        .N(PX_WIDTH),
        .DELAY(HALF_IMG_W)//parameter
    ) half_img_delay (
        .clk(clk),
        .ce(1'b1),
        .idata(pixel_in),
        .odata(pixel_del)
    );
    
    // zliczanie numeru wiersza i kolumny
//    localparam IMG_H = 720;
//    localparam IMG_W = 1280;
    localparam IMG_H = 64;
    localparam IMG_W = 64;  
    reg [10:0]x_pos = 11'b0; // init
    reg [9:0] y_pos = 10'b0; // init
    always @(posedge clk)
    begin
        if(v_sync_in == 1'b1) // odwrotna logika: 1 - brak obrazu
        begin
            x_pos <= 11'b0;
            y_pos <= 10'b0;
        end
        else
        begin
            if(de_in == 1'b1)
            begin
                x_pos <= x_pos + 1;
                if(x_pos == IMG_W - 1)
                begin
                    x_pos <= 11'b0;
                    y_pos <= y_pos + 1;
                    if(y_pos == IMG_H - 1) y_pos <= 10'b0;
                end
            end // if
        end // else
    end // always
    
    // zliczanie numeru wiersza i kolumny na podstawie hsync/vsync/de
    reg old_h_sync = 0;
    reg old_v_sync = 0;
    reg old_de = 0;
    reg new_row = 0;
    reg [10:0] col = 0;
    reg [9:0] row = 0;
    always @(posedge clk)
    begin
        old_h_sync <= h_sync_in;
        old_v_sync <= v_sync_in;
        old_de <= de_in;
        
        //rising hsync
        if (old_h_sync == 1'b0 && h_sync_in == 1'b1)
        begin
            if (new_row)
            begin
                new_row <= 1'b0;
                row <= row+1;
                col <= 1'b0;
            end
        end
        else if(de_in == 1'b1 && old_de == 1'b0) //rising de
        begin
            new_row <= 1'b1;
        end
        
        if(de_in == 1'b1)
        begin
            col <= col+1;
        end
        
        if (old_v_sync == 1'b0 && v_sync_in == 1'b1) //rising vsync
        begin
            row <= 10'b0;
        end
        
    end // always

//    wire valid = ((col < HALF_IMG_W) || !de_in) ? 1'b0 : 1'b1;
    wire valid = ((col >= HALF_IMG_W) && de_in) ? 1'b1 : 1'b0;
    generate
    if(24 == PX_WIDTH) // color output
    begin
        assign pixel_left = (valid) ? pixel_del : 24'h00ffff;
        assign pixel_right = (valid) ? pixel_in : 24'hff0000;
    end else
    begin
        assign pixel_left = (valid) ? pixel_del : 0;
        assign pixel_right = (valid) ? pixel_in : 0;
    end
    endgenerate
    
    assign h_sync_out = h_sync_in;
    assign v_sync_out = v_sync_in;
    assign de_out = de_in; 
    assign clk_out = clk; 
    
endmodule
