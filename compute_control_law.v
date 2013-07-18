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

/*** Wire Nets                  ***/
TimeCtr                         w__invsqrt;

/*** Sub-modules                ***/
invsqrt get_invsqrt             (
        .i__input               (i__count),
        .o__output              (w__invsqrt)
);

/*** Combinational Logic        ***/
// assign  o__output   = (i__input + (i__interval / i__count));  // TODO Wrong formula, but okay for now
assign  o__output   = (i__input + w__invsqrt); 

endmodule

