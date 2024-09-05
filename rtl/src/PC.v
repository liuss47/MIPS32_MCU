/*
v1:(1)要求在复位rst为高电平时PC禁用，且复位时pc指令地址清零
   (2)PC在工作时，pc指令地址每次在clk上升沿取指增加四个字节


*/
`include "defines.v"

module pc_reg (
    input wire clk,
    input wire rst,
    input wire[5:0] stall,//来自控制模块ctrl

    //来自IT译码阶段的信息
    input wire br_flag_in,
    input wire[`RegBus] br_tat_add_in,

    input wire flush,
    input wire[`RegBus] new_pc,

    output reg[`InstAddrBus] pc,
    output reg en
);
    always@(posedge clk) 
    begin
        if (rst == `RstEnable) 
        begin
            en <= `ChipDisable; //复位是禁用PC
        end 
        else 
        begin
            en <= `ChipEnable;   //复位结束后，回复使能
        end
    end

    always@(posedge clk)
    begin
        if(en == `ChipDisable)  
        begin
          pc <= 32'h00000000; //禁用时，PC清零
        end
        else if(flush == 1'b1)
        begin
            pc <= new_pc;
        end
        else if(stall[0] == `NoStop)    
        begin
            if(br_flag_in == `Branch) begin
                pc <= br_tat_add_in;
            end
            else begin
                pc <= pc + 4'h4;  //取指时，PC每次时钟周期加4
            end
        end
    end
endmodule
