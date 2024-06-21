`ifndef SCAN_MODULE_H
`define SCAN_MODULE_H
`include "scan_fsm.v"

module scan_module
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
    output o_ram_write,

    // ADC
    output o_adc_trig,
    input  i_adc_done,

    // contadores de direccionamiento de ram
    input                  i_row_overflow,
    input                  i_col_overflow,
    output wire [4:0]      o_row_control,
    output wire [4:0]      o_col_control,

    input  i_chip_rdy,
    
    // al chip
    output o_row_reg_data,
    output o_row_reg_write,

    output o_col_reg_data,
    output o_col_reg_write,

    output o_key_write

);
    localparam MEM_DEPTH   = PIXEL_N_ROWS * PIXEL_N_COLS;
    localparam NB_MEM_ADDR = $clog2(MEM_DEPTH);


/// FSM CONNECTIONS
wire fsm_col_ready;

// COL SHIFT REGISTER CONNECTIONS
wire sr_col_write;
wire [6:0] sr_col_data;

scan_fsm #(
    .PIXEL_N_COLS (PIXEL_N_COLS),
    .PIXEL_N_ROWS (PIXEL_N_ROWS),
    .NB_ADC (NB_ADC)
)
    u_scan_fsm(
    .clk                                ( clk                                ),
    .i_rst                              ( i_rst                              ),
    .i_start_scan                       ( i_start_scan                       ),
    .o_scan_ready                       ( o_scan_ready                       ),
    .o_ram_write                        ( o_ram_write                        ),
    .o_adc_trig                         ( o_adc_trig                         ),
    .i_adc_done                         ( i_adc_done                         ),
    .i_row_overflow                     ( i_row_overflow                     ),
    .i_col_overflow                     ( i_col_overflow                     ),
    .o_row_control                      ( o_row_control                      ),
    .o_col_control                      ( o_col_control                      ),
    .i_row_rdy                          ( i_chip_rdy                         ),
    .i_col_rdy                          ( fsm_col_ready                      ),
    .i_key_rdy                          ( i_chip_rdy                         ),
    .o_row_reg_data                     ( o_row_reg_data                     ),
    .o_row_reg_write                    ( o_row_reg_write                    ),
    .o_col_reg_data                     ( sr_col_data                        ),
    .o_col_reg_write                    ( sr_col_write                       ),
    .o_key_write                        ( o_key_write                        )
);



cfg_word_sr#(
    .LEN    ( 7 )
)u_cfg_word_sr(
    /* CLOCK */
    .clk             ( clk             ),           //! System_clock
    /* INPUTS */
    .i_rst           ( i_rst           ),           //! Driver reset
    .i_col_rdy       ( i_chip_rdy      ),           //! Shift enable
    .i_load          ( sr_col_write    ),           //! Shift register load enable
    .i_data          ( sr_col_data     ),           //! Input data to shift register
    /* OUTPUTS */
    .o_col_write     ( o_col_reg_write ),           //! Output clock
    .o_data          ( o_col_reg_data  ),           //! Output shifted data
    .o_ready         ( fsm_col_ready   )            //! Flag
);

    
endmodule

`endif /* SCAN_MODULE_H */