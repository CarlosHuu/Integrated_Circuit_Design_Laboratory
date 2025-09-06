module MVDM(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    in_data,
    // output signals
    out_valid,
    out_sad
    );

input clk;
input rst_n;
input in_valid;
input in_valid2;
input [11:0] in_data;

output reg out_valid;
output reg out_sad;

//=======================================================
//                   Reg/Wire
//=======================================================
integer i,l;
genvar j,k;
wire [7:0] DOUT_L1;
wire [7:0] DOUT_L0;
reg [7:0] L0_D1, L0_D2;
reg [7:0] L1_D1, L1_D2;
reg [11:0] A_L0 [10];
reg [11:0] A_L0_reg;
reg [11:0] A_L1 [10];
reg [11:0] A_L1_reg;
reg [13:0] address_L1;
reg [13:0] address_L0;
reg [15:0] BI_L0[10][10];
reg [15:0] BI_L1[10][10];
reg [15:0] abs_v1 [64];
reg [15:0] BI_L0_reg [8][8];
reg [15:0] BI_L1_reg [8][8];
reg [1:0] bias_L0_x, bias_L1_x, bias_L0_y, bias_L1_y;
reg [23:0] SAD_reg, SAD_new;
reg [23:0] add_l1_1, add_l1_2, add_l1_3, add_l1_4, add_l1_5, add_l1_6, add_l1_7, add_l1_8, add_l1_9, add_l1_10, add_l1_11, add_l1_12, add_l1_13, add_l1_14, add_l1_15, add_l1_16;
reg [23:0] add_l2_1, add_l2_2, add_l2_3, add_l2_4;
reg [15:0] BI_L0_comb;
reg [15:0] BI_L1_comb;
reg [13:0] address_L1_next;
reg [13:0] address_L0_next;
reg [14:0] counter;
reg [8:0] counter_bi;
reg [10:0] counter_enter;
reg [10:0] counter_output;
reg [10:0] counter_a;
reg [23:0] point1_sad;
reg [3:0] point1_search;
reg [23:0] point2_sad;
reg [3:0] point2_search;
reg WEB_L0;
reg WEB_L1;
reg [4:0]search_order;
reg [4:0]search_point;
reg [11:0] in_data_reg;

reg [11:0] DIN;
parameter	IDLE 	= 3'd0,
		    INPUT_data  = 3'd1,
            INPUT_mv = 3'd2,
            CAL_bi = 3'd3,
            SAD = 3'd4,
            OUTPUT = 3'd5;

reg [7:0] first_row [11];
reg [11:0] mv_reg [8];
reg [7:0] mvx_L0_1;
reg [7:0] mvy_L0_1;
reg [7:0] mvx_L1_1;
reg [7:0] mvy_L1_1;
reg [7:0] mvx_L0_2;
reg [7:0] mvy_L0_2;
reg [7:0] mvx_L1_2;
reg [7:0] mvy_L1_2;

reg [3:0] f_mvx_L0_1;
reg [3:0] f_mvy_L0_1;
reg [3:0] f_mvx_L1_1;
reg [3:0] f_mvy_L1_1;
reg [3:0] f_mvx_L0_2;
reg [3:0] f_mvy_L0_2;
reg [3:0] f_mvx_L1_2;
reg [3:0] f_mvy_L1_2;
reg [55:0] output_concate;
reg point1_complete;

// reg [] 

reg [2:0] current_state, next_state;
//=======================================================
//                   Design
//=======================================================

SUMA180_16384X8X1BM8 L0(.A0(address_L0[0]), .A1(address_L0[1]), .A2(address_L0[2]), .A3(address_L0[3]), .A4(address_L0[4]), .A5(address_L0[5]),
                        .A6(address_L0[6]), .A7(address_L0[7]), .A8(address_L0[8]), .A9(address_L0[9]), .A10(address_L0[10]), .A11(address_L0[11]),
                        .A12(address_L0[12]), .A13(address_L0[13]),
                        .DO0(DOUT_L0   [0 ]), .DO1(DOUT_L0   [1 ]), .DO2(DOUT_L0[2]), .DO3(DOUT_L0[3]), .DO4(DOUT_L0[4]), .DO5(DOUT_L0[5]),
                        .DO6(DOUT_L0   [6 ]), .DO7(DOUT_L0   [7 ]),
                        .DI0(DIN       [0 ]), .DI1(DIN       [1 ]), .DI2(DIN[2]), .DI3(DIN[3]), .DI4(DIN[4]), .DI5(DIN[5]),
                        .DI6(DIN       [6 ]), .DI7(DIN       [7 ]),
                        .CK (clk           ), .WEB(WEB_L0        ), .OE(1'b1), .CS(1'b1)
                        );

