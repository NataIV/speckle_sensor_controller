/*
*
*
* MODULO QUE SIMULA EL FUNCIONAMIENTO COMPLETO DEL CHIP 
*
*
*/
module chip#(
    COL_NUM =    24,
    ROW_NUM =    24,
    NB_DATA =    12,
    PIXEL_FILE = "init.mem" // Cargar imagen de 24x24 para definir la intensidad de los pixeles
)(
    input clk,
    input [11:0] i_chip_signals,
    output reg o_Ifoto);

// Inicializacion de la memoria que simula el valor que entrega cada pixel
reg [NB_DATA-1:0] pix_mem [COL_NUM-1:0][ROW_NUM-1:0];
reg [4+NB_DATA-1:0] Ifoto_grupo [COL_NUM/2-1:0][ROW_NUM/2-1:0];
reg [6+NB_DATA+ROW_NUM-1:0] Ifoto_col [COL_NUM-1:0];
reg calc_I_foto;
integer pix_col, pix_row;
initial begin
   $readmemh(PIXEL_FILE, pix_mem, 0, COL_NUM*ROW_NUM);
end
always @(posedge clk) begin
    if(calc_I_foto)begin
        for(pix_col=0; pix_col < COL_NUM; pix_col = pix_col + 1) begin
            for(pix_row=0; pix_row < ROW_NUM; pix_row = pix_row + 1) begin
                Ifoto_grupo[pix_col/2][pix_row/2] <= Ifoto_grupo[pix_col/2][pix_row/2] + pix_mem[pix_row][pix_col];
            end 
        end
        for(pix_col=0; pix_col < COL_NUM; pix_col = pix_col + 2) begin
                Ifoto_col[pix_col/2] <= 0;
            for(pix_row=0; pix_row < ROW_NUM; pix_row = pix_row + 2) begin
                Ifoto_col[pix_col/2] <= Ifoto_col[pix_col/2] + Ifoto_grupo[pix_col/2][pix_row/2];
            end
            Ifoto_col[pix_col/2] <= Ifoto_col[pix_col/2] * (~regdesp_amps[pix_col]);
        end
        o_Ifoto <= 0;
        for(pix_col=0; pix_col < COL_NUM; pix_col = pix_col + 2) begin
            o_Ifoto <= o_Ifoto + Ifoto_col[pix_col/2];
        end
    end
end

wire clk_col = o_chip_signals[6];
wire rst_col = o_chip_signals[5];
wire ena_pixel = o_chip_signals[7];
wire dat_col = o_chip_signals[4];
// 21 columnas en total, cada columna tiene llaves ARL, WE, NE, SE
// Columnas pares (primer col = 0) no tienen su "ARL", en este codigo toma el valor 0
// Y se bypassea esta conexion en el registro de desplazamiento

reg [3:0] regdesp_col [COL_NUM-1:0]; 
integer icol; 
always@(clk_col) begin
    if(rst_col) begin
        for(icol = 0; icol < COL_NUM; icol = icol + 1)begin
            regdesp_col[icol] <= 4'b0000;
        end
    end else begin
        for(icol = COL_NUM-1; icol > 0; icol = icol - 1) begin
            if(icol%2) begin // Si no esta en la columna de ARL, ARL = 0
                regdesp_col[icol][3] <= 1'b0;
                regdesp_col[icol][2] <= regdesp_col[icol][1];
                regdesp_col[icol][1] <= regdesp_col[icol][0];
                regdesp_col[icol][0] <= regdesp_col[icol-1][3];
            end else begin
                regdesp_col[icol][3] <= regdesp_col[icol][2];
                regdesp_col[icol][2] <= regdesp_col[icol][1];
                regdesp_col[icol][1] <= regdesp_col[icol][0];
                regdesp_col[icol][0] <= regdesp_col[icol-1][2];
            end
        end
        regdesp_col[0][3] <= 1'b0;
        regdesp_col[0][2] <= regdesp_col[0][1];
        regdesp_col[0][1] <= regdesp_col[0][0];
        regdesp_col[0][0] <= dat_col;
    end
end


wire clk_row = o_chip_signals[3];
wire rst_row = o_chip_signals[2];
wire ena_row = o_chip_signals[1];
wire dat_row = o_chip_signals[0];
reg [ROW_NUM:0] regdesp_row;

always @(posedge clk_row ) begin
    if (rst_row) begin
        regdesp_row <= 0;
    end else if (ena_row) begin
        regdesp_row <= {regdesp_row[ROW_NUM-2:0], dat_row};
    end
end



wire clk_amps = o_chip_signals[11];
wire rst_amps = o_chip_signals[10];
wire ena_amps = o_chip_signals[9];
wire dat_amps = o_chip_signals[8];
reg [5:0] regdesp_amps [COL_NUM-1:0];
integer iamps;
always @(posedge clk_amps) begin
    if (rst_amps) begin
        for(iamps=0; iamps<COL_NUM-1;iamps = iamps + 1)begin
            regdesp_amps[iamps] <= 6'b000000;
        end
    end else if(ena_amps) begin
        for(iamps=COL_NUM-1; iamps>1; iamps = iamps - 1)begin
            if(iamps%2)begin
                regdesp_amps[iamps] <= 6'b000000; // No existen
            end else begin
                regdesp_amps[iamps] <= {regdesp_amps[iamps][4:0], regdesp_amps[iamps-2][5]};
            end
        end
        regdesp_amps[1] <= {regdesp_amps[1][4:0], dat_amps};
    end
end

//Configuracion final de los switches
reg [3:0] sw_mem [COL_NUM-1:0][ROW_NUM-1:0];
integer sw_col, sw_row;
always @(posedge clk ) begin
    if(ena_pixel)begin
        for(sw_col=0; sw_col < COL_NUM; sw_col = sw_col + 1) begin
            for(sw_row=0; sw_row < ROW_NUM; sw_row = sw_row + 1) begin
                if(regdesp_col[sw_col][0]) sw_mem[sw_col][sw_row][0] = regdesp_row[sw_row];
                if(regdesp_col[sw_col][1]) sw_mem[sw_col][sw_row][1] = regdesp_row[sw_row];
                if(regdesp_col[sw_col][2]) sw_mem[sw_col][sw_row][2] = regdesp_row[sw_row];
                if(regdesp_col[sw_col][3]) sw_mem[sw_col][sw_row][3] = regdesp_row[sw_row];
            end 
        end       
    end
end




endmodule