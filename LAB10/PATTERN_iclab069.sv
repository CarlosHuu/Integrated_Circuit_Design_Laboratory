/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2025 Spring IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: April-2025)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/
`define PAT_NUM         8500
`define RANDOM_SEED     5487
// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";

parameter MAX_CYCLE=1000;
parameter CLK_TIME = 15;

parameter SEED = `RANDOM_SEED;
integer addr;
integer total_lat, lat;
integer i, i_pat;
//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 32 box


Action       action_reg;
Strategy_Type strategy_reg;
Stock stock_A, stock_B, stock_C, stock_D;
Data_No data_reg;
Date date_reg;
Mode         mode_reg;
logic [11:0] Lily_request;
logic [11:0] Rose_request;
logic [11:0] Carnation_request;
logic [11:0] Baby_Breath_request;
logic [63:0] dram_out ,dram_in;
logic overflow_flag;
logic date_check;
logic warn_stock;
Data_Dir dram_in_dir, dram_out_dir;
// Data_Dir dram_in;
Warn_Msg       golden_warn_msg;
logic          golden_complete;
logic [12:0] Lily_new;
logic [12:0] Rose_new;
logic [12:0] Carnation_new;
logic [12:0] Baby_Breath_new;
//================================================================
// class random
//================================================================

/**
 * Class representing a random action.
 */
class random_act;
    randc Action act_id;
    constraint range{
        act_id inside{Purchase, Restock, Check_Valid_Date};
    }
    function new (int seed);
        
        this.srandom(seed);
    endfunction
endclass

class random_strategy;
    randc Strategy_Type strategy_id;
    constraint range{
        strategy_id inside{Strategy_A, Strategy_B, Strategy_C, Strategy_D,
                            Strategy_E, Strategy_F, Strategy_G, Strategy_H};
    }
    function new (int seed);
        
        this.srandom(seed);
    endfunction
endclass

class random_mode;
    randc Mode mode_id;
    constraint range{
        mode_id inside{Single, Group_Order, Event};
    }
    function new(int seed);
        
        this.srandom(seed);
    endfunction
endclass

class random_date;
    randc Date date_id;
    constraint limit{
        date_id.M inside {[1:12]};
        if(date_id.M==2){
            date_id.D  inside{[1:28]};
        }
        else if(date_id.M==1||date_id.M==3||date_id.M==5||date_id.M==7||date_id.M==8||date_id.M==10||date_id.M==12){
            date_id.D  inside{[1:31]};
        }
        else {
            date_id.D  inside{[1:30]};
        }
    }
    function new(int seed);
        
        this.srandom(seed);
    endfunction
endclass

class random_data_no;
	randc Data_No data_no_id;
	constraint limit{
		data_no_id inside{[0:255]};
	}
    function new(int seed);
        
        this.srandom(seed);
    endfunction
endclass

class random_stock;
    randc Stock stock_id;
    constraint range{
        stock_id inside{[0:4095]};
    }
    function new(int seed);
        
        this.srandom(seed);
    endfunction
endclass
random_act act_rand;
random_strategy strategy_rand;
random_mode mode_rand;
random_date date_rand;
random_data_no data_no_rand;
random_stock stock_rand;
//================================================================
// initial
//================================================================
initial begin
    $readmemh(DRAM_p_r, golden_DRAM);

    act_rand = new(SEED);
    strategy_rand = new(SEED);
    mode_rand = new(SEED);
    date_rand = new(SEED);
    data_no_rand = new(SEED);
    stock_rand = new(SEED);


    reset_task;

    for (i_pat=0; i_pat<`PAT_NUM; i_pat++) begin
        input_task;
        wait_out_valid_task;
        calculate_ans_task;
        $display("inf.warn_msg = %d, inf.complete = %d", inf.warn_msg, inf.complete);
        $display("golden_warn_msg = %d, golden_complete = %d", golden_warn_msg, golden_complete);
        check_ans_task;
		$display("\033[0;34mPASS PATTERN NO.%4d, \033[m \033[0;32m Execution Cycle: %3d\033[m", i_pat, lat);
    end
    YOU_PASS_task;
    $finish;
end



//================================================================
// task
//================================================================
task reset_task; begin
    inf.rst_n = 1'b1;

    inf.sel_action_valid = 1'b0;
    inf.strategy_valid = 1'b0;
    inf.mode_valid = 1'b0;
    inf.date_valid = 1'b0;
    inf.data_no_valid = 1'b0;
    inf.restock_valid = 1'b0;
    inf.D = 'dx;

    #(1); inf.rst_n = 0;
    #(5); inf.rst_n = 1;
