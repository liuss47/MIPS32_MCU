/*
V1:基本的模块连接封�????????



*/

`include "defines.v"

module mips32_core (
    input wire clk,
    input wire rst,
    input wire[5:0] int_i,
    input wire[`RegBus] rom_data_in,
    output wire[`RegBus] rom_add_out,
    output wire rom_en_out,
    output wire timer_int_o,
    //数据RAM
    input wire[`RegBus] ram_data_in,
    output wire[`RegBus] ram_add_out,
    output wire[`RegBus] ram_data_out,
    output wire ram_en_out,
    output wire[3:0] ram_sel_out,
    output wire ram_ce_out
);
    //IF_IT and IT
    wire[`InstAddrBus] pc;
    wire[`InstAddrBus] it_pc_in;
    wire[`InstBus] it_inst_in;
    
    //IT输出和IT_EXE输入
    wire[`AluOpBus] it_alu_op_out;
    wire[`AluSelBus] it_alu_sel_out;
    wire[`RegBus] it_reg1_out;
    wire[`RegBus] it_reg2_out;
    wire    it_w_reg_out;
    wire[`RegAddrBus] it_w_add_out;

    //IT_EXE
    wire[`AluOpBus] ex_alu_op_in;
    wire[`AluSelBus] ex_alu_sel_in;
    wire[`RegBus] ex_reg1_in;
    wire[`RegBus] ex_reg2_in;
    wire    ex_w_reg_in;
    wire[`RegAddrBus] ex_w_add_in;
 
    //EXE输出 EXE_MEB输入
    wire ex_w_reg_out;
    wire[`RegAddrBus] ex_w_add_out;
    wire[`RegBus] ex_w_data_out;

    //EX_MEB输出 MEB输入
    wire meb_w_reg_in;
    wire[`RegAddrBus] meb_w_add_in;
    wire[`RegBus] meb_w_data_in;


    //MEB输出 MEB_WB输入
    wire meb_w_reg_out;
    wire[`RegAddrBus] meb_w_add_out;
    wire[`RegBus] meb_w_data_out;

    //MEB_WB的输出和回写阶段的输�????????
    wire wb_w_reg_in;
    wire[`RegAddrBus] wb_w_add_in;
    wire[`RegBus] wb_w_data_in;

    //ID与REG group 的连�????????
    wire reg1_read;
    wire reg2_read;
    wire[`RegBus] reg1_data;
    wire[`RegBus] reg2_data;
    wire[`RegAddrBus] reg1_add;
    wire[`RegAddrBus] reg2_add;

    wire [`RegBus]  hi_out_hilo;
    wire [`RegBus]  lo_out_hilo;
    wire            hilo_out_exe;
    wire [`RegBus]  hi_out_exe;
    wire [`RegBus]  lo_out_exe;
    wire [`RegBus] meb_hi_out;
    wire [`RegBus] meb_lo_out;
    wire           meb_hilo_out;
    wire [`RegBus]     hi_out_meb;
    wire [`RegBus]     lo_out_meb;
    wire               hilo_out_meb;
    wire [`RegBus]     wb_hi_out;
    wire [`RegBus]     wb_lo_out;
    wire               wb_hilo_out;   

    //涉及暂停机制的连�??????
    wire[5:0] stall_out;
    wire stallreq_from_ex_out;
    wire stallreq_from_it_out;
    
    //涉及延迟槽的连线
    wire br_flag_ID_PC;
    wire[`RegBus] br_tat_add_ID_PC;
    wire next_inst_in_delayslot_ID_IDEX;
    wire in_delayslot_ID_IDEX;
    wire[`RegBus] add_link_ID_IDEX;
    wire ex_in_delayslot_IDEX_EX;
    wire[`RegBus] ex_add_link_IDEX_EX;
    wire in_delayslot_IDEX_ID;

    //加载存储的连�?????
    wire[`RegBus] inst_out_ID_IDEX;
    wire[`RegBus] ex_inst_IDEX_EX;
    wire[`AluOpBus] alu_op_EX_EXMEB;
    wire[`RegBus] meb_add_out_EX_EXMEB;
    wire[`RegBus] reg2_out_EX_EXMEB;
    wire[`AluOpBus] meb_alu_op_EXMEB_MEB;
    wire[`RegBus] meb_meb_add_EXMEB_MEB;
    wire[`RegBus] meb_reg2_EXMEB_MEB;

    //加载相关

    //cp0相关
    wire[4:0] cp0_reg_read_add_out_EX_cp0;
    wire[`RegBus] cp0_reg_data_out_EX_EXMEB;
    wire[4:0] cp0_reg_w_add_out_EX_EXMEB;
    wire cp0_reg_en_out_EX_EXMEB;
    wire[`RegBus] meb_cp0_reg_data_EXMEB_MEB;
    wire[4:0]meb_cp0_reg_w_add_EXMEB_MEB;
    wire meb_cp0_reg_en_EXMEB_MEB;
    wire[`RegBus] cp0_reg_data_out_MEB_MEBWB;
    wire[4:0] cp0_reg_w_add_out_MEB_MEBWB;
    wire cp0_reg_en_out_MEB_MEBWB;
    wire[`RegBus] wb_cp0_reg_data_MEBWB_cp0;
    wire[4:0]wb_cp0_reg_w_add_MEBWB_cp0;
    wire wb_cp0_reg_en_MEBWB_cp0;
    wire[`RegBus] cp0_data_out;

    //异常处理
    wire[`RegBus] excepttype_out_ID_IDEX;
    wire[`RegBus] current_inst_add_out_ID_IDEX;

    wire[`RegBus] ex_excepttype_out_IDEX_EX;
    wire[`RegBus] ex_current_inst_add_out_IDEX_EX;

    wire[`RegBus] excepttype_out_EX_EXMEB;
    wire[`RegBus] current_inst_add_out_EX_EXMEB;
    wire in_delayslot_EX_EXMEB;

    wire[`RegBus] meb_excepttype_out_EXMEB_MEB;
    wire[`RegBus] meb_current_inst_add_out_EXMEB_MEB;
    wire meb_in_delayslot_EXMEB_MEB;

    wire[`RegBus] cp0_status_in_cp0_MEB;
    wire[`RegBus] cp0_cause_in_cp0_MEB;
    wire[`RegBus] cp0_epc_in_cp0_MEB;

    wire[`RegBus] excepttype_out_MEB_cp0;
    wire[`RegBus] current_inst_add_out_MEB_cp0;
    wire in_delayslot_out_MEB_cp0;
    wire[`RegBus] cp0_epc_out_MEB_CTRL;

    wire flush_CTRL;
    wire[`RegBus] new_pc_CTRL;

    //实例化pc_reg
    pc_reg pc_reg0(
        .clk(clk),  
        .rst(rst),  
        .pc(pc),
        .en(rom_en_out),
        .stall(stall_out),
        .br_flag_in(br_flag_ID_PC),
        .br_tat_add_in(br_tat_add_ID_PC),
        .new_pc(new_pc_CTRL),
        .flush(flush_CTRL)
    );
    
    assign rom_add_out = pc;

    //实例化IF_IT
    if_it if_it0(
        .clk(clk),
        .rst(rst),
        .if_pc(pc),
        .if_inst(rom_data_in),
        .it_pc(it_pc_in),
        .it_inst(it_inst_in),
        .stall(stall_out),
        .flush(flush_CTRL)
    );
    
    //实例化IT
    it it0(
        .rst(rst),
        .pc_in(it_pc_in),
        .inst_in(it_inst_in),
        
        //reg_group的输�????????
        .data_reg1_in(reg1_data),
        .data_reg2_in(reg2_data),

        //输出到reg_group
        .reg1_read_out(reg1_read),
        .reg2_read_out(reg2_read),
        .reg1_add_out(reg1_add),
        .reg2_add_out(reg2_add),

        //输出到ID_EX
        .alu_op_out(it_alu_op_out),
        .alu_sel_out(it_alu_sel_out),
        .data_reg1_out(it_reg1_out),
        .data_reg2_out(it_reg2_out),
        .w_add_out(it_w_add_out),
        .w_reg_out(it_w_reg_out),

        //MEB和EXE数据回流
        .emb_w_add_in(meb_w_add_out),
        .emb_w_data_in(meb_w_data_out),
        .emb_w_reg_in(meb_w_reg_out),
        .ex_w_add_in(ex_w_add_out),
        .ex_w_data_in(ex_w_data_out),
        .ex_w_reg_in(ex_w_reg_out),

        //暂停机制
        .stallreq(stallreq_from_it_out),

        //延迟�??????
        .br_flag_out(br_flag_ID_PC),
        .br_tat_add_out(br_tat_add_ID_PC),
        .next_inst_in_delayslot_out(next_inst_in_delayslot_ID_IDEX),
        .in_delayslot_out(in_delayslot_ID_IDEX),
        .add_link_out(add_link_ID_IDEX),
        .in_delayslot_in(in_delayslot_IDEX_ID),

        //加载存储
        .inst_out(inst_out_ID_IDEX),

        //加载相关
        .ex_alu_op_in(alu_op_EX_EXMEB),

        //异常处理
        .excepttype_out(excepttype_out_ID_IDEX),
        .current_inst_add_out(current_inst_add_out_ID_IDEX)
    );

    //例化寄存器组reg_group
    reg_group reg_group0(
        .clk(clk),
        .rst(rst),
        .w_en(wb_w_reg_in),
        .w_add(wb_w_add_in),
        .w_data(wb_w_data_in),
        .reg1_en(reg1_read),
        .reg1_add(reg1_add),
        .data_reg1(reg1_data),
        .reg2_en(reg2_read),
        .reg2_add(reg2_add),
        .data_reg2(reg2_data)
    );

    //例化IT_EXE
    it_exe it_exe0(
        .clk(clk),
        .rst(rst),
        
        //从IT模块传�?�来的信�????????
        .it_alu_op(it_alu_op_out),
        .it_alu_sel(it_alu_sel_out),
        .it_reg1(it_reg1_out),
        .it_reg2(it_reg2_out),
        .it_w_add(it_w_add_out),
        .it_w_reg(it_w_reg_out),
        
        //传�?�到EXE阶段的信�????????
        .ex_alu_op(ex_alu_op_in),
        .ex_alu_sel(ex_alu_sel_in),
        .ex_reg1(ex_reg1_in),
        .ex_reg2(ex_reg2_in),
        .ex_w_add(ex_w_add_in),
        .ex_w_reg(ex_w_reg_in),
        
        .stall(stall_out),

        //延迟�??????
        .it_in_delayslot(in_delayslot_ID_IDEX),
        .it_add_link(add_link_ID_IDEX),
        .next_inst_in_delayslot_in(next_inst_in_delayslot_ID_IDEX),
        .ex_in_delayslot(ex_in_delayslot_IDEX_EX),
        .ex_add_link(ex_add_link_IDEX_EX),
        .in_delayslot_out(in_delayslot_IDEX_ID),

        //加载存储
        .it_inst(inst_out_ID_IDEX),
        .ex_inst(ex_inst_IDEX_EX),

        //异常处理
        .flush(flush_CTRL),
        .it_excepttype(excepttype_out_ID_IDEX),
        .it_current_inst_add(current_inst_add_out_ID_IDEX),
        .ex_excepttype(ex_excepttype_out_IDEX_EX),
        .ex_current_inst_add(ex_current_inst_add_out_IDEX_EX)
    );


    //例化EXE模块
    exe exe0(
        
        .rst(rst),

        //接受IT_EX模块传�?�来的信�????????
        .alu_op_in(ex_alu_op_in),
        .alu_sel_in(ex_alu_sel_in),
        .reg1_in(ex_reg1_in),
        .reg2_in(ex_reg2_in),
        .w_add_in(ex_w_add_in),
        .w_reg_in(ex_w_reg_in),
        .hi_in(hi_out_hilo),
        .lo_in(lo_out_hilo),
        .wb_hi_in(wb_hi_out),
        .wb_lo_in(wb_lo_out),
        .wb_hilo_in(wb_hilo_out),
        .meb_hi_in(hi_out_meb),
        .meb_lo_in(lo_out_meb),
        .meb_hilo_in(hilo_out_meb),

        //输出到EXE_MEB的信�????????
        .w_data_out(ex_w_data_out),
        .w_add_out(ex_w_add_out),
        .w_reg_out(ex_w_reg_out),
        .hilo_out   (hilo_out_exe),
        .hi_out     (hi_out_exe),
        .lo_out     (lo_out_exe),

        .stallreq_from_ex(stallreq_from_ex_out),

        //延迟�??????
        .in_delayslot_in(ex_in_delayslot_IDEX_EX),
        .add_link_in(ex_add_link_IDEX_EX),

        //加载存储
        .inst_in(ex_inst_IDEX_EX),
        .alu_op_out(alu_op_EX_EXMEB),
        .meb_add_out(meb_add_out_EX_EXMEB),
        .data_r2_out(reg2_out_EX_EXMEB),

        //加载相关

        //cp0相关
        .cp0_reg_data_in(cp0_data_out),
        .wb_cp0_reg_data(wb_cp0_reg_data_MEBWB_cp0),
        .wb_cp0_reg_w_add(wb_cp0_reg_w_add_MEBWB_cp0),
        .wb_cp0_reg_en(wb_cp0_reg_en_MEBWB_cp0),
        .meb_cp0_reg_data(cp0_reg_data_out_MEB_MEBWB),
        .meb_cp0_reg_w_add(cp0_reg_w_add_out_MEB_MEBWB),
        .meb_cp0_reg_en(cp0_reg_en_out_MEB_MEBWB),
        .cp0_reg_read_add_out(cp0_reg_read_add_out_EX_cp0),
        .cp0_reg_data_out(cp0_reg_data_out_EX_EXMEB),
        .cp0_reg_w_add_out(cp0_reg_w_add_out_EX_EXMEB),
        .cp0_reg_en_out(cp0_reg_en_out_EX_EXMEB),

        //异常处理
        .excepttype_in(ex_excepttype_out_IDEX_EX),
        .current_inst_add_in(ex_current_inst_add_out_IDEX_EX),
        .excepttype_out(excepttype_out_EX_EXMEB),
        .in_delayslot_out(in_delayslot_EX_EXMEB),
        .current_inst_add_out(current_inst_add_out_EX_EXMEB)
    );

    //例化EXE_MEB模块

    exe_meb ex_meb0(
        .clk(clk),
        .rst(rst),

        //接受EXE的信�????????
        .ex_w_data(ex_w_data_out),
        .ex_w_add(ex_w_add_out),
        .ex_w_reg(ex_w_reg_out),
        .ex_hilo(hilo_out_exe),
        .ex_hi(hi_out_exe),
        .ex_lo(lo_out_exe),

        //输出到MEB模块的信�????????
        .meb_w_data(meb_w_data_in),
        .meb_w_add(meb_w_add_in),
        .meb_w_reg(meb_w_reg_in),
        .meb_hi(meb_hi_out),
        .meb_lo(meb_lo_out),
        .meb_hilo(meb_hilo_out),

        .stall(stall_out),

        //加载存储
        .ex_alu_op(alu_op_EX_EXMEB),
        .ex_meb_add(meb_add_out_EX_EXMEB),
        .ex_reg2(reg2_out_EX_EXMEB),
        .meb_alu_op(meb_alu_op_EXMEB_MEB),
        .meb_meb_add(meb_meb_add_EXMEB_MEB),
        .meb_reg2(meb_reg2_EXMEB_MEB),


        //cp0相关
        .ex_cp0_reg_data(cp0_reg_data_out_EX_EXMEB),
        .ex_cp0_reg_w_add(cp0_reg_w_add_out_EX_EXMEB),
        .ex_cp0_reg_en(cp0_reg_en_out_EX_EXMEB),
        .meb_cp0_reg_data(meb_cp0_reg_data_EXMEB_MEB),
        .meb_cp0_reg_w_add(meb_cp0_reg_w_add_EXMEB_MEB),
        .meb_cp0_reg_en(meb_cp0_reg_en_EXMEB_MEB),

        .flush(flush_CTRL),
        .ex_excepttype(excepttype_out_EX_EXMEB),
        .ex_current_inst_add(current_inst_add_out_EX_EXMEB),
        .ex_in_delayslot(in_delayslot_EX_EXMEB),
        .meb_excepttype(meb_excepttype_out_EXMEB_MEB),
        .meb_current_inst_add(meb_current_inst_add_out_EXMEB_MEB),
        .meb_in_delayslot(meb_in_delayslot_EXMEB_MEB)

    );

    //例化MEB模块

    meb meb0(
        .rst(rst),

        //接收EXE_MEB模块的信�????????
        .w_data_in(meb_w_data_in),
        .w_add_in(meb_w_add_in),
        .w_reg_in(meb_w_reg_in),
        .hi_in(meb_hi_out),
        .lo_in(meb_lo_out),
        .hilo_in(meb_hilo_out),

        //输出到MEB/WB模块的信�????????
        .w_data_out(meb_w_data_out),
        .w_add_out(meb_w_add_out),
        .w_reg_out(meb_w_reg_out),
        .hi_out(hi_out_meb),
        .lo_out(lo_out_meb),
        .hilo_out(hilo_out_meb),


        //加载存储
        .alu_op_in(meb_alu_op_EXMEB_MEB),
        .meb_add_in(meb_meb_add_EXMEB_MEB),
        .reg2_in(meb_reg2_EXMEB_MEB),
        .meb_data_in(ram_data_in),
        .meb_add_out(ram_add_out),
        .meb_en_out(ram_en_out),
        .meb_sel_out(ram_sel_out),
        .meb_data_out(ram_data_out),
        .meb_ce_out(ram_ce_out),


        //cp0相关
        .cp0_reg_data_in(meb_cp0_reg_data_EXMEB_MEB),
        .cp0_reg_w_add_in(meb_cp0_reg_w_add_EXMEB_MEB),
        .cp0_reg_en_in(meb_cp0_reg_en_EXMEB_MEB),
        .cp0_reg_data_out(cp0_reg_data_out_MEB_MEBWB),
        .cp0_reg_w_add_out(cp0_reg_w_add_out_MEB_MEBWB),
        .cp0_reg_en_out(cp0_reg_en_out_MEB_MEBWB),

        //异常处理
        .excepttype_in(meb_excepttype_out_EXMEB_MEB),
        .current_inst_add_in(meb_current_inst_add_out_EXMEB_MEB),
        .in_delayslot_in(meb_in_delayslot_EXMEB_MEB),
        .cp0_cause_in(cp0_cause_in_cp0_MEB),
        .cp0_status_in(cp0_status_in_cp0_MEB),
        .cp0_epc_in(cp0_epc_in_cp0_MEB),
        .wb_cp0_reg_en(wb_cp0_reg_en_MEBWB_cp0),
        .wb_cp0_reg_w_add(wb_cp0_reg_w_add_MEBWB_cp0),
        .wb_cp0_reg_data(wb_cp0_reg_data_MEBWB_cp0),
        .cp0_epc_out(cp0_epc_out_MEB_CTRL),
        .excepttype_out(excepttype_out_MEB_cp0),
        .current_inst_add_out(current_inst_add_out_MEB_cp0),
        .in_delayslot_out(in_delayslot_out_MEB_cp0)
    );

    //实例化MEB_WB模块

    meb_wb meb_wb0(
        .clk(clk),
        .rst(rst),

        //接受访存阶段MEB的信�????????
        .meb_w_data(meb_w_data_out),
        .meb_w_add(meb_w_add_out),
        .meb_w_reg(meb_w_reg_out),
        .meb_hi(hi_out_meb),
        .meb_lo(lo_out_meb),
        .meb_hilo(hilo_out_meb),

        //输�?�回写阶段的信息
        .wb_w_data(wb_w_data_in),
        .wb_w_add(wb_w_add_in),
        .wb_w_reg(wb_w_reg_in),
        .wb_hi(wb_hi_out),
        .wb_lo(wb_lo_out),
        .wb_hilo(wb_hilo_out),

        .stall(stall_out),
        .flush(flush_CTRL),

        //cp0相关
        .meb_cp0_reg_data(cp0_reg_data_out_MEB_MEBWB),
        .meb_cp0_reg_w_add(cp0_reg_w_add_out_MEB_MEBWB),
        .meb_cp0_reg_en(cp0_reg_en_out_MEB_MEBWB),
        .wb_cp0_reg_data(wb_cp0_reg_data_MEBWB_cp0),
        .wb_cp0_reg_w_add(wb_cp0_reg_w_add_MEBWB_cp0),
        .wb_cp0_reg_en(wb_cp0_reg_en_MEBWB_cp0)
    );

    hilo hilo0(
        .clk(clk),
        .rst(rst),
        .hilo_en(wb_hilo_out),
        .hi_in(wb_hi_out),
        .lo_in(wb_lo_out),

        .hi_out(hi_out_hilo),
        .lo_out(lo_out_hilo)
    );

    ctrl ctrl0(
        .rst(rst),
        .stallreq_from_it(stallreq_from_it_out),
        .stallreq_from_ex(stallreq_from_ex_out),
        .stall(stall_out),
        .cp0_epc_i(cp0_epc_out_MEB_CTRL),
        .excepttype_i(excepttype_out_MEB_cp0),
        .new_pc(new_pc_CTRL),
        .flush(flush_CTRL)
    );
    
    cp0 cpf(

        .clk(clk),
        .rst(rst),
        .int_i(int_i),
        .timer_int_o(timer_int_o),
        .raddr_i(cp0_reg_read_add_out_EX_cp0),
        .data_i(wb_cp0_reg_data_MEBWB_cp0),
        .waddr_i(wb_cp0_reg_w_add_MEBWB_cp0),
        .we_i(wb_cp0_reg_en_MEBWB_cp0),
        
        .data_o(cp0_data_out),
        .excepttype_i(excepttype_out_MEB_cp0),
        .current_inst_addr_i(current_inst_add_out_MEB_cp0),
        .is_in_delayslot_i(in_delayslot_out_MEB_cp0),
        .cause_o(cp0_cause_in_cp0_MEB),
        .status_o(cp0_status_in_cp0_MEB),
        .epc_o(cp0_epc_in_cp0_MEB)
    );




endmodule

