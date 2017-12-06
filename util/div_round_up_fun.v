`ifndef _div_round_up_fun_v_
`define _div_round_up_fun_v_

function integer div_round_up;
    input integer dividend;
    input integer divisor;
    begin
        div_round_up = 0; // returned upon division by zero
        if (0 != divisor)
        begin
            for (div_round_up = 0; div_round_up*divisor < dividend; )
                div_round_up = div_round_up + 1;
        end
    end
endfunction

`endif // _div_round_up_fun_v_
