module tb_uart();

    localparam SYSTEM_CLOCK_RATE = 4;
    localparam BAUD_RATE = 1;
    localparam PERIOD = 10;
    
    reg [7:0] msg [0:19];

    initial begin
        msg[0] = "H";
        msg[1] = "o";
        msg[2] = "l";
        msg[3] = "a";
        msg[4] = " ";
        msg[5] = "M";
        msg[6] = "u";
        msg[7] = "n";
        msg[8] = "d";
        msg[9] = "o";
        msg[10] = "!";
    end

    reg clk;
    reg rst;
    reg en;
    reg tx_init;
    reg [7:0] tx_data;
    wire tx_out;
    wire tx_empty;
    wire tx_over_run;

    
    wire [7:0] rx_data;
    wire rx_in;
    wire rx_rdy;
    wire rx_busy;
    wire rx_frame_err;
    
    
    uart #(8) uut (  
        .clk(clk),
        .rst(rst),
        // TX 
        .tx_en(en),
        .tx_init(tx_init),
        .tx_data(tx_data),
        .tx_out(tx_out),
        .tx_empty(tx_empty),
        .tx_over_run(tx_over_run),
        // RX
        .rx_en(en),
        .rx_in(rx_in),
        .rx_data(rx_data),
        .rx_rdy(rx_rdy),
        .rx_busy(rx_busy),
        .rx_frame_err(rx_frame_err)
    );
  
    assign rx_in    = tx_out;
    //Clock process
    initial clk = 1'b1;
    always #(PERIOD/2) clk = ~clk;

    /* Initial Reset */
    initial begin
        rst = 1'b1; 
        #(3*PERIOD/2) rst = 1'b0;
    end
  
    integer i;
    always begin
        rst <= 1'b1;
        en  <= 1'b0;
        #30
        rst <= 1'b0;
        en  <= 1'b1;
        #30
        for (i = 0; i < 11; i = i + 1) begin
            @(posedge clk);
            tx_data <= msg[i];
            tx_init <= 1'b1;
            @(posedge clk);
            tx_init <= 1'b0;
            @(posedge tx_empty);
        end

        $finish;
    end 
  
  
endmodule;