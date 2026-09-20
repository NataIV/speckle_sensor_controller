module uart #(
    parameter BRG_VAL =  5208 //para 9600 bps con un clock base de 50Mhz
    )(	
    input clk,
    input rst,
    // TX 
    input tx_en,
    input tx_init,
    input [7:0] tx_data,
    output tx_out,
    output reg tx_empty,
    output reg tx_over_run,
    // RX
    input rx_en,
    input rx_in,
    input rx_read,
    output reg [7:0] rx_data,
    output reg rx_rdy,
    output reg rx_busy,
    output reg rx_frame_err
);

    // BRG TX

    reg [15:0] tx_brg_reg;
    reg tx_clk;

    always @(posedge clk) begin
        if (tx_empty) begin
            tx_brg_reg <= BRG_VAL-1;
            tx_clk <= 1'b0;
        end else begin
            if (tx_brg_reg)begin
                tx_brg_reg <= tx_brg_reg - 1'b1;
                tx_clk <= 1'b0;
            end else begin
                tx_brg_reg <= BRG_VAL-1;
                tx_clk <= 1'b1;
            end
        end
    end

    // TX

    reg [9:0] tx_reg;
    reg [3:0] tx_cnt;
  
    always@(posedge clk or posedge rst)begin
        if(rst) begin
            tx_empty <= 1'b1;
            tx_over_run <= 1'b0;
            tx_cnt <= 4'b0000;
            tx_reg <= 10'b1111111111;
        end else begin
            if (tx_init) begin
                if(!tx_empty)begin 
                    tx_over_run <= 1'b1;
                end else begin
                    tx_reg <= {1'b1,tx_data[7:0],1'b0};
                    tx_empty <= 1'b0;
                    tx_cnt <= 10;
                end
            end else if(!tx_empty & tx_clk) begin
                if(!tx_cnt)begin
                    tx_empty <= 1'b1;
                end else begin
                    tx_reg <= {1'b1, tx_reg[9:1]};
                    tx_cnt = tx_cnt - 1;
                end
        end
        end
    end
    
assign tx_out = tx_reg[0];



    // RX BRG
    reg [15:0] rx_brg_reg;
    reg rx_clk;

    always @(posedge clk) begin
        if (!rx_busy) begin
            rx_brg_reg <= (BRG_VAL-1)>>1;
            rx_clk <= 1'b0;
        end else begin
            if (rx_brg_reg)begin
                rx_brg_reg <= rx_brg_reg - 1'b1;
                rx_clk <= 1'b0;
            end else begin
                rx_brg_reg <= BRG_VAL-1;
                rx_clk <= 1'b1;
            end
        end
    end

    // RX
    reg [8:0] rx_reg;
    reg [3:0] rx_cnt;

    always @(posedge clk or posedge rst) begin
        if(rst)begin
            rx_data <= 8'b000000000;
            rx_reg  <= 8'b000000000;
            rx_cnt <= 4'b0000;
            rx_frame_err <= 1'b0;
            rx_busy <= 1'b0;
            rx_rdy <= 1'b0;
        end else if(rx_en) begin
            rx_rdy <= 1'b0;
            if(rx_busy)begin
                if(rx_clk)begin
                    if(rx_cnt)begin
                        rx_reg <= {rx_in, rx_reg[8:1]};
                        rx_cnt  <= rx_cnt - 1;
                    end else begin
                        rx_data <= rx_reg[8:1];
                        rx_frame_err <= rx_reg[0] | ~rx_in;
                        rx_busy <= 1'b0;
                        rx_rdy <= 1'b1;
                    end
                end
            end else if (!rx_in) begin
                rx_cnt <= 9;
                rx_busy <= 1'b1;
            end
        end
    end


  
endmodule