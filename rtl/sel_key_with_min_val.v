// find minimum value and associated key
module sel_key_with_min_val #(
    VALUE_WIDTH = 8,
    KEY_WIDTH = 3
    )(
    input wire [VALUE_WIDTH-1:0] x1_val,
    input wire [KEY_WIDTH-1:0] x1_key,
    input wire [VALUE_WIDTH-1:0] x2_val,
    input wire [KEY_WIDTH-1:0] x2_key,
    output reg [VALUE_WIDTH-1:0] min_val,
    output reg [KEY_WIDTH-1:0] min_key
    );
    
    //--------------------beg_assert----------------
    generate
    if (0 >= VALUE_WIDTH /* WIDTH should be greater than zero */ ) begin : assertion_val_width
        VALUE_WIDTH_should_be_greater_than_zero non_existing_module();
    end
    endgenerate
    generate
    if (0 >= KEY_WIDTH /* WIDTH should be greater than zero */ ) begin : assertion_key_width
        KEY_WIDTH_should_be_greater_than_zero non_existing_module();
    end
    endgenerate
    //--------------------end_assert----------------

    always @(*) begin
        if (x1_val <= x2_val) begin
            min_val = x1_val;
            min_key = x1_key;
        end
        else begin
            min_val = x2_val;
            min_key = x2_key;
        end
    end

endmodule
