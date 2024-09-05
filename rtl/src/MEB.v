/*
v1:
    (1) 组合电路，输入作为输�???
*/
`include "defines.v"
module meb(
    input wire              rst,

    input wire[`RegBus]     w_data_in,
    input wire              w_reg_in,
    input wire[`RegAddrBus] w_add_in,
    input wire[`RegBus]     hi_in,
    input wire[`RegBus]     lo_in,
    input wire              hilo_in,

    input wire[`AluOpBus] alu_op_in,
    input wire[`RegBus] meb_add_in,
    input wire[`RegBus] reg2_in,
    input wire[`RegBus] meb_data_in,
	
	//cp0相关
	input wire cp0_reg_en_in,
	input wire[4:0] cp0_reg_w_add_in,
	input wire[`RegBus] cp0_reg_data_in,

	//异常处理
	input wire[`RegBus] excepttype_in,
	input wire in_delayslot_in,
	input wire[`RegBus] current_inst_add_in,
	//来自cp0模块
	input wire[`RegBus] cp0_status_in,
	input wire[`RegBus] cp0_cause_in,
	input wire[`RegBus] cp0_epc_in,
	//
	input wire wb_cp0_reg_en,
	input wire[4:0] wb_cp0_reg_w_add,
	input wire[`RegBus] wb_cp0_reg_data,



    output reg[`RegBus]     w_data_out,
    output reg              w_reg_out,
    output reg[`RegAddrBus] w_add_out,
    output reg[`RegBus]     hi_out,
    output reg[`RegBus]     lo_out,
    output reg              hilo_out,
    //传输到外部数据储存器RAM的信�??
    output reg[`RegBus] meb_add_out,
    output wire meb_en_out,
    output reg[3:0] meb_sel_out,
    output reg[`RegBus] meb_data_out,
    output reg meb_ce_out,

	//cp0相关
	output reg cp0_reg_en_out,
	output reg[4:0] cp0_reg_w_add_out,
	output reg[`RegBus] cp0_reg_data_out,

	//异常处理
	output reg[31:0] excepttype_out,
	output wire[`RegBus] cp0_epc_out,
	output wire in_delayslot_out,
	output wire[`RegBus] current_inst_add_out

);

    wire[`RegBus] zero32;
    reg meb_en;

	reg[`RegBus] cp0_status;
	reg[`RegBus] cp0_cause;
	reg[`RegBus] cp0_epc;


    assign meb_en_out = meb_en & (~(|excepttype_out));
    assign zero32 = `ZeroWord;

	assign in_delayslot_out = in_delayslot_in;

	assign current_inst_add_out = current_inst_add_in;
    assign cp0_epc_out = cp0_epc;
    // 组合逻辑
    always  @ (*) begin
        if (rst == `RstEnable) begin
            // 初始化状�???
            w_data_out <= `ZeroWord;
            w_reg_out <= `WriteDisable;
            w_add_out <= `NOPRegAddr;
            hi_out <= `ZeroWord;
            lo_out <= `ZeroWord;
            hilo_out <= `WriteDisable;
            meb_add_out <= `ZeroWord;
            meb_en <= `WriteDisable;
            meb_sel_out <= 4'b0000;
            meb_data_out <= `ZeroWord;
            meb_ce_out <= `ChipDisable;
			cp0_reg_en_out <= `WriteDisable;
			cp0_reg_w_add_out <= 5'b00000;
			cp0_reg_data_out <= `ZeroWord;
        end else begin
            // 将输入直接赋值给输出
            w_data_out <= w_data_in;
            w_reg_out <= w_reg_in;
            w_add_out <= w_add_in;
            hi_out <= hi_in;
            lo_out <= lo_in;
            hilo_out <= hilo_in;
            meb_add_out <= `ZeroWord;
            meb_en <= `WriteDisable;
            meb_sel_out <= 4'b1111;
            meb_ce_out <= `ChipDisable;
            cp0_reg_en_out <= cp0_reg_en_in;
			cp0_reg_w_add_out <= cp0_reg_w_add_in;
			cp0_reg_data_out <= cp0_reg_data_in;

            case (alu_op_in)
				`EXE_LB_OP:		begin
					meb_add_out <= meb_add_in;
					meb_en <= `WriteDisable;
					meb_ce_out <= `ChipEnable;
					case (meb_add_in[1:0])
						2'b00:	begin
							w_data_out <= {{24{meb_data_in[31]}},meb_data_in[31:24]};
							meb_sel_out <= 4'b1000;
						end
						2'b01:	begin
							w_data_out <= {{24{meb_data_in[23]}},meb_data_in[23:16]};
							meb_sel_out <= 4'b0100;
						end
						2'b10:	begin
							w_data_out <= {{24{meb_data_in[15]}},meb_data_in[15:8]};
							meb_sel_out <= 4'b0010;
						end
						2'b11:	begin
							w_data_out <= {{24{meb_data_in[7]}},meb_data_in[7:0]};
							meb_sel_out <= 4'b0001;
						end
						default:	begin
							w_data_out <= `ZeroWord;
						end
					endcase
				end
				`EXE_LBU_OP:		begin
					meb_add_out <= meb_add_in;
					meb_en <= `WriteDisable;
					meb_ce_out <= `ChipEnable;
					case (meb_add_in[1:0])
						2'b00:	begin
							w_data_out <= {{24{1'b0}},meb_data_in[31:24]};
							meb_sel_out <= 4'b1000;
						end
						2'b01:	begin
							w_data_out <= {{24{1'b0}},meb_data_in[23:16]};
							meb_sel_out <= 4'b0100;
						end
						2'b10:	begin
							w_data_out <= {{24{1'b0}},meb_data_in[15:8]};
							meb_sel_out <= 4'b0010;
						end
						2'b11:	begin
							w_data_out <= {{24{1'b0}},meb_data_in[7:0]};
							meb_sel_out <= 4'b0001;
						end
						default:	begin
							w_data_out <= `ZeroWord;
						end
					endcase				
				end
				`EXE_LH_OP:		begin
					meb_add_out <= meb_add_in;
					meb_en <= `WriteDisable;
					meb_ce_out <= `ChipEnable;
					case (meb_add_in[1:0])
						2'b00:	begin
							w_data_out <= {{16{meb_data_in[31]}},meb_data_in[31:16]};
							meb_sel_out <= 4'b1100;
						end
						2'b10:	begin
							w_data_out <= {{16{meb_data_in[15]}},meb_data_in[15:0]};
							meb_sel_out <= 4'b0011;
						end
						default:	begin
							w_data_out <= `ZeroWord;
						end
					endcase					
				end
				`EXE_LHU_OP:		begin
					meb_add_out <= meb_add_in;
					meb_en <= `WriteDisable;
					meb_ce_out <= `ChipEnable;
					case (meb_add_in[1:0])
						2'b00:	begin
							w_data_out <= {{16{1'b0}},meb_data_in[31:16]};
							meb_sel_out <= 4'b1100;
						end
						2'b10:	begin
							w_data_out <= {{16{1'b0}},meb_data_in[15:0]};
							meb_sel_out <= 4'b0011;
						end
						default:	begin
							w_data_out <= `ZeroWord;
						end
					endcase				
				end
				`EXE_LW_OP:		begin
					meb_add_out <= meb_add_in;
					meb_en <= `WriteDisable;
					w_data_out <= meb_data_in;
					meb_sel_out <= 4'b1111;
					meb_ce_out <= `ChipEnable;		
				end
				`EXE_LWL_OP:		begin
					meb_add_out <= {meb_add_in[31:2], 2'b00};
					meb_en <= `WriteDisable;
					meb_sel_out <= 4'b1111;
					meb_ce_out <= `ChipEnable;
					case (meb_add_in[1:0])
						2'b00:	begin
							w_data_out <= meb_data_in[31:0];
						end
						2'b01:	begin
							w_data_out <= {meb_data_in[23:0],reg2_in[7:0]};
						end
						2'b10:	begin
							w_data_out <= {meb_data_in[15:0],reg2_in[15:0]};
						end
						2'b11:	begin
							w_data_out <= {meb_data_in[7:0],reg2_in[23:0]};	
						end
						default:	begin
							w_data_out <= `ZeroWord;
						end
					endcase				
				end
				`EXE_LWR_OP:		begin
					meb_add_out <= {meb_add_in[31:2], 2'b00};
					meb_en <= `WriteDisable;
					meb_sel_out <= 4'b1111;
					meb_ce_out <= `ChipEnable;
					case (meb_add_in[1:0])
						2'b00:	begin
							w_data_out <= {reg2_in[31:8],meb_data_in[31:24]};
						end
						2'b01:	begin
							w_data_out <= {reg2_in[31:16],meb_data_in[31:16]};
						end
						2'b10:	begin
							w_data_out <= {reg2_in[31:24],meb_data_in[31:8]};
						end
						2'b11:	begin
							w_data_out <= meb_data_in;	
						end
						default:	begin
							w_data_out <= `ZeroWord;
						end
					endcase					
				end
				`EXE_SB_OP:		begin
					meb_add_out <= meb_add_in;
					meb_en <= `WriteEnable;
					meb_data_out <= {reg2_in[7:0],reg2_in[7:0],reg2_in[7:0],reg2_in[7:0]};
					meb_ce_out <= `ChipEnable;
					case (meb_add_in[1:0])
						2'b00:	begin
							meb_sel_out <= 4'b1000;
						end
						2'b01:	begin
							meb_sel_out <= 4'b0100;
						end
						2'b10:	begin
							meb_sel_out <= 4'b0010;
						end
						2'b11:	begin
							meb_sel_out <= 4'b0001;	
						end
						default:	begin
							meb_sel_out <= 4'b0000;
						end
					endcase				
				end
				`EXE_SH_OP:		begin
					meb_add_out <= meb_add_in;
					meb_en <= `WriteEnable;
					meb_data_out <= {reg2_in[15:0],reg2_in[15:0]};
					meb_ce_out <= `ChipEnable;
					case (meb_add_in[1:0])
						2'b00:	begin
							meb_sel_out <= 4'b1100;
						end
						2'b10:	begin
							meb_sel_out <= 4'b0011;
						end
						default:	begin
							meb_sel_out <= 4'b0000;
						end
					endcase						
				end
				`EXE_SW_OP:		begin
					meb_add_out <= meb_add_in;
					meb_en <= `WriteEnable;
					meb_data_out <= reg2_in;
					meb_sel_out <= 4'b1111;	
					meb_ce_out <= `ChipEnable;		
				end
				`EXE_SWL_OP:		begin
					meb_add_out <= {meb_add_in[31:2], 2'b00};
					meb_en <= `WriteEnable;
					meb_ce_out <= `ChipEnable;
					case (meb_add_in[1:0])
						2'b00:	begin						  
							meb_sel_out <= 4'b1111;
							meb_data_out <= reg2_in;
						end
						2'b01:	begin
							meb_sel_out <= 4'b0111;
							meb_data_out <= {zero32[7:0],reg2_in[31:8]};
						end
						2'b10:	begin
							meb_sel_out <= 4'b0011;
							meb_data_out <= {zero32[15:0],reg2_in[31:16]};
						end
						2'b11:	begin
							meb_sel_out <= 4'b0001;	
							meb_data_out <= {zero32[23:0],reg2_in[31:24]};
						end
						default:	begin
							meb_sel_out <= 4'b0000;
						end
					endcase							
				end
				`EXE_SWR_OP:		begin
					meb_add_out <= {meb_add_in[31:2], 2'b00};
					meb_en <= `WriteEnable;
					meb_ce_out <= `ChipEnable;
					case (meb_add_in[1:0])
						2'b00:	begin						  
							meb_sel_out <= 4'b1000;
							meb_data_out <= {reg2_in[7:0],zero32[23:0]};
						end
						2'b01:	begin
							meb_sel_out <= 4'b1100;
							meb_data_out <= {reg2_in[15:0],zero32[15:0]};
						end
						2'b10:	begin
							meb_sel_out <= 4'b1110;
							meb_data_out <= {reg2_in[23:0],zero32[7:0]};
						end
						2'b11:	begin
							meb_sel_out <= 4'b1111;	
							meb_data_out <= reg2_in[31:0];
						end
						default:	begin
							meb_sel_out <= 4'b0000;
						end
					endcase											
				end 
				default:		begin
          //ʲôҲ����
				end
			endcase

        end
    end

	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_status <= `ZeroWord;
		end else if((wb_cp0_reg_en == `WriteEnable) && 
								(wb_cp0_reg_w_add == `CP0_REG_STATUS ))begin
			cp0_status <= wb_cp0_reg_data;
		end else begin
		  cp0_status <= cp0_status_in;
		end
	end
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_epc <= `ZeroWord;
		end else if((wb_cp0_reg_en == `WriteEnable) && 
								(wb_cp0_reg_w_add == `CP0_REG_EPC ))begin
			cp0_epc <= wb_cp0_reg_data;
		end else begin
		  cp0_epc <= cp0_epc_in;
		end
	end

  always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_cause <= `ZeroWord;
		end else if((wb_cp0_reg_en == `WriteEnable) && 
								(wb_cp0_reg_w_add == `CP0_REG_CAUSE ))begin
			cp0_cause[9:8] <= wb_cp0_reg_data[9:8];
			cp0_cause[22] <= wb_cp0_reg_data[22];
			cp0_cause[23] <= wb_cp0_reg_data[23];
		end else begin
		  cp0_cause <= cp0_cause_in;
		end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			excepttype_out <= `ZeroWord;
		end else begin
			excepttype_out <= `ZeroWord;
			
			if(current_inst_add_in != `ZeroWord) begin
				if(((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) && (cp0_status[1] == 1'b0) && 
							(cp0_status[0] == 1'b1)) begin
					excepttype_out <= 32'h00000001;        //interrupt
				end else if(excepttype_in[8] == 1'b1) begin
			  	excepttype_out <= 32'h00000008;        //syscall
				end else if(excepttype_in[9] == 1'b1) begin
					excepttype_out <= 32'h0000000a;        //inst_invalid
				end else if(excepttype_in[10] ==1'b1) begin
					excepttype_out <= 32'h0000000d;        //trap
				end else if(excepttype_in[11] == 1'b1) begin  //ov
					excepttype_out <= 32'h0000000c;
				end else if(excepttype_in[12] == 1'b1) begin  //����ָ��
					excepttype_out <= 32'h0000000e;
				end
			end
				
		end
	end

endmodule