end
endtask


task input_task; begin
    @(negedge clk);
    inf.sel_action_valid = 1;
    act_rand.randomize();
    action_reg = act_rand.act_id;
    inf.D.d_act[0] = action_reg; 
    @(negedge clk); 
	inf.sel_action_valid = 0; 
    inf.D = 'bx;

    case (action_reg)
        Purchase: begin
            repeat($urandom_range(0,3))@(negedge clk);
            input_strategy_task;
            repeat($urandom_range(0,3))@(negedge clk);
            input_mode_task;
            repeat($urandom_range(0,3))@(negedge clk);
            input_date_task;
            repeat($urandom_range(0,3))@(negedge clk);
            input_data_no_task;
        end
        Restock: begin
            repeat($urandom_range(0,3))@(negedge clk);
            input_date_task;
            repeat($urandom_range(0,3))@(negedge clk);
            input_data_no_task;
            input_restock_task;
        end
        Check_Valid_Date: begin
            repeat($urandom_range(0,3))@(negedge clk);
            input_date_task;
            repeat($urandom_range(0,3))@(negedge clk);
            input_data_no_task;
        end
    endcase
end
endtask

task input_strategy_task; begin
    inf.strategy_valid = 1'd1;
    strategy_rand.randomize();
    strategy_reg = strategy_rand.strategy_id;
    inf.D.d_strategy[0] = strategy_reg;
    @(negedge clk); 
    inf.strategy_valid = 1'd0;
    inf.D = 'bx;
end
endtask
task input_mode_task; begin
    inf.mode_valid = 1'd1;
    mode_rand.randomize();
    mode_reg = mode_rand.mode_id;
    inf.D.d_mode[0] = mode_reg;
    @(negedge clk); 
    inf.mode_valid = 1'd0;
    inf.D = 'bx;
end
endtask
task input_date_task; begin
    inf.date_valid = 1'd1;
    date_rand.randomize();
    date_reg = date_rand.date_id;
    inf.D.d_date[0] = date_reg;
    @(negedge clk); 
    inf.date_valid = 1'd0;
    inf.D = 'bx;
end
endtask
task input_data_no_task; begin
    inf.data_no_valid = 1'd1;
    data_no_rand.randomize();
    data_reg = data_no_rand.data_no_id;
    inf.D.d_data_no[0] = data_reg;
    @(negedge clk); 
    inf.data_no_valid = 1'd0;
    inf.D = 'bx;
end
endtask

task input_restock_task; begin
    for (i = 0 ; i < 4 ; i++) begin
        repeat($urandom_range(0,3))@(negedge clk);
        inf.restock_valid = 1'd1;
        stock_rand.randomize();
        inf.D.d_stock[0]= stock_rand.stock_id;
        case (i)
            0    : stock_A = inf.D.d_stock[0];
            1    : stock_B = inf.D.d_stock[0];
            2    : stock_C = inf.D.d_stock[0];
            3    : stock_D = inf.D.d_stock[0]; 
        endcase
        @(negedge clk); 
        inf.restock_valid = 1'd0;
        inf.D = 'bx;
    end
end
endtask

