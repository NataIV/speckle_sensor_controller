`timescale 1ns / 1ps

`include "speckle_sensor_controller.v"

`define COLS     24
`define ROWS     24
`define NB_DATA  12
`define UMBRAL   1

`define CLOCK_FREQ 125_000_000
`define WRITE_FREQ       1_000

`define NB_FREQ_DIV  24
`define FREQ_DIV_SR  24'h0F_FFFF
`define FREQ_DIV_KEY 24'hFF_FFFF

`define SIM 1'b0
`define VIO_DEBUG 1'b1
`define ILA_DEBUG 1'b1

module top #(
    COLS =    `COLS,
    ROWS =    `ROWS,
    NB_DATA = `NB_DATA,
    UMBRAL  = `UMBRAL,
    FREQ_DIV_SR  = `FREQ_DIV_SR,
    FREQ_DIV_KEY = `FREQ_DIV_KEY,
    DEBUG = `SIM
)
(
    input clk,

    input  [3:0] sw,
    input  [3:0] btn,
    output [3:0] led,

    input  vauxn6,
    input  vauxp6,
    
    output o_chip_key_wren,

    output o_chip_col_clk,
    output o_chip_col_rst,
    output o_chip_col_data,
    
    output o_chip_row_clk,
    output o_chip_row_rst,
    output o_chip_row_ena,
    output o_chip_row_data,


    output o_chip_col_data_cpy,
    output o_chip_col_rst_cpy,
    output o_chip_row_ena_cpy,
    output o_chip_row_rst_cpy,
    output o_chip_col_clk_cpy,
    output o_chip_key_wren_cpy,
    output o_chip_row_clk_cpy,
    output o_chip_row_data_cpy
);

localparam NB_RAM_ADDR = $clog2(COLS*ROWS);

wire [7:0]  chip_signals;
wire [31:0] optreg;
wire [31:0] status;

wire ram_dbg;
wire [11:0] ram_out_reg;
wire [9:0]  ram_dbg_addr;
wire [11:0] ram_dbg_input = 0;
wire [31:0] ram_ctrl_reg = {ram_dbg, ~ram_dbg, ram_dbg, ~ram_dbg, ram_dbg, ram_dbg_addr, ram_dbg_input};


wire [23:0] vio_key_clk_div;
wire [NB_DATA-1:0] vio_ram_output;
wire [23:0] vio_sr_clk_div;
wire [NB_DATA-1:0] vio_umbral;

speckle_sensor_controller_xadc#(
    .COLS        ( COLS         ),
    .ROWS        ( ROWS         ),
    .NB_DATA     ( NB_DATA      )
)u_speckle_sensor_controller_xadc(
    .clk             ( clk              ),
    .i_optreg        ( optreg           ),
    .i_ram_ctrl_reg  ( ram_ctrl_reg     ),
    .i_umbral        ( vio_umbral       ),
    .i_clk_div_sr    ( vio_sr_clk_div   ),
    .i_clk_div_key   ( vio_key_clk_div  ),
    .o_ram_out_reg   ( ram_out_reg      ),
    .o_status        ( status           ),
    .vauxn6          ( vauxn6           ),
    .vauxp6          ( vauxp6           ),
    .o_chip_signals  ( chip_signals     )
);

vio vio_i (
    .clk            ( clk               ),
    .key_clk_div    ( vio_key_clk_div   ),
    .ram_address    (    ),
    .ram_output     ( ram_out_reg       ),
    .sr_clk_div     ( vio_sr_clk_div    ),
    .umbral         ( vio_umbral        ),
    .xadc_output    (    )
);

ila_ram_scan dbg_ram
(
    .clk(clk),
    .rst(rst),
    .i_start_scan(btn[3]),
    .o_ram_addr(ram_dbg_addr),
    .o_ram_dbg(ram_dbg)
);

ila_bram_debug u_ila (   
    .clk(clk),
    .data(ram_out_reg),
    .trigger(ram_dbg)
);


// Entradas y salidas

assign optreg[7-:4] = sw ;
assign optreg[3-:4] = btn;
assign led = status[3:0];

// Salidas al chip
assign o_chip_key_wren = chip_signals[7];
assign o_chip_col_clk  = chip_signals[6];
assign o_chip_col_rst  = chip_signals[5];
assign o_chip_col_data = chip_signals[4];
assign o_chip_row_clk  = chip_signals[3];
assign o_chip_row_rst  = chip_signals[2];
assign o_chip_row_ena  = chip_signals[1];
assign o_chip_row_data = chip_signals[0];

// Salidas Para Debug
assign o_chip_col_data_cpy = o_chip_col_data;
assign o_chip_col_rst_cpy =  o_chip_col_rst; 
assign o_chip_row_ena_cpy =  o_chip_row_ena; 
assign o_chip_row_rst_cpy =  o_chip_row_rst; 
assign o_chip_col_clk_cpy =  o_chip_col_clk; 
assign o_chip_key_wren_cpy = o_chip_key_wren;
assign o_chip_row_clk_cpy =  o_chip_row_clk; 
assign o_chip_row_data_cpy = o_chip_row_data;

endmodule