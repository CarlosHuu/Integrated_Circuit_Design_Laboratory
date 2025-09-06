//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/



// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;


//###########################################
//
// Wrtie down your design below
//
//###########################################

//####################################################
//               reg & wire
//####################################################
/////////////////////////////// FSM
parameter   INITAIL_1 = 4'd0,
            INITAIL_2 = 4'd1,
            IF = 4'd2,
			IF_WAIT = 4'd3,
			ID = 4'd4,
			EXE = 4'd5,
			MEM = 4'd6,
			WB = 4'd7,
			WB_DRAM = 4'd8,
			IF_DRAM = 4'd9,
			DATA_WRITE = 4'd10,
			DATA_D2S = 4'd11,
			WAIT_D2S = 4'd12;

reg [3:0] current_state, next_state;


/////////////////////////////// SRAM REG
reg [7:0] SRAM_addr_inst;
reg web_inst;
reg [15:0] DO_inst, DO_data, DI_inst, DI_data, DO_inst_tmp, DO_data_tmp;
reg [6:0] SRAM_addr_data,SRAM_addr_data_reg;
reg web_data;
/////////////////////////////// AXI_inst
reg read_inst;
reg [ADDR_WIDTH-1:0] addr_inst;
reg [15:0] data_inst;
reg read_inst_done;
reg read_inst_done_reg;
reg [7:0] counter_read_inst;
/////////////////////////////// AXI_data
reg read;
reg write;
reg [ADDR_WIDTH-1:0] addr;
reg [15:0] data_read;
reg [15:0] data_write;
reg read_done;
reg write_done;
reg [8:0] counter_data;
/////////////////////////////// IF_STAGE
reg signed [10:0] pc_cnt;
/////////////////////////////// IF_DRAM
wire over_bound_inst, under_bound_inst;
reg [3:0] min_addr_inst, max_addr_inst;
reg SRAM_1OR2;
// reg [1:0] min_addr_data, max_addr_data;
/////////////////////////////// ID_STAGE
wire [2:0] op_code;
reg [2:0] op_code_reg;
wire [3:0] rs, rt, rd;
wire func;
reg signed [15:0] rs_data, rt_data, rd_data;
wire signed [4:0] immediate;
reg [15:0] cur_inst;
reg write2_flag,write2_flag_reg, sram_wt_flag;
reg [31:0] total_inst;
/////////////////////////////// EXE_STAGE
reg [1:0] mul_cnt;
wire signed [15:0] 	add_out;
wire signed [15:0] 	sub_out;
wire signed [15:0] 	mult_out;
wire 				comp_out;
wire 				equal_out;
wire signed [15:0] 	cal_data_addr;
wire signed [15:0] 	cal_jump_addr;
reg signed [15:0] rd_data_comb;
wire signed [31:0] multiplier_out;
/////////////////////////////// MEM_STAGE
reg [1:0] mem_cnt;
reg store_flag;
/////////////////////////////// WB_STAGE
reg [3:0] ten_cnt;
/////////////////////////////// DATA MISS
reg [3:0] old_data_addr;
reg data_miss_flag;
reg flag_jump;

