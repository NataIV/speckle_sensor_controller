`timescale 1ns / 1ps


module tb_sr_amp( );

    parameter N_BITS = 6;
    time PERIOD = 10;

    reg [N_BITS-1 : 0] data;
    reg clk;     
    reg en;      
    reg ld;
    reg rst;     

    wire bit_out;
    wire shift_end;

    amp_sr#(N_BITS) uut (clk, rst, en, ld, data, bit_out, shift_end);

    //Clock process
    initial clk = 1'b1;
    always #(PERIOD/2) clk = ~clk;

    /* Initial Reset */
    initial begin
        rst = 1'b1; 
        #(3*PERIOD/2) rst = 1'b0;
    end

    initial begin
        data = 0;    
        en = 0;      
        ld = 0;
        @(negedge rst);
        #(PERIOD/2);

        data = 6'b110001;
        en = 1;
        ld = 1;

        @(posedge clk)
        en = 1;
        ld = 0;

        #(32*PERIOD);
        

        $finish();
    end

endmodule
