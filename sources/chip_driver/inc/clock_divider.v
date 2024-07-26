
`ifndef CLOCK_DIVIDER_V
`define CLOCK_DIVIDER_V
`timescale 1ns / 1ps


module clock_divider #(
    NB_DIVIDER = 24
)
(
    input wire i_clk,
    input wire i_rst,
    input wire [NB_DIVIDER-1 : 0] i_divider,
    output wire o_clk
);

    reg [NB_DIVIDER-1 : 0] count;

    always @(posedge i_clk or posedge i_rst) begin
        if(i_rst)
            count <= {NB_DIVIDER{1'b0}};
        else if (o_clk)
            count <= 0;
        else
            count <= count + 1;
    end

    assign o_clk = (count == i_divider);

endmodule

`endif /* CLOCK_DIVIDER_V */