AXI4_int AXI4_int(
	// .arid_m_inf(arid_m_inf[2*ID_WIDTH-1:ID_WIDTH]), .araddr_m_inf(araddr_m_inf[2*ADDR_WIDTH-1:ADDR_WIDTH]), .arlen_m_inf(arlen_m_inf[13:7]), 
    // .arsize_m_inf(arsize_m_inf[5:3]), .arburst_m_inf(arburst_m_inf[3:2]), .arvalid_m_inf(arvalid_m_inf[1]), .arready_m_inf(arready_m_inf[1]),
    // .rid_m_inf(rid_m_inf[2*ID_WIDTH-1:ID_WIDTH]), .rdata_m_inf(rdata_m_inf[2*DATA_WIDTH-1:DATA_WIDTH]), .rresp_m_inf(rresp_m_inf[3:2]),
    // .rlast_m_inf(rlast_m_inf[1]), .rvalid_m_inf(rvalid_m_inf[1]), .rready_m_inf(rready_m_inf[1]) ,
	.arid_m_inf(arid_m_inf[2*ID_WIDTH-1:ID_WIDTH]),
       .araddr_m_inf(araddr_m_inf[2*ADDR_WIDTH-1:ADDR_WIDTH]),
        .arlen_m_inf(arlen_m_inf[13:7]),
       .arsize_m_inf(arsize_m_inf[5:3]),
      .arburst_m_inf(arburst_m_inf[3:2]),
      .arvalid_m_inf(arvalid_m_inf[1]),
      .arready_m_inf(arready_m_inf[1]), 
                 
          .rid_m_inf(rid_m_inf[2*ID_WIDTH-1:ID_WIDTH]),
        .rdata_m_inf(rdata_m_inf[2*DATA_WIDTH-1:DATA_WIDTH]),
        .rresp_m_inf(rresp_m_inf[3:2]),
        .rlast_m_inf(rlast_m_inf[1]),
       .rvalid_m_inf(rvalid_m_inf[1]),
       .rready_m_inf(rready_m_inf[1]) ,
	.clk(clk), .rst_n(rst_n), .read_inst(read_inst), .addr_inst(addr_inst),
	.data_inst(data_inst), .read_inst_done(read_inst_done), .counter_read_inst(counter_read_inst)
);
AXI4_data AXI4_data(
	.clk(clk), .rst_n(rst_n),
	.awid_m_inf(awid_m_inf), .awaddr_m_inf(awaddr_m_inf), .awsize_m_inf(awsize_m_inf), .awburst_m_inf(awburst_m_inf), .awlen_m_inf(awlen_m_inf), .awvalid_m_inf(awvalid_m_inf), 
	.awready_m_inf(awready_m_inf), .wdata_m_inf(wdata_m_inf), .wlast_m_inf(wlast_m_inf), .wvalid_m_inf(wvalid_m_inf), .wready_m_inf(wready_m_inf),
    .bid_m_inf(bid_m_inf), .bresp_m_inf(bresp_m_inf), .bvalid_m_inf(bvalid_m_inf), .bready_m_inf(bready_m_inf),
	   
    .arid_m_inf(arid_m_inf[ID_WIDTH-1:0]), .araddr_m_inf(araddr_m_inf[ADDR_WIDTH-1:0]), .arlen_m_inf(arlen_m_inf[6:0]),
	.arsize_m_inf(arsize_m_inf[2:0]), .arburst_m_inf(arburst_m_inf[1:0]), .arvalid_m_inf(arvalid_m_inf[0]), .arready_m_inf(arready_m_inf[0]), 
    
	.rid_m_inf(rid_m_inf[ID_WIDTH-1:0]), .rdata_m_inf(rdata_m_inf[DATA_WIDTH-1:0]), .rresp_m_inf(rresp_m_inf[1:0]),
 	.rlast_m_inf(rlast_m_inf[0]), .rvalid_m_inf(rvalid_m_inf[0]), .rready_m_inf(rready_m_inf[0]) ,
	.read(read), .write(write), .addr(addr), .data_read(data_read), .data_write(data_write), .read_done(read_done), .write_done(write_done), .counter_data(counter_data)
);
HU_256X16 inst_SRAM(.A0(SRAM_addr_inst[0]),.A1(SRAM_addr_inst[1]),.A2(SRAM_addr_inst[2]),.A3(SRAM_addr_inst[3]),.A4(SRAM_addr_inst[4]),.A5(SRAM_addr_inst[5]),.A6(SRAM_addr_inst[6]),.A7(SRAM_addr_inst[7]),
                      .DI0(DI_inst[0]),.DI1(DI_inst[1]),.DI2(DI_inst[2]),.DI3(DI_inst[3]),.DI4(DI_inst[4]),.DI5(DI_inst[5]),
                      .DI6(DI_inst[6]),.DI7(DI_inst[7]),.DI8(DI_inst[8]),.DI9(DI_inst[9]),.DI10(DI_inst[10]),
                      .DI11(DI_inst[11]),.DI12(DI_inst[12]),.DI13(DI_inst[13]),.DI14(DI_inst[14]),.DI15(DI_inst[15]),
                      .DO0(DO_inst_tmp[0]),.DO1(DO_inst_tmp[1]),.DO2(DO_inst_tmp[2]),.DO3(DO_inst_tmp[3]),.DO4(DO_inst_tmp[4]),.DO5(DO_inst_tmp[5]),
                      .DO6(DO_inst_tmp[6]),.DO7(DO_inst_tmp[7]),.DO8(DO_inst_tmp[8]),.DO9(DO_inst_tmp[9]),.DO10(DO_inst_tmp[10]),
                      .DO11(DO_inst_tmp[11]),.DO12(DO_inst_tmp[12]),.DO13(DO_inst_tmp[13]),.DO14(DO_inst_tmp[14]),.DO15(DO_inst_tmp[15]),
                      .CK(clk),.WEB(web_inst),.OE(1'b1),.CS(1'b1));
HU_128X16 data_SRAM(.A0(SRAM_addr_data[0]),.A1(SRAM_addr_data[1]),.A2(SRAM_addr_data[2]),.A3(SRAM_addr_data[3]),.A4(SRAM_addr_data[4]),.A5(SRAM_addr_data[5]),.A6(SRAM_addr_data[6]),
                      .DI0(DI_data[0]),.DI1(DI_data[1]),.DI2(DI_data[2]),.DI3(DI_data[3]),.DI4(DI_data[4]),.DI5(DI_data[5]),
                      .DI6(DI_data[6]),.DI7(DI_data[7]),.DI8(DI_data[8]),.DI9(DI_data[9]),.DI10(DI_data[10]),
                      .DI11(DI_data[11]),.DI12(DI_data[12]),.DI13(DI_data[13]),.DI14(DI_data[14]),.DI15(DI_data[15]),
                      .DO0(DO_data_tmp[0]),.DO1(DO_data_tmp[1]),.DO2(DO_data_tmp[2]),.DO3(DO_data_tmp[3]),.DO4(DO_data_tmp[4]),.DO5(DO_data_tmp[5]),
                      .DO6(DO_data_tmp[6]),.DO7(DO_data_tmp[7]),.DO8(DO_data_tmp[8]),.DO9(DO_data_tmp[9]),.DO10(DO_data_tmp[10]),
                      .DO11(DO_data_tmp[11]),.DO12(DO_data_tmp[12]),.DO13(DO_data_tmp[13]),.DO14(DO_data_tmp[14]),.DO15(DO_data_tmp[15]),
                      .CK(clk),.WEB(web_data),.OE(1'b1),.CS(1'b1));

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin  
        DO_data <= 0;
        DO_inst <= 0;
    end
    else begin
        DO_data <= DO_data_tmp;
        DO_inst <= DO_inst_tmp;
    end
end

//=======================================================
//                   FSM
//=======================================================
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        current_state <= INITAIL_1;
    end
    else begin
        current_state <= next_state;
    end
