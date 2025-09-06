// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

module SNN(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	img,
	ker,
	weight,

	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input cg_en;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//


//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [6:0] counter_input;
genvar i, j;
integer k;
reg [7:0]	image_half 	[15]; 
reg [7:0]   conv_img 	[9];
reg [7:0]   conv_ker 	[9];
reg [7:0]   ker_reg 	[9];
reg [7:0]   weight_reg 	[4];
reg [15:0]  conv_result [9];
reg [19:0]  conv_add_result;
wire [2:0] count_in_x;
wire [1:0] count_in_y;
wire [2:0] count_row;
reg [7:0] quan_max_reg1;
reg [7:0] quan_max_reg2;
reg [16:0] sum_mult[4];
reg [7:0]  encode1	[4];
reg [7:0]  encode2	[4];
reg [9:0]  sum_reg;
//==============================================//
//                  clock gating                //
//==============================================//
// input
wire sleep_img[0:14];
wire clock_img[0:14];
generate
    for (i = 0; i < 15; i = i + 1) begin 
        assign sleep_img[i] = ~(counter_input == i || counter_input == (i+15) || counter_input == (i+30) || counter_input == (i+45) || counter_input == (i+60));
    end
endgenerate
GATED_OR image_0(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[0]), .RST_N(rst_n), .CLOCK_GATED(clock_img[0]));
GATED_OR image_1(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[1]), .RST_N(rst_n), .CLOCK_GATED(clock_img[1]));
GATED_OR image_2(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[2]), .RST_N(rst_n), .CLOCK_GATED(clock_img[2]));
GATED_OR image_3(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[3]), .RST_N(rst_n), .CLOCK_GATED(clock_img[3]));
GATED_OR image_4(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[4]), .RST_N(rst_n), .CLOCK_GATED(clock_img[4]));
GATED_OR image_5(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[5]), .RST_N(rst_n), .CLOCK_GATED(clock_img[5]));
GATED_OR image_6(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[6]), .RST_N(rst_n), .CLOCK_GATED(clock_img[6]));
GATED_OR image_7(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[7]), .RST_N(rst_n), .CLOCK_GATED(clock_img[7]));
GATED_OR image_8(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[8]), .RST_N(rst_n), .CLOCK_GATED(clock_img[8]));
GATED_OR image_9(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[9]), .RST_N(rst_n), .CLOCK_GATED(clock_img[9]));
GATED_OR image_10(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[10]), .RST_N(rst_n), .CLOCK_GATED(clock_img[10]));
GATED_OR image_11(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[11]), .RST_N(rst_n), .CLOCK_GATED(clock_img[11]));
GATED_OR image_12(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[12]), .RST_N(rst_n), .CLOCK_GATED(clock_img[12]));
GATED_OR image_13(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[13]), .RST_N(rst_n), .CLOCK_GATED(clock_img[13]));
GATED_OR image_14(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_img[14]), .RST_N(rst_n), .CLOCK_GATED(clock_img[14]));
wire sleep_weight [0:3];
wire clock_weight [0:3];
generate
	for (i = 0; i < 4; i = i + 1) begin 
		assign sleep_weight[i] = ~(counter_input == i);
	end
endgenerate
GATED_OR weight_0(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_weight[0]), .RST_N(rst_n), .CLOCK_GATED(clock_weight[0]));
GATED_OR weight_1(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_weight[1]), .RST_N(rst_n), .CLOCK_GATED(clock_weight[1]));
GATED_OR weight_2(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_weight[2]), .RST_N(rst_n), .CLOCK_GATED(clock_weight[2]));
GATED_OR weight_3(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_weight[3]), .RST_N(rst_n), .CLOCK_GATED(clock_weight[3]));
wire sleep_kernal [0:8];
wire clock_kernal [0:8];
generate
	for (i = 0; i < 9; i = i + 1) begin 
		assign sleep_kernal[i] = ~(counter_input == i);
	end
