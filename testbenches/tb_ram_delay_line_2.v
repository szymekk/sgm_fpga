//`timescale 1ns / 1ps
module tb_ram_delay_line_2 (
);

reg clk = 1'b0;
initial
begin
    while(1)
    begin
        #1 clk = 1'b0;
        #1 clk = 1'b1;
    end
end

localparam DATA_WIDTH = 12;

reg garbage = 0;

localparam IMG_WIDTH = 100;
localparam PORCH = 10;
reg de_img = 1;
reg [DATA_WIDTH-1:0] data_in = 'h101;
initial 
begin 
    repeat(IMG_WIDTH - 1)@(posedge clk) begin data_in <= data_in + 1; de_img <= 1; end
    repeat(PORCH)@(posedge clk) begin data_in <= garbage; de_img <= 0; end
    @(posedge clk) begin data_in <= 'h201; de_img <= 1; end
    repeat(IMG_WIDTH - 1)@(posedge clk) begin data_in <= data_in + 1; de_img <= 1; end
    repeat(PORCH)@(posedge clk) begin data_in <= garbage; de_img <= 0; end
    @(posedge clk) begin data_in <= 'h301; de_img <= 1; end
    repeat(IMG_WIDTH - 1)@(posedge clk) begin data_in <= data_in + 1; de_img <= 1; end
    repeat(PORCH)@(posedge clk) begin data_in <= garbage; de_img <= 0; end
    @(posedge clk) begin data_in <= 'h401; de_img <= 1; end
    repeat(IMG_WIDTH - 1)@(posedge clk) begin data_in <= data_in + 1; de_img <= 1; end
    repeat(PORCH)@(posedge clk) begin data_in <= garbage; de_img <= 0; end
    $stop;
end

localparam LINE_WIDTH = IMG_WIDTH + PORCH;
reg [11:0] column = 0;
always @(posedge clk) begin
    column <= column + 1;
    if (column == LINE_WIDTH - 1)
        column <= 0;
end
reg [DATA_WIDTH-1:0] data_modified_in = 'h0;
reg previous_de_img = 0;
always @(posedge clk) begin
    data_modified_in <= data_in + 'h10;
    previous_de_img <= de_img;
end
wire extended_de_img = de_img || previous_de_img;

localparam FIRST_COL = 0;
localparam SECOND_COL = FIRST_COL + 1;
localparam LAST_COL = IMG_WIDTH - 1;
localparam PENULTIMATE_COL = LAST_COL - 1;
wire de = (column <= LAST_COL) ? 1'b1 : 1'b0;
wire de_top_left = (column <= PENULTIMATE_COL);
wire de_top_right = (SECOND_COL <= column) && (column <= LAST_COL);

wire [DATA_WIDTH-1:0] dut_out;
wire [DATA_WIDTH-1:0] dut_test_out;
wire [DATA_WIDTH-1:0] dut_modified_out;
wire [DATA_WIDTH-1:0] ff_out;
wire [DATA_WIDTH-1:0] ff_modified_out;

//wire [DATA_WIDTH-1:0] dut_test_out;
//wire [DATA_WIDTH-1:0] top_left = de_top_right ? dut_test_out : 0;
//wire [DATA_WIDTH-1:0] top_right = de_top_left ? dut_test_out : 0;

wire de_tested;
wire discrepancy = (ff_out !== dut_out);

localparam OFFSET = -1;//1 OK, 0 OK, -1 OK
generate
    if (OFFSET == -1)
        assign de_tested = de_top_left;
    else if (OFFSET == 0)
        assign de_tested = de;
    else if (OFFSET == 1)
        assign de_tested = de_top_right;
    else
        invalid_OFFSET_value nonexisting_module_name();
endgenerate

ram_delay_line
#(
    .DATA_WIDTH(DATA_WIDTH),
    .DELAY(IMG_WIDTH + OFFSET)
) DUT (
    .clk(clk),
    .ce(de_img),
    .rst(1'b0),
    .data_in(data_in),
    //outputs
    .data_out(dut_out)
);

ram_delay_line
#(
    .DATA_WIDTH(DATA_WIDTH),
    .DELAY(LINE_WIDTH + OFFSET) // full line width
) DUT_test (
    .clk(clk),
    .ce(1'b1), // const 1
    .rst(1'b0),
    .data_in(data_in),
    //outputs
    .data_out(dut_test_out)
);

delay_line
#(
    .N(DATA_WIDTH),
    .DELAY(LINE_WIDTH + OFFSET)
) reference (
    .clk(clk),
    .ce(1'b1),
    .idata(data_in),
    //outputs
    .odata(ff_out)
);

delay_line
#(
    .N(DATA_WIDTH),
    .DELAY(LINE_WIDTH + OFFSET - 1)
) reference_modified (
    .clk(clk),
    .ce(1'b1),
    .idata(data_modified_in),
    //outputs
    .odata(ff_modified_out)
);

//ram_delay_line
//#(
//    .DATA_WIDTH(DATA_WIDTH),
//    .DELAY(IMG_WIDTH + OFFSET - 1) // full line width
//) DUT_modified (
//    .clk(clk),
//    .ce(de_img), // const 1
//    .rst(1'b0),
//    .data_in(data_modified_in),
//    //outputs
//    .data_out(dut_modified_out)
//);
ram_delay_line
#(//OFFSET 1 OK, 0 OK
    .DATA_WIDTH(DATA_WIDTH),
    .DELAY(IMG_WIDTH + OFFSET) // full line width
) DUT_modified (
    .clk(clk),
    .ce(extended_de_img), // extend de_img by one cycle
    .rst(1'b0),
    .data_in(data_modified_in),
    //outputs
    .data_out(dut_modified_out)
);

always @(posedge clk) begin
    if (de_tested && (ff_out !== dut_out))
    begin
        $display("[%d] ASSERTION FAILED in %m", $time);
        $display("EXPECTED: ff_out === dut_out");
        $display("ACTUAL: %d !== %d", ff_out, dut_out);
//        $finish;
        $stop;
    end
end

endmodule
