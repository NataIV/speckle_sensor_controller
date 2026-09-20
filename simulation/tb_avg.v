`timescale 1ns / 1ps


module tb_avg();

    parameter N_BITS = 6;
    time PERIOD = 10;

    reg clk;     
    reg rst;     
    reg i_start;
    reg i_eoc  ;
    reg [2:0]i_size;
    reg [11:0] i_data ;
    wire o_done ;
    wire o_trig ;
    wire [11:0] o_data ;

    avg#(
        .NB_DATA ( 12 )
    )u_avg(
        .clk     ( clk     ),
        .rst     ( rst     ),
        .i_start ( i_start ),
        .i_eoc   ( i_eoc   ),
        .i_size ( i_size ),
        .i_data  ( i_data  ),
        .o_done  ( o_done  ),
        .o_trig  ( o_trig  ),
        .o_data  ( o_data  )
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
        i_start = 0;
        i_size = 7;
        @(negedge rst);
        #(5);
        @(posedge clk)
        
        i_start = 1'b1;
        @(posedge clk)
        i_start = 1'b0;



        while (!o_done) @(posedge clk);
        

        

        $finish();
    end


    //Simulo el valor del ADC con ruido al rededor del valor 2048
    integer ruido;
    localparam Pr = 250;

    always @(posedge clk) begin
        if (rst) begin
            i_eoc <= 1'b0;
            i_data <= 12'd0;
        end else if (o_trig) begin
            i_eoc <= 1'b0;
            #(6*PERIOD)
            ruido =
            $urandom_range(-Pr,Pr)
            + $urandom_range(-Pr,Pr)
            + $urandom_range(-Pr,Pr)
            + $urandom_range(-Pr,Pr);

            i_data <= 2048 + ruido;
            i_eoc <= 1'b1;
        end
    end

endmodule