endgenerate
GATED_OR kernal_0(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_kernal[0]), .RST_N(rst_n), .CLOCK_GATED(clock_kernal[0]));
GATED_OR kernal_1(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_kernal[1]), .RST_N(rst_n), .CLOCK_GATED(clock_kernal[1]));
GATED_OR kernal_2(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_kernal[2]), .RST_N(rst_n), .CLOCK_GATED(clock_kernal[2]));
GATED_OR kernal_3(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_kernal[3]), .RST_N(rst_n), .CLOCK_GATED(clock_kernal[3]));
GATED_OR kernal_4(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_kernal[4]), .RST_N(rst_n), .CLOCK_GATED(clock_kernal[4]));
GATED_OR kernal_5(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_kernal[5]), .RST_N(rst_n), .CLOCK_GATED(clock_kernal[5]));
GATED_OR kernal_6(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_kernal[6]), .RST_N(rst_n), .CLOCK_GATED(clock_kernal[6]));
GATED_OR kernal_7(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_kernal[7]), .RST_N(rst_n), .CLOCK_GATED(clock_kernal[7]));
GATED_OR kernal_8(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_kernal[8]), .RST_N(rst_n), .CLOCK_GATED(clock_kernal[8]));
//max pooling + quantization
wire sleep_maxpooling_1;
wire clock_maxpooling_1;
assign sleep_maxpooling_1 = ~(counter_input == 15 || counter_input == 16 || counter_input == 21 || counter_input == 22 ||
					counter_input == 27 || counter_input == 28 || counter_input == 33 || counter_input == 34 ||
					counter_input == 51 || counter_input == 52 || counter_input == 57 || counter_input == 58 ||
					counter_input == 63 || counter_input == 64 || counter_input == 69 || counter_input == 70);
GATED_OR maxpooling1(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_maxpooling_1), .RST_N(rst_n), .CLOCK_GATED(clock_maxpooling_1));
wire sleep_maxpooling_2;
wire clock_maxpooling_2;
assign sleep_maxpooling_2 = ~(counter_input == 17 || counter_input == 18 || counter_input == 23 || counter_input == 24 ||
					counter_input == 29 || counter_input == 30 || counter_input == 35 || counter_input == 36 ||
					counter_input == 53 || counter_input == 54 || counter_input == 59 || counter_input == 60 ||
					counter_input == 65 || counter_input == 66 || counter_input == 71 || counter_input == 72);
GATED_OR maxpooling2(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_maxpooling_2), .RST_N(rst_n), .CLOCK_GATED(clock_maxpooling_2));
//encode
wire sleep_encode1;
wire clock_encode1;
assign sleep_encode1 = ~(counter_input == 25 || counter_input == 26 || counter_input == 37 || counter_input == 38);
GATED_OR encode111(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_encode1), .RST_N(rst_n), .CLOCK_GATED(clock_encode1));
//sum
wire sleep_sum;
wire clock_sum;
assign sleep_sum = ~(counter_input == 60 ||counter_input == 61 || counter_input == 62 || counter_input == 73 );
GATED_OR sum1(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_sum), .RST_N(rst_n), .CLOCK_GATED(clock_sum));
//ourput
wire sleep_output;
wire clock_output;
assign sleep_output = ~(counter_input == 74 || out_valid);
GATED_OR output1(.CLOCK(clk), .SLEEP_CTRL(cg_en & sleep_output), .RST_N(rst_n), .CLOCK_GATED(clock_output));
//==============================================//
//                  INPUT                       //
//==============================================//

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		counter_input <= 7'd0;
	end else if (in_valid) begin
		counter_input <= counter_input + 1'b1;
	end else if (counter_input != 74 && counter_input )begin
		counter_input <=  counter_input + 1'b1;
	end else begin
		counter_input <= 0;
	end
end



generate
for (i = 0; i < 15; i = i + 1) begin
		always @(posedge clock_img[i] /*or negedge rst_n*/) begin
			// if (!rst_n)
			// 	image_half[i] <= 8'd0;
			// else 
			if (counter_input == i || counter_input == i + 15 || counter_input == i + 30 || counter_input == i + 45 || counter_input == i + 60)	
				image_half[i] <= img;
			else								
				image_half[i] <= image_half[i];
		end
end
endgenerate

