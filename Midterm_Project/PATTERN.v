`ifdef RTL
`define CYCLE_TIME 15
`endif
`ifdef GATE
`define CYCLE_TIME 15
`endif


`include "../00_TESTBED/MEM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM.v"


module PATTERN #(parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32)(
	// CHIP IO 
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
  loc_y         	,
	cost			,
	busy         	,

	// AXI4 IO
         awid_s_inf,
       awaddr_s_inf,
       awsize_s_inf,
      awburst_s_inf,
        awlen_s_inf,
      awvalid_s_inf,
      awready_s_inf,
                    
        wdata_s_inf,
        wlast_s_inf,
       wvalid_s_inf,
       wready_s_inf,
                    
          bid_s_inf,
        bresp_s_inf,
       bvalid_s_inf,
       bready_s_inf,
                    
         arid_s_inf,
       araddr_s_inf,
        arlen_s_inf,
       arsize_s_inf,
      arburst_s_inf,
      arvalid_s_inf,
                    
      arready_s_inf, 
          rid_s_inf,
        rdata_s_inf,
        rresp_s_inf,
        rlast_s_inf,
       rvalid_s_inf,
       rready_s_inf 
             );

// ===============================================================
//                Input and Output Declaration
// ===============================================================

// << CHIP io port with system >>
output reg			  	clk,rst_n;
output reg			   	in_valid;
output reg [4:0] 		frame_id;
output reg [3:0]       	net_id;     
output reg [5:0]       	loc_x; 
output reg [5:0]       	loc_y; 
input [13:0]			cost;
input                   busy;       
 
// << AXI Interface wire connecttion for pseudo DRAM read/write >>
// (1) 	axi write address channel 
// 		src master
input wire [ID_WIDTH-1:0]      awid_s_inf;
input wire [ADDR_WIDTH-1:0]  awaddr_s_inf;
input wire [2:0]             awsize_s_inf;
input wire [1:0]            awburst_s_inf;
input wire [7:0]              awlen_s_inf;
input wire                  awvalid_s_inf;
// 		src slave
output wire                 awready_s_inf;
// -----------------------------

// (2)	axi write data channel 
// 		src master
input wire [DATA_WIDTH-1:0]   wdata_s_inf;
input wire                    wlast_s_inf;
input wire                   wvalid_s_inf;
// 		src slave
output wire                  wready_s_inf;

// (3)	axi write response channel 
// 		src slave
output wire  [ID_WIDTH-1:0]     bid_s_inf;
output wire  [1:0]            bresp_s_inf;
output wire                  bvalid_s_inf;
// 		src master 
input wire                   bready_s_inf;
// -----------------------------

// (4)	axi read address channel 
// 		src master
input wire [ID_WIDTH-1:0]      arid_s_inf;
input wire [ADDR_WIDTH-1:0]  araddr_s_inf;
input wire [7:0]              arlen_s_inf;
input wire [2:0]             arsize_s_inf;
input wire [1:0]            arburst_s_inf;
input wire                  arvalid_s_inf;
// 		src slave
output wire                 arready_s_inf;
// -----------------------------

// (5)	axi read data channel 
// 		src slave
output wire [ID_WIDTH-1:0]      rid_s_inf;
output wire [DATA_WIDTH-1:0]  rdata_s_inf;
output wire [1:0]             rresp_s_inf;
output wire                   rlast_s_inf;
output wire                  rvalid_s_inf;
// 		src master
input wire                   rready_s_inf;

// -------------------------//
//     DRAM Connection      //
//--------------------------//

pseudo_DRAM u_DRAM(

  	  .clk(clk),
  	  .rst_n(rst_n),

   .   awid_s_inf(   awid_s_inf),
   . awaddr_s_inf( awaddr_s_inf),
   . awsize_s_inf( awsize_s_inf),
   .awburst_s_inf(awburst_s_inf),
   .  awlen_s_inf(  awlen_s_inf),
   .awvalid_s_inf(awvalid_s_inf),
   .awready_s_inf(awready_s_inf),

   .  wdata_s_inf(  wdata_s_inf),
   .  wlast_s_inf(  wlast_s_inf),
   . wvalid_s_inf( wvalid_s_inf),
   . wready_s_inf( wready_s_inf),

   .    bid_s_inf(    bid_s_inf),
   .  bresp_s_inf(  bresp_s_inf),
   . bvalid_s_inf( bvalid_s_inf),
   . bready_s_inf( bready_s_inf),

   .   arid_s_inf(   arid_s_inf),
   . araddr_s_inf( araddr_s_inf),
   .  arlen_s_inf(  arlen_s_inf),
   . arsize_s_inf( arsize_s_inf),
   .arburst_s_inf(arburst_s_inf),
   .arvalid_s_inf(arvalid_s_inf),
   .arready_s_inf(arready_s_inf), 

   .    rid_s_inf(    rid_s_inf),
   .  rdata_s_inf(  rdata_s_inf),
   .  rresp_s_inf(  rresp_s_inf),
   .  rlast_s_inf(  rlast_s_inf),
   . rvalid_s_inf( rvalid_s_inf),
   . rready_s_inf( rready_s_inf) 
);

// ===============================================================
//                Parameter and Integer Declaration 
// ===============================================================
real CYCLE = `CYCLE_TIME;

