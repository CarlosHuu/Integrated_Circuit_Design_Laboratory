/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2025 Spring IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: May-2025)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

// integer fp_w;

// initial begin
// fp_w = $fopen("out_valid.txt", "w");
// end

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */

class Strategy_and_mode;
    Strategy_Type f_type;
    Mode f_mode;
endclass

Strategy_and_mode fm_info = new();

always_comb begin
    if(inf.strategy_valid)
        fm_info.f_type = inf.D.d_strategy[0];
    if(inf.mode_valid)
        fm_info.f_mode = inf.D.d_mode[0];
end

//=======================================================
//                   COVERAGE
//=======================================================

covergroup SPEC1 @(posedge clk iff (inf.strategy_valid));
    option.per_instance = 1;
    option.at_least = 100;
    coverpoint fm_info.f_type {
        bins b_strategy_type[] = {[Strategy_A : Strategy_H]};
    }
endgroup
SPEC1 coverage_spec1 = new();

covergroup SPEC2 @(posedge clk iff (inf.mode_valid));
    option.per_instance = 1;
    option.at_least = 100;
    coverpoint fm_info.f_mode {
        bins b_mode[] = {[Single : Event]};
    }
endgroup
SPEC2 coverage_spec2 = new();

covergroup SPEC3 @(posedge clk iff (inf.mode_valid));
    option.per_instance = 1;
    option.at_least = 100;
    cross fm_info.f_type, fm_info.f_mode;
endgroup
SPEC3 coverage_spec3 = new();

covergroup SPEC4 @(posedge clk iff (inf.out_valid));
    option.per_instance = 1;
    option.at_least = 10;
    coverpoint inf.warn_msg{
        bins b_warn_msg [] = {No_Warn , Date_Warn, Stock_Warn, Restock_Warn};
    }
endgroup
SPEC4 coverage_spec4 = new();

covergroup SPEC5 @(posedge clk iff (inf.sel_action_valid));
    option.per_instance = 1;
    option.at_least = 300;
    coverpoint inf.D.d_act[0]{
        bins b_act [] = ([Purchase:Check_Valid_Date] => [Purchase:Check_Valid_Date]);
    }
endgroup
SPEC5 coverage_spec5 = new();

covergroup SPEC6 @(posedge clk iff (inf.restock_valid));
    option.per_instance = 1;
    option.at_least = 1;
    coverpoint inf.D.d_stock[0]{
        option.auto_bin_max = 32;
    }
endgroup
SPEC6 coverage_spec6 = new();

//=======================================================
//                   ASSERTION
//=======================================================
wire #(1) reg_rst_n = inf.rst_n;
property ASSERT_1;
    @(negedge reg_rst_n) (!inf.out_valid    &&!inf.warn_msg   &&!inf.complete     &&!inf.AR_VALID  
                          &&!inf.R_READY    &&!inf.AW_VALID   &&!inf.AW_ADDR      &&!inf.AR_ADDR      
                          &&!inf.W_DATA     &&!inf.W_VALID    &&!inf.B_READY);
endproperty

property ASSERT_2;
	@(posedge clk) (inf.sel_action_valid | inf.data_no_valid | inf.restock_valid | inf.data_no_valid)
    |-> ##[1:1000] inf.out_valid;
endproperty

property ASSERT_3; 
    @(negedge clk) 
    (inf.complete && inf.out_valid) 
    |-> inf.warn_msg === No_Warn;
endproperty

property ASSERT_4_purchase;
    @(posedge clk) 
    (inf.sel_action_valid === 1 & inf.D.d_act[0] === Purchase) 
    |-> ##[1:4] inf.strategy_valid  ##[1:4] inf.mode_valid  ##[1:4] inf.date_valid  ##[1:4] inf.data_no_valid; 
endproperty

property ASSERT_4_restock;
    @(posedge clk) 
    (inf.sel_action_valid === 1 & inf.D.d_act[0] === Restock) 
    |-> ##[1:4] inf.date_valid ##[1:4] inf.data_no_valid ##[1:4] inf.restock_valid ##[1:4] inf.restock_valid ##[1:4] inf.restock_valid ##[1:4] inf.restock_valid; 
endproperty

property ASSERT_4_check;
    @(posedge clk) 
    (inf.sel_action_valid === 1 & inf.D.d_act[0] === Check_Valid_Date) 
    |-> ##[1:4] inf.date_valid ##[1:4] inf.data_no_valid; 
endproperty

property ASSERT_5_A;
    @(negedge clk)(!(inf.sel_action_valid===1 && inf.strategy_valid===1));
endproperty
property ASSERT_5_B;
    @(negedge clk)(!(inf.sel_action_valid===1 && inf.mode_valid===1));
endproperty
property ASSERT_5_C;
    @(negedge clk)(!(inf.sel_action_valid===1 && inf.date_valid===1));
endproperty
property ASSERT_5_D;
    @(negedge clk)(!(inf.sel_action_valid===1 && inf.data_no_valid===1));
endproperty
property ASSERT_5_E;
    @(negedge clk)(!(inf.sel_action_valid===1 && inf.restock_valid===1));
endproperty
property ASSERT_5_F;
    @(negedge clk)(!(inf.strategy_valid===1 && inf.mode_valid===1));
endproperty
property ASSERT_5_G;
    @(negedge clk)(!(inf.strategy_valid===1 && inf.date_valid===1));
