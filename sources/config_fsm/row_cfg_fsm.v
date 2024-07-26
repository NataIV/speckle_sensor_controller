`ifndef ROW_CFG_FSM_V
`define ROW_CFG_FSM_V

module row_cfg_fsm(
    input  wire clk,
    input  wire rst,
    input  wire i_go,
    input  wire i_pixel_valid, 
    input  wire i_overflow,
    input  wire i_write_done,
    input  wire i_key_write_done,

    /* Salidas de Moore */
    output wire o_mem_read,
    output wire o_row_reload,
    output wire o_row_dec,
    output wire o_row_offset,
    output wire o_row_wren,
    output wire o_row_val,
    output wire o_key_wren,
    output wire o_done
);
    
    reg [3:0] state;
    reg [3:0] next_state;

    localparam 
        IDLE            =  0,
        ROW_RELOAD      =  1,
        ROW_ENDS_CHECK  =  2,
        CMP_PIX_1       =  3,
        CMP_PIX_2       =  4,
        WRITE_0         =  5,
        WRITE_1         =  6,
        ROW_DEC         =  7,
        WAIT_ROW_IDLE   =  8,
        KEY_WREN        =  9,
        DONE            =  10,
        RAM_READ_PIX_1_CYC1  =  11,
        RAM_READ_PIX_1_CYC2  =  12,
        RAM_READ_PIX_2_CYC1  =  13,
        RAM_READ_PIX_2_CYC2  =  14,
        WAIT_WRITE_DONE =  15;


    always @(posedge clk or posedge rst) begin
        if(rst)
            state <= 4'b0000;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)
        IDLE           : next_state <= i_go ? ROW_RELOAD : IDLE;
        ROW_RELOAD     : next_state <= ROW_ENDS_CHECK;
        ROW_ENDS_CHECK : next_state <= i_overflow ? WAIT_ROW_IDLE : WAIT_WRITE_DONE;
        WAIT_WRITE_DONE: next_state <= i_write_done? RAM_READ_PIX_1_CYC1 : WAIT_WRITE_DONE;
        RAM_READ_PIX_1_CYC1 : next_state <= RAM_READ_PIX_1_CYC2;
        RAM_READ_PIX_1_CYC2 : next_state <= CMP_PIX_1;
        CMP_PIX_1      : next_state <= i_pixel_valid ? RAM_READ_PIX_2_CYC1 : WRITE_0;
        RAM_READ_PIX_2_CYC1 : next_state <= RAM_READ_PIX_2_CYC2;//RAM_READ_PIX_2_CYC2;
        RAM_READ_PIX_2_CYC2 : next_state <= CMP_PIX_2;
        CMP_PIX_2      : next_state <= i_pixel_valid ? WRITE_1 : WRITE_0;
        WRITE_0        : next_state <= ROW_DEC;
        WRITE_1        : next_state <= ROW_DEC;
        ROW_DEC        : next_state <= ROW_ENDS_CHECK;
        WAIT_ROW_IDLE  : next_state <= i_write_done ? KEY_WREN : WAIT_ROW_IDLE;
        KEY_WREN       : next_state <= i_key_write_done ? DONE : KEY_WREN;
        //KEY_WREN       : next_state <= KEY_WAIT;
        //KEY_WAIT       : next_state <= i_key_write_done ? DONE : KEY_WAIT;
        DONE           : next_state <= IDLE;
        default        : next_state <= IDLE;
        endcase
    end

/* SALIDAS */
    assign o_done       = (state == DONE);

    assign o_mem_read   = (state == RAM_READ_PIX_1_CYC1) || (state == RAM_READ_PIX_1_CYC2) || (state == RAM_READ_PIX_2_CYC1) || (state == RAM_READ_PIX_2_CYC2);
    assign o_row_offset = (state == RAM_READ_PIX_2_CYC1) || (state == RAM_READ_PIX_2_CYC2) || (state == CMP_PIX_2);
    assign o_row_reload = (state == ROW_RELOAD);
    assign o_row_dec    = (state == ROW_DEC);
    assign o_row_wren   = (state == WRITE_0) || (state == WRITE_1);
    assign o_row_val    = (state == WRITE_1);

    assign o_key_wren   = (state == WAIT_ROW_IDLE) && i_write_done;
    
endmodule

`endif /* ROW_CFG_FSM_V */