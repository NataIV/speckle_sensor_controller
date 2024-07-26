`ifndef COUNTER_OFFSET_V
`define COUNTER_OFFSET_V
//!    @title CONTADOR CON OFFSET
//!    @file counter_offset.v
//!    @author Valle Natalio
//!    @details
//!         Este modulo es un contador modificado para que pueda
//!         ajustarse un offset a la salida sin modificar el valor
//!         almacenado.
//!              00 => mantiene el valor 
//!              01 => suma  1
//!              10 => suma  2
//!              11 => resta 1
   

`define COUNTER_RESET     5'b10000
`define COUNTER_SETMAX    5'b01000
`define COUNTER_ENABLE    5'b00100

`define COUNTER_DEC_1     5'b00011
`define COUNTER_INC_2     5'b00010
`define COUNTER_INC_1     5'b00001
`define COUNTER_NO_CHANGE 5'b00000

`define COUNTER_RESET_BIT   4
`define COUNTER_LOADMAX_BIT 3
`define COUNTER_ENABLE_BIT  2

module counter_offset #(
    parameter MOD = 24
)
(
    input clk,
    input [4:0] control,
    output [$clog2(MOD)-1 : 0] value,
    output overflow
);

    wire rst, load_max, en;
    wire [1:0] sel;
    
    assign rst = control[4];
    assign load_max = control[3];
    assign en = control[2];
    assign sel = control[1:0];

    localparam REGISTER_SIZE = $clog2(MOD);

    reg [REGISTER_SIZE+2 : 0] count;
    wire [REGISTER_SIZE+2 : 0] count_unreg;
    wire [2:0] add_value;

    always @(posedge clk) begin
        if(rst)
            count <= 0;//{(REGISTER_SIZE + 1){1'b0}};
        else if(load_max)
            count <= MOD - 1;
        else if(en)
            count <= count_unreg;
    end 


    assign add_value   = (sel == 2'b00) ? 3'b000 :  
                         (sel == 2'b01) ? 3'b001 : 
                         (sel == 2'b10) ? 3'b010 : 3'b111; 

    assign count_unreg = count + {{(REGISTER_SIZE){add_value[2]}},add_value[1:0]};
    
    assign value    = count_unreg[REGISTER_SIZE-1:0];
    assign overflow = !(count_unreg[REGISTER_SIZE : 0] < MOD);


endmodule

`endif /* COUNTER_OFFSET_V */