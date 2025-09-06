module HF(
    // Input signals
    input [24:0] symbol_freq,
    // Output signals
    output reg [19:0] out_encoded
);

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment

//================================================================
//    DESIGN
//================================================================
wire [4:0] a, b, c, d, e;
// wire [4:0] a_encode, b_encode, c_encode, d_encode, e_encode;
wire [4:0] out0, out1, out2, out3, out4;
wire [4:0] out0_en ,out1_en, out2_en, out3_en, out4_en; 
// wire [5:0] stage1_0, stage1_1, stage1_2, stage1_3;

assign a = symbol_freq[24:20];
assign b = symbol_freq[19:15];
assign c = symbol_freq[14:10];
assign d = symbol_freq[9:5];
assign e = symbol_freq[4:0];

///////////////////////////////////
Sort5 sorting (.freq0(a), .freq1(b), .freq2(c), .freq3(d), .freq4(e), 
.order_0(out0), .order_1(out1), .order_2(out2), .order_3(out3), .order_4(out4), 
.order_en_0(out0_en), .order_en_1(out1_en), .order_en_2(out2_en), .order_en_3(out3_en), .order_en_4(out4_en)); 
///////////////////////////////////

reg [4:0] stage1_0, stage1_1, stage1_2;
reg [5:0] stage1_3;
reg [4:0] stage1_0_en, stage1_1_en, stage1_2_en, stage1_3_en;
wire [5:0] plus1;
wire [4:0] plus_order_1;
assign plus_order_1 = out0_en | out1_en;
assign plus1= out0 + out1;
 
always @(*) begin
    if (plus1 <= out2)begin
        stage1_0 = plus1;
        stage1_0_en = plus_order_1;
        stage1_1 = out2;
        stage1_1_en = out2_en;
        stage1_2    = out3;
        stage1_2_en = out3_en;
        stage1_3    = out4;
        stage1_3_en = out4_en;
    end
    else if (plus1 <= out3)begin
            stage1_0    = out2;
            stage1_0_en = out2_en;
            stage1_1    = plus1;
            stage1_1_en = plus_order_1;
            stage1_2    = out3;
            stage1_2_en = out3_en;
            stage1_3    = out4;
            stage1_3_en = out4_en;
        end
        else if(plus1 <= out4) begin
            stage1_0    = out2;
            stage1_0_en = out2_en;
            stage1_1    = out3;
            stage1_1_en = out3_en;
            stage1_2    = plus1;
            stage1_2_en = plus_order_1;
            stage1_3    = out4;
            stage1_3_en = out4_en;
            end
        else begin
            stage1_0 = out2;
            stage1_0_en = out2_en;
            stage1_1 = out3;
            stage1_1_en = out3_en;
            stage1_2    = out4;
            stage1_2_en = out4_en;
            stage1_3    = plus1;
            stage1_3_en = plus_order_1;
        end
    // else begin
    //     if(plus1 <= out3)begin
    //         stage1_0    = out2;
    //         stage1_0_en = out2_en;
    //         stage1_1    = plus1;
    //         stage1_1_en = plus_order_1;
    //         stage1_2    = out3;
    //         stage1_2_en = out3_en;
    //         stage1_3    = out4;
    //         stage1_3_en = out4_en;
    //     end
    //     else if(plus1 <= out4) begin
    //         stage1_0    = out2;
    //         stage1_0_en = out2_en;
    //         stage1_1    = out3;
    //         stage1_1_en = out3_en;
    //         stage1_2    = plus1;
    //         stage1_2_en = plus_order_1;
    //         stage1_3    = out4;
    //         stage1_3_en = out4_en;
    //         end
    //     else begin
    //         stage1_0 = out2;
    //         stage1_0_en = out2_en;
    //         stage1_1 = out3;
    //         stage1_1_en = out3_en;
    //         stage1_2    = out4;
    //         stage1_2_en = out4_en;
    //         stage1_3    = plus1;
    //         stage1_3_en = plus_order_1;
    //     end
    // end
end