integer patcount;
integer latency;
integer total_latency;
integer input_file, output_file, map_file, weight_file;
integer a, b, c, d, e;
integer i, j;

// ===============================================================
//                Reg and Wire Declaration
// ===============================================================
reg [4:0] PATNUM; // total pattern number = 32;
reg [3:0] net_num;
reg [31:0] start_addr, addr;
reg even;
reg [3:0] data;
reg [4:0] frame_id_reg, frame_id_reg_m, frame_id_reg_r, frame_id_reg_w;
reg [3:0] map    [0:4095];
reg [3:0] result [0:4095];
reg [3:0] weight [0:4095];
reg [3:0] out    [0:4095];
reg [13:0] cost_ans;
// ===============================================================
//                Clock
// ===============================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
//                Initial
//================================================================
initial begin
    rst_n    = 1'b1;
    in_valid = 1'b0;
    frame_id = 'bx;
    net_id   = 'bx;
    loc_x    = 'bx;
    loc_y    = 'bx;
    total_latency = 0;
    //$monitor(clk);
    force clk = 0; // corresponding to "release" in reset signal task
    reset_signal_task;

    input_file  = $fopen("../00_TESTBED/For_student/TEST_CASE/input_0.txt","r");
    $display("input_file",input_file);
	output_file = $fopen("../00_TESTBED/For_student/TEST_CASE/output_0.txt","r");
	$display("output_flie",output_file);
    map_file    = $fopen("../00_TESTBED/For_student/TEST_CASE/map_0.txt","r");
	$display("map_file= %d", map_file);
    weight_file = $fopen("../00_TESTBED/For_student/TEST_CASE/weight_0.txt","r");
    $display("weight_file= %d", weight_file);
    a = $fscanf(input_file, "%d", PATNUM);
   $display("PATNUM= %d", PATNUM);

    for (patcount=0; patcount<PATNUM; patcount=patcount+1) begin
        input_task;
        count_latency;
        print_map_task;
		golden_ans;
        consistent_check;
        //connectivity_check;
        cost_check;
        $display("a dsdfasdfsadf= %d", a);
		@(negedge clk);
    end
    you_pass_task;
end

// ===============================================================
//                Reset & Specifications
// ===============================================================
task reset_signal_task; begin
    #(0.5); rst_n = 1'b0;

    #(CYCLE/2.0);
    if ((busy !== 0) || (cost !== 0)) begin
        $display ("**************************************************************");
        $display ("*   busy and cost should be 0 after initial RESET at %4t     *",$time);
        $display ("**************************************************************");
        $finish;
    end

    #(10); rst_n = 1'b1;
    #(3);  release clk;
end endtask

task count_latency; begin
    latency = 0;
    while (busy !== 0) begin
        latency = latency + 1;
        if (latency >= 1000000) begin
            $display("***************************************************************");
            $display("*      The execution latency are over 1,000,000 cycles        *");
            $display("***************************************************************");
            $display("\n");
            print_map_task;
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

task print_map_task; begin
    start_addr = 32'h0001_0000+32'h800*frame_id_reg;
    addr = start_addr;
    even = 0;
    for (i=0; i<64; i=i+1) begin
        for (j=0; j<64; j=j+1) begin
            even = j % 2;
            if (even) data = u_DRAM.DRAM_r[addr][7:4];
            else      data = u_DRAM.DRAM_r[addr][3:0];
			out[i*64+j] = data;
            if (j==63) begin
				case(data)
					0 : $display("%h ", data);
					1 : $display("\033[0;33m%h \033[m", data);
					2 : $display("\033[0;34m%h \033[m", data);
					3 : $display("\033[0;35m%h \033[m", data);
					4 : $display("\033[0;36m%h \033[m", data);
					5 : $display("\033[0;31m%h \033[m", data);
					6 : $display("\033[0;32m%h \033[m", data);
					7 : $display("\033[0;38;5;10m%h \033[m", data);
					8 : $display("\033[0;38;5;80m%h \033[m", data);
					9 : $display("\033[0;41m%h \033[m", data);
					10: $display("\033[0;42m%h \033[m", data);
					11: $display("\033[0;43m%h \033[m", data);
					12: $display("\033[0;44m%h \033[m", data);
					13: $display("\033[0;45m%h \033[m", data);
					14: $display("\033[0;46m%h \033[m", data);
					15: $display("\033[0;47m%h \033[m", data);
				endcase
			end
            else begin
				case(data)
					0 : $write  ("%h ", data);
					1 : $write  ("\033[0;33m%h \033[m", data);
					2 : $write  ("\033[0;34m%h \033[m", data);
					3 : $write  ("\033[0;35m%h \033[m", data);
					4 : $write  ("\033[0;36m%h \033[m", data);
					5 : $write  ("\033[0;31m%h \033[m", data);
					6 : $write  ("\033[0;32m%h \033[m", data);
					7 : $write  ("\033[0;38;5;10m%h \033[m", data);
					8 : $write  ("\033[0;38;5;80m%h \033[m", data);
					9 : $write  ("\033[0;41m%h \033[m", data);
					10: $write  ("\033[0;42m%h \033[m", data);
					11: $write  ("\033[0;43m%h \033[m", data);
					12: $write  ("\033[0;44m%h \033[m", data);
					13: $write  ("\033[0;45m%h \033[m", data);
					14: $write  ("\033[0;46m%h \033[m", data);
					15: $write  ("\033[0;47m%h \033[m", data);
				endcase
			end
            if (even) addr = addr + 32'h1;
            else      addr = addr;
        end
    end
	$display("");
    //$finish;
