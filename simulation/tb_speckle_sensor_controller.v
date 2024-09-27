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

reg  clk             ;
reg  [ 3:0] selection;
wire [ 3:0] btn      ;
wire [ 3:0] led      ;
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

wire [9:0] row, col;
wire [9:0] mem_addr;
reg  [11:0] mem [15:0];

reg rst, start;
assign btn[0] = rst;
assign btn[1] = start;
assign btn[2] = 1'b0;
assign btn[3] = 1'b0;

assign col = uut.u_speckle_sensor_controller.from_cnt_col_value;
assign row = uut.u_speckle_sensor_controller.from_cnt_row_value;
assign mem_addr = col * 24 + row;

initial clk = 1'b1;
always #(PERIOD/2) clk =~ clk;

initial rst = 1'b1; always #(PERIOD/2) rst = 1'b0;

// Memory
initial begin
    $readmemh("init.mem", mem, 0, 15);
end

always @(posedge clk) begin
    if(rst)begin
        i_adc_val <= mem[0];
        adc_cnt <= 0;
    end
    if(o_adc_trigger)begin
        i_adc_val <= mem[adc_cnt];
        adc_cnt <= adc_cnt + 1;
    end
end

// Stimulus
initial begin
    start = 1'b0;
    i_adc_done = 1'b1;
    selection = 4'b0111;
    @(negedge rst);
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;
    #50000;
    $finish();
end



speckle_sensor_controller_pl_only#(
    .COLS ( 4 ),
    .ROWS ( 4 ),
    .NB_DATA ( 12 ),
    .INIT_FILE ( " .mem" )
)uut(
    .clk                          ( clk                          ),
    .sw                           ( selection                    ),
    .btn                          ( btn                          ),
    .led                          ( led                          ),
    .i_ram_ctrl_reg               ( 0                            ),
    .i_adc_val                    ( i_adc_val                    ),
    .i_adc_done                   ( i_adc_done                   ),
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
    .o_chip_row_data              ( o_chip_row_data              )
);


endmodule