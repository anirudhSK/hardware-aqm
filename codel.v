// -----------------------------------------------------------------------
//
// Top level module - CODEL
// Inputs:
// [1] i__packet: Packet to be enqueued
//     If i__packet.valid == 1'b1, then we have a 
//     valid packet on the link and we can enqueue it
// [2] i__link_ready: Whenever the link is
//     ready to accept a packet, it pulls this signal high.
//     Think of it like there is a queue on the egress
//     link, and whenever it is not full it is high.
// 
// Outputs:
// [1] o__queue_full: Is the packet queue full
//     If you send a packet when this signal is 1
//     it will get dropped with no warning. Send packet
//     only after checking that this value is 0
// [2] o__packet: Packet to be sent out to link
//     Equivalent of return r;
// [3] o__drop_packet: Drop the returned packet
//
// -----------------------------------------------------------------------

   
module codel (
    clk,
    reset,

    i__packet,
    i__link_ready,

    o__queue_full,
    o__packet,
    o__drop_packet

);

import  CodelPkg::*;

/*** Local Data Structures      ***/
typedef enum logic {
	DONT_DROP   =   1'b0,
	DROP        =   1'b1
} Dropping;


/*** Inputs                     ***/
input       logic               clk;
input       logic               reset;
input       Packet              i__packet;
input       logic               i__link_ready;

/*** Outputs                    ***/
output      logic               o__queue_full;
output      Packet              o__packet;
output      logic               o__drop_packet;


/*** Registers                  ***/
Dropping                        r__dropping__pff;
TimeCtr                         r__count__pff;
TimeCtr                         r__drop_next__pff;
TimeCtr                         r__interval__pff;

/*** Wires                      ***/
// Next state signals
Dropping                        w__dropping__next;
TimeCtr                         w__count__next;
TimeCtr                         w__time_counter;
TimeCtr                         w__time_counter__next;
TimeCtr                         w__drop_next__next;

// FIFO Signals
logic                           w__read_queue;
logic                           w__write_queue;
TimeCtr                         w__out_packet_time_stamp;
Packet                          w__out_packet;
logic                           w__fifo_empty;
logic [$clog2(QUEUE_DEPTH)-1:0] w__queue_length;

logic                           w__okay_to_drop;
TimeCtr                         w__next_time_to_drop;

TimeCtr                         w__first_above_time;
TimeCtr                         w__control_law_input;
logic                           w__drop_this_packet;


/*** Sub-modules                ***/
// Time Counter ---- Returns the current time
// Currently this is a 32-bit value --- see globals.v
// to change the value.
counter                         #(
    .NUM_COUNT                  (NUM_COUNT)
) time_ctr                      (
    .clk                        (clk),
    .reset                      (reset),
    .i__inc                     (1'b1),
    .o__count                   (w__time_counter),
    .o__count__next             (w__time_counter__next)
);


// The actual packet queue -- holds the packet
// and the associated time stamp. It also 
// returns the length of the queue for comparison.
fifo                            #(
    .DEPTH                      (QUEUE_DEPTH)
) packet_queue                  (
    .clk                        (clk),
    .reset                      (reset),
    .i__read                    (w__read_queue),
    .i__write                   (w__write_queue),

    .o__full                    (o__queue_full),
    .o__empty                   (w__fifo_empty),
    .o__packet                  (w__out_packet),
    .o__time_stamp              (w__out_packet_time_stamp),
    .o__queue_length            (w__queue_length),

    .i__packet                  (i__packet),
    .i__time_stamp              (w__time_counter)
);

// This module implements the dodequeue function
// It spits out the first_above_time, and the
// okay_to_drop value for the packet in the head
// of the packet queue.
dodeque dodeque_instance        (
    .clk                        (clk),
    .reset                      (reset),

    .i__packet_null             (w__fifo_empty),
    .i__packet_time_stamp       (w__out_packet_time_stamp),
    .i__queue_length            (w__queue_length),
    .i__time_counter            (w__time_counter),
    .i__interval                (r__interval__pff),

    .o__okay_to_drop            (w__okay_to_drop),
    .o__first_above_time        (w__first_above_time)
);

// Computes the control law for the specified input
compute_control_law next_time_to_drop (
    .i__input                   (w__control_law_input),
    .i__interval                (r__interval__pff),
    .i__count                   (w__count__next),                
    .o__output                  (w__next_time_to_drop)
);


