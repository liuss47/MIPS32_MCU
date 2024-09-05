/*
v1:
    (1)32�?32位寄存器
    (2)在clk上升�?,当rst不为1�?,w_en有效，且写入地址不为$0�?,进行写入操作
    (3)两个读端口，组合逻辑实现，当复位有效时，输出始终�?0�?
    复位无效时，如果读地�?�?$0,则直接输�?0�?
    如果读写地址�?致，则直接将要写入的作为读的结果�?
    正常条件下根据目标地�?读出结果
    若端口地�?无法访问则直接输�?0


*/
`include "defines.v"
module reg_group (
    input wire clk,
    input wire rst,

    //write�?
    input wire w_en,
    input wire[`RegAddrBus] w_add,
    input wire[`RegBus] w_data,
    //read�?1
    input wire reg1_en,
    input wire[`RegAddrBus] reg1_add,
    output reg[`RegBus] data_reg1,

    //read�?2
    input wire reg2_en,
    input wire[`RegAddrBus] reg2_add,
    output reg[`RegBus] data_reg2
);
    /*定义32�?32位寄存器*/
    reg[`RegBus] regs[0:`RegNum - 1];


    /*写操�?*/
    always @(posedge clk) 
    begin
        if (rst == `RstDisable)
        begin
            if((w_en == `WriteEnable) && (w_add != `RegNumLog2'h0))
            begin
                regs[w_add] <= w_data;
            end
        end
    end

    /*读操�?,组合电路*/
    always @(*) 
    begin
        if(rst == `RstEnable)
        begin
            data_reg1 <= `ZeroWord;
        end
        else if(reg1_add == `RegNumLog2'h0)
            begin
                data_reg1 <=`ZeroWord;
            end
        else if((reg1_add == w_add) && (w_en == `WriteEnable) && (reg1_en == `ReadEnable)) 
            begin
                data_reg1 <= w_data;
            end
        else if(reg1_en == `ReadEnable)
            begin
                data_reg1 <= regs[reg1_add];
            end
        else
            begin
                data_reg1 <= `ZeroWord;
            end
    end

    always @(*) 
    begin
        if(rst == `RstEnable)
        begin
            data_reg2 <= `ZeroWord;
        end
        else if(reg2_add == `RegNumLog2'h0)
            begin
                data_reg2 <=`ZeroWord;
            end
        else if((reg2_add == w_add) && (w_en == `WriteEnable) && (reg2_en == `ReadEnable)) 
            begin
                data_reg2 <= w_data;
            end
        else if(reg2_en == `ReadEnable)
            begin
                data_reg2 <= regs[reg2_add];
            end
        else
            begin
                data_reg2 <= `ZeroWord;
            end
    end
endmodule
