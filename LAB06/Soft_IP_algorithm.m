%% some SPEC.
%  input of dividend and divisor are power of alpha
%  input length is IP_WIDTH*4 bits
%  output of quotient are power of alpha
%  output length is IP_WIDTH*4 bits
%  in GF:
%  add and subtract are the same, operation => c = inv_GF( XOR(GF(a), GF(b)) )
%  inv_GF means inverse of GF encoding
%  multiply operation will add the power of alpha, then making modulus of
%  15, multiply operation => a*b = c = mod((a+b), 15)
%  divide operation will subtract the power of aplha, then making modulus
%  of 15, divide operatioin => a/b = c = mod((a-b), 15)

%% clear all
clear all; clc; close all;
%% for Look Up Table of the GF(2^4)
PowerOfAlpha = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15];
GF           = [1 2 4 8 3 6 12 11 5 10 7 14 15 13 9 0];
inv_GF       = [15 0 1 4 2 8 5 10 3 14 9 7 6 13 11 12];
%% 定義 GF 中的基本運算 (以 inline 區塊方式實作，不包成 function)
% GF multiplication: 若 a 或 b 為 15 (零元)，則結果為 15；否則 a*b = mod(a+b,15)
GF_mult = @(a,b) ( (a==15 || b==15) * 15 + ((a~=15)&&(b~=15)) * mod(a+b,15) );
% GF division: a/b = mod(a-b,15)，前提 a 不為零，且 b 非零
% GF_divide = @(a,b) ( (a==15) * 15 + ((a~=15)&&(b~=15)) * mod(a-b,15) );
GF_divide = @(a,b) ( (a==15) * 15 + ((a~=15)) * mod(a-b,15));
% GF addition (亦為減法): 若其中一個為 15 (零元)，則結果為另一個；否則：
%   result = inv_GF( XOR( GF(a), GF(b) ) )
% 注意：lookup 陣列為 1-indexed，所以 a 的 GF value為 GF(a+1) (a 為 exponent)
GF_add = @(a,b) ( (a==15) &&(b==15)) * 15+( (a==15) &&(b~=15)) * b + ( (a~=15)&&b==15 ) * a + ((a~=15)&&(b~=15)) * inv_GF( bitxor( GF(a+1), GF(b+1) ) + 1 );
%% main code start
% setting IP_WIDTH
IP_WIDTH =7; 
pattern_number = 1;

%% open the txt file that we needed to read for input and golden_ans
dividend_output_dir = ['dividend_' num2str(IP_WIDTH) '.txt']
fid_dividend = fopen(dividend_output_dir, 'r');
divisor_output_dir = ['divisor_' num2str(IP_WIDTH) '.txt'];
fid_divisor = fopen(divisor_output_dir, 'r');
golden_ans_output_dir = ['golden_ans_IP_' num2str(IP_WIDTH) '.txt'];
fid_gold = fopen(golden_ans_output_dir, 'r');
%% setting correct flag
error_flag = 0;




