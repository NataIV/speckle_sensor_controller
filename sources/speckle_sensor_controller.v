`ifndef SPECKLE_SENSOR_CONTROLLER_H
`define SPECKLE_SENSOR_CONTROLLER_H
`timescale 1ns / 1ps

`include "top_level_fsm/top_fsm.v"
`include "chip_driver/chip_driver.v"
`include "counter_offset/counter_offset.v"
`include "config_fsm/cfg_fsm.v"
`include "ram/ram.v"
`include "scan_fsm/scan_module.v"
`include "scan_fsm/scan_fsm.v"
`include "scan_fsm/cfg_word_sr.v"
`include "process_fsm/process_fsm.v"
//`include "ram/ila_ram_scan.v"
//`include "filter/avg.v"

`define CLOCK_FREQ 125_000_000
`define WRITE_FREQ       1_000

`define NB_FREQ_DIV  24
`define BRAM_DEBUG 1'b0

module speckle_sensor_controller #(
    COLS =    24,
    ROWS =    24,
    NB_DATA = 12,
    INIT_FILE = "init.mem"
)
(
    input clk,

    output [31:0] o_status,
    input  [31:0] i_optreg,

    input  [31:0] i_ram_ctrl_reg,
    // | ram_ext_debug| ram_ena | ram_rst | ram_read | ram_wren | ram_address | ram_input |
    //        26          25        24         23         22         21-12        11-0

    output [31:0] o_ram_out_reg,

    input  [NB_DATA-1:0] i_adc_val,
    input  i_adc_done, //(eoc)

    input  [NB_DATA-1:0] i_umbral,

    input  [`NB_FREQ_DIV-1:0] i_clk_div_sr,
    input  [`NB_FREQ_DIV-1:0] i_clk_div_key,

    output o_adc_trigger, 
    
    output [7:0] o_chip_signals
);

// CONEXIONES SALIDAS Y ENTRADAS A VECTORES

wire chip_key_wren;
wire chip_col_clk;
wire chip_col_rst;
wire chip_col_data;
wire chip_row_clk;
wire chip_row_rst;
wire chip_row_ena;
wire chip_row_data;


assign o_chip_signals = {
    chip_key_wren,
    chip_col_clk,
    chip_col_rst,
    chip_col_data,
    chip_row_clk,
    chip_row_rst,
    chip_row_ena,
    chip_row_data
};


localparam MODE_OFFSET  = 7; // REEMPLAZAN LOS SW
localparam MODE_WIDTH   = 4;
localparam OPT_READMEM  = 2; // REEMPLAZAN BOTONES
localparam OPT_START    = 1;
localparam OPT_RST      = 0;

localparam RAM_DEPTH = COLS * ROWS;

wire rst;

// CHIP DRIVER COMPONENT SIGNAL DECLARATIONS
wire to_chip_driver_i_data_col;
wire to_chip_driver_i_data_row;
wire to_chip_driver_i_write_key;
wire to_chip_driver_i_write_col;
wire to_chip_driver_i_write_row;

wire to_chip_driver_i_rst_row;

wire from_chip_driver_o_rdy;


// CONFIGURATION FSM SIGNAL DECLARATIONS
wire to_cfg_fsm_start              ;
wire [NB_DATA-1:0] to_cfg_fsm_i_ram_data ;
wire to_cfg_fsm_i_row_overflow    ;
wire to_cfg_fsm_i_col_overflow    ;
wire to_cfg_fsm_i_col_is_even     ;
wire to_cfg_fsm_i_chip_write_ready;

wire from_cfg_fsm_o_ram_read      ;
wire [4:0] from_cfg_fsm_o_row_control   ;
wire [4:0] from_cfg_fsm_o_col_control   ;
wire from_cfg_fsm_o_row_reg_data  ;
wire from_cfg_fsm_o_row_reg_write ;
wire from_cfg_fsm_o_col_reg_data  ;
wire from_cfg_fsm_o_col_reg_write ;
wire from_cfg_fsm_o_key_wren      ;
wire from_cfg_fsm_o_done          ;

// SCAN FSM SIGNAL DECLARATIONS
wire to_scan_fsm_start    ;
wire to_scan_fsm_adc_done      ;
wire to_scan_fsm_row_overflow  ;
wire to_scan_fsm_col_overflow  ;
//wire to_scan_fsm_row_rdy       ;
//wire to_scan_fsm_col_rdy       ;
//wire to_scan_fsm_key_rdy       ;
wire to_scan_fsm_chip_rdy      ;

