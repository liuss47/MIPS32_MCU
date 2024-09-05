
//`include "./src/defines.v"
`include "defines.v"

`timescale 1ns/1ps

module testbench();

    reg clk_50;
    reg rst;

    initial
    begin
        clk_50 = 1'b0;

        forever begin
            
            #10 clk_50 = ~clk_50;

        end
    end

    initial
    begin

        rst = `RstEnable;

        #195 rst = `RstDisable;
	
	#10000; $finish;

    end
	/*nitial begin 
	$fsdbDumpfile("test.fsdb");
	$fsdbDumpvars(0,testbench);
    end*/
	

    mips_sopc mips_sopc0
    (
        .clk(clk_50),
        .rst(rst)
    );

    

endmodule