SUMA180_16384X8X1BM8 L1(.A0(address_L1[0]), .A1(address_L1[1]), .A2(address_L1[2]), .A3(address_L1[3]), .A4(address_L1[4]), .A5(address_L1[5]),
                        .A6(address_L1[6]), .A7(address_L1[7]), .A8(address_L1[8]), .A9(address_L1[9]), .A10(address_L1[10]), .A11(address_L1[11]),
                        .A12(address_L1[12]), .A13(address_L1[13]),
                        .DO0(DOUT_L1   [0 ]), .DO1(DOUT_L1   [1 ]), .DO2(DOUT_L1[2]), .DO3(DOUT_L1[3]), .DO4(DOUT_L1[4]), .DO5(DOUT_L1[5]),
                        .DO6(DOUT_L1   [6 ]), .DO7(DOUT_L1   [7 ]),
                        .DI0(DIN       [0 ]), .DI1(DIN       [1 ]), .DI2(DIN[2]), .DI3(DIN[3]), .DI4(DIN[4]), .DI5(DIN[5]),
                        .DI6(DIN       [6 ]), .DI7(DIN       [7 ]),
                        .CK (clk           ), .WEB(WEB_L1        ), .OE(1'b1), .CS(1'b1)
                        );



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
                next_state = INPUT_data;
            else if (in_valid2)
                next_state = INPUT_mv;
            else
                next_state = IDLE;
        end
        INPUT_data: begin
            if (counter == 2*16384-1)
                next_state = IDLE;
            else
                next_state = INPUT_data;
        end
        INPUT_mv: begin
            if (!in_valid2)
                next_state = CAL_bi;
            else
                next_state = INPUT_mv;
        end
        CAL_bi: begin
            if (counter_a=='d124)
                next_state = SAD;
            else
                next_state = CAL_bi;
        end
        SAD : begin
            if (search_order =='d14 && ~point1_complete)
                next_state = CAL_bi;
            else if (search_order =='d14 && point1_complete)
                next_state = OUTPUT;
            else
                next_state = SAD;
        end
        OUTPUT : begin
            if (counter_output == 'd55)
            next_state = IDLE;
            else
            next_state = OUTPUT;
        end



        default: next_state = IDLE;
    endcase 
end
//=======================================================
//                
//=======================================================
always @(*) begin
    case (current_state)
        INPUT_data: begin
            WEB_L0 = counter[14];
            WEB_L1 = ~(counter[14]);
        end
        CAL_bi: begin
            WEB_L0 = 1'b1;
            WEB_L1 = 1'b1;
        end
        default: begin
            WEB_L0 = 1'b1;
            WEB_L1 = 1'b1;
        end
    endcase
end

always @(*) begin
    case (current_state)
        INPUT_data: begin
            address_L0[13:0] = counter[13:0];
        end
        CAL_bi: begin
            // address_L0 = (mvy_L0_1+counter_enter)*128 + mvx_L0_1 +counter_bi;
            address_L0 = (point1_complete) ? (mvy_L0_2+counter_enter)*128 + mvx_L0_2 +counter_bi : (mvy_L0_1+counter_enter)*128 + mvx_L0_1 +counter_bi;
        end
        default: begin
            address_L0[13:0] = 0;
        end
    endcase
end


always @(*) begin
    case (current_state)
        INPUT_data: begin
            address_L1[13:0] = counter[13:0];
        end
        CAL_bi: begin
            // address_L1 = /*address_L0_next;*/(mvy_L1_1+counter_enter)*128 + mvx_L1_1 +counter_bi;
            address_L1 = (point1_complete) ? (mvy_L1_2+counter_enter)*128 + mvx_L1_2 +counter_bi : (mvy_L1_1+counter_enter)*128 + mvx_L1_1 +counter_bi;
        end
        default: begin
            address_L1[13:0] = 0;
        end
    endcase
end


//=======================================================
//                   
//=======================================================



always @(*) begin
    if (current_state == INPUT_data) begin
        DIN = in_data_reg[11:4];
    end
    else begin
        DIN = 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_data_reg <= 0;
    end else if (in_valid) begin 
        in_data_reg <= in_data;
    end else begin
        in_data_reg <= 0;
    end
end

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter <= 0;
	end
    else if (current_state== IDLE) begin
        counter <= 0;
    end
	else if (current_state== INPUT_data) begin
        counter <= counter + 1;
    end
end
//=======================================================
//                   input mv
//======================================================= 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mv_reg[7] <= 0;
    end else if (in_valid2) begin
        mv_reg[7] <= in_data;
    end
end
generate
    for (j = 0; j < 7; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    mv_reg[j] <= 0;
                end
                else if (in_valid2) begin
                    mv_reg[j] <= mv_reg[j+1];
                end
         end 
    end
endgenerate   

always @(*) begin
    mvx_L0_1 = mv_reg[0][11:4];
    mvy_L0_1 = mv_reg[1][11:4];
    mvx_L1_1 = mv_reg[2][11:4];
    mvy_L1_1 = mv_reg[3][11:4];
    mvx_L0_2 = mv_reg[4][11:4];
    mvy_L0_2 = mv_reg[5][11:4];
    mvx_L1_2 = mv_reg[6][11:4];
    mvy_L1_2 = mv_reg[7][11:4];
    f_mvx_L0_1 = mv_reg[0][3:0];
    f_mvy_L0_1 = mv_reg[1][3:0];
    f_mvx_L1_1 = mv_reg[2][3:0];
    f_mvy_L1_1 = mv_reg[3][3:0];
    f_mvx_L0_2 = mv_reg[4][3:0];
    f_mvy_L0_2 = mv_reg[5][3:0];
    f_mvx_L1_2 = mv_reg[6][3:0];
    f_mvy_L1_2 = mv_reg[7][3:0];
end

//=======================================================
//                   bi
//======================================================= 
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_a <= 0;
	end
    else if (current_state== IDLE) begin
        counter_a <= 0;
    end
	else if (current_state== CAL_bi) begin
        counter_a <= counter_a + 1;
    end
    else begin
        counter_a <= 0;
    end
end
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_bi <= 0;
	end
    else if (current_state== IDLE) begin
        counter_bi <= 0;
    end
	else if (current_state== CAL_bi) begin
        if (counter_bi < 10) begin
            counter_bi <= counter_bi + 1;
        end
        else begin
            counter_bi <= 0;
        end
    end
    else begin
        counter_bi <= 0;
    end
end
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_enter <= 0;
	end
    else if (current_state== IDLE) begin
        counter_enter <= 0;
    end
	else if (current_state== CAL_bi) begin
        if (counter_bi == 10) begin
            counter_enter <= counter_enter + 1;
        end
    end
    else begin
        counter_enter <= 0;
    end

end
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        L0_D1<=0;
        L0_D2 <=0;
        L1_D1 <=0;
        L1_D2<=0;
    end
    else if (current_state== CAL_bi) begin
        L0_D1 <= DOUT_L0;
        L0_D2 <= L0_D1;
        L1_D1 <= DOUT_L1;
        L1_D2 <= L1_D1;
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        A_L0_reg<=0;
        A_L1_reg<=0;
    end
    else if (current_state== CAL_bi && counter_a >=3 && counter_bi!=2) begin
        // A_L0_reg <= {L0_D2,4'd0} + f_mvx_L0_1*(L0_D1-L0_D2);
        A_L0_reg <= (point1_complete) ? {L0_D2,4'd0} + f_mvx_L0_2*(L0_D1-L0_D2) : {L0_D2,4'd0} + f_mvx_L0_1*(L0_D1-L0_D2);
        // A_L1_reg <= {L1_D2,4'd0} + f_mvx_L1_1*(L1_D1-L1_D2);
        A_L1_reg <= (point1_complete) ? {L1_D2,4'd0} + f_mvx_L1_2*(L1_D1-L1_D2) : {L1_D2,4'd0} + f_mvx_L1_1*(L1_D1-L1_D2);
    end
end
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        A_L0[9]<=0;
        A_L1[9]<=0;
    end
    else if (current_state== CAL_bi && counter_bi!=2) begin
        A_L0[9] <= A_L0_reg;
        A_L1[9] <= A_L1_reg;
    end
end

generate
    for (j = 0; j < 9; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    A_L0[j] <= 0;
                    A_L1[j] <= 0;
                end 
                else if (current_state== CAL_bi && counter_bi!=2) begin
                    A_L0[j] <= A_L0[j+1];
                    A_L1[j] <= A_L1[j+1];
                end
         end 
    end
endgenerate   

always @(*) begin
    // BI_L0_comb = {A_L0[0],4'd0} + f_mvy_L0_1*(A_L0_reg-A_L0[0]); 
    BI_L0_comb = (point1_complete) ? {A_L0[0],4'd0} + f_mvy_L0_2*(A_L0_reg-A_L0[0]) : {A_L0[0],4'd0} + f_mvy_L0_1*(A_L0_reg-A_L0[0]); 
    // BI_L1_comb = {A_L1[0],4'd0} + f_mvy_L1_1*(A_L1_reg-A_L1[0]); 
    BI_L1_comb = (point1_complete) ? {A_L1[0],4'd0} + f_mvy_L1_2*(A_L1_reg-A_L1[0]) : {A_L1[0],4'd0} + f_mvy_L1_1*(A_L1_reg-A_L1[0]); 
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        BI_L0[9][9]<=0;
        BI_L1[9][9]<=0;
    end
    else if (current_state== CAL_bi && counter_a>14 && counter_bi!=2 && counter_a<125) begin
        BI_L0[9][9] <= BI_L0_comb;
        BI_L1[9][9] <= BI_L1_comb;
    end
end

generate
    for (k = 0; k < 10; k = k + 1) begin
        for (j = 0; j < 9; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    BI_L0[k][j] <= 0;
                    BI_L1[k][j] <= 0;
                end
                else if (current_state== CAL_bi && counter_a>14 && counter_bi!=2 && counter_a<125) begin
                    BI_L0[k][j] <= BI_L0[k][j+1];
                    BI_L1[k][j] <= BI_L1[k][j+1];
                end
            end
        end
    end
endgenerate

generate
    for (k = 0; k < 9; k = k + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    BI_L0[k][9] <= 0;
                    BI_L1[k][9] <= 0;
                end
                else if (current_state== CAL_bi && counter_a>14 && counter_bi!=2 && counter_a<125) begin
                    BI_L0[k][9] <= BI_L0[k+1][0];
                    BI_L1[k][9] <= BI_L1[k+1][0];
                end
         end 
    end
endgenerate 

//=======================================================
//                   SAD
//======================================================= 
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 8 ;i++)begin
            for (l = 0; l < 8 ;l++)begin
                BI_L0_reg[i][l] <= 0;
            end
        end
        for (i = 0; i < 8 ;i++)begin
            for (l = 0; l < 8 ;l++)begin
                BI_L1_reg[i][l] <= 0;
            end
        end
    end
    else if (current_state== SAD) begin
        for (i = 0; i < 8 ;i++)begin
            for (l=0  ; l < 8 ;l++) begin
                BI_L0_reg[i][l] <= BI_L0[i+bias_L0_x][l+bias_L0_y];
            end
        end
        for (i = 0; i < 8 ;i++)begin
            for (l=0  ; l < 8 ;l++) begin
                BI_L1_reg[i][l] <= BI_L1[i+bias_L1_x][l+bias_L1_y];
            end
        end
    end
end
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 8 ;i++)begin
            for (l = 0; l < 8 ;l++)begin
                abs_v1[i*8 + l] <= 0;
            end
        end
    end
    else if (current_state== SAD) begin 
        for (i = 0; i < 8 ;i++)begin
            for (l=0  ; l < 8 ;l++) begin
                abs_v1[i*8 + l] <= ( (BI_L0_reg[i][l] > BI_L1_reg[i][l]) ) ? (BI_L0_reg[i][l] - BI_L1_reg[i][l]) :  (BI_L1_reg[i][l]- BI_L0_reg[i][l]);
            end
        end
    end 
end
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        add_l1_1 <= 0; add_l1_2 <= 0; add_l1_3 <= 0; add_l1_4 <= 0; add_l1_5 <= 0; add_l1_6 <= 0; add_l1_7 <= 0; add_l1_8 <= 0;
        add_l1_9 <= 0; add_l1_10 <= 0; add_l1_11 <= 0; add_l1_12 <= 0; add_l1_13 <= 0; add_l1_14 <= 0; add_l1_15 <= 0; add_l1_16 <= 0;
    end
    else if (current_state== SAD) begin
        add_l1_1 <= abs_v1[0] + abs_v1[1] + abs_v1[2] + abs_v1[3];
        add_l1_2 <= abs_v1[4] + abs_v1[5] + abs_v1[6] + abs_v1[7]; 
        add_l1_3 <= abs_v1[8] + abs_v1[9] + abs_v1[10] + abs_v1[11]; 
        add_l1_4 <= abs_v1[12] + abs_v1[13] + abs_v1[14] + abs_v1[15];  
        add_l1_5 <= abs_v1[16] + abs_v1[17] + abs_v1[18] + abs_v1[19];
        add_l1_6 <= abs_v1[20] + abs_v1[21] + abs_v1[22] + abs_v1[23];
        add_l1_7 <= abs_v1[24] + abs_v1[25] + abs_v1[26] + abs_v1[27];
        add_l1_8 <= abs_v1[28] + abs_v1[29] + abs_v1[30] + abs_v1[31];
        add_l1_9 <= abs_v1[32] + abs_v1[33] + abs_v1[34] + abs_v1[35];
        add_l1_10 <= abs_v1[36] + abs_v1[37] + abs_v1[38] + abs_v1[39];
        add_l1_11 <= abs_v1[40] + abs_v1[41] + abs_v1[42] + abs_v1[43];
        add_l1_12 <= abs_v1[44] + abs_v1[45] + abs_v1[46] + abs_v1[47];
        add_l1_13 <= abs_v1[48] + abs_v1[49] + abs_v1[50] + abs_v1[51];
        add_l1_14 <= abs_v1[52] + abs_v1[53] + abs_v1[54] + abs_v1[55];
        add_l1_15 <= abs_v1[56] + abs_v1[57] + abs_v1[58] + abs_v1[59];
        add_l1_16 <= abs_v1[60] + abs_v1[61] + abs_v1[62] + abs_v1[63]; 
    end
end
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        add_l2_1 <= 0; add_l2_2 <= 0; add_l2_3<= 0; add_l2_4 <= 0;
    end
    else if (current_state== SAD) begin
        add_l2_1 <= add_l1_1 + add_l1_2 + add_l1_3 + add_l1_4; 
        add_l2_2 <= add_l1_5 + add_l1_6 + add_l1_7 + add_l1_8; 
        add_l2_3 <= add_l1_9 + add_l1_10 + add_l1_11 + add_l1_12; 
        add_l2_4 <= add_l1_13 + add_l1_14 + add_l1_15 + add_l1_16; 
    end
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        SAD_new <= 0;
    end
    else if (current_state == SAD)begin
        SAD_new <= add_l2_1 + add_l2_2 + add_l2_3 + add_l2_4;
    end
end


always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        point1_complete<=0;
    end
    else if (current_state == IDLE) begin
        point1_complete<=0;
    end
    else if (current_state == SAD  && search_order ==14) begin
        point1_complete <=1;
    end
end


always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        SAD_reg <= 0; 
        search_point <=0;
    end
    else if (current_state == SAD  && search_order ==5) begin
        SAD_reg <= SAD_new ;
        search_point <=search_order;
    end
    else begin
        if   (SAD_new < SAD_reg) begin
            SAD_reg <= SAD_new ;
            search_point <= search_order;
        end
        else begin
            SAD_reg <= SAD_reg;
            search_point <= search_point;
        end

    end
end

always @ (posedge clk or negedge rst_n)begin
    if (!rst_n) begin
        point1_sad <=0;
        point1_search <=0;
    end
    else if (current_state == SAD /*&& search_order ==13*/ && (~point1_complete)) begin
        point1_sad <=SAD_reg;
        point1_search <=search_point-5;
    end
end

always @ (posedge clk or negedge rst_n)begin
    if (!rst_n) begin
        point2_sad <=0;
        point2_search <=0;
    end
    else if (current_state == SAD /*&& search_order ==13*/ && point1_complete) begin
        point2_sad <=SAD_reg;
        point2_search <=search_point-5;
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        search_order <= 0; 
    end
    else if (current_state == IDLE) begin
        search_order <= 0;
    end

    else if (current_state == SAD && search_order <14) begin
        search_order <= search_order +1;
    end
    else begin
        search_order <= 0;
    end
end


always @(*) begin
    case(search_order)
        'd0: begin
            bias_L0_x = 0;
            bias_L0_y = 0;
            bias_L1_x = 2;
            bias_L1_y = 2;
        end
        'd1: begin
            bias_L0_x = 1;
            bias_L0_y = 0;
            bias_L1_x = 1;
            bias_L1_y = 2;
        end
        'd2: begin
            bias_L0_x = 2;
            bias_L0_y = 0;
            bias_L1_x = 0;
            bias_L1_y = 2;
        end
        'd3: begin
            bias_L0_x = 0;
            bias_L0_y = 1;
            bias_L1_x = 2;
            bias_L1_y = 1;
        end
        'd4: begin
            bias_L0_x = 1;
            bias_L0_y = 1;
            bias_L1_x = 1;
            bias_L1_y = 1;
        end
        'd5: begin
            bias_L0_x = 2;
            bias_L0_y = 1;
            bias_L1_x = 0;
            bias_L1_y = 1;
        end
        'd6: begin
            bias_L0_x = 0;
            bias_L0_y = 2;
            bias_L1_x = 2;
            bias_L1_y = 0;
        end
        'd7: begin
            bias_L0_x = 1;
            bias_L0_y = 2;
            bias_L1_x = 1;
            bias_L1_y = 0;
        end
        'd8: begin
            bias_L0_x = 2;
            bias_L0_y = 2;
            bias_L1_x = 0;
            bias_L1_y = 0;
        end
        default : begin
            bias_L0_x = 0;
            bias_L0_y = 0;
            bias_L1_x = 2;
            bias_L1_y = 2;
        end
    endcase
end

//=======================================================
//                   output
//=======================================================
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_output <=0;
    end
    else if (current_state == OUTPUT) begin
        counter_output <=  counter_output +1 ;
    end
    else begin
        counter_output <= 0;
    end

end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 1'b0;
    end 
    else if (current_state == OUTPUT)begin
        out_valid <= 1'b1;
    end
    else begin
        out_valid <= 1'b0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_sad <= 1'b0;
    end 
    else if (current_state == OUTPUT)begin
        out_sad <= output_concate[counter_output];
    end
    else begin
        out_sad <= 1'b0;
    end
end
always @(*)begin
    if (current_state == OUTPUT) begin
        output_concate = {point2_search, point2_sad, point1_search, point1_sad};
    end
    else begin
        output_concate = 0;
    end
end

endmodule




// always @ (*) begin
//     if (current_state== SAD) begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l=0  ; l < 8 ;l++) begin
//                 abs_0[i*8 + l] = ((BI_L0[i][l] - BI_L1[i+2][l+2])>0) ? (BI_L0[i][l] - BI_L1[i+2][l+2]) :  (BI_L1[i+2][l+2] - BI_L0[i][l]);
//             end
//         end
//     end
//     else begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l = 0; l < 8 ;l++)begin
//                 abs_0[i*8 + l] = 0;
//             end
//         end
//     end
// end

// always @ (*) begin
//     if (current_state== SAD) begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l=0  ; l < 8 ;l++) begin
//                 abs_1[i*8 + l] = ((BI_L0[i+1][l] - BI_L1[i+1][l+2])>0) ? (BI_L0[i+1][l] - BI_L1[i+1][l+2]) :  (BI_L1[i+1][l+2] - BI_L0[i+1][l]);
//             end
//         end
//     end
//     else begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l = 0; l < 8 ;l++)begin
//                 abs_1[i*8 + l] = 0;
//             end
//         end
//     end
// end
// always @ (*) begin
//     if (current_state== SAD) begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l=0  ; l < 8 ;l++) begin
//                 abs_2[i*8 + l] = ((BI_L0[i+2][l] - BI_L1[i][l+2])>0) ? (BI_L0[i+2][l] - BI_L1[i][l+2]) :  (BI_L1[i][l+2] - BI_L0[i+2][l]);
//             end
//         end
//     end
//     else begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l = 0; l < 8 ;l++)begin
//                 abs_2[i*8 + l] = 0;
//             end
//         end
//     end
// end
// always @ (*) begin
//     if (current_state== SAD) begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l=0  ; l < 8 ;l++) begin
//                 abs_3[i*8 + l] = ((BI_L0[i][l+1] - BI_L1[i+2][l+1])>0) ? (BI_L0[i][l+1] - BI_L1[i+2][l+1]) :  (BI_L1[i+2][l+1] - BI_L0[i][l+1]);
//             end
//         end
//     end
//     else begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l = 0; l < 8 ;l++)begin
//                 abs_3[i*8 + l] = 0;
//             end
//         end
//     end
// end
// always @ (*) begin
//     if (current_state== SAD) begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l=0  ; l < 8 ;l++) begin
//                 abs_4[i*8 + l] = ((BI_L0[i+1][l+1] - BI_L1[i+1][l+1])>0) ? (BI_L0[i+1][l+1] - BI_L1[i+1][l+1]) :  (BI_L1[i+1][l+1] - BI_L0[i+1][l+1]);
//             end
//         end
//     end
//     else begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l = 0; l < 8 ;l++)begin
//                 abs_4[i*8 + l] = 0;
//             end
//         end
//     end
// end
// always @ (*) begin
//     if (current_state== SAD) begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l=0  ; l < 8 ;l++) begin
//                 abs_5[i*8 + l] = ((BI_L0[i+2][l+1] - BI_L1[i][l+1])>0) ? (BI_L0[i+2][l+1] - BI_L1[i][l+1]) :  (BI_L1[i][l+1] - BI_L0[i+2][l+1]);
//             end
//         end
//     end
//     else begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l = 0; l < 8 ;l++)begin
//                 abs_5[i*8 + l] = 0;
//             end
//         end
//     end
// end
// always @ (*) begin
//     if (current_state== SAD) begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l=0  ; l < 8 ;l++) begin
//                 abs_6[i*8 + l] = ((BI_L0[i][l+2] - BI_L1[i+2][l])>0) ? (BI_L0[i][l+2] - BI_L1[i+2][l]) :  (BI_L1[i+2][l] - BI_L0[i][l+2]);
//             end
//         end
//     end
//     else begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l = 0; l < 8 ;l++)begin
//                 abs_6[i*8 + l] = 0;
//             end
//         end
//     end
// end
// always @ (*) begin
//     if (current_state== SAD) begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l=0  ; l < 8 ;l++) begin
//                 abs_7[i*8 + l] = ((BI_L0[i+1][l+2] - BI_L1[i+1][l])>0) ? (BI_L0[i+1][l+2] - BI_L1[i+1][l]) :  (BI_L1[i+1][l] - BI_L0[i+1][l+2]);
//             end
//         end
//     end
//     else begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l = 0; l < 8 ;l++)begin
//                 abs_7[i*8 + l] = 0;
//             end
//         end
//     end
// end
// always @ (*) begin
//     if (current_state== SAD) begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l=0  ; l < 8 ;l++) begin
//                 abs_8[i*8 + l] = ((BI_L0[i+2][l+2] - BI_L1[i][l])>0) ? (BI_L0[i+2][l+2] - BI_L1[i][l]) :  (BI_L1[i][l] - BI_L0[i+2][l+2]);
//             end
//         end
//     end
//     else begin
//         for (i = 0; i < 8 ;i++)begin
//             for (l = 0; l < 8 ;l++)begin
//                 abs_8[i*8 + l] = 0;
//             end
//         end
//     end
// end