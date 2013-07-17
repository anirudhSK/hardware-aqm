timeunit 1ns;
timeprecision 1ps;

package CodelPkg;

localparam  MAX_PACKET          =   8;      // Total size in bytes / Packet size in bytes
localparam  TARGET              =   32'b00000000000000001001010101000111;
localparam  NUM_COUNT           =   (1'b1<<32)-1;
localparam  TIME_COUNTER_LENGTH =   32;
localparam  INTERVAL            =   32'b00000000000000001001010101000111;

localparam  PACKET_DATA_WIDTH   =   10;
localparam  QUEUE_DEPTH         =   2;

typedef logic   [31:0]                      TimeCtr;
typedef logic   [31:0]                      Count;
typedef logic   [$clog2(QUEUE_DEPTH)-1:0]   QueueLength;

typedef struct packed {
	logic [PACKET_DATA_WIDTH-1:0]   data;
	logic                           valid;
} Packet;

endpackage

