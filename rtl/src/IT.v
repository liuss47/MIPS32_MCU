/*
v1:(1)要求在复位rst为高电平时禁�?????????
   (2)搻�基本的指令译码结构，解析指令码和功能�?????????
v1:(1)要求在复位rst为高电平时禁�?????????
   (2)搻�基本的指令译码结构，解析指令码和功能�?????????
   (3)实现对I型指令寄存器操作数和立即操作数的替换
   (4)添加了ori指令

v2:(1)添加接口实现数据回流
   (2)添加回流的操作�?�辑,涉及读操作的输出
*/

`include "defines.v"



module it (
    input wire rst,
    input wire[`InstAddrBus] pc_in,
    input wire[`InstBus] inst_in,

    input wire[`RegBus] data_reg1_in,
    input wire[`RegBus] data_reg2_in,


    //执行阶段EXE的回�????????

    //执行阶段EXE的回�????????

    input wire[`RegBus] ex_w_data_in,
    input wire[`RegAddrBus] ex_w_add_in,
    input wire ex_w_reg_in,


    //访存阶段MEB的回�????????

    //访存阶段MEB的回�????????

    input wire[`RegBus] emb_w_data_in,
    input wire[`RegAddrBus] emb_w_add_in,
    input wire emb_w_reg_in,

    input wire in_delayslot_in,
    input wire[`AluOpBus] ex_alu_op_in,

    output reg reg1_read_out,
    output reg[`RegAddrBus] reg1_add_out,
    output reg reg2_read_out,
    output reg[`RegAddrBus] reg2_add_out,


    output reg[`AluOpBus] alu_op_out, //运算子类�?????????

    output reg[`AluSelBus] alu_sel_out, //运算类型
    output reg[`RegBus] data_reg1_out,
    output reg[`RegBus] data_reg2_out,
    output reg[`RegAddrBus] w_add_out,
    output reg w_reg_out,
    output wire stallreq, //暂停机制信号

    output reg br_flag_out,
    output reg[`RegBus] br_tat_add_out,
    output reg[`RegBus] add_link_out,
    output reg in_delayslot_out,
    output reg next_inst_in_delayslot_out,

    output wire[`RegBus] inst_out,

    //异常处理
    output wire[`RegBus] excepttype_out,
    output wire[`RegBus] current_inst_add_out

);
    /*指令的指令码和功能码*/
    wire[5:0] op = inst_in[31:26];
    wire[4:0] op2 = inst_in[10:6];
    wire[5:0] op3 = inst_in[5:0];
    wire[4:0] op4 = inst_in[20:16];


    /*操作立即�?????????*/
    reg[`RegBus] imm;
    /*指令有效�?????????*/

    reg inst_true;

    /*指令跳转*/
    wire[`RegBus] pc_plus_8;
    wire[`RegBus] pc_plus_4;

    wire[`RegBus] imm_sll2_signedext;

    //异常处理
    reg excepttype_is_syscall;
    reg excepttype_is_eret;
    

    


    assign pc_plus_8 = pc_in + 8;
    assign pc_plus_4 = pc_in + 4;

    //imm_sll2_signedext立即数对应的为指令跳转做的位扩展
    assign imm_sll2_signedext = {{14{inst_in[15]}},inst_in[15:0],2'b00};

    //inst_out译码阶段指令
    assign inst_out = inst_in;

    //load相关变量
    reg stallreq_for_reg1_loadrelate;
    reg stallreq_for_reg2_loadrelate;
    wire pre_inst_ins_load;



    //加载指令相关的判�???
    assign pre_inst_ins_load = ((ex_alu_op_in == `EXE_LB_OP) || 
  													(ex_alu_op_in == `EXE_LBU_OP)||
  													(ex_alu_op_in == `EXE_LH_OP) ||
  													(ex_alu_op_in == `EXE_LHU_OP)||
  													(ex_alu_op_in == `EXE_LW_OP) ||
  													(ex_alu_op_in == `EXE_LWR_OP)||
  													(ex_alu_op_in == `EXE_LWL_OP)||
  													(ex_alu_op_in == `EXE_LL_OP) ||
  													(ex_alu_op_in == `EXE_SC_OP)) ? 1'b1 : 1'b0;

    assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
    //excepttype�?8位保留给外部中断,�?8bit表示是否由syscall引起
    //9bit表示无效指令,12bit表示是否是eret指令,也被认为是返回异�?
    assign excepttype_out ={19'b0 , excepttype_is_eret ,2'b0 , inst_true , excepttype_is_syscall ,8'b0 };
    assign current_inst_add_out = pc_in;
    /*指令译码阶段*/
    always @(*) begin
        if(rst == `RstEnable) 
        begin
            alu_op_out <= `EXE_NOP_OP;
			alu_sel_out <= `EXE_RES_NOP;
			w_add_out <= `NOPRegAddr;
			w_reg_out <= `WriteDisable;
			inst_true <= `InstValid;
			reg1_read_out <= 1'b0;
			reg2_read_out <= 1'b0;
			reg1_add_out <= `NOPRegAddr;
			reg2_add_out <= `NOPRegAddr;
			imm <= 32'h0;
            add_link_out <= `ZeroWord;
            br_tat_add_out <=`ZeroWord;
            br_flag_out <= `NotBranch;
            next_inst_in_delayslot_out <= `NotInDelaySlot;
            excepttype_is_syscall <= `False_v;
			excepttype_is_eret <= `False_v;
        end

        else 
        begin
            alu_op_out <= `EXE_NOP_OP;
			alu_sel_out <= `EXE_RES_NOP;
			w_add_out <= inst_in[15:11];
			w_reg_out <= `WriteDisable;
			inst_true <= `InstInvalid;
			reg1_read_out <= 1'b0;
			reg2_read_out <= 1'b0;
			reg1_add_out <= inst_in[25:21];
			reg2_add_out <= inst_in[20:16];
			imm <= `ZeroWord;
            add_link_out <= `ZeroWord;
            br_tat_add_out <= `ZeroWord;
            br_flag_out <= `NotBranch;
            next_inst_in_delayslot_out <= `NotInDelaySlot;
            excepttype_is_syscall <= `False_v;
            excepttype_is_eret <= `False_v;
    case (op)
        `EXE_SPECIAL_INST:  begin
        case (op2)
            5'b00000:   begin
              case(op3)
                `EXE_OR:
                begin
                    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_OR_OP;
                    alu_sel_out <= `EXE_RES_LOGIC;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                end
                `EXE_AND:	
                begin
                    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_AND_OP;
                    alu_sel_out <= `EXE_RES_LOGIC;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;	
				end  	
		    	`EXE_XOR:	
                begin
		    	    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_XOR_OP;
                    alu_sel_out <= `EXE_RES_LOGIC;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;	
				end  				
		    	`EXE_NOR:	
                begin
		    	    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_NOR_OP;
                    alu_sel_out <= `EXE_RES_LOGIC;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
				end 
				`EXE_SLLV:	
                begin
		    	    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_SLL_OP;
                    alu_sel_out <= `EXE_RES_SHIFT;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
				end
                `EXE_SRLV:
                begin	
		    	    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_SRL_OP;
                    alu_sel_out <= `EXE_RES_SHIFT;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                end				
                `EXE_SRAV:
                begin	
		    	    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_SRA_OP;
                    alu_sel_out <= `EXE_RES_SHIFT;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                end	
                `EXE_SYNC:
                begin	
		    	    w_reg_out <= `WriteDisable;
                    alu_op_out <= `EXE_NOP_OP;
                    alu_sel_out <= `EXE_RES_NOP;
                    reg1_read_out <= 1'b0;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                end
                `EXE_MFHI:
                begin	
		    	    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_MFHI_OP;
                    alu_sel_out <= `EXE_RES_MOVE;
                    reg1_read_out <= 1'b0;
                    reg2_read_out <= 1'b0;
                    inst_true <= `InstValid;
                end
                `EXE_MFLO:
                begin	
		    	    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_MFLO_OP;
                    alu_sel_out <= `EXE_RES_MOVE;
                    reg1_read_out <= 1'b0;
                    reg2_read_out <= 1'b0;
                    inst_true <= `InstValid;
                end
                `EXE_MTHI:
                begin	
		    	    w_reg_out <= `WriteDisable;
                    alu_op_out <= `EXE_MTHI_OP;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b0;
                    inst_true <= `InstValid;
                end
                `EXE_MTLO:
                begin	
		    	    w_reg_out <= `WriteDisable;
                    alu_op_out <= `EXE_MTLO_OP;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b0;
                    inst_true <= `InstValid;
                end
                `EXE_MOVN:
                begin	
                    alu_op_out <= `EXE_MOVN_OP;
                    alu_sel_out <= `EXE_RES_MOVE;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                    if (data_reg2_in != `ZeroWord) begin
                        w_reg_out <= `WriteEnable;
                    end else begin
                        w_reg_out <= `WriteDisable;
                    end
                end
                `EXE_MOVZ:
                begin	
                    alu_op_out <= `EXE_MOVZ_OP;
                    alu_sel_out <= `EXE_RES_MOVE;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                    if (data_reg2_in != `ZeroWord) begin
                        w_reg_out <= `WriteDisable;
                    end else begin
                        w_reg_out <= `WriteEnable;
                    end
                end
                `EXE_SLT:
                begin
                    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_SLT_OP;
                    alu_sel_out <= `EXE_RES_ARITHMETIC;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                end
                `EXE_SLTU:
                begin
                    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_SLTU_OP;
                    alu_sel_out <= `EXE_RES_ARITHMETIC;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                end
                `EXE_ADD:
                begin
                    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_ADD_OP;
                    alu_sel_out <= `EXE_RES_ARITHMETIC;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                end
                `EXE_ADDU:
                begin
                    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_ADDU_OP;
                    alu_sel_out <= `EXE_RES_ARITHMETIC;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                end
                `EXE_SUB:
                begin
                    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_SUB_OP;
                    alu_sel_out <= `EXE_RES_ARITHMETIC;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                end
                `EXE_SUBU:
                begin
                    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_SUBU_OP;
                    alu_sel_out <= `EXE_RES_ARITHMETIC;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                end
                `EXE_MULT:
                begin
                    w_reg_out <= `WriteDisable;
                    alu_op_out <= `EXE_MULT_OP;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                end
                `EXE_MULTU:
                begin
                    w_reg_out <= `WriteDisable;
                    alu_op_out <= `EXE_MULTU_OP;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                end
                `EXE_JR:
                begin
                    w_reg_out <= `WriteDisable;
                    alu_op_out <= `EXE_JR_OP;
                    alu_sel_out <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b0;
                    add_link_out <= `ZeroWord;
                    br_tat_add_out <= data_reg1_out;
                    br_flag_out <= `Branch;
                    next_inst_in_delayslot_out <= `InDelaySlot;
                    inst_true <= `InstValid;
                end
                `EXE_JALR:
                begin
                    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_JALR_OP;
                    alu_sel_out <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b0;
                    w_add_out <= inst_in[15:11];
                    add_link_out <= pc_plus_8;
                    br_tat_add_out <= data_reg1_out;
                    br_flag_out <= `Branch;
                    next_inst_in_delayslot_out <= `InDelaySlot;
                    inst_true <= `InstValid;
                end
                default:
                begin
                end	
              endcase
            end          
            default:begin
            end
        endcase
        case (op3)
						    `EXE_TEQ: begin
								w_reg_out <= `WriteDisable;	
                                alu_op_out <= `EXE_TEQ_OP;
		  						alu_sel_out <= `EXE_RES_NOP;   
                                reg1_read_out<= 1'b0;	
                                reg2_read_out <= 1'b0;
		  					inst_true <= `InstValid;
		  					end
		  					`EXE_TGE: begin
								w_reg_out <= `WriteDisable;	
                                alu_op_out <= `EXE_TGE_OP;
		  						alu_sel_out <= `EXE_RES_NOP;   
                                reg1_read_out<= 1'b1;	
                                reg2_read_out <= 1'b1;
		  					inst_true <= `InstValid;
		  					end		
		  					`EXE_TGEU: begin
								w_reg_out <= `WriteDisable;	
                                alu_op_out <= `EXE_TGEU_OP;
		  						alu_sel_out <= `EXE_RES_NOP;   
                                reg1_read_out<= 1'b1;	
                                reg2_read_out <= 1'b1;
		  					inst_true <= `InstValid;
		  					end	
		  					`EXE_TLT: begin
								w_reg_out <= `WriteDisable;
                                alu_op_out <= `EXE_TLT_OP;
		  						alu_sel_out <= `EXE_RES_NOP;   
                                reg1_read_out<= 1'b1;	
                                reg2_read_out <= 1'b1;
		  					inst_true <= `InstValid;
		  					end
		  					`EXE_TLTU: begin
								w_reg_out <= `WriteDisable;		
                                alu_op_out <= `EXE_TLTU_OP;
		  						alu_sel_out <= `EXE_RES_NOP;   
                                reg1_read_out<= 1'b1;	
                                reg2_read_out <= 1'b1;
		  					inst_true <= `InstValid;
		  					end	
		  					`EXE_TNE: begin
								w_reg_out <= `WriteDisable;		
                                alu_op_out <= `EXE_TNE_OP;
		  						alu_sel_out <= `EXE_RES_NOP;   
                                reg1_read_out<= 1'b1;	
                                reg2_read_out <= 1'b1;
		  					inst_true <= `InstValid;
		  					end
		  					`EXE_SYSCALL: begin
								w_reg_out <= `WriteDisable;		
                                alu_op_out <= `EXE_SYSCALL_OP;
		  						alu_sel_out <= `EXE_RES_NOP;   
                                reg1_read_out<= 1'b0;	
                                reg2_read_out <= 1'b0;
		  					inst_true <= `InstValid; 
                                excepttype_is_syscall<= `True_v;
		  					end							 																					
								default:	begin
								end	
		endcase				
        end
        `EXE_ORI: 			
        begin                        
            w_reg_out <= `WriteEnable;		
            alu_op_out <= `EXE_OR_OP;
            alu_sel_out <= `EXE_RES_LOGIC; 
            reg1_read_out <= 1'b1;	
            reg2_read_out <= 1'b0;	  	
            imm <= {16'h0, inst_in[15:0]};		
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_ANDI:			
        begin                        
            w_reg_out <= `WriteEnable;		
            alu_op_out <= `EXE_AND_OP;
            alu_sel_out <= `EXE_RES_LOGIC; 
            reg1_read_out <= 1'b1;	
            reg2_read_out <= 1'b0;	  	
            imm <= {16'h0, inst_in[15:0]};		
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_XORI:			
        begin                        
            w_reg_out <= `WriteEnable;		
            alu_op_out <= `EXE_XOR_OP;
            alu_sel_out <= `EXE_RES_LOGIC; 
            reg1_read_out <= 1'b1;	
            reg2_read_out <= 1'b0;	  	
            imm <= {16'h0, inst_in[15:0]};		
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_LUI:			
        begin                        
            w_reg_out <= `WriteEnable;		
            alu_op_out <= `EXE_OR_OP;
            alu_sel_out <= `EXE_RES_LOGIC; 
            reg1_read_out <= 1'b1;	
            reg2_read_out <= 1'b0;	  	
            imm <= {inst_in[15:0],16'h0};		
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_PREF:			
        begin                        
            w_reg_out <= `WriteDisable;		
            alu_op_out <= `EXE_NOP_OP;
            alu_sel_out <= `EXE_RES_NOP; 
            reg1_read_out <= 1'b0;	
            reg2_read_out <= 1'b0;	  	
            inst_true <= `InstValid;
        end
        `EXE_SLTI:			
        begin                        
            w_reg_out <= `WriteEnable;		
            alu_op_out <= `EXE_SLTI_OP;
            alu_sel_out <= `EXE_RES_ARITHMETIC; 
            reg1_read_out <= 1'b1;	
            reg2_read_out <= 1'b0;
            imm <= {{16{inst_in[15]}},inst_in[15:0]};	
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_SLTIU:			
        begin                        
            w_reg_out <= `WriteEnable;		
            alu_op_out <= `EXE_SLTIU_OP;
            alu_sel_out <= `EXE_RES_ARITHMETIC; 
            reg1_read_out <= 1'b1;	
            reg2_read_out <= 1'b0;
            imm <= {{16{inst_in[15]}},inst_in[15:0]};	
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_ADDI:			
        begin                        
            w_reg_out <= `WriteEnable;		
            alu_op_out <= `EXE_ADDI_OP;
            alu_sel_out <= `EXE_RES_ARITHMETIC; 
            reg1_read_out <= 1'b1;	
            reg2_read_out <= 1'b0;
            imm <= {{16{inst_in[15]}},inst_in[15:0]};	
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_ADDIU:			
        begin                        
            w_reg_out <= `WriteEnable;		
            alu_op_out <= `EXE_ADDIU_OP;
            alu_sel_out <= `EXE_RES_ARITHMETIC; 
            reg1_read_out <= 1'b1;	
            reg2_read_out <= 1'b0;
            imm <= {{16{inst_in[15]}},inst_in[15:0]};	
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_SPECIAL2_INST:
        begin
            case(op3)
                `EXE_CLZ: 
                begin
                    w_reg_out <= `WriteEnable;		
                    alu_op_out <= `EXE_CLZ_OP;
                    alu_sel_out <= `EXE_RES_ARITHMETIC; 
                    reg1_read_out <= 1'b1;	
                    reg2_read_out <= 1'b0;
                    inst_true <= `InstValid;
                end
                `EXE_CLO: 
                begin
                    w_reg_out <= `WriteEnable;		
                    alu_op_out <= `EXE_CLO_OP;
                    alu_sel_out <= `EXE_RES_ARITHMETIC; 
                    reg1_read_out <= 1'b1;	
                    reg2_read_out <= 1'b0;
                    inst_true <= `InstValid;
                end
                `EXE_MUL: 
                begin
                    w_reg_out <= `WriteEnable;		
                    alu_op_out <= `EXE_MUL_OP;
                    alu_sel_out <= `EXE_RES_MUL; 
                    reg1_read_out <= 1'b1;	
                    reg2_read_out <= 1'b1;
                    inst_true <= `InstValid;
                end
                default: begin 
                
                end
            endcase
    
        end
        `EXE_J:
        begin
            w_reg_out <= `WriteDisable;
            alu_op_out <= `EXE_J_OP;
            alu_sel_out <= `EXE_RES_JUMP_BRANCH;
            reg1_read_out <= 1'b0;
            reg2_read_out <= 1'b0;
            add_link_out <= `ZeroWord;
            br_flag_out <= `Branch;
            next_inst_in_delayslot_out <= `InDelaySlot;
            inst_true <= `InstValid;
            br_tat_add_out <= {pc_plus_4[31:28],inst_in[25:0],2'b00};
        end
        `EXE_JAL:
        begin
            w_reg_out <= `WriteEnable;
            alu_op_out <= `EXE_JAL_OP;
            alu_sel_out <= `EXE_RES_JUMP_BRANCH;
            reg1_read_out <= 1'b0;
            reg2_read_out <= 1'b0;
            w_add_out <= 5'b11111;
            add_link_out <= pc_plus_8;
            br_flag_out <= `Branch;
            next_inst_in_delayslot_out <= `InDelaySlot;
            inst_true <= `InstValid;
            br_tat_add_out <= {pc_plus_4[31:28],inst_in[25:0],2'b00};
        end
        `EXE_BEQ:
        begin
            w_reg_out <= `WriteDisable;
            alu_op_out <= `EXE_BEQ_OP;
            alu_sel_out <= `EXE_RES_JUMP_BRANCH;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b1;
            inst_true <= `InstValid;
            if(data_reg1_out == data_reg2_out)
            begin
            br_flag_out <= `Branch;
            next_inst_in_delayslot_out <= `InDelaySlot;
            br_tat_add_out <= pc_plus_4 + imm_sll2_signedext;
            end
        end
        `EXE_BGTZ:
        begin
            w_reg_out <= `WriteDisable;
            alu_op_out <= `EXE_BGTZ_OP;
            alu_sel_out <= `EXE_RES_JUMP_BRANCH;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b0;
            inst_true <= `InstValid;
            if((data_reg1_out[31] == 1'b0) && (data_reg1_out != `ZeroWord))
            begin
            br_flag_out <= `Branch;
            next_inst_in_delayslot_out <= `InDelaySlot;
            br_tat_add_out <= pc_plus_4 + imm_sll2_signedext;
            end
        end
        `EXE_BLEZ:
        begin
            w_reg_out <= `WriteDisable;
            alu_op_out <= `EXE_BLEZ_OP;
            alu_sel_out <= `EXE_RES_JUMP_BRANCH;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b0;
            inst_true <= `InstValid;
            if((data_reg1_out[31] == 1'b1) && (data_reg1_out != `ZeroWord))
            begin
            br_flag_out <= `Branch;
            next_inst_in_delayslot_out <= `InDelaySlot;
            br_tat_add_out <= pc_plus_4 + imm_sll2_signedext;
            end
        end
        `EXE_BNE:
        begin
            w_reg_out <= `WriteDisable;
            alu_op_out <= `EXE_BNE_OP;
            alu_sel_out <= `EXE_RES_JUMP_BRANCH;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b1;
            inst_true <= `InstValid;
            if(data_reg1_out != data_reg2_out)
            begin
            br_flag_out <= `Branch;
            next_inst_in_delayslot_out <= `InDelaySlot;
            br_tat_add_out <= pc_plus_4 + imm_sll2_signedext;
            end
        end
        `EXE_REGIMM_INST:   begin
            case (op4)
                `EXE_BGEZ:
                begin
                    w_reg_out <= `WriteDisable;
                    alu_op_out <= `EXE_BGEZ_OP;
                    alu_sel_out <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b0;
                    inst_true <= `InstValid;
                    if(data_reg1_out[31] == 1'b0)
                    begin
                    br_flag_out <= `Branch;
                    next_inst_in_delayslot_out <= `InDelaySlot;
                    br_tat_add_out <= pc_plus_4 + imm_sll2_signedext;
                    end
                end
                `EXE_BGEZAL:
                begin
                    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_BGEZAL_OP;
                    alu_sel_out <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b0;
                    add_link_out <= pc_plus_8;
                    w_add_out <= 5'b11111;
                    inst_true <= `InstValid;
                    if(data_reg1_out[31] == 1'b0)
                    begin
                    br_flag_out <= `Branch;
                    next_inst_in_delayslot_out <= `InDelaySlot;
                    br_tat_add_out <= pc_plus_4 + imm_sll2_signedext;
                    end
                end
                `EXE_BLTZ:
                begin
                    w_reg_out <= `WriteDisable;
                    alu_op_out <= `EXE_BLTZ_OP;
                    alu_sel_out <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b0;
                    inst_true <= `InstValid;
                    if(data_reg1_out[31] == 1'b1)
                    begin
                    br_flag_out <= `Branch;
                    next_inst_in_delayslot_out <= `InDelaySlot;
                    br_tat_add_out <= pc_plus_4 + imm_sll2_signedext;
                    end
                end
                `EXE_BLTZAL:
                begin
                    w_reg_out <= `WriteEnable;
                    alu_op_out <= `EXE_BLTZAL_OP;
                    alu_sel_out <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_out <= 1'b1;
                    reg2_read_out <= 1'b0;
                    add_link_out <= pc_plus_8;
                    w_add_out <= 5'b11111;
                    inst_true <= `InstValid;
                    if(data_reg1_out[31] == 1'b1)
                    begin
                    br_flag_out <= `Branch;
                    next_inst_in_delayslot_out <= `InDelaySlot;
                    br_tat_add_out <= pc_plus_4 + imm_sll2_signedext;
                    end
                end
                        `EXE_TEQI:			begin
		  				w_reg_out <= `WriteDisable;		
                        alu_op_out <= `EXE_TEQI_OP;
		  				alu_sel_out <= `EXE_RES_NOP; 
                        reg1_read_out<= 1'b1;	
                        reg2_read_out<= 1'b0;	  	
						imm <= {{16{inst_in[15]}}, inst_in[15:0]};		  	
						inst_true<= `InstValid;	
						end
						`EXE_TGEI:			begin
		  				w_reg_out <= `WriteDisable;		
                        alu_op_out <= `EXE_TGEI_OP;
		  				alu_sel_out <= `EXE_RES_NOP; 
                        reg1_read_out<= 1'b1;	
                        reg2_read_out<= 1'b0;	  	
						imm <= {{16{inst_in[15]}}, inst_in[15:0]};		  	
						inst_true<= `InstValid;	
						end
						`EXE_TGEIU:			begin
		  				w_reg_out <= `WriteDisable;		
                        alu_op_out <= `EXE_TGEIU_OP;
		  				alu_sel_out <= `EXE_RES_NOP; 
                        reg1_read_out<= 1'b1;	
                        reg2_read_out<= 1'b0;	  	
						imm <= {{16{inst_in[15]}}, inst_in[15:0]};		  	
						inst_true<= `InstValid;	
						end
						`EXE_TLTI:			begin
		  				w_reg_out <= `WriteDisable;		
                        alu_op_out <= `EXE_TLTI_OP;
		  				alu_sel_out <= `EXE_RES_NOP; 
                        reg1_read_out<= 1'b1;	
                        reg2_read_out<= 1'b0;	  	
						imm <= {{16{inst_in[15]}}, inst_in[15:0]};		  	
						inst_true<= `InstValid;	
						end
						`EXE_TLTIU:			begin
		  				w_reg_out <= `WriteDisable;		
                        alu_op_out <= `EXE_TLTIU_OP;
		  				alu_sel_out <= `EXE_RES_NOP; 
                        reg1_read_out<= 1'b1;	
                        reg2_read_out<= 1'b0;	  	
						imm <= {{16{inst_in[15]}}, inst_in[15:0]};		  	
						inst_true<= `InstValid;	
						end
						`EXE_TNEI:			begin
		  				w_reg_out <= `WriteDisable;		
                        alu_op_out <= `EXE_TNEI_OP;
		  				alu_sel_out <= `EXE_RES_NOP; 
                        reg1_read_out<= 1'b1;	
                        reg2_read_out<= 1'b0;	  	
						imm <= {{16{inst_in[15]}}, inst_in[15:0]};		  	
						inst_true<= `InstValid;	
						end
                default:begin
                end
                endcase
                end
        `EXE_LB: 
        begin
            w_reg_out <= `WriteEnable;
            alu_op_out <= `EXE_LB_OP;
            alu_sel_out <= `EXE_RES_LOAD_STORE;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b0;
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_LBU: 
        begin
            w_reg_out <= `WriteEnable;
            alu_op_out <= `EXE_LBU_OP;
            alu_sel_out <= `EXE_RES_LOAD_STORE;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b0;
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_LH: 
        begin
            w_reg_out <= `WriteEnable;
            alu_op_out <= `EXE_LH_OP;
            alu_sel_out <= `EXE_RES_LOAD_STORE;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b0;
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_LHU: 
        begin
            w_reg_out <= `WriteEnable;
            alu_op_out <= `EXE_LHU_OP;
            alu_sel_out <= `EXE_RES_LOAD_STORE;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b0;
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_LW: 
        begin
            w_reg_out <= `WriteEnable;
            alu_op_out <= `EXE_LW_OP;
            alu_sel_out <= `EXE_RES_LOAD_STORE;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b0;
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_LWL: 
        begin
            w_reg_out <= `WriteEnable;
            alu_op_out <= `EXE_LWL_OP;
            alu_sel_out <= `EXE_RES_LOAD_STORE;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b1;
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_LWR: 
        begin
            w_reg_out <= `WriteEnable;
            alu_op_out <= `EXE_LWR_OP;
            alu_sel_out <= `EXE_RES_LOAD_STORE;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b1;
            w_add_out <= inst_in[20:16];
            inst_true <= `InstValid;
        end
        `EXE_SB: 
        begin
            w_reg_out <= `WriteDisable;
            alu_op_out <= `EXE_SB_OP;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b1;
            inst_true <= `InstValid;
            alu_sel_out <= `EXE_RES_LOAD_STORE;
        end
        `EXE_SH: 
        begin
            w_reg_out <= `WriteDisable;
            alu_op_out <= `EXE_SH_OP;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b1;
            inst_true <= `InstValid;
            alu_sel_out <= `EXE_RES_LOAD_STORE;
        end
        `EXE_SW: 
        begin
            w_reg_out <= `WriteDisable;
            alu_op_out <= `EXE_SW_OP;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b1;
            inst_true <= `InstValid;
            alu_sel_out <= `EXE_RES_LOAD_STORE;
        end
        `EXE_SWL: 
        begin
            w_reg_out <= `WriteDisable;
            alu_op_out <= `EXE_SWL_OP;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b1;
            inst_true <= `InstValid;
            alu_sel_out <= `EXE_RES_LOAD_STORE;
        end
        `EXE_SWR: 
        begin
            w_reg_out <= `WriteDisable;
            alu_op_out <= `EXE_SWR_OP;
            reg1_read_out <= 1'b1;
            reg2_read_out <= 1'b1;
            inst_true <= `InstValid;
            alu_sel_out <= `EXE_RES_LOAD_STORE;
        end
        
        default:begin
        end
        
    endcase
        
    if(inst_in == `EXE_ERET)
    begin
        w_reg_out <= `WriteDisable;
        alu_op_out <= `EXE_ERET_OP;
        alu_sel_out <= `EXE_RES_NOP;
        reg1_read_out <= 1'b0;
        reg2_read_out <= 1'b0;
        inst_true <= `InstValid;
        excepttype_is_eret <= `True_v;
    end



    if(inst_in[31:21] == 11'b00000000000)
    begin
        if(op3 == `EXE_SLL)
        begin
            w_reg_out <= `WriteEnable;		
            alu_op_out <= `EXE_SLL_OP;
            alu_sel_out <= `EXE_RES_SHIFT; 
            reg1_read_out <= 1'b0;	
            reg2_read_out <= 1'b1;	  	
            imm[4:0] <=  inst_in[10:6];		
            w_add_out <= inst_in[15:11];
            inst_true <= `InstValid;
        end
        else if(op3 == `EXE_SRL)
        begin
            w_reg_out <= `WriteEnable;		
            alu_op_out <= `EXE_SRL_OP;
            alu_sel_out <= `EXE_RES_SHIFT; 
            reg1_read_out <= 1'b0;	
            reg2_read_out <= 1'b1;	  	
            imm[4:0] <=  inst_in[10:6];		
            w_add_out <= inst_in[15:11];
            inst_true <= `InstValid;
        end
        else if(op3 == `EXE_SRA)
        begin
            w_reg_out <= `WriteEnable;		
            alu_op_out <= `EXE_SRA_OP;
            alu_sel_out <= `EXE_RES_SHIFT; 
            reg1_read_out <= 1'b0;	
            reg2_read_out <= 1'b1;	  	
            imm[4:0] <=  inst_in[10:6];		
            w_add_out <= inst_in[15:11];
            inst_true <= `InstValid;
        end
    end
    
    if(inst_in[31:21] == 11'b01000000000 && inst_in[10:0] == 11'b00000000000) begin
				alu_op_out <= `EXE_MFC0_OP;
				alu_sel_out <= `EXE_RES_MOVE;
				w_add_out <= inst_in[20:16];
				w_reg_out <= `WriteEnable;
				inst_true <= `InstValid;	   
				reg1_read_out <= 1'b0;
				reg2_read_out <= 1'b0;		
			end else if(inst_in[31:21] == 11'b01000000100 && inst_in[10:0] == 11'b00000000000) begin
				alu_op_out <= `EXE_MTC0_OP;
				alu_sel_out <= `EXE_RES_NOP;
				w_reg_out <= `WriteDisable;
				inst_true <= `InstValid;	   
				reg1_read_out <= 1'b1;
				reg1_add_out <= inst_in[20:16];
				reg2_read_out <= 1'b0;		
			end
    end
end

    //延迟槽判�??????

    //延迟槽判�??????
    always @(*) begin
        if(rst == `RstEnable) begin
            in_delayslot_out <= `NotInDelaySlot;
        end else begin
            in_delayslot_out <= in_delayslot_in;
        end
    end


    /*对两个读出的数据端进行修�?????????*/
    /*对两个读出的数据端进行修�?????????*/
    always @ (*) begin
        stallreq_for_reg1_loadrelate <= `NoStop;
        if(rst == `RstEnable) begin
		    data_reg1_out <= `ZeroWord;
        end else if((pre_inst_ins_load == 1'b1) && (ex_w_add_in == reg1_add_out) && reg1_read_out == 1)
        begin
            stallreq_for_reg1_loadrelate <= `Stop;
        end
        else if((reg1_read_out == 1'b1)&&(ex_w_reg_in == 1'b1)
        &&(reg1_add_out == ex_w_add_in)) begin
            data_reg1_out <= ex_w_data_in;
        end
        else if((reg1_read_out == 1'b1)&&(emb_w_reg_in == 1'b1)
        &&(reg1_add_out == emb_w_add_in)) begin
            data_reg1_out <= emb_w_data_in;
        end
        else if(reg1_read_out == 1'b1) begin
	  	    data_reg1_out <= data_reg1_in;
	    end 
        else if(reg1_read_out == 1'b0) begin
	  	    data_reg1_out <= imm;
	    end 
        else begin
	        data_reg1_out <= `ZeroWord;
	    end
    end

    always @ (*) begin
        stallreq_for_reg2_loadrelate <= `NoStop;
        if(rst == `RstEnable) begin
		    data_reg2_out <= `ZeroWord;
    	end else if((pre_inst_ins_load == 1'b1) && (ex_w_add_in == reg2_add_out) && reg2_read_out == 1)
        begin
            stallreq_for_reg2_loadrelate <= `Stop;
        end
        else if((reg2_read_out == 1'b1)&&(ex_w_reg_in == 1'b1)
        &&(reg2_add_out == ex_w_add_in)) begin
            data_reg2_out <= ex_w_data_in;
        end
        else if((reg2_read_out == 1'b1)&&(emb_w_reg_in == 1'b1)
        &&(reg2_add_out == emb_w_add_in)) begin
            data_reg2_out <= emb_w_data_in;
        end
        else if(reg2_read_out == 1'b1) begin
	  	    data_reg2_out <= data_reg2_in;
	    end 
        else if(reg2_read_out == 1'b0) begin
	  	    data_reg2_out <= imm;
	    end 
        else begin
	        data_reg2_out <= `ZeroWord;
	    end
    end

endmodule