////////
reg [4:0] stage2_0;
reg [5:0] stage2_1, stage2_2;
reg [4:0] stage2_0_en, stage2_1_en, stage2_2_en;
wire [5:0] plus2;
wire [4:0] plus_order_2;
assign plus_order_2 = stage1_0_en | stage1_1_en;
assign plus2= stage1_0 + stage1_1;

always @(*) begin
    if (plus2 <= stage1_2)begin
        stage2_0 = plus2;
        stage2_0_en = plus_order_2;
        stage2_1 = stage1_2;
        stage2_1_en = stage1_2_en;
        stage2_2    = stage1_3;
        stage2_2_en = stage1_3_en;
    end
    else if(plus2 <= stage1_3)begin
        stage2_0    = stage1_2;
        stage2_0_en = stage1_2_en;
        stage2_1    = plus2;
        stage2_1_en = plus_order_2;
        stage2_2    = stage1_3;
        stage2_2_en = stage1_3_en;
    end
    else begin
        stage2_0 = stage1_2;
        stage2_0_en = stage1_2_en;
        stage2_1 = stage1_3;
        stage2_1_en = stage1_3_en;
        stage2_2    = plus2;
        stage2_2_en = plus_order_2;
    end
end
////////
// reg [7:0] stage3_0, stage3_1;
reg [4:0] stage3_0_en, stage3_1_en;
wire [6:0] plus3;
wire [4:0] plus_order_3;
assign plus_order_3 = stage2_0_en | stage2_1_en;
assign plus3= stage2_0 + stage2_1;

always @(*) begin
    if (plus3 <= stage2_2)begin
        // stage3_0 = plus3;
        stage3_0_en = plus_order_3;
        // stage3_1 = stage2_2;
        stage3_1_en = stage2_2_en;
    end
    else begin
        // stage3_0 = stage2_2;
        stage3_0_en = stage2_2_en;
        // stage3_1 = plus3;
        stage3_1_en = plus_order_3;
    end
end


///////////////
wire [3:0] left_vector_a, right_vector_a;
wire [3:0] left_vector_b, right_vector_b;
wire [3:0] left_vector_c, right_vector_c;
wire [3:0] left_vector_d, right_vector_d;
wire [3:0] left_vector_e, right_vector_e;
assign left_vector_a = {out0_en[4], stage1_0_en[4], stage2_0_en[4], stage3_0_en[4]};
assign right_vector_a = {out1_en[4], stage1_1_en[4], stage2_1_en[4], stage3_1_en[4]};
assign left_vector_b = {out0_en[3], stage1_0_en[3], stage2_0_en[3], stage3_0_en[3]};
assign right_vector_b = {out1_en[3], stage1_1_en[3], stage2_1_en[3], stage3_1_en[3]};
assign left_vector_c = {out0_en[2], stage1_0_en[2], stage2_0_en[2], stage3_0_en[2]};
assign right_vector_c = {out1_en[2], stage1_1_en[2], stage2_1_en[2], stage3_1_en[2]};
assign left_vector_d = {out0_en[1], stage1_0_en[1], stage2_0_en[1], stage3_0_en[1]};
assign right_vector_d = {out1_en[1], stage1_1_en[1], stage2_1_en[1], stage3_1_en[1]};
assign left_vector_e = {out0_en[0], stage1_0_en[0], stage2_0_en[0], stage3_0_en[0]};
assign right_vector_e = {out1_en[0], stage1_1_en[0], stage2_1_en[0], stage3_1_en[0]};
////////////////////////////////
wire [3:0] a_encode, b_encode, c_encode, d_encode, e_encode;
maping_encode  a_ans( .left_encode(left_vector_a), .right_encode(right_vector_a), .output_encode(a_encode));
maping_encode  b_ans( .left_encode(left_vector_b), .right_encode(right_vector_b), .output_encode(b_encode));
maping_encode  c_ans( .left_encode(left_vector_c), .right_encode(right_vector_c), .output_encode(c_encode));
maping_encode  d_ans( .left_encode(left_vector_d), .right_encode(right_vector_d), .output_encode(d_encode));
maping_encode  e_ans( .left_encode(left_vector_e), .right_encode(right_vector_e), .output_encode(e_encode));

always@(*)begin
    out_encoded = {a_encode, b_encode, c_encode, d_encode, e_encode};
