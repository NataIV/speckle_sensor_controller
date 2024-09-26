`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.07.2024 17:10:34
// Design Name: 
// Module Name: filter_FIR
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module filter_FIR#(
        NB_DATA = 12,
        ORDER = 4
    ) (
        input clk,
        input rst,
        input  [NB_DATA-1:0] i_sample,
        output  [NB_DATA-1:0] out
    );

    reg [NB_DATA-1:0] x [ORDER:0];

    
    always@(*) x[0] = i_sample;
    genvar i;
    generate
        for(i = 1; i <= ORDER; i = i + 1) begin
            always@(posedge clk)begin
                if(rst)begin
                    x[i] <= {NB_DATA {1'b0}};        
                end else begin
                    if (i > 0) begin
                        x[i] <= x[i-1];
                    end
                end
            end
        end
    endgenerate

    wire unsigned [ORDER + NB_DATA-1:0] sum [ORDER:0];

    genvar k;
    generate
        for(k = 1; k <= ORDER; k = k + 1) begin
            assign sum[k] = x[k] + sum[k-1];
        end
    endgenerate
    
    assign sum[0] = x[0];
    assign out = sum[ORDER] >> $clog2(ORDER);



endmodule
