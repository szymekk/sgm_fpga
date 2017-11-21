module img_coordinates_counter #(
    ROW_WIDTH = 10,
    COL_WIDTH = 11
)
(
    //inputs
    input clk,
    input de_in,
    input h_sync_in,
    input v_sync_in,
    //outputs
    output [ROW_WIDTH - 1 : 0] row_out,
    output [COL_WIDTH - 1 : 0] col_out
);

    // zliczanie numeru wiersza i kolumny na podstawie hsync/vsync/de
    reg old_h_sync = 0;
    reg old_v_sync = 0;
    reg old_de = 0;
    reg new_row = 0;
    reg [ROW_WIDTH - 1 : 0] row = 0;
    reg [COL_WIDTH - 1 : 0] col = 0;
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
    
    assign row_out = row;
    assign col_out = col;
    
endmodule
