`ifndef CHIP_DRIVER_H
`define CHIP_DRIVER_H
`timescale 1ns / 1ps

//!    @title Synchronous Write
//!    @file sync_write.v
//!    @author Valle Natalio
//!    
//!         Este módulo genera una escritura sincronica
//!         disparada por un flanco de i_write
//!         a una velocidad de reloj OUT_FREQ. 
//!
//!         El dato de entrada i_data se almacena internamente cuando se recibe la señal de escritura.
//!
//!         La salida o_ready indica si este modulo esta inactivo, un intento de escritura
//!         cuando el modulo esta activo no tiene ningun efecto.


`include "inc/clock_divider.v"
`include "inc/sync_write.v"



module chip_driver
#(
    parameter NB_DIVIDER = 24
)
(
    input                    clk,
    input                    rst,
    input                    i_write_key,
    input                    i_write_col,
    input                    i_write_row,
    input                    i_data_col,
    input                    i_data_row,
    input                    i_rst_row,

    input [NB_DIVIDER-1 : 0] i_clk_div_sr,
    input [NB_DIVIDER-1 : 0] i_clk_div_key,

    output                   o_clk_col,
    output                   o_clk_row,
    output                   o_data_col,
    output                   o_data_row,
    output                   o_write_key,
    output                   o_rst_row,
    output                   o_rdy,

    output                   o_sync
);

    localparam
        IDLE      = 3'b000,
        WRITE_COL = 3'b001,
        WRITE_ROW = 3'b010,
        WRITE_KEY = 3'b011,
        ROW_RST   = 3'b100;


    wire sync_sr_rst, sync_sr;
    wire sync_key_rst, sync_key;
    wire col_wr, row_wr, key_wr, row_rst;
    wire col_rdy, row_rdy, key_rdy, row_rst_rdy;
    reg [2:0] state, state_next;

        
    sync_write col_sync_write(
        .clk     ( clk         ),
        .rst     ( rst         ),
        .i_write ( col_wr      ),
        .i_data  ( i_data_col  ),
        .i_sync  ( sync_sr     ),
        .o_clk   ( o_clk_col   ),
        .o_data  ( o_data_col  ),
        .o_ready ( col_rdy     )
    );

    sync_write row_sync_write(
        .clk     ( clk         ),
        .rst     ( rst         ),
        .i_write ( row_wr      ),
        .i_data  ( i_data_row  ),
        .i_sync  ( sync_sr     ),
        .o_clk   ( o_clk_row   ),
        .o_data  ( o_data_row  ),
        .o_ready ( row_rdy     )
    );

    sync_write key_sync_write(
        .clk     ( clk         ),
        .rst     ( rst         ),
        .i_write ( key_wr      ),
        .i_data  ( 1'b0        ),
        .i_sync  ( sync_key    ),
        .o_clk   ( o_write_key ),
        .o_data  (             ),
        .o_ready ( key_rdy     )
    );

    sync_write row_sync_reset(
        .clk     ( clk         ),
        .rst     ( rst         ),
        .i_write ( row_rst     ),
        .i_data  ( 1'b0        ),
        .i_sync  ( sync_sr     ),
        .o_clk   ( o_rst_row   ),
        .o_data  (             ),
        .o_ready ( row_rst_rdy )
    );

    //Generador de clock para los registros de desplazamiento
    clock_divider#(
        .NB_DIVIDER (NB_DIVIDER)
    )u_clock_divider_sr(
        .i_clk     ( clk          ),
        .i_rst     ( sync_sr_rst  ),
        .i_divider ( i_clk_div_sr ),
        .o_clk     ( sync_sr      )
    );

    //Generador de clock para la escritura de pixeles
    clock_divider#(
        .NB_DIVIDER (NB_DIVIDER)
    )u_clock_divider_key(
        .i_clk     ( clk           ),
        .i_rst     ( sync_key_rst  ),
        .i_divider ( i_clk_div_key ),
        .o_clk     ( sync_key      )
    );

    // Registros de FSM
    always@(posedge clk or posedge rst) begin
        if(rst) state <= IDLE;
        else state <= state_next;
    end

    // Logica de estado siguiente
    always @(*) begin
        case (state)
            IDLE:
                if (i_write_key) state_next = WRITE_KEY;
                else if (i_write_col) state_next = WRITE_COL;
                else if (i_write_row) state_next = WRITE_ROW;
                else if (i_rst_row) state_next = ROW_RST;
                else state_next = IDLE;
            WRITE_COL: 
                if (col_rdy) state_next = IDLE;
                else state_next = WRITE_COL;
            WRITE_ROW:
                if (row_rdy) state_next = IDLE;
                else state_next = WRITE_ROW;
            WRITE_KEY: 
                if (key_rdy) state_next = IDLE;
                else state_next = WRITE_KEY;
            ROW_RST:
                if( row_rst_rdy ) state_next = IDLE;
                else state_next = ROW_RST;
            default: 
                state_next = IDLE;
        endcase
    end
                
    assign sync_sr_rst = (state == IDLE);
    assign sync_key_rst = (state != WRITE_KEY);
    assign key_wr = (state == IDLE) && i_write_key;
    assign col_wr = (state == IDLE) && i_write_col;
    assign row_wr = (state == IDLE) && i_write_row;
    assign row_rst = (state == IDLE) &&  i_rst_row;

    assign o_rdy  = (state == IDLE);// && (state_next == IDLE);

    assign o_sync = sync_sr;


endmodule

`endif