end
always @(*) begin
    case (current_state)
        INITAIL_1: begin
            if (read_inst_done) begin
                next_state = INITAIL_2;
            end
            else begin
                next_state = INITAIL_1;
            end
        end
        INITAIL_2: begin
            if (read_inst_done) begin
                next_state = IF;
            end
            else begin
                next_state = INITAIL_2;
            end
        end
		IF: begin
			if (ten_cnt == 9 && !flag_jump) begin
				next_state = WB;
			end
			else if (over_bound_inst || under_bound_inst) begin
				next_state = IF_DRAM; 
			end
			else begin
				next_state = IF_WAIT; // You can change this to your next state
			end
		end
		IF_DRAM: begin
			if (read_inst_done) begin
				next_state = IF;
			end
			else begin
				next_state = IF_DRAM;
			end
		end
		IF_WAIT: begin
			next_state = ID; 
		end
		ID: begin
			if (write2_flag) begin
				next_state = MEM;
			end
			else if (op_code == 3'b101) begin //JUMP
				next_state = IF;
			end
			else begin
				next_state = EXE;
			end
		end
		EXE : begin
			if  (op_code[1] == 1 && data_miss_flag) begin
				next_state = DATA_WRITE;
			end
			else if (op_code[1]) begin // load && store
				next_state = MEM;
			end
			else if (!(op_code == 3'b001 && func))begin
				next_state = IF;
			end
			else if (mul_cnt == 1) begin
				next_state = IF;
			end
			else begin
				next_state = EXE;
			end
		end
		MEM : begin 
			if ((ten_cnt == 10 || write2_flag) && mem_cnt == 1 ) begin
				next_state = WB;
			end
			else if (mem_cnt == 2) begin
				next_state = IF;
			end
			else begin
				next_state = MEM;
			end
		end
		WB : begin
			if (store_flag && (ten_cnt == 10 || write2_flag)) begin
				next_state = WB_DRAM;
			end
			else begin
				next_state = IF;
			end
		end
		WB_DRAM : begin
			if (bvalid_m_inf) begin
				next_state = IF;
			end
			else begin
				next_state = WB_DRAM;
			end
		end 
		DATA_WRITE : begin
			if (bvalid_m_inf) begin
				next_state = DATA_D2S;
			end
			else begin
				next_state = DATA_WRITE;
			end
		end
		DATA_D2S : begin
			if (read_done) begin
                // next_state = WAIT_D2S;

				next_state = MEM;
            end
            else begin
                next_state = DATA_D2S;
            end
		end
		// WAIT_D2S: begin
		// 	next_state = MEM;
		// end

        default: next_state = INITAIL_1;
    endcase 
end
//=======================================================
//                   AXI contraol
//=======================================================
always @ (*) begin
    addr_inst = 0;
	addr = 0;
    if (current_state == INITAIL_1) begin
        addr_inst = 32'b0000_0000_0000_0000_0001_0000_0000_0000;
		addr = 32'b0000_0000_0000_0000_0001_0000_0000_0000;
    end
    else if (current_state == INITAIL_2) begin
        addr_inst = 32'b0000_0000_0000_0000_0001_0001_0000_0000;
		addr = 32'b0000_0000_0000_0000_0001_0000_0000_0000;
    end
	else if (current_state == WB_DRAM) begin
		// addr = 32'b0000_0000_0000_0000_0001_0000_0000_0000;
		addr = {19'd0, 1'd1, old_data_addr, 8'd0};
	end
	else if (current_state == IF_DRAM) begin
		addr_inst = {19'd0, 1'd1, pc_cnt[10:7], 8'd0};
	end
	else if (current_state == DATA_WRITE) begin
		addr = {19'd0, 1'd1, old_data_addr, 8'd0};
	end
	else if (current_state == DATA_D2S) begin
		addr = {19'd0, 1'd1, old_data_addr, 8'd0};
	end


end
always @(*) begin
	read_inst = 0;
	read = 0;
	if (current_state == INITAIL_1) begin
		read_inst = 1;
		read = 1;
	end
	else if (current_state == INITAIL_2) begin
		read_inst = 1;
		read = 1;
	end
	else if (current_state == IF_DRAM) begin
		read_inst = 1;
	end
	else if (current_state == DATA_D2S) begin
		read = 1;
	end
end

always @(*) begin
	write = 0;
	data_write = 0;
	if (current_state == WB_DRAM) begin
		write = 1;
		data_write = DO_data_tmp;
	end
	else if (current_state == DATA_WRITE) begin
		write = 1;
		data_write = DO_data_tmp;
	end
end

//=======================================================
//                   SRAM contraol
//=======================================================
//DATA SRAM
always @ (*)begin
	SRAM_addr_data = cal_data_addr[11:1];
	web_data = 1;
	DI_data = 0;
	if (current_state == INITAIL_1) begin
		SRAM_addr_data = counter_data;
		web_data = 0;
		DI_data = data_read;
	end
	else if (current_state == INITAIL_2) begin
		SRAM_addr_data = counter_data;
		web_data = 0;
		DI_data = data_read;
	end
	else if (current_state == EXE) begin
		SRAM_addr_data = cal_data_addr[11:1];
	end
	else if (current_state == MEM && op_code == 3'b011) begin
		SRAM_addr_data = cal_data_addr[11:1];
		web_data = 0;
		DI_data = rt_data;
	end
	else if (current_state == WB_DRAM) begin
		SRAM_addr_data = counter_data;
		web_data = 1;
		DI_data = 0;
	end
	else if (current_state == DATA_WRITE) begin
		SRAM_addr_data = counter_data;
		web_data = 1;
		DI_data = 0;
	end
	else if (current_state == DATA_D2S) begin
		SRAM_addr_data = counter_data;
		web_data = 0;
		DI_data = data_read;
	end
end
//INSTRUCTION SRAM
always @ (*)begin
	SRAM_addr_inst = pc_cnt[7:0];
    web_inst = 1;
    DI_inst = 0;
	if (current_state == INITAIL_1) begin
		SRAM_addr_inst = counter_read_inst;
		web_inst = 0;
		DI_inst = data_inst;
	end
	else if (current_state == INITAIL_2) begin
		SRAM_addr_inst = counter_read_inst + 128;
		web_inst = 0;
		DI_inst = data_inst;
	end
	else if (current_state == IF) begin
		SRAM_addr_inst = pc_cnt[7:0];
		web_inst = 1;
		DI_inst = DO_inst;
	end
	else if (current_state == IF_DRAM) begin
		SRAM_addr_inst = (SRAM_1OR2) ? counter_read_inst + 128 : counter_read_inst;
		web_inst = 0;
		DI_inst = data_inst;
	end
	/////
	

	/////
end
//=======================================================
//               instruction fetch
//=======================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        pc_cnt <= 0;
	else if ( next_state == IF && current_state == EXE && op_code == 3'b100) begin
		pc_cnt <= (rs_data == rt_data) ? pc_cnt+1+immediate : pc_cnt + 1;
	end
	else if (next_state == IF && current_state != INITAIL_2 && ten_cnt!=10 && current_state != IF_DRAM && (write2_flag_reg || current_state != WB_DRAM)) begin
		if(DO_inst[15:13] == 3'b101) // jump
            pc_cnt <= DO_inst[11:1];
        else
			pc_cnt <= pc_cnt + 1;
	end
    else
        pc_cnt <=  pc_cnt;
end
//=======================================================
//               instruction fetch DRAM
//=======================================================
// // over_bound_inst & under_bound_inst
// // assign over_bound_inst = (pc_cnt[7] == min_addr_inst[0] && pc_cnt[8] != min_addr_inst[1])? 1: 0;
// // assign under_bound_inst = (pc_cnt[7] == max_addr_inst[0] && pc_cnt[8] != max_addr_inst[1])? 1: 0;
assign over_bound_inst = (pc_cnt[10:7] >max_addr_inst)? 1: 0;
assign under_bound_inst = (pc_cnt[10:7] <min_addr_inst)? 1: 0;
// max_addr_inst
reg upp_dff, down_dff;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        max_addr_inst <= 1;  
    else if(/*current_state == IF && next_state != WB*/current_state == IF_DRAM && read_inst_done ) begin
        if(over_bound_inst)
            max_addr_inst <= max_addr_inst + 1;
        else if(under_bound_inst)
            max_addr_inst <= max_addr_inst - 1;
    end
end
// min_addr_inst
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        min_addr_inst <= 0;   
    else if(/*current_state == IF && next_state != WB*/ current_state == IF_DRAM && read_inst_done) begin
        if(over_bound_inst) 
            min_addr_inst <= min_addr_inst + 1;
        else if(under_bound_inst)
            min_addr_inst <= min_addr_inst - 1;
    end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		SRAM_1OR2 <= 1;
	end
	else if (current_state == IF && next_state != WB && over_bound_inst) begin
		SRAM_1OR2 <= (sram_wt_flag) ? ~SRAM_1OR2 : SRAM_1OR2;
	end
	else if (current_state == IF && next_state != WB && under_bound_inst) begin
		SRAM_1OR2 <= (sram_wt_flag) ? SRAM_1OR2 : ~SRAM_1OR2;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		sram_wt_flag <= 1;
	end
	else if (current_state == IF && next_state != WB && over_bound_inst) begin
		sram_wt_flag <= 1;
	end
	else if (current_state == IF && next_state != WB && under_bound_inst) begin
		sram_wt_flag <= 0;
	end
end
//=======================================================
//               instruction decode
//=======================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cur_inst <= 0;
    else if(current_state == ID)
        cur_inst <= DO_inst;
end

assign rs = (current_state == ID) ? DO_inst[12:9] : cur_inst[12:9];
assign rt =(current_state == ID) ? DO_inst[8:5] : cur_inst[8:5];
assign op_code = (current_state == ID) ? DO_inst[15:13] : cur_inst[15:13]; 

assign rd = (current_state == ID) ? DO_inst[4:1] : cur_inst[4:1];
assign immediate = (current_state == ID) ? DO_inst[4:0] : cur_inst[4:0];
assign func = (current_state == ID) ? DO_inst[0] : cur_inst[0];

// rs_data
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        rs_data <= 0;
    else if( current_state == ID ) begin
        case(rs)
            0:      rs_data <= core_r0  ;
            1:      rs_data <= core_r1  ;
            2:      rs_data <= core_r2  ;
            3:      rs_data <= core_r3  ;
            4:      rs_data <= core_r4  ;
            5:      rs_data <= core_r5  ;
            6:      rs_data <= core_r6  ;
            7:      rs_data <= core_r7  ;
            8:      rs_data <= core_r8  ;
            9:      rs_data <= core_r9  ;
            10:     rs_data <= core_r10 ; 
            11:     rs_data <= core_r11 ; 
            12:     rs_data <= core_r12 ; 
            13:     rs_data <= core_r13 ; 
            14:     rs_data <= core_r14 ; 
            15:     rs_data <= core_r15 ; 
        endcase
    end
end

// rt_data
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        rt_data <= 0;
    else if( current_state == ID ) begin
        case(rt)
            0:      rt_data <= core_r0  ;
            1:      rt_data <= core_r1  ;
            2:      rt_data <= core_r2  ;
            3:      rt_data <= core_r3  ;
            4:      rt_data <= core_r4  ;
            5:      rt_data <= core_r5  ;
            6:      rt_data <= core_r6  ;
            7:      rt_data <= core_r7  ;
            8:      rt_data <= core_r8  ;
            9:      rt_data <= core_r9  ;
            10:     rt_data <= core_r10 ; 
            11:     rt_data <= core_r11 ; 
            12:     rt_data <= core_r12 ; 
            13:     rt_data <= core_r13 ; 
            14:     rt_data <= core_r14 ; 
            15:     rt_data <= core_r15 ; 
        endcase
    end
end
//=======================================================
//               EXECUTE 
//=======================================================
assign add_out = rs_data + rt_data;
assign sub_out = rs_data - rt_data;
assign mult_out = rs_data * rt_data;
assign comp_out = (rs_data < rt_data);
assign equal_out = (rs_data == rt_data);
assign cal_data_addr = (rs_data+immediate)*2 + $signed('h1000);
assign cal_jump_addr = {3'b0, DO_inst[12:0]};

DW02_mult_2_stage_inst mul2(.inst_A(rs_data), .inst_B(rt_data), .inst_TC(1'b1), .inst_CLK(clk), .PRODUCT_inst(multiplier_out));
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rd_data <= 0;
	end else begin
		rd_data <= multiplier_out[15:0];
	end
end
always@(*) begin
	case({op_code[0],func})
	'b00: rd_data_comb = add_out;
	'b01: rd_data_comb = sub_out;
	'b10: rd_data_comb = comp_out;
	default: rd_data_comb = comp_out;
	endcase
end
//=======================================================
//               Data miss
//=======================================================
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		old_data_addr <= 0;
	end
	else if (current_state==10 && wlast_m_inf)begin
		old_data_addr <= cal_data_addr[11:8];
	end
end
always @(*)begin
	data_miss_flag = 0;
	if(current_state==EXE && (old_data_addr != cal_data_addr[11:8]))begin
			data_miss_flag = 1;
	end
end
//=======================================================
//               FLAG
//=======================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        mul_cnt <= 0;
    else if(current_state == IF)
        mul_cnt <= 0;
    else if(current_state == EXE)
        mul_cnt <= mul_cnt + 1;
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        mem_cnt <= 0;
    else if(current_state == IF)
        mem_cnt <= 0;
    else if(current_state == MEM)
        mem_cnt <= mem_cnt + 1;
end
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		store_flag <= 0;
	end
	else if (current_state == ID  && op_code == 3'b011) begin //store
		store_flag <= 1;
	end
	else if (current_state == WB) begin
		store_flag <= 0;
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		ten_cnt <= 0;
	end
	else if (!IO_stall) begin
		ten_cnt <= ten_cnt + 1;
	end
	else if ((current_state == WB) && total_inst[0] == 0) begin
		ten_cnt <= 0;
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		write2_flag <= 0;
	end
	else if (ten_cnt == 0 && op_code == 3'b011 && current_state != WB_DRAM && current_state != IF && current_state != IF_WAIT && total_inst[0] == 0) begin //sub add set
		write2_flag <= 1;
	end
	else begin
		write2_flag <= 0;
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		write2_flag_reg <= 0;
	end
	else if (current_state == EXE)begin
		write2_flag_reg <= write2_flag;
	end
	else if (current_state == IF) begin
		write2_flag_reg <= 0;
	end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        total_inst <= 0;
    else if(!IO_stall)
        total_inst <= total_inst + 1;
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        flag_jump <= 0;
    else if(current_state == IF_DRAM)
        flag_jump  <= 1;
		else if (current_state == IF)
		flag_jump  <= 0;
end


//=======================================================
//                   register
//=======================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r0 <= 0;
	end
	else if (current_state == MEM && rt == 'd0 && op_code == 3'b010) begin //load
		core_r0 <= DO_data;
	end
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd0) begin //mul
		core_r0 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd0 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r0 <= rd_data_comb;
	end
    else begin
		core_r0 <= core_r0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r1 <= 0;
	end 
	else if (current_state == MEM && rt == 'd1 && op_code == 3'b010) begin
		core_r1 <= DO_data;
	end
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd1) begin
		core_r1 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd1 && op_code[2:1] == 'b00 ) begin 
		core_r1 <= rd_data_comb;
	end
    else begin
		core_r1 <= core_r1;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r2 <= 0;
	end 
	else if (current_state == MEM && rt == 'd2 && op_code == 3'b010) begin
		core_r2 <= DO_data;
	end
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd2) begin
		core_r2 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd2 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r2 <= rd_data_comb;
	end
    else begin
		core_r2 <= core_r2;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r3 <= 0;
	end 
	else if (current_state == MEM && rt == 'd3 && op_code == 3'b010) begin
		core_r3 <= DO_data;
	end
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd3) begin
		core_r3 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd3 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r3 <= rd_data_comb;
	end
    else begin
		core_r3 <= core_r3;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r4 <= 0;
	end 
	else if (current_state == MEM && rt == 'd4 && op_code == 3'b010) begin
		core_r4 <= DO_data;
	end
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd4) begin
		core_r4 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd4 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r4 <= rd_data_comb;
	end
    else begin
		core_r4 <= core_r4;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r5 <= 0;
	end 
	else if (current_state == MEM && rt == 'd5 && op_code == 3'b010) begin
		core_r5 <= DO_data;
	end
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd5) begin
		core_r5 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd5 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r5 <= rd_data_comb;
	end
    else begin
		core_r5 <= core_r5;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r6 <= 0;
	end
	else if (current_state == MEM && rt == 'd6 && op_code == 3'b010) begin
		core_r6 <= DO_data;
	end 
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd6) begin
		core_r6 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd6 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r6 <= rd_data_comb;
	end
    else begin
		core_r6 <= core_r6;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r7 <= 0;
	end
	else if (current_state == MEM && rt == 'd7 && op_code == 3'b010) begin
		core_r7 <= DO_data;
	end 
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd7) begin
		core_r7 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd7 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r7 <= rd_data_comb;
	end
    else begin
		core_r7 <= core_r7;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r8 <= 0;
	end 
	else if (current_state == MEM && rt == 'd8 && op_code == 3'b010) begin
		core_r8 <= DO_data;
	end
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd8) begin
		core_r8 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd8 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r8 <= rd_data_comb;
	end
    else begin
		core_r8 <= core_r8;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r9 <= 0;
	end 
	else if (current_state == MEM && rt == 'd9 && op_code == 3'b010) begin
		core_r9 <= DO_data;
	end
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd9) begin
		core_r9 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd9 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r9 <= rd_data_comb;
	end
    else begin
		core_r9 <= core_r9;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r10 <= 0;
	end 
	else if (current_state == MEM && rt == 'd10 && op_code == 3'b010) begin
		core_r10 <= DO_data;
	end 
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd10) begin
		core_r10 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd10 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r10 <= rd_data_comb;
	end
    else begin
		core_r10 <= core_r10;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r11 <= 0;
	end 
	else if (current_state == MEM && rt == 'd11 && op_code == 3'b010) begin
		core_r11 <= DO_data;
	end 
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd11) begin
		core_r11 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd11 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r11 <= rd_data_comb;
	end
    else begin
		core_r11 <= core_r11;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r12 <= 0;
	end 
	else if (current_state == MEM && rt == 'd12 && op_code == 3'b010) begin
		core_r12 <= DO_data;
	end
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd12) begin
		core_r12 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd12 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r12 <= rd_data_comb;
	end
    else begin
		core_r12 <= core_r12;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r13 <= 0;
	end 
	else if (current_state == MEM && rt == 'd13 && op_code == 3'b010) begin
		core_r13 <= DO_data;
	end
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd13) begin
		core_r13 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd13 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r13 <= rd_data_comb;
	end
    else begin
		core_r13 <= core_r13;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r14 <= 0;
	end 
	else if (current_state == MEM && rt == 'd14 && op_code == 3'b010) begin
		core_r14 <= DO_data;
	end
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd14) begin
		core_r14 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd14 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r14 <= rd_data_comb;
	end
    else begin
		core_r14 <= core_r14;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r15 <= 0;
	end
	else if (current_state == MEM && rt == 'd15 && op_code == 3'b010) begin
		core_r15 <= DO_data;
	end
	else if(current_state == EXE && mul_cnt == 1 && rd == 'd15) begin
		core_r15 <= multiplier_out[15:0];
	end
	else if (current_state == EXE && rd == 'd15 && op_code[2:1] == 'b00 ) begin //sub add set
		core_r15 <= rd_data_comb;
	end
    else begin
		core_r15 <= core_r15;
	end
end


//=======================================================
//                   OUTPUT
//=======================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        IO_stall <= 1;
    end
	else if (next_state == IF && current_state != INITAIL_2 && ten_cnt!=10 && current_state != IF_DRAM && (write2_flag_reg || current_state != WB_DRAM) ) begin
		IO_stall <= 0;
	end
    else begin
        IO_stall <= 1;
    end
end


endmodule

//=======================================================
//                AXI for inst
//=======================================================
module AXI4_int #(parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=1)(
	arid_m_inf, araddr_m_inf, arlen_m_inf, arsize_m_inf, arburst_m_inf, arvalid_m_inf, arready_m_inf,
	rid_m_inf, rdata_m_inf, rresp_m_inf, rlast_m_inf, rvalid_m_inf, rready_m_inf,
	clk, rst_n, read_inst, addr_inst, data_inst, read_inst_done, counter_read_inst
);

// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  reg [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  reg [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  reg  [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

input clk;
input rst_n;
input read_inst;
input [ADDR_WIDTH-1:0] addr_inst;//
output reg [15:0] data_inst;
output reg read_inst_done;
output reg [7:0] counter_read_inst;

// ======================================================
// Reg & Wire Declaration
// ======================================================
parameter	IDLE 	= 2'd0,
		    READ_ADDRESS = 2'd1,
			READ_DATA = 2'd2,
			READ_FINISH = 2'd3;


reg [1:0] current_state, next_state;
reg [7:0] counter_comb;
reg [DRAM_NUMBER-1:0] arready_m_inf_reg, rvalid_m_inf_reg,rlast_m_inf_reg;
reg [ADDR_WIDTH-1:0] addr_inst_reg;
// reg [DRAM_NUMBER-1:0] arvalid_m_inf_reg;
// reg [ADDR_WIDTH-1:0] araddr_m_inf_comb;
//=======================================================
//                   initial
//=======================================================

//read
assign arid_m_inf = 0;
assign arburst_m_inf = 2'b01;
assign arsize_m_inf = 3'b001;
assign arlen_m_inf = 127;
//write

//=======================================================
//                   FSM
//=======================================================
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

always @(*) begin
    case (current_state)
        IDLE: begin
            if (read_inst) begin
                next_state = READ_ADDRESS;
			end
            else begin
                next_state = IDLE;
			end
        end
		READ_ADDRESS: begin
			if (arready_m_inf) begin
				next_state = READ_DATA;
			end
			else begin
				next_state = READ_ADDRESS;
			end
		end
		READ_DATA: begin
			if (rlast_m_inf) begin
				next_state = READ_FINISH;
			end
			else begin
				next_state = READ_DATA;
			end
		end
		READ_FINISH: begin
			next_state = IDLE;
		end

        default: next_state = IDLE;
    endcase 
end

// data_count
always @ (*)begin
	counter_comb = counter_read_inst;
	if (current_state == READ_ADDRESS) begin
		counter_comb = 0;
	end 
	else if (current_state == READ_DATA) begin
		if (rvalid_m_inf_reg) begin
			counter_comb = counter_read_inst + 1;
		end
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_read_inst<= 0;
	end else begin
		counter_read_inst <= counter_comb;
	end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        arready_m_inf_reg <= 0;
        rvalid_m_inf_reg <= 0;
		rlast_m_inf_reg <= 0;
    end else begin
        arready_m_inf_reg <= arready_m_inf;
        rvalid_m_inf_reg <= rvalid_m_inf;
		rlast_m_inf_reg <= rlast_m_inf;
    end
end
//=======================================================
//                   read
//=======================================================
//araddr_m_inf
always @ (posedge clk or negedge rst_n)begin
	if (!rst_n) begin
		addr_inst_reg <= 0;
	end
	else if(read_inst)begin
		addr_inst_reg <= addr_inst;
	end
end
always @ (*)begin
	araddr_m_inf = addr_inst_reg;
end
// arvalid_m_inf
always @ (*)begin
	arvalid_m_inf = 0;
	if (current_state == READ_ADDRESS) begin
		arvalid_m_inf = 1;
	end
end
// rready_m_inf 
always @ (*)begin
	rready_m_inf = 0;
	if (current_state == READ_DATA) begin
		rready_m_inf = 1;
	end
end

always @ (posedge clk or negedge rst_n)begin
    if (!rst_n) begin
        data_inst <= 0;
    end
    else if (current_state == READ_DATA )begin
		if (rvalid_m_inf) 
			data_inst <= rdata_m_inf;
		else
        	data_inst <= 0;
    end
	else begin
		data_inst <= 0;
	end
end
always @ (*)begin
	if (rlast_m_inf_reg) begin
		read_inst_done = 1;
	end
	else begin
		read_inst_done = 0;
	end
end

endmodule



//=======================================================
//                AXI for DATA
//=======================================================
module AXI4_data #(parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=1, WRIT_NUMBER=1)(
	arid_m_inf, araddr_m_inf, arlen_m_inf, arsize_m_inf, arburst_m_inf, arvalid_m_inf, arready_m_inf,
	rid_m_inf, rdata_m_inf, rresp_m_inf, rlast_m_inf, rvalid_m_inf, rready_m_inf,
	awid_m_inf, awaddr_m_inf, awsize_m_inf, awburst_m_inf, awlen_m_inf, awvalid_m_inf, awready_m_inf,
	wdata_m_inf, wlast_m_inf, wvalid_m_inf, wready_m_inf,
	bid_m_inf, bresp_m_inf, bvalid_m_inf, bready_m_inf,

	clk, rst_n, read, write, addr, data_read, data_write, read_done, write_done, counter_data
);