task wait_out_valid_task; begin
  lat = -1; 
  while(inf.out_valid !== 1) begin 
  	lat = lat + 1;  
		if(lat == 1000) begin
            YOU_FAIL_task;
            $display("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display("                                                             PATTERN NO.%4d 	                                                              ", i_pat);
            $display("                                             The execution latency should not over 1000 cycles                                              ");
            $display("--------------------------------------------------------------------------------------------------------------------------------------------");
            $finish;
		end
	@(negedge clk);
  end
  total_lat = total_lat + lat;
end
endtask


task calculate_ans_task; begin
    addr = 65536 + 8 * data_reg;
     dram_out = {golden_DRAM[addr+7], golden_DRAM[addr+6], golden_DRAM[addr+5], golden_DRAM[addr+4], golden_DRAM[addr+3], golden_DRAM[addr+2], golden_DRAM[addr+1], golden_DRAM[addr]};
     dram_out_dir.Rose       = dram_out[63:52];
     dram_out_dir.Lily       = dram_out[51:40];
     dram_out_dir.M          = dram_out[39:32];
     dram_out_dir.Carnation  = dram_out[31:20];
     dram_out_dir.Baby_Breath= dram_out[19:8];
     dram_out_dir.D          = dram_out[7:0];

    // $display("DEBUG: action_reg = %0d", action_reg);
    // $display("DEBUG: data_reg = %0d", data_reg);
    // $display("DEBUG: date_reg.M = %0d", date_reg.M);
    // $display("DEBUG: date_reg.D = %0d", date_reg.D);
    // $display("DEBUG: strategy_reg = %0d, mode_reg = %0d", strategy_reg, mode_reg);
    // $display("DEBUG: After all cases, dram_out_dir.Rose = %0d", dram_out_dir.Rose);
    // $display("DEBUG: After all cases, dram_out_dir.Lily = %0d", dram_out_dir.Lily);
    // $display("DEBUG: After all cases, dram_out_dir.M = %0d", dram_out_dir.M);
    // $display("DEBUG: After all cases, dram_out_dir.D = %0d", dram_out_dir.D);
    // $display("DEBUG: After all cases, dram_out_dir.Carnation = %0d", dram_out_dir.Carnation);
    // $display("DEBUG: After all cases, dram_out_dir.Baby_Breath = %0d", dram_out_dir.Baby_Breath);
    // date_check = (date_reg.M < dram_out_dir.M) | ((date_reg.M == dram_out_dir.M) & (date_reg.D < dram_out_dir.D)) && action_reg != Restock  ;
    // overflow_flag = Lily_new[12] | Rose_new[12] | Carnation_new[12] | Baby_Breath_new[12];
    // warn_stock = ( (dram_out_dir.Rose < Rose_request) | (dram_out_dir.Lily < Lily_request) | (dram_out_dir.Carnation < Carnation_request) | (dram_out_dir.Baby_Breath < Baby_Breath_request));

    if (action_reg == Purchase) begin
        // $display("DEBUG: In Purchase case, strategy_reg = %0d, mode_reg = %0d", strategy_reg, mode_reg);
        Lily_request = 0;
        Rose_request = 0;
        Carnation_request = 0;
        Baby_Breath_request = 0;
         case (strategy_reg)
            Strategy_A: begin
                case (mode_reg)
                    Single: begin
                        Rose_request = 'd120;
                        // $display("DEBUG: In Single mode case, setting Rose_request to 120");
                    end
                    Group_Order: begin
                        Rose_request = 'd480;
                    end
                    Event: begin
                        Rose_request = 'd960;
                    end
                    default: begin
                        Rose_request = 0;
                    end
                endcase
            end
            Strategy_B: begin
                case (mode_reg)
                    Single: begin
                        Lily_request = 'd120;
                    end
                    Group_Order: begin
                        Lily_request = 'd480;
                    end
                    Event: begin
                        Lily_request = 'd960;
                    end
                    default: begin
                        Lily_request = 0;
                    end
                endcase
            end
            Strategy_C: begin
                case (mode_reg)
                    Single: begin
                        Carnation_request = 'd120;
                    end
                    Group_Order: begin
                        Carnation_request = 'd480;
                    end
                    Event: begin
                        Carnation_request = 'd960;
                    end
                    default: begin
                        Carnation_request = 0;
                    end
                endcase
            end
            Strategy_D: begin
                case (mode_reg)
                    Single: begin
                        Baby_Breath_request = 'd120;
                    end
                    Group_Order: begin
                        Baby_Breath_request = 'd480;
                    end
                    Event: begin
                        Baby_Breath_request = 'd960;
                    end
                    default: begin
                        Baby_Breath_request = 0;
                    end
                endcase
            end
            Strategy_E: begin
                case (mode_reg)
                    Single: begin
                        Rose_request = 'd60;
                        Lily_request = 'd60;
                    end
                    Group_Order: begin
                        Rose_request = 'd240;
                        Lily_request = 'd240;
                    end
                    Event: begin
                        Rose_request = 'd480;
                        Lily_request = 'd480;
                    end
                    default: begin
                        Rose_request = 'd0;
                        Lily_request = 'd0;
                    end
                endcase
            end
            Strategy_F: begin
                case (mode_reg)
                    Single: begin
                        Carnation_request = 'd60;
                        Baby_Breath_request = 'd60;
                    end
                    Group_Order: begin
                        Carnation_request = 'd240;
                        Baby_Breath_request = 'd240;
                    end
                    Event: begin
                        Carnation_request = 'd480;
                        Baby_Breath_request = 'd480;
                    end
                    default: begin
                        Carnation_request = 'd0;
                        Baby_Breath_request = 'd0;
                    end
                endcase
            end
            Strategy_G: begin
                case (mode_reg)
                    Single: begin
                        Carnation_request = 'd60;
                        Rose_request = 'd60;
                    end
                    Group_Order: begin
                        Carnation_request = 'd240;
                        Rose_request = 'd240;
                    end
                    Event: begin
                        Carnation_request = 'd480;
                        Rose_request = 'd480;
                    end
                    default: begin
                        Carnation_request = 'd0;
                        Rose_request = 'd0;
                    end
                endcase
            end
            Strategy_H: begin
                case (mode_reg)
                    Single: begin
                        Carnation_request = 'd30;
                        Baby_Breath_request = 'd30;
                        Rose_request = 'd30;
                        Lily_request = 'd30;
                    end
                    Group_Order: begin
                        Carnation_request = 'd120;
                        Baby_Breath_request = 'd120;
                        Rose_request = 'd120;
                        Lily_request = 'd120;
                    end
                    Event: begin
                        Carnation_request = 'd240;
                        Baby_Breath_request = 'd240;
                        Rose_request = 'd240;
                        Lily_request = 'd240;
                    end
                    default: begin
                        Carnation_request = 'd0;
                        Baby_Breath_request = 'd0;
                        Rose_request = 'd0;
                        Lily_request = 'd0;
                    end
                endcase
            end 
         endcase
        //  $display("DEBUG: After all cases, Rose_request = %0d", Rose_request);
        //  $display("DEBUG: After all cases, Lily_request = %0d", Lily_request);
        //  $display("DEBUG: After all cases, Carnation_request = %0d", Carnation_request);
        //  $display("DEBUG: After all cases, Baby_Breath_request = %0d", Baby_Breath_request);
        //  $display("DEBUG: After all cases, dram_out_dir.Rose = %0d", dram_out_dir.Rose);
        //  $display("DEBUG: After all cases, dram_out_dir.Lily = %0d", dram_out_dir.Lily);
        //  $display("DEBUG: After all cases, dram_out_dir.Carnation = %0d", dram_out_dir.Carnation);
        //  $display("DEBUG: After all cases, dram_out_dir.Baby_Breath = %0d", dram_out_dir.Baby_Breath);
        //  if (( (dram_out_dir.Rose < Rose_request) || (dram_out_dir.Lily < Lily_request) || (dram_out_dir.Carnation < Carnation_request) || (dram_out_dir.Baby_Breath < Baby_Breath_request))) begin
        //     golden_complete = 0;
        //     golden_warn_msg = Stock_Warn;
        //  end
         if ((date_reg.M < dram_out_dir.M) || ((date_reg.M == dram_out_dir.M) && (date_reg.D < dram_out_dir.D)))  begin
            golden_complete = 0;
            golden_warn_msg = Date_Warn;
         end
         else if (( (dram_out_dir.Rose < Rose_request) || (dram_out_dir.Lily < Lily_request) || (dram_out_dir.Carnation < Carnation_request) || (dram_out_dir.Baby_Breath < Baby_Breath_request))) begin
            golden_complete = 0;
            golden_warn_msg = Stock_Warn;
         end
        //  if (!(date_reg.M < dram_out_dir.M) || ((date_reg.M == dram_out_dir.M) && (date_reg.D < dram_out_dir.D)) && !( (dram_out_dir.Rose < Rose_request) | (dram_out_dir.Lily < Lily_request) | (dram_out_dir.Carnation < Carnation_request) | (dram_out_dir.Baby_Breath < Baby_Breath_request))) 
         else
         begin
            golden_complete = 1;
            golden_warn_msg = No_Warn;
            dram_in_dir.Rose       = dram_out_dir.Rose - Rose_request;
            dram_in_dir.Lily       = dram_out_dir.Lily - Lily_request;
            dram_in_dir.Carnation  = dram_out_dir.Carnation - Carnation_request;
            dram_in_dir.Baby_Breath= dram_out_dir.Baby_Breath - Baby_Breath_request;
            dram_in_dir.M          = dram_out_dir.M;
            dram_in_dir.D          = dram_out_dir.D;
            dram_in = {dram_in_dir.Rose, dram_in_dir.Lily,4'b0000 ,dram_in_dir.M, dram_in_dir.Carnation, dram_in_dir.Baby_Breath,3'b000 ,dram_in_dir.D};
            {golden_DRAM[addr+7], golden_DRAM[addr+6], golden_DRAM[addr+5], golden_DRAM[addr+4], golden_DRAM[addr+3], golden_DRAM[addr+2], golden_DRAM[addr+1], golden_DRAM[addr]} = dram_in;
         end
    end else if (action_reg == Restock) begin
        // calculate ans for Restock action
        golden_complete = 1;
        golden_warn_msg = No_Warn;
        
        Lily_new = dram_out_dir.Lily + stock_B;
        Rose_new = dram_out_dir.Rose + stock_A;
        Carnation_new = dram_out_dir.Carnation + stock_C;
        Baby_Breath_new = dram_out_dir.Baby_Breath + stock_D;
        if (Lily_new[12] || Rose_new[12] || Carnation_new[12] || Baby_Breath_new[12]) begin
            golden_complete = 0;
            golden_warn_msg = Restock_Warn;
        end
        dram_in_dir.M           = date_reg.M;
        dram_in_dir.D           = date_reg.D;
        dram_in_dir.Lily        = Lily_new[12]==1        ? 12'd4095 : Lily_new[11:0];
        dram_in_dir.Rose        = Rose_new[12]==1        ? 12'd4095 : Rose_new[11:0];
        dram_in_dir.Carnation   = Carnation_new[12]==1   ? 12'd4095 : Carnation_new[11:0];
        dram_in_dir.Baby_Breath = Baby_Breath_new[12]==1 ? 12'd4095 : Baby_Breath_new[11:0];
        dram_in = {dram_in_dir.Rose, dram_in_dir.Lily,4'b0000 ,dram_in_dir.M, dram_in_dir.Carnation, dram_in_dir.Baby_Breath,3'b000 ,dram_in_dir.D};
        {golden_DRAM[addr+7], golden_DRAM[addr+6], golden_DRAM[addr+5], golden_DRAM[addr+4], golden_DRAM[addr+3], golden_DRAM[addr+2], golden_DRAM[addr+1], golden_DRAM[addr]} = dram_in;
    end else if (action_reg == Check_Valid_Date) begin
        // calculate ans for Check_Valid_Date action
        if ((date_reg.M < dram_out_dir.M) || ((date_reg.M == dram_out_dir.M) && (date_reg.D < dram_out_dir.D))) begin
            golden_complete = 0;
            golden_warn_msg = Date_Warn;
        end else begin
            golden_complete = 1;
            golden_warn_msg = No_Warn;
        end
    end 
end
endtask


task check_ans_task; begin
   if(inf.out_valid ===1) begin 
    if(inf.complete!==golden_complete || inf.warn_msg!==golden_warn_msg)begin
        YOU_FAIL_task;
        $display("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display("                                                             PATTERN NO.%4d 	                                                              ", i_pat);
        $display("                                             The output warn_msg is wrong, please check it!                                              ");
        $display("--------------------------------------------------------------------------------------------------------------------------------------------");
        $finish;
    end
   end
@(negedge inf.out_valid);

end endtask




task YOU_PASS_task; begin
    $display("=======================");
    $display(" \033[0;32m ");
    $display(" Congratulations ");
    $display(" \033[m ");
    $display("=======================");
	$display("\033[37m                                  .$&X.      x$$x              \033[32m      :BBQvi.");
	$display("\033[37m                                .&&;.X&$  :&&$+X&&x            \033[32m     BBBBBBBBQi");
	$display("\033[37m                               +&&    &&.:&$    .&&            \033[32m    :BBBP :7BBBB.");
	$display("\033[37m                              :&&     &&X&&      $&;           \033[32m    BBBB     BBBB");
	$display("\033[37m                              &&;..   &&&&+.     +&+           \033[32m   iBBBv     BBBB       vBr");
	$display("\033[37m                             ;&&...   X&&&...    +&.           \033[32m   BBBBBKrirBBBB.     :BBBBBB:");
	$display("\033[37m                             x&$..    $&&X...    +&            \033[32m  rBBBBBBBBBBBR.    .BBBM:BBB");
	$display("\033[37m                             X&;...   &&&....    &&            \033[32m  BBBB   .::.      EBBBi :BBU");
	$display("\033[37m                             $&...    &&&....    &&            \033[32m MBBBr           vBBBu   BBB.");
	$display("\033[37m                             $&....   &&&...     &$            \033[32m i7PB          iBBBBB.  iBBB");
	$display("\033[37m                             $&....   &&& ..    .&x                        \033[32m  vBBBBPBBBBPBBB7       .7QBB5i");
	$display("\033[37m                             $&....   &&& ..    x&+                        \033[32m :RBBB.  .rBBBBB.      rBBBBBBBB7");
	$display("\033[37m                             X&;...   x&&....   &&;                        \033[32m    .       BBBB       BBBB  :BBBB");
	$display("\033[37m                             x&X...    &&....   &&:                        \033[32m           rBBBr       BBBB    BBBU");
	$display("\033[37m                             :&$...    &&+...   &&:                        \033[32m           vBBB        .BBBB   :7i.");
	$display("\033[37m                              &&;...   &&$...   &&:                        \033[32m             .7  BBB7   iBBBg");
	$display("\033[37m                               && ...  X&&...   &&;                                         \033[32mdBBB.   5BBBr");
	$display("\033[37m                               .&&;..  ;&&x.    $&;.$&$x;                                   \033[32m ZBBBr  EBBBv     YBBBBQi");
	$display("\033[37m                               ;&&&+   .+xx;    ..  :+x&&&&&&&x                             \033[32m  iBBBBBBBBD     BBBBBBBBB.");
	$display("\033[37m                        +&&&&&&X;..             .          .X&&&&&x                         \033[32m    :LBBBr      vBBBi  5BBB");
	$display("\033[37m                    $&&&+..                                    .:$&&&&.                     \033[32m          ...   :BBB:   BBBu");
	$display("\033[37m                 $&&$.                                             .X&&&&.                  \033[32m         .BBBi   BBBB   iMBu");
	$display("\033[37m              ;&&&:                                               .   .$&&&                x\033[32m          BBBX   :BBBr");
	$display("\033[37m            x&&x.      .+&&&&&.                .x&$x+:                  .$&&X         $+  &x  ;&X   \033[32m  .BBBv  :BBBQ");
	$display("\033[37m          .&&;       .&&&:                      .:x$&&&&X                 .&&&        ;&     +&.    \033[32m   .BBBBBBBBB:");
	$display("\033[37m         $&&       .&&$.                             ..&&&$                 x&& x&&&X+.          X&x\033[32m     rBBBBB1.");
	$display("\033[37m        &&X       ;&&:                                   $&&x                $&x   .;x&&&&:                       ");
	$display("\033[37m      .&&;       ;&x                                      .&&&                &&:       .$&&$    ;&&.             ");
	$display("\033[37m      &&;       .&X                                         &&&.              :&$          $&&x                   ");
	$display("\033[37m     x&X       .X& .                                         &&&.              .            ;&&&  &&:             ");
	$display("\033[37m     &&         $x                                            &&.                            .&&&                 ");
	$display("\033[37m    :&&                                                       ;:                              :&&X                ");
	$display("\033[37m    x&X                 :&&&&&;                ;$&&X:                                          :&&.               ");
	$display("\033[37m    X&x .              :&&&  $&X              &&&  X&$                                          X&&               ");
	$display("\033[37m    x&X                x&&&&&&&$             :&&&&$&&&                                          .&&.              ");
	$display("\033[37m    .&&    \033[38;2;255;192;203m      ....\033[37m  .&&X:;&&+              &&&++;&&                                          .&&               ");
	$display("\033[37m     &&    \033[38;2;255;192;203m  .$&.x+..:\033[37m  ..+Xx.                 :&&&&+\033[38;2;255;192;203m  .;......    \033[37m                             .&&");
	$display("\033[37m     x&x   \033[38;2;255;192;203m .x&:;&x:&X&&.\033[37m              .             \033[38;2;255;192;203m .&X:&&.&&.:&.\033[37m                             :&&");
	$display("\033[37m     .&&:  \033[38;2;255;192;203m  x;.+X..+.;:.\033[37m         ..  &&.            \033[38;2;255;192;203m &X.;&:+&$ &&.\033[37m                             x&;");
	$display("\033[37m      :&&. \033[38;2;255;192;203m    .......   \033[37m         x&&&&&$++&$        \033[38;2;255;192;203m .... ......: \033[37m                             && ");
	$display("\033[37m       ;&&                          X&  .x.              \033[38;2;255;192;203m .... \033[37m                               .&&;                ");
	$display("\033[37m        .&&x                        .&&$X                                          ..         .x&&&               ");
	$display("\033[37m          x&&x..                                                                 :&&&&&+         +&X              ");
	$display("\033[37m            ;&&&:                                                                     x&&$XX;::x&&X               ");
	$display("\033[37m               &&&&&:.                                                              .X&x    +xx:                  ");
	$display("\033[37m                  ;&&&&&&&&$+.                                  :+x&$$X$&&&&&&&&&&&&&$                            ");
	$display("\033[37m                       .+X$&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&$X+xXXXxxxx+;.                                   ");
end endtask

task YOU_FAIL_task; begin 
    $display("=======================");
    $display(" \033[0;31m ");
    $display(" Wrong Answer ");
    $display(" \033[m ");      
    $display("=======================");                                                                                                                  
	$display("\033[37m                                                                         x&&&&X  +&&&&&&+                                    ");
	$display("\033[37m                                                                      .&&&&$$&&&&&&+ .&&&&                                   ");
	$display("\033[37m                                                                     X&&&;   &&&&$     X&&&                                  ");
	$display("\033[31m i:..::::::i.      :::::         ::::    .:::.        \033[37m              &&&X.    &&&&..    .&&&;                                 ");
	$display("\033[31m BBBBBBBBBBBi     iBBBBBL       .BBBB    7BBB7        \033[37m             &&&X .   .&&&; .    .&&&;                                 ");
	$display("\033[31m BBBB.::::ir.     BBB:BBB.      .BBBv    iBBB:        \033[37m            X&&&...   +&&&. .    ;&&&:                                 ");
	$display("\033[31m BBBQ            :BBY iBB7       BBB7    :BBB:        \033[37m           ;&&&; ..  .&&&X  .    x&&&.                                 ");
	$display("\033[31m BBBB            BBB. .BBB.      BBB7    :BBB:        \033[37m           &&&$  ..  ;&&&+  .   .&&&$                                  ");
	$display("\033[31m BBBB:r7vvj:    :BBB   gBBs      BBB7    :BBB:        \033[37m          .&&&;  ..  $&&&. ..   ;&&&;                                  ");
	$display("\033[31m BBBBBBBBBB7    BBB:   .BBB.     BBB7    :BBB:        \033[37m          ;&&&:  .  .&&&x ..    X&&&                                   ");
	$display("\033[31m BBBB    ..    iBBBBBBBBBBBP     BBB7    :BBB:        \033[37m          +&&&.  .  +&&&: ..   .&&&x                                   ");
	$display("\033[31m BBBB          BBBBi7vviQBBB.    BBB7    :BBB.        \033[37m          +&&&.     $&&X. ..   X&&&.                                   ");
	$display("\033[31m BBBB         rBBB.      BBBQ   .BBBv    iBBB2ir777L7 \033[37m          +&&&.    :&&&:...   :&&&X                                    ");
	$display("\033[31m.BBBB        :BBBB       BBBB7  .BBBB    7BBBBBBBBBBB \033[37m          ;&&&.    x&&$       X&&&.                                    ");
	$display("\033[31m . ..        ....         ...:   ....    ..   ....... \033[37m          .&&&.   .&&&&+.    :&&&X                                     ");
	$display("\033[37m                                                        :+X&&.   X&X     X&&&X.    &&&&                                      ");
	$display("\033[37m                                                    ;$&&&&&&&:                     :Xx  ;&&&&&&$;                            ");
	$display("\033[37m                                                .$&&&&&X;.                                 ;x&&&&&&+   $&&&X:                ");
	$display("\033[37m                                              ;&&&&&x.                                         :$&&&&;  ;x&&&&&:             ");
	$display("\033[37m                                            :&&&&&.      .;X$$:                   ....            ;&&&&+    .x&&&x           ");
	$display("\033[37m                                           $&&&x.     .$&&&&&&x.                ;&&&&&&&$;          :&&&&;      $&&X         ");
	$display("\033[37m                                         :&&&&.     .$&&&;.                        ..;&&&&&$.         x&&&x      :&&&.       ");
	$display("\033[37m                                        .&&&&      :&&&.                                ;&&&&:         +&&&x       $&&+      ");
	$display("\033[37m                                        $&&$.     :&&X                                   .$&&&:         ;&&&+       &&&x     ");
	$display("\033[37m                                       x&&&.     .&&x                                   .  &&&&.         $&&&:      .&&&+    ");
	$display("\033[37m                                      :&&&:       ;+.      .:;:..              :&&&&&x     :&&&.         ;&&&x       +&&&    ");
	$display("\033[37m                                      X&&$               .&&&&&&&&.           X&&& .&&&+     .           .&&&$       :&&&;   ");
	$display("\033[37m                                      &&&;               $&&& +&&&X           $&&&&&&&&x                  $&&&:       &&&&   ");
	$display("\033[37m                                     +&&&.               X&&&&&&&&;           +&&&&x&&&.             .    x&&&;       x&&&:  ");
	$display("\033[37m                                     &&&X  \033[38;2;255;192;203m      ....   \033[37m .X&&&&&&;             .x&&&&X.\033[38;2;255;192;203m  ......    \033[37m  ..   ;&&&:       +&&&+  ");
	$display("\033[37m                                     X&&X  \033[38;2;255;192;203m  .  ;&$. .. \033[37m                .              \033[38;2;255;192;203m x&&:   ..  \033[37m       +&&&.       ;&&&+  ");
	$display("\033[37m         x&&&&&&&&&&&&&&&&&X         +&&$  \033[38;2;255;192;203m .. .&&&:&&&: . \033[37m        .:..&&&;          \033[38;2;255;192;203m .+&&&.x&&: . \033[37m       x&&&        :&&&X  ");
	$display("\033[37m      :;  xxxx;   .;;;.  .$&&.       :&&&. \033[38;2;255;192;203m  . .XX.x&&;  . \033[37m       .&&&&&&&&&X;       \033[38;2;255;192;203m ..&&:.$&&&.. \033[37m      .&&&X        ;&&&x  ");
	$display("\033[37m   ;&&&&:                  x&&:       $&&$ \033[38;2;255;192;203m        .:.. .  \033[37m         +&&&;x&&&x.      \033[38;2;255;192;203m .      .:.   \033[37m      ;&&&.        ;&&&;  ");
	$display("\033[37m :&&&&&&$        .+$&&&$Xx+X&&&.       &&&X\033[38;2;255;192;203m    ........    \033[37m         .&&&+            \033[38;2;255;192;203m    .......   \033[37m     .&&&x         X&&&   ");
	$display("\033[37m &&$   +&&&&&&&&&&&&&&&&&&&&&&&;       .&&&&.                        ;&&&&.                             X&&&          &&&$   ");
	$display("\033[37m &&x:&x  $&&&&&&X.          x&&         .&&&&+                         .:.                             X&&&          .&&&;   ");
	$display("\033[37m.&&$:&&+ :&&;x&&            $&&           :&&&&;                                                     ;&&&X           x&&&    ");
	$display("\033[37m X&&&:   .&&; &&+           ;&&;             $&&$.                                                  ;&&&             &&&+    ");
	$display("\033[37m  :&&&&$$&&&&$&&&            $&&.            ;&&+                                                    .&&;           x&&&.    ");
	$display("\033[37m     x&&&&&&&&&&&;           x&&&+           $&&.     .                                   ;&&+       .&&X          :&&&+     ");
	$display("\033[37m               +&&. .+x$&&&&&&&X:            &&&.   .&&$                                 x&&X  .&$   .&&X         +&&&;      ");
	$display("\033[37m                &&&&&&&&&&&X:                &&&.   .&&;                                .&&&+ ;&&&.  ;&&&+        &&$        ");
	$display("\033[37m                 ;+:                         +&&$. +&&X                                  $&&&&&&&;   X&&&&X                  ");
	$display("\033[37m                                              :&&&&&&&+.                                 .+&&&&;    :&&&&&&.   :&$           ");
	$display("\033[37m                                                     &&&;                                          .&&&&&&&    X&&+          ");
	$display("\033[37m                                                     .&&&:                                        .&&&&&&&     &&&&          ");
	$display("\033[37m                                                      :&&&;                                      ;&&&&&&&x    x&&&x          ");
	$display("\033[37m                                                   :&x  &&&$.                                   x&&&&&&&.    $&&&&$          ");
	$display("\033[37m                                                  +&&X    x&&&&;                              x&&&&&&&x    .&&&&&&&          ");
	$display("\033[37m                                                  &&&       x&&+    +$;      ..        ..;X&&&&&&&&x.     x&&&&&&&X          ");
	$display("\033[37m                                                  $&&       .&&&   :&&&.   .$&&:&&&&&&&&&&&&&$;          &&&&X &&&;          ");
	$display("\033[37m                                                  :&&&:      +&&&;;&&&&    X&&. x&&&&&$X:             .$&&&&: ;&&&           ");
	$display("\033[37m                                                   ;&&&$      .$&&&&&&&$:X&&$                       :&&&&&:  :&&&:           ");
	$display("\033[37m                                                    .&&&&&;          X&&&&X.                     +&&&&&X    +&&&.            ");
	$display("\033[37m                                                      .$&&&&&+                               x&&&&&&+      ;&&&.             ");
	$display("\033[37m                                                         :&&&&&&&&$+.            .;+xX$&&&&&&&&&X:        +&&&:              ");
	$display("\033[37m                                                           $&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&x:           +&&&&.               ");
	$display("\033[37m                                                             x&&&&;+X&&&&&&&&&&&$x.                  :$&&&&:                 ");
	$display("\033[37m                                                               &&&&$:                             .X&&&&x                    ");
	$display("\033[37m                                                                .&&&&&&&&&&+                   X&&&&&$.                      ");
	$display("\033[37m                                                                      .;&&&&&                  $&&&+                         ");
	$display("\033[37m                                                                         &&&&+.             :x&&&&:                          ");
	$display("\033[37m                                                                          X&&&&&&&&&&&&&&&&&&&&$                             ");
	$display("\033[37m                                                                             .;xX$&&&&&$$x+:                                 ");
end endtask
endprogram