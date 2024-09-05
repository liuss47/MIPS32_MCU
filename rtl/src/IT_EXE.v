/*
v1:(1)要求在复位rst为高电平时禁�??
   (2)在时钟上升沿将IT阶段的输出传递给EXE阶段

*/
`include "defines.v"


module it_exe (
    input wire clk,
    input wire rst,

    //译码阶段的数�??
    input wire[`AluOpBus] it_alu_op,
    input wire[`AluSelBus] it_alu_sel,
    input wire[`RegBus] it_reg1,
    input wire[`RegBus] it_reg2,
    input wire[`RegAddrBus] it_w_add,
    input wire it_w_reg,

    input wire[5:0] stall,

    input wire it_in_delayslot,
    input wire[`RegBus] it_add_link,
    input wire next_inst_in_delayslot_in,
    input wire[`RegBus] it_inst,

    input wire flush,
    input wire[`RegBus] it_current_inst_add,
    input wire[`RegBus] it_excepttype,


    //传�?�信�??
    output reg[`AluOpBus] ex_alu_op,
    output reg[`AluSelBus] ex_alu_sel,
    output reg[`RegBus] ex_reg1,
    output reg[`RegBus] ex_reg2,
    output reg[`RegAddrBus] ex_w_add,
    output reg ex_w_reg,

    output reg ex_in_delayslot,
    output reg[`RegBus] ex_add_link,
    output reg in_delayslot_out,

    output reg[`RegBus] ex_inst,

    output reg[`RegBus] ex_current_inst_add,
    output reg[`RegBus] ex_excepttype

);
    
    always @(posedge clk) begin
        if(rst == `RstEnable)
        begin
            ex_alu_op <= `EXE_NOP_OP;
            ex_alu_sel <= `EXE_RES_NOP;
            ex_reg1 <= `ZeroWord;
            ex_reg2 <= `ZeroWord;
            ex_w_add <= `NOPRegAddr;
            ex_w_reg <= `WriteDisable;
            ex_add_link <= `ZeroWord;
            ex_in_delayslot <= `NotInDelaySlot;
            in_delayslot_out <= `NotInDelaySlot;
            ex_inst <= `ZeroWord;
            ex_excepttype <= `ZeroWord;
            ex_current_inst_add <= `ZeroWord;
        end
        else if(flush == 1'b1)
        begin
            ex_alu_op <= `EXE_NOP_OP;
            ex_alu_sel <= `EXE_RES_NOP;
            ex_reg1 <= `ZeroWord;
            ex_reg2 <= `ZeroWord;
            ex_w_add <= `NOPRegAddr;
            ex_w_reg <= `WriteDisable;
            ex_add_link <= `ZeroWord;
            ex_in_delayslot <= `NotInDelaySlot;
            in_delayslot_out <= `NotInDelaySlot;
            ex_inst <= `ZeroWord;
            ex_excepttype <= `ZeroWord;
            ex_current_inst_add <= `ZeroWord;
        end
        else if(stall[2] == `Stop && stall[3] == `NoStop)
        begin
            ex_alu_op <= `EXE_NOP_OP;
            ex_alu_sel <= `EXE_RES_NOP;
            ex_reg1 <= `ZeroWord;
            ex_reg2 <= `ZeroWord;
            ex_w_add <= `NOPRegAddr;
            ex_w_reg <= `WriteDisable;
            ex_add_link <= `ZeroWord;
            ex_in_delayslot <= `NotInDelaySlot;
            in_delayslot_out <= `NotInDelaySlot;
            ex_inst <= `ZeroWord;
            ex_excepttype <= `ZeroWord;
            ex_current_inst_add <= `ZeroWord;
        end
        else if(stall[2] == `NoStop)
        begin
            ex_alu_op <= it_alu_op;
            ex_alu_sel <= it_alu_sel;
            ex_reg1 <= it_reg1;
            ex_reg2 <= it_reg2;
            ex_w_add <= it_w_add;
            ex_w_reg <= it_w_reg;
            ex_add_link <= it_add_link;
            ex_in_delayslot <= it_in_delayslot;
            in_delayslot_out <= next_inst_in_delayslot_in;
            ex_inst <= it_inst;
            ex_excepttype <= it_excepttype;
            ex_current_inst_add <= it_current_inst_add;
        end
    end




endmodule