wire from_scan_fsm_scan_ready    ;
wire from_scan_fsm_ram_wren      ;
wire from_scan_fsm_adc_trig      ;
wire [4:0] from_scan_fsm_row_control   ;
wire [4:0] from_scan_fsm_col_control   ;
wire from_scan_fsm_row_reg_data  ;
wire from_scan_fsm_row_reg_write ;
wire from_scan_fsm_col_reg_data  ;
wire from_scan_fsm_col_reg_write ;
wire from_scan_fsm_key_write     ;
wire from_scan_fsm_row_rst;

// PROCESS FSM SINGAN DECLARATIONS
wire to_process_fsm_start        ;
wire [NB_DATA-1:0] to_process_fsm_ram_value ;
wire to_process_fsm_row_overflow ;
wire to_process_fsm_col_overflow ;
wire from_process_fsm_rdy        ; 
wire from_process_fsm_ram_wren   ; 
wire [NB_DATA-1:0] from_process_fsm_ram_data; 
wire [4:0] from_process_fsm_row_control; 
wire [4:0] from_process_fsm_col_control; 

// RAM INDEX COUNTER SIGNAL DECLARATIONS
wire [4:0] to_cnt_col_control   ;
wire [$clog2(COLS)-1:0] from_cnt_col_value   ;
wire from_cnt_col_overflow;

wire [4:0] to_cnt_row_control   ;
wire [$clog2(ROWS)-1:0] from_cnt_row_value   ;
wire from_cnt_row_overflow;

// TOP FSM SIGNAL CONNECTIONS
wire [NB_DATA-1 : 0] to_top_fsm_scan_ram_data;
wire [3:0] to_top_fsm_select_mode;
wire to_top_fsm_start;
wire from_top_fsm_done;


wire [$clog2(COLS)-1:0] ram_col_addr;
wire [$clog2(ROWS)-1:0] ram_row_addr;
wire [$clog2(RAM_DEPTH)-1:0] __ram_addr_unsat;
wire [$clog2(RAM_DEPTH)-1:0] to_ram_addr; 
wire [NB_DATA-1:0]           from_ram_data_out;
wire [NB_DATA-1:0]           __from_ram_data_out;
wire                         to_ram_wren;
wire [NB_DATA-1:0]           to_ram_data_in;
wire                         to_ram_read;
wire                         to_ram_rsta;
wire to_ram_ena;


/*--------------------------- CONNECTIONS ------------------------------*/
// Input signals connections
assign rst  = i_optreg[OPT_RST]; //
assign to_top_fsm_start = i_optreg[OPT_START];
assign to_top_fsm_scan_ram_data = i_adc_val;
assign to_top_fsm_select_mode   = i_optreg[MODE_OFFSET-:MODE_WIDTH];