// -----------------------------
// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  reg [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  reg [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  reg [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  reg [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  reg [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  reg [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  reg [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  reg [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  reg  [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

input clk;
input rst_n;
input read;
input write;
input [ADDR_WIDTH-1:0] addr;
output reg [15:0] data_read;
input [15:0] data_write;
output reg read_done;
output reg write_done;
output reg [8:0] counter_data;
// ======================================================
// Reg & Wire Declaration
// ======================================================
parameter	IDLE 	= 3'd0,
		    READ_ADDRESS = 3'd1,
			READ_DATA = 3'd2,
			READ_FINISH = 3'd3,
			WRITE_ADDRESS = 3'd4,
			WRITE_DATA = 3'd5,
			WRITE_FINISH = 3'd6;


reg [2:0] current_state, next_state;
reg [7:0] counter_comb;
reg [DRAM_NUMBER-1:0] arready_m_inf_reg, rvalid_m_inf_reg,rlast_m_inf_reg;
reg [ADDR_WIDTH-1:0] addr_data_reg;
reg [15:0] data_write_reg;
//=======================================================
//                   initial
//=======================================================

//read
assign arid_m_inf = 0;
assign arburst_m_inf = 2'b01;
assign arsize_m_inf = 3'b001;
assign arlen_m_inf = 127;
//write
assign awid_m_inf = 0;
assign awburst_m_inf = 2'b01;
assign awsize_m_inf = 3'b001;
assign awlen_m_inf = 127;
//=======================================================
//                   FSM
//=======================================================
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

