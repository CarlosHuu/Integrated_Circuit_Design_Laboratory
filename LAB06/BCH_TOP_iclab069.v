//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2025
//		Version		: v1.0
//   	File Name   : BCH_TOP.v
//   	Module Name : BCH_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`include "Division_IP.v"


module BCH_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_syndrome, 
    // Output signals
    out_valid, 
	out_location
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [3:0] in_syndrome;

output reg out_valid;
output reg [3:0] out_location;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================
parameter	IDLE 	= 3'd0,
		    INPUT_data  = 3'd1,
            EUCLID = 3'd2,
            CHIEN = 3'd3,
            OUTPUT = 3'd4;


reg [2:0] current_state, next_state;
reg [3:0] input_syndrome [6];
reg [27:0] omega [2];
reg [27:0] sigma [2];
reg [5:0] counter_euclid;
reg [5:0] count;
reg [5:0] counter_output;
wire [27:0] quotient;
reg [27:0] quotient_reg;
reg [27:0] omega0_reg;
reg [27:0] omega1_reg;
reg [27:0] sigma0_reg;
reg [27:0] sigma1_reg;
wire [27:0] mult_out;
wire [27:0] add_out;
wire [27:0] mult_out1;
wire [27:0] add_out1;
wire [3:0] omega_dim;
wire [3:0] sigma_dim;
reg [3:0] omega_dim_check[7];
reg [3:0] sigma_dim_check[7];
reg [3:0] chain_search_poly[4];
reg [3:0] sum_all_15 [15];
reg [3:0] location_three[3];
genvar  i;
integer k;
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
            else
                next_state = IDLE;
        end
        INPUT_data: begin
            if (!in_valid)
                next_state = EUCLID;
            else
                next_state = INPUT_data;
        end
        EUCLID: begin
            if (omega_dim <= 2 && sigma_dim <=3 && counter_euclid >=2)
                next_state = CHIEN;
            else
                next_state = EUCLID;
        end
        CHIEN: begin
            next_state = OUTPUT;
        end
        OUTPUT: begin
            if (counter_output ==2)
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
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        input_syndrome[5] <= 0;
    end 
    else if (in_valid) begin
        input_syndrome[5] <= in_syndrome;
    end
	else begin
        input_syndrome[5] <= input_syndrome[5];
    end
