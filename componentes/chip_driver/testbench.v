`timescale 1ns / 1ps


module testbench();

    reg clk;        
    reg rst;        
    reg key_wr;     
    reg col_wr;     
    reg row_wr;     
    reg col_data;   
    reg row_data;   
    wire o_clk_col;  
    wire o_clk_row;  
    wire o_data_col; 
    wire o_data_row; 
    wire o_write_key;
    wire o_rdy;      

    initial clk <= 1'b0; always #10 clk <= ~clk;
    initial rst <= 1'b1; always #1 rst <= 1'b0;
    
    chip_driver uut (
        .clk         ( clk         ),
        .rst         ( rst         ),
        .i_write_key ( key_wr      ),
        .i_write_col ( col_wr      ),
        .i_write_row ( row_wr      ),
        .i_data_col  ( col_data    ),
        .i_data_row  ( row_data    ),
        .i_clk_div   ( 24'b100     ),
        .i_clk_div   ( 24'b1000    ),
        .o_clk_col   ( o_clk_col   ),
        .o_clk_row   ( o_clk_row   ),
        .o_data_col  ( o_data_col  ),
        .o_data_row  ( o_data_row  ),
        .o_write_key ( o_write_key ),
        .o_rdy       ( o_rdy       )
    );


    initial begin
        
        key_wr   = 1'b0;  
        col_wr   = 1'b0;  
        row_wr   = 1'b0;  
        col_data = 1'b0;  
        row_data = 1'b0; 
        
        @(negedge rst);
        key_wr   = 1'b0;  
        col_wr   = 1'b1;  
        row_wr   = 1'b0;  
        col_data = 1'b1;  
        row_data = 1'b0; 
        @(posedge clk);
        @(posedge clk);
        key_wr   = 1'b0;  
        col_wr   = 1'b0;  
        row_wr   = 1'b0;  
        col_data = 1'b0;  
        row_data = 1'b0; 
        
        @(posedge o_rdy);

        key_wr   = 1'b0;  
        col_wr   = 1'b0;  
        row_wr   = 1'b1;  
        col_data = 1'b0;  
        row_data = 1'b1; 
        @(posedge clk);
        @(posedge clk);
        key_wr   = 1'b0;  
        col_wr   = 1'b0;  
        row_wr   = 1'b0;  
        col_data = 1'b0;  
        row_data = 1'b0; 
        
        @(posedge o_rdy);


        key_wr   = 1'b1;  
        col_wr   = 1'b0;  
        row_wr   = 1'b0;  
        col_data = 1'b0;  
        row_data = 1'b0; 
        @(posedge clk);
        @(posedge clk);
        key_wr   = 1'b0;  
        col_wr   = 1'b0;  
        row_wr   = 1'b0;  
        col_data = 1'b0;  
        row_data = 1'b0; 
        
        @(posedge o_rdy);

        key_wr   = 1'b0;  
        col_wr   = 1'b1;  
        row_wr   = 1'b0;  
        col_data = 1'b0;  
        row_data = 1'b0; 
        @(posedge clk);
        @(posedge clk);
        key_wr   = 1'b0;  
        col_wr   = 1'b0;  
        row_wr   = 1'b0;  
        col_data = 1'b0;  
        row_data = 1'b0; 
        
        @(posedge o_rdy);

        key_wr   = 1'b0;  
        col_wr   = 1'b0;  
        row_wr   = 1'b1;  
        col_data = 1'b0;  
        row_data = 1'b0; 
        @(posedge clk);
        @(posedge clk);
        key_wr   = 1'b0;  
        col_wr   = 1'b0;  
        row_wr   = 1'b0;  
        col_data = 1'b0;  
        row_data = 1'b0; 
        
        @(posedge o_rdy);
        $finish();
    end


endmodule
