`ifndef PROCESS_FSM_H
`define PROCESS_FSM_H

`include "../counter_offset/counter_offset.v"

module process_fsm 
#(/*    PARAMETROS    */
    parameter PIXEL_N_COLS = 24,
    parameter PIXEL_N_ROWS = 24,
    parameter NB_ADC = 12
)
(/*    PUERTOS ENTRADA/SALIDAS     */
    // Control desde la interfaz superior
    input  clk,
    input  rst,
    input  i_start,
    output o_rdy,

    // Control de memoria
//    output [NB_MEM_ADDR - 1 : 0]     o_ram_addr,
    input  [NB_ADC-1 : 0] i_ram_value,
    output                o_ram_write,
    output [NB_ADC-1 : 0] o_ram_value,                            

    
    // contadores de direccionamiento de ram
    input                  i_row_overflow,
    input                  i_col_overflow,
    output reg [4:0]       o_row_control,
    output reg [4:0]       o_col_control
);


    localparam
        IDLE               =  0,
        RESET              =  1,
        LOAD_PIX_1_0       =  2,
        LOAD_PIX_1_1       =  12,
        SAVE_PIX_1         =  22,
        LOAD_PIX_2_0       =  3,
        LOAD_PIX_2_1       =  13,
        SAVE_PIX_2         =  23,  
        SUBS               =  5,
        WRITE_RAM          =  6,
        ROW_INC            =  7,
        ROW_CHK            =  8,
        COL_INC            =  9,
        COL_CHK            = 10,
        NEXT_PIXEL         = 11,
        DONE               = 31;       


    reg [5:0] state;
    reg [5:0] state_next;
    reg [1:0] pixel_cnt;

    reg result_carry;
    reg [NB_ADC-1 : 0] result_reg;
    reg [NB_ADC-1 : 0] pix_1;
    reg [NB_ADC-1 : 0] pix_2;

    reg [4:0] row_control_load_gp_1 [2:0];
    reg [4:0] col_control_load_gp_1 [2:0];
    reg [4:0] row_control_load_gp_2 [2:0];
    reg [4:0] col_control_load_gp_2 [2:0];
    

    // SALIDAS
    assign o_ram_value = (result_carry) ? {NB_ADC{1'b0}} : result_reg;
    assign o_ram_write = (state == WRITE_RAM);
    assign o_rdy = (state == DONE);


    // REGISTROS
    always @(posedge clk) begin
        if(rst)
            state <= IDLE;
        else
            state <= state_next;
    end

    // LOGICA DE ESTADO SIGUIENTE
    always @(*) begin
        case (state)
            IDLE: begin
                if (i_start) begin
                    state_next = RESET;
                end else begin
                    state_next = IDLE;
                end
            end
            RESET: begin
                state_next = LOAD_PIX_1_0;
            end
            LOAD_PIX_1_0: begin
                state_next = LOAD_PIX_1_1;
            end 
            LOAD_PIX_1_1: begin
                state_next = SAVE_PIX_1;
            end 
            SAVE_PIX_1: begin
                state_next = LOAD_PIX_2_0;
            end
            LOAD_PIX_2_0: begin
                state_next = LOAD_PIX_2_1;
            end 
            LOAD_PIX_2_1: begin
                state_next = SAVE_PIX_2;
            end 
            SAVE_PIX_2: begin
                state_next = SUBS;
            end
            SUBS: begin
                state_next = WRITE_RAM;
            end
            WRITE_RAM: begin
                state_next = ROW_INC;
            end
            ROW_INC: begin
                state_next = ROW_CHK;
            end
            ROW_CHK: begin
                if (i_row_overflow) begin
                    state_next = COL_INC;
                end else begin
                    state_next = LOAD_PIX_1_0;
                end
            end
            COL_INC: begin
                state_next = COL_CHK;
            end
            COL_CHK: begin
                if (i_col_overflow) begin
                    state_next = NEXT_PIXEL;
                end else begin
                    state_next = LOAD_PIX_1_0;
                end
            end
            NEXT_PIXEL: begin
                if(pixel_cnt == 2'b10) begin
                    state_next = DONE;
                end else begin
                    state_next = RESET;
                end
            end
            DONE : begin
                state_next = IDLE;
            end
            default: 
                state_next = IDLE;
        endcase    
    end

    /*  Registro temporal donde se almacenan resultados  */
    always @(posedge clk) begin
        if (rst) begin
            pix_1 <= {(NB_ADC+1){1'b0}};
            pix_2 <= {(NB_ADC+1){1'b0}};
            result_reg <= {(NB_ADC+1){1'b0}};
        end else begin
            if ( state == SAVE_PIX_1 ) begin
               pix_1 <= i_ram_value;
            end
            else if (state == SAVE_PIX_1)  begin
               pix_2 <= i_ram_value;
            end 
            else if (state == SUBS) begin
                {result_carry, result_reg} <= pix_1 - pix_2;
            end
        end
    end

    /*    Control del direccionamiento de memoria    */
    always@(posedge clk)begin
        if(rst)begin
            o_row_control = `COUNTER_RESET;
            o_col_control = `COUNTER_RESET;
        end else begin
            case(state_next)
            IDLE           : begin
                o_row_control = `COUNTER_RESET;
                o_col_control = `COUNTER_RESET;
            end
            RESET    : begin
                o_row_control = `COUNTER_RESET;
                o_col_control = `COUNTER_RESET;
            end
            LOAD_PIX_1_0 : begin
                o_row_control = row_control_load_gp_1[pixel_cnt];
                o_col_control = col_control_load_gp_1[pixel_cnt];
            end
            LOAD_PIX_2_0 : begin
                o_row_control = row_control_load_gp_2[pixel_cnt];
                o_col_control = col_control_load_gp_2[pixel_cnt];
            end
            SUBS : begin
                o_row_control = row_control_load_gp_1[pixel_cnt];
                o_col_control = col_control_load_gp_1[pixel_cnt];
            end
            WRITE_RAM : begin
                o_row_control = row_control_load_gp_1[pixel_cnt];
                o_col_control = col_control_load_gp_1[pixel_cnt];
            end
            ROW_INC   : begin
                o_row_control = `COUNTER_ENABLE | `COUNTER_INC_2;
                o_col_control = `COUNTER_NO_CHANGE;
            end
            COL_INC : begin
                o_row_control = `COUNTER_RESET;
                o_col_control = `COUNTER_ENABLE | `COUNTER_INC_2;
            end
            NEXT_PIXEL  : begin
                o_row_control = `COUNTER_RESET;
                o_col_control = `COUNTER_RESET;
            end
            default: begin
                o_row_control = `COUNTER_NO_CHANGE;
                o_col_control = `COUNTER_NO_CHANGE;
            end
            endcase
        end
    end



/*
    ROM con los indices para restar cada grupo de pixeles
    y conseguir el valor de cada pixel individual
    Las restas entre pixeles son:

         . X         . .         X .          
        X X         X X         X .
        -           -           -
         . .         . .         . .
        X X         X .         X .
        ____        ____        ____

         . X         . .         X .
        . .         . X         . .

    El pixel inferior izquierda corresponde un pixel conectado
    a la ARL, por lo que su valor leido ya es el del pixel 
    individual.
    El resto de pixeles es un valor acumulado necesario para
    que acceda a una ARL.

    La FSM encargada de desacumular estos pixeles indexará la 
    ram cada 2 pixeles y cargara los valores necesarios apli-
    cando un offset para seleccionar el valor de cada grupo.
    
    El offset se hace en referencia al pixel inferior derecho.
    Por ejemplo, para acceder al pixel de la ARL, se hace que 
    el valor de la direccion de la RAM sea: [col+1, row],
    es decir, un offset de [1, 0].

    Para cada pixel las operaciones seran:
        RAM[c, r+1]   = RAM[c, r+1]   - RAM[c, r]
        RAM[c, r]     = RAM[c, r]     - RAM[c+1, r]
        RAM[c+1, r+1] = RAM[c+1, r+1] - RAM[c+1, r]

    Para que la FSM no tenga que repetir estados para cada 
    offset, estos se guardaran en una rom, y se incrementara
    cada vez que haya que cambiar entre grupos de pixeles.

*/
 
    initial begin
        row_control_load_gp_1[0] <= `COUNTER_INC_1;
        col_control_load_gp_1[0] <= `COUNTER_NO_CHANGE;

        row_control_load_gp_1[1] <= `COUNTER_NO_CHANGE;
        col_control_load_gp_1[1] <= `COUNTER_NO_CHANGE;

        row_control_load_gp_1[2] <= `COUNTER_INC_1;
        col_control_load_gp_1[2] <= `COUNTER_INC_1;
    end
    
    
    initial begin
        row_control_load_gp_2[0] <= `COUNTER_NO_CHANGE;
        col_control_load_gp_2[0] <= `COUNTER_NO_CHANGE;

        row_control_load_gp_2[1] <= `COUNTER_NO_CHANGE;
        col_control_load_gp_2[1] <= `COUNTER_INC_1;

        row_control_load_gp_2[2] <= `COUNTER_NO_CHANGE;
        col_control_load_gp_2[2] <= `COUNTER_INC_1;
    end

    always @(posedge clk) begin
        if (rst) begin
            pixel_cnt <= 2'b00;
        end else if(state == NEXT_PIXEL) begin
            pixel_cnt <= pixel_cnt + 1;
        end
    end

endmodule

`endif