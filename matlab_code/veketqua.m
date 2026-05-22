% % % ========== lọc dữ liệu

clear;clc;close all;
proc_data = support_plot.load_CSV('data\save\SweepData_PGAx1_Rcal20k_47nFss20k_nt_25k.csv');
support_plot.plotBodeSweepData2(proc_data,0,'raw.pdf');
support_plot.plotBodeSweepData2(proc_data,1,'calib.pdf');
proc_data = support.removeOutliers(proc_data, 10);
support_plot.plotBodeSweepData2(proc_data,1,'calib_filed.pdf');


%%%%% ========== SweepData_PGAx1_Rcal20k_47nFss20k_nt_25k.csv

clear;clc;close all;
proc_data = support_plot.load_CSV('data\test_Rcal_200_test340.csv');
proc_data = support.removeOutliers(proc_data, 10);
support_plot.compareTheoreticalComplexZ(proc_data, 340,'R_340_so_sanh.pdf');

%%%%% ========== SweepData_PGAx1_Rcal20k_47nFss20k_nt_25k.csv

clear;clc;close all;
proc_data = support_plot.load_CSV('data\save\SweepData_PGAx1_Rcal20k_47nFss20k_nt_25k.csv');
proc_data = support.removeOutliers(proc_data, 10);
R1  = 20e3;      % 20 kOhm
R16 = 25e3;      % 25 kOhm
C6  = 47e-9;     % 47 nF
freqs = proc_data.freq;
w = 2*pi*freqs;
Zc = 1 ./ (1j*w*C6);
Z_parallel = (R1 .* Zc) ./ (R1 + Zc);
Z_theo_complex = R16 + Z_parallel;
support_plot.compareTheoreticalComplexZ(proc_data, Z_theo_complex,'so sánh 47nFss20k_nt_25k.pdf');


%%%%% ========== SweepData_PGAx1_Rcal20k_10nF.csv

clear;clc;close all;
proc_data = support_plot.load_CSV('data\save\SweepData_PGAx1_Rcal20k_10nF.csv');
proc_data = support.removeOutliers(proc_data, 10);
C6  = 10e-9;     % 47 nF
freqs = proc_data.freq;
w = 2*pi*freqs;
Zc = 1 ./ (1j*w*C6);
support_plot.compareTheoreticalComplexZ(proc_data, Zc,'so sánh 10nF.pdf');


%%%%% ========== SweepData_PGAx5_Rcal20k_10nF_nt_60k.csv
clear;clc;close all;
proc_data = support_plot.load_CSV('data\save\SweepData_PGAx5_Rcal20k_10nF_nt_60k.csv');
proc_data = support.removeOutliers(proc_data, 10);
% proc_data = support_plot.filterByFrequency(proc_data,100,100000);
R = 60e3;
C6  = 10e-9;     % 47 nF
freqs = proc_data.freq;
w = 2*pi*freqs;
Zc = 1 ./ (1j*w*C6);
Z_theo_complex = R + Zc;
support_plot.compareTheoreticalComplexZ(proc_data, Z_theo_complex,'so sánh 10nF nối tiếp 60K.pdf');


%%%%% ========== SweepData_PGAx5_Rcal20k_10nF_nt_50k.csv
clear;clc;close all;
proc_data = support_plot.load_CSV('data\save\SweepData_PGAx5_Rcal20k_10nF_nt_50k.csv');
proc_data = support.removeOutliers(proc_data, 10);
proc_data = support_plot.filterByFrequency(proc_data,100,100000);
R = 50e3;
C6  = 10e-9;     % 47 nF
freqs = proc_data.freq;
w = 2*pi*freqs;
Zc = 1 ./ (1j*w*C6);
Z_theo_complex = R + Zc;
support_plot.compareTheoreticalComplexZ(proc_data, Z_theo_complex,'so sánh 10nF nối tiếp 50K.pdf');

%%%%% ========== SweepData_PGAx1_Rcal20k_10nF_nt_20k.csv
clear;clc;close all;
proc_data = support_plot.load_CSV('data\save\SweepData_PGAx1_Rcal20k_10nF_nt_20k.csv');
proc_data = support.removeOutliers(proc_data, 10);
proc_data = support_plot.filterByFrequency(proc_data,100,100000);
R = 20e3;
C6  = 10e-9;     % 47 nF
freqs = proc_data.freq;
w = 2*pi*freqs;
Zc = 1 ./ (1j*w*C6);
Z_theo_complex = R + Zc;
support_plot.compareTheoreticalComplexZ(proc_data, Z_theo_complex,'so sánh 10nF nối tiếp 20K.pdf');

% % % SweepData_PGAx1_Rcal20k_47nF_nt_47nFss20k_nt_25k
clear; clc; close all;
proc_data = support_plot.load_CSV('data\save\SweepData_PGAx1_Rcal20k_47nF_nt_47nFss20k_nt_25k.csv');
proc_data = support.removeOutliers(proc_data, 10);
R18 = 25e3;       % Điện trở nối tiếp: 1 kOhm
R20 = 20e3;      % Điện trở song song: 10 kOhm
C24 = 47e-9;     % Tụ điện song song: 10 nF
freqs = proc_data.freq;
w = 2 * pi * freqs;
Z_parallel = 1 ./ (1/R20 + 1j * w * C24); % Tính cụm song song (R20 // C24)
Zc = 1 ./ (1j*w*C24);
Z_theo_complex = R18 + Z_parallel + Zc;        % Cộng nối tiếp với R18
support_plot.compareTheoreticalComplexZ(proc_data, Z_theo_complex, '47nF_nt_47nFss20k_nt25k.pdf');