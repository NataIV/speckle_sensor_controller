`include "speckle_sensor_controller.v"

module speckle_sensor_controller_pl_only #(
    COLS =    24,
    ROWS =    24,
    NB_DATA = 12,
    INIT_FILE = "init.mem"
)
(
    input clk,

    input  [3:0] sw,
    input  [3:0] btn,
    output [3:0] led,

    input  [NB_DATA-1:0] i_adc_val,
    input  i_adc_done,

    input  [31:0] i_ram_ctrl_reg,
    output [31:0] o_ram_out_reg,

    input  [NB_DATA-1:0] i_umbral,

    input  [`NB_FREQ_DIV-1:0] i_clk_div_sr,
    input  [`NB_FREQ_DIV-1:0] i_clk_div_key,

    output o_adc_trigger,
    
    output o_chip_key_wren,

    output o_chip_col_clk,
    output o_chip_col_rst,
    output o_chip_col_data,
    
    output o_chip_row_clk,
    output o_chip_row_rst,
    output o_chip_row_ena,
    output o_chip_row_data
);

wire [7:0] chip_signals;
wire [31:0] optreg;
wire [31:0] status;



speckle_sensor_controller#(
    .COLS        ( COLS ),
    .ROWS        ( ROWS ),
    .NB_DATA     ( NB_DATA ),
    .INIT_FILE   ( INIT_FILE )
)u_speckle_sensor_controller(
    .clk             ( clk             ),
    .o_status        ( status          ),
    .i_optreg        ( optreg          ),
    .i_ram_ctrl_reg  ( i_ram_ctrl_reg  ),
    .o_ram_out_reg   ( o_ram_out_reg   ),
    .i_adc_val       ( i_adc_val       ),
    .i_adc_done      ( i_adc_done      ),
    .i_umbral        ( i_umbral        ),
    .i_clk_div_sr    ( i_clk_div_sr    ),
    .i_clk_div_key   ( i_clk_div_key   ),
    .o_adc_trigger   ( o_adc_trigger   ),
    .o_chip_signals  ( chip_signals    )
);


assign o_chip_key_wren = chip_signals[7];
assign o_chip_col_clk  = chip_signals[6];
assign o_chip_col_rst  = chip_signals[5];
assign o_chip_col_data = chip_signals[4];
assign o_chip_row_clk  = chip_signals[3];
assign o_chip_row_rst  = chip_signals[2];
assign o_chip_row_ena  = chip_signals[1];
assign o_chip_row_data = chip_signals[0];

assign optreg[7-:4] = sw ;
assign optreg[3-:4] = btn;

assign led = status[3:0];

endmodule