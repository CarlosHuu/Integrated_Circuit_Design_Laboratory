 //############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : Division_IP.v
//   	Module Name : Division_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module Division_IP #(parameter IP_WIDTH = 7) (
    // Input signals
    IN_Dividend, IN_Divisor,
    // Output signals
    OUT_Quotient
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*4-1:0]  IN_Dividend;
input [IP_WIDTH*4-1:0]  IN_Divisor;

output reg [IP_WIDTH*4-1:0] OUT_Quotient;


// ===============================================================
// Design
// ===============================================================
// localparam [3:0]GF_TABLE[0:15] = '{1, 2, 4, 8, 3, 6, 12, 11, 5, 10, 7, 14, 15, 13, 9, 0};
// localparam [3:0]INV_GF_TABLE[0:15] = '{15, 0, 1, 4, 2, 8, 5, 10, 3, 14, 9, 7, 6, 13, 11, 12};
function [3:0] gf_table_lookup;
    input [3:0] idx;
    begin
        case (idx)
            4'd0:  gf_table_lookup = 4'd1;
            4'd1:  gf_table_lookup = 4'd2;
            4'd2:  gf_table_lookup = 4'd4;
            4'd3:  gf_table_lookup = 4'd8;
            4'd4:  gf_table_lookup = 4'd3;
            4'd5:  gf_table_lookup = 4'd6;
            4'd6:  gf_table_lookup = 4'd12;
            4'd7:  gf_table_lookup = 4'd11;
            4'd8:  gf_table_lookup = 4'd5;
            4'd9:  gf_table_lookup = 4'd10;
            4'd10: gf_table_lookup = 4'd7;
            4'd11: gf_table_lookup = 4'd14;
            4'd12: gf_table_lookup = 4'd15;
            4'd13: gf_table_lookup = 4'd13;
            4'd14: gf_table_lookup = 4'd9;
            4'd15: gf_table_lookup = 4'd0;
        endcase
    end
endfunction

function [3:0] inv_gf_table_lookup;
    input [3:0] idx;
    begin
        case (idx)
            4'd0:  inv_gf_table_lookup = 4'd15;
            4'd1:  inv_gf_table_lookup = 4'd0;
            4'd2:  inv_gf_table_lookup = 4'd1;
            4'd3:  inv_gf_table_lookup = 4'd4;
            4'd4:  inv_gf_table_lookup = 4'd2;
            4'd5:  inv_gf_table_lookup = 4'd8;
            4'd6:  inv_gf_table_lookup = 4'd5;
            4'd7:  inv_gf_table_lookup = 4'd10;
            4'd8:  inv_gf_table_lookup = 4'd3;
            4'd9:  inv_gf_table_lookup = 4'd14;
            4'd10: inv_gf_table_lookup = 4'd9;
            4'd11: inv_gf_table_lookup = 4'd7;
            4'd12: inv_gf_table_lookup = 4'd6;
            4'd13: inv_gf_table_lookup = 4'd13;
            4'd14: inv_gf_table_lookup = 4'd11;
            4'd15: inv_gf_table_lookup = 4'd12;
        endcase
    end
endfunction


