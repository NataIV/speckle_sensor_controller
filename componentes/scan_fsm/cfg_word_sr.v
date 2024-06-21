`ifndef CFG_WORD_SR
`define CFG_WORD_SR

//!    @title Registro de desplazamiento de la palabra de configuracion
//!    @file cfg_word_sr.v
//!    @author Valle Natalio
//!    @details
//!        Maquina de estados que controla la escritura de los registros
//!        del sensor en la etapa de configuración. Maneja las salidas de datos y clock
//!        para escribir las palabras de datos de configuración de 7 bits.
//!        No controla la señal de enable ni reset
//!      

//! Ejemplo forma de onda
//!{signal: [
//!  ['Entradas',
//!     {name: 'clk',     wave: 'P...................'},
//!  	{name: 'i_rst',   wave: '10..................'},
//!  	{name: 'i_load',  wave: '0.10................'},
//!  	{name: 'i_data',  wave: 'x.3.xxxxxxxxxxxxxxxx', data: ['data']}
//!  ],
//!  
//!  {name: 'state',   wave: '3..45454545454543...', data: ['idle', 'clk', 'data']},
//!  {name: 'counter', wave: '=...=============...', data: '0 1 2 3 4 5 6 7 8 9 10 11 12 0'},
//!  ['Salidas',
//!   	{name: 'o_clk',   wave: '0...1010101010101010'},
//!  	{name: 'o_data',  wave: '0.=..=.=.=.=.=.=.0..', data: ['data[6]','data[5]','data[4]','data[3]','data[2]','data[1]','data[0]']},
//!  	{name: 'o_ready', wave: '1..0.............1..'}
//!  ]
//!]}


module cfg_word_sr #(
    parameter LEN = 7
) (
    input           clk,    //! System_clock
    input           i_rst,  //! Driver reset
    input           i_col_rdy,   //! Shift enable
    input           i_load, //! Shift register load enable
    input [LEN-1:0] i_data, //! Input data to shift register
    output          o_col_write, //! Output clock
    output          o_data, //! Output shifted data
    output          o_ready //! Flag
);

localparam CNT_LEN = $clog2(2*LEN);
localparam MAX_CNT = 2*LEN - 1;

reg [LEN-1:0]       sr_data; //! Datos del registro de desplazamiento
reg                 sr_load; //! Habilitacion de escritura
reg                 sr_shift;//! Habilitacion de desplazamiento

reg [CNT_LEN-1:0]   cnt_val;
reg                 cnt_rst;

reg [1:0] state;
reg [1:0] next_state;


localparam STATE_IDLE   = 2'b00;
localparam STATE_WRITE  = 2'b01;
localparam STATE_WAIT   = 2'b11;
localparam STATE_SHIFT  = 2'b10;

always @(posedge clk or posedge i_rst) begin : MEM
    #1
    if (i_rst)
        state <= STATE_IDLE;
    else
        state <= next_state;
end

always @(*) begin : LOGIC
    #1 //Para la simulacion
    case (state)
        STATE_IDLE : begin
            // NEXT STATE
            if (i_load)
                next_state <= STATE_WRITE;
            else
                next_state <= STATE_IDLE;
            
            // OUTPUT TO INTERNAL MODULES
            sr_load   = i_load;
            sr_shift  = 1'b0;
            cnt_rst   = 1'b1;

        end
        STATE_WRITE : begin
            // NEXT STATE
            next_state <= STATE_WAIT;

            // OUTPUT TO INTERNAL MODULES
            sr_load   = 1'b0;
            sr_shift  = 1'b0;
            cnt_rst   = 1'b0;

        end
        STATE_WAIT : begin
            // NEXT STATE
            if(i_col_rdy) begin 
                if(|cnt_val) next_state <= STATE_SHIFT;
                else next_state <= STATE_IDLE;
            end
            else begin
                next_state <= STATE_WAIT;
            end

            // OUTPUT TO INTERNAL MODULES
            sr_load   = 1'b0;
            sr_shift  = 1'b0;
            cnt_rst   = 1'b0;

        end
        STATE_SHIFT : begin
            // NEXT STATE
            next_state <= STATE_WRITE;

            
            // OUTPUT TO INTERNAL MODULES
            sr_load   = 1'b0;
            sr_shift  = 1'b1;
            cnt_rst   = 1'b0;
        end
    endcase
end


// SHIFT REGISTER
always @(posedge clk or posedge i_rst) begin : SHIFT_REGISTER
    if (i_rst)
        sr_data <= {LEN{1'b0}};
    else
        // LOAD SHIFT REGISTER
        if (sr_load)
            sr_data <= i_data;
        // SHIFT DATA
        else if(sr_shift)
            sr_data <= {sr_data[LEN-2: 0], 1'b0};
end

// COUNTER
always @(posedge clk) begin : COUNTER
    if (cnt_rst)
        cnt_val <= 3'b110;
    else if (sr_shift)
        cnt_val <= cnt_val - 1;
end

// SALIDAS
assign o_data = sr_data[LEN-1];
assign o_ready = (next_state == STATE_IDLE);
assign o_col_write = (state == STATE_WRITE);

endmodule

`endif /* CFG_WORD_SR */