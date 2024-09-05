/*
v1:
    (1)将PC取指结果�?单地在时钟上升沿传�?�给IT译码阶段
    (2)要求在复位rst为高电平时，进行清零

*/

`include "defines.v"
module if_it (
    input wire clk,
    input wire rst,
    
    input wire[`InstAddrBus] if_pc,
    input wire[`InstBus] if_inst,
    //均为32�?

    input wire[5:0] stall,

    input wire flush,

    output reg[`InstAddrBus] it_pc,
    output reg[`InstBus]it_inst
);

    always @(posedge clk) 
    begin
        if(rst == `RstEnable) 
        begin
          it_pc <= `ZeroWord;
          it_inst <= `ZeroWord; //复位时皆清零
        end
        else if(flush == 1'b1)
        begin
          it_pc <= `ZeroWord;
          it_inst <= `ZeroWord;
        end
        else if(stall[1] == `Stop && stall[2] == `NoStop) begin
          it_pc <= `ZeroWord;
          it_inst <= `ZeroWord;
        end else if(stall[1] == `NoStop) 
        begin
          it_pc <= if_pc;    //向下传�?�取指阶段的�?
          it_inst <= if_inst;
        end
    end
  
endmodule
