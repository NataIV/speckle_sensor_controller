`ifndef SYNC_WRITE_H
`define SYNC_WRITE_H

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


//! Ejemplo:
//!{signal: [
//!  ['Entradas',
//!     {name: 'clk',     wave: 'P............'},
//!  	{name: 'rst',     wave: '10...........'},
//!  	{name: 'i_write', wave: '0.1..0.......'},
//!  	{name: 'i_data',  wave: 'x.3xxxxxxxxxx', data: ['data','data']}
//!  ],
//!  ['Internas',
//!  {name: 'state' ,     wave: '3..4...5...3.', data: ['idle', 'data', 'clk', 'idle']},
//!  {name: 'write ',     wave: '0.10.........', data: ['idle', 'data', 'clk']},
//!  {name: 'i_sync  ',     wave: '0.....10..10.', data: ['idle', 'data', 'clk']},
//!  ],
//!  ['Salidas',
//!   	{name: 'o_clk',   wave: '0......1...0.'},
//!  	{name: 'o_data',  wave: '0..3.........', data: ['data','data']},
//!  	{name: 'o_ready', wave: '1..0.......1.'}
//!  ]
//!]}

//`include "edge_detector.v"

`include "edge_detector.v"

module sync_write
(
    input      clk,
    input      rst,
    input      i_write, 
    input      i_data,
    input      i_sync,

    output     o_clk,
    output     o_data,
    output     o_ready
);

    localparam
        IDLE        = 2'b00,
        SET_DATA    = 2'b01,
        SET_CLOCK   = 2'b11;

    wire write;
    reg [3:0] state;

    edge_detector#(1) write_posedge_detector(clk, rst, i_write, write);

    // data and clock output state machine
    always @(posedge clk or posedge rst) begin
        if(rst)
            state  <= IDLE;
        else
            case (state)
                IDLE: begin
                    if(write)
                        state <= SET_DATA;
                    else
                        state <= IDLE;
                end 

                SET_DATA: begin
                    if(i_sync)
                        state <= SET_CLOCK;
                    else
                        state <= SET_DATA;
                end

                SET_CLOCK: begin
                    if(i_sync)
                        state <= IDLE;
                    else
                        state <= SET_CLOCK;
                end

                default: 
                    state <= IDLE;
            endcase
    end

    // Data flip flop D register
    reg data_reg;
    always@(posedge clk) begin
        if((state == IDLE) && (write))
            data_reg <= i_data;
    end

    assign o_ready  = (state == IDLE);
    assign o_data   = data_reg;
    assign o_clk    = (state == SET_CLOCK);

endmodule

`endif