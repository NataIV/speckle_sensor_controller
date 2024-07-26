`ifndef SCAN_FSM_H
`define SCAN_FSM_H
//!    @title SCAN FSM
//!    @file scan_fsm.v
//!    @author Valle Natalio
//!    @details
//!        Maquina de estados que controla el proceso de escaneo de la matriz de pixeles
//!        Divide la matriz de pixeles en grupos de 4 pixeles y realiza 4 escaneos de la
//!        matriz de pixeles con la finalidad de obtener el valor de cada pixel de manera  
//!        independiente. Los grupos de pixeles se activan con una palabra de configuracion
//!        en el registro de desplazamiento de columnas y un 1 en la fila correspondiente 
//!        (fila inferior del grupo de pixeles) y tienen el valor que se detalla a continuacion:
            /* 
                Palabras de configuracion 
            
                1)
            Utilizando la palabra de configuracion 0001100
            Se leera la suma de pixeles:
                 . .        
                X X
            Se debe aplicar un offset de (0,0) al valor la
            direccion de memoria
            
            Utilizando la palabra de configuracion 0001101
            Se leera la suma de pixeles:
                 . X        
                X X   
            Se debe aplicar un offset de (0,1) al valor la
            direccion de memoria
            
            
            Utilizando la palabra de configuracion 0001000
            Se leera la suma de pixeles:
                 . .        
                X .
            Se debe aplicar un offset de (1,0) al valor la
            direccion de memoria

            Utilizando la palabra de configuracion 0011000
            Se leera la suma de pixeles:
                 X .        
                X .
            Se debe aplicar un offset de (1,1) al valor la
            direccion de memoria
            
            */
//! 

`include "cfg_word_sr.v"
`include "../counter_offset/counter_offset.v"

module scan_fsm
#(/*    PARAMETROS    */
    parameter PIXEL_N_COLS = 24,
    parameter PIXEL_N_ROWS = 24,
    parameter NB_ADC = 12
)
(/*    PUERTOS ENTRADA/SALIDAS     */
    // Control desde la interfaz superior
    input clk,
    input i_rst,
    input i_start_scan,
    output o_scan_ready,

    // Control de memoria
//    output [NB_MEM_ADDR - 1 : 0]     o_ram_addr,
    output                           o_ram_write,

    // ADC
    output o_adc_trig,
    input  i_adc_done,
    
    // contadores de direccionamiento de ram
    input                  i_row_overflow,
    input                  i_col_overflow,
    output reg [4:0]       o_row_control,
    output reg [4:0]       o_col_control,

    input  i_row_rdy,
    input  i_col_rdy,
    input  i_key_rdy,
    
    // al chip
    output o_row_reg_data,
    output o_row_reg_write,

    output [6:0] o_col_reg_data,
    output o_col_reg_write,

    output o_key_write

);

