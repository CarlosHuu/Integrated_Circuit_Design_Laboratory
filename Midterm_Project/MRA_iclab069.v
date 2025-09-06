//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Midterm Proejct            : MRA  
//   Author                     : Lin-Hung, Lai
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//   Release version : V2.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA#(parameter ID_WIDTH=4, ADDR_WIDTH=32, DATA_WIDTH=128)(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
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
	   rready_m_inf,
	
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
	   bready_m_inf 
);

// ===============================================================
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
input 			  	clk,rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;     
input  [5:0]       	loc_x; 
input  [5:0]       	loc_y; 
output reg [13:0] 	cost;
output reg          busy;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/
 
// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output wire                  arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output wire                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output wire                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output wire                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------




// ======================================================
// Reg & Wire Declaration
// ======================================================
parameter	IDLE 	= 3'd0,
		    INPUT  = 3'd1,
			DRAM_TO_SRAM_loc = 3'd2,
			DRAM_TO_SRAM_wgt = 3'd3,
			SET_ST = 3'd4,
			DIFFUSION = 3'd5,
			RETRACE = 3'd6,
			WRITE_BACK = 3'd7;
reg [2:0] current_state, next_state;
reg [5:0] counter_input;
reg [7:0] counter_DtoS_L;
reg [7:0] counter_DtoS_W;
reg [7:0] counter_net;
reg [1:0] counter_diffusion;
reg [7:0] counter_retrace;
reg [7:0] counter_writeback;
reg counter_2;
reg [5:0] target_x[15];
reg [5:0] source_x[15];
reg [5:0] target_y[15];
reg [5:0] source_y[15];
reg [3:0] net_id_reg[15];
reg [4:0] frame_id_reg;
reg [127:0] data_read_reg;
reg read_done_reg;
reg [1:0]path_detect;
reg diffusion_finish;
wire retrace_finish;
reg [1:0] debug;
reg [1:0] map [64][64];
reg [1:0] map_comb [64][64];
// reg [1:0] map_retrace [4];
reg [1:0] map_retrace_row [64];
// reg [1:0] map_retrace_rowright [64];
reg [1:0] map_retrace_col [64];
reg [1:0] map_diff [64];
// reg [1:0] map_retrace_coldown [64];
reg [6:0] retrace_x, retrace_y, retrace_x_next, retrace_y_next;	
reg [127:0] update_data;
reg [13:0] cost_reg;
genvar i, j;
integer k,l;
/////////////////////////////// AXI
reg read;
reg write;
reg [ADDR_WIDTH-1:0] addr;
reg [127:0] data_read;
reg [127:0] data_write;
reg read_done;
reg write_done;
///////////////////////////////SRAM
reg [6:0] m_addr, m_addr_ff, w_addr, w_addr_ff;
reg [127:0] m_in, m_in_ff, w_in, w_in_ff;
reg [127:0] m_out, m_out_ff, w_out, w_out_ff;
// reg [127:0] m_out_ff;
reg m_web, m_web_ff, w_web, w_web_ff;
reg m_oe, m_oe_ff, w_oe, w_oe_ff;
reg m_cs, m_cs_ff, w_cs, w_cs_ff;


