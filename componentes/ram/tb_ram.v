`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.12.2023 19:54:13
// Design Name: 
// Module Name: tb_ram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module tb_ram( );

    localparam RAM_WIDTH = 10;
    localparam RAM_DEPTH = 576;

    time PERIOD = 10;

    reg [$clog2(RAM_DEPTH)-1 : 0] addr;    // Address bus, width determined from RAM_DEPTH
    reg [RAM_WIDTH-1 : 0] din;     // RAM input data, width determined from RAM_WIDTH
    reg clk;     // Clock
    reg we;      // Write enable
    reg en;      // RAM Enable, for additional power savings, disable port when not in use
    reg rst;     // Output reset (does not affect memory contents)
    reg regce;   // Output register enable
    wire [RAM_WIDTH-1 : 0] dout;    // RAM output data, width determined from RAM_WIDTH

    integer i; 

    xilinx_single_port_ram_no_change #(
        .RAM_WIDTH(RAM_WIDTH),                       // Specify RAM data width
        .RAM_DEPTH(RAM_DEPTH),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),      // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE("init.mem")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) your_instance_name (
        .addra(addr),    // Address bus, width determined from RAM_DEPTH
        .dina(din),      // RAM input data, width determined from RAM_WIDTH
        .clka(clk),      // Clock
        .wea(we),        // Write enable
        .ena(en),        // RAM Enable, for additional power savings, disable port when not in use
        .rsta(rst),      // Output reset (does not affect memory contents)
        .regcea(regce),  // Output register enable
        .douta(dout)     // RAM output data, width determined from RAM_WIDTH
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
        regce = 1'b1;
        en = 1'b1; 
        we = 1'b0;
        din = 10'h000;
        addr = 0;
        @(negedge rst);
        #(PERIOD/2);

        
        for (i = 0; i<576; i = i + 1'b1) begin
            addr = i;
            #(PERIOD);
        end

        $finish();
    end

endmodule
