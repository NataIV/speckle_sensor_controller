`ifndef SHIFT_REGISTER_H
`define SHIFT_REGISTER_H
module shift_register #(
    NB_REG = 32
) 
(
    input clk, rst, en, load,
    input [NB_REG-1 : 0] value,

    output o_data,
    output o_done
);
    wire c_run;
    reg [$clog2(NB_REG) : 0] c;
    reg [NB_REG-1 : 0] d;
    
    // Counter
    always @(posedge clk or posedge rst) begin
        if(rst)begin
            c <= {$clog2(NB_REG) {1'b0}};
        end else begin
            if (load) begin
                c <= {$clog2(NB_REG) {1'b0}};
            end else if (en && c_run) begin
                c <= c + 1;
            end
        end 
    end
    
    // Shift register
    always @(posedge clk or posedge rst) begin
        if(rst)begin
            d <= {NB_REG {1'b0}};
        end else begin
            if (load) begin
                d <= value;
            end else if (en) begin
                d <= d << 1;
            end
        end
    end

    assign c_run = (c < (NB_REG - 1));
    assign o_done = ~(c_run);
    assign o_data = d[NB_REG-1];

endmodule

`endif