end


endmodule


module Sort5( freq0, freq1, freq2, freq3, freq4, order_0, order_1, order_2, order_3, order_4, order_en_0, order_en_1, order_en_2, order_en_3, order_en_4);

    input [4:0] freq0, freq1, freq2, freq3, freq4;
    output [4:0] order_0, order_1, order_2, order_3, order_4;
    output [4:0] order_en_0, order_en_1, order_en_2, order_en_3, order_en_4;

    localparam a_en =5'b10000;
    localparam b_en =5'b01000;
    localparam c_en =5'b00100;
    localparam d_en =5'b00010;
    localparam e_en =5'b00001;

    reg [4:0] num0, num1, num2, num3, num4;
    reg [4:0] num0_en, num1_en, num2_en, num3_en, num4_en;
    reg [4:0] layer1_0, layer1_1, layer1_2, layer1_3, layer1_4; //layer 1
    reg [4:0] layer2_0, layer2_1, layer2_2, layer2_3, layer2_4; //layer 2
    reg [4:0] layer3_0, layer3_1, layer3_2, layer3_3, layer3_4; //layer 3
    reg [4:0] layer4_0, layer4_1, layer4_2, layer4_3, layer4_4; //layer 4
    reg [4:0] layer5_0, layer5_1, layer5_2, layer5_3, layer5_4; //layer 5

    reg [4:0] layer1_0_en, layer1_1_en, layer1_2_en, layer1_3_en, layer1_4_en; //layer 1
    reg [4:0] layer2_0_en, layer2_1_en, layer2_2_en, layer2_3_en, layer2_4_en; //layer 2
    reg [4:0] layer3_0_en, layer3_1_en, layer3_2_en, layer3_3_en, layer3_4_en; //layer 3
    reg [4:0] layer4_0_en, layer4_1_en, layer4_2_en, layer4_3_en, layer4_4_en; //layer 4
    reg [4:0] layer5_0_en, layer5_1_en, layer5_2_en, layer5_3_en, layer5_4_en; //layer 5

