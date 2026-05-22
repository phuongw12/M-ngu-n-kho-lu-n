classdef support
    methods (Static)

        % ================= BƯỚC 1: KẾT NỐI VÀ PING =================
        function connected_ping(comm)
            disp('1. Đang kết nối tới STM32...');
            if ~comm.isConnected
                disp(' -> Kết thúc chương trình do không mở được cổng COM.');
                return;
            end
            if comm.ping()
                disp(' -> PING thành công! Mạch STM32 đã phản hồi.');
            else
                disp(' -> [CẢNH BÁO] Không nhận được phản hồi PING từ STM32.');
            end
        end
        
        % ================= BƯỚC 2: KIỂM TRA TRẠNG THÁI =================
        function check_AD5933(comm)
            disp('2. Lấy cấu hình và kiểm tra AD5933...');
            cfg = comm.get_config();
            
            if ~isempty(cfg)
                if cfg.i2c == 0
                    disp(' -> [OK] Trạng thái I2C ổn định. AD5933 đang hoạt động.');
                else
                    fprintf(' -> [LỖI] STM32 báo lỗi giao tiếp I2C với AD5933 (Mã: %d).\n', cfg.i2c);
                    disp('    Vui lòng kiểm tra dây điện!');
                    comm.disconnect();
                    return;
                end
                
                fprintf(' -> Thanh ghi Ctrl (0x80, 0x81): 0x%02X, 0x%02X\n', cfg.regs(1), cfg.regs(2));
                fprintf(' -> Thanh ghi Status (0x8F): 0x%02X\n', cfg.status);
            else
                disp(' -> [LỖI] Không lấy được cấu hình từ STM32.');
                comm.disconnect();
                return;
            end
            disp('--------------------------------------------------');
        end

        % ================= THANH TIẾN ĐỘ 2 DÒNG =================
        function [prev_msg_len, state] = printProgress(prev_msg_len, f_val, start_f, stop_f, step_f, state)
            % ===== INIT STATE =====
            if isempty(state)
                state.t_start = tic;
                state.pts_received = 0;
                state.bytes_per_point = 13; % 1 byte header (0x13) + 12 byte payload
            end
            
            % Tăng số điểm đã nhận lên 1
            state.pts_received = state.pts_received + 1;

            % Xóa nội dung dòng cũ bằng ký tự backspace
            if prev_msg_len > 0
                fprintf(repmat('\b', 1, prev_msg_len));
            end
            % ===== TÍNH % VÀ BYTES =====
            percent = (f_val - start_f) / (stop_f - start_f) * 100;
            percent = max(0, min(100, percent));
            received_bytes = state.pts_received * state.bytes_per_point;
            % Ước tính tổng byte dựa trên step_f
            total_points = round((stop_f - start_f) / step_f) + 1;
            total_bytes = total_points * state.bytes_per_point;
            % ===== TÍNH THỜI GIAN & TỐC ĐỘ (BYTES/S) =====
            t_elapsed = toc(state.t_start);
            if t_elapsed > 0
                speed_bps = received_bytes / t_elapsed; 
            else
                speed_bps = 0;
            end
            if speed_bps > 0
                eta = max(0, (total_bytes - received_bytes) / speed_bps);
            else
                eta = inf;
            end
            eta_str = support.formatTime(eta);
            elapsed_str = support.formatTime(t_elapsed);
            % ===== BAR =====
            bar_len = 25;
            filled_len = round((percent / 100) * bar_len);
            bar_str = [repmat('=', 1, filled_len), repmat(' ', 1, bar_len - filled_len)];
            % ===== FORMATTING VÀ IN RA 2 DÒNG =====
            line1 = sprintf('Tiến độ: [%s] %5.2f%% | %8.1f Hz | %s / %s', ...
                            bar_str, percent, f_val, ...
                            support.formatBytes(received_bytes), ...
                            support.formatBytes(total_bytes));
                            
            line2 = sprintf('Speed: %8s/s | ETA: %s | T: %s', ...
                            support.formatBytes(speed_bps), eta_str, elapsed_str);
                            
            msg = sprintf('%s\n%s', line1, line2);
            fprintf('%s', msg);
            
            % Lưu lại độ dài để xóa cho vòng lặp kế tiếp
            prev_msg_len = length(msg);
        end

        % ================= CÁC HÀM TIỆN ÍCH =================
        function str = formatBytes(bytes)
            if bytes < 1024
                str = sprintf('%.0f B', bytes);
            elseif bytes < 1024^2
                str = sprintf('%.2f KB', bytes / 1024);
            else
                str = sprintf('%.2f MB', bytes / 1024^2);
            end
        end

        function str = formatTime(t)
            if isinf(t) || isnan(t)
                str = '--:--:--';
                return;
            end
            h = floor(t / 3600);
            m = floor(mod(t, 3600) / 60);
            s = floor(mod(t, 60));
            str = sprintf('%02d:%02d:%02d', h, m, s);
        end
        
        % ================= hàm nạp dữ liệu hiệu chuẩn =================
        function calib_data = loadCalibration(PGA_Gain, MUX_Ctrl)
            % Voltage_Range = 0;      % Mặc định
            % PGA_Gain = 1;             % 1: gain x1; 0: gain x5
            % MUX_Ctrl = 0;             % 0: Rcal 20k; 1: Rcal 200
            if PGA_Gain == 1            % 1: gain x1
                if MUX_Ctrl == 0        % 0: Rcal 20k
                    filepath = 'calib/Calib_Minh_duc_mach_PGAx1_Rcal20k_Rtest_36k.csv';
                elseif MUX_Ctrl == 1    % 0: Rcal 200
                    filepath = 'calib/Calib_Full_PGAx1_Rcal200_Rtest_1,5k.csv';
                end
            elseif PGA_Gain == 0        % 0: gain x5
                if MUX_Ctrl == 0        % 0: Rcal 20k
                    filepath = 'calib/Calib_Minh_duc_mach_PGAx5_Rcal20k_Rtest_100k.csv';
                elseif MUX_Ctrl == 1    % 0: Rcal 200
                    filepath = 'calib/Calib_Full_PGAx5_Rcal200_Rtest_5k.csv';
                end
            end


            calib_data = [];
            if ~exist(filepath, 'file')
                disp(['[CẢNH BÁO] Không tìm thấy file hiệu chuẩn: ', filepath]);
                return;
            end
            
            try
                opts = detectImportOptions(filepath);
                opts.VariableNamingRule = 'preserve'; 
                T = readtable(filepath, opts);
                vars = T.Properties.VariableNames;
                
                idx_f = find(contains(lower(vars), 'freq') | contains(lower(vars), 'hz') | strcmpi(vars, 'f'), 1);
                idx_p = find(contains(lower(vars), 'phase'), 1);
                idx_g = find(contains(lower(vars), 'gain'), 1);
                
                if isempty(idx_f) || isempty(idx_p) || isempty(idx_g)
                    disp('[LỖI] File CSV thiếu các cột Freq(Hz), Phase, hoặc Gain!');
                    return;
                end
                
                calib_data.freqs = T.(vars{idx_f});
                calib_data.phases = T.(vars{idx_p});
                calib_data.gains = T.(vars{idx_g});
                disp(['=> [OK] Đã nạp dữ liệu hiệu chuẩn từ: ', filepath]);
            catch e
                disp(['[LỖI] Quá trình nạp file hiệu chuẩn thất bại: ', e.message]);
            end
        end

        % ================= HÀM TÍNH TOÁN HIỆU CHUẨN =================
        function proc = applyCalibration(freq_data, real_data, imag_data, calib_data)
            % Hàm này trả về một struct chứa toàn bộ dữ liệu thô và đã hiệu chuẩn
            proc = struct();
            if isempty(freq_data)
                return;
            end
            
            % Đảm bảo định dạng cột
            proc.freq = freq_data';
            proc.real_raw = real_data';
            proc.imag_raw = imag_data';
            
            % 1. Tính toán giá trị thô (Raw)
            mag = sqrt(proc.real_raw.^2 + proc.imag_raw.^2);
            proc.z_raw_mag = zeros(size(mag));
            valid_idx = mag > 0;
            proc.z_raw_mag(valid_idx) = 1.0 ./ mag(valid_idx);
            
            proc.raw_phase = atan2(proc.imag_raw, proc.real_raw) .* (180.0 / pi);
            proc.raw_real_z = proc.z_raw_mag .* cosd(proc.raw_phase);
            proc.raw_imag_z = proc.z_raw_mag .* sind(proc.raw_phase);
            
            % 2. Tính toán áp dụng hiệu chuẩn
            proc.is_calibrated = ~isempty(calib_data);
            if proc.is_calibrated
                % Loại bỏ các điểm trùng lặp trong file calib để hàm nội suy (interp1) không lỗi
                [u_freqs, u_idx] = unique(calib_data.freqs);
                u_gains = calib_data.gains(u_idx);
                u_phases = calib_data.phases(u_idx);
                
                % Nội suy Gain và Phase theo tần số thực tế
                cal_gain = interp1(u_freqs, u_gains, proc.freq, 'linear', 'extrap');
                cal_phase_offset = interp1(u_freqs, u_phases, proc.freq, 'linear', 'extrap');
                
                % Tính Trở kháng Z đã hiệu chuẩn
                proc.z_cal_mag = zeros(size(mag));
                proc.z_cal_mag(valid_idx) = 1.0 ./ (cal_gain(valid_idx) .* mag(valid_idx));
                
                % Tính Góc pha đã hiệu chuẩn (Chuẩn hóa [-180, 180])
                corr_phase = proc.raw_phase - cal_phase_offset;
                proc.corr_phase = mod(corr_phase + 180, 360) - 180;
                
                % Tính Thành phần Thực/Ảo hiệu chuẩn
                proc.corr_real_z = proc.z_cal_mag .* cosd(proc.corr_phase);
                proc.corr_imag_z = proc.z_cal_mag .* sind(proc.corr_phase);
            else
                % Nếu không có dữ liệu calib, trả về mảng NaN hoặc 0 để đồng nhất cấu trúc
                proc.z_cal_mag = NaN(size(proc.freq));
                proc.corr_phase = NaN(size(proc.freq));
                proc.corr_real_z = NaN(size(proc.freq));
                proc.corr_imag_z = NaN(size(proc.freq));
            end
        end

        % ================= LỌC NHIỄU TRỰC TIẾP TRÊN PROC_DATA =================
        function proc = removeOutliers(proc, window_size)
            % Mặc định cửa sổ lọc là 10 điểm nếu không truyền tham số
            if nargin < 2
                window_size = 10; 
            end
            
            try
                % Lưu lại mảng cũ để đối chiếu đếm số điểm bị nhiễu
                old_real = proc.corr_real_z;
                old_imag = proc.corr_imag_z;

                % 1. Lọc trên các thành phần Thực và Ảo đã hiệu chuẩn
                proc.corr_real_z = filloutliers(proc.corr_real_z, 'linear', 'movmedian', window_size);
                proc.corr_imag_z = filloutliers(proc.corr_imag_z, 'linear', 'movmedian', window_size);
                
                % Lọc thêm trên Raw DFT để đồng bộ nếu bạn lưu ra file CSV
                if isfield(proc, 'raw_real_dft')
                    proc.raw_real_dft = filloutliers(proc.raw_real_dft, 'linear', 'movmedian', window_size);
                    proc.raw_imag_dft = filloutliers(proc.raw_imag_dft, 'linear', 'movmedian', window_size);
                end

                % 2. Tính toán lại Trở kháng |Z| (Magnitude) từ dữ liệu đã làm sạch
                % Dùng isfield để tương thích với các tên biến khác nhau bạn có thể đặt
                if isfield(proc, 'z_cal_mag')
                    proc.z_cal_mag = sqrt(proc.corr_real_z.^2 + proc.corr_imag_z.^2);
                end
                if isfield(proc, 'z_cal_ohm')
                    proc.z_cal_ohm = sqrt(proc.corr_real_z.^2 + proc.corr_imag_z.^2);
                end
                
                % 3. Tính toán lại Góc pha (Phase) = atan2(X, R)
                if isfield(proc, 'corr_phase')
                    proc.corr_phase = atan2d(proc.corr_imag_z, proc.corr_real_z);
                elseif isfield(proc, 'corr_phase_deg')
                    proc.corr_phase_deg = atan2d(proc.corr_imag_z, proc.corr_real_z);
                end

                % In kết quả ra màn hình Console
                num_outliers = sum((proc.corr_real_z ~= old_real) | (proc.corr_imag_z ~= old_imag));
                if num_outliers > 0
                    fprintf('=> [BỘ LỌC] Đã phát hiện và gọt mịn %d điểm dị thường trên proc_data! \n', num_outliers);
                end
                
            catch
                % Phương án dự phòng cho MATLAB phiên bản cũ (không có filloutliers)
                proc.corr_real_z = medfilt1(proc.corr_real_z, window_size);
                proc.corr_imag_z = medfilt1(proc.corr_imag_z, window_size);
                
                if isfield(proc, 'z_cal_mag')
                    proc.z_cal_mag = sqrt(proc.corr_real_z.^2 + proc.corr_imag_z.^2);
                end
                if isfield(proc, 'corr_phase')
                    proc.corr_phase = atan2d(proc.corr_imag_z, proc.corr_real_z);
                end
                disp('=> [BỘ LỌC] Đã áp dụng bộ lọc medfilt1 (phiên bản MATLAB cũ).');
            end
        end

        % Xử lý + lưu CSV
        function saveSweepData(proc, pga_gain, MUX_Ctrl)
            if ~isfield(proc, 'freq') || isempty(proc.freq)
                disp('=> Không có dữ liệu nào được thu thập.');
                return;
            end
            
            disp(' '); 
            disp('5. Đang lưu file CSV...');
            
            if proc.is_calibrated
                T = table(proc.freq, proc.real_raw, proc.imag_raw, proc.z_raw_mag, proc.raw_phase, proc.corr_phase, ...
                          proc.raw_real_z, proc.raw_imag_z, proc.z_cal_mag, proc.corr_real_z, proc.corr_imag_z, ...
                    'VariableNames', {'Freq_Hz', 'Raw_Real_DFT', 'Raw_Imag_DFT', ...
                                      'Z_Uncal_Ohm', 'Raw_Phase_deg', 'Corr_Phase_deg', ...
                                      'Raw_Real_Z', 'Raw_Imag_Z', 'Z_Cal_Ohm', 'Corr_Real_Z', 'Corr_Imag_Z'});
            else
                T = table(proc.freq, proc.real_raw, proc.imag_raw, proc.z_raw_mag, proc.raw_phase, proc.raw_real_z, proc.raw_imag_z, ...
                    'VariableNames', {'Freq_Hz', 'Raw_Real_DFT', 'Raw_Imag_DFT', ...
                                      'Magnitude_Z_Uncal', 'Raw_Phase_deg', 'Raw_Real_Z', 'Raw_Imag_Z'});
            end
            
            % Tạo thư mục data nếu chưa có
            folder = 'data';
            if ~exist(folder, 'dir')
                mkdir(folder);
            end
            
            time_str = datestr(now, 'yyyymmdd_HHMMSS');
            
            % ===== NẾU CÓ TRUYỀN THÊM THAM SỐ =====
            if nargin > 1
                % Xử lý chuỗi PGA Gain
                if isnumeric(pga_gain)
                    if pga_gain == 1, str_pga = 'PGAx1'; else, str_pga = 'PGAx5'; end
                else
                    str_pga = ['PGA' char(string(pga_gain))];
                end
                
                % Xử lý chuỗi Rcal
                 if MUX_Ctrl == 1
                     str_rcal = 'Rcal2k'; 
                 else
                     str_rcal = 'Rcal20k'; 
                 end
                
                
                % Tên file ví dụ: SweepData_PGAx1_Rcal20k_10-100000Hz_step1000_20260508_095000.csv
                filename = sprintf('SweepData_%s_%s_%s.csv', ...
                                    str_pga, str_rcal, time_str);
            else
                % Dự phòng nếu gọi hàm theo kiểu cũ
                filename = sprintf('SweepData_%s.csv', time_str);
            end
            
            fullpath = fullfile(folder, filename);
            writetable(T, fullpath);
            
            disp(['=> [THÀNH CÔNG] Dữ liệu đã được lưu vào: ', fullpath]);
        end
        
    end
end