always @(*) begin
    case (current_state)
        IDLE: begin
            if (read) begin
                next_state = READ_ADDRESS;
			end
			else if (write) begin
				next_state = WRITE_ADDRESS;
			end
            else begin
                next_state = IDLE;
			end
        end
		READ_ADDRESS: begin
			if (arready_m_inf) begin
				next_state = READ_DATA;
			end
			else begin
				next_state = READ_ADDRESS;
			end
		end
		READ_DATA: begin
			if (rlast_m_inf) begin
				next_state = READ_FINISH;
			end
			else begin
				next_state = READ_DATA;
			end
		end
		READ_FINISH: begin
			next_state = IDLE;
		end
		WRITE_ADDRESS: begin
			if (awready_m_inf) begin
				next_state = WRITE_DATA;
			end
			else begin
				next_state = WRITE_ADDRESS;
			end
		end
		WRITE_DATA: begin
			if (wlast_m_inf) begin
				next_state = WRITE_FINISH;
			end
			else begin
				next_state = WRITE_DATA;
			end
		end
		WRITE_FINISH: begin
			if (bvalid_m_inf && bresp_m_inf == 0) begin
				next_state = IDLE;
			end
			else begin
				next_state = WRITE_FINISH;
			end
		end
        default: next_state = IDLE;
    endcase 
