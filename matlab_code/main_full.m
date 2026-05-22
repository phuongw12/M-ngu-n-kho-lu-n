% Xóa workspace và command window
clear; clc; close;
warning('off', 'serialport:serialport:ReadWarning'); % Tắt cảnh báo Timeout rác

% ================= CẤU HÌNH =================
COM = 'COM5';
BAUD      = 115200;
mode      = 1;          % 1: Quét đơn

% --- ĐỊNH NGHĨA CÁC DẢI QUÉT TỪ THẤP TỚI CAO ---
% Dải 1: 1Hz - 10Hz       (clock_sel = 4, step = 1Hz)   % không dùng
% Dải 2: 10Hz - 100Hz     (clock_sel = 3, step = 10Hz)
% Dải 3: 100Hz - 1KHz     (clock_sel = 2, step = 100Hz)
% Dải 4: 1KHz - 10KHz     (clock_sel = 1, step = 1KHz)
% Dải 5: 10KHz - 100KHz   (clock_sel = 0, step = 10KHz)


clock_sels = [3, 2, 1, 0];
start_fs   = [10, 100, 1000, 10000];
stop_fs    = [100, 1000, 10000, 100000];
step_fs    = [0.1, 1, 10, 100];
% clock_sels = [ 1, 0];
% start_fs   = [  1000, 10000];
% stop_fs    = [  10000, 100000];
% step_fs    = [  10, 100];
Voltage_Range = 0;      % Mặc định
PGA_Gain = 0;           % 1: gain x1; 0: gain x5
MUX_Ctrl = 0;           % 0: Rcal 20k; 1: Rcal 200
AVDD = 2;               % 1: 5V; 2: 3.3V

calib = support.loadCalibration(PGA_Gain, MUX_Ctrl);

% ================= BƯỚC 1: KẾT NỐI VÀ PING =================
comm = STM32_protocol(COM, BAUD);
support.connected_ping(comm);

% ================= BƯỚC 2: KIỂM TRA TRẠNG THÁI =================
support.check_AD5933(comm);

% ================= BƯỚC 3: CẤU HÌNH VÀ QUÉT TOÀN BỘ =================
disp('3. Bắt đầu quá trình quét toàn dải (1Hz - 100KHz)...');

% Biến lưu trữ dữ liệu tổng hợp
all_freq_data = [];
all_real_data = [];
all_imag_data = [];

for idx = 1:length(clock_sels)
    % Lấy thông số cấu hình của dải hiện tại
    c_sel = clock_sels(idx);
    s_f   = start_fs(idx);
    sp_f  = stop_fs(idx);
    st_f  = step_fs(idx);
    vr    = Voltage_Range;
    pga_g = PGA_Gain;
    mux_ctrl = MUX_Ctrl;
    avdd = AVDD;
    fprintf('=================================================================\n');
    fprintf('Đang quét Dải %d: %d Hz -> %d Hz (clock_sel = %d, step = %d Hz)\nVoltage_Range = %d |PGA = %d |MUX_ctrl = %d\n', ...
             idx, s_f, sp_f, c_sel, st_f,vr,pga_g,mux_ctrl);
    
    % Gửi lệnh cấu hình Sweep cho dải hiện tại
    if ~comm.set_sweep_params(mode, c_sel, s_f, sp_f, st_f,vr,pga_g,mux_ctrl,avdd)
        fprintf(' -> [LỖI] Gửi lệnh cấu hình dải %d thất bại! Bỏ qua dải này.\n', idx);
        continue;
    end
    pause(0.5); % Chờ AD5933 đo điểm đầu tiên
    
    prev_msg_len = 0;
    state = [];
    
    while true
        % Yêu cầu 1 điểm dữ liệu
        [f, r, i] = comm.fetch_data_point();
        
        if isscalar(f) && isscalar(r) && isscalar(i)
            
            % Bỏ qua các gói padding rỗng
            if isequal(f, 0) && isequal(r, 0) && isequal(i, 0)
                continue;
            end
            
            f_val = double(f(1));
            
            % Tránh lưu trùng các điểm giao thoa (ví dụ điểm 10Hz ở cuối dải 1 và đầu dải 2)
            if isempty(all_freq_data) || f_val > all_freq_data(end)
                all_freq_data(end+1) = f_val; 
                all_real_data(end+1) = double(r(1));
                all_imag_data(end+1) = double(i(1));
            end
            
            % ---- In Thanh Tiến Độ (Đè Dòng) ----
            [prev_msg_len, state] = support.printProgress(prev_msg_len, f_val, s_f, sp_f, st_f, state);
            % ------------------------------------
            
            % Dừng nếu đạt tần số (Dung sai sai số float)
            if f_val >= (sp_f - st_f * 0.1)
                fprintf('\n-> Hoàn tất quét dải %d!\n', idx);
                break;
            end
            
        else
            % Nếu hàm trả về rỗng (tức là đã Timeout 1.0s) -> Hỏi STM32 xem còn quét không
            check_cfg = comm.get_config();
            
            if ~isempty(check_cfg) && check_cfg.mode == 0
                fprintf('\n-> Hoàn tất quét dải %d (STM32 đã tự động chuyển về Mode Stop)!\n', idx);
                break;
            end
        end
    end
end

% Đưa về Idle và Ngắt kết nối sau khi hoàn tất TẤT CẢ các dải
comm.disconnect();
disp('-> Hoàn tất toàn bộ chu trình. Đã ngắt kết nối thiết bị an toàn.');

% ================= BƯỚC 4: TÍNH TOÁN & XUẤT CSV =================
% Sử dụng dữ liệu tổng (all_freq_data, all_real_data, all_imag_data)
proc_data = support.applyCalibration(all_freq_data, all_real_data, all_imag_data, calib);
% Lọc số liệu đểu
support.saveSweepData(proc_data, PGA_Gain, MUX_Ctrl);
proc_data = support.removeOutliers(proc_data, 10);
% support.plotSweepData(proc_data);
support_plot.plotBodeSweepData2(proc_data,1,'a.pdf');
