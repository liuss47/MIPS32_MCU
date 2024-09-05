/*
v1:(1)指令寄存器的实现


*/
//`include "./src/defines.v"
`include "defines.v"
module inst_rom (
    input wire en,
    input wire[`InstAddrBus] add,
    output reg[`InstBus] inst
);

    //指令寄存数组
    reg[`InstBus] inst_mem[0:`InstMemNum - 1];


    //初始�???

    //初始�??

    //initial $readmemh( "./sim/inst_rom2.data" , inst_mem);/
    initial $readmemh( "inst_rom.data" , inst_mem);
    /*egin
    inst_mem[0] = 32'h34014044;
    inst_mem[1] = 32'h34220000;
    end*/
    //rst无效时根据输入的地址，给出指令ROM中的对应元素
    always@(*)
        begin
            if(en <= `ChipDisable)
            begin
            inst <= `ZeroWord;
            end
            else 
            begin
                inst <= inst_mem[ add[`InstMemNumLog2 + 1 : 2] ];
            end
        end

endmodule
