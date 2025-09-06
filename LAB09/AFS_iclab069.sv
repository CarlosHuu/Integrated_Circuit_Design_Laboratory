//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2025/4
//		Version		: v1.0
//   	File Name   : AFS.sv
//   	Module Name : AFS
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module AFS(input clk, INF.AFS_inf inf);
import usertype::*;
    //==============================================//
    //              logic declaration               //
    // ============================================ //
logic [63:0] r_data;  
logic [63:0] w_data;  
logic read_done;
logic read_j;
logic write_j;
logic write_done;
logic [17:0] addr;
logic [7:0] cnt_amount;
logic [7:0] cnt_purchase;
logic [11:0] rose_purchase;
logic [11:0] lily_purchase;
logic [11:0] carnation_purchase;
logic [11:0] baby_breath_purchase;

logic date_check;
logic warn_stock;
Action          action_reg;
Strategy_Type   strategy_reg;
Mode            mode_reg;
Date            date_reg;
Data_No         data_no_reg;
Stock           stock_A, stock_B, stock_C, stock_D;
logic read_done_reg;
//=======================================================
//                   FSM
//=======================================================
typedef enum logic [3:0] {
    IDLE           = 4'd0,
    INPUT          = 4'd1,
    PURCHASE       = 4'd2,
    PURCHASE_cal   = 4'd3,
    PURCHASE_write = 4'd4,
    RESTOCK        = 4'd5,
    RESTOCK_cal    = 4'd6,
    RESTOCK_write  = 4'd7,
    CHECK          = 4'd8,
    OUT            = 4'd9
} state_t;
state_t current_state, next_state;

always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n)begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

always_comb begin
    case (current_state)
        IDLE: begin
            next_state = (inf.sel_action_valid) ? INPUT : IDLE;
        end
		INPUT : begin
            if (action_reg == Purchase) begin
                next_state = PURCHASE;
            end
            else if (action_reg == Restock) begin
                next_state = RESTOCK;
            end
            else if (action_reg == Check_Valid_Date) begin
                next_state = CHECK;
            end
            else begin
                next_state = INPUT;
            end
		end
        PURCHASE : begin
            if (inf.R_VALID & inf.R_READY)
                next_state = PURCHASE_cal;
            else begin
                next_state = PURCHASE;
            end
        end
        PURCHASE_cal : begin
            if (date_check) begin
                next_state = OUT;
            end
            else if (warn_stock) begin
                next_state = OUT;
            end
            else if (cnt_purchase == 1) begin
                next_state = PURCHASE_write;
            end
            else begin
                next_state = PURCHASE_cal;
            end
        end
        PURCHASE_write : begin
            if (inf.B_VALID & inf.B_READY) begin
                next_state = OUT;
            end
            else begin
                next_state = PURCHASE_write;
            end
        end
        RESTOCK : begin
            if (cnt_amount == 4 & read_done_reg) begin
                next_state = RESTOCK_cal;
            end
            else begin
                next_state = RESTOCK;
            end
        end
        RESTOCK_cal : begin
            next_state = RESTOCK_write;
        end
        RESTOCK_write : begin
            if (inf.B_VALID & inf.B_READY) begin
                next_state = OUT;
            end
            else begin
                next_state = RESTOCK_write;
            end
        end
        CHECK : begin
            if (inf.R_VALID & inf.R_READY) begin
                next_state = OUT;
            end
            else begin
                next_state = CHECK;
            end

        end
        OUT : begin
            next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase 
end
//=======================================================
//                   CNT
//=======================================================

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        read_done_reg<= 0;
    end
    else if (current_state == IDLE) begin
        read_done_reg <= 0;
    end
    else if (read_done)begin
        read_done_reg <= 1;
    end
    else begin
        read_done_reg <= read_done_reg;
    end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        cnt_amount <= 0;
    end
    else if (current_state == IDLE) begin
        cnt_amount <= 0;
    end
    else if (current_state == RESTOCK && inf.restock_valid) begin
        cnt_amount <= cnt_amount + 1;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        cnt_purchase <= 0;
    end
    else if (current_state == IDLE) begin
        cnt_purchase <= 0;
    end
    else if (current_state == PURCHASE_cal) begin
        cnt_purchase <= cnt_purchase + 1;
    end
