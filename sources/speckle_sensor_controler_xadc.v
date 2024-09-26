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

module speckle_sensor_controller_xadc #(
    COLS =    24,
    ROWS =    24,
    NB_DATA = 12,
    INIT_FILE = "init.mem"
)
(
    input clk,

    // Registros de accedidos mediante axi
    input  [31:0] i_optreg,
    input  [31:0] i_ram_ctrl_reg,
    input  [NB_DATA-1:0] i_umbral,
    input  [`NB_FREQ_DIV-1:0] i_clk_div_sr,
    input  [`NB_FREQ_DIV-1:0] i_clk_div_key,

    output [31:0] o_ram_out_reg,
    output [31:0] o_status,
    
    // Entradas analogicas
    input  vauxn6,
    input  vauxp6,
    // Salidas digitales
    output [7:0] o_chip_signals
);



localparam NB_RAM_ADDR = $clog2(COLS*ROWS);
wire busy_out;
wire adc_trigger;
wire [NB_DATA-1:0] adc_result;
wire adc_done;
wire [15:0]do_out;
wire eos;


wire  [NB_DATA-1:0] adc_val;

wire ram_dbg;
wire [11:0] ram_out_reg;
wire [9:0]  ram_dbg_addr;
wire [11:0] ram_dbg_input = 0;

wire [7:0] chip_signals;
wire [31:0] optreg;
wire [31:0] status;

assign adc_result = do_out[15-:NB_DATA];

// wire [2:0] avg_sample_num;
// wire [NB_DATA-1:0] avg_input_sample;
// wire avg_start;
// wire avg_input_sample_ready;
// wire avg_input_sample_trigger;
// wire avg_done;
// wire [NB_DATA-1:0] avg_output;

// avg#(
//     .NB_DATA      ( NB_DATA )
// )u_avg(
//     .clk          ( clk                         ),
//     .rst          ( rst                         ),
//     .i_start      ( avg_start                   ),
//     .i_adc_done   ( avg_input_sample_ready      ),
//     .i_nSamples   ( avg_sample_num              ),
//     .i_sample     ( avg_input_sample            ),
//     .o_done       ( avg_done                    ),
//     .o_adcTrigger ( avg_input_sample_trigger    ),
//     .o_result     ( avg_output                  )
// );

adc adc_i(   
    .alarm_out                    (                              ),
    .busy_out                     ( busy_out                     ),
    .channel_out                  (                              ),
    .convst_in                    ( adc_trigger                  ),
    .daddr_in                     ( 6'h16                        ),
    .dclk_in                      ( clk                          ),
    .den_in                       ( 1'b1                         ),
    .di_in                        ( 16'h0000                     ),
    .do_out                       ( do_out                       ),
    .drdy_out                     (                              ),
    .dwe_in                       ( 1'b0                         ),
    .eoc_out                      ( adc_done                     ),
    .eos_out                      ( eos                          ),
    .vauxn6                       ( vauxn6                       ),
    .vauxp6                       ( vauxp6                       ),
    .vn_in                        (                              ),
    .vp_in                        (                              )
);

speckle_sensor_controller#(
    .COLS        ( COLS ),
    .ROWS        ( ROWS ),
    .NB_DATA     ( NB_DATA ),
    .INIT_FILE   ( INIT_FILE )
)u_speckle_sensor_controller(
    .clk             ( clk             ),
    .o_status        ( o_status        ),
    .i_optreg        ( i_optreg        ),
    .i_ram_ctrl_reg  ( i_ram_ctrl_reg  ),
    .i_adc_val       ( adc_result      ),
    .i_adc_done      ( adc_done        ),
    .i_umbral        ( i_umbral        ),
    .i_clk_div_sr    ( i_clk_div_sr    ),
    .i_clk_div_key   ( i_clk_div_key   ),
    .o_ram_out_reg   ( o_ram_out_reg   ),
    .o_adc_trigger   ( adc_trigger     ),
    .o_chip_signals  ( o_chip_signals  )
);


// assign o_chip_key_wren = chip_signals[7];
// assign o_chip_col_clk  = chip_signals[6];
// assign o_chip_col_rst  = chip_signals[5];
// assign o_chip_col_data = chip_signals[4];
// assign o_chip_row_clk  = chip_signals[3];
// assign o_chip_row_rst  = chip_signals[2];
// assign o_chip_row_ena  = chip_signals[1];
// assign o_chip_row_data = chip_signals[0];

// assign led = status[3:0];



endmodule