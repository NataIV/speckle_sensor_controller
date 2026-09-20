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
    output o_row_reg_data,
    output o_row_reg_write,

    output o_col_reg_data,
    output o_col_reg_write,

    output o_key_wren,
    
    output o_done
);


// Contadores
    reg [5:0] col;
    reg [5:0] row;
    reg col_rst;
    reg col_ena;
    reg row_rst;
    reg row_ena;
    

    always @(posedge clk) begin
        if (cnt_col_rst) begin
            col <= 0;
        end else if(cnt_col_ena) begin
            col <= col + 1;
        end
    end

    always @(posedge clk) begin
        if (cnt_row_rst) begin
            row <= 0;
        end else if(cnt_row_ena) begin
            row <= row + 1;
        end
    end

// Maquina de estados
    localparam 
        IDLE          =  0,
        COL_WRITE     =  1,
        INC_CNT_COL   =  2,
        ROW_WRITE     =  3,
        INC_CNT_ROW   =  4,
        KEY_ENABLE    =  5,
        DONE          =  6;

// Registros        
    reg [3:0] state;
    reg [3:0] next_state;

    always @(posedge clk or posedge rst) begin
        if(rst)
            state <= 4'b0000;
        else
            state <= next_state;
    end
// Logica de estado siguientes
    always @(*) begin
        case (state)
        IDLE        : next_state <= i_start ? COL_WRITE : IDLE; 
        
        COL_WAIT    : next_state <= (i_chip_write_ready) ? COL_WRITE : COL_WAIT;
        COL_WRITE   : next_state <= INC_COL;
        INC_COL     : next_state <= (col > 81) ? ROW_WRITE : COL_WAIT;
        

        ROW_WAIT    : next_state <= (i_chip_write_ready) ? ROW_WRITE : ROW_WAIT;
        ROW_WRITE   : next_state <= INC_ROW;
        INC_COL     : next_state <= (row > 24) ? ROW_WRITE : ROW_WAIT;

        KEY_ENABLE  : next_state <= (i_chip_write_ready) ? DONE : KEY_ENABLE;

        DONE        : next_state <= IDLE;
        default     : next_state <= IDLE;
        endcase
    end
// Salidas
    always @(posedge clk) begin
        case (next_state)
            IDLE        : next_state <= i_start ? COL_WRITE : IDLE; 
            
            COL_WAIT    : next_state <= (i_chip_write_ready) ? COL_WRITE : COL_WAIT;
            COL_WRITE   : next_state <= INC_COL;
            INC_COL     : next_state <= (col > 81) ? ROW_WRITE : COL_WAIT;
            

            ROW_WAIT    : next_state <= (i_chip_write_ready) ? ROW_WRITE : ROW_WAIT;
            ROW_WRITE   : next_state <= INC_ROW;
            INC_COL     : next_state <= (row > 24) ? ROW_WRITE : ROW_WAIT;

            KEY_ENABLE  : next_state <= (i_chip_write_ready) ? DONE : KEY_ENABLE;

            DONE        : next_state <= IDLE;
            default     : next_state <= IDLE;
        endcase
    end

/* SALIDAS */
    assign o_col_reg_data  = (state == COL_WRITE_1);
    assign o_col_reg_write = (state == COL_WRITE_1) || (fsm_row_done);
 
    assign o_done = (state == DONE);
    assign fsm_row_go = (state == ARL_CONFIG) || (state == NE_CONFIG) || (state == SE_CONFIG) || (state == WW_CONFIG);


endmodule


`endif /* RESET_FSM_V */