end
//=======================================================
//                   INPUT
//=======================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) action_reg <= Purchase;
    else if (inf.sel_action_valid) action_reg <= inf.D.d_act[0];
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)  strategy_reg <= Strategy_A;
    else if (inf.strategy_valid) strategy_reg <= inf.D.d_strategy[0];
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)mode_reg <= Single;
    else if (inf.mode_valid) 
        mode_reg <= inf.D.d_mode[0];
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        date_reg.M <= 0;
        date_reg.D <= 0;
    end
    else if (inf.date_valid) begin
        date_reg.M <= inf.D.d_date[0].M;
        date_reg.D <= inf.D.d_date[0].D;
    end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) 
        data_no_reg <= 0;
    else if(inf.data_no_valid) 
        data_no_reg <= inf.D.d_data_no[0];
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        stock_A <= 0;
        stock_B <= 0;
        stock_C <= 0;
        stock_D <= 0;
    end
    else if (inf.restock_valid) begin
        stock_D <= inf.D.d_stock[0];
        stock_C <= stock_D;
        stock_B <= stock_C;
        stock_A <= stock_B;
    end
end
//=======================================================
//                   DRAM
//=======================================================
Data_Dir dram_out;
Data_Dir dram_in;
// logic [63:0]    dram_reg;
Data_Dir dram_out_temp;
always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        dram_out <= 'd0;
    end
    else if (inf.R_VALID & inf.R_READY) begin
        dram_out <= dram_out_temp;
    end 
end

// always_comb begin
//     dram_out.Rose        = dram_reg[63:52];
//     dram_out.Lily        = dram_reg[51:40];
//     dram_out.M           = dram_reg[39:32];
//     dram_out.Carnation   = dram_reg[31:20];
//     dram_out.Baby_Breath = dram_reg[19:8];
//     dram_out.D           = dram_reg[7:0];
// end

always_comb begin
    dram_out_temp.Rose                 = r_data[63:52];
    dram_out_temp.Lily                 = r_data[51:40];
    dram_out_temp.M                    = r_data[39:32];
    dram_out_temp.Carnation            = r_data[31:20];
    dram_out_temp.Baby_Breath     = r_data[19:8];
    dram_out_temp.D               = r_data[7:0];
end

