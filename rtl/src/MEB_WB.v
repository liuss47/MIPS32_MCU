/*
v1:
    (1) 组合电路，输入作为输�??
*/
`include "defines.v"
module meb_wb(
    input wire                  rst,
    input wire                  clk,

    input wire[`RegAddrBus]     meb_w_add,
    input wire                  meb_w_reg,
    input wire[`RegBus]         meb_w_data,
    input wire[`RegBus]         meb_hi,
    input wire[`RegBus]         meb_lo,
    input wire                  meb_hilo,

    input wire[5:0] stall,
    input wire flush,


    //cp0相关
    input wire meb_cp0_reg_en,
    input wire[4:0] meb_cp0_reg_w_add,
    input wire[`RegBus] meb_cp0_reg_data,

    output reg wb_cp0_reg_en,
    output reg[4:0] wb_cp0_reg_w_add,
    output reg[`RegBus] wb_cp0_reg_data,


    output reg[`RegAddrBus]     wb_w_add,
    output reg                  wb_w_reg,
    output reg[`RegBus]         wb_w_data,
    output reg[`RegBus]         wb_hi,
    output reg[`RegBus]         wb_lo,
    output reg                  wb_hilo
);

    // 组合逻辑
    always  @ (posedge clk) begin
        if (rst == `RstEnable) begin
            // 初始化状�??
            wb_w_add    <=  `NOPRegAddr;
            wb_w_reg    <=  `WriteDisable;
            wb_w_data   <=  `ZeroWord;
            wb_hi       <=  `ZeroWord;
            wb_lo       <=  `ZeroWord;
            wb_hilo     <=  `WriteDisable;
            wb_cp0_reg_en <= `WriteDisable;
            wb_cp0_reg_w_add <= 5'b00000;
            wb_cp0_reg_data <= `ZeroWord;
        end else if(flush == 1'b1) begin
            wb_w_add    <=  `NOPRegAddr;
            wb_w_reg    <=  `WriteDisable;
            wb_w_data   <=  `ZeroWord;
            wb_hi       <=  `ZeroWord;
            wb_lo       <=  `ZeroWord;
            wb_hilo     <=  `WriteDisable;
            wb_cp0_reg_en <= `WriteDisable;
            wb_cp0_reg_w_add <= 5'b00000;
            wb_cp0_reg_data <= `ZeroWord;
        end else if(stall[4] == `Stop && stall[5] == `NoStop) begin
            wb_w_add    <=  `NOPRegAddr;
            wb_w_reg    <=  `WriteDisable;
            wb_w_data   <=  `ZeroWord;
            wb_hi       <=  `ZeroWord;
            wb_lo       <=  `ZeroWord;
            wb_hilo     <=  `WriteDisable;
            wb_cp0_reg_en <= `WriteDisable;
            wb_cp0_reg_w_add <= 5'b00000;
            wb_cp0_reg_data <= `ZeroWord;
        end else if(stall[4] == `NoStop) begin 
            // 将输入直接赋值给输出
            wb_w_add    <=  meb_w_add;
            wb_w_reg    <=  meb_w_reg;
            wb_w_data   <=  meb_w_data;
            wb_hi       <=  meb_hi;
            wb_lo       <=  meb_lo;
            wb_hilo     <=  meb_hilo;
            wb_cp0_reg_en <= meb_cp0_reg_en;
            wb_cp0_reg_w_add <= meb_cp0_reg_w_add;
            wb_cp0_reg_data <= meb_cp0_reg_data;
        end
    end

endmodule
