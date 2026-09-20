`timescale 1ns / 1ps

module avg #(
    parameter NB_DATA = 12
)(
    input clk,
    input rst,
    input i_start,
    input i_eoc,
    input [2:0] i_size,
    input [NB_DATA-1:0] i_data,
    
    output reg o_done,
    output reg o_trig,
    output [NB_DATA-1:0] o_data
    );


    localparam 
        IDLE = 0,
        TRIGGER_ADC = 1,
        WAIT_ADC = 2,
        ACUM = 3,
        DEC_CNT = 4,
        SHIFT = 5,
        DONE = 6;

    reg [3:0] state, next;
    reg [7:0] count;
    reg [2:0] size;
    reg [NB_DATA+$clog2(255)-1:0] acum_reg;
    reg [NB_DATA-1:0] avg_reg;

    reg e1, e2, ec;

    // REGISTROS
    always @(posedge clk) if(i_start) size <= i_size; // Guardo el numero de muestras al empezar
    always @(posedge clk) if(i_start) acum_reg <= 0;   else if(e1) acum_reg <= acum_reg + i_data; // e2 habilita el incremento del contador
    always @(posedge clk) if(i_start) avg_reg <= 0;    else if(e2) avg_reg <= (acum_reg >> size); // e3 calcula el promedio

    always @(posedge clk) 
        if(i_start) count <= 1 << i_size;
        else if(ec) count <= count - 1;

    // REGISTRO DE ESTADO
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next;
        end
    end


    always @(*) begin
        next = state; // Si no se cumple la condicion, vuelvo al mismo estado.
        case (state)
            IDLE:           if(i_start)     next = TRIGGER_ADC;
            TRIGGER_ADC:                    next = WAIT_ADC;
            WAIT_ADC:       if(i_eoc)       next = ACUM;
            ACUM:                           next = DEC_CNT;
            DEC_CNT:        if(count == 1)  next = SHIFT;
                            else            next = TRIGGER_ADC;
            SHIFT:                          next = DONE;
            DONE:                           next = IDLE;
            default:                        next = IDLE;
        endcase
    end


    always @(posedge clk) begin
        e1 <= 1'b0;
        ec <= 1'b0;
        e2 <= 1'b0;
        o_trig <= 1'b0;
        o_done <= 1'b0;
        case (next)
            IDLE:           ;
            TRIGGER_ADC:    o_trig  <= 1'b1;
            WAIT_ADC:       ;
            ACUM:           e1  <= 1'b1;
            DEC_CNT:        ec  <= 1'b1;
            SHIFT:          e2  <= 1'b1;
            DONE:           o_done <= 1'b1;
            default:        ;
        endcase
    end



    assign o_data = avg_reg;

endmodule