end

// data_count
always @ (*)begin
	counter_comb = counter_data;
	if (current_state == READ_ADDRESS) begin
		counter_comb = 0;
	end 
	else if (current_state == READ_DATA) begin
		if (rvalid_m_inf_reg) begin
			counter_comb = counter_data + 1;
		end
	end
	else if (current_state == WRITE_ADDRESS) begin
		if (!awready_m_inf) begin
			counter_comb = 0;
		end
	end
	else if (awready_m_inf) begin
			counter_comb = 1;
	end
	else if (current_state == WRITE_DATA) begin
		if (wready_m_inf) begin
			counter_comb = counter_data + 1;
		end
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_data <= 0;
	end else begin
		counter_data <= counter_comb;
	end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        arready_m_inf_reg <= 0;
        rvalid_m_inf_reg <= 0;
		rlast_m_inf_reg <= 0;
    end else begin
        arready_m_inf_reg <= arready_m_inf;
        rvalid_m_inf_reg <= rvalid_m_inf;
		rlast_m_inf_reg <= rlast_m_inf;
    end
end
//=======================================================
//                   read
//=======================================================
//araddr_m_inf
always @ (posedge clk or negedge rst_n)begin
	if (!rst_n) begin
		addr_data_reg <= 0;
	end
	else if(read)begin
		addr_data_reg <= addr;
	end