//READ
logic [16:0] read_addr;
assign read_addr  = {5'h10, 1'd0, data_no_reg, 3'd0};
always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        read_j <= 1'b0;
    end 
    else if (inf.data_no_valid) begin
        read_j <= 1'b1;
    end 
    else if (inf.R_VALID) begin
        read_j <= 1'b0;
    end
end
//WRITE
// always_ff @(posedge clk or negedge inf.rst_n) begin
//     if (!inf.rst_n) begin
//         write_j <= 1'b0;
//     end 
//     else if (current_state == RESTOCK_write) begin
//         write_j <= 1'b1;
//     end 
//     else if (current_state == OUT) begin
//         write_j <= 1'b0;
//     end
// end
always_comb begin
    if (current_state == RESTOCK_write | current_state == PURCHASE_write) begin
        write_j = 1;
    end
    else begin
        write_j = 0;
    end
end
//WRITE_DATA
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        w_data <= 'd0;
    end
    else if (current_state == RESTOCK_write) begin
        w_data <= {dram_in.Rose, dram_in.Lily, {4'd0,dram_in.M}, dram_in.Carnation, dram_in.Baby_Breath, {3'd0,dram_in.D}};
    end
    else if (current_state == PURCHASE_write) begin
        w_data <= {rose_purchase, lily_purchase, {4'd0,dram_out.M}, carnation_purchase, baby_breath_purchase, {3'd0,dram_out.D}};
    end
end  
//=======================================================
//                   PURCHASE
//=======================================================
logic [11:0] Lily_request;
logic [11:0] Rose_request;
logic [11:0] Carnation_request;
logic [11:0] Baby_Breath_request;
logic [11:0] amount;

always_comb begin
    case(mode_reg)
        Single: begin
            amount = 120;
        end
        Group_Order: begin
            amount = 480;
        end
        Event: begin
            amount = 960;
        end
        default: begin
            amount = 0;
        end
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        Lily_request <= 0;
        Rose_request <= 0;
        Carnation_request <= 0;
        Baby_Breath_request <= 0;
    end
    else if (current_state == PURCHASE_cal)begin
        case (strategy_reg)
            Strategy_A: begin
                Rose_request <= amount;
                Lily_request <= 0;
                Carnation_request <= 0;
                Baby_Breath_request <= 0;
            end
            Strategy_B: begin
                Lily_request <= amount;
                Rose_request <= 0;
                Carnation_request <= 0;
                Baby_Breath_request <= 0;
            end
            Strategy_C: begin
                Carnation_request <= amount;
                Rose_request <= 0;
                Lily_request <= 0;
                Baby_Breath_request <= 0;
            end
            Strategy_D: begin
                Baby_Breath_request <= amount;
                Rose_request <= 0;
                Lily_request <= 0;
                Carnation_request <= 0;
            end
            Strategy_E: begin
                Rose_request <= amount>>1;
                Lily_request <= amount>>1;
                Carnation_request <= 0;
                Baby_Breath_request <= 0;
            end
            Strategy_F: begin
                Rose_request <= 0;
                Lily_request <= 0;
                Carnation_request <= amount>>1;
                Baby_Breath_request <= amount>>1;
            end
            Strategy_G: begin
                Rose_request <= amount>>1;
                Lily_request <= 0;
                Carnation_request <= amount>>1;
                Baby_Breath_request <= 0;
            end
            Strategy_H: begin
                Rose_request <= amount>>2;
                Lily_request <= amount>>2;
                Carnation_request <= amount>>2;
                Baby_Breath_request <= amount>>2;
            end 
            default: begin
                Lily_request <= 0;
                Rose_request <= 0;
                Carnation_request <= 0;
                Baby_Breath_request <= 0;
            end
        endcase
    end
    else begin
        Rose_request <= 0;
        Lily_request <= 0;
        Carnation_request <= 0;
        Baby_Breath_request <= 0;
    end
end



always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        rose_purchase <= 0;
        lily_purchase <= 0;
        carnation_purchase <= 0;
        baby_breath_purchase <= 0;
    end
    else if (current_state == PURCHASE_cal) begin
        rose_purchase <= dram_out.Rose - Rose_request;
        lily_purchase <= dram_out.Lily - Lily_request;
        carnation_purchase <= dram_out.Carnation - Carnation_request;
        baby_breath_purchase <= dram_out.Baby_Breath - Baby_Breath_request;
    end
end

//=======================================================
//                   RESTOCK
//=======================================================
logic [11:0] Lily_new;
logic [11:0] Rose_new;
logic [11:0] Carnation_new;
logic [11:0] Baby_Breath_new;
logic L_warn, R_warn, C_warn, B_warn;
always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        Lily_new <= 0;
        Rose_new <= 0;
        Carnation_new <= 0;
        Baby_Breath_new <= 0;
        L_warn <= 0;
        R_warn <= 0;
        C_warn <= 0;
        B_warn <= 0;
    end
    else if (current_state == IDLE) begin
        Lily_new <= 0;
        Rose_new <= 0;
        Carnation_new <= 0;
        Baby_Breath_new <= 0;
        L_warn <= 0;
        R_warn <= 0;
        C_warn <= 0;
        B_warn <= 0;
    end
    else if (current_state == RESTOCK_cal)begin
        Lily_new <= dram_out.Lily + stock_B;
        Rose_new <= dram_out.Rose + stock_A;
        Carnation_new <= dram_out.Carnation + stock_C;
        Baby_Breath_new <= dram_out.Baby_Breath + stock_D;
        L_warn <= (dram_out.Lily + stock_B > 4095) ? 1 : 0;
        R_warn <= (dram_out.Rose + stock_A > 4095) ? 1 : 0;
        C_warn <= (dram_out.Carnation + stock_C > 4095) ? 1 : 0;
        B_warn <= (dram_out.Baby_Breath + stock_D > 4095) ? 1 : 0;
        
    end
end


always_comb begin
    dram_in.M           = date_reg.M;
    dram_in.D           = date_reg.D;
    dram_in.Lily        = L_warn        ? 4095 : Lily_new;
    dram_in.Rose        = R_warn        ? 4095 : Rose_new;
    dram_in.Carnation   = C_warn   ? 4095 : Carnation_new;
    dram_in.Baby_Breath = B_warn ? 4095 : Baby_Breath_new;
end

 
//=======================================================
//                   WARNING
//=======================================================

assign date_check = (date_reg.M < dram_out.M) | ((date_reg.M == dram_out.M) & (date_reg.D < dram_out.D)) && action_reg != Restock  ;

logic overflow_flag;
assign overflow_flag = L_warn | R_warn | C_warn | B_warn;

assign warn_stock = ( (dram_out.Rose < Rose_request) | (dram_out.Lily < Lily_request) | 
                        (dram_out.Carnation < Carnation_request) | (dram_out.Baby_Breath < Baby_Breath_request));

//=======================================================
//                   DESIGN
//=======================================================


 

// always_ff @(posedge clk or negedge inf.rst_n) begin
//     if (!inf.rst_n) begin
//         cnt <= 0;
//     end
//     else begin
//         cnt <= cnt + 1;
//     end
// end

AXI4_LITE axi4_lite(
    .clk(clk),
    .inf(inf),
    .read(read_j),
    .write(write_j),
    .addr(read_addr),
    .data_read(r_data),
    .data_write(w_data),
    .read_done(read_done)
);
// always_comb begin
//     read_j = (cnt>50) ? 1 : 0;
//     write_j = (cnt>50) ? 0 : 1;
//     addr = {1'b1, 4'h0, 4'h0, 4'h0, 4'h0};
//     w_data = {8'hC2, 8'h58, 8'h2D, 8'h0B, 8'h78, 8'h52, 8'h19, 8'h11};
// end




//=======================================================
//                OUTPUT
//=======================================================


always_ff @(posedge clk, negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.out_valid <= 1'b0;
    end
    else if (current_state == OUT) begin
        inf.out_valid <= 1'b1;
    end
    else begin
        inf.out_valid <= 1'b0;
    end
end

always_ff @(posedge clk, negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.complete <= 1'b0;
    end
    else if (current_state == OUT) begin
        inf.complete <= !(overflow_flag | date_check | warn_stock);
    end
    else begin
        inf.complete <= 1'b0;
    end
end

always_ff @(posedge clk, negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.warn_msg <= No_Warn;
    end
    else if (current_state == OUT) begin
        if (overflow_flag) begin
            inf.warn_msg <= Restock_Warn;
        end
        else if (date_check) begin
            inf.warn_msg <= Date_Warn;
        end 
        else if (warn_stock) begin
            inf.warn_msg <= Stock_Warn;
        end
        else begin
            inf.warn_msg <= No_Warn;
        end
    end
    else begin
        inf.warn_msg <= No_Warn;
    end
end






endmodule










module AXI4_LITE(/*clk, AFS_inf inf, read, write, addr, data_read, data_write, read_done*/
    input clk,
    INF.AFS_inf inf, 
    input read,
    input write,
    input [16:0] addr,
    output logic [63:0] data_read,
    input [63:0] data_write,
    output logic read_done);
import usertype::*;
// ======================================================
// Reg & Wire Declaration
// ======================================================
typedef enum logic [2:0] {
    IDLE        = 3'd0,
    READ_ADDRESS = 3'd1,
    READ_DATA   = 3'd2,
    WRITE_ADDRESS = 3'd3,
    WRITE_DATA  = 3'd4,
    WRITE_BRESP = 3'd5
} state_t;
state_t current_state, next_state;
//=======================================================
//                   FSM
//=======================================================
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n)begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

always_comb begin
    case (current_state)
        IDLE: begin
            if (read) begin
                next_state = READ_ADDRESS;
			end
			else if (write) begin
				next_state = WRITE_ADDRESS;
			end
            else begin
                next_state = IDLE;
			end
        end
		READ_ADDRESS: begin
			if (inf.AR_VALID & inf.AR_READY) begin
				next_state = READ_DATA;
			end
			else begin
				next_state = READ_ADDRESS;
			end
		end
		READ_DATA: begin
			if (inf.R_VALID & inf.R_READY) begin
				next_state = IDLE;
			end
			else begin
				next_state = READ_DATA;
			end
		end
		WRITE_ADDRESS: begin
			if (inf.AW_VALID & inf.AW_READY) begin
				next_state = WRITE_DATA;
			end
			else begin
				next_state = WRITE_ADDRESS;
			end
		end
		WRITE_DATA: begin
            if (inf.W_VALID & inf.W_READY) begin
                next_state = WRITE_BRESP;
            end
            else begin
                next_state = WRITE_DATA;
		    end
        end
		WRITE_BRESP: begin
			if (inf.B_VALID & inf.B_READY) begin
				next_state = IDLE;
		    end
            else begin
                next_state = WRITE_BRESP;
            end
        end
        default: next_state = IDLE;
    endcase 
end
//=======================================================
//                   read
//=======================================================
//AR_ADDR
// always_comb begin
// 	// inf.AR_ADDR = 0;
// 	// if (current_state == READ_ADDRESS) begin
// 	// 	if (read) begin
//     if (current_state == IDLE) begin
//         inf.AR_ADDR = 0;
//     end
//     else  begin
// 			inf.AR_ADDR = addr;
// 	end
// 	// end
// end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.AR_ADDR <= 0;
    end
    else begin
        inf.AR_ADDR <= addr;
    end
end
//AR_VALID
always_comb begin
	inf.AR_VALID = 0;
	if (current_state == READ_ADDRESS) begin
		inf.AR_VALID = 1;
	end
end
//RREADY
always_comb begin
	inf.R_READY = 0;
	if (current_state == READ_DATA) begin
		inf.R_READY = 1;
	end
end
//DATA_READ
always_comb begin
    data_read = inf.R_DATA;
end
//read_done
always_comb begin
    read_done = 0;
    if (inf.R_VALID) begin
        read_done = 1;
    end
end
//=======================================================
//                   write
//=======================================================
//AR_WRITE
always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.AW_ADDR  <= 0;
    end
    else begin
        inf.AW_ADDR  <= addr;
    end
end
// always_comb begin
// 	// inf.AW_ADDR = 0;
// 	// if (current_state == WRITE_ADDRESS) begin
// 	// 	if (write) begin
//     if (current_state == IDLE) begin
//         inf.AW_ADDR = 0;
//     end
//     else  begin
//         inf.AW_ADDR = addr;
//     end
// 			// inf.AW_ADDR = addr;
// 	// 	end
// 	// end
// end
//AW_VALID
always_comb begin
	if (current_state == WRITE_ADDRESS) begin
		inf.AW_VALID  = 1;
	end
	else begin
		inf.AW_VALID  = 0;
	end
end
//W_DATA
always_comb begin
	inf.W_DATA = data_write;
end
// wvalid_m_inf 
always_comb begin
	inf.W_VALID = 0;
	if (current_state == WRITE_DATA) begin
		inf.W_VALID = 1;
	end
end
//B_READY
always_comb begin
	inf.B_READY = 0;
	if (current_state == WRITE_DATA || current_state == WRITE_BRESP) begin
		inf.B_READY = 1;
	end
end

endmodule