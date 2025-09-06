function bin_str = ieee_to_binary(number)
    % 這個函數將 IEEE 754 單精度浮點數轉換為二進制格式
    % number: 要轉換的浮點數
    bytes = typecast(single(number), 'uint32');
    num_bits = 32;
    % 轉換為二進制字串
    bin_str = dec2bin(bytes, num_bits);
end

fileID_in_str = fopen('input.txt', 'w');
fileID_k_weight = fopen('kweight.txt', 'w');
fileID_q_weight = fopen('qweight.txt', 'w');
fileID_v_weight = fopen('vweight.txt', 'w');
fileID_out_weight = fopen('outweight.txt', 'w');
fileID_Final_res_bin = fopen('ans.txt', 'w');

for pattern_idx = 0:99
    % token
    in_str = single(rand(5, 4) * 1.0 - 0.5);   %-0.5~0.5
    % 初始化權重矩陣 (4 x 4)
    k_weight = single(rand(4, 4) * 1.0 - 0.5);  %-0.5~0.5
    q_weight = single(rand(4, 4) * 1.0 - 0.5);  %-0.5~0.5
    v_weight = single(rand(4, 4) * 1.0 - 0.5);  %-0.5~0.5
    out_weight = single(rand(4, 4) * 1.0 - 0.5);  %-0.5~0.5
    % 計算 K, Q, V 矩陣
    K = in_str * k_weight';
    Q = in_str * q_weight';
    V = in_str * v_weight';
    
    % 將 K, Q, V 分成兩個 heads
    K_head1 = K(:, 1:2);
    K_head2 = K(:, 3:4);
    Q_head1 = Q(:, 1:2);
    Q_head2 = Q(:, 3:4);
    V_head1 = V(:, 1:2);
    V_head2 = V(:, 3:4);
    
    
    Score1=Q_head1*K_head1';
    Score2=Q_head2*K_head2';
    
    Score1 = Score1 / sqrt(2);
    Score2 = Score2 / sqrt(2);
    
    Score1_softmax = exp(Score1) ./ sum(exp(Score1), 2);
    Score2_softmax = exp(Score2) ./ sum(exp(Score2), 2);
    
    Head_Out1 = Score1_softmax*V_head1;
    Head_Out2 = Score2_softmax*V_head2;
    Head_Out = [Head_Out1, Head_Out2];
    
    
    
    Final_res = Head_Out*out_weight';
    
    
    
    
    
    % 以下都是轉成二進位制
    in_str_bin = arrayfun(@ieee_to_binary, in_str, 'UniformOutput', false);
    k_weight_bin = arrayfun(@ieee_to_binary, k_weight, 'UniformOutput', false);
    q_weight_bin = arrayfun(@ieee_to_binary, q_weight, 'UniformOutput', false);
    v_weight_bin = arrayfun(@ieee_to_binary, v_weight, 'UniformOutput', false);
    out_weight_bin = arrayfun(@ieee_to_binary, out_weight, 'UniformOutput', false);
    
    K_bin = arrayfun(@ieee_to_binary, K, 'UniformOutput', false);
    Q_bin = arrayfun(@ieee_to_binary, Q, 'UniformOutput', false);
    V_bin = arrayfun(@ieee_to_binary, V, 'UniformOutput', false);
    
    K_head1_bin = K_bin(:, 1:2);
    K_head2_bin = K_bin(:, 3:4);
    Q_head1_bin = Q_bin(:, 1:2);
    Q_head2_bin = Q_bin(:, 3:4);
    V_head1_bin = V_bin(:, 1:2);
    V_head2_bin = V_bin(:, 3:4);
    
    
    Score1_bin = arrayfun(@ieee_to_binary, Score1, 'UniformOutput', false);       %已經除以根號2的結果
    Score2_bin = arrayfun(@ieee_to_binary, Score2, 'UniformOutput', false);       %已經除以根號2的結果
    
    Score1_softmax_bin = arrayfun(@ieee_to_binary, Score1_softmax, 'UniformOutput', false);    
    Score2_softmax_bin = arrayfun(@ieee_to_binary, Score2_softmax, 'UniformOutput', false);
    
    Head_Out1_bin = arrayfun(@ieee_to_binary, Head_Out1 , 'UniformOutput', false); 
    Head_Out2_bin = arrayfun(@ieee_to_binary, Head_Out2 , 'UniformOutput', false); 
    
    Head_Out_bin = arrayfun(@ieee_to_binary, Head_Out , 'UniformOutput', false); 
    Final_res_bin = arrayfun(@ieee_to_binary, Final_res , 'UniformOutput', false); 
    
    
    
    % fileID_in_str = fopen('in_str.txt', 'w');
    % fileID_k_weight = fopen('k_weight.txt', 'w');
    % fileID_q_weight = fopen('q_weight.txt', 'w');
    % fileID_v_weight = fopen('v_weight.txt', 'w');
    % fileID_Final_res_bin = fopen('Final_res.txt', 'w');
    
    
    in_str_bin_transpose=in_str_bin';
    k_weight_bin_transpose=k_weight_bin';
    q_weight_bin_transpose=q_weight_bin';
    v_weight_bin_transpose=v_weight_bin';
    out_weight_bin_transpose=out_weight_bin';
    Final_res_bin_transpose=Final_res_bin';
    
    

    fprintf(fileID_in_str, '\n%d\n',pattern_idx);
    for i = 1:numel(in_str_bin_transpose)
        fprintf(fileID_in_str, '%s\n', char(in_str_bin_transpose{i})); % 轉換 cell to char
    end
    %fclose(fileID_in_str); % 關閉文件
    
    fprintf(fileID_k_weight, '\n%d\n',pattern_idx);
    for i = 1:numel(k_weight_bin_transpose)
        fprintf(fileID_k_weight, '%s\n', char(k_weight_bin_transpose{i})); % 轉換 cell to char 再寫入
    end
    %fclose(fileID_k_weight); % 關閉文件
    
    fprintf(fileID_q_weight, '\n%d\n',pattern_idx);
    for i = 1:numel(q_weight_bin_transpose)
        fprintf(fileID_q_weight, '%s\n', char(q_weight_bin_transpose{i})); % 轉換 cell to char 再寫入
    end
    %fclose(fileID_q_weight); % 關閉文件
    
    fprintf(fileID_v_weight, '\n%d\n',pattern_idx);
    for i = 1:numel(v_weight_bin_transpose)
        fprintf(fileID_v_weight, '%s\n', char(v_weight_bin_transpose{i})); % 轉換 cell to char 再寫入
    end
    %fclose(fileID_v_weight); % 關閉文件

    fprintf(fileID_out_weight, '\n%d\n',pattern_idx);
    for i = 1:numel(out_weight_bin_transpose)
        fprintf(fileID_out_weight, '%s\n', char(out_weight_bin_transpose{i})); % 轉換 cell to char 再寫入
    end
    
    fprintf(fileID_Final_res_bin, '\n%d\n',pattern_idx);
    for i = 1:numel(Final_res_bin_transpose)
        fprintf(fileID_Final_res_bin, '%s\n', char(Final_res_bin_transpose{i})); % 轉換 cell to char 再寫入
    end
    
end
fclose(fileID_in_str);
fclose(fileID_k_weight);
fclose(fileID_q_weight);
fclose(fileID_v_weight);
fclose(fileID_out_weight);
fclose(fileID_Final_res_bin);

disp('二進位數據已成功寫入 txt 檔案！');