end
always @ (*)begin
	araddr_m_inf = addr_data_reg;
end
// arvalid_m_inf

always @ (*)begin
	arvalid_m_inf = 0;
	if (current_state == READ_ADDRESS) begin
		arvalid_m_inf = 1;
	end
end
// rready_m_inf 
always @ (*)begin
	rready_m_inf = 0;
	if (current_state == READ_DATA) begin
		rready_m_inf = 1;
	end
end

always @ (posedge clk or negedge rst_n)begin
    if (!rst_n) begin
        data_read <= 0;
    end
    else if (current_state == READ_DATA )begin
		if (rvalid_m_inf) 
			data_read <= rdata_m_inf;
		else
        	data_read <= 0;
    end
	else begin
		data_read<= 0;
	end
end
always @ (*)begin
	if (rlast_m_inf_reg) begin
		read_done = 1;
	end
	else begin
		read_done = 0;
	end
end

//=======================================================
//                   WRITE
//=======================================================
//awaddr_m_inf
always @ (*)begin
	awaddr_m_inf = 0;
	if (current_state == WRITE_ADDRESS) begin
		if (write) begin
			awaddr_m_inf = addr;
		end
	end
end
// awvalid_m_inf
always @ (*)begin
	if (current_state == WRITE_ADDRESS) begin
		awvalid_m_inf  = 1;
	end
	else begin
		awvalid_m_inf  = 0;
	end