end
generate
    for (i = 0; i < 5; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    input_syndrome[i] <= 0;
                end else if (in_valid) begin
                    input_syndrome[i] <= input_syndrome[i+1];
                end
         end 
    end
endgenerate 

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        omega[0] <= 0;
        omega[1] <= 0;
    end 
    else if (current_state == INPUT_data) begin
        omega[0] <= 28'b0000_1111_1111_1111_1111_1111_1111;
        omega[1] <= {4'b1111,input_syndrome[5],input_syndrome[4],input_syndrome[3],input_syndrome[2],input_syndrome[1],input_syndrome[0]};
    end 
    else if (current_state == EUCLID) begin
        if (counter_euclid == 0) begin
            omega[0] <= 28'b0000_1111_1111_1111_1111_1111_1111;
            omega[1] <= {4'b1111,input_syndrome[5],input_syndrome[4],input_syndrome[3],input_syndrome[2],input_syndrome[1],input_syndrome[0]};
        end 
        else if (counter_euclid %2 == 0) begin
            omega[0] <= omega[1];
            omega[1] <= add_out;
        end
        else begin
            omega[0] <= omega[0];
            omega[1] <= omega[1];
        end
    end 
    
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sigma[0] <= 0;
        sigma[1] <= 0;
    end 
    else if (current_state == INPUT_data) begin
        sigma[0] <= 28'b1111_1111_1111_1111_1111_1111_1111;
        sigma[1] <= 28'b1111_1111_1111_1111_1111_1111_0000;
    end
    else if (current_state == EUCLID) begin
        if (counter_euclid == 0) begin
            sigma[0] <= 28'b1111_1111_1111_1111_1111_1111_1111;
            sigma[1] <= 28'b1111_1111_1111_1111_1111_1111_0000;
        end 
        else if (counter_euclid %2 == 0) begin
            sigma[0] <= sigma[1];
            sigma[1] <= add_out1;
        end
        else begin
            sigma[0] <= sigma[0];
            sigma[1] <= sigma[1];
        end
    end  
end

Division_IP #(.IP_WIDTH('d7)) I_Division_IP(.IN_Dividend(omega[0]), .IN_Divisor(omega[1]), .OUT_Quotient(quotient)); 
Mult_IP #(.IP_WIDTH('d7)) I_Mult_IP(.IN_MULT1(quotient_reg), .IN_MULT2(omega1_reg), .OUT_MULT(mult_out)); 
Add_IP #(.IP_WIDTH('d7)) I_Add_IP(.IN_ADD1(omega0_reg), .IN_ADD2(mult_out), .OUT_ADD(add_out)); 
Mult_IP #(.IP_WIDTH('d7)) II_Mult_IP(.IN_MULT1(quotient_reg), .IN_MULT2(sigma1_reg), .OUT_MULT(mult_out1)); 
Add_IP #(.IP_WIDTH('d7)) II_Add_IP(.IN_ADD1(sigma0_reg), .IN_ADD2(mult_out1), .OUT_ADD(add_out1)); 
//=======================================================
//                EUCLID
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_euclid <= 0; 
    end 
    else if (current_state == IDLE) begin
        counter_euclid <= 0;
    end
    else if (current_state == EUCLID) begin
        counter_euclid <= counter_euclid + 1;
    end else begin
        counter_euclid <= 0;
    end 
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        quotient_reg <= 0;
        omega0_reg <= 0;
        omega1_reg <= 0;
        sigma0_reg <= 0;
        sigma1_reg <= 0;
    end 
    else if (current_state == EUCLID && counter_euclid >= 1) begin
        quotient_reg <= quotient;
        omega0_reg <= omega[0];
        omega1_reg <= omega[1];
        sigma0_reg <= sigma[0];
        sigma1_reg <= sigma[1];
    end 
end

always @(*) begin
    for (k = 0; k < 7; k = k + 1) begin
        omega_dim_check[k] = add_out[k*4 +: 4];
        sigma_dim_check[k] = add_out1[k*4 +: 4];
    end
end

assign omega_dim = check_dimension(omega_dim_check);
assign sigma_dim = check_dimension(sigma_dim_check);
//=======================================================
//                Chien search
//=======================================================
always @(*) begin
    for (k = 0; k < 4; k = k + 1) begin
        chain_search_poly[k] = sigma[1][k*4 +: 4];
    end
end

generate
    for(i = 0; i < 15; i = i + 1) begin : chain_search
        reg [3:0] reverse_location;
        reg [3:0] x3;
        reg [3:0] x2;
        reg [3:0] x3_value;
        reg [3:0] x2_value;
        reg [3:0] x1_value;
        reg [3:0] const_value;

        reg [3:0] add1_temp;
        reg [3:0] add2_temp;
        reg [3:0] sum;

        reg [3:0] index;
        reg [3:0] index_next;
        reg check;

        if (i == 0) begin
           always @(*) begin
                x2 = GF_mult(i, i);
                x3 = GF_mult(x2, i);
                const_value = chain_search_poly[0];
                x1_value =  GF_mult(chain_search_poly[1], i);
                x2_value = GF_mult(chain_search_poly[2], x2);
                x3_value = GF_mult(chain_search_poly[3], x3);
                add1_temp = GF_add(x1_value, const_value);
                add2_temp = GF_add(x2_value, x3_value);
                sum = GF_add(add1_temp, add2_temp);
                
            end
        end
        else begin
            always @(*) begin
               reverse_location = 15 - i;
                x2 = GF_mult(reverse_location, reverse_location);
                x3 = GF_mult(x2, reverse_location);
                const_value = chain_search_poly[0];
                x1_value =  GF_mult(chain_search_poly[1], reverse_location);
                x2_value = GF_mult(chain_search_poly[2], x2);
                x3_value = GF_mult(chain_search_poly[3], x3);
                add1_temp = GF_add(x1_value, const_value);
                add2_temp = GF_add(x2_value, x3_value);
                sum = GF_add(add1_temp, add2_temp);
            end
        end
        always @(*) begin
            sum_all_15[i] = chain_search[i].sum;
        end
    end
endgenerate




wire index_is_15 [15];  
generate
    for (i = 0; i < 15; i = i + 1) begin : check_loop
        assign index_is_15[i] = (sum_all_15[i] == 4'd15);
    end
endgenerate


always @(*) begin
    for (k = 0; k < 3; k = k + 1) begin
        location_three[k] = 4'd15;
    end
    count = 0; 
    for (k = 0; k < 15; k = k+ 1) begin
        if (index_is_15[k] && count < 3) begin
            location_three[count] = k[3:0]; 
            count = count + 1;
        end
    end
end

//=======================================================
//                OUTPUT
//=======================================================

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_output <= 0; 
    end 
    else if (current_state == IDLE) begin
        counter_output <= 0;
    end
    else if (current_state == CHIEN) begin
        counter_output <= 1;
    end
    else if (current_state == OUTPUT) begin
        counter_output <= counter_output + 1;
    end else begin
        counter_output <= 0;
    end 
end
// reg [3:0] out_location_sim;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_location<= 0;
    end
    else if (current_state == CHIEN)begin
        out_location<= location_three[0];
    end
    else if (current_state == OUTPUT )begin
        out_location <= location_three[counter_output];
    end
    else begin
        out_location <= 0;
    end
end



always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid <= 0;
    end
    else if (current_state == CHIEN || current_state == OUTPUT)begin
        out_valid <= 1;
    end
    else begin
        out_valid <= 0;
    end
end
// always @(posedge clk or negedge rst_n)begin
//     if(!rst_n)begin
//         out_location <= 0;
//     end
//     else begin
//         out_location <= 0;
//     end
// end
//=======================================================
//                FUNCTION
//=======================================================
localparam [3:0] GF_TABLE [0:15] = '{
    4'd1, 4'd2, 4'd4, 4'd8, 4'd3, 4'd6, 4'd12, 4'd11,
    4'd5, 4'd10, 4'd7, 4'd14, 4'd15, 4'd13, 4'd9, 4'd0
};

localparam [3:0] INV_GF_TABLE [0:15] = '{
    4'd15, 4'd0, 4'd1, 4'd4, 4'd2, 4'd8, 4'd5, 4'd10,
    4'd3, 4'd14, 4'd9, 4'd7, 4'd6, 4'd13, 4'd11, 4'd12
};

function [3:0] check_dimension;
    input [3:0] polynomial [0:6];
    integer i;
    reg check_flag;
    begin
        check_flag = 0;
        check_dimension = 0;
        for (i = 6; i >= 0; i = i - 1) begin
            if (polynomial[i] != 4'd15 && check_flag ==0) begin
                check_dimension = i ;
                check_flag = 1;
            end
        end
    end
endfunction

function [3:0] GF_mult;
    input [3:0] a;
    input [3:0] b;
    begin
        if (a == 4'd15 || b == 4'd15)
            GF_mult = 4'd15;
        else
            GF_mult = (a + b) % 15;
    end
endfunction

function [3:0] GF_add;
    input [3:0] a;
    input [3:0] b;
    begin
        if (a == 4'd15 && b == 4'd15)
            GF_add = 4'd15;
        else if (a == 4'd15)
            GF_add = b;
        else if (b == 4'd15)
            GF_add = a;
        else
            GF_add = INV_GF_TABLE[GF_TABLE[a] ^ GF_TABLE[b]];
    end
endfunction


endmodule
//=======================================================
//                submodule
//=======================================================

module Add_IP #(parameter IP_WIDTH = 7) (
    // Input signals
    IN_ADD1, IN_ADD2,
    // Output signals
    OUT_ADD
);

    input [IP_WIDTH*4-1:0]  IN_ADD1;
    input [IP_WIDTH*4-1:0]  IN_ADD2;

    output reg [IP_WIDTH*4-1:0] OUT_ADD;


    localparam [3:0] GF_TABLE [0:15] = '{
        4'd1, 4'd2, 4'd4, 4'd8, 4'd3, 4'd6, 4'd12, 4'd11,
        4'd5, 4'd10, 4'd7, 4'd14, 4'd15, 4'd13, 4'd9, 4'd0
    };

    localparam [3:0] INV_GF_TABLE [0:15] = '{
        4'd15, 4'd0, 4'd1, 4'd4, 4'd2, 4'd8, 4'd5, 4'd10,
        4'd3, 4'd14, 4'd9, 4'd7, 4'd6, 4'd13, 4'd11, 4'd12
    };

    function [3:0] GF_add;
        input [3:0] a;
        input [3:0] b;
        begin
            if (a == 4'd15 && b == 4'd15)
                GF_add = 4'd15;
            else if (a == 4'd15)
                GF_add = b;
            else if (b == 4'd15)
                GF_add = a;
            else
                GF_add = INV_GF_TABLE[GF_TABLE[a] ^ GF_TABLE[b]];
        end
    endfunction

    always @(*) begin
        OUT_ADD[3:0]   = GF_add(IN_ADD1[3:0], IN_ADD2[3:0]);
        OUT_ADD[7:4]   = GF_add(IN_ADD1[7:4], IN_ADD2[7:4]);
        OUT_ADD[11:8]  = GF_add(IN_ADD1[11:8], IN_ADD2[11:8]);
        OUT_ADD[15:12] = GF_add(IN_ADD1[15:12], IN_ADD2[15:12]);
        OUT_ADD[19:16] = GF_add(IN_ADD1[19:16], IN_ADD2[19:16]);
        OUT_ADD[23:20] = GF_add(IN_ADD1[23:20], IN_ADD2[23:20]);
        OUT_ADD[27:24] = GF_add(IN_ADD1[27:24], IN_ADD2[27:24]);
    end

endmodule


module Mult_IP #(parameter IP_WIDTH = 7) (
    // Input signals
    IN_MULT1, IN_MULT2,
    // Output signals
    OUT_MULT
);

    input [IP_WIDTH*4-1:0]  IN_MULT1;
    input [IP_WIDTH*4-1:0]  IN_MULT2;
    
    output reg [IP_WIDTH*4-1:0] OUT_MULT;

    integer i;
    reg [27:0] temp_mult_1 ;
    reg [23:0] temp_mult_2 ;
    reg [19:0] temp_mult_3 ;
    reg [15:0] temp_mult_4 ;
    reg [11:0] temp_mult_5 ;
    reg [7:0] temp_mult_6 ;
    reg [3:0] temp_mult_7 ;

    wire [27:0] temp_add_1 ;
    wire [27:0] temp_add_2 ;
    wire [27:0] temp_add_3 ;
    wire [27:0] temp_add_4 ;
    wire [27:0] temp_add_5 ;

    function [3:0] GF_mult;
    input [3:0] a;
    input [3:0] b;
    begin
        if (a == 4'd15 || b == 4'd15)
            GF_mult = 4'd15;
        else
            GF_mult = (a + b) % 15;
    end
    endfunction

    always @(*) begin
        for (i = 0; i < 7; i = i + 1) begin
            temp_mult_1[i*4 +: 4]  = GF_mult( IN_MULT1[i*4 +: 4], IN_MULT2[3:0]);
        end
    end
    always @(*) begin
        for (i = 0; i < 6; i = i + 1) begin
            temp_mult_2[i*4 +: 4]  = GF_mult( IN_MULT1[i*4 +: 4], IN_MULT2[7:4]);
        end
    end
    always @(*) begin
        for (i = 0; i < 5; i = i + 1) begin
            temp_mult_3[i*4 +: 4]  = GF_mult( IN_MULT1[i*4 +: 4], IN_MULT2[11:8]);
        end
    end
    always @(*) begin
        for (i = 0; i < 4; i = i + 1) begin
            temp_mult_4[i*4 +: 4]  = GF_mult( IN_MULT1[i*4 +: 4], IN_MULT2[15:12]);
        end
    end
    always @(*) begin
        for (i = 0; i < 3; i = i + 1) begin
            temp_mult_5[i*4 +: 4]  = GF_mult( IN_MULT1[i*4 +: 4], IN_MULT2[19:16]);
        end
    end
    always @(*) begin
        for (i = 0; i < 2; i = i + 1) begin
            temp_mult_6[i*4 +: 4]  = GF_mult( IN_MULT1[i*4 +: 4], IN_MULT2[23:20]);
        end
    end
    always @(*) begin
        for (i = 0; i < 1; i = i + 1) begin
            temp_mult_7[i*4 +: 4]  = GF_mult( IN_MULT1[i*4 +: 4], IN_MULT2[27:24]);
        end
    end

    Add_IP #(.IP_WIDTH('d7)) add1 (.IN_ADD1(temp_mult_1), .IN_ADD2( {temp_mult_2,4'b1111} ), .OUT_ADD(temp_add_1)); 
    Add_IP #(.IP_WIDTH('d7)) add2 (.IN_ADD1( {temp_mult_3,8'b1111_1111} ), .IN_ADD2( {temp_mult_4,12'b1111_1111_1111} ), .OUT_ADD(temp_add_2));
    Add_IP #(.IP_WIDTH('d7)) add3 (.IN_ADD1( {temp_mult_5,16'b1111_1111_1111_1111} ), .IN_ADD2( {temp_mult_6,20'b1111_1111_1111_1111_1111} ), .OUT_ADD(temp_add_3));
    Add_IP #(.IP_WIDTH('d7)) add4 (.IN_ADD1( {temp_mult_7,24'b1111_1111_1111_1111_1111_1111} ), .IN_ADD2( temp_add_3 ), .OUT_ADD(temp_add_5));
    Add_IP #(.IP_WIDTH('d7)) add5 (.IN_ADD1( temp_add_1 ), .IN_ADD2( temp_add_2 ), .OUT_ADD(temp_add_4));
    Add_IP #(.IP_WIDTH('d7)) add6 (.IN_ADD1( temp_add_4 ), .IN_ADD2( temp_add_5 ), .OUT_ADD(OUT_MULT));

endmodule