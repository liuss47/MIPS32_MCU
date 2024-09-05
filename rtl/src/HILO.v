/*
v3: writeenabel -> output
*/


module hilo (
    input wire          clk,
    input wire          rst,

    input wire          hilo_en,
    input wire[`RegBus] hi_in,
    input wire[`RegBus] lo_in,

    output reg[`RegBus] hi_out,
    output reg[`RegBus] lo_out
);

    always @ (posedge clk) begin
        if(rst == `RstEnable) begin
            hi_out <= `ZeroWord;
            lo_out <= `ZeroWord;
        end else if ((hilo_en == `WriteEnable)) begin
            hi_out <= hi_in;
            lo_out <= lo_in;
        end
    end

endmodule