generate
	for (j = 0; j < 4; j = j + 1) begin
		always @(posedge clock_weight[j] /*or negedge rst_n*/) begin
			// if (!rst_n)
			// 	weight_reg[j] <= 8'd0;
			// else 
			if (counter_input == j && in_valid)	
				weight_reg[j] <= weight;
			else								
				weight_reg[j] <= weight_reg[j];
		end
	end
endgenerate

generate
	for (j = 0; j < 9; j = j + 1) begin
		always @(posedge clock_kernal[j] /*or negedge rst_n*/) begin
			// if (!rst_n)
			// 	ker_reg[j] <= 8'd0;
			// else 
			if (counter_input == j && in_valid)	
				ker_reg[j] <= ker;
			else								
				ker_reg[j] <= ker_reg[j];
		end
	end
endgenerate

//==============================================//
//             conv multilpication              //
//==============================================//

always @ (*) begin
	case (counter_input)
		15, 30, 60: begin
			conv_img[0] = image_half[0]; 
			conv_img[3] = image_half[6]; 
			conv_img[6] = image_half[12];

			conv_img[1] = image_half[1]; 
			conv_img[4] = image_half[7]; 
			conv_img[7] = image_half[13];

			conv_img[2] = image_half[2]; 
			conv_img[5] = image_half[8]; 
			conv_img[8] = image_half[14];
		end
		16: begin
			conv_img[0] = image_half[1]; 
			conv_img[3] = image_half[7]; 
			conv_img[6] = image_half[13];

			conv_img[1] = image_half[2]; 
			conv_img[4] = image_half[8]; 
			conv_img[7] = image_half[14];
			
			conv_img[2] = image_half[3]; 
			conv_img[5] = image_half[9]; 
			conv_img[8] = image_half[0];
		end
		17: begin
			conv_img[0] = image_half[2]; 
			conv_img[3] = image_half[8]; 
			conv_img[6] = image_half[14];

			conv_img[1] = image_half[3]; 
			conv_img[4] = image_half[9]; 
			conv_img[7] = image_half[0];
			
			conv_img[2] = image_half[4]; 
			conv_img[5] = image_half[10]; 
			conv_img[8] = image_half[1];
		end
		18, 33, 63: begin
			conv_img[0] = image_half[3]; 
			conv_img[3] = image_half[9]; 
			conv_img[6] = image_half[0];

			conv_img[1] = image_half[4]; 
			conv_img[4] = image_half[10]; 
			conv_img[7] = image_half[1];
			
			conv_img[2] = image_half[5]; 
			conv_img[5] = image_half[11]; 
			conv_img[8] = image_half[2];
		end
		21, 36, 51, 66: begin
			conv_img[0] = image_half[6]; 
			conv_img[3] = image_half[12]; 
			conv_img[6] = image_half[3];

			conv_img[1] = image_half[7]; 
			conv_img[4] = image_half[13]; 
			conv_img[7] = image_half[4];
			
			conv_img[2] = image_half[8]; 
			conv_img[5] = image_half[14]; 
			conv_img[8] = image_half[5];
		end
		22, 52 : begin
			conv_img[0] = image_half[7]; 
			conv_img[3] = image_half[13]; 
			conv_img[6] = image_half[4];

			conv_img[1] = image_half[8]; 
			conv_img[4] = image_half[14]; 
			conv_img[7] = image_half[5];
			
			conv_img[2] = image_half[9]; 
			conv_img[5] = image_half[0]; 
			conv_img[8] = image_half[6];
		end
		23, 53 : begin
			conv_img[0] = image_half[8]; 
			conv_img[3] = image_half[14]; 
			conv_img[6] = image_half[5];

			conv_img[1] = image_half[9]; 
			conv_img[4] = image_half[0]; 
			conv_img[7] = image_half[6];
			
			conv_img[2] = image_half[10]; 
			conv_img[5] = image_half[1]; 
			conv_img[8] = image_half[7];
		end
		24, 54, 69: begin
			conv_img[0] = image_half[9]; 
			conv_img[3] = image_half[0]; 
			conv_img[6] = image_half[6];

			conv_img[1] = image_half[10]; 
			conv_img[4] = image_half[1]; 
			conv_img[7] = image_half[7];
			
			conv_img[2] = image_half[11]; 
			conv_img[5] = image_half[2]; 
			conv_img[8] = image_half[8];
		end
		27, 57, 72: begin
			conv_img[0] = image_half[12]; 
			conv_img[3] = image_half[3]; 
			conv_img[6] = image_half[9];

			conv_img[1] = image_half[13]; 
			conv_img[4] = image_half[4]; 
			conv_img[7] = image_half[10];
			
			conv_img[2] = image_half[14]; 
			conv_img[5] = image_half[5]; 
			conv_img[8] = image_half[11];
		end
		28, 58 : begin
			conv_img[0] = image_half[13]; 
			conv_img[3] = image_half[4]; 
			conv_img[6] = image_half[10];

			conv_img[1] = image_half[14]; 
			conv_img[4] = image_half[5]; 
			conv_img[7] = image_half[11];
			
			conv_img[2] = image_half[0]; 
			conv_img[5] = image_half[6]; 
			conv_img[8] = image_half[12];
		end
		29, 59 : begin
			conv_img[0] = image_half[14]; 
			conv_img[3] = image_half[5]; 
			conv_img[6] = image_half[11];

			conv_img[1] = image_half[0]; 
			conv_img[4] = image_half[6]; 
			conv_img[7] = image_half[12];
			
			conv_img[2] = image_half[1]; 
			conv_img[5] = image_half[7]; 
			conv_img[8] = image_half[13];
		end
		34, 64: begin
			conv_img[0] = image_half[4]; 
			conv_img[3] = image_half[10]; 
			conv_img[6] = image_half[1];

			conv_img[1] = image_half[5]; 
			conv_img[4] = image_half[11]; 
			conv_img[7] = image_half[2];
			
			conv_img[2] = image_half[6]; 
			conv_img[5] = image_half[12]; 
			conv_img[8] = image_half[3];
		end
		35, 65: begin
			conv_img[0] = image_half[5]; 
			conv_img[3] = image_half[11]; 
			conv_img[6] = image_half[2];

			conv_img[1] = image_half[6]; 
			conv_img[4] = image_half[12]; 
			conv_img[7] = image_half[3];
			
			conv_img[2] = image_half[7]; 
			conv_img[5] = image_half[13]; 
			conv_img[8] = image_half[4];
		end
		70 : begin
			conv_img[0] = image_half[10]; 
			conv_img[3] = image_half[1]; 
			conv_img[6] = image_half[7];

			conv_img[1] = image_half[11]; 
			conv_img[4] = image_half[2]; 
			conv_img[7] = image_half[8];
			
			conv_img[2] = image_half[12]; 
			conv_img[5] = image_half[3]; 
			conv_img[8] = image_half[9];
		end
		71 : begin
			conv_img[0] = image_half[11]; 
			conv_img[3] = image_half[2]; 
			conv_img[6] = image_half[8];

			conv_img[1] = image_half[12]; 
			conv_img[4] = image_half[3]; 
			conv_img[7] = image_half[9];
			
			conv_img[2] = image_half[13]; 
			conv_img[5] = image_half[4]; 
			conv_img[8] = image_half[10];
		end
		25,26,37,38,61,62,73,74: begin
			conv_img[0] = quan_max_reg1; 
			conv_img[3] = 0; 
			conv_img[6] = 0;

			conv_img[1] = quan_max_reg2; 
			conv_img[4] = 0; 
			conv_img[7] = 0;
			
			conv_img[2] = 0; 
			conv_img[5] = 0; 
			conv_img[8] = 0;
		end
		default: begin
			if (cg_en) begin
				for (k = 0; k < 9; k = k + 1) begin
					conv_img[k] = 0 ;
				end
			end
			else begin
				for (k = 0; k < 9; k = k + 1) begin
					conv_img[k] = counter_input;
				end
			end
		end
	endcase