end endtask
// ===============================================================
//                Input Signal
// ===============================================================
task input_task; begin
    // next input pattern will come in 3 cycles after "busy" falls
    repeat(3) @(negedge clk);

    // input start
    in_valid = 1'b1;
    b = $fscanf(input_file, "%d %d", frame_id, net_num);
	frame_id_reg = frame_id;
    for (i=0; i<net_num; i=i+1) begin
        if (busy !== 0) begin
          $display("***************************************************************");
          $display("*       busy should not be raised when in_valid is high       *");
          $display("***************************************************************");
          repeat(2)@(negedge clk);
          $finish;
        end
        c = $fscanf(input_file, "%d", net_id);     //generate case
		//c = $fscanf(input_file, "%d", net_id);   //*****conor*****
		//net_id = 0;                              //*****case *****
        for (j=0; j<2; j=j+1) begin
            if (j==0) d = $fscanf(input_file, "%d %d", loc_x, loc_y);
            else      e = $fscanf(input_file, "%d %d", loc_x, loc_y);
            @(negedge clk);
        end
    end
    in_valid = 1'b0;
    frame_id = 'bx;
    net_id   = 'bx;
    loc_x    = 'bx;
    loc_y    = 'bx;
	@(negedge clk);
    // input finish
end endtask


//================================================================
//                Verification
//================================================================
task golden_ans; begin
	cost_ans = 0;
	a = $fscanf(map_file, "%d", frame_id_reg_m);
    a = $fscanf(output_file, "%d", frame_id_reg_r);
	a = $fscanf(weight_file, "%d", frame_id_reg_w);
    for (i=0; i<4096; i=i+1) begin
        b = $fscanf(map_file,    "%d", map[i]);
		b = $fscanf(output_file, "%d", result[i]);
		b = $fscanf(weight_file, "%d", weight[i]);
		if(map[i]!==result[i]) begin
			cost_ans = cost_ans + weight[i];
		end
    end
end endtask

task consistent_check; begin
    for (i=0; i<4096; i=i+1) begin
        if(out[i]!==result[i]) begin
			$display("***************************************************************");
			$display("*                            map error                        *");
			$display("*                  Your execution cycles = %5d cycles       *", latency);
			$display("***************************************************************");
			repeat(2)@(negedge clk);
			$finish;
		end
    end
end endtask

task cost_check; begin
    if(cost!==cost_ans) begin
		display_fail;
        $display ("-------------------------------------------------------------------");
        $display ("                            PATTERN NO.%4d 	                      ", patcount);
        $display ("             answer should be : %d , your answer is : %d           ", cost_ans, cost);
        $display ("-------------------------------------------------------------------");
        repeat(2)@(negedge clk);
        $finish ;
	end else $display("\033[0;34mPASS PATTERN NO.%3d,\033[m \033[0;32mexecution cycle : %3d\033[m", patcount, latency);
end endtask

//================================================================
//                Simulation Result
//================================================================
task display_fail; begin
        $display("\n");
        $display("\n");
        $display("        ----------------------------               ");
        $display("        --                        --       |\__||  ");
        $display("        --  OOPS!!                --      / X,X  | ");
        $display("        --                        --    /_____   | ");
        $display("        --  \033[0;31mSimulation Failed!!\033[m   --   /^ ^ ^ \\  |");
        $display("        --                        --  |^ ^ ^ ^ |w| ");
        $display("        ----------------------------   \\m___m__|_|");
        $display("\n");
end endtask

task you_pass_task; begin
        $display("\n");
        $display("\n");
        $display("        ----------------------------               ");
        $display("        --                        --       |\__||  ");
        $display("        --  Congratulations !!    --      / O.O  | ");
        $display("        --                        --    /_____   | ");
        $display("        --  \033[0;32mSimulation PASS!!\033[m     --   /^ ^ ^ \\  |");
        $display("        --                        --  |^ ^ ^ ^ |w| ");
        $display("        ----------------------------   \\m___m__|_|");
        $display("\n");
        $display("       Your execution cycles = %5d cycles        ", total_latency);
	    $display("       Your clock period = %.1f ns        	   ", CYCLE);
	    $display("       Your total latency = %.1f ns              ", total_latency*CYCLE);
        $display("\n");
        $finish;
end endtask

endmodule