AXI4_interface AXI4_INF(
	.arid_m_inf(arid_m_inf), .araddr_m_inf(araddr_m_inf), .arlen_m_inf(arlen_m_inf), .arsize_m_inf(arsize_m_inf), .arburst_m_inf(arburst_m_inf), .arvalid_m_inf(arvalid_m_inf), .arready_m_inf(arready_m_inf),
	.rid_m_inf(rid_m_inf), .rdata_m_inf(rdata_m_inf), .rresp_m_inf(rresp_m_inf), .rlast_m_inf(rlast_m_inf), .rvalid_m_inf(rvalid_m_inf), .rready_m_inf(rready_m_inf),
	.awid_m_inf(awid_m_inf), .awaddr_m_inf(awaddr_m_inf), .awsize_m_inf(awsize_m_inf), .awburst_m_inf(awburst_m_inf), .awlen_m_inf(awlen_m_inf), .awvalid_m_inf(awvalid_m_inf), .awready_m_inf(awready_m_inf),
	.wdata_m_inf(wdata_m_inf), .wlast_m_inf(wlast_m_inf), .wvalid_m_inf(wvalid_m_inf), .wready_m_inf(wready_m_inf),
	.bid_m_inf(bid_m_inf), .bresp_m_inf(bresp_m_inf), .bvalid_m_inf(bvalid_m_inf), .bready_m_inf(bready_m_inf),
	
	.clk(clk), .rst_n(rst_n), .read(read), .write(write), .addr(addr),
	.data_read(data_read), .data_write(data_write), .read_done(read_done), .write_done(write_done)
);
// SRAM_map
HU_SRAM M( 	.A0(m_addr[0]), .A1(m_addr[1]), .A2(m_addr[2]), .A3(m_addr[3]), .A4(m_addr[4]), .A5(m_addr[5]), .A6(m_addr[6]), 
			.DO0(m_out[0]), .DO1(m_out[1]), .DO2(m_out[2]), .DO3(m_out[3]), .DO4(m_out[4]), .DO5(m_out[5]), .DO6(m_out[6]), .DO7(m_out[7]), .DO8(m_out[8]), .DO9(m_out[9]), .DO10(m_out[10]), .DO11(m_out[11]), .DO12(m_out[12]), .DO13(m_out[13]), .DO14(m_out[14]), .DO15(m_out[15]), .DO16(m_out[16]), .DO17(m_out[17]), .DO18(m_out[18]), .DO19(m_out[19]), .DO20(m_out[20]), .DO21(m_out[21]), .DO22(m_out[22]), .DO23(m_out[23]), .DO24(m_out[24]), .DO25(m_out[25]), .DO26(m_out[26]), .DO27(m_out[27]), .DO28(m_out[28]), .DO29(m_out[29]), .DO30(m_out[30]), .DO31(m_out[31]), .DO32(m_out[32]), .DO33(m_out[33]), .DO34(m_out[34]), .DO35(m_out[35]), .DO36(m_out[36]), .DO37(m_out[37]), .DO38(m_out[38]), .DO39(m_out[39]), .DO40(m_out[40]), .DO41(m_out[41]), .DO42(m_out[42]), .DO43(m_out[43]), .DO44(m_out[44]), .DO45(m_out[45]), .DO46(m_out[46]), .DO47(m_out[47]), .DO48(m_out[48]), .DO49(m_out[49]), .DO50(m_out[50]), .DO51(m_out[51]), .DO52(m_out[52]), .DO53(m_out[53]), .DO54(m_out[54]), .DO55(m_out[55]), .DO56(m_out[56]), .DO57(m_out[57]), .DO58(m_out[58]), .DO59(m_out[59]), .DO60(m_out[60]), .DO61(m_out[61]), .DO62(m_out[62]), .DO63(m_out[63]), .DO64(m_out[64]), 
			.DO65(m_out[65]), .DO66(m_out[66]), .DO67(m_out[67]), .DO68(m_out[68]), .DO69(m_out[69]), .DO70(m_out[70]), .DO71(m_out[71]), .DO72(m_out[72]), .DO73(m_out[73]), .DO74(m_out[74]), .DO75(m_out[75]), .DO76(m_out[76]), .DO77(m_out[77]), .DO78(m_out[78]), .DO79(m_out[79]), .DO80(m_out[80]), .DO81(m_out[81]), .DO82(m_out[82]), .DO83(m_out[83]), .DO84(m_out[84]), .DO85(m_out[85]), .DO86(m_out[86]), .DO87(m_out[87]), .DO88(m_out[88]), .DO89(m_out[89]), .DO90(m_out[90]), .DO91(m_out[91]), .DO92(m_out[92]), .DO93(m_out[93]), .DO94(m_out[94]), .DO95(m_out[95]), .DO96(m_out[96]), .DO97(m_out[97]), .DO98(m_out[98]), .DO99(m_out[99]), .DO100(m_out[100]), .DO101(m_out[101]), .DO102(m_out[102]), .DO103(m_out[103]), .DO104(m_out[104]), .DO105(m_out[105]), .DO106(m_out[106]), .DO107(m_out[107]), .DO108(m_out[108]), .DO109(m_out[109]), .DO110(m_out[110]), .DO111(m_out[111]), .DO112(m_out[112]), .DO113(m_out[113]), .DO114(m_out[114]), .DO115(m_out[115]), .DO116(m_out[116]), .DO117(m_out[117]), .DO118(m_out[118]), .DO119(m_out[119]), .DO120(m_out[120]), .DO121(m_out[121]), .DO122(m_out[122]), .DO123(m_out[123]), .DO124(m_out[124]), .DO125(m_out[125]), .DO126(m_out[126]), .DO127(m_out[127]), 
			.DI0(m_in[0]), .DI1(m_in[1]), .DI2(m_in[2]), .DI3(m_in[3]), .DI4(m_in[4]), .DI5(m_in[5]), .DI6(m_in[6]), .DI7(m_in[7]), .DI8(m_in[8]), .DI9(m_in[9]), .DI10(m_in[10]), .DI11(m_in[11]), .DI12(m_in[12]), .DI13(m_in[13]), .DI14(m_in[14]), .DI15(m_in[15]), .DI16(m_in[16]), .DI17(m_in[17]), .DI18(m_in[18]), .DI19(m_in[19]), .DI20(m_in[20]), .DI21(m_in[21]), .DI22(m_in[22]), .DI23(m_in[23]), .DI24(m_in[24]), .DI25(m_in[25]), .DI26(m_in[26]), .DI27(m_in[27]), .DI28(m_in[28]), .DI29(m_in[29]), .DI30(m_in[30]), .DI31(m_in[31]), .DI32(m_in[32]), .DI33(m_in[33]), .DI34(m_in[34]), .DI35(m_in[35]), .DI36(m_in[36]), .DI37(m_in[37]), .DI38(m_in[38]), .DI39(m_in[39]), .DI40(m_in[40]), .DI41(m_in[41]), .DI42(m_in[42]), .DI43(m_in[43]), .DI44(m_in[44]), .DI45(m_in[45]), .DI46(m_in[46]), .DI47(m_in[47]), .DI48(m_in[48]), .DI49(m_in[49]), .DI50(m_in[50]), .DI51(m_in[51]), .DI52(m_in[52]), .DI53(m_in[53]), .DI54(m_in[54]), .DI55(m_in[55]), .DI56(m_in[56]), .DI57(m_in[57]), .DI58(m_in[58]), .DI59(m_in[59]), .DI60(m_in[60]), .DI61(m_in[61]), .DI62(m_in[62]), .DI63(m_in[63]), .DI64(m_in[64]), 
			.DI65(m_in[65]), .DI66(m_in[66]), .DI67(m_in[67]), .DI68(m_in[68]), .DI69(m_in[69]), .DI70(m_in[70]), .DI71(m_in[71]), .DI72(m_in[72]), .DI73(m_in[73]), .DI74(m_in[74]), .DI75(m_in[75]), .DI76(m_in[76]), .DI77(m_in[77]), .DI78(m_in[78]), .DI79(m_in[79]), .DI80(m_in[80]), .DI81(m_in[81]), .DI82(m_in[82]), .DI83(m_in[83]), .DI84(m_in[84]), .DI85(m_in[85]), .DI86(m_in[86]), .DI87(m_in[87]), .DI88(m_in[88]), .DI89(m_in[89]), .DI90(m_in[90]), .DI91(m_in[91]), .DI92(m_in[92]), .DI93(m_in[93]), .DI94(m_in[94]), .DI95(m_in[95]), .DI96(m_in[96]), .DI97(m_in[97]), .DI98(m_in[98]), .DI99(m_in[99]), .DI100(m_in[100]), .DI101(m_in[101]), .DI102(m_in[102]), .DI103(m_in[103]), .DI104(m_in[104]), .DI105(m_in[105]), .DI106(m_in[106]), .DI107(m_in[107]), .DI108(m_in[108]), .DI109(m_in[109]), .DI110(m_in[110]), .DI111(m_in[111]), .DI112(m_in[112]), .DI113(m_in[113]), .DI114(m_in[114]), .DI115(m_in[115]), .DI116(m_in[116]), .DI117(m_in[117]), .DI118(m_in[118]), .DI119(m_in[119]), .DI120(m_in[120]), .DI121(m_in[121]), .DI122(m_in[122]), .DI123(m_in[123]), .DI124(m_in[124]), .DI125(m_in[125]), .DI126(m_in[126]), .DI127(m_in[127]), 
			.CK(clk), .WEB(m_web), .OE(m_oe), .CS(m_cs));

