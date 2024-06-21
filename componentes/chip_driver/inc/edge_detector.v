`ifndef EDGE_DETECTOR_V
`define EDGE_DETECTOR_V
`timescale 1ns / 1ps

module edge_detector 
#(  parameter 
        FLANK = 1
)
(
    input clk, rst,
    input level,
    output tick
);

    reg state;

    generate
        if(FLANK == 1) begin
            assign tick = ~state & level;
        end else if (FLANK == 2) begin
            assign tick = state ^ level;
        end else begin
            assign tick = state & ~level;
        end
    endgenerate

    //assign tick = ~state & level;

    // flip flop D
    always@(posedge clk or posedge rst)begin
        if (rst)
            state <= 1'b0;
        else
            state <= level;
    end


endmodule

`endif