end
// wdata_m_inf
 always @(posedge clk or negedge rst_n) begin
	if(!rst_n)   data_write_reg<=0;
		else if(/*current_state == WRITE_ADDRESS*/ awready_m_inf)   data_write_reg<=data_write;
		else if(current_state == WRITE_DATA && wready_m_inf) data_write_reg<=data_write;
end
always @ (*)begin
	wdata_m_inf = data_write_reg;
end
// wlast_m_inf 
always @ (*)begin
	wlast_m_inf = 0;
	if (current_state == WRITE_DATA) begin
		if (counter_data == 129) begin
			wlast_m_inf = 1;
		end
	end
end
// wvalid_m_inf 
always @ (*)begin
	wvalid_m_inf = 0;
	if (current_state == WRITE_DATA && counter_data == 3) begin
		wvalid_m_inf = 0;
	end
	else if (current_state == WRITE_DATA) begin
		wvalid_m_inf = 1;
	end
end
// bready_m_inf 
always @ (*)begin
	bready_m_inf = 0;
	if (current_state == WRITE_DATA || current_state == WRITE_FINISH) begin
		bready_m_inf = 1;
	end
end

// write_done
always @ (*)begin
	write_done= 0;
	if (current_state == WRITE_DATA) begin
		if (wready_m_inf) begin
			write_done = 1;
		end
	end
end

endmodule


module DW02_mult_2_stage_inst( inst_A, inst_B, inst_TC, inst_CLK, PRODUCT_inst );
    parameter A_width = 16;
    parameter B_width = 16;
    input [A_width-1 : 0] inst_A;
    input [B_width-1 : 0] inst_B;
    input inst_TC;
    input inst_CLK;
    output [A_width+B_width-1 : 0] PRODUCT_inst;
    // Instance of DW02_mult_2_stage
    DW02_mult_2_stage #(A_width, B_width)
    U1 ( .A(inst_A),
    .B(inst_B),
    .TC(inst_TC),
    .CLK(inst_CLK),
    .PRODUCT(PRODUCT_inst) );
endmodule











