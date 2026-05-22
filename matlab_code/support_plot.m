classdef support_plot
    methods (Static)

        % ================= HÀM VẼ ĐỒ THỊ =================
        function plotSweepData(proc)
            if ~isfield(proc, 'freq') || isempty(proc.freq)
                disp('=> Không có dữ liệu để vẽ đồ thị.');
                return;
            end
            
            disp('6. Đang hiển thị đồ thị...');
            
            % Tạo cửa sổ Figure mới
            f = figure('Name', 'AD5933 Sweep Results', 'NumberTitle', 'off', 'Color', 'w');
            f.Position = [100, 100, 1000, 600]; % [x, y, width, height]
            
            % ---------------------------------------------------------
            % ĐỒ THỊ 1: TRỞ KHÁNG (IMPEDANCE)
            % ---------------------------------------------------------
            subplot(2, 1, 1);
            hold on; box on; grid on;
            
            % Vẽ dữ liệu thô (Raw)
            plot(proc.freq, proc.z_raw_mag, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Uncalibrated |Z|');
            
            % Vẽ dữ liệu hiệu chuẩn (Calibrated) nếu có
            if proc.is_calibrated
                plot(proc.freq, proc.z_cal_mag, 'b-', 'LineWidth', 2, 'DisplayName', 'Calibrated |Z|');
            end
            
            xlabel('Frequency (Hz)', 'FontWeight', 'bold');
            ylabel('Impedance (\Omega)', 'FontWeight', 'bold');
            title('Impedance vs Frequency', 'FontSize', 12);
            legend('Location', 'best');
            
            % Tự động scale trục Y cho phù hợp, tránh các điểm dị thường
            if proc.is_calibrated
                ylim([min(proc.z_cal_mag)*0.8, max(proc.z_cal_mag)*1.2]);
            end
            hold off;
            
            % ---------------------------------------------------------
            % ĐỒ THỊ 2: GÓC PHA (PHASE)
            % ---------------------------------------------------------
            subplot(2, 1, 2);
            hold on; box on; grid on;
            
            % Vẽ pha thô (Raw Phase)
            plot(proc.freq, proc.raw_phase, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Raw Phase');
            
            % Vẽ pha đã hiệu chuẩn (Calibrated Phase) nếu có
            if proc.is_calibrated
                plot(proc.freq, proc.corr_phase, 'b-', 'LineWidth', 2, 'DisplayName', 'Calibrated Phase');
            end
            
            xlabel('Frequency (Hz)', 'FontWeight', 'bold');
            ylabel('Phase (Degrees)', 'FontWeight', 'bold');
            title('Phase vs Frequency', 'FontSize', 12);
            legend('Location', 'best');
            ylim([-180 180]); % Cố định trục Y của góc pha từ -180 đến 180 độ
            hold off;
        end
        
         % ================= HÀM VẼ ĐỒ THỊ X-logarit =================
         %calib != 1 thì hiển thị raw
         function plotBodeSweepData(proc, calib)
            if ~isfield(proc, 'freq') || isempty(proc.freq)
                disp('=> Không có dữ liệu để vẽ đồ thị.');
                return;
            end
            disp('6. Đang hiển thị đồ thị Bode (Trục X Logarit)...');
            % Tạo cửa sổ Figure mới
            f_fig = figure('Name', 'AD5933 Bode Plot', 'NumberTitle', 'off', 'Color', 'w');
            f_fig.Position = [150, 150, 900, 550];
            
            % Chọn dữ liệu để vẽ (Ưu tiên dữ liệu đã hiệu chuẩn)
            freqs = proc.freq;
            if proc.is_calibrated && calib == 1
                mag_data = proc.z_cal_mag;
                phase_data = proc.corr_phase;
                line_name = 'Đã áp dụng hiệu chuẩn';
                color_mag = 'b';  % Xanh blue cho magnitude đã hiệu chuẩn
            else
                mag_data = proc.z_raw_mag;
                phase_data = proc.raw_phase;
                line_name = 'Dữ liệu thô';
                color_mag = 'r';  % Đỏ cho magnitude chưa hiệu chuẩn
            end
            
            % ==================== TRỤC TRÁI (Trở kháng - Thang Log) ====================
            yyaxis left;
            loglog(freqs, mag_data, '-', 'Color', color_mag, 'LineWidth', 2, 'DisplayName', ['|Z| ' line_name ]);
            ax = gca; 
            ax.YAxis(1).Color = 'k'; % Ép màu trục Y về đen
            ylabel('Impedance (\Omega)', 'FontWeight', 'bold');
            
            % Chỉnh giới hạn trục Y trái có khoảng đệm
            min_mag = min(mag_data);
            max_mag = max(mag_data);
            if min_mag > 0 && max_mag > min_mag
                ylim([min_mag * 0.5, max_mag * 2]);
            end
            
            % ==================== TRỤC PHẢI (Góc pha - Thang Tuyến tính) ====================
            yyaxis right;
            semilogx(freqs, phase_data, 'k--', 'LineWidth', 1.5, 'DisplayName', ['Phase ' line_name ]);
            ax.YAxis(2).Color = 'k'; % Ép màu trục Y về đen
            ylabel('Phase (Degrees)', 'FontWeight', 'bold');
            ylim([-180 180]);
            yticks([-180 -90 0 90 180]);
            
            % ==================== CẤU HÌNH TRỤC X (Logarit) ====================
            xlabel('Frequency (Hz)', 'FontWeight', 'bold');
            set(gca, 'XScale', 'log');
            
            % Tự động tạo ticks cho đẹp (1, 10, 100, 1K, 10K, 100K...)
            xlim([min(freqs) max(freqs)]);
            
            % ==================== LƯỚI & HIỂN THỊ ====================
            grid on;
            grid minor;
            box on;
            title('Bode Plot: Impedance and Phase vs Frequency', 'FontSize', 12, 'FontWeight', 'bold');
            
            % Thêm chú thích
            legend('Location', 'best');
            
            % ==================== XUẤT FILE CHO LATEX ====================
            % 1. Đồng bộ font chữ sang Times New Roman để tránh lỗi font khi ép file PDF
            ax.FontName = 'Times New Roman';
            
            % 2. Đặt tên file xuất ra tự động theo loại dữ liệu
            if proc.is_calibrated && calib == 1
                export_filename = 'Bode_Plot_Calibrated.pdf';
            else
                export_filename = 'Bode_Plot_Uncalibrated.pdf';
            end
            
            % 3. Xuất file bằng exportgraphics 
            % (dùng ax để tự động cắt gọn lề dư, ContentType là vector để PDF được sắc nét nhất)
            try
                exportgraphics(ax, export_filename, 'ContentType', 'vector', 'BackgroundColor', 'none');
                fprintf('=> Đã xuất đồ thị Vector ra file: %s\ \n', export_filename);
            catch
                disp('=> [CẢNH BÁO] Không thể xuất file PDF (Có thể do bản MATLAB cũ không hỗ trợ exportgraphics).');
            end
        end
           
        % ================= HÀM VẼ ĐỒ THỊ REAL, IMAG VÀ |Z| =================
        function plotCalibratedComplexZ(proc)
            if ~isfield(proc, 'freq') || isempty(proc.freq)
                disp('=> Không có dữ liệu để vẽ đồ thị.');
                return;
            end
            
            % Kiểm tra xem dữ liệu đã được hiệu chuẩn chưa
            if ~isfield(proc, 'is_calibrated') || ~proc.is_calibrated
                disp('=> [CẢNH BÁO] Không có dữ liệu hiệu chuẩn. Hàm này chỉ vẽ dữ liệu đã Calib.');
                return;
            end
            
            disp('6. Đang hiển thị đồ thị Real, Imaginary và |Z| (Đã hiệu chuẩn)...');
            
            % Tạo cửa sổ Figure mới
            f_fig = figure('Name', 'Calibrated Complex Impedance', 'NumberTitle', 'off', 'Color', 'w');
            f_fig.Position = [200, 200, 900, 550];
            
            freqs = proc.freq;
            mag_data = proc.z_cal_mag;     % |Z|
            real_data = proc.corr_real_z;  % Phần thực
            imag_data = proc.corr_imag_z;  % Phần ảo
            
            % ==================== VẼ CÁC ĐƯỜNG ĐỒ THỊ ====================
            % Dùng semilogx (X logarit, Y tuyến tính) để hiển thị được giá trị âm của phần ảo
            hold on;
            semilogx(freqs, mag_data, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Magnitude |Z|');
            semilogx(freqs, real_data, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Real(Z) - Resistance');
            semilogx(freqs, imag_data, 'g-.', 'LineWidth', 1.5, 'DisplayName', 'Imag(Z) - Reactance');
            hold off;
            
            % ==================== CẤU HÌNH TRỤC X & Y ====================
            xlabel('Frequency (Hz)', 'FontWeight', 'bold');
            ylabel('Impedance (\Omega)', 'FontWeight', 'bold');
            set(gca, 'XScale', 'log'); % Ép trục X thành thang logarit
            
            % Tự động giới hạn trục X cho khít dữ liệu
            xlim([min(freqs) max(freqs)]);
            
            % ==================== LƯỚI & HIỂN THỊ ====================
            grid on;
            grid minor;
            box on;
            title('Calibrated Impedance Components: |Z|, Real, and Imaginary', 'FontSize', 12, 'FontWeight', 'bold');
            
            % Thêm chú thích
            legend('Location', 'best');
        end
        
        
        % ================= NẠP LẠI DỮ LIỆU TỪ FILE CSV ĐÃ LƯU =================
        % VD: support.load_and_plot_CSV('data\SweepData_20260503_212359.csv', 2);
        function proc = load_CSV(filepath)
            proc = struct();
            if nargin < 1 || isempty(filepath)
                [file, path] = uigetfile('*.csv', 'Chọn file dữ liệu quét (Ví dụ: SweepData_...)', 'data/');
                if isequal(file, 0)
                    disp('Đã hủy chọn file.');
                    return;
                end
                filepath = fullfile(path, file);
            end
            
            if ~exist(filepath, 'file')
                disp(['[LỖI] Không tìm thấy file: ', filepath]);
                return;
            end
            
            disp(['=> Đang nạp dữ liệu từ: ', filepath]);
            
            try
                % Tắt cảnh báo khi readtable tự động đổi tên cột
                warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
                T = readtable(filepath);
                vars = T.Properties.VariableNames;
                
                % 1. Tái tạo các trường cơ bản (Raw DFT & Phase)
                if any(contains(vars, 'Freq_Hz'))
                    proc.freq = T.Freq_Hz;
                else
                    disp('[LỖI] File không đúng định dạng (Thiếu cột Freq_Hz).');
                    return;
                end
                proc.real_raw = T.Raw_Real_DFT;
                proc.imag_raw = T.Raw_Imag_DFT;
                proc.raw_phase = T.Raw_Phase_deg;
                
                % 2. Tái tạo Magnitude thô (|Z| Uncalibrated)
                if any(contains(vars, 'Z_Uncal_Ohm'))
                    proc.z_raw_mag = T.Z_Uncal_Ohm;
                elseif any(contains(vars, 'Magnitude_Z_Uncal'))
                    proc.z_raw_mag = T.Magnitude_Z_Uncal;
                end
                
                % 3. Tái tạo Raw Real Z và Raw Imag Z (Nếu CSV cũ không có thì tự tính lại)
                if any(contains(vars, 'Raw_Real_Z')) && any(contains(vars, 'Raw_Imag_Z'))
                    proc.raw_real_z = T.Raw_Real_Z;
                    proc.raw_imag_z = T.Raw_Imag_Z;
                else
                    proc.raw_real_z = proc.z_raw_mag .* cosd(proc.raw_phase);
                    proc.raw_imag_z = proc.z_raw_mag .* sind(proc.raw_phase);
                end
                
                % 4. Tái tạo phần dữ liệu Đã Hiệu Chuẩn (Calibrated)
                if any(contains(vars, 'Z_Cal_Ohm')) && any(contains(vars, 'Corr_Phase_deg'))
                    proc.is_calibrated = true;
                    proc.z_cal_mag = T.Z_Cal_Ohm;
                    proc.corr_phase = T.Corr_Phase_deg;
                    
                    % Lấy Corr Real Z và Corr Imag Z
                    if any(contains(vars, 'Corr_Real_Z')) && any(contains(vars, 'Corr_Imag_Z'))
                        proc.corr_real_z = T.Corr_Real_Z;
                        proc.corr_imag_z = T.Corr_Imag_Z;
                    else
                        % Tự tính lại nếu nạp từ file CSV cũ
                        proc.corr_real_z = proc.z_cal_mag .* cosd(proc.corr_phase);
                        proc.corr_imag_z = proc.z_cal_mag .* sind(proc.corr_phase);
                    end
                else
                    % Đồng bộ cấu trúc: Nếu chưa hiệu chuẩn thì gán mảng NaN (Giống hệt hàm applyCalibration)
                    proc.is_calibrated = false;
                    proc.z_cal_mag = NaN(size(proc.freq));
                    proc.corr_phase = NaN(size(proc.freq));
                    proc.corr_real_z = NaN(size(proc.freq));
                    proc.corr_imag_z = NaN(size(proc.freq));
                end
                
                disp('=> [OK] Tái tạo dữ liệu thành công. Cấu trúc proc đã đồng bộ!');
                
            catch e
                disp(['[LỖI] Quá trình nạp file thất bại: ', e.message]);
            end
        end
        
        function proc = load_and_plot_CSV(filepath, plot_type)
            proc = struct();
            
            if nargin < 2
                plot_type = 1; % Mặc định vẽ đồ thị Bode
            end
            
            if nargin < 1 || isempty(filepath)
                [file, path] = uigetfile('*.csv', 'Chọn file dữ liệu quét (Ví dụ: SweepData_...)', 'data/');
                if isequal(file, 0)
                    disp('Đã hủy chọn file.');
                    return;
                end
                filepath = fullfile(path, file);
            end
            
            if ~exist(filepath, 'file')
                disp(['[LỖI] Không tìm thấy file: ', filepath]);
                return;
            end
            
            disp(['=> Đang nạp dữ liệu từ: ', filepath]);
            
            try
                % Tắt cảnh báo khi readtable tự động đổi tên cột
                warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
                T = readtable(filepath);
                vars = T.Properties.VariableNames;
                
                % 1. Tái tạo các trường cơ bản (Raw DFT & Phase)
                if any(contains(vars, 'Freq_Hz'))
                    proc.freq = T.Freq_Hz;
                else
                    disp('[LỖI] File không đúng định dạng (Thiếu cột Freq_Hz).');
                    return;
                end
                proc.real_raw = T.Raw_Real_DFT;
                proc.imag_raw = T.Raw_Imag_DFT;
                proc.raw_phase = T.Raw_Phase_deg;
                
                % 2. Tái tạo Magnitude thô (|Z| Uncalibrated)
                if any(contains(vars, 'Z_Uncal_Ohm'))
                    proc.z_raw_mag = T.Z_Uncal_Ohm;
                elseif any(contains(vars, 'Magnitude_Z_Uncal'))
                    proc.z_raw_mag = T.Magnitude_Z_Uncal;
                end
                
                % 3. Tái tạo Raw Real Z và Raw Imag Z (Nếu CSV cũ không có thì tự tính lại)
                if any(contains(vars, 'Raw_Real_Z')) && any(contains(vars, 'Raw_Imag_Z'))
                    proc.raw_real_z = T.Raw_Real_Z;
                    proc.raw_imag_z = T.Raw_Imag_Z;
                else
                    proc.raw_real_z = proc.z_raw_mag .* cosd(proc.raw_phase);
                    proc.raw_imag_z = proc.z_raw_mag .* sind(proc.raw_phase);
                end
                
                % 4. Tái tạo phần dữ liệu Đã Hiệu Chuẩn (Calibrated)
                if any(contains(vars, 'Z_Cal_Ohm')) && any(contains(vars, 'Corr_Phase_deg'))
                    proc.is_calibrated = true;
                    proc.z_cal_mag = T.Z_Cal_Ohm;
                    proc.corr_phase = T.Corr_Phase_deg;
                    
                    % Lấy Corr Real Z và Corr Imag Z
                    if any(contains(vars, 'Corr_Real_Z')) && any(contains(vars, 'Corr_Imag_Z'))
                        proc.corr_real_z = T.Corr_Real_Z;
                        proc.corr_imag_z = T.Corr_Imag_Z;
                    else
                        % Tự tính lại nếu nạp từ file CSV cũ
                        proc.corr_real_z = proc.z_cal_mag .* cosd(proc.corr_phase);
                        proc.corr_imag_z = proc.z_cal_mag .* sind(proc.corr_phase);
                    end
                else
                    % Đồng bộ cấu trúc: Nếu chưa hiệu chuẩn thì gán mảng NaN (Giống hệt hàm applyCalibration)
                    proc.is_calibrated = false;
                    proc.z_cal_mag = NaN(size(proc.freq));
                    proc.corr_phase = NaN(size(proc.freq));
                    proc.corr_real_z = NaN(size(proc.freq));
                    proc.corr_imag_z = NaN(size(proc.freq));
                end
                
                disp('=> [OK] Tái tạo dữ liệu thành công. Cấu trúc proc đã đồng bộ!');
                
                % Tự động gọi các hàm vẽ đồ thị
                if plot_type == 1
                    support.plotBodeSweepData(proc, 1);
                elseif plot_type == 2
                    support.plotSweepData(proc);
                elseif plot_type == 3
                    support.plotCalibratedComplexZ(proc);
                end
                
            catch e
                disp(['[LỖI] Quá trình nạp file thất bại: ', e.message]);
            end
        end
        
        % ================= LỌC DỮ LIỆU THEO DẢI TẦN SỐ =================
        function filtered_proc = filterByFrequency(proc, f_min, f_max)
            % 1. Tạo một bản sao từ struct gốc để giữ lại các biến đơn (ví dụ: is_calibrated)
            filtered_proc = proc;
            
            % Kiểm tra xem có mảng freq không
            if ~isfield(proc, 'freq') || isempty(proc.freq)
                disp('=> [LỖI] Dữ liệu không chứa mảng tần số (freq).');
                return;
            end
            
            % 2. Tạo mặt nạ logic: Tìm các vị trí thỏa mãn điều kiện tần số
            idx = (proc.freq >= f_min) & (proc.freq <= f_max);
            
            % Đếm số điểm giữ lại để báo cáo
            num_kept = sum(idx);
            num_total = length(proc.freq);
            
            if num_kept == 0
                disp('=> [CẢNH BÁO] Không có điểm dữ liệu nào nằm trong dải tần số này!');
                return;
            end
            
            % 3. Lấy danh sách tất cả các trường (fields) có trong struct
            all_fields = fieldnames(proc);
            
            % 4. Quét qua từng trường và tiến hành cắt mảng
            for i = 1:length(all_fields)
                field_name = all_fields{i};
                field_data = proc.(field_name);
                
                % Chỉ cắt nếu trường đó là một mảng và có độ dài bằng với mảng freq
                if isnumeric(field_data) && length(field_data) == num_total
                    % Ép kiểu thành mảng cột để tránh lỗi shape, sau đó lọc
                    field_data_col = field_data(:);
                    filtered_proc.(field_name) = field_data_col(idx);
                end
            end
            
            % 5. Báo cáo kết quả ra console
            fprintf('=> Đã lọc dữ liệu: Giữ lại %d / %d điểm (Từ %g Hz đến %g Hz).\n', ...
                    num_kept, num_total, f_min, f_max);
        end

        function plotBodeSweepData2(proc, calib, export_filename)
            if ~isfield(proc, 'freq') || isempty(proc.freq)
                disp('=> Không có dữ liệu để vẽ đồ thị.');
                return;
            end
            disp('6. Đang hiển thị đồ thị Bode (2 Subplots)...');
            
            % Tạo cửa sổ Figure mới (Tăng chiều cao lên 650 để chứa 2 đồ thị)
            f_fig = figure('Name', 'AD5933 Bode Plot', 'NumberTitle', 'off', 'Color', 'w');
            f_fig.Position = [150, 100, 900, 650]; 
            
            % Chọn dữ liệu để vẽ (Ưu tiên dữ liệu đã hiệu chuẩn)
            freqs = proc.freq;
            if proc.is_calibrated && calib == 1
                mag_data = proc.z_cal_mag;
                phase_data = proc.corr_phase;
                line_name = 'Đã áp dụng hiệu chuẩn';
                color_mag = 'b';  % Xanh blue cho magnitude đã hiệu chuẩn
            else
                mag_data = proc.z_raw_mag;
                phase_data = proc.raw_phase;
                line_name = 'Dữ liệu thô';
                color_mag = 'r';  % Đỏ cho magnitude chưa hiệu chuẩn
            end
            
            % ==================== ĐỒ THỊ 1: TRỞ KHÁNG (Phía trên) ====================
            ax1 = subplot(2, 1, 1); 
            semilogx(freqs, mag_data, '-', 'Color', color_mag, 'LineWidth', 2, 'DisplayName', [line_name ' |Z|']);
            
            % Đổi tên nhãn Y vì đơn vị đã được ghi trực tiếp trên từng vạch
            ylabel('Trở kháng', 'FontWeight', 'bold');
            title('Trở kháng theo tần số', 'FontSize', 12, 'FontWeight', 'bold');
            
            % Chỉnh lại khoảng đệm trục Y cho đồ thị tuyến tính
            min_mag = min(mag_data);
            max_mag = max(mag_data);
            if min_mag < max_mag
                range_mag = max_mag - min_mag;
                ylim([max(0, min_mag - 0.1 * range_mag), max_mag + 0.15 * range_mag]);
            end
            xlim([min(freqs) max(freqs)]);
            
            grid on; grid minor; box on;
            legend('Location', 'best');
            ax1.FontName = 'Times New Roman'; 
            
            % --- ĐỊNH DẠNG LẠI TRỤC Y (K\Omega, M\Omega) VÀ TẮT HỆ SỐ MŨ ---
            % Bắt MATLAB cập nhật lại các vạch chia trước khi lấy giá trị
            drawnow; 
            yticks_vals = ax1.YTick;
            labels = cell(size(yticks_vals));
            
            % Lặp qua từng vạch để format lại con số
            for i = 1:length(yticks_vals)
                val = yticks_vals(i);
                if val >= 1e6
                    ylabel('Trở kháng (M\Omega)', 'FontWeight', 'bold');
                    labels{i} = sprintf('%g', val / 1e6);
                elseif val >= 1e3
                    ylabel('Trở kháng (k\Omega)', 'FontWeight', 'bold');
                    labels{i} = sprintf('%g', val / 1e3);
                else
                    ylabel('Trở kháng (\Omega)', 'FontWeight', 'bold');
                    labels{i} = sprintf('%g', val);
                end
            end
            
            % Gắn nhãn mới vào trục Y và kích hoạt bộ dịch mã TeX để vẽ dấu Omega
            ax1.YTickLabel = labels;
            ax1.TickLabelInterpreter = 'tex';
            
            % ==================== ĐỒ THỊ 2: GÓC PHA (Phía dưới) ====================
            ax2 = subplot(2, 1, 2); % Lưới 2 hàng, 1 cột, vị trí số 2
            semilogx(freqs, phase_data, 'k--', 'LineWidth', 1.5, 'DisplayName', ['Pha ' line_name ]);
            
            xlabel('Tần số (Hz)', 'FontWeight', 'bold');
            ylabel('Pha (\circ)', 'FontWeight', 'bold');
            title('Pha theo tần số', 'FontSize', 12, 'FontWeight', 'bold');
            
            % Chỉnh giới hạn trục và hiển thị
            min_p = min(proc.corr_phase(:), [], 'omitnan');
            max_p = max(proc.corr_phase(:), [], 'omitnan');
            
            % Kiểm tra xem có điểm pha nào vượt quá ngưỡng -90 đến 90 độ không
            if min_p >= -30 && max_p <= 30
                ylim([-30 30]);
                yticks([-30 -15 0 25 30]); % Nếu dải hẹp thì chia vạch bước 45 độ nhìn sẽ rất đẹp
            elseif min_p >= -90 && max_p <= 90
                ylim([-90 90]);
                yticks([-90 -45 0 45 90]); % Nếu dải hẹp thì chia vạch bước 45 độ nhìn sẽ rất đẹp
            else
                ylim([-180 180]);
                yticks([-180 -90 0 90 180]); % Giữ nguyên dải rộng chuẩn Bode nếu có điểm vượt ngưỡng
            end
            xlim([min(freqs) max(freqs)]);
            
            grid on; grid minor; box on;
            legend('Location', 'best');
            ax2.FontName = 'Times New Roman'; % Sửa font cho LaTeX
            
            % ==================== XUẤT FILE CHO LATEX ====================

            
            % Xuất file bằng exportgraphics 
            % Lưu ý: Truyền f_fig (cửa sổ chính) thay vì ax1 hay ax2 để gom cả 2 vào 1 file
            try
                exportgraphics(f_fig, export_filename, 'ContentType', 'vector', 'BackgroundColor', 'none');
                fprintf('=> Đã xuất đồ thị Vector ra file: %s \n', export_filename);
            catch
                disp('=> [CẢNH BÁO] Không thể xuất file PDF (Có thể do bản MATLAB cũ không hỗ trợ exportgraphics).');
            end
        end
        
        % ================= SO SÁNH TỔNG TRỞ PHỨC ĐO ĐẠC VS LÝ THUYẾT (BẢN CHUẨN LATEX) =================
        function compareTheoreticalComplexZ(proc, Z_theo_complex, export_filename)
            if ~isfield(proc, 'freq') || isempty(proc.freq)
                disp('=> Không có dữ liệu đo đạc để so sánh.');
                return;
            end
            
            % 1. Ép các biến đo đạc thành mảng cột (Nx1)
            freq_meas = proc.freq(:);
            mag_meas = proc.z_cal_mag(:);
            phase_meas = proc.corr_phase(:);
            
            % Tự động xác định màu sắc dựa trên trạng thái hiệu chuẩn của dữ liệu đo
            if proc.is_calibrated
                line_name_meas = 'Calibrated';
                color_mag = 'b';  % Xanh dương cho dữ liệu đã hiệu chuẩn
            else
                mag_meas = proc.z_raw_mag(:);
                phase_meas = proc.raw_phase(:);
                line_name_meas = 'Uncalibrated';
                color_mag = 'r';  % Đỏ cho dữ liệu thô chưa hiệu chuẩn
            end
            
            % 2. TỰ ĐỘNG SỬA LỖI: Nếu Z lý thuyết truyền vào là 1 số duy nhất (Scalar)
            if isscalar(Z_theo_complex)
                Z_theo_complex = Z_theo_complex * ones(size(freq_meas));
            end
            Z_theo = Z_theo_complex(:);
            
            % 3. Kiểm tra và cắt tỉa độ dài mảng nếu có sai lệch nhỏ
            len_meas = length(freq_meas);
            len_theo = length(Z_theo);
            if len_meas ~= len_theo
                disp('=> [CẢNH BÁO] Chiều dài mảng đo đạc và lý thuyết không khớp. Đang tự động cấu trúc lại...');
                min_len = min(len_meas, len_theo);
                freq_meas = freq_meas(1:min_len);
                mag_meas = mag_meas(1:min_len);
                phase_meas = phase_meas(1:min_len);
                Z_theo = Z_theo(1:min_len);
            end
            
            % ==================== 4. TÍNH TOÁN SAI SỐ (CHIA THEO DẢI TẦN) ====================
            Z_theo_mag = abs(Z_theo);
            Phase_theo = angle(Z_theo) * (180 / pi); % Chuyển đổi sang Độ (Degrees)
            
            % Khai báo 4 dải tần số cần bóc tách
            band_limits = [
                10, 100;
                100, 1000;
                1000, 10000;
                10000, 100000
            ];
            num_bands = size(band_limits, 1);
            
            % Mảng lưu kết quả cho từng dải
            mae_mag_bands = zeros(num_bands, 1);
            mape_mag_bands = zeros(num_bands, 1);
            mae_phase_bands = zeros(num_bands, 1);
            valid_bands = false(num_bands, 1); % Cờ kiểm tra xem dải đó có dữ liệu không
            
            for i = 1:num_bands
                f_min = band_limits(i, 1);
                f_max = band_limits(i, 2);
                
                % Tạo mặt nạ lọc các điểm nằm trong dải hiện tại
                idx = (freq_meas >= f_min) & (freq_meas <= f_max);
                
                if any(idx)
                    valid_bands(i) = true;
                    mae_mag_bands(i) = mean(abs(mag_meas(idx) - Z_theo_mag(idx)), 'omitnan');
                    mae_phase_bands(i) = mean(abs(phase_meas(idx) - Phase_theo(idx)), 'omitnan');
                    mape_mag_bands(i) = mean(abs((mag_meas(idx) - Z_theo_mag(idx)) ./ Z_theo_mag(idx)), 'omitnan') * 100;
                end
            end
            
            % Vẫn tính thêm sai số tổng thể trên toàn dải để tham chiếu
            mae_mag_overall = mean(abs(mag_meas - Z_theo_mag), 'omitnan');
            mae_phase_overall = mean(abs(phase_meas - Phase_theo), 'omitnan');
            mape_mag_overall = mean(abs((mag_meas - Z_theo_mag) ./ Z_theo_mag), 'omitnan') * 100;
            
            % ==================== 5. KHỞI TẠO FIGURE SUBLOTS ====================
            disp('6. Đang hiển thị đồ thị so sánh Thực tế vs Lý thuyết (Trục Y Tuyến tính)...');
            f_fig = figure('Name', 'AD5933: Measured vs Theoretical', 'NumberTitle', 'off', 'Color', 'w');
            f_fig.Position = [150, 100, 900, 650]; 
            
            % ------------------- SUBPLOT 1: BIÊN ĐỘ TỔNG TRỞ (Tuyến tính) -------------------
            ax1 = subplot(2, 1, 1);
            semilogx(freq_meas, mag_meas, '-', 'Color', color_mag, 'LineWidth', 2, 'DisplayName', [line_name_meas ' |Z|']); hold on;
            semilogx(freq_meas, Z_theo_mag, 'k--', 'LineWidth', 2, 'DisplayName', 'Lý thuyết |Z|');
            
            ylabel('Trở kháng', 'FontWeight', 'bold');
            title('Trở kháng theo tần số', 'FontSize', 12, 'FontWeight', 'bold');
            
            % Định cấu hình khoảng đệm trục Y tuyến tính tinh tế
            min_mag = min([mag_meas; Z_theo_mag]);
            max_mag = max([mag_meas; Z_theo_mag]);
            if min_mag < max_mag
                range_mag = max_mag - min_mag;
                ylim([max(0, min_mag - 0.1 * range_mag), max_mag + 0.15 * range_mag]);
            end
            xlim([min(freq_meas) max(freq_meas)]);
            grid on; grid minor; box on;
            legend('Location', 'best');
            ax1.FontName = 'Times New Roman';
            
            % --- ĐỊNH DẠNG TRỤC Y SANG K\Omega / M\Omega ĐỂ FIX LỖI XUẤT PDF ---
            drawnow; 
            yticks_vals = ax1.YTick;
            labels = cell(size(yticks_vals));
            for i = 1:length(yticks_vals)
                val = yticks_vals(i);
                if val >= 1e6
                    ylabel('Trở kháng (M\Omega)', 'FontWeight', 'bold');
                    labels{i} = sprintf('%g', val / 1e6);
                elseif val >= 1e3
                    ylabel('Trở kháng (k\Omega)', 'FontWeight', 'bold');
                    labels{i} = sprintf('%g', val / 1e3);
                else
                    ylabel('Trở kháng (\Omega)', 'FontWeight', 'bold');
                    labels{i} = sprintf('%g', val);
                end
            end
            ax1.YTickLabel = labels;
            ax1.TickLabelInterpreter = 'tex';
            
            % ------------------- SUBPLOT 2: GÓC PHA (Tuyến tính) -------------------
            ax2 = subplot(2, 1, 2);
            semilogx(freq_meas, phase_meas, '-', 'Color', color_mag, 'LineWidth', 2, 'DisplayName', [line_name_meas ' Phase']); hold on;
            semilogx(freq_meas, Phase_theo, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Theoretical Phase');
            
            xlabel('Tần số (Hz)', 'FontWeight', 'bold');
            ylabel('Pha (\circ)', 'FontWeight', 'bold');
            title('Pha theo tần số', 'FontSize', 12, 'FontWeight', 'bold');
            
            % --- TỰ ĐỘNG SCALE ĐỘNG TRỤC Y PHA THEO ĐIỀU KIỆN ---
            all_phases = [phase_meas(:); Phase_theo(:)]; % Gom cả pha đo và pha lý thuyết lại để xét
            min_p = min(all_phases, [], 'omitnan');
            max_p = max(all_phases, [], 'omitnan');
            
            % Kiểm tra xem có điểm pha nào vượt quá ngưỡng -90 đến 90 độ không
            if min_p >= -30 && max_p <= 30
                ylim([-30 30]);
                yticks([-30 -15 0 15 30]); % Nếu dải hẹp thì chia vạch bước 45 độ nhìn sẽ rất đẹp
            elseif min_p >= -90 && max_p <= 90
                ylim([-90 90]);
                yticks([-90 -45 0 45 90]); % Nếu dải hẹp thì chia vạch bước 45 độ nhìn sẽ rất đẹp
            else
                ylim([-180 180]);
                yticks([-180 -90 0 90 180]); % Giữ nguyên dải rộng chuẩn Bode nếu có điểm vượt ngưỡng
            end
            xlim([min(freq_meas) max(freq_meas)]);
            grid on; grid minor; box on;
            legend('Location', 'best');
            ax2.FontName = 'Times New Roman';
            
            % ==================== 6. XUẤT FILE VECTOR CHO LATEX ====================
            % export_filename = 'Bode_Theory_Comparison.pdf';
            try
                % Xuất toàn bộ figure f_fig để không bỏ sót bất kỳ nét vẽ nào
                exportgraphics(f_fig, export_filename, 'ContentType', 'vector', 'BackgroundColor', 'none');
                fprintf('=> Đã xuất đồ thị Vector so sánh thành công ra file: %s\n', export_filename);
            catch
                disp('=> [CẢNH BÁO] Không thể xuất file PDF bằng lệnh exportgraphics.');
            end
            
            % ==================== 7. IN BÁO CÁO SAI SỐ RA CONSOLE ====================
            fprintf('\n================ KẾT QUẢ PHÂN TÍCH SAI SỐ MÔ HÌNH =================\n');
            fprintf('[TỔNG THỂ TOÀN DẢI ĐO]\n');
            fprintf(' - MAE Biên độ : %.2f \\Omega (Tương đương sai số %.2f%%)\n', mae_mag_overall, mape_mag_overall);
            fprintf(' - MAE Góc pha : %.2f độ\n', mae_phase_overall);
            fprintf('-------------------------------------------------------------------\n');
            fprintf('[PHÂN TÍCH CHI TIẾT THEO TỪNG DẢI TẦN]\n');
            
            for i = 1:num_bands
                if valid_bands(i)
                    fprintf(' > Dải %d (%g Hz - %g Hz):\n', i, band_limits(i,1), band_limits(i,2));
                    fprintf('    + Sai số Biên độ : %.2f \\Omega (%.2f%%)\n', mae_mag_bands(i), mape_mag_bands(i));
                    fprintf('    + Sai số Góc pha : %.2f độ\n', mae_phase_bands(i));
                else
                    fprintf(' > Dải %d (%g Hz - %g Hz): (Không có dữ liệu đo đạc)\n', i, band_limits(i,1), band_limits(i,2));
                end
            end
            fprintf('===================================================================\n');
        end

    end
end