// SRAM_weight
HU_SRAM W(	.A0(w_addr[0]), .A1(w_addr[1]), .A2(w_addr[2]), .A3(w_addr[3]), .A4(w_addr[4]), .A5(w_addr[5]), .A6(w_addr[6]), 
			.DO0(w_out[0]), .DO1(w_out[1]), .DO2(w_out[2]), .DO3(w_out[3]), .DO4(w_out[4]), .DO5(w_out[5]), .DO6(w_out[6]), .DO7(w_out[7]), .DO8(w_out[8]), .DO9(w_out[9]), .DO10(w_out[10]), .DO11(w_out[11]), .DO12(w_out[12]), .DO13(w_out[13]), .DO14(w_out[14]), .DO15(w_out[15]), .DO16(w_out[16]), .DO17(w_out[17]), .DO18(w_out[18]), .DO19(w_out[19]), .DO20(w_out[20]), .DO21(w_out[21]), .DO22(w_out[22]), .DO23(w_out[23]), .DO24(w_out[24]), .DO25(w_out[25]), .DO26(w_out[26]), .DO27(w_out[27]), .DO28(w_out[28]), .DO29(w_out[29]), .DO30(w_out[30]), .DO31(w_out[31]), .DO32(w_out[32]), .DO33(w_out[33]), .DO34(w_out[34]), .DO35(w_out[35]), .DO36(w_out[36]), .DO37(w_out[37]), .DO38(w_out[38]), .DO39(w_out[39]), .DO40(w_out[40]), .DO41(w_out[41]), .DO42(w_out[42]), .DO43(w_out[43]), .DO44(w_out[44]), .DO45(w_out[45]), .DO46(w_out[46]), .DO47(w_out[47]), .DO48(w_out[48]), .DO49(w_out[49]), .DO50(w_out[50]), .DO51(w_out[51]), .DO52(w_out[52]), .DO53(w_out[53]), .DO54(w_out[54]), .DO55(w_out[55]), .DO56(w_out[56]), .DO57(w_out[57]), .DO58(w_out[58]), .DO59(w_out[59]), .DO60(w_out[60]), .DO61(w_out[61]), .DO62(w_out[62]), 
			.DO63(w_out[63]), .DO64(w_out[64]), .DO65(w_out[65]), .DO66(w_out[66]), .DO67(w_out[67]), .DO68(w_out[68]), .DO69(w_out[69]), .DO70(w_out[70]), .DO71(w_out[71]), .DO72(w_out[72]), .DO73(w_out[73]), .DO74(w_out[74]), .DO75(w_out[75]), .DO76(w_out[76]), .DO77(w_out[77]), .DO78(w_out[78]), .DO79(w_out[79]), .DO80(w_out[80]), .DO81(w_out[81]), .DO82(w_out[82]), .DO83(w_out[83]), .DO84(w_out[84]), .DO85(w_out[85]), .DO86(w_out[86]), .DO87(w_out[87]), .DO88(w_out[88]), .DO89(w_out[89]), .DO90(w_out[90]), .DO91(w_out[91]), .DO92(w_out[92]), .DO93(w_out[93]), .DO94(w_out[94]), .DO95(w_out[95]), .DO96(w_out[96]), .DO97(w_out[97]), .DO98(w_out[98]), .DO99(w_out[99]), .DO100(w_out[100]), .DO101(w_out[101]), .DO102(w_out[102]), .DO103(w_out[103]), .DO104(w_out[104]), .DO105(w_out[105]), .DO106(w_out[106]), .DO107(w_out[107]), .DO108(w_out[108]), .DO109(w_out[109]), .DO110(w_out[110]), .DO111(w_out[111]), .DO112(w_out[112]), .DO113(w_out[113]), .DO114(w_out[114]), .DO115(w_out[115]), .DO116(w_out[116]), .DO117(w_out[117]), .DO118(w_out[118]), .DO119(w_out[119]), .DO120(w_out[120]), .DO121(w_out[121]), .DO122(w_out[122]), .DO123(w_out[123]), .DO124(w_out[124]), .DO125(w_out[125]), .DO126(w_out[126]), .DO127(w_out[127]), 
			.DI0(w_in[0]), .DI1(w_in[1]), .DI2(w_in[2]), .DI3(w_in[3]), .DI4(w_in[4]), .DI5(w_in[5]), .DI6(w_in[6]), .DI7(w_in[7]), .DI8(w_in[8]), .DI9(w_in[9]), .DI10(w_in[10]), .DI11(w_in[11]), .DI12(w_in[12]), .DI13(w_in[13]), .DI14(w_in[14]), .DI15(w_in[15]), .DI16(w_in[16]), .DI17(w_in[17]), .DI18(w_in[18]), .DI19(w_in[19]), .DI20(w_in[20]), .DI21(w_in[21]), .DI22(w_in[22]), .DI23(w_in[23]), .DI24(w_in[24]), .DI25(w_in[25]), .DI26(w_in[26]), .DI27(w_in[27]), .DI28(w_in[28]), .DI29(w_in[29]), .DI30(w_in[30]), .DI31(w_in[31]), .DI32(w_in[32]), .DI33(w_in[33]), .DI34(w_in[34]), .DI35(w_in[35]), .DI36(w_in[36]), .DI37(w_in[37]), .DI38(w_in[38]), .DI39(w_in[39]), .DI40(w_in[40]), .DI41(w_in[41]), .DI42(w_in[42]), .DI43(w_in[43]), .DI44(w_in[44]), .DI45(w_in[45]), .DI46(w_in[46]), .DI47(w_in[47]), .DI48(w_in[48]), .DI49(w_in[49]), .DI50(w_in[50]), .DI51(w_in[51]), .DI52(w_in[52]), .DI53(w_in[53]), .DI54(w_in[54]), .DI55(w_in[55]), .DI56(w_in[56]), .DI57(w_in[57]), .DI58(w_in[58]), .DI59(w_in[59]), .DI60(w_in[60]), .DI61(w_in[61]), .DI62(w_in[62]), .DI63(w_in[63]), 
			.DI64(w_in[64]), .DI65(w_in[65]), .DI66(w_in[66]), .DI67(w_in[67]), .DI68(w_in[68]), .DI69(w_in[69]), .DI70(w_in[70]), .DI71(w_in[71]), .DI72(w_in[72]), .DI73(w_in[73]), .DI74(w_in[74]), .DI75(w_in[75]), .DI76(w_in[76]), .DI77(w_in[77]), .DI78(w_in[78]), .DI79(w_in[79]), .DI80(w_in[80]), .DI81(w_in[81]), .DI82(w_in[82]), .DI83(w_in[83]), .DI84(w_in[84]), .DI85(w_in[85]), .DI86(w_in[86]), .DI87(w_in[87]), .DI88(w_in[88]), .DI89(w_in[89]), .DI90(w_in[90]), .DI91(w_in[91]), .DI92(w_in[92]), .DI93(w_in[93]), .DI94(w_in[94]), .DI95(w_in[95]), .DI96(w_in[96]), .DI97(w_in[97]), .DI98(w_in[98]), .DI99(w_in[99]), .DI100(w_in[100]), .DI101(w_in[101]), .DI102(w_in[102]), .DI103(w_in[103]), .DI104(w_in[104]), .DI105(w_in[105]), .DI106(w_in[106]), .DI107(w_in[107]), .DI108(w_in[108]), .DI109(w_in[109]), .DI110(w_in[110]), .DI111(w_in[111]), .DI112(w_in[112]), .DI113(w_in[113]), .DI114(w_in[114]), .DI115(w_in[115]), .DI116(w_in[116]), .DI117(w_in[117]), .DI118(w_in[118]), .DI119(w_in[119]), .DI120(w_in[120]), .DI121(w_in[121]), .DI122(w_in[122]), .DI123(w_in[123]), .DI124(w_in[124]), .DI125(w_in[125]), .DI126(w_in[126]), .DI127(w_in[127]), 
			.CK(clk), .WEB(w_web), .OE(w_oe), .CS(w_cs));
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
            if (in_valid)
                next_state = INPUT;
            else
                next_state = IDLE;
        end
        INPUT: begin
            if (!in_valid)
                next_state = DRAM_TO_SRAM_loc;
            else
                next_state = INPUT;
        end
		DRAM_TO_SRAM_loc: begin
			if (counter_DtoS_L== 127 )
				next_state = DRAM_TO_SRAM_wgt;
			else
				next_state = DRAM_TO_SRAM_loc;
		end
		DRAM_TO_SRAM_wgt: begin
			if (counter_DtoS_W== 127 )
				next_state = SET_ST;
			else
				next_state = DRAM_TO_SRAM_wgt;
		end
		SET_ST : begin
			next_state = DIFFUSION;
		end
		DIFFUSION : begin
			if (diffusion_finish) 
				next_state = RETRACE;
			else 
				next_state = DIFFUSION;
		end
		RETRACE : begin
			if (retrace_finish) begin
				if (counter_net == counter_input)
					next_state = WRITE_BACK;
				else
					next_state = SET_ST;
			end
			else 
				next_state = RETRACE;
		end
		WRITE_BACK : begin
			if (bvalid_m_inf)
				next_state = IDLE;
			else
				next_state = WRITE_BACK;
		end
        default: next_state = IDLE;
    endcase 
