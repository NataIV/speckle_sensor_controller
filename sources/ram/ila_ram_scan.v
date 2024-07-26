`ifndef ILA_RAM_SCAN_H
`define ILA_RAM_SCAN_H
module ila_ram_scan (
    input clk,
    input rst,
    input i_start_scan,
    output [9:0] o_ram_addr,
    output o_ram_dbg
);

localparam
    IDLE    = 0,
    DELAY_1 = 1,
    DELAY_2 = 2,
    READ    = 3;


    reg [3:0] state, nextState;
    reg [9:0] addr;

always @(posedge clk ) begin
    if(rst)begin
        state <= IDLE;
    end
    else
        state <= nextState;
end

always@(*)begin
    nextState = 4'b0;

    case (state)
        IDLE: begin
            if(i_start_scan) nextState = DELAY_1;
            else             nextState = IDLE;
        end
        DELAY_1: begin
            nextState = DELAY_2;
        end
        DELAY_2: begin
            nextState = READ;
        end
        READ: begin
            if(addr >= 576)  nextState = IDLE;
            else             nextState = READ;
        end
        default: nextState = IDLE;
    endcase

    // if(state[IDLE] & i_start_scan)begin
    //     nextState = 1<<DELAY_1;
    // end
    // else if (state[DELAY_1]) begin
    //     nextState = 1<<DELAY_2;
    // end
    // else if (state[DELAY_1]) begin
    //     nextState = 1<<READ;
    // end
    // else if (state[READ]) begin
    //     if(addr >= 576) begin
    //         nextState = 1<<IDLE;
    //     end else begin
    //         nextState = 1<<READ; 
    //     end
    // end
    // else begin
    //     nextState = 1<<IDLE;
    // end
end

// Contador 
always @(posedge clk) begin
    if(state != READ) begin
        addr <= 10'b00_0000_0000;
    end else begin
        addr <= addr + 1;
    end
end

assign o_ram_addr = addr;
assign o_ram_dbg = (state != IDLE);



endmodule
`endif 