`timescale 1ns / 1ps


module tb_amp_config();

    parameter N_BITS = 6;
    time PERIOD = 10;

    reg [N_BITS-1 : 0] amp_value;
    reg clk;     
    reg go;      
    reg rst;     
    
    wire amp_clk  ;
    wire amp_data ;
    wire amp_en   ;
    wire amp_nrst ;
    wire done     ;

    amp_config #(
        .NB_DIVIDER(24)
    ) uut (
        .clk ( clk ),
        .rst ( rst ),
        .i_go ( go ),
        .i_amp_value ( amp_value ),
        .i_clk_div  (24'b1000),
        .o_amp_clk  (amp_clk  ),
        .o_amp_data (amp_data ),
        .o_amp_en   (amp_en   ),
        .o_amp_nrst (amp_nrst ),
        .o_done     (done     )
    );

    //Clock process
    initial clk = 1'b1;
    always #(PERIOD/2) clk = ~clk;

    /* Initial Reset */
    initial begin
        rst = 1'b1; 
        #(3*PERIOD/2) rst = 1'b0;
    end

    initial begin
        amp_value = 6'b100110;
        go = 1'b0;
        @(negedge rst);
        #(5);
        go = 1'b1;

        @(posedge clk)

        go = 1'b0;
        #(10000000*PERIOD);
        

        $finish();
    end

endmodule;


