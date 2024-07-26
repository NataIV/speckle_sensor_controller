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
wire busy_out;
wire adc_trigger;
wire [NB_DATA-1:0] adc_result;
wire adc_done;
wire [15:0]do_out;
//wire [15:0]di_in;
//wire drdy_out;
//wire dwe_in;
wire eos;
//wire vn_in;
//wire vp_in;
wire [23:0] ssc_clk_div_sr;
wire [23:0] ssc_clk_div_key;
wire [11:0] ssc_umbral;


assign adc_result = do_out[15-:NB_DATA];

speckle_sensor_controller#(
    .COLS                         ( `COLS                        ),
    .ROWS                         ( `ROWS                        ),
    .NB_DATA                      ( `NB_DATA                     )
)u_speckle_sensor_controller(
    .clk                          ( clk                          ),
    .sw                           ( sw                           ),
    .btn                          ( btn                          ),
    .led                          ( led                          ),
    .i_umbral                     ( ssc_umbral                   ),
    .i_clk_div_sr                 ( ssc_clk_div_sr               ),
    .i_clk_div_key                ( ssc_clk_div_key              ),
    .i_adc_val                    ( adc_result                   ),
    .i_adc_done                   ( adc_done                     ),
    .o_adc_trigger                ( adc_trigger                  ),
    .o_chip_key_wren              ( o_chip_key_wren              ),
    .o_chip_col_clk               ( o_chip_col_clk               ),
    .o_chip_col_rst               ( o_chip_col_rst               ),
    .o_chip_col_data              ( o_chip_col_data              ),
    .o_chip_row_clk               ( o_chip_row_clk               ),
    .o_chip_row_rst               ( o_chip_row_rst               ),
    .o_chip_row_ena               ( o_chip_row_ena               ),
    .o_chip_row_data              ( o_chip_row_data              )
);

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






// clock_scaler
//     u_clock_scaler
//     (   .clk_in1_0 (clk),
//         .clk_out1_0 (clk),
//         .locked_0 (),
//         .reset_0 (1'b0));

generate
    if (`SIM) begin
        // para debug uso valores default o definidos en el testbench
        assign ssc_clk_div_sr  = FREQ_DIV_SR;
        assign ssc_clk_div_key = FREQ_DIV_KEY;
        assign ssc_umbral = UMBRAL;

    end else if (`VIO_DEBUG) begin
        // Si este modulo es el modulo superior, instancio el modulo VIO

        wire [23:0] vio_key_clk_div;
        wire [NB_RAM_ADDR-1:0]  vio_ram_address;
        wire [NB_DATA-1:0] vio_ram_output;
        wire [23:0] vio_sr_clk_div;
        wire [NB_DATA-1:0] vio_umbral;
        wire [NB_DATA-1:0] vio_xadc_output;

        vio vio_i
            (.clk(clk),
            .key_clk_div(vio_key_clk_div),
            .ram_address(vio_ram_address),
            .ram_output(vio_ram_output),
            .sr_clk_div(vio_sr_clk_div),
            .umbral(vio_umbral),
            .xadc_output(vio_xadc_output));

        assign vio_ram_address = u_speckle_sensor_controller.to_ram_addr;
        assign vio_ram_output = u_speckle_sensor_controller.from_ram_data_out;
        assign vio_xadc_output = adc_result;

        assign ssc_clk_div_sr  = vio_sr_clk_div;
        assign ssc_clk_div_key = vio_key_clk_div;
        assign ssc_umbral = vio_umbral;

    end else begin
        assign ssc_clk_div_sr  = FREQ_DIV_SR;
        assign ssc_clk_div_key = FREQ_DIV_KEY;
        assign ssc_umbral = UMBRAL;
    end
endgenerate       


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