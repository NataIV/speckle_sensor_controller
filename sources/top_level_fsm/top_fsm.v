`ifndef TOP_FSM_H
`define TOP_FSM_H
// FSM para administrar los recursos compartidos entre las demas FSM

module top_fsm
(
    input  clk,
    input  rst,
    input  en,
    input  [2:0] i_select_mode,
    input  i_signal_start,
    input  i_signal_scan_end,
    input  i_signal_cfg_end,
    input  i_signal_process_end,

    // scan
    input [4:0] i_scan_col_control,
    input [4:0] i_scan_row_control,
    input i_scan_ram_wren,
    input [11:0] i_scan_ram_data,
    input i_scan_row_reg_data, 
    input i_scan_row_reg_write,  
    input i_scan_col_reg_data,  
    input i_scan_col_reg_write,  
    input i_scan_key_wren,
    input i_scan_row_rst,
    output reg o_scan_go,    
    
    // Process
    input  [4:0]  i_process_col_control,
    input  [4:0]  i_process_row_control,
    input         i_process_ram_wren,
    input  [11:0] i_process_ram_data,
    output reg o_process_go,

    // cfg
    input  [4:0] i_cfg_col_control,
    input  [4:0] i_cfg_row_control,
    input i_cfg_ram_read,
    input i_cfg_row_reg_data, 
    input i_cfg_row_reg_write,  
    input i_cfg_col_reg_data,  
    input i_cfg_col_reg_write,  
    input i_cfg_key_wren,     
    output reg o_cfg_go,

    // Control de los contadores para controlar la RAM
    output reg [4:0] o_col_control,
    output reg [4:0] o_row_control,

    // Control de la block ram
    output o_ram_read,
    output o_ram_wren,
    output o_ram_rsta,
    output o_ram_ena,
    output [11:0] o_ram_data,
    // Control de los drivers
    output reg o_chip_row_ena,
    output reg o_chip_col_rst,
    output o_row_reg_data,
    output o_row_reg_write,
    output o_col_reg_data ,
    output o_col_reg_write,
    output o_key_wren,
    output reg o_row_rst,
    output reg o_done
);

    reg  [2:0] state, next_state;
    reg  [2:0] sel_fsm;

    // Estados
    localparam 
        MODE_000    = 3'b000,     
        MODE_001    = 3'b001, // SCAN
        MODE_010    = 3'b010, // PROCESS (No elegible, solo accesible desde estado 011)
        MODE_011    = 3'b011, // SCAN -> PROCESS
        MODE_100    = 3'b100, // CONFIG
        MODE_101    = 3'b101, // PIXEL RESET (CONFIG con entrada en 0's)
        MODE_110    = 3'b110, // PROCESS -> CONFIG
        MODE_111    = 3'b111; // SCAN -> PROCESS -> CONFIG

    // Salidas
    localparam 
        IDLE        = 0,
        RESET       = 1,
        SCAN        = 2,
        PROCESS     = 3,
        CONF        = 4;
        

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= MODE_000;
        end
        else if (en) begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
        /* ESPERO SEÑAL DE INICIO  */
            MODE_000: begin 
                if(i_signal_start) begin
                    case (i_select_mode)
                        0: next_state = MODE_101;
                        1: next_state = MODE_101;
                        2: next_state = MODE_000;
                        3: next_state = MODE_101;
                        4: next_state = MODE_100;
                        5: next_state = MODE_000;
                        6: next_state = MODE_000;
                        7: next_state = MODE_101;
                        default: next_state = MODE_000;
                    endcase
                end else begin
                    next_state = MODE_000;
                end

                sel_fsm = IDLE;
            end
            /* SI VOY A ESCANEAR LOS PIXELES PRIMERO TENGO QUE REINICIAR LA MATRIZ DE PIXELES  */
            MODE_101: begin
                if(i_signal_cfg_end) begin
                    case (i_select_mode)
                        0: next_state = MODE_000;
                        1: next_state = MODE_001;
                        2: next_state = MODE_000;
                        3: next_state = MODE_011;
                        4: next_state = MODE_100;
                        5: next_state = MODE_000;
                        6: next_state = MODE_000;
                        7: next_state = MODE_111;
                        default: next_state = MODE_000;
                    endcase
                end else begin
                    next_state = MODE_101;
                end

                sel_fsm = RESET;
            end
            /* HAGO SOLO ESCANEO DE PIXELES  */
            MODE_001: begin
                if(i_signal_scan_end) begin
                    next_state = MODE_000;
                end else begin
                    next_state = MODE_001;
                end

                sel_fsm = SCAN;
            end
            MODE_010: begin
                if(i_signal_process_end) begin
                    next_state = MODE_000;
                end else begin
                    next_state = MODE_010;
                end

                sel_fsm = PROCESS;
            end
            MODE_011: begin
                if(i_signal_scan_end) begin
                    next_state = MODE_010;
                end else begin
                    next_state = MODE_011;
                end

                sel_fsm = SCAN;
            end
            MODE_100: begin
                if(i_signal_cfg_end) begin
                    next_state = MODE_000;
                end else begin
                    next_state = MODE_100;
                end

                sel_fsm = CONF;
            end
            MODE_110: begin
                if(i_signal_process_end) begin
                    next_state = MODE_100;
                end else begin
                    next_state = MODE_110;
                end

                sel_fsm = PROCESS;
            end
            MODE_111: begin
                if(i_signal_scan_end) begin
                    next_state = MODE_110;
                end else begin
                    next_state = MODE_111;
                end

                sel_fsm = SCAN;
            end
            
            default: begin
                next_state = MODE_000;

                sel_fsm = RESET;
            end
                
        endcase
    end

    // Output logic (MOORE)
    always @(*) begin
        case (sel_fsm)
            IDLE: begin
                o_col_control   = 5'b10000;
                o_row_control   = 5'b10000;
                o_chip_row_ena  = 1'b0;
                o_row_rst       = 1'b0;
                o_chip_col_rst  = 1'b1;
                o_done          = 1'b1;
                o_scan_go       = 1'b0;
                o_process_go    = 1'b0;
                o_cfg_go        = 1'b0;
            end
            RESET: begin
                o_col_control   = i_cfg_col_control  ;
                o_row_control   = i_cfg_row_control  ;
                o_chip_row_ena  = 1'b1               ;
                o_row_rst  = 1'b0               ;
                o_chip_col_rst  = 1'b0               ;
                o_done          = 1'b0               ;
                o_scan_go       = 1'b0;
                o_process_go    = 1'b0;
                o_cfg_go        = 1'b1;
            end
            SCAN: begin
                o_col_control   = i_scan_col_control  ;
                o_row_control   = i_scan_row_control  ;
                o_chip_row_ena  = 1'b1                ;
                o_row_rst  = i_scan_row_rst      ;
                o_chip_col_rst  = 1'b0                ;
                o_done          = 1'b0                ;
                o_scan_go       = 1'b1;
                o_process_go    = 1'b0;
                o_cfg_go        = 1'b0;
            end
            PROCESS: begin
                o_col_control   = i_process_col_control  ;
                o_row_control   = i_process_row_control  ;
                o_chip_row_ena  = 1'b0                   ;
                o_row_rst  = 1'b0                   ;
                o_chip_col_rst  = 1'b1                   ;
                o_done          = 1'b0                   ;
                o_scan_go       = 1'b0;
                o_process_go    = 1'b1;
                o_cfg_go        = 1'b0;
            end
            CONF: begin
                o_col_control   = i_cfg_col_control  ;
                o_row_control   = i_cfg_row_control  ;
                o_chip_row_ena  = 1'b1               ;
                o_row_rst  = 1'b0               ;
                o_chip_col_rst  = 1'b0               ;
                o_done          = 1'b0               ;
                o_scan_go       = 1'b0;
                o_process_go    = 1'b0;
                o_cfg_go        = 1'b1;
            end
            default: begin
                o_col_control   = 5'b10000;
                o_row_control   = 5'b10000;
                o_chip_row_ena  = 1'b0;
                o_row_rst  = 1'b1;
                o_chip_col_rst  = 1'b1;
                o_done          = 1'b0;
                o_scan_go       = 1'b0;
                o_process_go    = 1'b0;
                o_cfg_go        = 1'b0;
            end
        endcase
    end

    assign o_ram_read   = i_cfg_ram_read | (sel_fsm == PROCESS);
    assign o_ram_wren   = i_process_ram_wren | i_scan_ram_wren;
    assign o_ram_data   = (sel_fsm == PROCESS) ? i_process_ram_data : i_scan_ram_data;
    assign o_ram_rsta   = (sel_fsm == IDLE) | (sel_fsm == RESET);
    assign o_ram_ena    = (sel_fsm == CONF) | (sel_fsm == PROCESS) | (sel_fsm == SCAN);

    assign o_row_reg_data  = i_cfg_row_reg_data  | i_scan_row_reg_data ;
    assign o_row_reg_write = i_cfg_row_reg_write | i_scan_row_reg_write;
    assign o_col_reg_data  = i_cfg_col_reg_data  | i_scan_col_reg_data ;
    assign o_col_reg_write = i_cfg_col_reg_write | i_scan_col_reg_write;
    assign o_key_wren      = i_cfg_key_wren      | i_scan_key_wren     ;

    //OUTPUT LOGIC MEALY
    // assign o_scan_go    = (next_state ==  MODE_001) || (next_state ==  MODE_011) || (next_state ==  MODE_111);
    // assign o_process_go = (next_state ==  MODE_010) || (next_state ==  MODE_110);
    // assign o_cfg_go     = (next_state ==  MODE_100) || (next_state ==  MODE_101);

endmodule

`endif