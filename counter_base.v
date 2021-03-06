
module counter_base(
    //--------------------------------------------------------------------------
    // Global signals
    //--------------------------------------------------------------------------
    clk,
    reset,

    //--------------------------------------------------------------------------
    // Control interface
    //--------------------------------------------------------------------------
    i__max_count,

    //--------------------------------------------------------------------------
    // Input interface
    //--------------------------------------------------------------------------
    i__inc,

    //--------------------------------------------------------------------------
    // Output interface
    //--------------------------------------------------------------------------
    o__count,
    o__count__next
);

//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
parameter COUNT_WIDTH                   = 3;
parameter INIT_VALUE                    = 1'b0;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Global signals
//------------------------------------------------------------------------------
input  logic                            clk;
input  logic                            reset;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Control interface
//------------------------------------------------------------------------------
input  logic [COUNT_WIDTH-1:0]          i__max_count;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Input interface
//------------------------------------------------------------------------------
input  logic                            i__inc;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Output interface
//------------------------------------------------------------------------------
output logic [COUNT_WIDTH-1:0]          o__count;
output logic [COUNT_WIDTH-1:0]          o__count__next;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------
logic [COUNT_WIDTH-1:0]                 r__count__pff;
logic [COUNT_WIDTH-1:0]                 w__count__next;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Output assignments
//------------------------------------------------------------------------------
assign o__count         = r__count__pff;
assign o__count__next   = w__count__next;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Count logic
//------------------------------------------------------------------------------
always_comb
begin
    w__count__next = r__count__pff;

    if(i__inc == 1'b1)
    begin
        if(r__count__pff == i__max_count)
        begin
            w__count__next = '0;
        end
        else
        begin
            w__count__next = r__count__pff + 1;
        end
    end
end

always_ff @ (posedge clk)
begin
    if(reset == 1'b1)
    begin
        r__count__pff <= INIT_VALUE;
    end
    else
    begin
        r__count__pff <= w__count__next;
    end
end
//------------------------------------------------------------------------------

endmodule

