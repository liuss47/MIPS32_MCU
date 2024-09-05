/*
v1,v2:指令扩充,逻辑和移位指�????

*/

`include "defines.v"

module exe(
    input wire rst,

    input wire[`AluOpBus] alu_op_in,
    input wire[`AluSelBus] alu_sel_in,
    input wire[`RegBus] reg1_in,
    input wire[`RegBus] reg2_in,
    input wire[`RegAddrBus] w_add_in,
    input wire w_reg_in,

    input wire[`RegBus] hi_in,
    input wire[`RegBus] lo_in,

    input wire[`RegBus] wb_hi_in,
    input wire[`RegBus] wb_lo_in,
    input wire          wb_hilo_in,

    input wire [`RegBus] meb_hi_in,
    input wire [`RegBus] meb_lo_in,
    input wire           meb_hilo_in,
    //延迟�????
    input wire in_delayslot_in,
    input wire[`RegBus]add_link_in,

    input wire[`RegBus] inst_in,
    
    //cp0访存阶段
    input wire meb_cp0_reg_en,
    input wire[4:0] meb_cp0_reg_w_add,
    input wire[`RegBus] meb_cp0_reg_data,

    //cp0回写阶段
    input wire wb_cp0_reg_en,
    input wire[4:0] wb_cp0_reg_w_add,
    input wire[`RegBus] wb_cp0_reg_data,

    //cp0读取
    input wire[`RegBus] cp0_reg_data_in,
    output reg[4:0] cp0_reg_read_add_out,

    //cp0传�??
    output reg cp0_reg_en_out,
    output reg[4:0] cp0_reg_w_add_out,
    output reg[`RegBus] cp0_reg_data_out,

    //异常处理
    input wire[`RegBus] excepttype_in,
    input wire[`RegBus] current_inst_add_in,

    output wire[`RegBus] excepttype_out,
    output wire in_delayslot_out,
    output wire[`RegBus] current_inst_add_out,


    //output
    output reg          w_reg_out,
    output reg[`RegBus] w_data_out,
    output reg[`RegAddrBus] w_add_out,

    output reg          hilo_out,
    output reg[`RegBus] hi_out,
    output reg[`RegBus] lo_out,

    output reg stallreq_from_ex, //暂停机制信号

    output wire[`AluOpBus] alu_op_out,
    output wire[`RegBus] meb_add_out,
    output wire[`RegBus] data_r2_out


);
    reg[`RegBus] logicout; //逻辑运算结果
    reg[`RegBus] shiftres; //移位运算结果
    reg[`RegBus] moveres; //
    reg[`RegBus] HI; //
    reg[`RegBus] LO; //

    wire            ov_sum;
    wire            reg1_eq_reg2;
    wire            reg1_lt_reg2;
    reg [`RegBus]   arithmeticres;
    wire [`RegBus]  reg2_i_mux;
    wire [`RegBus]  reg1_i_not;
    wire [`RegBus]  result_sum;
    wire [`RegBus]  opdata1_mult;
    wire [`RegBus]  opdata2_mult;
    wire [`DoubleRegBus] hilo_temp;
    reg [`DoubleRegBus] mulres;

    reg trapassert;
    reg ovassert;

    //�?10bit代表是否有自限异�?,11代表溢出异常
    assign excepttype_out = {excepttype_in[31:12],ovassert,trapassert,excepttype_in[9:8],8'h00};
    assign in_delayslot_out = in_delayslot_in;
    assign current_inst_add_out = current_inst_add_in;

    assign reg2_i_mux = ((alu_op_in == `EXE_SUB_OP) || (alu_op_in == `EXE_SUBU_OP) ||
							(alu_op_in == `EXE_SLT_OP)|| (alu_op_in == `EXE_TLT_OP) ||
	                       (alu_op_in == `EXE_TLTI_OP) || (alu_op_in == `EXE_TGE_OP) ||
	                       (alu_op_in == `EXE_TGEI_OP)) ? (~reg2_in)+1 : reg2_in;
    assign result_sum = reg1_in + reg2_i_mux;
    assign ov_sum = ((!reg1_in[31] && !reg2_i_mux[31]) && result_sum[31]) ||
                    ((reg1_in[31] && reg2_i_mux[31]) && (!result_sum[31]));
    assign reg1_lt_reg2 = ((alu_op_in == `EXE_SLT_OP)||
	                       (alu_op_in == `EXE_TLT_OP) || (alu_op_in == `EXE_TLTI_OP) ||
	                       (alu_op_in == `EXE_TGE_OP) || (alu_op_in == `EXE_TGEI_OP)) ?
												 ((reg1_in[31] && !reg2_in[31]) || 
												 (!reg1_in[31] && !reg2_in[31] && result_sum[31])||
			                   (reg1_in[31] && reg2_in[31] && result_sum[31]))
			                   :	(reg1_in < reg2_in);
    assign reg1_i_not = ~reg1_in;

    assign alu_op_out = alu_op_in;

    assign meb_add_out = reg1_in + {{16{inst_in[15]}},inst_in[15:0]};

    assign data_r2_out = reg2_in;

    always @ (*) begin
        if (rst == `RstEnable) begin
            arithmeticres <= `ZeroWord;   
        end else begin
            case(alu_op_in)
                `EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP: begin
                // ADD, ADDU, ADDI, ADDIU 操作（ADDI �???? ADDIU 带立即数�????
                    arithmeticres <= result_sum; 
                end
                `EXE_SUB_OP, `EXE_SUBU_OP: begin
                // SUB �???? SUBU 操作
                    arithmeticres <= result_sum; 
                end
                `EXE_SLT_OP, `EXE_SLTU_OP: begin
                // SLT (Set on Less Than, 比较)
                    arithmeticres <= reg1_lt_reg2;  
                end
                `EXE_CLZ_OP: begin
                    // CLZ (Count Leading Zeroes)
                    arithmeticres <= reg1_in ? $clog2(reg1_in) : 32;
                end
                `EXE_CLO_OP: begin
                    // CLO (Count Leading Ones)
                    arithmeticres <= reg1_in ? 32 - $clog2(~reg1_in) : 32; // use system function $clog2
                end
                default: begin
                    arithmeticres <= `ZeroWord; 
                end
            endcase
        end
    end


    always @ (*) begin
		if(rst == `RstEnable) begin
			trapassert <= `TrapNotAssert;
		end else begin
			trapassert <= `TrapNotAssert;
			case (alu_op_in)
				`EXE_TEQ_OP, `EXE_TEQI_OP:		begin
					if( reg1_in == reg2_in ) begin
						trapassert <= `TrapAssert;
					end
				end
				`EXE_TGE_OP, `EXE_TGEI_OP, `EXE_TGEIU_OP, `EXE_TGEU_OP:		begin
					if( ~reg1_lt_reg2 ) begin
						trapassert <= `TrapAssert;
					end
				end
				`EXE_TLT_OP, `EXE_TLTI_OP, `EXE_TLTIU_OP, `EXE_TLTU_OP:		begin
					if( reg1_lt_reg2 ) begin
						trapassert <= `TrapAssert;
					end
				end
				`EXE_TNE_OP, `EXE_TNEI_OP:		begin
					if( reg1_in != reg2_in ) begin
						trapassert <= `TrapAssert;
					end
				end
				default:				begin
					trapassert <= `TrapNotAssert;
				end
			endcase
		end
	end

    assign opdata1_mult = (((alu_op_in == `EXE_MUL_OP)||(alu_op_in == `EXE_MUL_OP)) 
                            && (reg1_in[31] == 1'b1)) ? (~reg1_in + 1 ) : reg1_in;
    assign opdata2_mult = (((alu_op_in == `EXE_MUL_OP)||(alu_op_in == `EXE_MUL_OP)) 
                            && (reg2_in[31] == 1'b1)) ? (~reg2_in + 1 ) : reg2_in;
    assign hilo_temp = opdata1_mult * opdata2_mult;

    always @ (*) begin
        if (rst == `RstEnable) begin
            mulres <= {`ZeroWord, `ZeroWord};
        end else if ((alu_op_in == `EXE_MULT_OP) || (alu_op_in == `EXE_MUL_OP)) begin
            // 当操作码为乘法操作时
            if (reg1_in[31] != reg2_in[31]) begin 
            // 如果 reg1 �???? reg2 的符号位不同（即�????个正�????个负），则取 hilo_temp 的补码加1
                mulres <= ~hilo_temp + 1;
            end else begin 
            // 如果符号位相同（即都是正或都是负），直接使用 hilo_temp
                mulres <= hilo_temp;
            end
        end else begin
            // 其他情况，维�???? hilo_temp 的�??
            mulres <= hilo_temp;
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            {HI,LO} <= {`ZeroWord,`ZeroWord};
        end else if (meb_hilo_in == `WriteEnable) begin
            {HI,LO} <= {meb_hi_in,meb_lo_in};
        end else if (wb_hilo_in == `WriteEnable) begin
            {HI,LO} <= {wb_hi_in,wb_lo_in};
        end else begin
            {HI,LO} <= {hi_in,lo_in};           
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            moveres <= `ZeroWord;
        end else begin
            moveres <= `ZeroWord;
            case(alu_op_in)
                `EXE_MFHI_OP: begin
                    moveres <= HI;
                end
                `EXE_MFLO_OP: begin
                    moveres <= LO;
                end
                `EXE_MOVN_OP: begin
                    moveres <= reg1_in;
                end
                `EXE_MOVZ_OP: begin
                    moveres <= reg1_in;
                end
                `EXE_MFC0_OP: begin
                    
                    cp0_reg_read_add_out <= inst_in[15:11];
                    moveres <= cp0_reg_data_in;
                    //cp0数据回流的处�??
                    if(meb_cp0_reg_en == `WriteEnable && meb_cp0_reg_w_add == inst_in[15:11])
                    begin
                        moveres <= meb_cp0_reg_data;
                    end else if(wb_cp0_reg_en == `WriteEnable && wb_cp0_reg_w_add == inst_in[15:11])
                    begin
                        moveres <= wb_cp0_reg_data;
                    end
                end

                default: begin end
            endcase      
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            logicout <= `ZeroWord;
        end else begin
            case (alu_op_in)
                `EXE_OR_OP: begin
                    logicout <= reg1_in | reg2_in; // Perform OR operation with immediate value
                end
                `EXE_AND_OP: begin
                    logicout <= reg1_in & reg2_in; // AND operation
                end
                `EXE_XOR_OP: begin
                    logicout <= reg1_in ^ reg2_in; // XOR operation
                end
                `EXE_NOR_OP: begin
                    logicout <= ~(reg1_in | reg2_in); // NOR operation
                end
                default: begin
                    logicout <= `ZeroWord; // Default to zero if no operation matches
                end
            endcase
        end
    end

    always @(*) begin
        if(rst == `RstEnable) begin
            shiftres <= `ZeroWord;
        end else begin
            case (alu_op_in)
                `EXE_SLL_OP:    begin
                    shiftres <= reg2_in << reg1_in[4:0];
                end
                `EXE_SRL_OP:    begin
                    shiftres <= reg2_in >> reg1_in[4:0];
                end
                `EXE_SRA_OP:    begin
                    shiftres <= ({32{reg2_in[31]}} << (6'd32 - {1'b0,reg1_in[4:0]})) | reg2_in >> reg1_in[4:0];
                end
                default :   begin
                    shiftres <= `ZeroWord;
                end
            endcase
        end

    end

    // Pass the results and control signals to the next pipeline stage
    always @ (*) begin
        w_add_out <= w_add_in;

	    if(((alu_op_in == `EXE_ADD_OP) || (alu_op_in == `EXE_ADDI_OP) || 
	    (alu_op_in == `EXE_SUB_OP)) && (ov_sum == 1'b1)) begin
	 	    w_reg_out <= `WriteDisable;
	 	    ovassert <= 1'b1;
	    end else begin
	        w_reg_out <= w_reg_in;
	        ovassert <= 1'b0;
	    end

        case (alu_sel_in)
            `EXE_RES_LOGIC: begin
                w_data_out <= logicout;
            end
            `EXE_RES_SHIFT: begin
                w_data_out <= shiftres;
            end
            `EXE_RES_MOVE: begin
                w_data_out <= moveres;
            end
            `EXE_RES_ARITHMETIC: begin
                w_data_out <= arithmeticres;
            end
            `EXE_RES_MUL: begin
                w_data_out <= mulres[31:0];
            end
            `EXE_RES_JUMP_BRANCH: begin
                w_data_out <= add_link_in;
            end
            default: begin
                w_data_out <= `ZeroWord;
            end 
        endcase
    end


    always @ (*) begin
        if (rst == `RstEnable) begin
            hilo_out <= `WriteDisable;
            hi_out <= `ZeroWord;
            lo_out <= `ZeroWord;        
        end else if((alu_op_in == `EXE_MULT_OP)||(alu_op_in == `EXE_MULTU_OP)) begin
            hilo_out <= `WriteEnable;
            hi_out <= mulres[63:32];
            lo_out <= mulres[31:0];
        end else if(alu_op_in == `EXE_MTHI_OP) begin
            hilo_out <= `WriteEnable;
            hi_out <=  reg1_in;
            lo_out <= LO;
        end else if(alu_op_in == `EXE_MTLO_OP) begin
            hilo_out <= `WriteEnable;
            hi_out <=  HI;
            lo_out <= reg1_in;
        end else begin
            hilo_out <= `WriteDisable;
            hi_out <= `ZeroWord;
            lo_out <= `ZeroWord;   
        end      
    end

    always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_reg_w_add_out <= 5'b00000;
			cp0_reg_en_out <= `WriteDisable;
			cp0_reg_data_out <= `ZeroWord;
		end else if(alu_op_in == `EXE_MTC0_OP) begin
			cp0_reg_w_add_out <= inst_in[15:11];
			cp0_reg_en_out <= `WriteEnable;
			cp0_reg_data_out <= reg1_in;
	  end else begin
			cp0_reg_w_add_out <= 5'b00000;
			cp0_reg_en_out <= `WriteDisable;
			cp0_reg_data_out <= `ZeroWord;
		end				
	end	


endmodule