end

//=======================================================
//                   INPUT
//=======================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_2 <= 0;
	end else if (in_valid) begin
		counter_2 <= ~counter_2 ;
	end else if (current_state == RETRACE) begin
		counter_2 <= ~counter_2 ;
	end else begin
		counter_2 <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_input <= 0;
	end 
	else if (current_state == IDLE) begin
		counter_input <= 0;
	end
	else if (in_valid && counter_2) begin
		counter_input <= counter_input + 1;
	end 
end

generate
    for (i = 0; i < 15; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    source_x[i] <= 0;
					source_y[i] <= 0;
				end else if (in_valid && i == counter_input && ~counter_2) begin
					source_x[i] <= loc_x;
					source_y[i] <= loc_y;
                end 
				else begin
					source_x[i] <= source_x[i];
					source_y[i] <= source_y[i];
				end
         end 
    end
endgenerate 

generate
    for (i = 0; i < 15; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
					target_x[i] <= 0;
					target_y[i] <= 0;
				end else if (current_state == IDLE) begin
					target_x[i] <= 0;
					target_y[i] <= 0;	
				end else if (in_valid && i == counter_input && counter_2) begin
					target_x[i] <= loc_x;
					target_y[i] <= loc_y;
                end 
				else begin
					target_x[i] <= target_x[i];
					target_y[i] <= target_y[i];
				end
         end 
    end
endgenerate 

generate
    for (i = 0; i < 15; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
					net_id_reg[i] <= 0;
				end else if (current_state == IDLE) begin
					net_id_reg[i] <= 0;
				end 
				else if (in_valid && i == counter_input && counter_2) begin
					net_id_reg[i] <= net_id;
                end 
				else begin
					net_id_reg[i] <= net_id_reg[i];
				end
         end 
    end
endgenerate 

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		frame_id_reg <= 0;
	end
	else if (in_valid) begin
		frame_id_reg <= frame_id;
	end
end
//=======================================================
//                DRAM TO SRAM
//=======================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_DtoS_L<=0;
	end
	else if (current_state == IDLE) begin
		counter_DtoS_L<=0;
	end
	else if (current_state == DRAM_TO_SRAM_loc && read_done_reg) begin
		counter_DtoS_L<= counter_DtoS_L+ 1;
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_DtoS_W<=0;
	end
	else if (current_state == IDLE) begin
		counter_DtoS_W<=0;
	end
	else if (current_state == DRAM_TO_SRAM_wgt && read_done_reg) begin
		counter_DtoS_W<= counter_DtoS_W+ 1;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		read_done_reg <=0;
		data_read_reg <=0;
	end
	else begin
		read_done_reg <= read_done;
		data_read_reg <= data_read;
	end
end
//=======================================================
//                AXI
//=======================================================
always @ (*)begin
	addr = 0 ;
	if (current_state == DRAM_TO_SRAM_loc) begin
		addr = {16'd1, frame_id_reg[4:0], 11'd0}; // 16,5,11
	end
	else if (current_state == DRAM_TO_SRAM_wgt) begin
		addr = {16'd2, frame_id_reg[4:0], 11'd0}; // 16,5,11
	end
	else if (current_state == WRITE_BACK) begin
		addr = {16'd1, frame_id_reg[4:0], 11'd0};
	end

end

always @(*) begin
	read = 0;
	if (current_state == DRAM_TO_SRAM_loc) begin
		read = 1;
	end
	else if (current_state == DRAM_TO_SRAM_wgt) begin
		read = 1;
	end
end

always @(*) begin
	write = 0;
	if (current_state == WRITE_BACK) begin
		write = 1;
	end
end
always @(*) begin
	data_write = m_out;
end
// always @ (posedge clk or negedge rst_n) begin
// 	if (!rst_n) begin
// 		m_out_ff <= 0;
// 	end
// 	else begin
// 		m_out_ff <= m_out;
// 	end
// end

//=======================================================
//                MAP
//=======================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_net<=0;
	end
	else if (current_state == IDLE) begin
		counter_net<=0;
	end
	else if (current_state == SET_ST) begin
		counter_net<= counter_net+ 1;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for (k = 0;k <64 ; k =k + 1) begin
			for (l = 0 ; l<64; l=l + 1) begin
				map[k][l] <=0;
			end
		end
	end
	else begin
		for (k = 0;k <64 ; k =k + 1) begin
			for (l = 0 ; l<64; l=l + 1) begin
				map[k][l] <=map_comb[k][l];
			end
		end
	end

end


//=======================================================
//                DIFFUSION
//=======================================================
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_diffusion <=0;	
	end
	else if (current_state == IDLE)  begin
		counter_diffusion <=  0;
	end
	else if (current_state == SET_ST)  begin
		counter_diffusion <=  0;
	end
	else if (current_state == DIFFUSION && next_state != RETRACE)  begin
		counter_diffusion <= counter_diffusion + 1; 
	end
	else if (current_state == DIFFUSION && next_state == RETRACE) begin
		counter_diffusion <= counter_diffusion - 3;
	end
	else if (current_state == RETRACE) begin
		if (counter_2) counter_diffusion <= counter_diffusion - 1;
		else counter_diffusion <= counter_diffusion;
	end
	else begin
		counter_diffusion <= counter_diffusion ; 
	end
end
always @(*) begin
	case (counter_diffusion)
		0,1: begin
			path_detect = 2'd2;
		end
		2,3: begin
			path_detect = 2'd3;
		end
		default: begin
			path_detect = 2'd0;
		end
	endcase
end
always @(*) begin
	if (current_state == DIFFUSION) begin
		for (k = 0 ; k < 64 ; k = k +1) begin
			map_diff[k] = map[k][target_x[counter_net-1]];
		end
	end
	else begin
		for (k = 0 ; k < 64 ; k = k +1) begin
			map_diff[k] =0;
		end
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		diffusion_finish <=  0;
	end
	else if (current_state == DIFFUSION) 
		diffusion_finish <= (map_diff[target_y[counter_net-1]]!=0) ? 1 : 0;
	else begin
		diffusion_finish <=  0;
	end
end

// always @(*) begin
// 	diffusion_finish =  0;
// 	if (current_state == DIFFUSION) 
// 		diffusion_finish = ( map[target_y[counter_net-1]][target_x[counter_net-1]] !=0) ? 1 : 0;
// end

always @ (*) begin
	for (k = 0 ; k <64 ; k =k +1) begin
		for (l=0 ; l <64 ; l = l + 1) begin
			map_comb [k][l] = map [k][l];
		end
	end
	case (current_state) 
		DRAM_TO_SRAM_loc : begin
			if (read_done_reg && counter_DtoS_L[0] == 0) begin
			for (k = 0 ; k <32 ; k = k+ 1) begin
				if (data_read_reg[(k*4)+:4] != 0 )
					map_comb[counter_DtoS_L[6:1]][k] = 1;
				else
					map_comb[counter_DtoS_L[6:1]][k] = 0;
			end
		end
		else if (read_done_reg && counter_DtoS_L[0] == 1) begin
			for (k = 0 ; k <32 ; k = k+ 1) begin
				if (data_read_reg[(k*4)+:4]  != 0 )
					map_comb[counter_DtoS_L[6:1]][k+32] = 1;
				else
					map_comb[counter_DtoS_L[6:1]][k+32] = 0;
			end
		end
		end
		SET_ST : begin
			for (k = 0 ; k <64 ; k =k +1) begin
				for (l=0 ; l <64 ; l = l + 1) begin
					map_comb [k][l] = (map[k][l] == 1) ? map[k][l] : 0;
				end
			end
			map_comb[source_y[counter_net]][source_x[counter_net]] = 3;
			map_comb[target_y[counter_net]][target_x[counter_net]] = 0;
		end

		DIFFUSION : begin 
			for(k = 1; k < 63; k = k + 1)begin//center
				for(l = 1; l < 63; l = l + 1)begin
					if( map[k][l] == 2'b00 && (map[k + 1][l][1]||map[k][l + 1][1]||map[k - 1][l][1]||map[k][l - 1][1]))
						map_comb[k][l] = path_detect;
				end
			end
			for (l = 1; l < 63; l = l + 1) begin//down
				if(map[63][l] == 2'b00 && (map[63][l + 1][1]||map[62][l][1]||map[63][l - 1][1]))
						map_comb[63][l] = path_detect;
			end
			for (l = 1; l < 63; l = l + 1) begin//top
				if(map[0][l] == 2'b00 && (map[0][l + 1][1]||map[1][l][1]||map[0][l - 1][1]))
						map_comb[0][l] = path_detect;
			end
			for (k = 1; k < 63; k = k + 1) begin//right
				if(map[k][63] == 2'b00 && (map[k + 1][63][1]||map[k][62][1]||map[k - 1][63][1]))
						map_comb[k][63] = path_detect;
			end
			for (k = 1; k < 63; k = k + 1) begin//left
				if(map[k][0] == 2'b00 && (map[k + 1][0][1]||map[k][1][1]||map[k - 1][0][1]))
						map_comb[k][0] = path_detect;
			end
			
			if(map[0][0] == 2'b00 && (map[0][1][1]||map[1][0][1]))
						map_comb[0][0] = path_detect;

			if(map[0][63] == 2'b00 && (map[0][62][1]||map[1][63][1]))
						map_comb[0][63] = path_detect;

			if(map[63][0] == 2'b00 && (map[63][1][1]||map[62][0][1]))
						map_comb[63][0] = path_detect;

			if(map[63][63] == 2'b00 && (map[63][62][1]||map[62][63][1]))
						map_comb[63][63] = path_detect;
		end
		RETRACE : begin
				map_comb[retrace_y][retrace_x] = 1;
		end
	endcase
end

//=======================================================
//                RETRACE
//=======================================================
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_retrace <=0;	
	end
	else if (current_state == RETRACE)  begin
		counter_retrace <= counter_retrace + 1;
	end
	else begin
		counter_retrace <=0;	
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		retrace_x <= 0;
		retrace_y <= 0;
	end
	else if (current_state == IDLE) begin
		retrace_x <= 0;
		retrace_y <= 0;
	end
	else if (current_state == SET_ST) begin
		retrace_x <=target_x[counter_net];
		retrace_y <= target_y[counter_net];
	end
	else if (counter_2==1 &&  current_state == RETRACE)begin
		retrace_x <= retrace_x_next;
		retrace_y <= retrace_y_next;
	end
end
assign retrace_finish =  (retrace_x == source_x[counter_net-1] && retrace_y == source_y[counter_net-1])? 1 : 0;
// always @(posedge clk or negedge rst_n) begin
// 	if (!rst_n) begin
// 		for (k = 0 ; k < 4 ; k = k +1) begin
// 			map_retrace [k] <= 0;
// 		end
// 	end
// 	else begin 
// 		map_retrace [0] <= map[retrace_y+1][retrace_x];
// 		map_retrace [1] <= map[retrace_y-1][retrace_x];
// 		map_retrace [2] <= map[retrace_y][retrace_x+1];
// 		map_retrace [3] <= map[retrace_y][retrace_x-1];
// 	end
// end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for (k = 0 ; k < 64 ; k = k +1) begin
			map_retrace_col[k] <= 0;
			map_retrace_row[k] <= 0;
		end
		
	end
	else begin 
		for (k = 0 ; k < 64 ; k = k +1) begin
			map_retrace_col[k] <= map[k][retrace_x];
			map_retrace_row[k] <= map[retrace_y][k];
		end
	end
end

always @ (*) begin
		if (/*map_retrace [0]*/ map_retrace_col[retrace_y+1]== path_detect && retrace_y!=63 ) begin//down
			retrace_y_next = retrace_y + 1;
			retrace_x_next = retrace_x;
		end
		else if (/*map_retrace [1]*/map_retrace_col[retrace_y-1] ==path_detect && retrace_y!=0 ) begin//up
			retrace_y_next = retrace_y - 1;
			retrace_x_next = retrace_x;
		end
		else if(/*map_retrace [2]*/map_retrace_row[retrace_x+1] ==path_detect && retrace_x!=63) begin//right
			retrace_x_next = retrace_x + 1;
			retrace_y_next = retrace_y;
		end
		else if (/*map_retrace [3]*/map_retrace_row[retrace_x-1] ==path_detect && retrace_x!=0) begin//left
			retrace_x_next = retrace_x - 1;	
			retrace_y_next = retrace_y;
		end
	else begin
		retrace_x_next = retrace_x;
		retrace_y_next = retrace_y;
	end
end

//=======================================================
//                SRAM CONTROL
//=======================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_writeback <= 0;
	end
	else if (current_state == IDLE) begin
		counter_writeback <= 0;
	end
	else if (current_state == WRITE_BACK && wready_m_inf) begin
		counter_writeback <= counter_writeback + 1;
	end

end
always @ (*)begin
	m_cs = 0;
	m_oe = 0;
	m_web = 0;
	m_addr = 0;
	m_in = 0;
	if (current_state == DRAM_TO_SRAM_loc) begin
		if (read_done_reg) begin
			m_cs = 1;
			m_oe = 1;
			m_web = 0;
			m_addr = counter_DtoS_L;
			m_in = data_read_reg;
		end
	end
	else if (current_state == RETRACE) begin
		m_cs = 1;
		m_oe = 1;
		m_web = (counter_2 == 1) ? 0 : 1;
		m_addr = {retrace_y[5:0], retrace_x[5]};
		m_in = m_out;
		m_in[retrace_x[4:0]*4+:4] = net_id_reg[counter_net-1];
	end
	else if (current_state == WRITE_BACK) begin
		m_cs = 1;
		m_oe = 1;
		m_web = 1;
		m_addr = (wready_m_inf) ? counter_writeback+1 : counter_writeback;
	end
end
always @ (*)begin
	w_cs = 0;
	w_oe = 0;
	w_web = 0;
	w_addr = 0;
	w_in = 0;
	if (current_state == DRAM_TO_SRAM_wgt) begin
		if (read_done_reg) begin
			w_cs = 1;
			w_oe = 1;
			w_web = 0;
			w_addr = counter_DtoS_W;
			w_in = data_read_reg;
		end
	end
	else if (current_state == RETRACE) begin
		w_cs = 1;
		w_oe = 1;
		w_web = 1;
		w_addr = {retrace_y[5:0], retrace_x[5]};
	end
end




//=======================================================
//                OUTPUT
//=======================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cost_reg <= 14'b0;
	end
	else if(current_state==RETRACE)begin
		// substract start&final
		if( ~counter_2 || (retrace_x==target_x[counter_net-1] && retrace_y==target_y[counter_net-1]) || (retrace_x==source_x[counter_net-1] && retrace_y==source_y[counter_net-1]) )begin
			cost_reg <= 14'b0;
		end 
		else begin
			cost_reg <= {w_out[{retrace_x[4:0],2'b11}],w_out[{retrace_x[4:0],2'b10}],w_out[{retrace_x[4:0],2'b01}],w_out[{retrace_x[4:0],2'b00}]};
		end
	end
	else cost_reg <= 14'b0;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cost <= 0;
	end 
	else if (current_state == IDLE) begin
		cost <= 0;
	end
	else if (current_state == RETRACE) begin
		cost <= cost + cost_reg;
	end
	else begin
		cost <= cost;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		busy <= 0;
	end else if (!in_valid && current_state == INPUT) begin
		busy <= 1;
	end
		else if (current_state == WRITE_BACK && bvalid_m_inf) begin
		busy <= 0;
	end 
end



endmodule











//=======================================================
//                AXI
//=======================================================

module AXI4_interface #(parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32)(
	arid_m_inf, araddr_m_inf, arlen_m_inf, arsize_m_inf, arburst_m_inf, arvalid_m_inf, arready_m_inf,
	rid_m_inf, rdata_m_inf, rresp_m_inf, rlast_m_inf, rvalid_m_inf, rready_m_inf,
	awid_m_inf, awaddr_m_inf, awsize_m_inf, awburst_m_inf, awlen_m_inf, awvalid_m_inf, awready_m_inf,
	wdata_m_inf, wlast_m_inf, wvalid_m_inf, wready_m_inf,
	bid_m_inf, bresp_m_inf, bvalid_m_inf, bready_m_inf,

	clk, rst_n, read, write, addr, data_read, data_write, read_done, write_done
);

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output reg                  arvalid_m_inf;
input  wire                  arready_m_inf;
output reg [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output reg                    rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output reg                  awvalid_m_inf;
input  wire                  awready_m_inf;
output reg [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output reg                   wvalid_m_inf;
input  wire                   wready_m_inf;
output reg [DATA_WIDTH-1:0]   wdata_m_inf;
output reg                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output reg                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------

input clk;
input rst_n;
input read;
input write;
input [ADDR_WIDTH-1:0] addr;
output reg [127:0] data_read;
input [127:0] data_write;
output reg read_done;
output reg write_done;

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


reg [3:0] current_state, next_state;
reg [7:0] counter, counter_comb;
// reg [ADDR_WIDTH-1:0] araddr_m_inf_comb;
reg [127:0] data_read_comb;
reg read_done_comb;
//=======================================================
//                   initial
//=======================================================

//read
assign arid_m_inf = 0;
assign arburst_m_inf = 2'b01;
assign arsize_m_inf = 3'b100;
assign arlen_m_inf = 127;
//write
assign awid_m_inf = 0;
assign awburst_m_inf = 2'b01;
assign awsize_m_inf = 3'b100;
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
	counter_comb = counter;
	if (current_state == READ_ADDRESS) begin
		counter_comb = 0;
	end 
	else if (current_state == READ_DATA) begin
		if (rvalid_m_inf) begin
			counter_comb = counter + 1;
		end
	end
	else if (current_state == WRITE_ADDRESS) begin
		if (!awready_m_inf) begin
			counter_comb = 0;
		end
	end
	else if (current_state == WRITE_DATA) begin
		if (wready_m_inf) begin
			counter_comb = counter + 1;
		end
	end
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter<= 0;
	end else begin
		counter <= counter_comb;
	end
end
//=======================================================
//                   read
//=======================================================
//araddr_m_inf
always @ (*)begin
	araddr_m_inf = 0;
	if (current_state == READ_ADDRESS) begin
		if (read) begin
			araddr_m_inf = addr;
		end
	end
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

always @ (*)begin
	data_read = rdata_m_inf;
end

always @ (*)begin
	if (rvalid_m_inf) begin
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
always @ (*)begin
	wdata_m_inf = data_write;
end
// wlast_m_inf 
always @ (*)begin
	wlast_m_inf = 0;
	if (current_state == WRITE_DATA) begin
		if (counter == 127) begin
			wlast_m_inf = 1;
		end
	end
end
// wvalid_m_inf 
always @ (*)begin
	wvalid_m_inf = 0;
	if (current_state == WRITE_DATA) begin
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






