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

//`define INCREMENTAL_SCAN

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

    output o_row_ena,
    output o_row_rst,
    output o_col_rst,
    output o_key_write

);

/*    DECLARACION DE SENIALES INTERNAS   */
    localparam MEM_DEPTH   = PIXEL_N_ROWS * PIXEL_N_COLS;
    localparam NB_MEM_ADDR = $clog2(MEM_DEPTH);
    localparam ROW_CNT_MAX = PIXEL_N_ROWS / 2 - 1;
    localparam COL_CNT_MAX = PIXEL_N_COLS / 2 - 1;
    localparam CFG_CNT_MAX = 3;

    reg [$clog2(PIXEL_N_ROWS)-1:0] row; 
    reg [$clog2(PIXEL_N_COLS)-1:0] col;
    reg [$clog2(CFG_CNT_MAX)-1:0] cfg_cnt;

    //ROM de palabras de configuracion
    reg [6:0] cfg_word [3:0]; 
    initial begin
        cfg_word[2'b00] = 7'b0001000;
        cfg_word[2'b01] = 7'b0001100;
        cfg_word[2'b10] = 7'b0011100;
        cfg_word[2'b11] = 7'b0011101;
    end

/* FSM */
    /*    DECLARACION DE ESTADOS    */

    reg [8:0] state;
    reg [8:0] next;

    localparam
        IDLE              = 0,      // Espera que se inicie el scan
        COL_WR_CFG_WORD   = 1,      // Escribe la palabra de configuracion al sr de columnas
        COL_WAIT_CFG_WORD = 2,      // Espera a que termine la escritura
        ROW_WR_1          = 3,      // Escribe un 1 en el sr de filas
        ROW_WR_1_WAIT     = 4,
        PIX_WR            = 5,      // Habilita escritura de pixeles    
        PIX_WR_WAIT       = 6,
        ADC_TRIGGER       = 7,      // Inicia la lectura del ADC
        ADC_WAIT          = 8,      // Espera a que termine el ADC (Capaz se puede remover con clock gatting)
        RAM_WR            = 9,      // Escribe en la memoria RAM
        ROW_WR_0_0        = 10,      // Desplaza el registro de filas (escribir 0 en el sr de filas)
        ROW_WR_0_1        = 11,     // Desplaza el registro de filas (escribir 0 en el sr de filas)
        COL_WR_ZERO       = 12,     // Desplaza la palabra de configuracion
        COL_NEXT_CFG_WORD = 13,     // Carga la siguiente palabra de configuracion
        COL_INC           = 14,
        ROW_INC           = 17,
        ROW_WR_0_0_WAIT   = 18,
        ROW_WR_0_1_WAIT   = 19,
        COL_WR_ZERO_WAIT  = 20,
        CHK_NEXT          = 21,
        CLR_COL_REG       = 22,
        CLR_COL_REG_WAIT  = 23,
        CLR_PIXELS        = 24,
        CLR_PIX_WAIT      = 25,
        ROW_RST           = 26,
        ROW_RST_WAIT      = 27,
        ROW_RST_0         = 28,
        ROW_RST_WAIT_0    = 29,
        DONE              = 30;
        

    /*    MEMORIA    */
    always @(posedge clk) begin
        if(i_rst)
            state <= IDLE;
        else
            state <= next;
    end

    /*    LOGICA DE ESTADO SIGUIENTE    */
    always @(*) begin
        next = state;
        case(state) 
        // Espero la señal de inicio
        IDLE :             if(i_start_scan)             next = COL_WR_CFG_WORD;
        // Escribo la palabra de configuracion
        COL_WR_CFG_WORD :                               next = COL_WAIT_CFG_WORD;
        // Espero a que el registro de desplazamiento termine de escribir la palabra de configuracion
        COL_WAIT_CFG_WORD: if(i_col_rdy)                next = ROW_WR_1;
        // Escribo el primer 1 al registro de filas del chip fotodetector
        ROW_WR_1:                                       next = ROW_WR_1_WAIT;
        ROW_WR_1_WAIT:     if(i_row_rdy)                next = PIX_WR;
        // Escribo las llaves del array de pixeles
        PIX_WR      :                                   next = PIX_WR_WAIT;
        // Espero a que finalice la escritura de pixeles
        PIX_WR_WAIT :      if(i_key_rdy)                next = ADC_TRIGGER;
        // Inicio la conversion AD
        ADC_TRIGGER:                                    next = ADC_WAIT;
        // Espero a que la conversion AD termine
        ADC_WAIT   :       if(i_adc_done)               next = RAM_WR;
        // Escribo el valor en la memoria RAM
        RAM_WR      :                                   next = ROW_WR_0_0;
        // desplazo el 1 en el registro de filas
        ROW_WR_0_0   :                                  next = ROW_WR_0_0_WAIT;
        ROW_WR_0_0_WAIT:   if(i_row_rdy)                next = ROW_WR_0_1;
        // desplazo el 1 en el registro de filas
        ROW_WR_0_1   :                                  next = ROW_WR_0_1_WAIT;
        ROW_WR_0_1_WAIT:   if(i_row_rdy)                next = ROW_INC;
        ROW_INC :          if(i_row_overflow)           next = CLR_PIXELS;
                           else                         next = PIX_WR;
        CLR_PIXELS:                                     next = CLR_PIX_WAIT;
        CLR_PIX_WAIT:      if(i_key_rdy)                next = ROW_RST;
        ROW_RST:                                        next = ROW_RST_WAIT;
        ROW_RST_WAIT:      if(i_row_rdy)                next = COL_INC;
        COL_INC :          if(i_col_overflow)           next = COL_NEXT_CFG_WORD;
                           else                         next = COL_WR_ZERO;
        COL_WR_ZERO  :                                  next = COL_WR_ZERO_WAIT;
        COL_WR_ZERO_WAIT:  if(i_col_rdy)                next = ROW_WR_1;
        COL_NEXT_CFG_WORD: if(cfg_cnt < CFG_CNT_MAX)    next = COL_WR_CFG_WORD;
                           else                         next = CLR_COL_REG;
        CLR_COL_REG:                                    next = CLR_COL_REG_WAIT;
        CLR_COL_REG_WAIT:  if(i_col_rdy)                next = DONE;
        DONE :                                          next = IDLE;
        default :                                       next = IDLE;
        endcase
    end


    // Contador de palabra de configuracion
    always@(posedge clk)begin
        if(state==IDLE)
            cfg_cnt <= 2'b00;
        else if(state == COL_NEXT_CFG_WORD)
            cfg_cnt = cfg_cnt + 1;
    end

    // Offset para el guardado en memoria
    reg [4:0] offset_col;
    reg [4:0] offset_row;
    always @(*) begin
        case(cfg_cnt)
        2'b00:begin
            offset_row = `COUNTER_NO_CHANGE;
            offset_col = `COUNTER_INC_1;
        end 
        2'b01:begin
            offset_row = `COUNTER_NO_CHANGE;
            offset_col = `COUNTER_NO_CHANGE;
        end
        2'b10:begin
            offset_row = `COUNTER_INC_1;
            offset_col = `COUNTER_INC_1;
        end 
        2'b11:begin
            offset_row = `COUNTER_INC_1;
            offset_col = `COUNTER_NO_CHANGE;
        end 
        endcase
    end


    /*    Control del direccionamiento de memoria    */
    always@(posedge clk)begin
        if (i_rst)begin
            o_row_control = `COUNTER_RESET;
            o_col_control = `COUNTER_RESET;
        end else begin
            case(next)
            IDLE           : begin
                o_row_control = `COUNTER_RESET;
                o_col_control = `COUNTER_RESET;
            end
            ROW_INC   : begin
                o_row_control = `COUNTER_ENABLE | `COUNTER_INC_2;
                o_col_control = `COUNTER_NO_CHANGE;
            end
            COL_INC : begin
                o_row_control = `COUNTER_RESET;
                o_col_control = `COUNTER_ENABLE | `COUNTER_INC_2;
            end
            RAM_WR   : begin
                o_row_control = offset_row;
                o_col_control = offset_col;
            end
            COL_NEXT_CFG_WORD  : begin
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

        // Offset para el guardado en memoria
    reg row_offset;
    reg col_offset;
    always @(*) begin
        case(cfg_cnt)
        2'b00:begin
            row_offset = 1'b0;
            col_offset = 1'b1;
        end 
        2'b01:begin
            row_offset = 1'b0;
            col_offset = 1'b0;
        end
        2'b10:begin
            row_offset = 1'b1;
            col_offset = 1'b1;
        end 
        2'b11:begin
            row_offset = 1'b1;
            col_offset = 1'b0;
        end 
        endcase
    end

    always @(posedge clk ) begin
        case (next)
        IDLE : begin
            row = 0;
            col = 0;
        end
        ROW_INC : begin
            row = row + 2'b10;
        end
        COL_INC : begin
            row = 0;
            col = col + 2'b10;
        end
        RAM_WR : begin
            row = row + row_offset;
            col = col + col_offset;
        end
        COL_NEXT_CFG_WORD : begin
            row = 0;
            col = 0;
        end
        default: begin
        end
        endcase
    end


/*    LOGICA DE SALIDA    */
    assign o_col_reg_write = (state == COL_WR_CFG_WORD) || (state == COL_WR_ZERO) || (state == CLR_COL_REG);
    assign o_col_reg_data  = (state == COL_WR_CFG_WORD) ? cfg_word[cfg_cnt] : 7'b0000000;
    assign o_row_reg_write = (state == ROW_WR_1) || (state == ROW_WR_0_0) || (state == ROW_WR_0_1);
    assign o_key_write     = (state == PIX_WR) || (state == CLR_PIXELS);
    assign o_row_rst       = (state == ROW_RST) || (state == ROW_RST_0);
    assign o_ram_write     = (state == RAM_WR);
    assign o_adc_trig      = (state == ADC_TRIGGER);
    assign o_scan_ready    = (state == DONE);
    assign o_col_rst       = (state == COL_WR_CFG_WORD);
    assign o_row_ena       = (state != IDLE);

`ifdef INCREMENTAL_SCAN
    assign o_row_reg_data  = (state == ROW_WR_1) || (state == ROW_WR_0_1); // Para encender de manera incremental
`else
    assign o_row_reg_data  = (state == ROW_WR_1);
`endif
    
endmodule

`endif /* SCAN_FSM_H */


// `ifndef SCAN_FSM_H
// `define SCAN_FSM_H
// //!    @title SCAN FSM
// //!    @file scan_fsm.v
// //!    @author Valle Natalio
// //!    @details
// //!        Maquina de estados que controla el proceso de escaneo de la matriz de pixeles
// //!        Divide la matriz de pixeles en grupos de 4 pixeles y realiza 4 escaneos de la
// //!        matriz de pixeles con la finalidad de obtener el valor de cada pixel de manera  
// //!        independiente. Los grupos de pixeles se activan con una palabra de configuracion
// //!        en el registro de desplazamiento de columnas y un 1 en la fila correspondiente 
// //!        (fila inferior del grupo de pixeles) y tienen el valor que se detalla a continuacion:
//             /* 
//                 Palabras de configuracion 
            
//                 1)
//             Utilizando la palabra de configuracion 0001100
//             Se leera la suma de pixeles:
//                  . .        
//                 X X
//             Se debe aplicar un offset de (0,0) al valor la
//             direccion de memoria
            
//             Utilizando la palabra de configuracion 0001101
//             Se leera la suma de pixeles:
//                  . X        
//                 X X   
//             Se debe aplicar un offset de (0,1) al valor la
//             direccion de memoria
            
            
//             Utilizando la palabra de configuracion 0001000
//             Se leera la suma de pixeles:
//                  . .        
//                 X .
//             Se debe aplicar un offset de (1,0) al valor la
//             direccion de memoria

//             Utilizando la palabra de configuracion 0011000
//             Se leera la suma de pixeles:
//                  X .        
//                 X .
//             Se debe aplicar un offset de (1,1) al valor la
//             direccion de memoria
            
//             */
// //! 

// //`define INCREMENTAL_SCAN

// `include "cfg_word_sr.v"
// `include "../counter_offset/counter_offset.v"

// module scan_fsm
// #(/*    PARAMETROS    */
//     parameter PIXEL_N_COLS = 24,
//     parameter PIXEL_N_ROWS = 24,
//     parameter NB_ADC = 12
// )
// (/*    PUERTOS ENTRADA/SALIDAS     */
//     // Control desde la interfaz superior
//     input clk,
//     input i_rst,
//     input i_start_scan,
//     output o_scan_ready,

//     // Control de memoria
// //    output [NB_MEM_ADDR - 1 : 0]     o_ram_addr,
//     output                           o_ram_write,

//     // ADC
//     output o_adc_trig,
//     input  i_adc_done,
    
//     // contadores de direccionamiento de ram
//     input                  i_row_overflow,
//     input                  i_col_overflow,
//     output reg [4:0]       o_row_control,
//     output reg [4:0]       o_col_control,

//     input  i_row_rdy,
//     input  i_col_rdy,
//     input  i_key_rdy,
    
//     // al chip
//     output o_row_reg_data,
//     output o_row_reg_write,

//     output [6:0] o_col_reg_data,
//     output o_col_reg_write,

//     output o_key_write,

//     output o_row_rst

// );

// /*    DECLARACION DE SENIALES INTERNAS   */
//     localparam MEM_DEPTH   = PIXEL_N_ROWS * PIXEL_N_COLS;
//     localparam NB_MEM_ADDR = $clog2(MEM_DEPTH);
//     localparam ROW_CNT_MAX = PIXEL_N_ROWS / 2 - 1;
//     localparam COL_CNT_MAX = PIXEL_N_COLS / 2 - 1;
//     localparam CFG_CNT_MAX = 3;

//     // reg [$clog2(ROW_CNT_MAX)-1:0] row_cnt; 
//     // reg [$clog2(COL_CNT_MAX)-1:0] col_cnt;
//     reg [$clog2(CFG_CNT_MAX)-1:0] cfg_cnt;


//     //ROM de palabras de configuracion
//     reg [6:0] cfg_word [3:0]; 
//     initial begin
//         cfg_word[2'b00] = 7'b0001000;
//         cfg_word[2'b01] = 7'b0001100;
//         cfg_word[2'b10] = 7'b0011100;
//         cfg_word[2'b11] = 7'b0011101;
//     end

// /* FSM */
//     /*    DECLARACION DE ESTADOS    */

//     reg [4:0] state;
//     reg [4:0] next;

//     localparam
//         IDLE              = 0,      // Espera que se inicie el scan
//         COL_WR_CFG_WORD   = 1,      // Escribe la palabra de configuracion al sr de columnas
//         COL_WAIT_CFG_WORD = 2,      // Espera a que termine la escritura
//         ROW_WR_1          = 3,      // Escribe un 1 en el sr de filas
//         ROW_WR_1_WAIT     = 4,
//         PIX_WR            = 5,      // Habilita escritura de pixeles    
//         PIX_WR_WAIT       = 6,
//         ADC_TRIGGER       = 7,      // Inicia la lectura del ADC
//         ADC_WAIT          = 8,      // Espera a que termine el ADC (Capaz se puede remover con clock gatting)
//         RAM_WR            = 9,      // Escribe en la memoria RAM
//         ROW_WR_0_0        = 10,      // Desplaza el registro de filas (escribir 0 en el sr de filas)
//         ROW_WR_0_1        = 11,     // Desplaza el registro de filas (escribir 0 en el sr de filas)
//         COL_WR_ZERO       = 12,     // Desplaza la palabra de configuracion
//         COL_NEXT_CFG_WORD = 13,     // Carga la siguiente palabra de configuracion
//         COL_INC           = 14,
//         ROW_INC           = 17,
//         ROW_WR_0_0_WAIT   = 18,
//         ROW_WR_0_1_WAIT   = 19,
//         COL_WR_ZERO_WAIT  = 10,
//         CHK_NEXT          = 21,
//         CLR_COL_REG       = 22,
//         CLR_COL_REG_WAIT  = 23,
//         CLR_PIXELS        = 24,
//         CLR_PIX_WAIT      = 25,
//         ROW_RST           = 26,
//         ROW_RST_WAIT      = 27,
//         ROW_RST_0         = 28,
//         ROW_RST_WAIT_0    = 29,
//         DONE              = 30;
        

//     /*    MEMORIA    */
//     always @(posedge clk) begin
//         if(i_rst)
//             state <= IDLE;
//         else
//             state <= next;
//     end

//     /*    LOGICA DE ESTADO SIGUIENTE    */
//     always @(*) begin
//         next = state;
//         case(state) 
//         // Espero la señal de inicio
//         IDLE :             if(i_start_scan)             next = COL_WR_CFG_WORD;
//         // Escribo la palabra de configuracion
//         COL_WR_CFG_WORD :                               next = COL_WAIT_CFG_WORD;
//         // Espero a que el registro de desplazamiento termine de escribir la palabra de configuracion
//         COL_WAIT_CFG_WORD: if(i_col_rdy)                next = ROW_WR_1;
//         // Escribo el primer 1 al registro de filas del chip fotodetector
//         ROW_WR_1:                                       next = ROW_WR_1_WAIT;
//         ROW_WR_1_WAIT:     if(i_row_rdy)                next = PIX_WR;
//         // Escribo las llaves del array de pixeles
//         PIX_WR      :                                   next = PIX_WR_WAIT;
//         // Espero a que finalice la escritura de pixeles
//         PIX_WR_WAIT :      if(i_key_rdy)                next = ADC_TRIGGER;
//         // Inicio la conversion AD
//         ADC_TRIGGER:                                    next = ADC_WAIT;
//         // Espero a que la conversion AD termine
//         ADC_WAIT   :       if(i_adc_done)               next = RAM_WR;
//         // Escribo el valor en la memoria RAM
//         RAM_WR      :                                   next = ROW_WR_0_0;
//         // desplazo el 1 en el registro de filas
//         ROW_WR_0_0   :                                  next = ROW_WR_0_0_WAIT;
//         ROW_WR_0_0_WAIT:   if(i_row_rdy)                next = ROW_WR_0_1;
//         // desplazo el 1 en el registro de filas
//         ROW_WR_0_1   :                                  next = ROW_WR_0_1_WAIT;
//         ROW_WR_0_1_WAIT:   if(i_row_rdy)                next = ROW_INC;
//         ROW_INC :          if(i_row_overflow)           next = CLR_PIXELS;
//                            else                         next = PIX_WR;
//         CLR_PIXELS:                                     next = CLR_PIX_WAIT;
//         CLR_PIX_WAIT:      if(i_key_rdy)                next = ROW_RST;
//         ROW_RST:                                        next = ROW_RST_WAIT;
//         ROW_RST_WAIT:      if(i_row_rdy)                next = COL_INC;
//         COL_INC :          if(i_col_overflow)           next = COL_NEXT_CFG_WORD;
//                            else                         next = COL_WR_ZERO;
//         COL_WR_ZERO  :                                  next = COL_WR_ZERO_WAIT;
//         COL_WR_ZERO_WAIT:  if(i_col_rdy)                next = ROW_WR_1;
//         COL_NEXT_CFG_WORD: if(cfg_cnt < CFG_CNT_MAX)    next = COL_WR_CFG_WORD;
//                            else                         next = CLR_COL_REG;
//         CLR_COL_REG:                                    next = CLR_COL_REG_WAIT;
//         CLR_COL_REG_WAIT:  if(i_col_rdy)                next = DONE;
//         DONE :                                          next = IDLE;
//         default :                                       next = IDLE;
//         endcase
//     end


//     // Contador de palabra de configuracion
//     always@(posedge clk)begin
//         if(state==IDLE)
//             cfg_cnt <= 2'b00;
//         else if(state == COL_NEXT_CFG_WORD)
//             cfg_cnt = cfg_cnt + 1;
//     end

//     // Offset para el guardado en memoria
//     reg [4:0] offset_col;
//     reg [4:0] offset_row;
//     always @(*) begin
//         case(cfg_cnt)
//         2'b00:begin
//             offset_row = `COUNTER_NO_CHANGE;
//             offset_col = `COUNTER_INC_1;
//         end 
//         2'b01:begin
//             offset_row = `COUNTER_NO_CHANGE;
//             offset_col = `COUNTER_NO_CHANGE;
//         end
//         2'b10:begin
//             offset_row = `COUNTER_INC_1;
//             offset_col = `COUNTER_INC_1;
//         end 
//         2'b11:begin
//             offset_row = `COUNTER_INC_1;
//             offset_col = `COUNTER_NO_CHANGE;
//         end 
//         endcase
//     end


//     /*    Control del direccionamiento de memoria    */
//     always@(posedge clk)begin
//         if (i_rst)begin
//             o_row_control = `COUNTER_RESET;
//             o_col_control = `COUNTER_RESET;
//         end else begin
//             case(next)
//             IDLE           : begin
//                 o_row_control = `COUNTER_RESET;
//                 o_col_control = `COUNTER_RESET;
//             end
//             ROW_INC   : begin
//                 o_row_control = `COUNTER_ENABLE | `COUNTER_INC_2;
//                 o_col_control = `COUNTER_NO_CHANGE;
//             end
//             COL_INC : begin
//                 o_row_control = `COUNTER_RESET;
//                 o_col_control = `COUNTER_ENABLE | `COUNTER_INC_2;
//             end
//             RAM_WR   : begin
//                 o_row_control = offset_row;
//                 o_col_control = offset_col;
//             end
//             COL_NEXT_CFG_WORD  : begin
//                 o_row_control = `COUNTER_RESET;
//                 o_col_control = `COUNTER_RESET;
//             end
//             default: begin
//                 o_row_control = `COUNTER_NO_CHANGE;
//                 o_col_control = `COUNTER_NO_CHANGE;
//             end
//             endcase
//         end
//     end


// /*    LOGICA DE SALIDA    */
//     assign o_col_reg_write = (state == COL_WR_CFG_WORD) || (state == COL_WR_ZERO) || (state == CLR_COL_REG);
//     assign o_col_reg_data  = (state == COL_WR_CFG_WORD) ? cfg_word[cfg_cnt] : 7'b0000000;
//     assign o_row_reg_write = (state == ROW_WR_1) || (state == ROW_WR_0_0) || (state == ROW_WR_0_1);
//     assign o_key_write     = (state == PIX_WR) || (state == CLR_PIXELS);
//     assign o_row_rst       = (state == ROW_RST) || (state == ROW_RST_0);
//     assign o_ram_write     = (state == RAM_WR);
//     assign o_adc_trig      = (state == ADC_TRIGGER);
//     assign o_scan_ready    = (state == DONE);

// `ifdef INCREMENTAL_SCAN
//     assign o_row_reg_data  = (state == ROW_WR_1) || (state == ROW_WR_0_1); // Para encender de manera incremental
// `else
//     assign o_row_reg_data  = (state == ROW_WR_1);
// `endif
    
// endmodule

// `endif /* SCAN_FSM_H */