/*    DECLARACION DE SENIALES INTERNAS   */
    localparam MEM_DEPTH   = PIXEL_N_ROWS * PIXEL_N_COLS;
    localparam NB_MEM_ADDR = $clog2(MEM_DEPTH);
    localparam ROW_CNT_MAX = PIXEL_N_ROWS / 2 - 1;
    localparam COL_CNT_MAX = PIXEL_N_COLS / 2 - 1;
    localparam CFG_CNT_MAX = 3;

    // reg [$clog2(ROW_CNT_MAX)-1:0] row_cnt; 
    // reg [$clog2(COL_CNT_MAX)-1:0] col_cnt;
    reg [$clog2(CFG_CNT_MAX)-1:0] cfg_cnt;


    //ROM de palabras de configuracion
    reg [6:0] cfg_word [3:0]; 
    initial begin
        cfg_word[2'b00] = 7'b0001100;
        cfg_word[2'b01] = 7'b0001101;
        cfg_word[2'b10] = 7'b0001000;
        cfg_word[2'b11] = 7'b0011000;
    end

/* FSM */
    /*    DECLARACION DE ESTADOS    */

    reg [4:0] state;
    reg [4:0] state_next;

    localparam
        STATE_IDLE                    = 0,      // Espera que se inicie el scan
        STATE_COL_WRITE_CFG_WORD      = 1,      // Escribe la palabra de configuracion al sr de columnas
        STATE_COL_WAIT_CFG_WORD       = 2,      // Espera a que termine la escritura
        STATE_ROW_WRITE_1             = 3,      // Escribe un 1 en el sr de filas
        STATE_PIXELS_WRITE            = 5,      // Habilita escritura de pixeles    
        STATE_ADC_TRIGGER             = 6,      // Inicia la lectura del ADC
        STATE_ADC_WAIT                = 7,      // Espera a que termine el ADC (Capaz se puede remover con clock gatting)
        STATE_RAM_WRITE               = 8,      // Escribe en la memoria RAM
        STATE_ROW_WRITE_0_0           = 9,      // Desplaza el registro de filas (escribir 0 en el sr de filas)
        STATE_ROW_WRITE_0_1           = 10,     // Desplaza el registro de filas (escribir 0 en el sr de filas)
        STATE_COL_WRITE_0000000       = 11,     // Desplaza la palabra de configuracion
        STATE_COL_NEXT_CFG_WORD       = 12,     // Carga la siguiente palabra de configuracion
        STATE_RAM_COL_INC             = 13,
        STATE_RAM_ROW_INC             = 14,
        STATE_ROW_WRITE_1_WAIT        = 15,
        STATE_PIXELS_WRITE_WAIT       = 16,
        STATE_ROW_WRITE_0_0_WAIT      = 17,
        STATE_ROW_WRITE_0_1_WAIT      = 18,
        STATE_COL_WRITE_0000000_WAIT  = 19,
        STATE_CHECK_NEXT              = 20,
        STATE_CLEAN_COL_REG           = 21,
        STATE_CLEAN_COL_REG_WAIT      = 22,
        STATE_CLEAN_PIXELS            = 23,
        STATE_CLEAN_PIXELS_WAIT       = 24,
        STATE_DONE                    = 25;
        

    /*    MEMORIA    */
    always @(posedge clk) begin
        if(i_rst)
            state <= STATE_IDLE;
        else
            state <= state_next;
    end

    /*    LOGICA DE ESTADO SIGUIENTE    */
    always @(*) begin
        case(state) 
        STATE_IDLE : begin 
            // Espero la señal de inicio
            if(i_start_scan)    state_next = STATE_COL_WRITE_CFG_WORD;
            else                state_next = STATE_IDLE;
        end
        STATE_COL_WRITE_CFG_WORD : begin
            // Escribo la palabra de configuracion
                                state_next = STATE_COL_WAIT_CFG_WORD;
        end
        STATE_COL_WAIT_CFG_WORD  : begin
            // Espero a que el registro de desplazamiento termine de escribir la palabra de configuracion
            if(i_col_rdy)       state_next = STATE_ROW_WRITE_1;
            else                state_next = STATE_COL_WAIT_CFG_WORD;
        end
        STATE_ROW_WRITE_1       : begin
            // Escribo el primer 1 al registro de filas del chip fotodetector
            state_next =  STATE_ROW_WRITE_1_WAIT;
        end
        STATE_ROW_WRITE_1_WAIT  : begin
            if(i_row_rdy)       state_next = STATE_PIXELS_WRITE;
            else                state_next = STATE_ROW_WRITE_1_WAIT;
        end
        STATE_PIXELS_WRITE      : begin
            // Escribo las llaves del array de pixeles
            state_next = STATE_PIXELS_WRITE_WAIT;
        end
        STATE_PIXELS_WRITE_WAIT : begin
            // Espero a que finalice la escritura de pixeles
            if(i_key_rdy)       state_next = STATE_ADC_TRIGGER;
            else                state_next = STATE_PIXELS_WRITE_WAIT;
        end
        STATE_ADC_TRIGGER       : begin
            // Inicio la conversion AD
            state_next = STATE_ADC_WAIT;
        end
        STATE_ADC_WAIT          : begin
            // Espero a que la conversion AD termine
            if(i_adc_done)      state_next = STATE_RAM_WRITE;
            else                state_next = STATE_ADC_WAIT;
        end
        STATE_RAM_WRITE      : begin
            // Escribo el valor en la memoria RAM
            state_next = STATE_ROW_WRITE_0_0;
        end
        STATE_ROW_WRITE_0_0   : begin
            // desplazo el 1 en el registro de filas
            state_next = STATE_ROW_WRITE_0_0_WAIT;
        end
        STATE_ROW_WRITE_0_0_WAIT: begin
            if(i_row_rdy) state_next = STATE_ROW_WRITE_0_1;
            else          state_next = STATE_ROW_WRITE_0_0_WAIT;
        end
        STATE_ROW_WRITE_0_1   : begin
            // desplazo el 1 en el registro de filas
            state_next = STATE_ROW_WRITE_0_1_WAIT;
        end
        STATE_ROW_WRITE_0_1_WAIT: begin 
            if(i_row_rdy)   state_next = STATE_RAM_ROW_INC;
            else            state_next = STATE_ROW_WRITE_0_1_WAIT;
        end
        STATE_RAM_ROW_INC : begin
            if(i_row_overflow)  state_next = STATE_CLEAN_PIXELS;
            else                state_next = STATE_PIXELS_WRITE;
        end
        STATE_CLEAN_PIXELS: begin
            state_next = STATE_CLEAN_PIXELS_WAIT;
        end
        STATE_CLEAN_PIXELS_WAIT: begin
            if(i_key_rdy) state_next = STATE_RAM_COL_INC;
            else          state_next = STATE_CLEAN_PIXELS_WAIT; 
        end
        STATE_RAM_COL_INC : begin
            if(i_col_overflow)   state_next = STATE_COL_NEXT_CFG_WORD;
            else                 state_next = STATE_COL_WRITE_0000000;
        end
        STATE_COL_WRITE_0000000  : begin
            state_next = STATE_COL_WRITE_0000000_WAIT;
        end
        STATE_COL_WRITE_0000000_WAIT  : begin
            if(i_col_rdy) state_next = STATE_ROW_WRITE_1;
            else          state_next = STATE_COL_WRITE_0000000_WAIT;
        end
        STATE_COL_NEXT_CFG_WORD  : begin 
            if(cfg_cnt < CFG_CNT_MAX) state_next = STATE_COL_WRITE_CFG_WORD;
            else state_next = STATE_CLEAN_COL_REG;
        end
        STATE_CLEAN_COL_REG: begin
            state_next = STATE_CLEAN_COL_REG_WAIT;
        end
        STATE_CLEAN_COL_REG_WAIT: begin
            if(i_col_rdy) state_next = STATE_DONE;
            else          state_next = STATE_CLEAN_COL_REG_WAIT;
        end 
        STATE_DONE : begin
            state_next = STATE_IDLE;
        end
        default : begin
            state_next = STATE_IDLE;
        end
        endcase
    end


    // Contador de palabra de configuracion
    always@(posedge clk)begin
        if(state==STATE_IDLE)
            cfg_cnt <= 2'b00;
        else if(state == STATE_COL_NEXT_CFG_WORD)
            cfg_cnt = cfg_cnt + 1;
    end

    // Offset para el guardado en memoria
    reg [4:0] offset_col;
    reg [4:0] offset_row;
    always @(*) begin
        case(cfg_cnt)
        2'b00:begin
            offset_row = `COUNTER_NO_CHANGE;
            offset_col = `COUNTER_NO_CHANGE;
        end
        2'b01:begin
            offset_row = `COUNTER_INC_1;
            offset_col = `COUNTER_NO_CHANGE;
        end 
        2'b10:begin
            offset_row = `COUNTER_NO_CHANGE;
            offset_col = `COUNTER_INC_1;
        end 
        2'b11:begin
            offset_row = `COUNTER_INC_1;
            offset_col = `COUNTER_INC_1;
        end 
        endcase
    end


    /*    Control del direccionamiento de memoria    */
    always@(posedge clk)begin
        if (i_rst)begin
            o_row_control = `COUNTER_RESET;
            o_col_control = `COUNTER_RESET;
        end else begin
            case(state_next)
            STATE_IDLE           : begin
                o_row_control = `COUNTER_RESET;
                o_col_control = `COUNTER_RESET;
            end
            STATE_RAM_ROW_INC   : begin
                o_row_control = `COUNTER_ENABLE | `COUNTER_INC_2;
                o_col_control = `COUNTER_NO_CHANGE;
            end
            STATE_RAM_COL_INC : begin
                o_row_control = `COUNTER_RESET;
                o_col_control = `COUNTER_ENABLE | `COUNTER_INC_2;
            end
            STATE_RAM_WRITE   : begin
                o_row_control = offset_row;
                o_col_control = offset_col;
            end
            STATE_COL_NEXT_CFG_WORD  : begin
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


/*    LOGICA DE SALIDA    */
    assign o_col_reg_write = (state == STATE_COL_WRITE_CFG_WORD) || (state == STATE_COL_WRITE_0000000) || (state == STATE_CLEAN_COL_REG);
    assign o_col_reg_data  = (state == STATE_COL_WRITE_CFG_WORD) ? cfg_word[cfg_cnt] : 7'b0000000;
    assign o_row_reg_data  = (state == STATE_ROW_WRITE_1);
    assign o_row_reg_write = (state == STATE_ROW_WRITE_1) || (state == STATE_ROW_WRITE_0_0) || (state == STATE_ROW_WRITE_0_1);
    assign o_key_write     = (state == STATE_PIXELS_WRITE) || (state == STATE_CLEAN_PIXELS);
    assign o_ram_write     = (state == STATE_RAM_WRITE);
    assign o_adc_trig      = (state == STATE_ADC_TRIGGER);
    assign o_scan_ready    = (state == STATE_DONE);

    
endmodule

`endif /* SCAN_FSM_H */