always @(*)
    begin
        {num0, num1, num2, num3, num4} = {freq0, freq1, freq2, freq3, freq4};
        {num0_en, num1_en, num2_en, num3_en, num4_en} = {a_en, b_en, c_en, d_en, e_en};
        ////////////////////////////////////////////////////////////////////////////////////layer 1
        if (num0 <= num3) begin
            layer1_0 = num0;
            layer1_0_en = num0_en;
            layer1_3 = num3;
            layer1_3_en = num3_en;
        end
        else begin
            layer1_0 = num3;
            layer1_0_en = num3_en;
            layer1_3 = num0;
            layer1_3_en = num0_en;
        end
        ////
        if (num1 <= num4) begin
            layer1_1 = num1;
            layer1_1_en = num1_en;
            layer1_4 = num4;
            layer1_4_en = num4_en;
        end
        else begin
            layer1_1 = num4;
            layer1_1_en = num4_en;
            layer1_4 = num1;
            layer1_4_en = num1_en;
        end
        layer1_2 = num2;
        layer1_2_en = num2_en;
 ////////////////////////////////////////////////////////////////////////////////////layer 2
        if (layer1_0 > layer1_2 ||((layer1_0 == layer1_2)&&(layer1_0_en < layer1_2_en))) begin
            layer2_0 = layer1_2;
            layer2_0_en = layer1_2_en;
            layer2_2 = layer1_0;
            layer2_2_en = layer1_0_en;
        end
        else begin
            layer2_0 = layer1_0;
            layer2_0_en = layer1_0_en;
            layer2_2 = layer1_2;
            layer2_2_en = layer1_2_en;
        end
        
        if (layer1_1 > layer1_3 || ((layer1_1 == layer1_3)&&(layer1_1_en < layer1_3_en)))begin
            layer2_1    = layer1_3;
            layer2_1_en = layer1_3_en;
            layer2_3    = layer1_1;
            layer2_3_en = layer1_1_en;
        end
        else begin
            layer2_1    = layer1_1;
            layer2_1_en = layer1_1_en;
            layer2_3    = layer1_3;
            layer2_3_en = layer1_3_en;
        end


        layer2_4 = layer1_4;
        layer2_4_en = layer1_4_en;
        
        ////////////////////////////////////////////////////////////////////////////////////layer 3
        if (layer2_0 > layer2_1 || ((layer2_0 == layer2_1)&&(layer2_0_en < layer2_1_en))) begin
            layer3_0    = layer2_1;
            layer3_0_en = layer2_1_en;
            layer3_1    = layer2_0;
            layer3_1_en = layer2_0_en;
        end
        else begin
            layer3_0    = layer2_0;
            layer3_0_en = layer2_0_en;
            layer3_1    = layer2_1;
            layer3_1_en = layer2_1_en;
        end
        ////
        if (layer2_2 > layer2_4 || ((layer2_2 == layer2_4)&&(layer2_2_en < layer2_4_en))) begin
            layer3_2    = layer2_4;
            layer3_2_en = layer2_4_en;
            layer3_4    = layer2_2;
            layer3_4_en = layer2_2_en;
        end
        else begin
            layer3_2    = layer2_2;
            layer3_2_en = layer2_2_en;
            layer3_4    = layer2_4;
            layer3_4_en = layer2_4_en;
        end
        layer3_3 = layer2_3;
        layer3_3_en = layer2_3_en;
        ////////////////////////////////////////////////////////////////////////////////////layer 4
        if (layer3_1 > layer3_2 || ((layer3_1 == layer3_2)&&(layer3_1_en < layer3_2_en))) begin
            layer4_1 = layer3_2;
            layer4_1_en = layer3_2_en;
            layer4_2 = layer3_1;
            layer4_2_en = layer3_1_en;
        end
        else begin
            layer4_1 = layer3_1;
            layer4_1_en = layer3_1_en;
            layer4_2 = layer3_2;
            layer4_2_en = layer3_2_en;
        end
        ////
        if (layer3_3 > layer3_4 || ((layer3_3 == layer3_4)&&(layer3_3_en < layer3_4_en))) begin
            layer4_3 = layer3_4;
            layer4_3_en = layer3_4_en;
            layer4_4 = layer3_3;
            layer4_4_en = layer3_3_en;
        end
        else begin
            layer4_3 = layer3_3;
            layer4_3_en = layer3_3_en;
            layer4_4 = layer3_4;
            layer4_4_en = layer3_4_en;
        end
        layer4_0 = layer3_0;
        layer4_0_en = layer3_0_en;
        ////////////////////////////////////////////////////////////////////////////////////layer 5
        if (layer4_2 > layer4_3 || ((layer4_2 == layer4_3)&&(layer4_2_en < layer4_3_en)))begin
            layer5_2    = layer4_3;
            layer5_2_en = layer4_3_en;
            layer5_3    = layer4_2;
            layer5_3_en = layer4_2_en;
        end
        else begin
            layer5_2    = layer4_2;
            layer5_2_en = layer4_2_en;
            layer5_3    = layer4_3;
            layer5_3_en = layer4_3_en;
        end
        layer5_0 = layer4_0;
        layer5_0_en = layer4_0_en;
        layer5_1 = layer4_1;
        layer5_1_en = layer4_1_en;
        layer5_4 = layer4_4;
        layer5_4_en = layer4_4_en;
    end


assign {order_0, order_1, order_2, order_3, order_4} = {layer5_0, layer5_1, layer5_2, layer5_3, layer5_4};
assign {order_en_0, order_en_1, order_en_2, order_en_3, order_en_4} = {layer5_0_en, layer5_1_en, layer5_2_en, layer5_3_en, layer5_4_en};

endmodule 

