module MAZE(
    // input
    input clk,
    input rst_n,
	input in_valid,
	input [1:0] in,

    // output
    output reg out_valid,
    output reg [1:0] out
);
// --------------------------------------------------------------
// Reg & Wire
// --------------------------------------------------------------
reg  [1:0] maze [0:16][0:16];
reg [1:0] current_state, next_state;
//FSM
parameter IDLE= 2'b00 ; 
parameter INPUT= 2'b01 ;
parameter OUT = 2'b10 ;
//DIRECTION
parameter LEFT= 2'b10 ;
parameter UP= 2'b11 ;
parameter RIGHT = 2'b00 ;
parameter DOWN = 2'b01 ;

reg[1:0] direction, direction_next ;
reg sword_possess_comb, sword_possess ;
reg [5:0] location_x, location_y, location_x_next, location_y_next;
reg [3:0] situation;
reg [1:0] right_cell;
// ------------------------------------------
// Design
// --------------------------------------------------------------
//=======================================================
// INPUT
//=======================================================
always @(posedge clk) begin
    if (in_valid) begin
        maze[16][16] <= in;
    end
end
genvar i, j;
generate
    for (i = 0; i < 17; i = i + 1) begin
        for (j = 0; j < 16; j = j + 1) begin
            always @(posedge clk) begin
                if (in_valid) begin
                    maze[i][j] <= maze[i][j+1];
                end
            end
        end
    end
endgenerate
generate
    for (i = 0; i < 16; i = i + 1) begin
            always @(posedge clk) begin
                if (in_valid) begin
                    maze[i][16] <= maze[i+1][0];
                end
         end 
    end
endgenerate   
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
always@(*) begin : fsm
	case (current_state)
		IDLE:begin
			if(in_valid)begin
				next_state = INPUT;
			end
			else begin
				next_state = IDLE;
			end
		end 
		INPUT:begin
			if(!in_valid)begin
				next_state = OUT;
			end
			else begin
				next_state = INPUT;
			end
		end
		OUT:begin
            if(location_x_next=='d16 && location_y_next == 'd16)begin
                next_state = IDLE;
			end
            else begin
                next_state = OUT;
            end
        end
		default:
			next_state = IDLE; 
	endcase