// ---- RAM
// Solo datos validos a la salida de la ram
assign from_ram_data_out = (from_cnt_col_overflow | from_cnt_row_overflow) ? {NB_DATA{1'b0}} : __from_ram_data_out; 
assign ram_col_addr = from_cnt_col_value;
assign ram_row_addr = from_cnt_row_value;
assign __ram_addr_unsat = (ROWS)*ram_col_addr+ram_row_addr;
assign to_ram_addr = (__ram_addr_unsat < RAM_DEPTH) ? __ram_addr_unsat : (RAM_DEPTH-1);

// ---- CFG FSM
assign to_cfg_fsm_i_ram_data         = from_ram_data_out;
assign to_cfg_fsm_i_row_overflow     = from_cnt_row_overflow;
assign to_cfg_fsm_i_col_overflow     = from_cnt_col_overflow;
assign to_cfg_fsm_i_chip_write_ready = from_chip_driver_o_rdy;
assign to_cfg_fsm_i_col_is_even      = ~from_cnt_col_value[0];

// -- Chip Driver
//assign to_chip_driver_i_clk_div_sr   = FREQ_DIV_SR;
//assign to_chip_driver_i_clk_div_key  = FREQ_DIV_KEY;

// -- SCAN FSM
assign to_scan_fsm_adc_done      = i_adc_done;
assign to_scan_fsm_row_overflow  = from_cnt_row_overflow;
assign to_scan_fsm_col_overflow  = from_cnt_col_overflow;
assign to_scan_fsm_chip_rdy      = from_chip_driver_o_rdy; 
//assign to_scan_fsm_row_rdy       = from_chip_driver_o_rdy; 
//assign to_scan_fsm_col_rdy       = from_chip_driver_o_rdy;
//assign to_scan_fsm_key_rdy       = from_chip_driver_o_rdy;

// -- PROCESS FSM
assign to_process_fsm_ram_value    = from_ram_data_out;
assign to_process_fsm_col_overflow = from_cnt_col_overflow;
assign to_process_fsm_row_overflow = from_cnt_row_overflow;

// CHIP DRIVER COMPONENT INSTANTIATION
chip_driver u_chip_driver (
    .clk           ( clk                         ),
    .rst           ( rst                         ),
    .i_write_key   ( to_chip_driver_i_write_key  ),
    .i_write_col   ( to_chip_driver_i_write_col  ),
    .i_write_row   ( to_chip_driver_i_write_row  ),
    .i_data_col    ( to_chip_driver_i_data_col   ),
    .i_data_row    ( to_chip_driver_i_data_row   ),
    .i_rst_row     ( to_chip_driver_i_rst_row    ),
    //.i_clk_div_sr  ( to_chip_driver_i_clk_div_sr ),
    //.i_clk_div_key ( to_chip_driver_i_clk_div_key),
    .i_clk_div_sr  ( i_clk_div_sr                ),
    .i_clk_div_key ( i_clk_div_key               ),
    .o_clk_col     ( chip_col_clk                ),
    .o_clk_row     ( chip_row_clk                ),
    .o_data_col    ( chip_col_data               ),
    .o_data_row    ( chip_row_data               ),
    .o_write_key   ( chip_key_wren               ),
    .o_rst_row     ( chip_row_rst                ),
    .o_sync        (                             ),
    .o_rdy         ( from_chip_driver_o_rdy      )
);

// SCAN MODULE INSTANTIATION
scan_module#(
    .PIXEL_N_ROWS                       ( ROWS                               ),
    .PIXEL_N_COLS                       ( COLS                               ),
    .NB_ADC                             ( NB_DATA                            )
)u_scan_module(
        .clk                            ( clk                                ),
        .i_rst                          ( rst                                ),
        .i_start_scan                   ( to_scan_fsm_start                  ),
        .i_adc_done                     ( to_scan_fsm_adc_done               ),
        .i_row_overflow                 ( to_scan_fsm_row_overflow           ),
        .i_col_overflow                 ( to_scan_fsm_col_overflow           ),
        .i_chip_rdy                     ( to_scan_fsm_chip_rdy               ),
        .o_scan_ready                   ( from_scan_fsm_scan_ready           ),
        .o_ram_write                    ( from_scan_fsm_ram_wren             ),
        .o_adc_trig                     ( from_scan_fsm_adc_trig             ),
        .o_row_control                  ( from_scan_fsm_row_control          ),
        .o_col_control                  ( from_scan_fsm_col_control          ),
        .o_row_reg_data                 ( from_scan_fsm_row_reg_data         ),
        .o_row_reg_write                ( from_scan_fsm_row_reg_write        ),
        .o_col_reg_data                 ( from_scan_fsm_col_reg_data         ),
        .o_col_reg_write                ( from_scan_fsm_col_reg_write        ),
        .o_key_write                    ( from_scan_fsm_key_write            ),
        .o_row_rst                      ( from_scan_fsm_row_rst              )
);


/*     PROCESS FSM INSTANTATION      */
process_fsm#(
    .PIXEL_N_COLS                       ( ROWS                               ),
    .PIXEL_N_ROWS                       ( COLS                               ),
    .NB_ADC                             ( NB_DATA                            )
)u_process_fsm(
    .clk                                ( clk                                ),
    .rst                                ( rst                                ),
    .i_start                            ( to_process_fsm_start               ),
    .o_rdy                              ( from_process_fsm_rdy               ),
    .i_ram_value                        ( to_process_fsm_ram_value           ),
    .o_ram_write                        ( from_process_fsm_ram_wren          ),
    .o_ram_value                        ( from_process_fsm_ram_data          ),
    .i_row_overflow                     ( to_process_fsm_row_overflow        ),
    .i_col_overflow                     ( to_process_fsm_col_overflow        ),
    .o_row_control                      ( from_process_fsm_row_control       ),
    .o_col_control                      ( from_process_fsm_col_control       )
);