end
always @ (*) begin
	conv_ker[0] = ker_reg[0];
	conv_ker[1] = ker_reg[1];
	conv_ker[2] = ker_reg[2];
	conv_ker[3] = ker_reg[3];
	conv_ker[4] = ker_reg[4];
	conv_ker[5] = ker_reg[5];
	conv_ker[6] = ker_reg[6];
	conv_ker[7] = ker_reg[7];
	conv_ker[8] = ker_reg[8];
	if (counter_input == 25 || counter_input == 37 || counter_input == 61 || counter_input == 73) begin
		conv_ker[0] = weight_reg[0];
		conv_ker[1] = weight_reg[2];
	end 
	else if (counter_input == 26 || counter_input == 38 || counter_input == 62 || counter_input == 74)begin
		conv_ker[0] = weight_reg[1];
		conv_ker[1] = weight_reg[3];

	end
end
generate
	for (i = 0; i < 9; i = i + 1) begin
		always @ (*) begin
			conv_result[i] = conv_img[i] * conv_ker[i];
		end
	end
endgenerate

always @ (*) begin
	sum_mult[0] = conv_result[0] + conv_result[1];
	sum_mult[1] = conv_result[2] + conv_result[3];
	sum_mult[2] = conv_result[4] + conv_result[5];
	sum_mult[3] = conv_result[6] + conv_result[7];
	conv_add_result = sum_mult[0] + sum_mult[1] + sum_mult[2] + sum_mult[3] + conv_result[8];
