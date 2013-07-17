module fifo (
    clk,
    reset,

    i__read,
    i__write,
    i__packet,
    i__time_stamp,

    o__full,
    o__empty,
    o__packet,
    o__time_stamp,
    o__queue_length
);

import  CodelPkg::*;

/*** Parameters                 ***/
parameter   DEPTH           =   QUEUE_DEPTH;

/*** Local Data Structure       ***/
typedef struct packed {
	Packet                      packet;
	TimeCtr                     time_stamp;
} Data;

/*** Inputs                     ***/
input   logic                       clk;
input   logic                       reset;

input   logic                       i__read;
input   logic                       i__write;
input   Packet                      i__packet;
input   TimeCtr                     i__time_stamp;

/*** Outputs                    ***/
output  logic                       o__full;
output  logic                       o__empty;
output  Packet                      o__packet;
output  TimeCtr                     o__time_stamp;
output  logic [$clog2(DEPTH)-1:0]   o__queue_length;

/*** Wires                      ***/
Data                            w__in_data;
Data                            w__out_data;

logic                           w__not_full;
logic                           w__not_empty;


/*** Sub-modules                ***/
fifo_base                       #(
    .DATA_WIDTH                 ($bits(Packet)+$bits(TimeCtr)),
    .DEPTH                      (DEPTH)
) packet_fifo                   (
    .clk                        (clk),
    .reset                      (reset),

    .i__data_in_valid           (i__write),
    .i__data_in                 (w__in_data),
    .o__data_in_ready           (w__not_full),
    .o__data_in_ready__next     (),

    .o__data_out_valid          (w__not_empty),
    .o__data_out                (w__out_data),
    .i__data_out_ready          (i__read),
    .i__clear_all               (1'b0),
    .oa__all_data               (),

    .o__fifo_length             (o__queue_length)
);


/*** Combinational Logic        ***/
assign  o__full             =   ~w__not_full;
assign  o__empty            =   ~w__not_empty;

always_comb
begin
    w__in_data.packet       =   i__packet;
    w__in_data.time_stamp   =   i__time_stamp;

    o__packet               =   w__out_data.packet;
    o__time_stamp           =   w__out_data.time_stamp;
end


endmodule

