`ifndef RESET_FSM_V
`define RESET_FSM_V

module reset_fsm #(
    parameter NB_DATA = 12
) (
    input  clk,
    input  rst,
    input  i_start,
    input  i_chip_write_ready,  
    input  i_col_reg_value,     
    input  i_row_reg_value,     

    // Al chip
    output reg o_row_reg_data,
    output reg o_row_reg_write,

    output reg o_col_reg_data,
    output reg o_col_reg_write,
    
    output reg o_row_ena,
    output reg o_row_rst,
    output reg o_col_rst,
    output reg o_key_write,
    output reg o_done
);


// Contadores
    reg [7:0] col;
    reg [7:0] row;
    
// Maquina de estados
    localparam 
        IDLE          =  0,
        ROW_RST       =  1,
        COL_RST       =  2,
        ROW_WAIT      =  3,
        ROW_WRITE     =  4,
        INC_ROW       =  5,
        COL_WRITE     =  6,
        COL_WAIT      =  7,
        PIX_WRITE     =  8,
        PIX_WAIT      =  9,
        INC_COL       = 10,
        COL_SHIFT     = 11,
        DONE          = 12;

// Registros        
    reg [3:0] state;
    reg [3:0] next;

    always @(posedge clk or posedge rst) begin
        if(rst)
            state <= 4'b0000;
        else
            state <= next;
    end
// Logica de estado siguientes
    always @(*) begin
        next = state;
        case (state)
        IDLE        :   if(i_start) next = ROW_RST; 
        ROW_RST     :   if (i_chip_write_ready) next = COL_RST; 
        COL_RST     :   if (i_chip_write_ready) 
                            if(i_row_reg_value) next = ROW_WRITE;
                            else                next = COL_WRITE;
        ROW_WRITE   :   if (i_chip_write_ready) next = ROW_WAIT;
        ROW_WAIT    :   if (i_chip_write_ready) next = INC_ROW;
        INC_ROW     :   if (row < 24) next = ROW_WRITE; 
                        else  next = COL_WRITE;
        COL_WRITE   :   if (i_chip_write_ready) next = COL_WAIT;
        COL_WAIT    :   if (i_chip_write_ready) next = PIX_WRITE;
        PIX_WRITE   :   next = PIX_WAIT;
        PIX_WAIT    :   if (i_chip_write_ready) next = INC_COL;
        INC_COL     :   if (col < 96) next = COL_SHIFT;
                        else  next = DONE;
        COL_SHIFT   :   next = COL_WAIT;
        DONE        :   next = IDLE;
        default     :    next = IDLE;
        endcase
    end

// Salidas
    always @(posedge clk) begin
        o_row_ena <= 1'b0; 
        o_row_rst <= 1'b0;
        o_col_rst <= 1'b0;
        o_col_reg_write <= 1'b0;
        o_row_reg_write <= 1'b0;
        o_col_reg_data <= 1'b0;
        o_row_reg_data <= 1'b0;
        o_key_write <= 1'b0;
        o_done <= 1'b0;

        case (next)
            IDLE : begin
                col <= 0;
                row <= 0;
            end
            ROW_RST: begin
                o_row_rst <= 1'b1;
            end
            COL_RST: begin  
                o_col_rst <= 1'b1;
            end
            ROW_WRITE   : begin
                o_row_ena <= 1'b1;
                o_row_reg_write <= 1'b1;
                o_row_reg_data <= i_row_reg_value;
                end 
            ROW_WAIT    : begin
                o_row_ena <= 1'b1;
            end
            INC_ROW : begin
                row <= row + 1;
                o_row_ena <= 1'b1;
            end
            COL_WRITE   : begin 
                o_col_reg_write <= 1'b1;
                o_col_reg_data <= 1'b1;
            end
            PIX_WRITE  : begin
                o_key_write <= 1'b1;
            end
            INC_COL : begin
                col <= col + 1;
            end
            COL_SHIFT  : begin 
                o_col_reg_write <= 1'b1;
                o_col_reg_data <= 1'b0;
            end
            DONE        : o_done <= 1'b1;
            default     : begin
                o_col_reg_write <= 1'b0;
                o_row_reg_write <= 1'b0;
                o_col_reg_data <= 1'b0;
                o_row_reg_data <= 1'b0;
                o_key_write <= 1'b0;
                o_row_ena <= 1'b0; 
                o_row_rst <= 1'b0;
                o_col_rst <= 1'b0;
                o_done <= 1'b0;
            end
        endcase
    end



endmodule


`endif /* RESET_FSM_V */