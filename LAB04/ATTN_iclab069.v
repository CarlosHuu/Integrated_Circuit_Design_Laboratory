//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Two Head Attention
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : ATTN.v
//   Module Name : ATTN
//   Release version : V1.0 (Release Date: 2025-3)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


module ATTN(
    //Input Port
    clk,
    rst_n,

    in_valid,
    in_str,
    q_weight,
    k_weight,
    v_weight,
    out_weight,

    //Output Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
parameter sqare_root_2 = 32'b00111111101101010000010011110011;

parameter IDLE = 3'd0;
parameter INPUT = 3'd1;
parameter KQstate = 3'd2;
parameter SCORE = 3'd3;
parameter HEAD = 3'd4;
parameter OUTPUT = 3'd5;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] in_str, q_weight, k_weight, v_weight, out_weight;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;


//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
reg [2:0] current_state, next_state;
reg [inst_sig_width+inst_exp_width:0] in_str_reg [5][4];
reg [inst_sig_width+inst_exp_width:0] q_weight_reg [4][4];
reg [inst_sig_width+inst_exp_width:0] k_weight_reg [4][4];
reg [inst_sig_width+inst_exp_width:0] k_5x4 [5][4];
reg [inst_sig_width+inst_exp_width:0] q_5x4 [5][4];
reg [inst_sig_width+inst_exp_width:0] v_5x4 [5][4];
reg [inst_sig_width+inst_exp_width:0] v_weight_reg [4][4];
reg [inst_sig_width+inst_exp_width:0] out_weight_reg [4][4];
// reg [inst_sig_width+inst_exp_width:0] score1 [5][5];
reg [inst_sig_width+inst_exp_width:0] score1_softmax [5][5];
// reg [inst_sig_width+inst_exp_width:0] score2 [5][5];
reg [inst_sig_width+inst_exp_width:0] score2_softmax [5][5];

reg [inst_sig_width+inst_exp_width:0] head_out [5][4];
// reg [inst_sig_width+inst_exp_width:0] head_2 [2][5];
reg [inst_sig_width+inst_exp_width:0] V1 [5];
reg [inst_sig_width+inst_exp_width:0] V2 [5];
reg [inst_sig_width+inst_exp_width:0] out_sim;
reg [4:0] counter, counter_head, counter_out;
reg [7:0] counter_score;
reg [1:0] counter_kq, counter_v;
reg [2:0] counter_instr;
reg  [inst_sig_width+inst_exp_width:0] reg_div11, reg_div12, reg_div21, reg_div22;
wire [inst_sig_width+inst_exp_width:0] in_div11, in_div12, out_div1,in_div21, in_div22, out_div2;
reg  [inst_sig_width+inst_exp_width:0] reg_mult11, reg_mult12, reg_mult21, reg_mult22, reg_mult31, reg_mult32, reg_mult41, reg_mult42, reg_mult51, reg_mult52;
reg  [inst_sig_width+inst_exp_width:0] reg_mult61, reg_mult62, reg_mult71, reg_mult72, reg_mult81, reg_mult82, reg_mult91, reg_mult92, reg_mult101, reg_mult102;
wire [inst_sig_width+inst_exp_width:0] in_mult11, in_mult12, out_mult1;
wire [inst_sig_width+inst_exp_width:0] in_mult21, in_mult22, out_mult2;
wire [inst_sig_width+inst_exp_width:0] in_mult31, in_mult32, out_mult3;
wire [inst_sig_width+inst_exp_width:0] in_mult41, in_mult42, out_mult4;
wire [inst_sig_width+inst_exp_width:0] in_mult51, in_mult52, out_mult5;
wire [inst_sig_width+inst_exp_width:0] in_mult61, in_mult62, out_mult6;
wire [inst_sig_width+inst_exp_width:0] in_mult71, in_mult72, out_mult7;
wire [inst_sig_width+inst_exp_width:0] in_mult81, in_mult82, out_mult8;
wire [inst_sig_width+inst_exp_width:0] in_mult91, in_mult92, out_mult9;
wire [inst_sig_width+inst_exp_width:0] in_mult101, in_mult102, out_mult10;
reg  [inst_sig_width+inst_exp_width:0] reg_add11, reg_add12, reg_add21, reg_add22, reg_add31, reg_add32, reg_add41, reg_add42;
reg  [inst_sig_width+inst_exp_width:0] reg_add51, reg_add52, reg_add61, reg_add62, reg_add71, reg_add72, reg_add81, reg_add82;
wire [inst_sig_width+inst_exp_width:0] in_add11, in_add12, out_add1;
wire [inst_sig_width+inst_exp_width:0] in_add21, in_add22, out_add2;
wire [inst_sig_width+inst_exp_width:0] in_add31, in_add32, out_add3;
wire [inst_sig_width+inst_exp_width:0] in_add41, in_add42, out_add4;
wire [inst_sig_width+inst_exp_width:0] in_add51, in_add52, out_add5;
wire [inst_sig_width+inst_exp_width:0] in_add61, in_add62, out_add6;
wire [inst_sig_width+inst_exp_width:0] in_add71, in_add72, out_add7;
wire [inst_sig_width+inst_exp_width:0] in_add81, in_add82, out_add8;

reg  [inst_sig_width+inst_exp_width:0] reg_exp1, reg_exp2, exp_plus_reg, exp_plus_reg_1 , denominator_1, numerator_1, denominator_2, numerator_2;
wire [inst_sig_width+inst_exp_width:0] in_exp1, out_exp1;
wire [inst_sig_width+inst_exp_width:0] in_exp2, out_exp2;

reg  [inst_sig_width+inst_exp_width:0] score1_reg;
reg  [inst_sig_width+inst_exp_width:0] score2_reg;
reg  [inst_sig_width+inst_exp_width:0] queue_1[5];
reg  [inst_sig_width+inst_exp_width:0] queue_2[5];

wire [7:0] status_d1, status_d2;
wire [7:0] status_m1, status_m2, status_m3, status_m4, status_m5;
wire [7:0] status_m6, status_m7, status_m8, status_m9, status_m10;
wire [7:0] status_a1, status_a2, status_a3, status_a4;
wire [7:0] status_a5, status_a6, status_a7, status_a8;
wire [7:0] status_e1, status_e2;
reg [inst_sig_width+inst_exp_width:0] k_weight_source;
wire [inst_sig_width+inst_exp_width:0] k_out, q_out;
reg  [inst_sig_width+inst_exp_width:0] head_reg_add11, head_reg_add12, head_reg_add21, head_reg_add22, head_reg_add41, head_reg_add42_1, head_reg_add42_2, head_reg_add51, head_reg_add52, head_reg_add61, head_reg_add62, head_reg_add81, head_reg_add82_1, head_reg_add82_2;
genvar i, j;
integer k, l;
//---------------------------------------------------------------------
// IPs
//---------------------------------------------------------------------
// ex.
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// MUL1 ( .a(mul1_a), .b(mul1_b), .rnd(3'b000), .z(mul1_res), .status(mul_status1));
DW_fp_div #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    D1(.a(in_div11),.b(in_div12),.rnd(3'b000),.z(out_div1),.status(status_d1));
DW_fp_div #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    D2(.a(in_div21),.b(in_div22),.rnd(3'b000),.z(out_div2),.status(status_d2));

DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    M1(.a(in_mult11),.b(in_mult12),.rnd(3'b000),.z(out_mult1),.status(status_m1));
DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    M2(.a(in_mult21),.b(in_mult22),.rnd(3'b000),.z(out_mult2),.status(status_m2));
DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    M3(.a(in_mult31),.b(in_mult32),.rnd(3'b000),.z(out_mult3),.status(status_m3));
DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    M4(.a(in_mult41),.b(in_mult42),.rnd(3'b000),.z(out_mult4),.status(status_m4));
DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    M5(.a(in_mult51),.b(in_mult52),.rnd(3'b000),.z(out_mult5),.status(status_m5));
DW_fp_add  #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    A1(.a(in_add11) ,.b(in_add12) ,.rnd(3'b000),.z(out_add1) ,.status(status_a1));
DW_fp_add  #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    A2(.a(in_add21) ,.b(in_add22) ,.rnd(3'b000),.z(out_add2) ,.status(status_a2));
DW_fp_add  #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    A3(.a(in_add31) ,.b(in_add32) ,.rnd(3'b000),.z(out_add3) ,.status(status_a3));
DW_fp_add  #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    A4(.a(in_add41) ,.b(in_add42) ,.rnd(3'b000),.z(out_add4) ,.status(status_a4));

DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    M6(.a(in_mult61),.b(in_mult62),.rnd(3'b000),.z(out_mult6),.status(status_m6));
DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    M7(.a(in_mult71),.b(in_mult72),.rnd(3'b000),.z(out_mult7),.status(status_m7));
DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    M8(.a(in_mult81),.b(in_mult82),.rnd(3'b000),.z(out_mult8),.status(status_m8));
DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    M9(.a(in_mult91),.b(in_mult92),.rnd(3'b000),.z(out_mult9),.status(status_m9));
DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    M10(.a(in_mult101),.b(in_mult102),.rnd(3'b000),.z(out_mult10),.status(status_m10));
DW_fp_add  #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    A5(.a(in_add51) ,.b(in_add52) ,.rnd(3'b000),.z(out_add5) ,.status(status_a5));
DW_fp_add  #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    A6(.a(in_add61) ,.b(in_add62) ,.rnd(3'b000),.z(out_add6) ,.status(status_a6));
DW_fp_add  #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    A7(.a(in_add71) ,.b(in_add72) ,.rnd(3'b000),.z(out_add7) ,.status(status_a7));
DW_fp_add  #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    A8(.a(in_add81) ,.b(in_add82) ,.rnd(3'b000),.z(out_add8) ,.status(status_a8));

DW_fp_exp  #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch) 
    E1(.a(in_exp1) ,.z(out_exp1) ,.status(status_e1));
DW_fp_exp  #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch) 
    E2(.a(in_exp2) ,.z(out_exp2) ,.status(status_e2));
// //=======================================================
wire [7:0] status_a9, status_a10;
reg  [inst_sig_width+inst_exp_width:0] reg_add101, reg_add102, reg_add91, reg_add92;
wire [inst_sig_width+inst_exp_width:0] in_add91, in_add92, out_add9;
wire [inst_sig_width+inst_exp_width:0] in_add101, in_add102, out_add10;
DW_fp_add  #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    A9(.a(in_add91) ,.b(in_add92) ,.rnd(3'b000),.z(out_add9) ,.status(status_a9));
DW_fp_add  #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    A10(.a(in_add101) ,.b(in_add102) ,.rnd(3'b000),.z(out_add10) ,.status(status_a10));
// //=======================================================

//==============================================================================================================
// FSM
//==============================================================================================================
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
                next_state = KQstate;
            else
                next_state = INPUT;
        end
        KQstate: begin
            if (counter_instr==4 && counter_kq==3)
                next_state = SCORE;
            else
                next_state = KQstate;
        end
        SCORE: begin
            if (counter_score == 'd31)
                next_state = HEAD;
            else
                next_state = SCORE;
        end
        HEAD: begin
            if (counter_head == 'd12)
                next_state = OUTPUT;
            else
                next_state = HEAD;
        end
        OUTPUT: begin
            if (counter_out == 'd19)
                next_state = IDLE;
            else
                next_state = OUTPUT;
        end


        default: next_state = IDLE;
    endcase
end
// //==============================================================================================================
// // multiplication
// //==============================================================================================================
always @(*) begin
    if (current_state == KQstate) begin
        reg_mult11 = in_str_reg[0][0];
    end
    else if (current_state == SCORE) begin
        reg_mult11 = q_5x4[0][0];
    end
    else if (current_state == HEAD) begin
        reg_mult11 = score1_softmax[0][0];
    end
    else if (current_state == OUTPUT) begin
        reg_mult11 = head_out[0][0];
    end
    else begin
        reg_mult11 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_mult12 = k_weight_reg[0][0];
    end
    else if (current_state == SCORE) begin
        reg_mult12 = k_5x4[0][0];
    end
    else if (current_state == HEAD) begin
        reg_mult12 = V1[0];
    end
    else if (current_state == OUTPUT) begin
        reg_mult12 = out_weight_reg[0][0];
    end
    else begin
        reg_mult12 = 0;
    end        
end

always @(*) begin
    if (current_state == KQstate) begin
        reg_mult21 = in_str_reg[0][1];
    end
    else if (current_state == SCORE) begin
        reg_mult21 = q_5x4[0][1];
    end
    else if (current_state == HEAD) begin
        reg_mult21 = score1_softmax[0][1];
    end
    else if (current_state == OUTPUT) begin
        reg_mult21 = head_out[0][1];
    end
    else begin
        reg_mult21 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_mult22 = k_weight_reg[0][1];
    end
    else if (current_state == SCORE) begin
        reg_mult22 = k_5x4[0][1];
    end
    else if (current_state == HEAD) begin
        reg_mult22 = V1[1];
    end
    else if (current_state == OUTPUT) begin
        reg_mult22 = out_weight_reg[0][1];
    end
    else begin
        reg_mult22 = 0;
    end        
end

always @(*) begin
    if (current_state == KQstate) begin
        reg_mult31 = in_str_reg[0][2];
    end
    else if (current_state == SCORE) begin
        reg_mult31 = q_5x4[0][2];
    end
    else if (current_state == HEAD) begin
        reg_mult31 = score1_softmax[0][2];
    end
    else if (current_state == OUTPUT) begin
        reg_mult31 = head_out[0][2];
    end
    else begin
        reg_mult31 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_mult32 = k_weight_reg[0][2];
    end
    else if (current_state == SCORE) begin
        reg_mult32 = k_5x4[0][2];
    end
    else if (current_state == HEAD) begin
        reg_mult32 = V1[2];
    end
    else if (current_state == OUTPUT) begin
        reg_mult32 = out_weight_reg[0][2];
    end
    else begin
        reg_mult32 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_mult41 = in_str_reg[0][3];
    end
    else if (current_state == SCORE) begin
        reg_mult41 = q_5x4[0][3];
    end
    else if (current_state == HEAD) begin
        reg_mult41 = score1_softmax[0][3];
    end
    else if (current_state == OUTPUT) begin
        reg_mult41 = head_out[0][3];
    end
    else begin
        reg_mult41 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_mult42 = k_weight_reg[0][3];
    end
    else if (current_state == SCORE) begin
        reg_mult42 = k_5x4[0][3];
    end
    else if (current_state == HEAD) begin
        reg_mult42 = V1[3];
    end
    else if (current_state == OUTPUT) begin
        reg_mult42 = out_weight_reg[0][3];
    end
    else begin
        reg_mult42 = 0;
    end        
end
assign in_mult11 =  reg_mult11;
assign in_mult12 =  reg_mult12;
assign in_mult21 =  reg_mult21;
assign in_mult22 =  reg_mult22;
assign in_mult31 =  reg_mult31;
assign in_mult32 =  reg_mult32;
assign in_mult41 =  reg_mult41;
assign in_mult42 =  reg_mult42;
always @(*) begin
    if (current_state == KQstate) begin
        reg_mult51 = in_str_reg[0][0];
    end
    else if (current_state == SCORE) begin
        reg_mult51 = in_str_reg[0][0];
    end
    else if (current_state == HEAD) begin
        reg_mult51 = score1_softmax[0][4];
    end
    else begin
        reg_mult51 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_mult52 = q_weight_reg[0][0];
    end
    else if (current_state == SCORE) begin
        reg_mult52 = v_weight_reg[0][0];
    end
    else if (current_state == HEAD) begin
        reg_mult52 = V1[4];
    end
    else begin
        reg_mult52 = 0;
    end        
end

always @(*) begin
    if (current_state == KQstate) begin
        reg_mult61 = in_str_reg[0][1];
    end
    else if (current_state == SCORE) begin
        reg_mult61 = in_str_reg[0][1];
    end
    else if (current_state == HEAD) begin
        reg_mult61 = score2_softmax[0][0];
    end
    else begin
        reg_mult61 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_mult62 = q_weight_reg[0][1];
    end
    else if (current_state == SCORE) begin
        reg_mult62 = v_weight_reg[0][1];
    end
    else if (current_state == HEAD) begin
        reg_mult62 = V2[0];
    end
    else begin
        reg_mult62 = 0;
    end        
end

always @(*) begin
    if (current_state == KQstate) begin
        reg_mult71 = in_str_reg[0][2];
    end
    else if (current_state == SCORE) begin
        reg_mult71 = in_str_reg[0][2];
    end
    else if (current_state == HEAD) begin
        reg_mult71 = score2_softmax[0][1];
    end
    else begin
        reg_mult71 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_mult72 = q_weight_reg[0][2];
    end
    else if (current_state == SCORE) begin
        reg_mult72 = v_weight_reg[0][2];
    end
    else if (current_state == HEAD) begin
        reg_mult72 = V2[1];
    end
    else begin
        reg_mult72 = 0;
    end        
end

always @(*) begin
    if (current_state == KQstate) begin
        reg_mult81 = in_str_reg[0][3];
    end
    else if (current_state == SCORE) begin
        reg_mult81 = in_str_reg[0][3];
    end
    else if (current_state == HEAD) begin
        reg_mult81 = score2_softmax[0][2];
    end
    else begin
        reg_mult81 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_mult82 = q_weight_reg[0][3];
    end
    else if (current_state == SCORE) begin
        reg_mult82 = v_weight_reg[0][3];
    end
    else if (current_state == HEAD) begin
        reg_mult82 = V2[2];
    end
    else begin
        reg_mult82 = 0;
    end        
end
always @(*) begin
    if (current_state == HEAD) begin
        reg_mult91 = score2_softmax[0][3];
    end
    else begin
        reg_mult91 = 0;
    end        
end
always @(*) begin
    if (current_state == HEAD) begin
        reg_mult92 = V2[3];
    end
    else begin
        reg_mult92 = 0;
    end        
end
always @(*) begin
    if (current_state == HEAD) begin
        reg_mult101 = score2_softmax[0][4];
    end
    else begin
        reg_mult101 = 0;
    end        
end
always @(*) begin
    if (current_state == HEAD) begin
        reg_mult102 = V2[4];
    end
    else begin
        reg_mult102 = 0;
    end        
end
assign in_mult51 =  reg_mult51;
assign in_mult52 =  reg_mult52;
assign in_mult61 =  reg_mult61;
assign in_mult62 =  reg_mult62;
assign in_mult71 =  reg_mult71;
assign in_mult72 =  reg_mult72;
assign in_mult81 =  reg_mult81;
assign in_mult82 =  reg_mult82;
assign in_mult91 =  reg_mult91;
assign in_mult92 =  reg_mult92;
assign in_mult101 =  reg_mult101;
assign in_mult102 =  reg_mult102;
// //==============================================================================================================
// // adder
// //==============================================================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        head_reg_add11 <= 0;
        head_reg_add12 <= 0;
        head_reg_add21 <= 0;
        head_reg_add22 <= 0;
        head_reg_add42_1 <= 0;
    end
    else if (current_state == HEAD)begin
        head_reg_add11 <= out_mult1;
        head_reg_add12 <= out_mult2;
        head_reg_add21 <= out_mult3;
        head_reg_add22 <= out_mult4;
        head_reg_add42_1 <= out_mult5;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        head_reg_add41 <= 0;
        head_reg_add42_2 <= 0;
    end
    else if (current_state == HEAD)begin
        head_reg_add41 <= out_add3;
        head_reg_add42_2 <= head_reg_add42_1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        head_reg_add51 <= 0;
        head_reg_add52 <= 0;
        head_reg_add61 <= 0;
        head_reg_add62 <= 0;
        head_reg_add82_1 <= 0;
    end
    else if (current_state == HEAD)begin
        head_reg_add51 <= out_mult6;
        head_reg_add52 <= out_mult7;
        head_reg_add61 <= out_mult8;
        head_reg_add62 <= out_mult9;
        head_reg_add82_1 <= out_mult10;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        head_reg_add81 <= 0;
        head_reg_add82_2 <= 0;
    end
    else if (current_state == HEAD)begin
        head_reg_add81 <= out_add7;
        head_reg_add82_2 <= head_reg_add82_1;
    end
end

always @(*) begin
    if (current_state == KQstate) begin
        reg_add11 = out_mult1;
    end
    else if (current_state == SCORE && (counter_score<'d25) ) begin
        reg_add11 = out_mult1;
    end
    else if (current_state == HEAD) begin
        // reg_add11 = out_mult1;
        reg_add11 = head_reg_add11;
    end
    else if (current_state == OUTPUT) begin
        reg_add11 = out_mult1;
    end
    else begin
        reg_add11 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_add12 = out_mult2;
    end
    else if (current_state == SCORE && (counter_score<'d25)) begin
        reg_add12 = out_mult2;
    end
    else if (current_state == HEAD) begin
        // reg_add12 = out_mult2;
        reg_add12 = head_reg_add12;
    end
    else if (current_state == OUTPUT) begin
        reg_add12 = out_mult2;
    end
    else begin
        reg_add12 = 0;
    end        
end

always @(*) begin
    if (current_state == KQstate) begin
        reg_add21 = out_mult3;
    end
    else if (current_state == SCORE && (counter_score<'d25)) begin
        reg_add21 = out_mult3;
    end
    else if (current_state == HEAD) begin
        // reg_add21 = out_mult3;
        reg_add21 = head_reg_add21;
    end
    else if (current_state == OUTPUT) begin
        reg_add21 = out_mult3;
    end
    else begin
        reg_add21 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_add22 = out_mult4;
    end
    else if (current_state == SCORE && (counter_score<'d25)) begin
        reg_add22 = out_mult4;
    end
    else if (current_state == HEAD) begin
        // reg_add22 = out_mult4;
        reg_add22 = head_reg_add22;
    end
    else if (current_state == OUTPUT) begin
        reg_add22 = out_mult4;
    end
    else begin
        reg_add22 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_add31 = out_add1;
    end
    // else if (current_state == SCORE && (counter_score<'d26)) begin
    //     reg_add31 = out_exp1;
    // end
    else if (current_state == HEAD) begin
        reg_add31 = out_add1;
    end
    else if (current_state == OUTPUT) begin
        reg_add31 = out_add1;
    end
    else begin
        reg_add31 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_add32 = out_add2;
    end
    // else if (current_state == SCORE && (counter_score<'d26)) begin
    //     case (counter_score)
    //         'd6: reg_add32 = 0;
    //         'd11: reg_add32 = 0;
    //         'd16: reg_add32 = 0;
    //         'd21: reg_add32 = 0;
    //         // 'd24: reg_add32 = 0;
    //         default: reg_add32 = exp_plus_reg;
    //     endcase
    // end
    else if (current_state == HEAD) begin
        reg_add32 = out_add2;
    end 
    else if (current_state == OUTPUT) begin
        reg_add32 = out_add2;
    end 
    else begin
        reg_add32 = 0;
    end        
end
always @(*) begin
    if (current_state == SCORE && (counter_score<'d26)) begin
        reg_add91 = out_exp1;
    end
    else begin
        reg_add91 = 0;
    end
end
always @(*) begin
    if (current_state == SCORE && (counter_score<'d26)) begin
        case (counter_score)
            'd6: reg_add92 = 0;
            'd11: reg_add92 = 0;
            'd16: reg_add92 = 0;
            'd21: reg_add92 = 0;
            // 'd24: reg_add32 = 0;
            default: reg_add92 = exp_plus_reg;
        endcase
    end
    else begin
        reg_add92 = 0;
    end
end
always @(*) begin
    if (current_state == SCORE && (counter_score<'d26)) begin
        reg_add101 = out_exp2;
    end
    else begin
        reg_add101 = 0;
    end
end
always @(*) begin
    if (current_state == SCORE && (counter_score<'d26)) begin
        case (counter_score)
            'd6: reg_add102 = 0;
            'd11: reg_add102 = 0;
            'd16: reg_add102 = 0;
            'd21: reg_add102 = 0;
            // 'd24: reg_add32 = 0;
            default: reg_add102 = exp_plus_reg_1;
        endcase
    end
    else begin
        reg_add102 = 0;
    end
end
assign in_add91 =  reg_add91;
assign in_add92 =  reg_add92;
assign in_add101 =  reg_add101;
assign in_add102 =  reg_add102;

assign in_add11 =  reg_add11;
assign in_add12 =  reg_add12;
assign in_add21 =  reg_add21;
assign in_add22 =  reg_add22;
assign in_add31 =  reg_add31;
assign in_add32 =  reg_add32;
always @(*) begin
    if (current_state == KQstate) begin
        reg_add41 = out_mult5;
    end
    // else if (current_state == SCORE && (counter_score<'d26)) begin
    //     reg_add41 = out_exp2;
    // end
    else if (current_state == HEAD) begin
        // reg_add41 = out_add3;
        reg_add41 = head_reg_add41;
    end 
    else begin
        reg_add41 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_add42 = out_mult6;
    end
    // else if (current_state == SCORE && (counter_score<'d26)) begin
    //     case (counter_score)
    //         'd6: reg_add42 = 0;
    //         'd11: reg_add42 = 0;
    //         'd16: reg_add42 = 0;
    //         'd21: reg_add42 = 0;
    //         // 'd24: reg_add42 = 0;
    //         default: reg_add42 = exp_plus_reg_1;
    //     endcase
    // end
    else if (current_state == HEAD) begin
        // reg_add42 = out_mult5;
        reg_add42 = head_reg_add42_2;
    end 
    else begin
        reg_add42 = 0;
    end        
end

always @(*) begin
    if (current_state == KQstate) begin
        reg_add51 = out_mult7;
    end
    else if (current_state == SCORE) begin
        reg_add51 = out_mult5;
    end
    else if (current_state == HEAD) begin
        // reg_add51 = out_mult6;
        reg_add51 = head_reg_add51;
    end 
    else begin
        reg_add51 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_add52 = out_mult8;
    end
    else if (current_state == SCORE) begin
        reg_add52 = out_mult6;
    end
    else if (current_state == HEAD) begin
        // reg_add52 = out_mult7;
        reg_add52 = head_reg_add52;
    end 
    else begin
        reg_add52 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_add61 = out_add4;
    end
    else if (current_state == SCORE) begin
        reg_add61 = out_mult7;
    end
    else if (current_state == HEAD) begin
        // reg_add61 = out_mult8;
        reg_add61 = head_reg_add61;
    end 
    else begin
        reg_add61 = 0;
    end        
end
always @(*) begin
    if (current_state == KQstate) begin
        reg_add62 = out_add5;
    end
    else if (current_state == SCORE) begin
        reg_add62 = out_mult8;
    end
    else if (current_state == HEAD) begin
        // reg_add62 = out_mult9;
        reg_add62 = head_reg_add62;
    end 
    else begin
        reg_add62 = 0;
    end        
end
always @(*) begin
    if (current_state == SCORE) begin
        reg_add71 = out_add5;
    end
    else if (current_state == HEAD) begin
        reg_add71 = out_add5;
    end 
    else begin
        reg_add71 = 0;
    end        
end
always @(*) begin
    if (current_state == SCORE) begin
        reg_add72 = out_add6;
    end
    else if (current_state == HEAD) begin
        reg_add72 = out_add6;
    end 
    else begin
        reg_add72 = 0;
    end        
end
always @(*) begin
    if (current_state == HEAD) begin
        // reg_add81 = out_add7;
        reg_add81 = head_reg_add81;
    end 
    else begin
        reg_add81 = 0;
    end        
end
always @(*) begin
    if (current_state == HEAD) begin
        // reg_add82 = out_mult10;
        reg_add82 = head_reg_add82_2;
    end 
    else begin
        reg_add82 = 0;
    end        
end
assign in_add41 =  reg_add41;
assign in_add42 =  reg_add42;
assign in_add51 =  reg_add51;
assign in_add52 =  reg_add52;
assign in_add61 =  reg_add61;
assign in_add62 =  reg_add62;
assign in_add71 =  reg_add71;
assign in_add72 =  reg_add72;
assign in_add81 =  reg_add81;
assign in_add82 =  reg_add82;


// //==============================================================================================================
// // KQstate
// //==============================================================================================================
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_kq <= 0;
	end
    else if (current_state== IDLE) begin
        counter_kq <= 0;
    end
	else if (current_state== KQstate) begin
        if (counter_kq < 3) begin
            counter_kq <= counter_kq + 1;
        end
        else begin
            counter_kq <= 0;
        end
    end
end
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_instr <= 0;
	end
    else if (current_state== IDLE) begin
        counter_instr <= 0;
    end
    else if (current_state== KQstate) begin
        if ( counter_kq == 3 && counter_instr < 4) begin
            counter_instr <= counter_instr + 1;
        end
    end
end
// //=======================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        k_5x4[4][3] <= 0;
    end
    else if (current_state == KQstate) begin
        k_5x4[4][3] <= out_add3;
    end
    else if (current_state == SCORE && (counter_score<'d25) ) begin
        k_5x4[4][3] <= k_5x4[0][3];
    end
end
generate
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    k_5x4[i][j] <= 0;
                end
                else if (current_state == KQstate) begin
                    k_5x4[i][j] <= k_5x4[i][j+1];
                end
                else if (current_state == SCORE && (counter_score<'d25)) begin
                    k_5x4[i][j] <= k_5x4[i+1][j];
                end
            end
        end
    end
endgenerate
generate
    for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    k_5x4[4][j] <= 0;
                end
                else if (current_state == KQstate) begin
                    k_5x4[4][j] <= k_5x4[4][j+1];
                end
                else if (current_state == SCORE && (counter_score<'d25)) begin
                    k_5x4[4][j] <= k_5x4[0][j];
                end
         end 
    end
endgenerate
generate
    for (i = 0; i < 4; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    k_5x4[i][3] <= 0;
                end
                else if (current_state == KQstate) begin
                    k_5x4[i][3] <= k_5x4[i+1][0];
                end
                else if (current_state == SCORE && (counter_score<'d25)) begin
                    k_5x4[i][3] <= k_5x4[i+1][3];
                end
         end 
    end
endgenerate
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        q_5x4[4][3] <= 0;
    end
    else if (current_state == KQstate) begin
        q_5x4[4][3] <= out_add6;
    end
    else if (current_state == SCORE && ((counter_score == 'd4) || (counter_score == 'd9) || (counter_score == 'd14) || (counter_score == 'd19) || (counter_score == 'd24)) && (counter_score<'d25)) begin
        q_5x4[4][3] <= q_5x4[0][3];
    end
end
generate
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    q_5x4[i][j] <= 0;
                end
                else if (current_state == KQstate) begin
                    q_5x4[i][j] <= q_5x4[i][j+1];
                end
                else if (current_state == SCORE && ((counter_score == 'd4) || (counter_score == 'd9) || (counter_score == 'd14) || (counter_score == 'd19) || (counter_score == 'd24)) && (counter_score<'d25)) begin
                    q_5x4[i][j] <= q_5x4[i+1][j];
                end
            end
        end
    end
endgenerate
generate
    for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    q_5x4[4][j] <= 0;
                end
                else if (current_state == KQstate) begin
                    q_5x4[4][j] <= q_5x4[4][j+1];
                end
                else if (current_state == SCORE && ((counter_score == 'd4) || (counter_score == 'd9) || (counter_score == 'd14) || (counter_score == 'd19) || (counter_score == 'd24)) && (counter_score<'d25)) begin
                    q_5x4[4][j] <= q_5x4[0][j];
                end
         end 
    end
endgenerate
generate
    for (i = 0; i < 4; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    q_5x4[i][3] <= 0;
                end
                else if (current_state == KQstate) begin
                    q_5x4[i][3] <= q_5x4[i+1][0];
                end
                else if (current_state == SCORE && ((counter_score == 'd4) || (counter_score == 'd9) || (counter_score == 'd14) || (counter_score == 'd19) || (counter_score == 'd24)) && (counter_score<'d25)) begin
                    q_5x4[i][3] <= q_5x4[i+1][3];
                end
         end 
    end
endgenerate    
// //==============================================================================================================
// // SCORE
// //==============================================================================================================
always @(*) begin
    if (current_state == SCORE) begin
        reg_div21 = numerator_2;
    end
    else begin
        reg_div21 = 0;
    end
end
always @(*) begin
    if (current_state == SCORE) begin
        reg_div22 = denominator_2;
    end
    else begin
        reg_div22 = 0;
    end
end

assign in_div21 = reg_div21;
assign in_div22 = reg_div22;
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		score1_reg <= 0;
	end
	else if (current_state == SCORE) begin
		score1_reg <= out_add1;
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		score2_reg <= 0;
	end
	else if (current_state == SCORE) begin
		score2_reg <= out_add2;
	end
end
always @ (*) begin
    if (current_state == SCORE) begin
        reg_exp1= score1_reg;
    end
    else begin
        reg_exp1 = 0;
    end
end
always @ (*) begin
    if (current_state == SCORE) begin
        reg_exp2= score2_reg;
    end
    else begin
        reg_exp2 = 0;
    end
end
assign in_exp1 = reg_exp1;
assign in_exp2 = reg_exp2;

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		exp_plus_reg_1 <= 0;
	end
    else if (counter_score == 0) begin
		exp_plus_reg_1 <= 0;
	end
	else if (current_state == SCORE) begin
		// exp_plus_reg_1 <= out_add4;
        exp_plus_reg_1 <= out_add10;
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		exp_plus_reg <= 0;
	end
    else if (counter_score == 0) begin
		exp_plus_reg <= 0;
	end
	else if (current_state == SCORE) begin
		// exp_plus_reg <= out_add3;
        exp_plus_reg <= out_add9;
	end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        queue_1[4] <= 0;
    end
    else if (counter_score == 0) begin
		queue_1[4] <= 0;
	end
    else if (current_state == SCORE) begin
        queue_1[4] <= out_exp1;
    end
end
generate
    for (i = 0; i < 4; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                queue_1[i] <= 0;
            end
            else if (current_state == SCORE) begin
                queue_1[i] <= queue_1[i+1];
            end
         end 
    end
endgenerate 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        queue_2[4] <= 0;
    end
    else if (counter_score == 0) begin
		queue_2[4] <= 0;
	end
    else if (current_state == SCORE) begin
        queue_2[4] <= out_exp2;
    end
end
generate
    for (i = 0; i < 4; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                queue_2[i] <= 0;
            end
            else if (current_state == SCORE) begin
                queue_2[i] <= queue_2[i+1];
            end
         end 
    end
endgenerate  
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		denominator_1 <= 0;
	end
    else if (current_state == IDLE) begin
		denominator_1 <= 0;
	end
	else if (current_state == SCORE && ((counter_score == 'd6) || (counter_score == 'd11) || (counter_score == 'd16) || (counter_score == 'd21) || (counter_score == 'd26))) begin
		denominator_1 <= exp_plus_reg;
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		numerator_1 <= 0;
	end
    else if (current_state == IDLE) begin
		numerator_1 <= 0;
	end
	else if (current_state == SCORE) begin
		numerator_1 <= queue_1[0];
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		denominator_2 <= 0;
	end
    else if (current_state == IDLE) begin
		denominator_2 <= 0;
	end
	else if (current_state == SCORE && ((counter_score == 'd6) || (counter_score == 'd11) || (counter_score == 'd16) || (counter_score == 'd21) || (counter_score == 'd26))) begin
		denominator_2 <= exp_plus_reg_1;
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		numerator_2 <= 0;
	end
    else if (current_state == IDLE) begin
		numerator_2 <= 0;
	end
	else if (current_state == SCORE) begin
		numerator_2 <= queue_2[0];
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_score <= 0;
	end
    else if (current_state== IDLE) begin
        counter_score <= 0;
    end
	else if (current_state == SCORE) begin
		counter_score <= counter_score + 1;
	end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        score1_softmax[4][4] <= 0;
    end
    else if (current_state == SCORE) begin
        score1_softmax[4][4] <= out_div1;
    end
    else if (current_state == HEAD && ((counter_head == 'd2) || (counter_head == 'd4) || (counter_head == 'd6) || (counter_head == 'd8) || (counter_head == 'd10)) && (counter_head<'d11) ) begin
        score1_softmax[4][4] <= score1_softmax[0][4];
    end
end
generate
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    score1_softmax[i][j] <= 0;
                end
                else if (current_state == SCORE ) begin
                    score1_softmax[i][j] <= score1_softmax[i][j+1];
                end
                else if (current_state == HEAD && ((counter_head == 'd2) || (counter_head == 'd4) || (counter_head == 'd6) || (counter_head == 'd8) || (counter_head == 'd10)) && (counter_head<'d11) ) begin
                    score1_softmax[i][j] <= score1_softmax[i+1][j];
                end
            end
        end
    end
endgenerate
generate
    for (j = 0; j < 4; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    score1_softmax[4][j] <= 0;
                end
                else if (current_state == SCORE) begin
                    score1_softmax[4][j] <= score1_softmax[4][j+1];
                end
                else if (current_state == HEAD && ((counter_head == 'd2) || (counter_head == 'd4) || (counter_head == 'd6) || (counter_head == 'd8) || (counter_head == 'd10)) && (counter_head<'d11)) begin
                    score1_softmax[4][j] <= score1_softmax[0][j];
                end
         end 
    end
endgenerate
generate
    for (i = 0; i < 4; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    score1_softmax[i][4] <= 0;
                end
                else if (current_state == SCORE) begin
                    score1_softmax[i][4] <= score1_softmax[i+1][0];
                end
                else if (current_state == HEAD && ((counter_head == 'd2) || (counter_head == 'd4) || (counter_head == 'd6) || (counter_head == 'd8) || (counter_head == 'd10)) && (counter_head<'d11)) begin
                    score1_softmax[i][4] <= score1_softmax[i+1][4];
                end
         end 
    end
endgenerate  

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        score2_softmax[4][4] <= 0;
    end
    else if (current_state == SCORE ) begin
        score2_softmax[4][4] <= out_div2;
    end
    else if (current_state == HEAD && ((counter_head == 'd2) || (counter_head == 'd4) || (counter_head == 'd6) || (counter_head == 'd8) || (counter_head == 'd10)) && (counter_head<'d11) ) begin
        score2_softmax[4][4] <= score2_softmax[0][4];
    end
end
generate
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    score2_softmax[i][j] <= 0;
                end
                else if (current_state == SCORE) begin
                    score2_softmax[i][j] <= score2_softmax[i][j+1];
                end
                else if (current_state == HEAD && ((counter_head == 'd2) || (counter_head == 'd4) || (counter_head == 'd6) || (counter_head == 'd8) || (counter_head == 'd10)) && (counter_head<'d11) ) begin
                    score2_softmax[i][j] <= score2_softmax[i+1][j];
                end
            end
        end
    end
endgenerate
generate
    for (j = 0; j < 4; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    score2_softmax[4][j] <= 0;
                end
                else if (current_state == SCORE) begin
                    score2_softmax[4][j] <= score2_softmax[4][j+1];
                end
                else if (current_state == HEAD && ((counter_head == 'd2) || (counter_head == 'd4) || (counter_head == 'd6) || (counter_head == 'd8) || (counter_head == 'd10)) && (counter_head<'d11)) begin
                    score2_softmax[4][j] <= score2_softmax[0][j];
                end
         end 
    end
endgenerate
generate
    for (i = 0; i < 4; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    score2_softmax[i][4] <= 0;
                end
                else if (current_state == SCORE) begin
                    score2_softmax[i][4] <= score2_softmax[i+1][0];
                end
                else if (current_state == HEAD && ((counter_head == 'd2) || (counter_head == 'd4) || (counter_head == 'd6) || (counter_head == 'd8) || (counter_head == 'd10)) && (counter_head<'d11)) begin
                    score2_softmax[i][4] <= score2_softmax[i+1][4];
                end
         end 
    end
endgenerate  

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        v_5x4[4][3] <= 0;
    end
    else if (current_state == SCORE && (counter_score<'d20)) begin
        v_5x4[4][3] <= out_add7;
    end
end
generate
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    v_5x4[i][j] <= 0;
                end
                else if (current_state == SCORE && (counter_score<'d20)) begin
                    v_5x4[i][j] <= v_5x4[i][j+1];
                end
            end
        end
    end
endgenerate
generate
    for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    v_5x4[4][j] <= 0;
                end
                else if (current_state == SCORE && (counter_score<'d20)) begin
                    v_5x4[4][j] <= v_5x4[4][j+1];
                end
         end 
    end
endgenerate
generate
    for (i = 0; i < 4; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    v_5x4[i][3] <= 0;
                end
                else if (current_state == SCORE && (counter_score<'d20)) begin
                    v_5x4[i][3] <= v_5x4[i+1][0];
                end
         end 
    end
endgenerate
// //==============================================================================================================
// // HEAD
// //==============================================================================================================
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_head <= 0;
	end
    else if (current_state== IDLE) begin
        counter_head <= 0;
    end
	else if (current_state== HEAD) begin
        counter_head <= counter_head + 1;
    end
end
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_v <= 0;
	end
    else if (current_state== IDLE) begin
        counter_v <= 0;
    end
	else if (current_state== HEAD) begin
        if (counter_v < 1) begin
            counter_v <= counter_v + 1;
        end
        else begin
            counter_v <= 0;
        end
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		for (k = 0; k < 5; k = k + 1) begin
            V1[k] <= 0;
        end
	end
    else if (current_state == HEAD) begin
        V1[0] <= v_5x4[0][counter_v];
        V1[1] <= v_5x4[1][counter_v];
        V1[2] <= v_5x4[2][counter_v];
        V1[3] <= v_5x4[3][counter_v];
        V1[4] <= v_5x4[4][counter_v];
    end 
    else begin
        for (k = 0; k < 5; k = k + 1) begin
            V1[k] <= 0;
        end
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		for (k = 0; k < 5; k = k + 1) begin
            V2[k] <= 0;
        end
	end
    else if (current_state == HEAD) begin
        V2[0] <= v_5x4[0][counter_v+2];
        V2[1] <= v_5x4[1][counter_v+2];
        V2[2] <= v_5x4[2][counter_v+2];
        V2[3] <= v_5x4[3][counter_v+2];
        V2[4] <= v_5x4[4][counter_v+2];
    end 
    else begin
        for (k = 0; k < 5; k = k + 1) begin
            V2[k] <= 0;
        end
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (l =0 ; l < 4; l = l + 1) begin
                head_out[k][l] <= 0;
            end
        end
    end
    else if (current_state == HEAD ) begin
        head_out[0][0] <= head_out[0][1];
        head_out[0][1] <= head_out[1][0];
        head_out[1][0] <= head_out[1][1];
        head_out[1][1] <= head_out[2][0];
        head_out[2][0] <= head_out[2][1];
        head_out[2][1] <= head_out[3][0];
        head_out[3][0] <= head_out[3][1];
        head_out[3][1] <= head_out[4][0];
        head_out[4][0] <= head_out[4][1];
        head_out[4][1] <= out_add4;

        head_out[0][2] <= head_out[0][3];
        head_out[0][3] <= head_out[1][2];
        head_out[1][2] <= head_out[1][3];
        head_out[1][3] <= head_out[2][2];
        head_out[2][2] <= head_out[2][3];
        head_out[2][3] <= head_out[3][2];
        head_out[3][2] <= head_out[3][3];
        head_out[3][3] <= head_out[4][2];
        head_out[4][2] <= head_out[4][3];
        head_out[4][3] <= out_add8;
    end
    else if (current_state == OUTPUT && ((counter_out == 'd3) || (counter_out == 'd7) || (counter_out == 'd11)|| (counter_out == 'd15) || (counter_out == 'd19) && (counter_out<'d20)) ) begin
        head_out[0][0] <= head_out[1][0];
        head_out[0][1] <= head_out[1][1];
        head_out[0][2] <= head_out[1][2];
        head_out[0][3] <= head_out[1][3];
        head_out[1][0] <= head_out[2][0];
        head_out[1][1] <= head_out[2][1];
        head_out[1][2] <= head_out[2][2];
        head_out[1][3] <= head_out[2][3];
        head_out[2][0] <= head_out[3][0];
        head_out[2][1] <= head_out[3][1];
        head_out[2][2] <= head_out[3][2];
        head_out[2][3] <= head_out[3][3];
        head_out[3][0] <= head_out[4][0];
        head_out[3][1] <= head_out[4][1];
        head_out[3][2] <= head_out[4][2];
        head_out[3][3] <= head_out[4][3];
        head_out[4][0] <= head_out[0][0];
        head_out[4][1] <= head_out[0][1];
        head_out[4][2] <= head_out[0][2];
        head_out[4][3] <= head_out[0][3];
    end
end

// //==============================================================================================================
// // OUTPUT
// //==============================================================================================================
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_out <= 0;
	end
    else if (current_state== IDLE) begin
        counter_out <= 0;
    end
	else if (current_state== OUTPUT) begin
        counter_out <= counter_out + 1;
    end
end






// //==============================================================================================================
// // initial
// //==============================================================================================================
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter <= 0;
	end
    else if (current_state== IDLE) begin
        counter <= 0;
    end
	else if (in_valid && counter <16) begin
		counter <= counter + 1;
	end
end
//k_weight_transpose
always @(*) begin
    if (current_state == INPUT) begin
        reg_div11 = k_weight_source;
    end
    else if (current_state == SCORE) begin
        reg_div11 = numerator_1;
    end
    else begin
        reg_div11 = 0;
    end
end
always @(*) begin
    if (current_state == INPUT) begin
        reg_div12 = sqare_root_2;
    end
    else if (current_state == SCORE) begin
        reg_div12 = denominator_1;
    end
    else begin
        reg_div12 = 0;
    end
end

assign in_div11 = reg_div11;
assign in_div12 = reg_div12;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        k_weight_source <= 0;
    end
    else if (in_valid && counter <15) begin
        k_weight_source <= k_weight;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        k_weight_reg[3][3] <= 0;
    end
    else if (in_valid && counter <16) begin
        k_weight_reg[3][3] <= out_div1;
    end
    else if (current_state == KQstate) begin
        k_weight_reg[3][3] <= k_weight_reg[0][3];
    end
end
generate
    for (i = 0; i < 3; i = i + 1) begin
        for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    k_weight_reg[i][j] <= 0;
                end
                else if (in_valid && counter <16) begin
                    k_weight_reg[i][j] <= k_weight_reg[i][j+1];
                end
                else if (current_state == KQstate) begin
                    // if(i==3) begin
                    //     k_weight_reg[i][j] <= k_weight_reg[0][j];
                    // end
                    // else begin
                        k_weight_reg[i][j] <= k_weight_reg[i+1][j];
                    // end
                end
            end
        end
    end
endgenerate
generate
    for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    k_weight_reg[3][j] <= 0;
                end
                else if (in_valid && counter <16) begin
                    k_weight_reg[3][j] <= k_weight_reg[3][j+1];
                end
                else if (current_state == KQstate) begin
                    k_weight_reg[3][j] <= k_weight_reg[0][j];
                end
         end 
    end
endgenerate  
generate
    for (i = 0; i < 3; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    k_weight_reg[i][3] <= 0;
                end
                else if (in_valid && counter <16) begin
                    k_weight_reg[i][3] <= k_weight_reg[i+1][0];
                end
                else if (current_state == KQstate) begin
                    k_weight_reg[i][3] <= k_weight_reg[i+1][3];
                end
         end 
    end
endgenerate  
//in_str
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_str_reg[4][3] <= 0;
    end
    else if (in_valid) begin
        in_str_reg[4][3] <= in_str;
    end
    else if (current_state == KQstate && counter_kq ==3) begin
        in_str_reg[4][3] <= in_str_reg [0][3];
    end
    else if (current_state == SCORE && ((counter_score == 'd3) || (counter_score == 'd7) || (counter_score == 'd11) || (counter_score == 'd15) && (counter_score<'d20))) begin
        in_str_reg[4][3] <= in_str_reg [0][3];
    end
end
generate
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    in_str_reg[i][j] <= 0;
                end
                else if (in_valid) begin
                    in_str_reg[i][j] <= in_str_reg[i][j+1];
                end
                else if (current_state == KQstate && counter_kq ==3) begin
                    in_str_reg[i][j] <= in_str_reg[i+1][j];
                end
                else if (current_state == SCORE && ((counter_score == 'd3) || (counter_score == 'd7) || (counter_score == 'd11) || (counter_score == 'd15)  && (counter_score<'d20))) begin
                    in_str_reg[i][j] <= in_str_reg[i+1][j];
                end
            end
        end
    end
endgenerate
generate
    for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    in_str_reg[4][j] <= 0;
                end
                else if (in_valid) begin
                    in_str_reg[4][j] <= in_str_reg[4][j+1];
                end
                else if (current_state == KQstate && counter_kq ==3) begin
                    in_str_reg[4][j] <= in_str_reg[0][j];
                end
                else if (current_state == SCORE && ((counter_score == 'd3) || (counter_score == 'd7) || (counter_score == 'd11) || (counter_score == 'd15)  && (counter_score<'d20))) begin
                    in_str_reg[4][j] <= in_str_reg[0][j];
                end
         end 
    end
endgenerate
generate
    for (i = 0; i < 4; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    in_str_reg[i][3] <= 0;
                end
                else if (in_valid) begin
                    in_str_reg[i][3] <= in_str_reg[i+1][0];
                end
                else if (current_state == KQstate && counter_kq ==3) begin
                    in_str_reg[i][3] <= in_str_reg[i+1][3];
                end
                else if (current_state == SCORE && ((counter_score == 'd3) || (counter_score == 'd7) || (counter_score == 'd11) || (counter_score == 'd15) && (counter_score<'d20))) begin
                    in_str_reg[i][3] <= in_str_reg[i+1][3];
                end
         end 
    end
endgenerate  
//q_weight_transpose
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        q_weight_reg[3][3] <= 0;
    end
    else if (in_valid && counter <15) begin
        q_weight_reg[3][3] <= q_weight;
    end
    else if (current_state == KQstate) begin
        q_weight_reg[3][3] <= q_weight_reg[0][3];
    end
end
generate
    for (i = 0; i < 3; i = i + 1) begin
        for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    q_weight_reg[i][j] <= 0;
                end
                else if (in_valid && counter <15) begin
                    q_weight_reg[i][j] <= q_weight_reg[i][j+1];
                end
                else if (current_state == KQstate) begin
                    // if(i==3) begin
                    //     q_weight_reg[i][j] <= q_weight_reg[0][j];
                    // end
                    // else begin
                        q_weight_reg[i][j] <= q_weight_reg[i+1][j];
                    // end
                end

            end
        end
    end
endgenerate
generate
    for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    q_weight_reg[3][j] <= 0;
                end
                else if (in_valid && counter <15) begin
                    q_weight_reg[3][j] <= q_weight_reg[3][j+1];
                end
                else if (current_state == KQstate) begin
                    q_weight_reg[3][j] <= q_weight_reg[0][j];
                end
         end 
    end
endgenerate  
generate
    for (i = 0; i < 3; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    q_weight_reg[i][3] <= 0;
                end
                else if (in_valid && counter <15) begin
                    q_weight_reg[i][3] <= q_weight_reg[i+1][0];
                end
                else if (current_state == KQstate) begin
                    q_weight_reg[i][3] <= q_weight_reg[i+1][3];
                end
         end 
    end
endgenerate  
//v_weight_transpose
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        v_weight_reg[3][3] <= 0;
    end
    else if (in_valid && counter <15) begin
        v_weight_reg[3][3] <= v_weight;
    end
    else if (current_state == SCORE) begin
        v_weight_reg[3][3] <= v_weight_reg[0][3];
    end
end
generate
    for (i = 0; i < 3; i = i + 1) begin
        for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    v_weight_reg[i][j] <= 0;
                end
                else if (in_valid && counter <15) begin
                    v_weight_reg[i][j] <= v_weight_reg[i][j+1];
                end
                else if (current_state == SCORE) begin
                    v_weight_reg[i][j] <= v_weight_reg[i+1][j];
                end
            end
        end
    end
endgenerate
generate
    for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    v_weight_reg[3][j] <= 0;
                end
                else if (in_valid && counter <15) begin
                    v_weight_reg[3][j] <= v_weight_reg[3][j+1];
                end
                else if (current_state == SCORE) begin
                    v_weight_reg[3][j] <= v_weight_reg[0][j];
                end
         end 
    end
endgenerate  
generate
    for (i = 0; i < 3; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    v_weight_reg[i][3] <= 0;
                end
                else if (in_valid && counter <15) begin
                    v_weight_reg[i][3] <= v_weight_reg[i+1][0];
                end
                else if (current_state == SCORE) begin
                    v_weight_reg[i][3] <= v_weight_reg[i+1][3];
                end
         end 
    end
endgenerate   

//out_weight_transpose
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_weight_reg[3][3] <= 0;
    end
    else if (in_valid && counter <15) begin
        out_weight_reg[3][3] <= out_weight;
    end
    else if (current_state == OUTPUT) begin
        out_weight_reg[3][3] <= out_weight_reg[0][3];
    end
end
generate
    for (i = 0; i < 3; i = i + 1) begin
        for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    out_weight_reg[i][j] <= 0;
                end
                else if (in_valid && counter <15) begin
                    out_weight_reg[i][j] <= out_weight_reg[i][j+1];
                end
                else if (current_state == OUTPUT) begin
                    out_weight_reg[i][j] <= out_weight_reg[i+1][j];
                end
            end
        end
    end 
endgenerate
generate
    for (j = 0; j < 3; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    out_weight_reg[3][j] <= 0;
                end
                else if (in_valid && counter <15) begin
                    out_weight_reg[3][j] <= out_weight_reg[3][j+1];
                end
                else if (current_state == OUTPUT) begin
                    out_weight_reg[3][j] <= out_weight_reg[0][j];
                end
         end 
    end
endgenerate  
generate
    for (i = 0; i < 3; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    out_weight_reg[i][3] <= 0;
                end
                else if (in_valid && counter <15) begin
                    out_weight_reg[i][3] <= out_weight_reg[i+1][0];
                end
                else if (current_state == OUTPUT) begin
                    out_weight_reg[i][3] <= out_weight_reg[i+1][3];
                end
         end 
    end
endgenerate 












always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else if (current_state == OUTPUT) begin
        out_valid <= 1;
    end
    else begin
        out_valid <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out <= 0;
    end
    else if (current_state == OUTPUT) begin
        out <= out_add3;
    end
    else begin
        out <= 0;
    end
end


endmodule


// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         score1[4][4] <= 0;
//     end
//     else if (current_state == SCORE && (counter_score<'d25)) begin
//         score1[4][4] <= out_add1;
//     end
//     // else if (current_state == SCORE) begin
//     //     score1[4][3] <= score1[0][3];
//     // end
// end
// generate
//     for (i = 0; i < 4; i = i + 1) begin
//         for (j = 0; j < 4; j = j + 1) begin
//             always @(posedge clk or negedge rst_n) begin
//                 if(!rst_n) begin
//                     score1[i][j] <= 0;
//                 end
//                 else if (current_state == SCORE && (counter_score<'d25)) begin
//                     score1[i][j] <= score1[i][j+1];
//                 end
//                 // else if (current_state == SCORE) begin
//                 //     score1[i][j] <= score1[i+1][j];
//                 // end
//             end
//         end
//     end
// endgenerate
// generate
//     for (j = 0; j < 4; j = j + 1) begin
//             always @(posedge clk or negedge rst_n) begin
//                 if(!rst_n) begin
//                     score1[4][j] <= 0;
//                 end
//                 else if (current_state == SCORE && (counter_score<'d25)) begin
//                     score1[4][j] <= score1[4][j+1];
//                 end
//                 // else if (current_state == SCORE) begin
//                 //     score1[4][j] <= score1[0][j];
//                 // end
//          end 
//     end
// endgenerate
// generate
//     for (i = 0; i < 4; i = i + 1) begin
//             always @(posedge clk or negedge rst_n) begin
//                 if(!rst_n) begin
//                     score1[i][4] <= 0;
//                 end
//                 else if (current_state == SCORE && (counter_score<'d25)) begin
//                     score1[i][4] <= score1[i+1][0];
//                 end
//                 // else if (current_state == SCORE) begin
//                 //     score1[i][3] <= score1[i+1][3];
//                 // end
//          end 
//     end
// endgenerate  

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         score2[4][4] <= 0;
//     end
//     else if (current_state == SCORE) begin
//         score2[4][4] <= out_add2;
//     end
//     // else if (current_state == SCORE) begin
//     //     score2[4][3] <= score2[0][3];
//     // end
// end
// generate
//     for (i = 0; i < 4; i = i + 1) begin
//         for (j = 0; j < 4; j = j + 1) begin
//             always @(posedge clk or negedge rst_n) begin
//                 if(!rst_n) begin
//                     score2[i][j] <= 0;
//                 end
//                 else if (current_state == SCORE && (counter_score<'d25)) begin
//                     score2[i][j] <= score2[i][j+1];
//                 end
//                 // else if (current_state == SCORE) begin
//                 //     score2[i][j] <= score2[i+1][j];
//                 // end
//             end
//         end
//     end
// endgenerate
// generate
//     for (j = 0; j < 4; j = j + 1) begin
//             always @(posedge clk or negedge rst_n) begin
//                 if(!rst_n) begin
//                     score2[4][j] <= 0;
//                 end
//                 else if (current_state == SCORE && (counter_score<'d25)) begin
//                     score2[4][j] <= score2[4][j+1];
//                 end
//                 // else if (current_state == SCORE) begin
//                 //     score2[4][j] <= score2[0][j];
//                 // end
//          end 
//     end
// endgenerate
// generate
//     for (i = 0; i < 4; i = i + 1) begin
//             always @(posedge clk or negedge rst_n) begin
//                 if(!rst_n) begin
//                     score2[i][4] <= 0;
//                 end
//                 else if (current_state == SCORE && (counter_score<'d25)) begin
//                     score2[i][4] <= score2[i+1][0];
//                 end
//                 // else if (current_state == SCORE) begin
//                 //     score2[i][3] <= score2[i+1][3];
//                 // end
//          end 
//     end
// endgenerate  