for PATTERN_NUM = 0:pattern_number-1
    dividend = ones(IP_WIDTH, 1)*15;
    divisor = ones(IP_WIDTH, 1)*15;
    golden_ans = ones(IP_WIDTH, 1)*15;
    remainder_all = [];
    quotient_all = [];
    % read dividend
    token = fscanf(fid_dividend, '%s', 1);
    if strcmp(token, 'PATTERN_NUM')
        % 讀取pattern編號
        current_PAT = fscanf(fid_dividend, '%d', 1);
        % 依據檔案內容，每個pattern後面有7個數字
        dividend = fscanf(fid_dividend, '%d', IP_WIDTH);
        
        % 顯示讀取結果
        % fprintf('Pattern %d: ', current_PAT);
        % fprintf('%d ', dividend);
        % fprintf('\n');
    end
    % read divisor
    token = fscanf(fid_divisor, '%s', 1);
    if strcmp(token, 'PATTERN_NUM')
        % 讀取pattern編號
        current_PAT = fscanf(fid_divisor, '%d', 1);
        % 依據檔案內容，每個pattern後面有7個數字
        divisor = fscanf(fid_divisor, '%d', IP_WIDTH);
        
        % 顯示讀取結果
        % fprintf('Pattern %d: ', current_PAT);
        % fprintf('%d ', divisor);
        % fprintf('\n');
    end
    % read gold_ans
    token = fscanf(fid_gold, '%s', 1);
    if strcmp(token, 'PATTERN_NUM')
        % 讀取pattern編號
        current_PAT = fscanf(fid_gold, '%d', 1);
        % 依據檔案內容，每個pattern後面有7個數字
        golden_ans = fscanf(fid_gold, '%d', IP_WIDTH);
        
        % 顯示讀取結果
        % fprintf('Pattern %d: ', current_PAT);
        % fprintf('%d ', golden_ans);
        % fprintf('\n');
    end

    %% after reading input, starting caculate
    % first check b_dim_max
    b = divisor;
    b_dim_max = check_dimension(b, IP_WIDTH);
    b_dim_max = b_dim_max + 1;
    remainder = dividend;
    quotient  = ones(IP_WIDTH,1)*15;
    remainder_temp = ones(IP_WIDTH,1)*15;
    remainder_all = [remainder_all; remainder'];
    quotient_all = [quotient_all; quotient'];
    minus_all = [];
    for i = IP_WIDTH:-1:1
        a_dim_max = check_dimension(remainder, IP_WIDTH);
        a_dim_max = a_dim_max + 1;
        minus_temp = ones(IP_WIDTH,1)*15;
        % finding quotient
        quotient(i) = GF_divide(remainder(a_dim_max), b(b_dim_max));
        % disp(quotient);
        % quotient(i) = GF_mult(quotient(i), b(IP_WIDTH-i+1));
        % disp("real_quotient");
        % disp(quotient);
        % disp(["a_dim_max" num2str(a_dim_max)]);
        % disp(["b_dim_max" num2str(b_dim_max)]);
        if(b_dim_max <= IP_WIDTH-i+1 && b_dim_max <= a_dim_max)
            quotient(i) = quotient(i);
        else
            quotient(i) = 15;
        end
        % disp(remainder);
        % finding minus temp
        for j = IP_WIDTH:-1:i
            minus_temp(j) = GF_mult(quotient(i), b(j-i+1));
        end
        minus_temp_max_dim = check_dimension(minus_temp, IP_WIDTH);
        minus_temp_max_dim = minus_temp_max_dim+1;
        if minus_temp_max_dim ~= a_dim_max
            for j = IP_WIDTH:-1:i
                minus_temp(j) = 15;
            end
            quotient(i) = 15;
        end
        % subtracting
        for k = 1:IP_WIDTH
            remainder_temp(k) = GF_add(remainder(k), minus_temp(k));
        end
        remainder = remainder_temp;
        remainder_all = [remainder_all; remainder'];
        quotient_all = [quotient_all; quotient'];
        minus_all = [minus_all; minus_temp'];
    end
    if(sum(quotient ~= golden_ans) == 0)
        fprintf("PATTERN %d Congradulation: you find all error location \n", PATTERN_NUM);
    else
        fprintf("PATTERN %d: there are something wrong in SOFT_IP_algorithm \n", PATTERN_NUM);
        error_flag = 1;
        break;
    end
end
if(error_flag == 0)
    fprintf("Congradulation: your design are all correct for %d pattern \n", PATTERN_NUM);
end

fclose(fid_divisor);
fclose(fid_dividend);
fclose(fid_gold);


%% function for check dimension
function dimension = check_dimension(a, IP_WIDTH)
    dimension = 0;
    for i = IP_WIDTH:-1:1
        if(a(i)~= 15)
            dimension = i-1;
            break;
        end
    end
end