end

//==============================================///             max pooling + quantization       //
//==============================================//
wire [7:0] quan_max_comb1;
assign quan_max_comb1 = (counter_input == 15 || counter_input == 27 || counter_input == 51 || counter_input == 63 || counter_input == 16 || counter_input == 21 || counter_input == 22 || counter_input == 28 || counter_input == 33 || counter_input == 34 
		  	|| counter_input == 52 || counter_input == 57 || counter_input == 58 || counter_input == 64 || counter_input == 69 || counter_input == 70) ? (conv_add_result/'d2295) : 0;
always @ (posedge clock_maxpooling_1 /*or negedge rst_n*/) begin
	// if (!rst_n) begin
	// 	quan_max_reg1 <= 8'd0;
	// end 

	// else 
	if (counter_input == 15 || counter_input == 27 || counter_input == 51 || counter_input == 63) begin
		quan_max_reg1 <= quan_max_comb1;
	end 
	else if (counter_input == 16 || counter_input == 21 || counter_input == 22 || counter_input == 28 || counter_input == 33 || counter_input == 34 
		  	|| counter_input == 52 || counter_input == 57 || counter_input == 58 || counter_input == 64 || counter_input == 69 || counter_input == 70) begin
		if (quan_max_reg1 < quan_max_comb1) begin
			quan_max_reg1 <= quan_max_comb1;
		end else begin
			quan_max_reg1 <= quan_max_reg1;
		end
	end 
	else begin
		quan_max_reg1 <= quan_max_reg1;
	end
end
wire [7:0] quan_max_comb2;
assign quan_max_comb2 = (counter_input == 17 || counter_input == 29 || counter_input == 53 || counter_input == 65 || counter_input == 18 || counter_input == 23 || counter_input == 24 || counter_input == 30 || counter_input == 35 || counter_input == 36 
			|| counter_input == 54 || counter_input == 59 || counter_input == 60 || counter_input == 66 || counter_input == 71 || counter_input == 72) ? (conv_add_result/'d2295) : 0;
always @ (posedge clock_maxpooling_2 /*or negedge rst_n*/) begin
	// if (!rst_n) begin
	// 	quan_max_reg2 <= 8'd0;
	// end 
	// else 
	if (counter_input == 17 || counter_input == 29 || counter_input == 53 || counter_input == 65) begin
		quan_max_reg2 <= quan_max_comb2;
	end 
	else if (counter_input == 18 || counter_input == 23 || counter_input == 24 || counter_input == 30 || counter_input == 35 || counter_input == 36 
			|| counter_input == 54 || counter_input == 59 || counter_input == 60 || counter_input == 66 || counter_input == 71 || counter_input == 72) begin
		if (quan_max_reg2 < quan_max_comb2) begin
			quan_max_reg2 <= quan_max_comb2;
		end else begin
			quan_max_reg2 <= quan_max_reg2;
		end
	end 
	else begin
		quan_max_reg2 <= quan_max_reg2;
	end
end
//==============================================//
//                   encode                     //
//==============================================//

always @ (posedge clock_encode1 /*or negedge rst_n*/) begin
	// if (!rst_n) begin
	// 	encode1[0] <= 8'd0;
	// 	encode1[1] <= 8'd0;
	// 	encode1[2] <= 8'd0;
	// 	encode1[3] <= 8'd0;
	// end 
	// else 
	if (counter_input == 25) 
	begin
		encode1[0] <= sum_mult[0]/510;
	end 
	else if (counter_input == 26) 
	begin
		encode1[1] <= sum_mult[0]/510;
	end
	else if (counter_input == 37) 
	begin
		encode1[2] <= sum_mult[0]/510;
	end 
	else if (counter_input == 38) 
	begin
		encode1[3] <= sum_mult[0]/510;
	end 
	else 
	begin
		encode1[0] <= ~encode1[0];
		encode1[1] <= encode1[1];
		encode1[2] <= ~encode1[2];
		encode1[3] <= encode1[3];
	end
end


always @ (*) begin
	for (k = 0 ; k < 4; k = k + 1) begin
		encode2[k] = 0;
	end
	case (counter_input) 
		61 : begin
			encode2[0] = sum_mult[0]/510;
		end
		62 : begin
			encode2[1] = sum_mult[0]/510;
		end
		73 : begin
			encode2[2] = sum_mult[0]/510;
		end
		74 : begin
			encode2[3] = sum_mult[0]/510;
		end
	endcase
end

wire [9:0] sum_comb0, sum_comb1, sum_comb2, sum_comb3;
assign sum_comb0 = (encode1[0] > encode2[0]) ? (sum_reg + encode1[0] - encode2[0]) : (sum_reg + encode2[0] - encode1[0]);
assign sum_comb1 = (encode1[1] > encode2[1]) ? (sum_reg + encode1[1] - encode2[1]) : (sum_reg + encode2[1] - encode1[1]);
assign sum_comb2 = (encode1[2] > encode2[2]) ? (sum_reg + encode1[2] - encode2[2]) : (sum_reg + encode2[2] - encode1[2]);
assign sum_comb3 = (encode1[3] > encode2[3]) ? (sum_reg + encode1[3] - encode2[3]) : (sum_reg + encode2[3] - encode1[3]);


always @ (posedge clock_sum /*or negedge rst_n*/) begin
	// if (!rst_n) begin
	// 	sum_reg <= 10'd0;
	// end
	// else 
	if (counter_input == 0)
		sum_reg <= 10'd0;
	else if (counter_input == 60) begin
		sum_reg <= 10'd0;
	end
	else if (counter_input == 61) begin
		sum_reg <= sum_comb0;
	end
	else if (counter_input == 62) begin
		sum_reg <= sum_comb1;
	end
	else if (counter_input == 73) begin
		sum_reg <= sum_comb2;
	end
	else if (counter_input == 74) begin
		sum_reg <= sum_comb3;
	end
	else begin
		sum_reg <= ~sum_reg;
	end
	
end
//==============================================//
//                   output                     //
//==============================================//

always @(posedge clock_output or negedge rst_n) begin
	if (!rst_n) begin
		out_data <= 1'b0;
		out_valid <= 1'b0;
	end
	else if (counter_input == 74) begin
		if (encode1[3] > encode2[3]) begin
			if (sum_reg + encode1[3] - encode2[3] >= 16) begin
				out_data <= sum_reg + encode1[3] - encode2[3];
				out_valid <= 1'b1;
			end else begin
				out_data <= 0;
				out_valid <= 1'b1;
			end
		end else begin
			if (sum_reg + encode2[3] - encode1[3] >= 16) begin
				out_data <= sum_reg + encode2[3] - encode1[3];
				out_valid <= 1'b1;
			end else begin
				out_data <= 0;
				out_valid <= 1'b1;
			end
		end
	end else begin
		out_data <= 0;
		out_valid <= 1'b0;
	end
end




endmodule

