`ifndef CFG_FSM_V
`define CFG_FSM_V

`include "../counter_offset/counter_offset.v"
`include "row_cfg_fsm.v"

module cfg_fsm #(
    parameter NB_DATA = 12
) (
    input        clk,
    input        rst,
    input        i_go,
    input        i_chip_write_ready,
    input  [NB_DATA-1 : 0] i_umbral,

    // RAM
    input  [NB_DATA-1 : 0] i_ram_data, 
    output                 o_ram_read,
    input                  i_row_overflow,
    input                  i_col_overflow,
    input                  i_col_is_even,
    output reg [4:0]       o_row_control,
    output reg [4:0]       o_col_control,

    // To the chip
    output o_row_reg_data,
    output o_row_reg_write,

    output o_col_reg_data,
    output o_col_reg_write,

    output o_key_wren,
    
    output o_done
);

    localparam 
        IDLE          =  0,
        COL_WRITE_1   =  1,
        ARL_CONFIG    =  2,
        NE_CONFIG     =  3,
        SE_CONFIG     =  4,
        WW_CONFIG     =  5,
        COL_INCREMENT =  6,
        COL_CHECK_END =  7,
        DONE          =  8;


    wire fsm_row_dec;
    wire fsm_row_offset;
    wire fsm_row_done;
    wire fsm_row_reload;
    wire fsm_pixel_valid;
    wire fsm_row_go;
    wire pixel_is_in_bound;

    assign pixel_is_in_bound = ~(i_row_overflow || i_col_overflow);
    assign fsm_pixel_valid = (i_ram_data >= i_umbral) && pixel_is_in_bound;

    /* FSM PARA CONFIGURAR CADA FILA */
    row_cfg_fsm u_row_cfg_fsm(
        .clk           ( clk            ),
        .rst           ( rst            ),
        .i_go          ( fsm_row_go     ),
        .i_pixel_valid ( fsm_pixel_valid),
        .i_overflow    ( i_row_overflow ),
        .i_write_done  ( i_chip_write_ready ),
        .i_key_write_done( i_chip_write_ready),
        .o_done        ( fsm_row_done   ),
        .o_mem_read    ( o_ram_read     ),
        .o_row_reload  ( fsm_row_reload ),
        .o_row_dec     ( fsm_row_dec    ),
        .o_row_offset  ( fsm_row_offset ),
        .o_row_wren    ( o_row_reg_write),
        .o_row_val     ( o_row_reg_data ),
        .o_key_wren    ( o_key_wren     )
    );

    reg [3:0] state;
    reg [3:0] next_state;

    always @(posedge clk or posedge rst) begin
        if(rst)
            state <= 4'b0000;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)
        IDLE:          next_state <= i_go ? COL_WRITE_1 : IDLE; 

        COL_WRITE_1  : next_state <= (i_chip_write_ready) ? NE_CONFIG : COL_WRITE_1;

        ARL_CONFIG   : next_state <= fsm_row_done ? NE_CONFIG : ARL_CONFIG;
        NE_CONFIG    : next_state <= fsm_row_done ? SE_CONFIG : NE_CONFIG ;
        SE_CONFIG    : next_state <= fsm_row_done ? WW_CONFIG : SE_CONFIG ;
        WW_CONFIG    : next_state <= fsm_row_done ? COL_INCREMENT : WW_CONFIG ;


        COL_INCREMENT: next_state <= COL_CHECK_END;
        COL_CHECK_END: next_state <= i_col_overflow ? DONE : (i_col_is_even ?  NE_CONFIG : ARL_CONFIG);
        DONE:          next_state <= IDLE;
        default:       next_state <= IDLE;
        endcase
    end


/* SALIDAS */
    assign o_col_reg_data  = (state == COL_WRITE_1);
    assign o_col_reg_write = (state == COL_WRITE_1) || (fsm_row_done);
 
    assign o_done = (state == DONE);
    assign fsm_row_go = (state == ARL_CONFIG) || (state == NE_CONFIG) || (state == SE_CONFIG) || (state == WW_CONFIG);

    /* CONTROL DEL INDICE DE LA MEMORIA RAM */
    always @(*) begin
        o_col_control[`COUNTER_RESET_BIT]   = (state == COL_WRITE_1);
        o_col_control[`COUNTER_LOADMAX_BIT] = 1'b0;
        o_row_control[`COUNTER_RESET_BIT]   = 1'b0;
        o_row_control[`COUNTER_LOADMAX_BIT] = fsm_row_reload;
    end

    always @(*) begin
        case (state)
            ARL_CONFIG: begin
                if(fsm_row_dec)begin
                    o_col_control[2:0] = `COUNTER_NO_CHANGE;
                    o_row_control[2:0] = `COUNTER_ENABLE | `COUNTER_DEC_1;
                end else begin
                    o_col_control[2:0] = `COUNTER_NO_CHANGE;
                    o_row_control[2:0] = `COUNTER_NO_CHANGE;
                end
            end
            NE_CONFIG: begin
                if(fsm_row_dec)begin
                    o_col_control[2:0] = `COUNTER_NO_CHANGE;
                    o_row_control[2:0] = `COUNTER_ENABLE | `COUNTER_DEC_1;
                end else if (fsm_row_offset) begin
                    o_col_control[2:0] = `COUNTER_NO_CHANGE;
                    o_row_control[2:0] = `COUNTER_INC_1;
                end else begin
                    o_col_control[2:0] = `COUNTER_NO_CHANGE;
                    o_row_control[2:0] = `COUNTER_NO_CHANGE;
                end
            end
            SE_CONFIG: begin
                if(fsm_row_dec)begin
                    o_col_control[2:0] = `COUNTER_NO_CHANGE;
                    o_row_control[2:0] = `COUNTER_ENABLE | `COUNTER_DEC_1;
                end else if (fsm_row_offset) begin
                    o_col_control[2:0] = `COUNTER_DEC_1;
                    o_row_control[2:0] = `COUNTER_DEC_1;
                end else begin
                    o_col_control[2:0] = `COUNTER_NO_CHANGE;
                    o_row_control[2:0] = `COUNTER_NO_CHANGE;
                end
            end
            WW_CONFIG: begin
                if(fsm_row_dec)begin
                    o_col_control[2:0] = `COUNTER_NO_CHANGE;
                    o_row_control[2:0] = `COUNTER_ENABLE | `COUNTER_DEC_1;
                end else if (fsm_row_offset) begin
                    o_col_control[2:0] = `COUNTER_INC_1;
                    o_row_control[2:0] = `COUNTER_NO_CHANGE;
                end else begin
                    o_col_control[2:0] = `COUNTER_NO_CHANGE;
                    o_row_control[2:0] = `COUNTER_NO_CHANGE;
                end
            end
            COL_INCREMENT:begin
                o_col_control[2:0] = `COUNTER_ENABLE | `COUNTER_INC_1;
                o_row_control[2:0] = `COUNTER_NO_CHANGE;
            end
            default: begin
                o_col_control[2:0] = `COUNTER_NO_CHANGE;
                o_row_control[2:0] = `COUNTER_NO_CHANGE;
            end
        endcase
    end

endmodule

`endif /* CFG_FSM_V */