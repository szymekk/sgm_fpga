`ifndef _digits_b10_fun_v_
`define _digits_b10_fun_v_

function integer digits_b10;
    input integer value;
    begin 
        for (digits_b10 = 0; value >= 1; digits_b10 = digits_b10 + 1)
        begin
            value = value/10;
        end
    end 
endfunction

`endif // _digits_b10_fun_v_
