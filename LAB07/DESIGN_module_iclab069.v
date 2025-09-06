module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
    seed_in,
    out_idle,
    out_valid,
    seed_out,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4
);

input clk;
input rst_n;
input in_valid;
input [31:0] seed_in;
input out_idle;
output reg out_valid;
output reg [31:0] seed_out;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;


reg [1:0] current_state, next_state;
reg [31:0] seed_reg;
parameter S_wait_input = 2'b00,
		  S_wait_sync_idle = 2'b01,
		  S_send_data = 2'b10;
//=======================================================
//                   FSM
//=======================================================
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        current_state <= S_wait_input;
    end
    else begin
        current_state <= next_state;
    end
end
always @(*) begin
	case(current_state)
		S_wait_input :	   next_state = in_valid ? S_wait_sync_idle : S_wait_input;
		S_wait_sync_idle : next_state = out_idle ? S_send_data : S_wait_sync_idle;
		S_send_data :      next_state = S_wait_input;
		default:next_state = S_wait_input;
	endcase
end
//seed_reg
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        seed_reg <= 32'd0;
    end
    else if(in_valid) begin
        seed_reg <= seed_in;
    end
    else  begin
        seed_reg <= seed_reg;
    end
end

always @ (*) begin
    out_valid = (current_state == S_send_data) ? 1 : 0;
    seed_out = (current_state == S_send_data) ? seed_reg : 32'd0;
end
endmodule




module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    seed,
    out_valid,
    rand_num,
    busy,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [31:0] seed;
output out_valid;
output [31:0] rand_num;
output busy;

// You can change the input / output of the custom flag ports
input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

input clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;
reg [8:0] counter;
reg [1:0] current_state, next_state;
parameter IDLE = 2'b00,
		  INPUT = 2'b01,
          OUTPUT = 2'b10;
reg [31:0] seed_reg;
reg busy_reg;
reg [31:0] rand_num_ff;
reg [31:0] gen_i, gen_ii, gen_iii, gen_iv;
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
	case(current_state)
		IDLE :	   next_state = in_valid ? INPUT : IDLE;
		// INPUT : next_state = !in_valid ? OUTPUT : INPUT;
        INPUT : next_state = OUTPUT ;
        OUTPUT : next_state = (counter =='d256) ? IDLE : OUTPUT ;
		default:next_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        seed_reg <= 32'd0;
    end
    else if(in_valid) begin
        seed_reg <= seed;
    end
    else begin
        seed_reg <= seed_reg;
    end
end
always @ (*) begin
    gen_i = (current_state == INPUT) ? seed_reg : rand_num_ff;
    gen_ii = (gen_i) ^ (gen_i << 13);
    gen_iii = (gen_ii) ^ (gen_ii >> 17);
    gen_iv = (gen_iii) ^ (gen_iii << 5);
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)         
        rand_num_ff <= 32'd0;
    else if (fifo_full)  
        rand_num_ff <= rand_num_ff;
    else                
        rand_num_ff <= gen_iv;
end


always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        busy_reg <= 1'b0;
    end
    else if (in_valid) begin
        busy_reg <= 1'b1;
    end
    else if (counter == 'd256) begin
        busy_reg <= 1'b0;
    end
    else begin
        busy_reg <= busy_reg;
    end
end
assign busy = busy_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 8'd0;
    end 
    else if(current_state == IDLE) begin
        counter <= 8'd0;
    end
    else if(current_state == OUTPUT ) begin
        counter <= (fifo_full) ? counter : counter + 1'b1;
    end
    else begin
        counter <= counter;
    end
end
assign out_valid = (!fifo_full && current_state == OUTPUT) ? 1'b1 : 1'b0; 
assign rand_num = (fifo_full) ? 32'd0 : rand_num_ff;

endmodule

module CLK_3_MODULE (
    clk,
    rst_n,
    fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    rand_num,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input clk;
input rst_n;
input fifo_empty;
input [31:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [31:0] rand_num;

// You can change the input / output of the custom flag ports
input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;
reg empty_delay_i, empty_delay_ii;

assign fifo_rinc = ~fifo_empty ? 1'b1 : 1'b0;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        empty_delay_i <= 1'b1;
        empty_delay_ii <= 1'b1;
    end
    else begin
        empty_delay_i <= fifo_empty;
        empty_delay_ii <= empty_delay_i;
    end
end
always @(*) begin
    if(~empty_delay_ii) begin
        out_valid = 1'b1;
        rand_num = fifo_rdata;
    end
    else begin
        out_valid = 1'b0;
        rand_num = 'd0;
    end
end

endmodule