module dodeque (
    clk,
    reset,

    i__packet_time_stamp,
    i__packet_null,
    i__queue_length,
    i__time_counter,
    i__interval,

    o__okay_to_drop,
    o__first_above_time
);

import  CodelPkg::*;

/*** Inputs                     ***/
input   logic                   clk;
input   logic                   reset;

input   logic                   i__packet_null;
input   TimeCtr                 i__packet_time_stamp;
input   QueueLength             i__queue_length;
input   TimeCtr                 i__time_counter;
input   TimeCtr                 i__interval;

/*** Outputs                    ***/
output  logic                   o__okay_to_drop;
output  TimeCtr                 o__first_above_time; 

/*** Registers                  ***/
TimeCtr                         r__first_above_time__pff;
TimeCtr                         r__target__pff; 
QueueLength                     r__max_packet__pff; 

/*** Wire Nets                  ***/
TimeCtr                         w__first_above_time__next;
TimeCtr                         w__sojourn_time;
logic                           w__okay_to_drop;

/*** Combinational Logic        ***/
assign  o__okay_to_drop     =   w__okay_to_drop;
assign  o__first_above_time =   w__first_above_time__next;

always_comb
begin
    if (i__packet_null)
    begin
    	w__first_above_time__next   =   '0;
    	w__okay_to_drop             =   1'b0;
    end
    else 
    begin
        if ((w__sojourn_time < r__target__pff) || (i__queue_length < r__max_packet__pff))
        begin
            w__first_above_time__next=  '0;
            w__okay_to_drop          =  1'b0;
        end
        else
        begin
            if (r__first_above_time__pff == '0) 
            begin
                w__first_above_time__next=  i__time_counter +  i__interval;
                w__okay_to_drop          =  1'b0;
            end
            else if (i__time_counter >= r__first_above_time__pff)
            begin
            	w__first_above_time__next=  r__first_above_time__pff;
                w__okay_to_drop          =  1'b1;
            end
            else
            begin
                w__first_above_time__next=  r__first_above_time__pff;
                w__okay_to_drop          =  1'b0;
            end
        end
    end
end


always_comb
begin
    w__sojourn_time     =   i__time_counter - i__packet_time_stamp;
end

always_ff @(posedge clk)
begin
    if (reset)
    begin
        r__first_above_time__pff    <=  '0;        
        r__max_packet__pff          <=  MAX_PACKET; 
        r__target__pff              <=  TARGET;
    end
    else
    begin
        r__first_above_time__pff    <=  w__first_above_time__next;
        r__max_packet__pff          <=  MAX_PACKET; 
        r__target__pff              <=  TARGET;
    end
end

endmodule

