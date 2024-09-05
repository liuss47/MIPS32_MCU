/*
v1:(1)立即数或指令SOPC


*/

//`include "./src/defines.v"
`include "defines.v"
module mips_sopc (
    input wire clk,
    input wire rst
);

    wire[`InstAddrBus] inst_add;
    wire[`InstBus] inst;
    wire rom_en;
    wire[`RegBus] ram_add_out;
    wire[`RegBus] ram_data_out;
    wire[3:0] ram_sel_out;
    wire ram_en_out;
    wire ram_ce_out;
    wire[`RegBus] ram_data_in;
    wire timer_int;
    wire[5:0] int;

    assign int = {5'b00000 , timer_int};
    //例化MIPS_CORE
    mips32_core mips32_core0(
        .clk(clk),
        .rst(rst),
        .rom_add_out(inst_add),
        .rom_data_in(inst),
        .rom_en_out(rom_en),
        .ram_add_out(ram_add_out),
        .ram_data_out(ram_data_out),
        .ram_sel_out(ram_sel_out),
        .ram_ce_out(ram_ce_out),
        .ram_en_out(ram_en_out),
        .ram_data_in(ram_data_in),
        .int_i(int),
        .timer_int_o(timer_int)
    );

    //例化INST_ROM
    inst_rom inst_rom0(
        .en(rom_en),
        .add(inst_add),
        .inst(inst)
    );

    //例化DATA_RAM
    data_ram data_ram0(
        .clk(clk),
        .addr(ram_add_out),
        .data_in(ram_data_out),
        .sel(ram_sel_out),
        .en(ram_en_out),
        .ce(ram_ce_out),
        .data_out(ram_data_in)
    );



endmodule