function [3:0] gf_power;
    input [3:0] base;
    input [3:0] exponent;
    reg [7:0] result_log;
    begin
        if (base == 4'b0000)
            gf_power = (exponent == 4'b0000) ? 4'b0001 : 4'b0000;
        else if (base == 4'b1111 || exponent == 4'b1111)
            gf_power = 4'b1111;
        else if (exponent == 4'b0000)
            gf_power = 4'b0001;
        else begin
            // Log-domain exponentiation
            result_log = (gf_table_lookup(base) * exponent) % 15;
            gf_power = inv_gf_table_lookup(result_log);
        end
    end
endfunction

function [3:0] gf_trace;
    input [3:0] a;
    reg [3:0] trace_result;
    integer j;
    begin
        if (a == 4'b1111)
            gf_trace = 4'b1111;
        else begin
            // Calculate trace: a + a^2 + a^4 + a^8
            trace_result = a;
            gf_trace = trace_result & 4'b0001; // Only keep the lowest bit
        end
    end
endfunction

function [3:0] checkFORdegree;
    input [3:0] polynomial [0:IP_WIDTH-1];
    integer i;
    reg check_flag;
    begin
        check_flag = 0;
        checkFORdegree = 0;
        for (i = IP_WIDTH-1; i >= 0; i = i - 1) 
        begin
            if (polynomial[i] != 4'd15 && check_flag ==0) 
            begin
                checkFORdegree = i + 1 ;
                check_flag = 1;
            end
        end
    end
endfunction

reg [3:0] dividend [0:IP_WIDTH-1];
reg [3:0] divisor  [0:IP_WIDTH-1];

integer g;
genvar i;
integer j;

always @(*) begin
    for(g = 0; g < IP_WIDTH; g = g + 1) begin
        divisor[g]  = IN_Divisor[((g)*4) +: 4];
            dividend[g] = IN_Dividend[((g)*4) +: 4];
            
    end
end


generate
    for(i = 0; i < IP_WIDTH; i = i +  1) begin : stage
       
        
        
        reg [3:0] minus_item     [0:IP_WIDTH-1];
        reg [3:0] remainder_DIM;
        reg [3:0] divisor_DIM;
        reg [3:0] minus_DIM;
        reg [3:0] remainder_next [0:IP_WIDTH-1];
        reg [3:0] idx;
         reg [3:0] quotient_now;
         reg [3:0] remainder      [0:IP_WIDTH-1];
        if (i != 0) begin
            always @(*) begin
                for (j = 0; j < IP_WIDTH; j = j + 1) remainder[j]      = stage[i-1].remainder_next[j];
                
                quotient_now = stage[i-1].quotient_now;
                divisor_DIM = checkFORdegree(divisor);
                idx = IP_WIDTH - 1 - i;
                remainder_DIM = checkFORdegree(remainder);
                if(remainder_DIM == 0) begin
                    quotient_now = 4'd15;
                end else begin
                  
                    if (remainder[remainder_DIM-1] == 4'd15)
                        quotient_now = 4'd15;
                    else if (divisor[divisor_DIM-1] != 4'd15) begin
                        if (remainder[remainder_DIM-1] >= divisor[divisor_DIM-1])
                            quotient_now = remainder[remainder_DIM-1] - divisor[divisor_DIM-1];
                        else
                            quotient_now = (remainder[remainder_DIM-1] + 15) - divisor[divisor_DIM-1];
                    end 
                    else
                        quotient_now = 4'd15;
                        
                    if((divisor_DIM > (IP_WIDTH - idx)) || (divisor_DIM > remainder_DIM))
                        quotient_now = 4'd15;
                end
                for(j = 0; j < IP_WIDTH; j = j + 1) begin
                    minus_item[j] = 4'd15;
                end
                for(j = idx; j < IP_WIDTH; j = j + 1) begin
                    if((j - idx) < divisor_DIM)

                        if (quotient_now == 4'd15 || divisor[j - idx] == 4'd15)
                            minus_item[j] = 4'd15;
                        else
                            minus_item[j] = (quotient_now + divisor[j - idx]) % 15;
                    else
                        minus_item[j] = 4'd15;
                end
                minus_DIM = checkFORdegree(minus_item);
                if(minus_DIM != remainder_DIM) begin
                    quotient_now = 4'd15;
                    for(j = idx; j < IP_WIDTH; j = j + 1) begin
                        minus_item[j] = 4'd15;
                    end
                end
                for(j = 0; j < IP_WIDTH; j = j + 1) begin
                    if (remainder[j] == 4'd15 && minus_item[j] == 4'd15) begin
                        remainder_next[j] = 4'd15;
                    end
                    else if (remainder[j] == 4'd15)
                        remainder_next[j] = minus_item[j];
                    else if (minus_item[j] == 4'd15)
                        remainder_next[j] = remainder[j];
                    else
                        remainder_next[j] = inv_gf_table_lookup(
                        gf_table_lookup(remainder[j]) ^ gf_table_lookup(minus_item[j])
                    );

                end
            end

        end
        else begin
            always @(*) begin
                for (j = 0; j < IP_WIDTH; j = j + 1) remainder[j]      = dividend[j];
               
                quotient_now = 4'd15;
                divisor_DIM = checkFORdegree(divisor);
                idx = IP_WIDTH - 1 - i;
                remainder_DIM = checkFORdegree(remainder);
                if(remainder_DIM == 0) begin
                    quotient_now = 4'd15;
                end 
                else begin
                    // quotient_now = GF_divide(remainder[remainder_DIM-1], divisor[divisor_DIM-1]);
                    if (remainder[remainder_DIM-1] == 4'd15)
                        quotient_now = 4'd15;
                    else if (divisor[divisor_DIM-1] != 4'd15) begin
                        if (remainder[remainder_DIM-1] >= divisor[divisor_DIM-1])
                            quotient_now = remainder[remainder_DIM-1] - divisor[divisor_DIM-1];
                        else
                            quotient_now = (remainder[remainder_DIM-1] + 15) - divisor[divisor_DIM-1];
                    end 
                    else
                        quotient_now = 4'd15;

                    if((divisor_DIM > (IP_WIDTH - idx)) || (divisor_DIM > remainder_DIM))
                        quotient_now = 4'd15;
                end
                for(j = 0; j < IP_WIDTH; j = j + 1) begin
                    minus_item[j] = 4'd15;
                end
                for(j = idx; j < IP_WIDTH; j = j + 1) begin
                    if((j - idx) < divisor_DIM)
                        // minus_item[j] = GF_mult(quotient_now, divisor[j - idx]);
                        if (quotient_now == 4'd15 || divisor[j - idx] == 4'd15)
                            minus_item[j] = 4'd15;
                        else
                            minus_item[j] = (quotient_now + divisor[j - idx]) % 15;
                    else
                        minus_item[j] = 4'd15;
                end
                minus_DIM = checkFORdegree(minus_item);
                if(minus_DIM != remainder_DIM) begin
                    quotient_now = 4'd15;
                    for(j = idx; j < IP_WIDTH; j = j + 1) begin
                        minus_item[j] = 4'd15;
                    end
                end
                for(j = 0; j < IP_WIDTH; j = j + 1) begin
                    if (remainder[j] == 4'd15 && minus_item[j] == 4'd15)
                        remainder_next[j] = 4'd15;
                    else if (remainder[j] == 4'd15)
                        remainder_next[j] = minus_item[j];
                    else if (minus_item[j] == 4'd15)
                        remainder_next[j] = remainder[j];
                    else
                  
                        remainder_next[j] = inv_gf_table_lookup(
                        gf_table_lookup(remainder[j]) ^ gf_table_lookup(minus_item[j])
                    );

                end
            end
        end
        always @(*) begin
            OUT_Quotient[((IP_WIDTH-i-1)*4) +: 4] = stage[i].quotient_now;
        end
    end
endgenerate



endmodule
