%% purpose: generate dram.dat
%-----------------------------------------
% Rose:         12bit
% Lily:         12bit
% Date_Month:   8 bit

% Carnation:    12bit
% Baby Breath:  12bit
% Date_Day:     8 bit
% 
%-----------------------------------------
any_error = 0;

Rose = randi([0 4095], 1, 256);
Lily = randi([0 4095], 1, 256);
Carnation = randi([0 4095], 1, 256);
Baby_Breath = randi([0 4095], 1, 256);

Date_Month = randi([1 12], 1, 256);
Date_Day = zeros(1,256);
for i = 1:256
    if(Date_Month(i) == 2)
        Date_Day_tmp = randi([1 28]);
    elseif(sum(Date_Month(i) == [4 6 9 11]) == 1)
        Date_Day_tmp = randi([1 30]);
    else
        Date_Day_tmp = randi([1 31]);
    end
    Date_Day(i) = Date_Day_tmp;
end

if(sum(Date_Month == 0) > 0)
    disp("there are some problem in your code, for Date_Month");
    any_error = 1;
end

if(sum(Date_Day == 0) > 0)
    disp("there are some problem in your code, for Date_Day");
    any_error = 1;
end

for i = 1:256
    if(Date_Month(i) == 2 && Date_Day(i)>28)
        disp("there are some problem in your code, for Date_Day, Month 2");
        any_error = 1;
    elseif(sum(Date_Month(i) == [4 6 9 11]) == 1 && Date_Day(i)>30)
        disp("there are some problem in your code, for Date_Day, Month 4 6 9 11");
        any_error = 1;
    elseif(Date_Day(i)>31)
        disp("there are some problem in your code, for Date_Day, Month rest");
        any_error = 1;
    end
end
%% starting for writing dram.dat
starting_address = 65536;
current_address = starting_address;
current_data_1 = zeros(256, 1);
current_data_1_1 = zeros(256, 1);
current_data_1_2 = zeros(256, 1);
current_data_1_3 = zeros(256, 1);
current_data_1_4 = zeros(256, 1);
current_data_2 = zeros(256, 1);
current_data_2_1 = zeros(256, 1);
current_data_2_2 = zeros(256, 1);
current_data_2_3 = zeros(256, 1);
current_data_2_4 = zeros(256, 1);
% file I/O
fileID = fopen('dram.dat','w');
for i = 1:256
    % writing first 4 Byte
    fprintf(fileID, '@');
    fprintf(fileID, [dec2hex(current_address) '\n']);
    current_address = current_address + 4;
    current_data_1(i) = bitshift(Carnation(i),20) + bitshift(Baby_Breath(i),8) + Date_Day(i);
    current_data_1_1(i) = mod(current_data_1(i), 256); 
    current_data_1_2(i) = mod((current_data_1(i)-current_data_1_1(i))/256, 256); 
    current_data_1_3(i) = mod((current_data_1(i)-current_data_1_2(i)*256-current_data_1_1(i))/256/256, 256); 
    current_data_1_4(i) = mod((current_data_1(i)-current_data_1_3(i)*256*256 -current_data_1_2(i)*256-current_data_1_1(i))/256/256/256, 256);
    fprintf(fileID, [dec2hex(current_data_1_1(i), 2) ' ']);
    fprintf(fileID, [dec2hex(current_data_1_2(i), 2) ' ']);
    fprintf(fileID, [dec2hex(current_data_1_3(i), 2) ' ']);
    fprintf(fileID, [dec2hex(current_data_1_4(i), 2) '\n']);
    % writing second 4 Byte
    fprintf(fileID, '@');
    fprintf(fileID, [dec2hex(current_address) '\n']);
    current_address = current_address + 4;
    current_data_2(i) = bitshift(Rose(i),20) + bitshift(Lily(i),8) + Date_Month(i);
    current_data_2_1(i) = mod(current_data_2(i), 256); 
    current_data_2_2(i) = mod((current_data_2(i)-current_data_2_1(i))/256, 256); 
    current_data_2_3(i) = mod((current_data_2(i)-current_data_2_2(i)*256-current_data_2_1(i))/256/256, 256); 
    current_data_2_4(i) = mod((current_data_2(i)-current_data_2_3(i)*256*256 -current_data_2_2(i)*256-current_data_2_1(i))/256/256/256, 256);
    fprintf(fileID, [dec2hex(current_data_2_1(i), 2) ' ']);
    fprintf(fileID, [dec2hex(current_data_2_2(i), 2) ' ']);
    fprintf(fileID, [dec2hex(current_data_2_3(i), 2) ' ']);
    fprintf(fileID, [dec2hex(current_data_2_4(i), 2) '\n']);
end
current_1 = [current_data_1 current_data_1_1 current_data_1_2 current_data_1_3 current_data_1_4];
if(sum(current_data_1 ~= bitshift(current_data_1_4, 24)+bitshift(current_data_1_3, 16)+bitshift(current_data_1_2, 8)+current_data_1_1)>0)
    disp("current_data_1 are wrong");
    any_error = 1;
else
    disp("current_data_1 are correct")
end
if(sum(current_data_2 ~= bitshift(current_data_2_4, 24)+bitshift(current_data_2_3, 16)+bitshift(current_data_2_2, 8)+current_data_2_1)>0)
    disp("current_data_2 are wrong");
    any_error = 1;
else
    disp("current_data_2 are correct")
end

fclose(fileID);

if(any_error  == 0)
    disp("sucess for generating dram.dat");
else
    disp("something wrong for generating dram.dat");
end