module maping_encode ( left_encode, right_encode, output_encode);
    input [3:0] left_encode, right_encode;
    output [3:0] output_encode;
    reg[3:0] thr,sec,fir,zero;

    always @(*) begin
        if (left_encode[0] == 1'b1)begin
            thr = 4'b0000;
        end
        else if (right_encode[0] == 1'b1)begin
            thr = 4'b1000;
        end
        else begin
            thr = 4'b0000;
        end
    end
    always @(*) begin
        if (left_encode[1] == 1'b1)begin
            sec = 4'b0000 | thr;
        end
        else if (right_encode[1] == 1'b1)begin
            sec = 4'b0100 | thr;
        end
        else begin
            sec = thr >> 1;
        end
    end
    always @(*) begin
        if (left_encode[2] == 1'b1)begin
            fir = 4'b0000 | sec;
        end
        else if (right_encode[2] == 1'b1)begin
            fir = 4'b0010 | sec;
        end
        else begin
            fir = sec >> 1;
        end
    end
    always @(*) begin
        if (left_encode[3] == 1'b1)begin
            zero = 4'b0000 | fir;
        end
        else if (right_encode[3] == 1'b1)begin
            zero = 4'b0001 | fir;
        end
        else begin
            zero = fir >> 1;
        end
    end
    assign output_encode = zero;
endmodule

// module maping_encode ( left_encode, right_encode, output_encode);
//     input [3:0] left_encode, right_encode;
//     output reg [3:0]  output_encode;

//     wire [7:0] combine ;

//     assign combine = {left_encode, right_encode};
    
//     always@(*)begin
//         case(combine) 
//             8'b00000001 : output_encode = 4'b0001;
//             8'b00000011 : output_encode = 4'b0011;
//             8'b00000101 : output_encode = 4'b0011;
//             8'b00000111 : output_encode = 4'b1110;
//             8'b00001001 : output_encode = 4'b0011;
//             8'b00001011 : output_encode = 4'b0111;
//             8'b00001101 : output_encode = 4'b0111;
//             8'b00010000 : output_encode = 4'b0000;
//             8'b00010010 : output_encode = 4'b0001;
//             8'b00010100 : output_encode = 4'b0001;

//             8'b00010110 : output_encode = 4'b0011;
//             8'b00011000 : output_encode = 4'b0001;
//             8'b00011010 : output_encode = 4'b0011;
//             8'b00011100 : output_encode = 4'b0011;
//             8'b00011110 : output_encode = 4'b0111;
//             8'b00100001 : output_encode = 4'b0010;
//             8'b00100101 : output_encode = 4'b0101;
//             8'b00101001 : output_encode = 4'b0101;
//             8'b00101101 : output_encode = 4'b1011;
//             8'b00110000 : output_encode = 4'b0000;

//             8'b00110100 : output_encode = 4'b0001;
//             8'b00111000 : output_encode = 4'b0001;
//             8'b00111100 : output_encode = 4'b0011;
//             8'b01000001 : output_encode = 4'b0010;
//             8'b01000011 : output_encode = 4'b0110;
//             8'b01001001 : output_encode = 4'b0101;
//             8'b01001011 : output_encode = 4'b1101;
//             8'b01010000 : output_encode = 4'b0000;
//             8'b01010010 : output_encode = 4'b0010;
//             8'b01011000 : output_encode = 4'b0001;

//             8'b01011010 : output_encode = 4'b0101;
//             8'b01100001 : output_encode = 4'b0100;
//             8'b01101001 : output_encode = 4'b1001;
//             8'b01110000 : output_encode = 4'b0000;
//             8'b01111000 : output_encode = 4'b0001;
//             8'b10000001 : output_encode = 4'b0010;
//             8'b10000011 : output_encode = 4'b0110;
//             8'b10000101 : output_encode = 4'b0110;
//             8'b10000111 : output_encode = 4'b1110;
//             8'b10010000 : output_encode = 4'b0000;

//             8'b10010010 : output_encode = 4'b0010;
//             8'b10010100 : output_encode = 4'b0010;
//             8'b10010110 : output_encode = 4'b0110;
//             8'b10100001 : output_encode = 4'b0100;
//             8'b10100101 : output_encode = 4'b1010;
//             8'b10110000 : output_encode = 4'b0000;
//             8'b10110100 : output_encode = 4'b0010;
//             8'b11000001 : output_encode = 4'b0100;
//             8'b11000011 : output_encode = 4'b1100;
//             8'b11010000 : output_encode = 4'b0000;

//             8'b11010010 : output_encode = 4'b0100;
//             8'b11100001 : output_encode = 4'b1000;

//             default : output_encode = 4'b1111;
//         endcase 
//     end
    
// endmodule