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

`define CYCLE_TIME      50.0
`define SEED_NUMBER     28825252
`define PATTERN_NUMBER 100

module PATTERN(
    //Output Port
    clk,
    rst_n,

    in_valid,
    in_str,
    q_weight,
    k_weight,
    v_weight,
    out_weight,

    //Input Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output  logic        clk, rst_n, in_valid;
output  logic[31:0]  in_str;
output  logic[31:0]  q_weight;
output  logic[31:0]  k_weight;
output  logic[31:0]  v_weight;
output  logic[31:0]  out_weight;

input           out_valid;
input   [31:0]  out;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;

parameter PATTERN_NUMBER = 100;

integer patcount;
integer instr_file, kweight_file, qweight_file, vweight_file, outweight_file, ans_file;
integer total_latency, pattern_number_now;
integer a,wait_val_time;
//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
wire [31:0] diff;
wire [7:0] status_sub;
reg [31:0] golden_out, diff_ans;
real trans_out, trans_golden_out;;

//================================================================
// clock
//================================================================

always #(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//---------------------------------------------------------------------
//   Pattern_Design
//---------------------------------------------------------------------
always @(negedge clk) begin
    if(out_valid === 0) begin 
        if(out !== 0) begin
            print_fail_usagi;
            $display("**************************************************************");
            $display("*   Output signal should be 0 when out_valid is low          *");
            $display("**************************************************************");
            $finish;
        end
    end
end

real xxx;

initial begin

	// xxx = $bitstoshortreal(32'b01000000101000000000000000000000);
	// #100
	// $finish;

    instr_file  = $fopen("../00_TESTBED/input.txt", "r");
    kweight_file  = $fopen("../00_TESTBED/kweight.txt", "r");
    qweight_file  = $fopen("../00_TESTBED/qweight.txt", "r");
    vweight_file  = $fopen("../00_TESTBED/vweight.txt", "r");
    outweight_file  = $fopen("../00_TESTBED/outweight.txt", "r");
    ans_file  = $fopen("../00_TESTBED/ans.txt", "r");
	

    if (instr_file == 0) begin
        $display("Failed to open input.txt");
        $finish;
    end
    if (qweight_file == 0) begin
        $display("Failed to open qweight.txt");
        $finish;
    end
    if (kweight_file == 0) begin
        $display("Failed to open kweight.txt");
        $finish;
    end
    if (vweight_file == 0) begin
        $display("Failed to open vweight.txt");
        $finish;
    end
    if (outweight_file == 0) begin
        $display("Failed to open outweight.txt");
        $finish;
    end
    if (ans_file == 0) begin
        $display("Failed to open ans.txt");
        $finish;
    end

	force clk = 0;
	rst_n = 1'b1;
	in_valid = 1'b0;
    total_latency = 0;
	
	
    #(3);		release clk;

    reset_signal_task;

    for(patcount=0; patcount<PATTERN_NUMBER; patcount=patcount+1) begin

		$display("pattern number = %d", patcount);

		input_data_task;
		wait_outvalid_task;
		check_ans_task;
	    $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",patcount ,wait_val_time);
	end

    print_pass_usagi;
	$finish;

end



//---------------------------------------------------------------------
//    Task
//---------------------------------------------------------------------
task reset_signal_task; begin
  #(0.5);	rst_n=0;
  #(CYCLE/2);
  if((out_valid !== 0)||(out !== 0)) 
  begin
    print_fail_usagi;
    $display("**************************************************************");
    $display("*   Output signal should be 0 after initial RESET at %4t     *",$time);
    $display("**************************************************************");
    $finish;
  end
  #(10);	rst_n=1;
  #(3);		release clk;
end endtask

task input_data_task; begin
	repeat(2)@(negedge clk);

    a = $fscanf(instr_file, "%d", pattern_number_now); 
    a = $fscanf(qweight_file, "%d", pattern_number_now);
    a = $fscanf(kweight_file, "%d", pattern_number_now);
    a = $fscanf(vweight_file, "%d", pattern_number_now);
    a = $fscanf(outweight_file, "%d", pattern_number_now);
	in_valid = 1'b1;
    for(integer i=0; i<20; i+=1) begin
        if(i >= 0 && i<16) begin
            a = $fscanf(instr_file, "%b", in_str); 
            a = $fscanf(qweight_file, "%b", q_weight);
            a = $fscanf(kweight_file, "%b", k_weight);
            a = $fscanf(vweight_file, "%b", v_weight);
            a = $fscanf(outweight_file, "%b", out_weight);
        end
        else if(i >= 16 && i < 20) begin
            a = $fscanf(instr_file, "%b", in_str); 
            q_weight= 32'bx;
            k_weight= 32'bx;
            v_weight= 32'bx;
            out_weight= 32'bx;
            
        end
        else begin
            in_str = 32'bx;
            q_weight= 32'bx;
            k_weight= 32'bx;
            v_weight= 32'bx;
            out_weight= 32'bx;
        end
        @(negedge clk);
    end
	
	in_valid = 1'b0;
    in_str = 32'bx;
    q_weight= 32'bx;
    k_weight= 32'bx;
    v_weight= 32'bx;
    out_weight= 32'bx;

end endtask

task wait_outvalid_task; begin
  wait_val_time = -1; 
  while(out_valid !== 1) begin 
  	wait_val_time = wait_val_time + 1;  
		if(wait_val_time > 200) begin
				print_fail_usagi;
				$display("********************************************************");     
                $display("*  The execution latency exceeded 200 cycles at %8t   *", $time);
                $display("********************************************************");
                repeat (2) @(negedge clk);
                $finish;
			end
	@(negedge clk);
  end
  total_latency = total_latency + wait_val_time;
end endtask 



task check_ans_task; begin
    a = $fscanf(ans_file, "%d", pattern_number_now);
    for(integer i=0; i<20; i+=1) begin
        a = $fscanf(ans_file, "%b", golden_out);
        trans_out = $bitstoshortreal(out);
        trans_golden_out = $bitstoshortreal(golden_out);

        diff_ans = (trans_golden_out - trans_out)/trans_golden_out;
        if (diff_ans < 0) begin
            diff_ans = -diff_ans;
        end

        if(diff_ans >= 0.0000001) begin
            print_fail_usagi;
		    $display ("--------------------------------------------------------------------");
		    $display ("                     PATTERN #%d  FAILED!!!                         ",patcount);
		    $display ("                      Ans: %b, Yours: %b                            ",golden_out, out);		
		    $display ("                           Error: %d                                ", diff_ans);		
		    $display ("--------------------------------------------------------------------");
		    repeat(2) @(negedge clk);		
		    $finish;
        end
        @(negedge clk);
    end
end endtask









task print_pass_usagi; begin
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
    $display("**************************************************");
	$display("                  Congratulations!                ");
	$display("              execution cycles = %7d", total_latency);
	$display("              clock period = %4fns", CYCLE);
	$display("**************************************************");
end endtask

task print_fail_usagi; begin                                                                                                                         
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
    $display("                  JGS MOTHER FUCKER !                ");
    $display("                  JGS MOTHER FUCKER !                ");
    $display("                  JGS MOTHER FUCKER !                ");
end endtask

endmodule