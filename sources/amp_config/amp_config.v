module amp_config #(
    parameter NB_DIVIDER = 24
) (
    input        clk,
    input        rst,
    input        i_go,
    input [5:0]  i_amp_value,
    input [NB_DIVIDER-1 : 0] i_clk_div,
    // To the chip
    output o_amp_clk,
    output o_amp_data,
    output o_amp_en,
    output o_amp_nrst,
    output o_done
);

localparam 
    STATE_IDLE  = 0,
    STATE_LOAD  = 1,
    STATE_WRITE = 2,
    STATE_WAIT  = 3,
    STATE_SHIFT = 4,
    STATE_END   = 5;


reg [3:0] state, nextState;

reg [4:0] amp_cnt;
wire amp_next;

wire sr_en, sr_ld, sr_last_bit;
wire amp_write_start;
wire amp_data;
wire write_rdy;
wire sync;
wire sync_rst;



sync_write amp_sync_write(
    .clk     ( clk             ),
    .rst     ( rst             ),
    .i_write ( amp_write_start ),
    .i_data  ( amp_data        ),
    .i_sync  ( sync            ),
    .o_clk   ( o_amp_clk       ), 
    .o_data  ( o_amp_data      ),
    .o_ready ( write_rdy       )
);

clock_divider#(
    .NB_DIVIDER (NB_DIVIDER)
)u_clock_divider_amp(
    .i_clk     ( clk           ),
    .i_rst     ( sync_rst      ),
    .i_divider ( i_clk_div     ),
    .o_clk     ( sync          )
);

amp_sr #(
    .N_BITS ( 6 )
) u_amp_sr
(
    .clk            ( clk ),
    .rst            ( rst ),
    .i_en           ( sr_en ),
    .i_ld           ( sr_ld ),
    .i_val          ( i_amp_value ),
    .o_data         ( amp_data ),
    .o_shift_done   ( sr_last_bit )
);


// Contador de amplificadores restantes
always @(posedge clk) begin
    if(rst) amp_cnt <= 0; 
    else if (i_go && (state == STATE_IDLE)) amp_cnt <= 4'd12;
    else if (amp_next && amp_cnt) amp_cnt <= amp_cnt - 1; 
end


always @(posedge clk ) begin
    if (rst) begin
        state <= STATE_IDLE;
    end else begin
        state <= nextState;
    end
end

always @(*) begin
    case (state)
        STATE_IDLE: begin
            nextState <= (i_go) ? STATE_LOAD : STATE_IDLE;
        end
        STATE_LOAD: begin
            nextState <= STATE_WRITE;
        end
        STATE_WRITE: begin
            nextState <= STATE_WAIT;
        end
        STATE_WAIT: begin
            nextState <= (!write_rdy)  ? STATE_WAIT  : 
                        (!sr_last_bit) ? STATE_SHIFT :
                        (amp_cnt)      ? STATE_LOAD  :
                                         STATE_END   ;
        end
        STATE_SHIFT: begin
            nextState <= STATE_WRITE;
        end
        STATE_END: begin
            nextState <= (!i_go) ? STATE_IDLE : STATE_END;
        end
        default: begin
            nextState <= STATE_IDLE;
        end
    endcase
end

assign sync_rst = (state == STATE_IDLE);
assign sr_ld        = (state == STATE_LOAD);
assign sr_en        = (state == STATE_SHIFT);
assign amp_next     = (nextState == STATE_LOAD);
assign amp_write_start  = (state == STATE_WRITE);

assign o_amp_en     = (state != STATE_IDLE);
assign o_amp_nrst   = 1'b1; 
assign o_done       = (state == STATE_END);

endmodule


// module amp_config #(
//     parameter NB_DIVIDER = 4
// ) (
//     input        clk,
//     input        rst,
//     input        i_go,
//     input [5:0]  i_amp_value,
//     input [23:0] i_clk_div,
//     // To the chip
//     output o_amp_clk,
//     output o_amp_data,
//     output o_amp_en,
//     output o_amp_nrst,
//     output o_done
// );

// localparam 
//     STATE_IDLE  = 0,
//     STATE_LOAD  = 1,
//     STATE_WRITE = 2,
//     STATE_WAIT  = 3,
//     STATE_SHIFT = 4,
//     STATE_END   = 5;


// reg [3:0] state, nextState;

// reg [4:0] amp_cnt;
// wire amp_next;

// wire sr_en, sr_ld, sr_last_bit;
// wire amp_write_start;
// wire amp_data;
// wire write_rdy;
// wire sync;

// assign amp_next = (nextState == STATE_LOAD);

// sync_write amp_sync_write(
//     .clk     ( clk             ),
//     .rst     ( rst             ),
//     .i_write ( amp_write_start ),
//     .i_data  ( amp_data        ),
//     .i_sync  ( sync            ),
//     .o_clk   ( o_amp_clk       ), 
//     .o_data  ( o_amp_data      ),
//     .o_ready ( write_rdy       )
// );

// clock_divider#(
//     .NB_DIVIDER (NB_DIVIDER)
// )u_clock_divider_amp(
//     .i_clk     ( clk           ),
//     .i_rst     ( sync_rst      ),
//     .i_divider ( i_clk_div     ),
//     .o_clk     ( sync          )
// );

// amp_sr #(
//     .N_BITS ( 6 )
// ) u_amp_sr
// (
//     .clk            ( clk ),
//     .rst            ( rst ),
//     .i_en           ( sr_en ),
//     .i_ld           ( sr_ld ),
//     .i_val          ( i_amp_value ),
//     .o_data         ( amp_data ),
//     .o_shift_done   ( sr_last_bit )
// );


// // Contador de amplificadores restantes
// always @(posedge clk) begin
//     if(rst) amp_cnt <= 0; 
//     else if (i_go && (state == STATE_IDLE)) amp_cnt <= 12;
//     else if (amp_next && amp_cnt) amp_cnt <= amp_cnt - 1; 
// end


// always @(posedge clk ) begin
//     if (rst) begin
//         state <= STATE_IDLE;
//     end else begin
//         state <= nextState;
//     end
// end

// always @(*) begin
//     case (state)
//         STATE_IDLE: begin
//             nextState <= (i_go) ? STATE_LOAD : STATE_IDLE;
//         end
//         STATE_LOAD: begin
//             nextState <= STATE_WRITE;
//         end
//         STATE_WRITE: begin
//             nextState <= STATE_WAIT;
//         end
//         STATE_WAIT: begin
//             nextState <= (!write_rdy)   ? STATE_WAIT  : 
//                         (!sr_last_bit)  ? STATE_SHIFT :
//                         (amp_cnt)       ? STATE_LOAD  :
//                                           STATE_END   ;
//         end
//         STATE_SHIFT: begin
//             nextState <= STATE_WRITE;
//         end
//         STATE_END: begin
//             nextState <= (!i_go) ? STATE_IDLE : STATE_END;
//         end
//         default: begin
//             nextState <= STATE_IDLE;
//         end
//     endcase
// end

// assign sr_ld        = (state == STATE_LOAD);
// assign sr_en        = (state == STATE_SHIFT);
// assign o_amp_en     = (state != STATE_IDLE);
// assign o_amp_nrst   = 1'b1; 
// assign o_amp_write  = (state == STATE_WRITE);
// assign o_done       = (state == STATE_END);

// endmodule