endproperty
property ASSERT_5_H;
    @(negedge clk)(!(inf.strategy_valid===1 && inf.data_no_valid===1));
endproperty
property ASSERT_5_I;
    @(negedge clk)(!(inf.strategy_valid===1 && inf.restock_valid===1));
endproperty
property ASSERT_5_J;
    @(negedge clk)(!(inf.mode_valid===1 && inf.date_valid===1));
endproperty
property ASSERT_5_K;
    @(negedge clk)(!(inf.mode_valid===1 && inf.data_no_valid===1));
endproperty
property ASSERT_5_L;
    @(negedge clk)(!(inf.mode_valid===1 && inf.restock_valid===1));
endproperty 
property ASSERT_5_M;
    @(negedge clk)(!(inf.date_valid===1 && inf.data_no_valid===1));
endproperty
property ASSERT_5_N;
    @(negedge clk)(!(inf.date_valid===1 && inf.restock_valid===1));
endproperty
property ASSERT_5_O;
    @(negedge clk)(!(inf.data_no_valid===1 && inf.restock_valid===1));
endproperty

property ASSERT_6;
	@(posedge clk) 
    (inf.out_valid) 
    |=> inf.out_valid === 0;
endproperty

property ASSERT_7;
    @(negedge clk) (inf.out_valid === 1) 
    |=> ##[1:4] inf.sel_action_valid; 
endproperty

property ASSERT_8_31days;
    @(posedge clk) 
    (inf.date_valid && is_31days_month(inf.D.d_date[0].M)) 
    |-> day_in_valid_range(inf.D.d_date[0].D, 1, 31); 
endproperty

property ASSERT_8_30days;
    @(posedge clk) 
    (inf.date_valid && is_30days_month(inf.D.d_date[0].M)) 
    |-> day_in_valid_range(inf.D.d_date[0].D, 1, 30); 
endproperty

property ASSERT_8_28days;
    @(posedge clk) 
    (inf.date_valid && (inf.D.d_date[0].M == 2)) 
    |-> day_in_valid_range(inf.D.d_date[0].D, 1, 28); 
endproperty

property ASSERT_8_M;
    @(posedge clk) 
    inf.date_valid 
    |-> (inf.D.d_date[0].M >= 1 && inf.D.d_date[0].M <= 12); 
endproperty

function automatic bit is_31days_month(logic [3:0] month);
    return (month == 1 || month == 3 || month == 5 || month == 7 || 
            month == 8 || month == 10 || month == 12);
endfunction

function automatic bit is_30days_month(logic [3:0] month);
    return (month == 4 || month == 6 || month == 9 || month == 11);
endfunction

function automatic bit day_in_valid_range(logic [4:0] day, int lower, int upper);
    return (day >= lower && day <= upper);
endfunction

property ASSERT_9;
    @(posedge clk) 
    (inf.AR_VALID === 1) 
    |-> !(inf.AW_VALID);
endproperty
//=======================================================
//                   PRINT ASSERTION
//=======================================================
SPEC1_reset_check:
    assert property (ASSERT_1)
        else begin
            $display("=======================");
            $display("Assertion 1 is violated");
            $display("=======================");
            $fatal; 
        end

SPEC2_latency_check:
    assert property (ASSERT_2)
        else begin
            $display("=======================");
            $display("Assertion 2 is violated");
            $display("=======================");
            $fatal; 
        end

SPEC3_complete_check:
    assert property (ASSERT_3)
        else begin
            $display("=======================");
            $display("Assertion 3 is violated");
            $display("=======================");
            $fatal; 
        end
SPEC4_valid_check:
    assert property (ASSERT_4_purchase)
        else begin
            $display("=======================");
            $display("Assertion 4 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_4_restock) 
        else begin
            $display("=======================");
            $display("Assertion 4 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_4_check)
        else begin
            $display("=======================");
            $display("Assertion 4 is violated");
            $display("=======================");
            $fatal; 
        end
SPEC5_valid_check:
    assert property (ASSERT_5_A)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_5_B)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_5_C)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_5_D)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_5_E)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_5_F)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_5_G)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_5_H)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_5_I)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_5_J)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_5_K)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_5_L)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_5_M)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_5_N)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_5_O)
        else begin
            $display("=======================");
            $display("Assertion 5 is violated");
            $display("=======================");
            $fatal; 
        end

SPEC6_OUT_valid_check:
    assert property (ASSERT_6)
        else begin
            $display("=======================");
            $display("Assertion 6 is violated");
            $display("=======================");
            $fatal; 
        end

SPEC7_NEXT_OPERATION_check:
    assert property (ASSERT_7)
        else begin
            $display("=======================");
            $display("Assertion 7 is violated");
            $display("=======================");
            $fatal; 
        end
SPEC8_DATE_check:
    assert property (ASSERT_8_31days)
        else begin
            $display("=======================");
            $display("Assertion 8 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_8_30days)
        else begin
            $display("=======================");
            $display("Assertion 8 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_8_28days)
        else begin
            $display("=======================");
            $display("Assertion 8 is violated");
            $display("=======================");
            $fatal; 
        end
    assert property (ASSERT_8_M)
        else begin
            $display("=======================");
            $display("Assertion 8 is violated");
            $display("=======================");
            $fatal; 
        end
SPEC9_AR_AW_check:
    assert property (ASSERT_9)
        else begin
            $display("=======================");
            $display("Assertion 9 is violated");
            $display("=======================");
            $fatal; 
        end
endmodule