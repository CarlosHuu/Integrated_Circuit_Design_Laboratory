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
GF_divide = @(a,b) ( (a==15) * 15 + ((a~=15)&&(b~=15)) * mod(a-b,15) );
% GF addition (亦為減法): 若其中一個為 15 (零元)，則結果為另一個；否則：
%   result = inv_GF( XOR( GF(a), GF(b) ) )
% 注意：lookup 陣列為 1-indexed，所以 a 的 GF value為 GF(a+1) (a 為 exponent)
GF_add = @(a,b) ( (a==15) &&(b==15)) * 15+( (a==15) &&(b~=15)) * b + ( (a~=15)&&b==15 ) * a + ((a~=15)&&(b~=15)) * inv_GF( bitxor( GF(a+1), GF(b+1) ) + 1 );


%% main code start
% parameter
IP_WIDTH = 7;
pattern_number = 1;
max_count = 0;
error_flag = 0;
%% open the txt file that we needed to write for input and golden_ans
syndrome_output_dir = 'syndrome.txt';
fid_syndrome = fopen(syndrome_output_dir, 'w');
golden_ans_output_dir = 'golden_ans.txt';
fid_gold = fopen(golden_ans_output_dir, 'w');
%% starting generating pattern
for PATTERN_NUM = 0:pattern_number-1
    %% making syndrome using parity check matrix and error pattern
    % making random e
    e = zeros(15,1);
    e_error = randi([1, 15], 3, 1);
    if PATTERN_NUM == 99 || PATTERN_NUM == 0
        e_error = [4 6 13];
    end 
    e_error = sort(e_error);
    e(e_error) = 1;
    if PATTERN_NUM == 100 
        e = zeros(15,1);
    end
    % for debug
    
    syndrome = make_syndrome(e);
    % let syndrome length = 7
    temp = ones(1, IP_WIDTH)*15;
    temp(1:6) = syndrome;
    syndrome = temp;
    fprintf(fid_syndrome, 'PATTERN_NUM %d\n', PATTERN_NUM);
    for i = 1:IP_WIDTH-1
        fprintf(fid_syndrome, '%d\n', syndrome(i));
    end
        
    %% initialized ohm, sigma matrix
    ohm = [15 15 15 15 15 15 0];
    ohm = [ohm; syndrome];
    sigma = [15 15 15 15 15 15 15;
             0  15 15 15 15 15 15];
    %% initialized Quotient matrix and Remainder matrix
    Q = [];
    R = [];
    count = 1;
    %% main code
    while (1)
        [temp_quotient, temp_remainder] = poly_div(ohm(count, :), ohm(count+1, :), 7);
        Q = [Q; temp_quotient'];
        R = [R; temp_remainder];
        % xxx = poly_mult(temp_quotient, ohm(count+1,:), 7)
        temp_product = poly_add(poly_mult(temp_quotient, sigma(count+1,:), 7), sigma(count,:), 7);
        temp_product2 = poly_add(poly_mult(temp_quotient, ohm(count+1,:), 7), ohm(count,:), 7);
        sigma = [sigma; temp_product'];
        ohm = [ohm; temp_product2'];
        ohm_dim = check_dimension(temp_remainder, IP_WIDTH);
        sigma_dim = check_dimension(temp_product, IP_WIDTH);
        if(ohm_dim <= 2 && sigma_dim <= 3)
            break;
        end
        count = count + 1;
    end
    if(count >max_count)
        max_count = count;
    end
    % after iteration is finished
    % do chien search
    sigma_last = sigma(count+2,:);
    
    error_pattern = ones(15,1)*15;
    for alpha = 0:-1:-14
        temp_add = 15;
        for i = 1:IP_WIDTH
            temp = 0;
            for j = 1:i
                temp = GF_mult(temp, mod(alpha, 15));
            end
            temp = GF_mult(temp, sigma_last(i));
            temp_add = GF_add(temp_add, temp);
        end
        error_pattern(1-alpha) = temp_add;
    end
    error_location = [];
    for i = 1:15
        if(error_pattern(i) == 15)
            error_location = [error_location; i-1];
        end
    end
    
    % find the error location in e
    e_location = [];
    for i = 1:15
        if(e(i) == 1)
            e_location = [e_location; i-1];
        end
    end
    
    if(sum(error_location ~= e_location) ~= 0)
        fprintf("PATTERN %d: there are something in whole_algorithm \n", PATTERN_NUM);
        error_flag = 1;
    else
        fprintf("PATTERN %d Congradulation: you find all error location \n", PATTERN_NUM);
    end
    fprintf(fid_gold, 'PATTERN_NUM %d\n', PATTERN_NUM);
    if (length(error_location)==3)
        for i = 1:3
            fprintf(fid_gold, '%d\n', error_location(i));
        end
    elseif (length(error_location)==2)
        for i = 1:2
            fprintf(fid_gold, '%d\n', error_location(i));
        end
        fprintf(fid_gold, '%d\n', 15);
    elseif (length(error_location)==1)
        fprintf(fid_gold, '%d\n', error_location);
        for i = 1:2
            fprintf(fid_gold, '%d\n', 15);
        end
    elseif (length(error_location)==0)
        fprintf(fid_gold, '%d\n', error_location);
        for i = 1:3
            fprintf(fid_gold, '%d\n', 15);
        end
    end
end
fclose(fid_syndrome);
fclose(fid_gold);
if(error_flag == 0)
    fprintf("Congradulation: your design are all correct for %d pattern \n", PATTERN_NUM);
end

%% function for making syndrome using parity check matrix and error pattern
function syndrome = make_syndrome(e)
    %% for Look Up Table of the GF(2^4)
    PowerOfAlpha = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15];
    GF           = [1 2 4 8 3 6 12 11 5 10 7 14 15 13 9 0];
    inv_GF       = [15 0 1 4 2 8 5 10 3 14 9 7 6 13 11 12];
    %% 定義 GF 中的基本運算 (以 inline 區塊方式實作，不包成 function)
    % GF multiplication: 若 a 或 b 為 15 (零元)，則結果為 15；否則 a*b = mod(a+b,15)
    GF_mult = @(a,b) ( (a==15 || b==15) * 15 + ((a~=15)&&(b~=15)) * mod(a+b,15) );
    % GF division: a/b = mod(a-b,15)，前提 a 不為零，且 b 非零
    GF_divide = @(a,b) ( (a==15) * 15 + ((a~=15)&&(b~=15)) * mod(a-b,15) );
    % GF addition (亦為減法): 若其中一個為 15 (零元)，則結果為另一個；否則：
    %   result = inv_GF( XOR( GF(a), GF(b) ) )
    % 注意：lookup 陣列為 1-indexed，所以 a 的 GF value為 GF(a+1) (a 為 exponent)
    GF_add = @(a,b) ( (a==15) &&(b==15)) * 15+( (a==15) &&(b~=15)) * b + ( (a~=15)&&b==15 ) * a + ((a~=15)&&(b~=15)) * inv_GF( bitxor( GF(a+1), GF(b+1) ) + 1 );

    parity_check_matrix = zeros(6,15);
    for i = 1:6
        for j = 1:15
            temp = 0;
            for k = 1:i
                temp = GF_mult(temp, j-1);
            end
            parity_check_matrix(i,j) = temp;
        end
    end
    % 例如，指定一個 error pattern (error vector) e，長度 n
    % e 的每個元素同樣以 power-of-alpha 表示，15 代表無錯誤
    
    % change e matrix into GF
    e(e == 0) = 15;
    e(e == 1) = 0;
    
    %% 矩陣乘法：計算 syndrome = H * e （所有運算在 GF(2^4) 下進行）
    % syndrome 為一個 m x 1 的向量
    syndrome = ones(6,1)*15;  % 先以 15 (0) 初始化
    
    for i = 1:6
        % 對於 H 的每一列，計算 dot product
        temp = 15;  % 初始累加值為 15 (代表 0)
        for j = 1:15
            % 計算 H(i,j) 與 e(j) 的乘積 (GF 乘法)
            prod = GF_mult( parity_check_matrix(i,j), e(j) );
            % 將累加值與 prod 進行 GF 加法
            temp = GF_add( temp, prod );
        end
        syndrome(i) = temp;
    end
    
    %% 輸出結果
    % disp('Parity Check Matrix H (power of alpha):');
    % disp(parity_check_matrix);
    % disp('Error Pattern e (power of alpha):');
    % disp(e.');
    % disp('Syndrome = H * e (power of alpha):');
    % disp(syndrome.');
end

%% for polynominal divider function
function [quotient, remainder] = poly_div(dividend, divisor, IP_WIDTH)
    %% for Look Up Table of the GF(2^4)
    PowerOfAlpha = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15];
    GF           = [1 2 4 8 3 6 12 11 5 10 7 14 15 13 9 0];
    inv_GF       = [15 0 1 4 2 8 5 10 3 14 9 7 6 13 11 12];
    %% 定義 GF 中的基本運算 (以 inline 區塊方式實作，不包成 function)
    % GF multiplication: 若 a 或 b 為 15 (零元)，則結果為 15；否則 a*b = mod(a+b,15)
    GF_mult = @(a,b) ( (a==15 || b==15) * 15 + ((a~=15)&&(b~=15)) * mod(a+b,15) );
    % GF division: a/b = mod(a-b,15)，前提 a 不為零，且 b 非零
    GF_divide = @(a,b) ( (a==15) * 15 + ((a~=15)&&(b~=15)) * mod(a-b,15) );
    % GF addition (亦為減法): 若其中一個為 15 (零元)，則結果為另一個；否則：
    %   result = inv_GF( XOR( GF(a), GF(b) ) )
    % 注意：lookup 陣列為 1-indexed，所以 a 的 GF value為 GF(a+1) (a 為 exponent)
    GF_add = @(a,b) ( (a==15) &&(b==15)) * 15+( (a==15) &&(b~=15)) * b + ( (a~=15)&&b==15 ) * a + ((a~=15)&&(b~=15)) * inv_GF( bitxor( GF(a+1), GF(b+1) ) + 1 );
    %% main code start
    % setting IP_WIDTH
    
    % fill in with power of alpha
    % dividend = randi([0 15], IP_WIDTH, 1); 
    % divisor = randi([0 15], IP_WIDTH, 1); 
    
    % for debug
    % dividend = [15 15 15 15 15 15 0];
    % divisor  = [0 0 10 0 10 5 15]; 
    % 
    % dividend = [0 0 10 0 10 5 15];
    % divisor  = [0 5 15 10 15 15 15]; 
    
    % 初始化商與餘數
    quotient = ones(IP_WIDTH,1)*15;  % 初始設定均為 15 (即 0)
    remainder = dividend;
    %% 多項式除法運算 (長除法演算法)
    % 假設最高次係數位於陣列的第一個元素
    % 每一步：以當前餘數的第一個非零係數除以 divisor 的最高次項(即 divisor(1))，
    % 得到 quotient(i)；接著將 quotient(i)*divisor 整體「消去」餘數的對應項
    
    % polynomial have nonzero term starting at divisor_location
    divisor_location = 1;
    for i = IP_WIDTH:-1:1
        if divisor(i) ~= 15
            divisor_location = IP_WIDTH+1-i;
            break;
        end
    end
    
    
    for i = IP_WIDTH:-1:1
        % 只在餘數當前首係數非零 (不為15) 時進行運算
        if remainder(i) ~= 15 && i>=IP_WIDTH+1-divisor_location
            % 計算本步的商係數: quotient(i) = remainder(i) / divisor(1)
            quotient(i-(IP_WIDTH-divisor_location)) = GF_divide(remainder(i), divisor(IP_WIDTH+1-divisor_location));
            % 利用 quotient(i) 消去餘數中相對應的項
            for j = IP_WIDTH+1-divisor_location:-1:1
                % 僅對 divisor 當前係數非零執行
                if divisor(j) ~= 15
                    % 計算乘積： quotient(i) * divisor(j)
                    prod = GF_mult( quotient(i-(IP_WIDTH-divisor_location)), divisor(j) );
                    % 將對應餘數相減(在 GF 中加減相同)
                    remainder(i+j-(IP_WIDTH+1)+divisor_location) = GF_add( remainder(i+j-(IP_WIDTH+1)+divisor_location), prod );
                end
            end
            % for debug
            % disp(i)
            % disp('Quotient (power of alpha):');
            % disp(quotient.');
            % disp('Remainder (power of alpha):');
            % disp(remainder);
        end
    end
    
    %% 輸出結果
    % disp('Dividend (power of alpha):');
    % disp(dividend.');
    % disp('Divisor (power of alpha):');
    % disp(divisor.');
    % disp('Quotient (power of alpha):');
    % disp(quotient.');
    % disp('Remainder (power of alpha):');
    % disp(remainder);
end


%% for polynominal multiply function
function product = poly_mult(a, b, IP_WIDTH)
    %% for Look Up Table of the GF(2^4)
    PowerOfAlpha = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15];
    GF           = [1 2 4 8 3 6 12 11 5 10 7 14 15 13 9 0];
    inv_GF       = [15 0 1 4 2 8 5 10 3 14 9 7 6 13 11 12];
    %% 定義 GF 中的基本運算 (以 inline 區塊方式實作，不包成 function)
    % GF multiplication: 若 a 或 b 為 15 (零元)，則結果為 15；否則 a*b = mod(a+b,15)
    GF_mult = @(a,b) ( (a==15 || b==15) * 15 + ((a~=15)&&(b~=15)) * mod(a+b,15) );
    % GF division: a/b = mod(a-b,15)，前提 a 不為零，且 b 非零
    GF_divide = @(a,b) ( (a==15) * 15 + ((a~=15)&&(b~=15)) * mod(a-b,15) );
    % GF addition (亦為減法): 若其中一個為 15 (零元)，則結果為另一個；否則：
    %   result = inv_GF( XOR( GF(a), GF(b) ) )
    % 注意：lookup 陣列為 1-indexed，所以 a 的 GF value為 GF(a+1) (a 為 exponent)
    GF_add = @(a,b) ( (a==15) &&(b==15)) * 15+( (a==15) &&(b~=15)) * b + ( (a~=15)&&b==15 ) * a + ((a~=15)&&(b~=15)) * inv_GF( bitxor( GF(a+1), GF(b+1) ) + 1 );
    %% main code start
    product = ones(IP_WIDTH,1)*15;  % 初始設定均為 15 (即 0)
    for i = 1:IP_WIDTH
        temp_add = ones(IP_WIDTH,1)*15;
        for j = 1:IP_WIDTH
            temp_add(j) = GF_mult(a(j), b(i));
        end
        temp_temp_add = ones(IP_WIDTH,1)*15;
        temp_temp_add(i:IP_WIDTH) = temp_add(1:IP_WIDTH-i+1);
        for j = 1:IP_WIDTH
            product(j) = GF_add(product(j), temp_temp_add(j));
        end
    end
   
    
    %% 輸出結果
    % disp('a (power of alpha):');
    % disp(a);
    % disp('b (power of alpha):');
    % disp(b);
    % disp('product (power of alpha):');
    % disp(product);
end

%% for polynominal add function
function c = poly_add(a, b, IP_WIDTH)
    %% for Look Up Table of the GF(2^4)
    PowerOfAlpha = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15];
    GF           = [1 2 4 8 3 6 12 11 5 10 7 14 15 13 9 0];
    inv_GF       = [15 0 1 4 2 8 5 10 3 14 9 7 6 13 11 12];
    %% 定義 GF 中的基本運算 (以 inline 區塊方式實作，不包成 function)
    % GF multiplication: 若 a 或 b 為 15 (零元)，則結果為 15；否則 a*b = mod(a+b,15)
    GF_mult = @(a,b) ( (a==15 || b==15) * 15 + ((a~=15)&&(b~=15)) * mod(a+b,15) );
    % GF division: a/b = mod(a-b,15)，前提 a 不為零，且 b 非零
    GF_divide = @(a,b) ( (a==15) * 15 + ((a~=15)&&(b~=15)) * mod(a-b,15) );
    % GF addition (亦為減法): 若其中一個為 15 (零元)，則結果為另一個；否則：
    %   result = inv_GF( XOR( GF(a), GF(b) ) )
    % 注意：lookup 陣列為 1-indexed，所以 a 的 GF value為 GF(a+1) (a 為 exponent)
    GF_add = @(a,b) ( (a==15) &&(b==15)) * 15+( (a==15) &&(b~=15)) * b + ( (a~=15)&&b==15 ) * a + ((a~=15)&&(b~=15)) * inv_GF( bitxor( GF(a+1), GF(b+1) ) + 1 );
    %% main code start
    c = ones(IP_WIDTH,1)*15;  % 初始設定均為 15 (即 0)
    for i = 1:IP_WIDTH
        c(i) = GF_add(a(i), b(i));
    end
   
    
    %% 輸出結果
    % disp('a (power of alpha):');
    % disp(a);
    % disp('b (power of alpha):');
    % disp(b);
    % disp('c (power of alpha):');
    % disp(c);
end

%% function for check dimension
function dimension = check_dimension(a, IP_WIDTH)
    dimension = 1;
    for i = IP_WIDTH:-1:1
        if(a(i)~= 15)
            dimension = i-1;
            break;
        end
    end
end