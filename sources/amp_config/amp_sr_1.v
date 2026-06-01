`ifndef AMP_SR
`define AMP_SR

module amp_sr #(
    parameter N_BITS = 6
)    
(
    input clk,
    input rst,
    input i_en,
    input i_ld,
    input [N_BITS-1:0] i_val,

    output o_data,
    output o_shift_done
);

reg [N_BITS-1:0] data;
reg [$clog2(N_BITS)-1:0] cnt;

// SHIFT REGISTER
always @(posedge clk ) begin
    if (rst) begin
        data <= {(N_BITS-1){1'b0}};
    end else if(i_ld) begin
        data <= i_val;
    end else if(i_en) begin
        if(cnt != 0) begin
            data <= {data[N_BITS-2:0], 1'b0};
        end
    end
end

assign o_data = data[N_BITS-1];

// COUNTER
always @(posedge clk) begin
    if(rst) begin
        cnt <= {$clog2(N_BITS){1'b0}};
    end else if(i_ld) begin
        cnt <= N_BITS-1;
    end else if (i_en) begin
        if(cnt != 0) begin
            cnt <= cnt - 1;
        end
    end
end

assign o_shift_done = ~|(cnt);

endmodule


`endif /* AMP_SR */
