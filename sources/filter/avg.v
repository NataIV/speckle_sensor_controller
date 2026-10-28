`timescale 1ns / 1ps


module avg #(
    parameter NB_DATA = 12
)(
    input clk,
    input rst,
    input i_start,
    input i_eoc,
    /*
        i_size: [0-7]
        define el numero de muestras
          i_size  |  muestras
            0     |       1
            1     |       4 
            2     |      16
            3     |      64
            4     |     256
            5     |    1024
            6     |    4096
            7     |   16384
    */
    input [2:0] i_size,
    input [NB_DATA-1:0] i_data,
    
    output reg o_done,
    output reg o_trig,
    output [NB_DATA-1:0] o_data
    );


    localparam 
        IDLE = 0,
        SET_SIZE = 1,
        LOAD_COUNT = 2,
        TRIGGER_ADC = 3,
        WAIT_ADC = 4,
        ACUM = 5,
        DEC_CNT = 6,
        SHIFT = 7,
        DONE = 8;

    reg [$clog2(DONE+1):0] state, next;
    reg [$clog2(16384):0] count;
    reg load_count;
    reg [3:0] size;
    reg set_size;
    reg [NB_DATA+$clog2(16384)-1:0] acum_reg;
    reg [NB_DATA-1:0] avg_reg;

    reg e1, e2, ec;

    // REGISTROS
    always @(posedge clk) if(set_size) size <= {i_size, 1'b0}; // Guardo el numero de muestras al empezar
    always @(posedge clk) if(i_start) acum_reg <= 0;   else if(e1) acum_reg <= acum_reg + i_data; // e2 habilita el incremento del contador
    always @(posedge clk) if(i_start) avg_reg <= 0;    else if(e2) avg_reg <= (acum_reg >> size); // e3 calcula el promedio

    always @(posedge clk) 
        if(load_count) count <= 1 << size;
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
            IDLE:           if(i_start)     next = SET_SIZE;
            SET_SIZE:                       next = LOAD_COUNT;
            LOAD_COUNT:                     next = TRIGGER_ADC;
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
        set_size <= 1'b0;
        load_count <= 1'b0;
        e1 <= 1'b0;
        ec <= 1'b0;
        e2 <= 1'b0;
        o_trig <= 1'b0;
        o_done <= 1'b0;
        case (next)
            IDLE:           ;
            SET_SIZE:       set_size <= 1'b1;
            LOAD_COUNT:     load_count <= 1'b1;
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
