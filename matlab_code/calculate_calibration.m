clc;clear; close all;

filename = 'calib\Minh_duc_mach_PGAx5_Rcal20k_Rtest_100k.csv';
Rtest = 100000;

% Đọc dữ liệu từ file (chỉ định vùng từ ô A2 đến hết cột C)
% A2: Bắt đầu từ Cột 1 (A), Dòng 2 (Bỏ dòng 1)
% C: Kéo dài đến hết Cột 3 (C)
data = readmatrix(filename, 'Range', 'A:D');
data(1, :) = [];

% Gán tên từng cột theo đúng dữ liệu của bạn để tính toán
Freq        =  data(:, 1); % Cột 1: Tần số
Real        =  data(:, 2); % Cột 2: Raw Real
Imag        =  data(:, 3); % Cột 3: Raw Imag

% lọc khoản ổn
idx = find(Freq  >= 10 & Freq <= 100000);
% Trích xuất dữ liệu của khoảng đó
Freq_filtered = Freq(idx);
Real_filtered = Real(idx);
Imag_filtered = Imag(idx);

%tính pha
Phase = atan2(Imag_filtered,Real_filtered)*180/pi();
%ính gain
gain_array = 1 ./ (Rtest * (sqrt(Real_filtered.^2 + Imag_filtered.^2)));

bang_du_lieu = table(Freq_filtered, Real_filtered, Imag_filtered, Phase, gain_array);

% (Tùy chọn) Nếu bạn muốn đổi tên tiêu đề cột cho đẹp hơn trong Excel:
bang_du_lieu.Properties.VariableNames = {'F(Hz)', 'REAL', 'IMAG', 'Phase', 'Gain'};

% 3. Ghi bảng này ra file Excel mới
ten_file_xuat ='calib\Calib_Minh_duc_mach_PGAx5_Rcal20k_Rtest_100k.csv';
writetable(bang_du_lieu, ten_file_xuat);

disp('Đã xuất file Excel thành công!');