/*                      CONFIGURATION FSM INSTANTIATION                      */
cfg_fsm#(
    .NB_DATA                            ( NB_DATA                            )
)u_cfg_fsm(
    .clk                                ( clk                                ),
    .rst                                ( rst                                ),
    .i_go                               ( to_cfg_fsm_start                   ),
    .i_umbral                           ( i_umbral                           ),
    .i_ram_data                         ( to_cfg_fsm_i_ram_data              ),
    .i_row_overflow                     ( to_cfg_fsm_i_row_overflow          ),
    .i_col_overflow                     ( to_cfg_fsm_i_col_overflow          ),
    .i_col_is_even                      ( to_cfg_fsm_i_col_is_even           ),//cfg_col_is_even   ),
    .i_chip_write_ready                 ( to_cfg_fsm_i_chip_write_ready      ),
    .o_ram_read                         ( from_cfg_fsm_o_ram_read            ),
    .o_row_control                      ( from_cfg_fsm_o_row_control         ),
    .o_col_control                      ( from_cfg_fsm_o_col_control         ),
    .o_row_reg_data                     ( from_cfg_fsm_o_row_reg_data        ), 
    .o_row_reg_write                    ( from_cfg_fsm_o_row_reg_write       ),  
    .o_col_reg_data                     ( from_cfg_fsm_o_col_reg_data        ),  
    .o_col_reg_write                    ( from_cfg_fsm_o_col_reg_write       ),  
    .o_key_wren                         ( from_cfg_fsm_o_key_wren            ),  
    .o_done                             ( from_cfg_fsm_o_done                )
);

// RAM INDEX COUNTERS INSTANTIATION 

counter_offset#(
    .MOD                 ( COLS                  )          
)u_counter_cols(
    .clk                 ( clk                   ),
    .control             ( to_cnt_col_control    ), /* Vector de control: (rst, set_max, en, sel[1:0]) */
    .value               ( from_cnt_col_value    ),
    .overflow            ( from_cnt_col_overflow )
);

counter_offset#(
    .MOD                 ( ROWS                  )          
)u_counter_rows(
    .clk                 ( clk                   ),
    .control             ( to_cnt_row_control    ), /* Vector de control: (rst, set_max, en, sel[1:0]) */
    .value               ( from_cnt_row_value    ),
    .overflow            ( from_cnt_row_overflow )
);


wire [$clog2(RAM_DEPTH)-1:0] ram_dbg_addr = i_ram_ctrl_reg[21:12];
wire ram_dbg = i_ram_ctrl_reg[26];

wire [$clog2(RAM_DEPTH)-1:0] _to_ram_addr = (ram_dbg) ? ram_dbg_addr : to_ram_addr;     
wire _to_ram_ena      = (!ram_dbg) ? to_ram_ena  : i_ram_ctrl_reg[25];   
wire _to_ram_rsta     = (!ram_dbg) ? to_ram_rsta : i_ram_ctrl_reg[24];  
wire _to_ram_read     = (!ram_dbg) ? to_ram_read : i_ram_ctrl_reg[23]; 
wire _to_ram_wren     = (!ram_dbg) ? to_ram_wren : i_ram_ctrl_reg[22]; 

// BRAM instantiation
xilinx_single_port_ram_no_change #(
    .RAM_WIDTH(NB_DATA),                       // Specify RAM data width
    .RAM_DEPTH(RAM_DEPTH),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),      // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(INIT_FILE)                      // Specify name/location of RAM initialization file if using one (leave blank if not)
) ram (
    .addra(_to_ram_addr),         // Address bus, width determined from RAM_DEPTH
    .dina(to_ram_data_in),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),                  // Clock
    .wea(_to_ram_wren),           // Write enable
    .ena(_to_ram_ena),            // RAM Enable, for additional power savings, disable port when not in use
    .rsta(_to_ram_rsta),          // Output reset (does not affect memory contents)
    //.rsta(1'b1),                // Output reset (does not affect memory contents)
    .regcea(_to_ram_read),        // Output register enable
    //.regcea(1'b0),              // Output register enable
    .douta(__from_ram_data_out)  // RAM output data, width determined from RAM_WIDTH
);








