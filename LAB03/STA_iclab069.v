
/**************************************************************************/
// Copyright (c) 2025, OASIS Lab
// MODULE: STA
// FILE NAME: STA.v
// VERSRION: 1.0
// DATE: 2025/02/26
// AUTHOR: Yu-Hao Cheng, NYCU IEE
// DESCRIPTION: ICLAB 2025 Spring / LAB3 / STA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module STA(
	//INPUT
	rst_n,
	clk,
	in_valid,
	delay,
	source,
	destination,
	//OUTPUT
	out_valid,
	worst_delay,
	path
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input				rst_n, clk, in_valid;
input		[3:0]	delay;
input		[3:0]	source;
input		[3:0]	destination;

output reg			out_valid;
output reg	[7:0]	worst_delay;
output reg	[3:0]	path;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
parameter IDLE      = 3'd0;
parameter INPUT     = 3'd1;
parameter KAHN      = 3'd2;
parameter LONGEST   = 3'd3;
parameter STACK    = 3'd4;
parameter WAIT    = 3'd5;
parameter OUTPUT    = 3'd6;
integer k;
integer j;
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [3:0] node_delay [0:15];
reg [2:0] current_state, next_state;
reg [4:0] counter;
reg [4:0] counter_kahn;
reg [4:0] counter_long;
reg [4:0] counter_stack;
reg [3:0] edge_source [0:31];
reg [3:0] edge_dest [0:31];
reg [3:0] degree_number [16];//4
reg [3:0] degree_number_comb [16];//4
reg topo_complete [16];//1
reg topo_complete_comb [16];//1 
reg [3:0 ]topo_order [16];
reg [7:0] road [16];
reg [7:0] road_comb [16];
reg [3:0] pred [16];//4
reg [3:0] pred_comb [16];//4
reg [3:0] u_source,s;
reg [3:0] stack_comb [16];
reg [3:0] stack [16];
reg [3:0] path_reg;//4
reg [3:0] path_comb;
reg verify [16];
reg [7:0] new_road [16];
//=======================================================
// FSML
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
                next_state = KAHN;
            else
                next_state = INPUT;
        end
        KAHN: begin
            if (counter_kahn == 'd15)
                next_state = LONGEST;
            else
                next_state = KAHN;
        end
        LONGEST: begin
            if (counter_long == 'd15)
                next_state = STACK;
            else
                next_state = LONGEST;
        end
        STACK: begin
            if (path_reg == 0) 
                next_state = WAIT;
            else   
                next_state = STACK;
        end
        WAIT: begin
                next_state = OUTPUT;
        end
        OUTPUT: begin
            if (path == 1)
                next_state = IDLE;
            else
                next_state = OUTPUT;
        end

        default: next_state = IDLE;
    endcase
end

// //=======================================================
// // initial
// //=======================================================

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter <= 0;
	end
    else if (next_state== IDLE) begin
        counter <= 0;
    end
	else if (in_valid && counter <16) begin
		counter <= counter + 1;
	end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        node_delay[15] <= 2'b00;
    end 
    else if (in_valid && counter <16 ) begin
        node_delay[15] <= delay;
    end
	else begin
        node_delay[15] <= node_delay[15];
    end
end
genvar i;
generate
    for (i = 0; i < 15; i = i + 1) begin
            always @(posedge clk) begin
                if (in_valid && counter <16) begin
                    node_delay[i] <= node_delay[i+1];
                end
         end 
    end
endgenerate 

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        edge_source[31] <= 2'b00;
    end 
	else if (in_valid) begin
        edge_source[31] <= source;
    end
end
generate
    for (i = 0; i < 31; i = i + 1) begin
            always @(posedge clk) begin
                if (in_valid) begin
                    edge_source[i] <= edge_source[i+1];
                end
         end 
    end
endgenerate 

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        edge_dest[31] <= 2'b00;
    end 
	else if (in_valid) begin
        edge_dest[31] <= destination;
    end
end
generate
    for (i = 0; i < 31; i = i + 1) begin
            always @(posedge clk) begin
                if (in_valid) begin
                    edge_dest[i] <= edge_dest[i+1];
                end
         end 
    end
endgenerate 

//---------------------------------------------------------------------
//   topology sort  Khan's alogorithms
//---------------------------------------------------------------------
generate
    for (i = 0; i < 16; i = i + 1) begin
            always @(posedge clk  or negedge rst_n)begin
                if (!rst_n) begin
                    degree_number[i] <= 0;
                end
                else if (current_state==IDLE) begin
                    degree_number[i] <= 0;
                end
                else if (current_state == INPUT) begin
                    if (edge_dest[31] == i  && i!=0) begin
                        degree_number[i] <= degree_number[i] + 1;
                    end
                end
                else if (current_state == KAHN) begin
                    degree_number[i] <= degree_number_comb[i];
                end

         end 
    end
endgenerate 

generate
    for (i = 0; i < 16; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    topo_complete[i] <= 0;
                end
                else if (next_state == IDLE) begin
                    topo_complete[i] <= 0;
                end
                else if (current_state == KAHN) begin
                    topo_complete[i] <= topo_complete_comb[i]|topo_complete[i];
                end
         end 
    end
endgenerate 

always @ (posedge clk  or negedge rst_n) begin
    if (!rst_n) begin
        counter_kahn <= 0;
    end
    else if (current_state== IDLE) begin
        counter_kahn <= 0;
    end
	else if (current_state == KAHN) begin
		counter_kahn <= counter_kahn + 1;
	end
end

always @(posedge clk or negedge rst_n) begin
    if  (!rst_n) begin
        for (k = 0 ; k<16 ; k=k+1) begin
            topo_order[k] <= 0;
        end
    end
    else if (current_state == IDLE) begin
        for (k = 0 ; k<16 ; k=k+1) begin
            topo_order[k] <= 0;
        end
    end
    else if (current_state == KAHN) begin
        topo_order [counter_kahn] <= s;
    end
end 

always @(*) begin
    for (k = 0; k < 16; k = k + 1) begin
        topo_complete_comb[k] = topo_complete[k];
    end
    for (k = 0; k < 16; k = k + 1) begin
       degree_number_comb[k] = degree_number[k];
    end
    s=0;
    if (current_state == KAHN) begin
        for (k = 15; k >= 0; k = k - 1) begin
            if ( degree_number[k] == 0 && topo_complete[k] !=1 ) begin
                s=k;
            end
        end
        topo_complete_comb[s] = 1;
        // $display(" current_State= %d s= %d", current_state ,s);
        for (j=0; j < 32;j++) begin
            if (edge_source[j] == s)begin
                degree_number_comb[edge_dest[j]] = degree_number[edge_dest[j]] - 1;
            end 
        end
    end
end
//---------------------------------------------------------------------
//   find longest path 
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n ) begin
        for (k = 0 ; k<16 ; k=k+1) begin
            road[k] <= 0;
        end
    end
    else if (current_state == IDLE) begin
        for (k = 0 ; k<16 ; k=k+1) begin
            road[k] <= 0;
        end
    end
    else if (current_state == KAHN) begin
            road[0] <= 1;
    end
    else if (current_state == LONGEST) begin
        for (k = 0; k < 16; k = k + 1 ) begin
            road[k] <= road_comb[k];
        end
    end

end 

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_long <= 0;
    end
    else if (current_state== IDLE) begin
            counter_long <= 0;
        end
	else if (current_state ==LONGEST) begin
		counter_long <= counter_long + 1;
	end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0 ; k<16 ; k=k+1) begin
            pred[k] <= 0;
        end
    end
    else if (current_state== IDLE) begin
        for (k = 0 ; k<16 ; k=k+1) begin
            pred[k] <= 0;
        end
    end
	else if (current_state ==LONGEST) begin
		for (k = 0 ; k<16 ; k=k+1) begin
            pred[k] <= pred_comb[k];
        end
	end
end
 
always @(*) begin
    for (k = 0; k < 16; k = k + 1 ) begin
        road_comb[k] = road[k];
    end
  
    for (k = 0; k < 16; k = k + 1 ) begin
        pred_comb[k] = pred[k];
    end
    
    for (k=0; k < 16; k = k + 1) begin
        new_road [k] = 0;
        verify [k] = 0;
    end
    u_source = topo_order[counter_long];
    if (current_state == LONGEST) begin
        if (road[u_source] != 0)   begin
            for (j=0; j < 32; j=j+1) begin
                if (edge_source[j] == u_source) begin
                    verify[edge_dest[j]]=1;
                    new_road[edge_dest[j]]=road[u_source] + node_delay[u_source];
                end
            end
        end
        for (k=0; k<16 ; k =k+1)begin
            if(road[k]<= new_road[k] && verify[k])begin
                road_comb[k] = new_road[k];
                pred_comb    [k] = u_source;
            end
        end

    end




end
//---------------------------------------------------------------------
//   STACK
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if   (!rst_n) begin
        counter_stack <= 0;
    end
    else if (current_state==IDLE) begin
        counter_stack <=0;
    end
    else if (current_state == STACK && path_reg!=0) begin
        counter_stack <= counter_stack + 1;
    end
    else if (next_state == OUTPUT && counter_stack!=0) begin
        counter_stack <= counter_stack - 1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        path_reg <=0;
    end
    else if (current_state==IDLE) begin
        path_reg <=0;
    end
    else if (current_state == LONGEST) begin
        path_reg <= 1;
    end
    else if (current_state == STACK) begin
        path_reg <= path_comb;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k=0 ; k<16 ; k++) begin
            stack [k] <= 0;
        end
    end
    else if (current_state==IDLE) begin
        for (k=0 ; k<16 ; k++) begin
            stack [k] <= 0;
        end
    end
    else if (current_state == STACK) begin
        for (k=0 ; k<16 ; k++) begin
            stack [k] <= stack_comb[k];
        end
    end
end

always @ (*)begin
    for (k=0 ; k<16 ; k++) begin
        stack_comb [k] = stack[k];
    end
    stack_comb[counter_stack] = path_reg;
    path_comb = pred[path_reg];

end
//---------------------------------------------------------------------
//   Wait
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        worst_delay<=0;
    end
    else if (current_state == WAIT) begin
        worst_delay <= road[1] + node_delay[1] -1 ;
    end
    else begin
        worst_delay<=0;
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        path<=0;
    end
    else if (next_state == OUTPUT) begin
        path <=  stack[counter_stack];
    end
    else begin
        path<=0;
    end
end




always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <=0;
	end
	else if (next_state == OUTPUT)begin
        out_valid <= 1;
	end
    else begin
        out_valid <= 0;
    end
end

endmodule

