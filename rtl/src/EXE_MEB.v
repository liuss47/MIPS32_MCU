/*
v1:
    时钟上升沿将结果传�?�到MEB
*/
`include "defines.v"

module exe_meb(
    input wire clk,
    input wire rst,

    input wire ex_w_reg,
    input wire[`RegBus] ex_w_data,
    input wire[`RegAddrBus] ex_w_add,
    input wire[`RegBus] ex_hi,
    input wire[`RegBus] ex_lo,
    input wire          ex_hilo,
    input wire[5:0] stall,
    input wire[`AluOpBus] ex_alu_op,
    input wire[`RegBus] ex_meb_add,
    input wire[`RegBus] ex_reg2,
    input wire ex_cp0_reg_en,
    input wire[4:0] ex_cp0_reg_w_add,
    input wire[`RegBus] ex_cp0_reg_data,
    input wire flush,
    input wire[`RegBus] ex_excepttype,
    input wire ex_in_delayslot,
    input wire[`RegBus] ex_current_inst_add,
    




    output reg meb_w_reg,
    output reg[`RegBus] meb_w_data,
    output reg[`RegAddrBus] meb_w_add,
    output reg[`RegBus] meb_hi  ,
    output reg[`RegBus] meb_lo  ,
    output reg          meb_hilo,

    output reg[`AluOpBus] meb_alu_op,
    output reg[`RegBus] meb_meb_add,
    output reg[`RegBus] meb_reg2,
    //cp0相关
    output reg meb_cp0_reg_en,
    output reg[4:0] meb_cp0_reg_w_add,
    output reg[`RegBus] meb_cp0_reg_data,
    output reg[`RegBus] meb_excepttype,
    output reg meb_in_delayslot,
    output reg[`RegBus] meb_current_inst_add

);


    // 时钟上升沿时更新输出
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            meb_w_reg <= `NOPRegAddr;
            meb_w_data <= `WriteDisable;
            meb_w_add <= `ZeroWord;
            meb_hi <= `ZeroWord;
            meb_lo <= `ZeroWord;
            meb_hilo <= `WriteDisable;
            meb_alu_op <= `EXE_NOP_OP;
            meb_meb_add <= `ZeroWord;
            meb_reg2 <= `ZeroWord;
            meb_cp0_reg_en <= `WriteDisable;
            meb_cp0_reg_w_add <= 5'b00000;
            meb_cp0_reg_data <= `ZeroWord;
            meb_excepttype <= `ZeroWord;
            meb_in_delayslot <= `NotInDelaySlot;
            meb_current_inst_add <= `ZeroWord;
        end
        else if(flush == 1'b1)
        begin
            meb_w_reg <= `NOPRegAddr;
            meb_w_data <= `WriteDisable;
            meb_w_add <= `ZeroWord;
            meb_hi <= `ZeroWord;
            meb_lo <= `ZeroWord;
            meb_hilo <= `WriteDisable;
            meb_alu_op <= `EXE_NOP_OP;
            meb_meb_add <= `ZeroWord;
            meb_reg2 <= `ZeroWord;
            meb_cp0_reg_en <= `WriteDisable;
            meb_cp0_reg_w_add <= 5'b00000;
            meb_cp0_reg_data <= `ZeroWord;
            meb_excepttype <= `ZeroWord;
            meb_in_delayslot <= `NotInDelaySlot;
            meb_current_inst_add <= `ZeroWord;
        end        
        else if(stall[3] == `Stop && stall[4] == `NoStop ) begin
            meb_w_reg <= `NOPRegAddr;
            meb_w_data <= `WriteDisable;
            meb_w_add <= `ZeroWord;
            meb_hi <= `ZeroWord;
            meb_lo <= `ZeroWord;
            meb_hilo <= `WriteDisable;
            meb_alu_op <= `EXE_NOP_OP;
            meb_meb_add <= `ZeroWord;
            meb_reg2 <= `ZeroWord;
            meb_cp0_reg_en <= `WriteDisable;
            meb_cp0_reg_w_add <= 5'b00000;
            meb_cp0_reg_data <= `ZeroWord;
            meb_excepttype <= `ZeroWord;
            meb_in_delayslot <= `NotInDelaySlot;
            meb_current_inst_add <= `ZeroWord;
        end
        else if(stall[3] == `NoStop) begin
            // 时钟上升沿，将EXE阶段的结果传递到MEB阶段
            meb_w_reg <= ex_w_reg;
            meb_w_data <= ex_w_data;
            meb_w_add <= ex_w_add;
            meb_hi <= ex_hi;
            meb_lo <= ex_lo;
            meb_hilo <= ex_hilo;
            meb_alu_op <= ex_alu_op;
            meb_meb_add <= ex_meb_add;
            meb_reg2 <= ex_reg2;
            meb_cp0_reg_en <= ex_cp0_reg_en;
            meb_cp0_reg_w_add <= ex_cp0_reg_w_add;
            meb_cp0_reg_data <= ex_cp0_reg_data;
            meb_excepttype <= ex_excepttype;
            meb_in_delayslot <= ex_in_delayslot;
            meb_current_inst_add <= ex_current_inst_add;
        end
    end

endmodule
