`ifndef _write_int_b10_to_file_task_v_
`define _write_int_b10_to_file_task_v_

`include "digits_b10_fun.v"

task write_int_b10_to_file;
input integer number, out_file;
integer i, j, temp;
begin
    for (i=digits_b10(number); i > 0; i=i-1)
    begin
        temp = number;
        for (j=1; j < i; j=j+1)
        begin
            temp = temp / 10;
        end
        $fwrite(out_file, "%c", "0"+(temp % 10) );
    end
end
endtask

`endif // _write_int_b10_to_file_task_v_