end
// //=======================================================
// // initial
// //=======================================================
always @ (posedge clk) begin
	if (current_state == OUT)begin

		direction <= direction_next;
		location_x <= location_x_next;
		location_y <= location_y_next;
		sword_possess  <= sword_possess_comb;
	end
	else begin
		direction <= 0;
		location_x <= 0;
		location_y <= 0;
		sword_possess <= (maze[0][0] == 'd2)? 'd1 :0;
	end
end
always @(*) begin
	right_cell = maze[location_x][location_y+1];
end

// //=======================================================
// // OUTPUT
// //=======================================================
always @ (*)begin
	location_y_next   = 0;
	location_x_next = 0 ;
	sword_possess_comb = 0;
	direction_next = 0;
	
			// 	TOP_LEFT_CONER 
			if (location_x == 'd0 && location_y == 'd0) begin
					
					case(direction)
						UP : begin
							if	((right_cell != 2'b01) && (right_cell != 2'b11 || (sword_possess))) begin
								location_y_next   = location_y +1;
								location_x_next = location_x ;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
							else begin//
								location_x_next   = location_x+1;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
						end
						LEFT : begin
							if ((maze[location_x+1][location_y] != 2'b01) && (maze[location_x+1][location_y] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
							else begin
								location_x_next   = location_x;
								location_y_next   = location_y + 1;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
						end
						RIGHT : begin
							if	((right_cell != 2'b01) && (right_cell != 2'b11 || sword_possess)) begin
								location_y_next   = location_y +1;
								location_x_next = location_x ;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
							else begin
								location_x_next   = location_x+1;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
						end
						
					endcase
			end
				// TOP_RIGHT_CONER 
			else if (location_x == 'd0 && location_y == 'd16) begin
					case (direction)
						UP : begin
							if ((maze[location_x][location_y-1] != 2'b01) && (maze[location_x][location_y-1] != 2'b11 || sword_possess))begin
								location_y_next   = location_y - 1;
								location_x_next = location_x;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
							else begin
								location_x_next   = location_x + 1;
								location_y_next   = location_y;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
						end 
						RIGHT : begin
							if ((maze[location_x+1][location_y] != 2'b01) && (maze[location_x+1][location_y] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
							else begin
								location_x_next   = location_x ;
								location_y_next   = location_y - 1;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
						end
					endcase
			end
				// BOTTOM_LEFT_CONER 
			else if (location_x == 'd16  && location_y == 'd0) begin
					case (direction)
						DOWN : begin
							if ((right_cell != 2'b01) && (right_cell != 2'b11 || sword_possess)) begin
								location_y_next   = location_y + 1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
							else begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
						end 
						LEFT : begin
							if ((maze[location_x-1][location_y] != 2'b01) && (maze[location_x-1][location_y] != 2'b11 || sword_possess)) begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
							else begin
								location_y_next   = location_y +1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
						end
					endcase
			end
				// TOP_SLIDE
				else if (location_x == 'd0) begin
					case (direction)
						UP : begin
							if ((maze[location_x][location_y-1] != 2'b01) && (maze[location_x][location_y-1] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y - 1;
								location_x_next = location_x;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
							else if ((right_cell != 2'b01) && (right_cell != 2'b11 || sword_possess)) begin
								location_y_next   = location_y +1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
							else begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
						end 
						LEFT : begin
							if ((maze[location_x+1][location_y] != 2'b01) && (maze[location_x+1][location_y] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
							else if ((maze[location_x][location_y-1] != 2'b01) && (maze[location_x][location_y-1] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y - 1;
								location_x_next = location_x;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
							else begin
								location_y_next   = location_y +1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
						end
						RIGHT : begin
							if ((right_cell != 2'b01) && (right_cell != 2'b11 || sword_possess)) begin
								location_y_next   = location_y +1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
							else if ((maze[location_x+1][location_y] != 2'b01) && (maze[location_x+1][location_y] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
							else begin
								location_y_next   = location_y - 1;
								location_x_next = location_x;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
						end
					endcase
				end
				// BOTTOM_SLIDE
				else if (location_x == 'd16) begin
					case (direction)
						DOWN : begin
							if ((right_cell != 2'b01) && (right_cell != 2'b11 || sword_possess)) begin
								location_y_next   = location_y +1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
							else if ((maze[location_x][location_y-1] != 2'b01) && (maze[location_x][location_y-1] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y - 1;
								location_x_next = location_x;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
							else begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
						end 
						LEFT : begin
							if ((maze[location_x][location_y-1] != 2'b01) && (maze[location_x][location_y-1] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y - 1;
								location_x_next = location_x;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
							else if ((maze[location_x-1][location_y] != 2'b01) && (maze[location_x-1][location_y] != 2'b11 || sword_possess)) begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
							else begin
								location_y_next   = location_y +1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
						end
						RIGHT : begin
							if ((maze[location_x-1][location_y] != 2'b01) && (maze[location_x-1][location_y] != 2'b11 || sword_possess)) begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
							else if ((right_cell != 2'b01) && (right_cell != 2'b11 || sword_possess)) begin
								location_y_next   = location_y +1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
							else begin
								location_y_next   = location_y - 1;
								location_x_next = location_x;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
						end
					endcase
				end
				// LEFT_SLIDE 
				else if (location_y == 'd0 ) begin
					case (direction)
						DOWN : begin
							if ((right_cell != 2'b01) && (right_cell != 2'b11 || sword_possess)) begin
								location_y_next   = location_y +1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
							else if ((maze[location_x+1][location_y] != 2'b01) && (maze[location_x+1][location_y] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
							else begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
						end 
						LEFT : begin
							if ((maze[location_x+1][location_y] != 2'b01) && (maze[location_x+1][location_y] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
							else if ((maze[location_x-1][location_y] != 2'b01) && (maze[location_x-1][location_y] != 2'b11 || sword_possess)) begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
							else begin
								location_y_next   = location_y +1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
						end
						UP: begin
							if ((maze[location_x-1][location_y] != 2'b01) && (maze[location_x-1][location_y] != 2'b11 || sword_possess)) begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
							else if ((right_cell != 2'b01) && (right_cell != 2'b11 || sword_possess)) begin
								location_y_next   = location_y +1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
							else begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
						end
					endcase
				end
				// RIGHT_SLIDE 
				else if (location_y == 'd16) begin
					case (direction)
						DOWN : begin
							if ((maze[location_x+1][location_y] != 2'b01) && (maze[location_x+1][location_y] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
							else if ((maze[location_x][location_y-1] != 2'b01) && (maze[location_x][location_y-1] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y - 1;
								location_x_next = location_x;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
							else begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
						end 
						RIGHT : begin
							if ((maze[location_x-1][location_y] != 2'b01) && (maze[location_x-1][location_y] != 2'b11 || sword_possess)) begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
							else if ((maze[location_x+1][location_y] != 2'b01) && (maze[location_x+1][location_y] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
							else begin
								location_y_next   = location_y - 1;
								location_x_next = location_x;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
						end
						UP: begin
							if ((maze[location_x][location_y-1] != 2'b01) && (maze[location_x][location_y-1] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y - 1;
								location_x_next = location_x;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
							else if ((maze[location_x-1][location_y] != 2'b01) && (maze[location_x-1][location_y] != 2'b11 || sword_possess)) begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
							else begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
						end
					endcase
				end
				// CENTER 
				else begin
					case (direction)
						DOWN : begin
							if ((right_cell != 2'b01) && (right_cell != 2'b11 || sword_possess)) begin
								location_y_next   = location_y +1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
							else if ((maze[location_x+1][location_y] != 2'b01) && (maze[location_x+1][location_y] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
							else if ((maze[location_x][location_y-1] != 2'b01) && (maze[location_x][location_y-1] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y - 1;
								location_x_next = location_x;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
							else begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
						end 
						RIGHT : begin
							if ((maze[location_x-1][location_y] != 2'b01) && (maze[location_x-1][location_y] != 2'b11 || sword_possess)) begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
							else if ((right_cell != 2'b01) && (right_cell != 2'b11 || sword_possess)) begin
								location_y_next   = location_y +1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
							else if ((maze[location_x+1][location_y] != 2'b01) && (maze[location_x+1][location_y] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
							else begin
								location_y_next   = location_y - 1;
								location_x_next = location_x;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
						end
						UP: begin
							if ((maze[location_x][location_y-1] != 2'b01) && (maze[location_x][location_y-1] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y - 1;
								location_x_next = location_x;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
							else if ((maze[location_x-1][location_y] != 2'b01) && (maze[location_x-1][location_y] != 2'b11 || sword_possess)) begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
							else if ((right_cell != 2'b01) && (right_cell != 2'b11 || sword_possess)) begin
								location_y_next   = location_y +1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
							else begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
						end
						LEFT: begin
							if ((maze[location_x+1][location_y] != 2'b01) && (maze[location_x+1][location_y] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y;
								location_x_next = location_x+1;
								sword_possess_comb = (maze[location_x+1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = DOWN;
							end
							else if ((maze[location_x][location_y-1] != 2'b01) && (maze[location_x][location_y-1] != 2'b11 || sword_possess)) begin
								location_y_next   = location_y - 1;
								location_x_next = location_x;
								sword_possess_comb = (maze[location_x][location_y-1] == 2'b10) ? 'd1 : sword_possess;
								direction_next = LEFT;
							end
							else if ((maze[location_x-1][location_y] != 2'b01) && (maze[location_x-1][location_y] != 2'b11 || sword_possess)) begin
								location_x_next   = location_x -1 ;
								location_y_next   = location_y ;
								sword_possess_comb = (maze[location_x-1][location_y] == 2'b10) ? 'd1 : sword_possess;
								direction_next = UP;
							end
							else begin
								location_y_next   = location_y +1;
								location_x_next = location_x;
								sword_possess_comb = (right_cell == 2'b10) ? 'd1 : sword_possess;
								direction_next = RIGHT;
							end
						end
					endcase
				end
	end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)begin 
		out <= 2'b00;
    end
	else if (current_state == OUT)begin
		out       <= direction_next;
	end
	else begin
		out       <= 2'b00;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)begin 
        out_valid <= 1'b0;
    end
	else if (current_state == OUT)begin
        out_valid <= 1'b1;
	end
	else begin
		out_valid <= 1'b0;
	end
end


 
// always @(posedge clk) begin
//  $display("X%d , Y%d , out%d , out_valid%d",location_x,location_y,out,out_valid);	
// end

endmodule