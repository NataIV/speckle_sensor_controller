`ifndef TOP_FSM_H
`define TOP_FSM_H
// FSM para administrar la ejecucion de las demas FSM

module top_fsm
(
    input   clk,
    input   rst,
    input   i_select_scan,
    input   i_select_config,
    input   i_start,
    input   i_scan_done,
    input   i_cfg_done,
    input   i_process_done,
    input   i_rst_chip_done,
    output  reg o_rst_chip_go,
    output  reg o_scan_go,    
    output  reg o_process_go,
    output  reg o_cfg_go,
    output  reg o_done
);

    reg  [2:0] state, next;

    // Salidas
    localparam 
        IDLE        = 0,
        RESET       = 1,
        SCAN        = 2,
        PROCESS     = 3,
        CONF        = 4,
        DONE        = 5;
        

    always @(posedge clk) begin
        if (rst) 
            state <= IDLE;
        else 
            state <= next;
    end

    // Next state logic
    always @(*) begin
        next = state;
        case (state)
            IDLE:       if(i_start & i_select_scan)         next = RESET;
                        else if(i_start & i_select_config)  next = PROCESS;
            RESET:      if(i_rst_chip_done)                 next = SCAN;
            SCAN:       if(i_scan_done & i_select_config)   next = PROCESS;
                        else if (i_scan_done)               next = DONE;
            PROCESS:    if(i_process_done)                  next = CONF;
            CONF:       if(i_cfg_done)                      next = DONE;
            DONE:                                           next = IDLE;
            default:                                        next = IDLE;
        endcase
    end

    // Output logic (MOORE)
    always @(posedge clk) begin
        o_done          <= 1'b0;
        o_scan_go       <= 1'b0;
        o_process_go    <= 1'b0;
        o_cfg_go        <= 1'b0;
        o_rst_chip_go   <= 1'b0;
        case (next)
            RESET:      o_rst_chip_go   <= 1'b1;
            SCAN:       o_scan_go       <= 1'b1;
            PROCESS:    o_process_go    <= 1'b1;
            CONF:       o_cfg_go        <= 1'b1;
            DONE:       o_done          <= 1'b1;
            default: begin
                o_done          <= 1'b0;
                o_scan_go       <= 1'b0;
                o_process_go    <= 1'b0;
                o_cfg_go        <= 1'b0;
                o_rst_chip_go   <= 1'b0;
            end
        endcase
    end

endmodule

`endif