/*** Combinational Logic        ***/
assign  o__packet           =   w__read_queue ? w__out_packet : '0;
assign  o__drop_packet      =   w__drop_this_packet;


always_comb
begin
    if (i__packet.valid)
    	w__write_queue      =   1'b1;
    else
    	w__write_queue      =   1'b0;
end

always_comb
begin
    if (i__link_ready)
    begin
        case (r__dropping__pff)
            DONT_DROP:                  // The controller is currently in the DONT_DROP state
            begin
                w__control_law_input    =   w__time_counter;

                if (~w__okay_to_drop)   // Not okay to drop the current packet (either because 
                	                    // okay_to_drop is zero, or because of NULL
                	                    // packet
                begin
                    w__drop_next__next  =   r__drop_next__pff;
                    w__drop_this_packet =   1'b0;

                	w__dropping__next   =   DONT_DROP;
                	w__count__next      =   r__count__pff;
                	if (~w__fifo_empty && i__link_ready)
                		w__read_queue   =   1'b1;
                	else
                		w__read_queue   =   1'b0;
                end
                else
                begin
                    if ( ((w__time_counter - r__drop_next__pff) < r__interval__pff) 
                    	    || (w__time_counter - w__first_above_time >= r__interval__pff) )
                    begin
                        w__read_queue       =   i__link_ready;
                        w__drop_this_packet =   1'b1;

                        if ((w__time_counter - r__drop_next__pff) < r__interval__pff)
                        	w__count__next  =   (r__count__pff > 2'b10) ? (r__count__pff - 2'b10) : 1'b1;
                        else
                        	w__count__next  =   1'b1;

                        w__drop_next__next  =   w__next_time_to_drop;   

                        w__dropping__next   =   DROP;
                    end
                    else
                    begin 
                        w__read_queue       =   i__link_ready;
                        w__drop_this_packet =   1'b0;
                        w__count__next      =   r__count__pff;
                        w__dropping__next   =   DONT_DROP;
                        w__drop_next__next  =   r__drop_next__pff;
                    end
                end
            end

            DROP:       // DROP state
            begin
                if (~w__okay_to_drop)
                begin
                    w__dropping__next   =   DONT_DROP;
                    w__read_queue       =   ~w__fifo_empty && i__link_ready;
                    w__count__next      =   r__count__pff;
                    w__control_law_input=   r__drop_next__pff;
                    w__drop_next__next  =   w__next_time_to_drop;
                    w__drop_this_packet =   1'b0;
                end
                else
                begin
                    if (w__time_counter < r__drop_next__pff)
                    begin
                        w__drop_this_packet =   1'b0;
                        w__dropping__next   =   DONT_DROP;
                        w__read_queue       =   i__link_ready;
                        w__count__next      =   r__count__pff;
                        w__control_law_input=   w__time_counter;
                        w__drop_next__next  =   r__drop_next__pff;
                    end
                    else
                    begin
                        w__drop_this_packet =   1'b1;
                        w__dropping__next   =   DROP;
                        w__read_queue       =   i__link_ready;
                        w__count__next      =   r__count__pff + 1'b1;
                        w__control_law_input=   w__time_counter;        // Doesnt matter
                        w__drop_next__next  =   r__drop_next__pff;
                    end
                end
            end

            default: 
            begin
                w__dropping__next   =   r__dropping__pff;
                w__count__next      =   r__count__pff;
                w__read_queue       =   1'b0;
                w__drop_next__next  =   r__drop_next__pff;
                w__control_law_input=   w__time_counter;
                w__drop_this_packet =   1'b0;
            end
        endcase
    end
    else
    begin
        w__dropping__next   =   r__dropping__pff;
        w__count__next      =   r__count__pff;
        w__read_queue       =   1'b0;
        w__drop_next__next  =   r__drop_next__pff;
        w__control_law_input=   w__time_counter;
        w__drop_this_packet =   1'b0;
    end
end



/*** Sequential Logic           ***/
always_ff @(posedge clk)
begin
    if (reset)
    begin
        r__dropping__pff        <=  DONT_DROP;
        r__drop_next__pff       <=  '0;                 // TODO Set default value
        r__count__pff           <=  '0; 
        r__interval__pff        <=  INTERVAL;
    end
    else
    begin
        r__dropping__pff        <=  DROP;
        r__drop_next__pff       <=  w__drop_next__next;
        r__count__pff           <=  w__count__next;
        r__interval__pff        <=  INTERVAL;
    end
end

endmodule

