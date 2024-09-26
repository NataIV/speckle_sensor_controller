`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.07.2024 15:09:56
// Design Name: 
// Module Name: avg
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


module avg #(
    parameter NB_DATA = 12
)(
    input clk,
    input rst,
    input i_start,
    input i_adc_done,
    input [2:0] i_nSamples,
    input [NB_DATA-1:0] i_sample,
    
    output o_done,
    output o_adcTrigger,
    output [NB_DATA-1:0] o_result
    );


    localparam 
        IDLE = 0,
        TRIGGER_ADC = 1,
        WAIT_ADC = 2,
        ACUM = 3,
        SHIFT = 4,
        DONE = 5;

    reg [3:0] state, nextState;
    reg [7:0] count;
    reg [2:0] sample_num;
    reg [NB_DATA-1:0] sample_reg;
    reg [NB_DATA+$clog2(127)-1:0] acum_reg;
    reg [NB_DATA-1:0] avg_reg;

    wire e1, e2, e3, ec;

    // REGISTROS
    always @(posedge clk ) if(i_start) sample_num <= i_nSamples;
    always @(posedge clk ) if(i_start) sample_reg <= 0; else if(e1) sample_reg <= i_sample;
    always @(posedge clk ) if(i_start) acum_reg <= 0;   else if(e2) acum_reg <= acum_reg + sample_reg;
    always @(posedge clk ) if(i_start) avg_reg <= 0;    else if(e3) avg_reg <= (acum_reg >> sample_num);

    always @(posedge clk ) 
        if(i_start) count <= 1<<i_nSamples;
        else if(ec) count <= count - 1;

    // REGISTRO DE ESTADO
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= nextState;
        end
    end


    always @(*) begin
        case (state)
            IDLE: begin
                if(i_start)begin
                    nextState = TRIGGER_ADC;
                end else begin
                    nextState = IDLE;
                end
            end
            TRIGGER_ADC: begin
                nextState = WAIT_ADC;                
            end
            WAIT_ADC: begin
                if(i_adc_done)begin
                    nextState = ACUM;
                end else begin
                    nextState = WAIT_ADC;
                end
            end
            ACUM: begin
                if(count == 0)begin
                    nextState = SHIFT; 
                end else begin
                    nextState = TRIGGER_ADC;
                end
            end
            SHIFT: begin
                nextState = DONE;
            end
            DONE: begin
                nextState = IDLE;
            end
            default: 
                nextState = IDLE;
        endcase
    end

    assign e1 = state == ACUM;
    assign ec = state == ACUM;
    assign e2 = state == ACUM;
    assign e3 = state == SHIFT;
    assign o_adcTrigger = state == TRIGGER_ADC;
    assign o_done = (state == DONE);
    assign o_result = avg_reg;

endmodule
