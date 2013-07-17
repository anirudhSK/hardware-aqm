module compute_control_law (
    i__input,
    i__interval,
    i__count,
    o__output
);

import  CodelPkg::*;

/*** Inputs                     ***/
input   TimeCtr                 i__input;
input   TimeCtr                 i__interval;
input   Count                   i__count; 

/*** Outputs                    ***/
output  TimeCtr                 o__output;

/*** Combinational Logic        ***/
assign  o__output   = (i__input + (i__interval / i__count));  // TODO Wrong formula, but okay for now

endmodule

