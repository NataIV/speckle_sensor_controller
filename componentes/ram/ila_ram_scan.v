module ila_ram_scan (
    input clk,
    input rst,
    input i_start_scan,
    input [11:0] i_ram_data,
    output [9:0] o_ram_addr,
    output o_ram_dbg
);

localparam
    IDLE    = 0,
    DELAY_1 = 1,
    DELAY_2 = 2,
    READ    = 3;


    reg [3:0] state, stateNext;
    reg [9:0] addr;

always @(posedge clk ) begin
    if(rst)begin
        state <= IDLE;
    end
    else
        state <= stateNext;
end

always@(*)begin
    if(state[IDLE] & i_start_scan)begin
        stateNext = 1<<DELAY_1;
    end
    else if (state[DELAY_1]) begin
        stateNext = 1<<DELAY_2;
    end
    else if (state[DELAY_1]) begin
        stateNext = 1<<READ;
    end
    else if (state[READ]) begin
        if(addr >= 576) begin
            stateNext = 1<<IDLE;
        end else begin
            stateNext = 1<<READ; 
        end
    end
    else begin
        stateNext = 1<<IDLE;
    end
end

// Contador 
always @(posedge clk) begin
    if(!state[READ]) begin
        addr <= 10'b00_0000_0000;
    end else begin
        addr <= addr + 1;
    end
end

assign o_ram_addr = addr;
assign o_ram_dbg = state[DELAY_1] || state[DELAY_2] || state[READ];

ila_bram_debug u_ila (   
    .clk(clk),
    .data(i_ram_data),
    .trigger(state[READ])
);

endmodule