// FSM para separar las conexiones de recursos compartidos
top_fsm u_top_fsm(
    .clk                   ( clk                          ),
    .rst                   ( rst                          ),
    .en                    ( 1'b1                         ),
    .i_signal_start        ( to_top_fsm_start             ),
    .i_select_mode         ( to_top_fsm_select_mode[2:0]  ),

    /*                  ENTRADAS DE SCAN                   */
    .i_signal_scan_end     ( from_scan_fsm_scan_ready     ),
    .i_scan_col_control    ( from_scan_fsm_col_control    ),
    .i_scan_row_control    ( from_scan_fsm_row_control    ),
    .i_scan_ram_wren       ( from_scan_fsm_ram_wren       ),
    .i_scan_ram_data       ( to_top_fsm_scan_ram_data     ),
    .i_scan_row_reg_data   ( from_scan_fsm_row_reg_data   ),
    .i_scan_row_reg_write  ( from_scan_fsm_row_reg_write  ),
    .i_scan_col_reg_data   ( from_scan_fsm_col_reg_data   ),
    .i_scan_col_reg_write  ( from_scan_fsm_col_reg_write  ),
    .i_scan_key_wren       ( from_scan_fsm_key_write      ),
    .i_scan_row_rst        ( from_scan_fsm_row_rst        ),

    /*             ENTRADAS DE PROCESAMIENTO              */
    .i_signal_process_end  ( from_process_fsm_rdy         ),
    .i_process_col_control ( from_process_fsm_col_control ),
    .i_process_row_control ( from_process_fsm_row_control ),
    .i_process_ram_wren    ( from_process_fsm_ram_wren    ),
    .i_process_ram_data    ( from_process_fsm_ram_data    ),

    /*                  ENTRADAS DE CFG                    */
    .i_signal_cfg_end      ( from_cfg_fsm_o_done          ),
    .i_cfg_col_control     ( from_cfg_fsm_o_col_control   ),
    .i_cfg_row_control     ( from_cfg_fsm_o_row_control   ),
    .i_cfg_ram_read        ( from_cfg_fsm_o_ram_read      ),
    .i_cfg_row_reg_data    ( from_cfg_fsm_o_row_reg_data  ),
    .i_cfg_row_reg_write   ( from_cfg_fsm_o_row_reg_write ),
    .i_cfg_col_reg_data    ( from_cfg_fsm_o_col_reg_data  ),
    .i_cfg_col_reg_write   ( from_cfg_fsm_o_col_reg_write ),
    .i_cfg_key_wren        ( from_cfg_fsm_o_key_wren      ),

    /*                      SALIDAS                      */
    .o_cfg_go              ( to_cfg_fsm_start             ),
    .o_scan_go             ( to_scan_fsm_start            ),
    .o_process_go          ( to_process_fsm_start         ),
    .o_col_control         ( to_cnt_col_control           ),
    .o_row_control         ( to_cnt_row_control           ),
    .o_ram_read            ( to_ram_read                  ),
    .o_ram_wren            ( to_ram_wren                  ),
    .o_ram_data            ( to_ram_data_in               ),
    .o_ram_rsta            ( to_ram_rsta                  ),
    .o_ram_ena             ( to_ram_ena                   ),
    .o_chip_row_ena        ( chip_row_ena                 ),
    .o_row_rst             ( to_chip_driver_i_rst_row     ),
    .o_chip_col_rst        ( chip_col_rst                 ),
    .o_row_reg_data        ( to_chip_driver_i_data_row    ),
    .o_row_reg_write       ( to_chip_driver_i_write_row   ),
    .o_col_reg_data        ( to_chip_driver_i_data_col    ),
    .o_col_reg_write       ( to_chip_driver_i_write_col   ),
    .o_key_wren            ( to_chip_driver_i_write_key   ),
    .o_done                ( from_top_fsm_done            )
);






// OUTPUTS
assign o_adc_trigger = from_scan_fsm_adc_trig;

assign o_status [12:4] = o_chip_signals;
assign o_status[3:0] = {
    to_scan_fsm_start,
    to_process_fsm_start,
    to_cfg_fsm_start,
    from_top_fsm_done
};


assign o_ram_out_reg[11:0] = from_ram_data_out;

endmodule

`endif