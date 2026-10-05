`ifndef RESET_FSM_V
`define RESET_FSM_V

module reset_fsm #(
    parameter NB_DATA = 12
) (
    input        clk,
    input        rst,
    input        i_start,
    input        i_chip_write_ready,

    // Al chip
    output reg o_row_reg_data,
    output reg o_row_reg_write,

    output reg o_col_reg_data,
    output reg o_col_reg_write,

    output reg o_key_wren,
    
    output reg o_done
);


// Contadores
    reg [7:0] col;
    reg [7:0] row;
    
// Maquina de estados
    localparam 
        IDLE          =  0,
        COL_WAIT      =  1,
        COL_WRITE     =  2,
        INC_COL       =  3,
        ROW_WAIT      =  4,
        ROW_WRITE     =  5,
        INC_ROW       =  6,
        KEY_ENABLE    =  7,
        DONE          =  8;

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
        IDLE        :   if(i_start) next = COL_WRITE; 
        COL_WAIT    :   if (i_chip_write_ready) next = COL_WRITE;
        COL_WRITE   :   next = INC_COL;
        INC_COL     :   if (col > 81) next = ROW_WRITE; 
                        else  next = COL_WAIT;
        ROW_WAIT    :   if (i_chip_write_ready) next =  ROW_WRITE;
        ROW_WRITE   :   next = INC_ROW;
        INC_ROW     :   if (row > 24) next = KEY_ENABLE;
                        else  next = ROW_WAIT;
        KEY_ENABLE  :   if (i_chip_write_ready) next = DONE;

        DONE        :   next = IDLE;
        default     :    next = IDLE;
        endcase
    end

// Salidas
    always @(posedge clk) begin
        o_col_reg_write <= 1'b0;
        o_row_reg_write <= 1'b0;
        o_col_reg_data <= 1'b0;
        o_row_reg_data <= 1'b0;
        o_done <= 1'b0;

        case (next)
            IDLE : begin
                col <= 0;
                row <= 0;
            end
            COL_WRITE   : begin 
                o_col_reg_write <= 1'b1;
                o_col_reg_data <= 1'b1;
            end
            INC_COL : begin
                col <= col + 1;
            end
            ROW_WRITE   : begin
                o_row_reg_write <= 1'b1;
                o_row_reg_data <= 1'b0;
                end 
                
            INC_ROW : begin
                row <= row + 1;
            end
            KEY_ENABLE  : o_key_wren <= 1'b0;
            DONE        : o_done <= 1'b1;
            default     : begin
                o_col_reg_write <= 1'b0;
                o_row_reg_write <= 1'b0;
                o_col_reg_data <= 1'b0;
                o_row_reg_data <= 1'b0;
                o_done <= 1'b0;
            end
        endcase
    end



endmodule


`endif /* RESET_FSM_V */