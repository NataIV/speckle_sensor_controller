`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.04.2024 16:48:34
// Design Name: 
// Module Name: tb_speckle_sensor_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "../sources/speckle_sensor_controller.v"

module tb_speckle_sensor_controller();

localparam PERIOD = 10;

reg [8*64-1:0] descripcion;
reg  clk             ;
wire [ 3:0] sw       ;
wire [ 3:0] btn      ;
wire [ 3:0] led      ;
reg  [ 2:0] avg_len;
reg  [11:0] i_adc_val;
reg  [16:0] adc_cnt;
reg  i_adc_done      ;
wire o_adc_trigger   ;
wire o_chip_key_wren ;
wire o_chip_col_clk  ;
wire o_chip_col_rst  ;
wire o_chip_col_data ;
wire o_chip_row_clk  ;
wire o_chip_row_rst  ;
wire o_chip_row_ena  ;
wire o_chip_row_data ;
wire o_chip_amp_clk ;
wire o_chip_amp_data;
wire o_chip_amp_ena ;
wire o_chip_amp_rst ;

wire [9:0] row, col;
wire [9:0] mem_addr;
reg  [11:0] mem [15:0];

reg sw_scan, sw_config, sw_reset_val, sw_dark_scan;
reg done_scan, done_reset, done_process, done_config;
reg rst, start, amp_config;
assign btn[0] = rst;
assign btn[1] = start;
assign btn[2] = amp_config;
assign btn[3] = 1'b0;

assign sw = {sw_reset_val, sw_dark_scan, sw_config, sw_scan};

assign col = uut.u_speckle_sensor_controller.from_cnt_col_value;
assign row = uut.u_speckle_sensor_controller.from_cnt_row_value;
assign mem_addr = col * 4 + row;

initial clk = 1'b1;
always #(PERIOD/2) clk =~ clk;

initial rst = 1'b1; always #(PERIOD/2) rst = 1'b0;

// Memory
initial begin
    $readmemh("init.mem", mem, 0, 15);
end

/*
    Simulacion de los valores de los pixeles
*/
always @(posedge clk) begin
    if(rst)begin
        i_adc_val <= mem[0];
    end
    if(o_adc_trigger)begin
        i_adc_val <= mem[mem_addr];
    end
end

// Stimulus
initial begin
    descripcion = "Iniciando simulacion";
    avg_len = 3'b010;
    amp_config = 1'b0;
    start = 1'b0;
    i_adc_done = 1'b1;
    sw_reset_val = 1'b1;
    sw_config = 1'b1;
    sw_scan = 1'b1;
    sw_dark_scan = 1'b0;
    @(negedge rst);
    #100
    
    // descripcion = "Configurando amplificadores";
    // @(posedge clk);
    // amp_config = 1'b1;
    // @(posedge clk);
    // amp_config = 1'b0;
    // #7000;
    
    descripcion = "Iniciando Escaneo";
    @(posedge clk);
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;
    #50000;
    $finish();
end

// // Stimulus amp
// initial begin
//     start = 1'b0;
//     i_adc_done = 1'b1;
//     sw = 4'b0000;
//     amp_config = 1'b0;
//     @(negedge rst);
//     #20;
//     @(posedge clk);
//     amp_config = 1'b1;
//     #20;
    
//     @(posedge clk);
//     amp_config = 1'b0;

    
//     #50000;
//     $finish();
// end

speckle_sensor_controller_pl_only#(
    .COLS ( 4 ),
    .ROWS ( 4 ),
    .NB_DATA ( 12 ),
    .INIT_FILE ( " .mem" )
)uut(
    .clk                          ( clk                          ),
    .sw                           ( sw                    ),
    .btn                          ( btn                          ),
    .led                          ( led                          ),
    .i_ram_ctrl_reg               ( 0                            ),
    .i_amp_value_reg              ( 6'b111010                    ),
    .i_adc_val                    ( i_adc_val                    ),
    .i_adc_eoc                    ( i_adc_done                   ),    
    .i_avg_len                    ( avg_len                      ),
    .i_umbral                     ( 3                            ),
    .i_clk_div_sr                 ( 4                            ),
    .i_clk_div_key                ( 8                            ),
    .o_adc_trigger                ( o_adc_trigger                ),
    .o_chip_key_wren              ( o_chip_key_wren              ),
    .o_chip_col_clk               ( o_chip_col_clk               ),
    .o_chip_col_rst               ( o_chip_col_rst               ),
    .o_chip_col_data              ( o_chip_col_data              ),
    .o_chip_row_clk               ( o_chip_row_clk               ),
    .o_chip_row_rst               ( o_chip_row_rst               ),
    .o_chip_row_ena               ( o_chip_row_ena               ),
    .o_chip_row_data              ( o_chip_row_data              ),
    .o_chip_amp_clk               ( o_chip_amp_clk               ),
    .o_chip_amp_data              ( o_chip_amp_data              ),
    .o_chip_amp_ena               ( o_chip_amp_ena               ),
    .o_chip_amp_rst               ( o_chip_amp_rst               )
);
endmodule