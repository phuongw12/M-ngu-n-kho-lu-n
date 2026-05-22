classdef STM32_protocol < handle
    properties
        s % Đối tượng serialport
        isConnected = false;
    end
    
    methods
        function obj = STM32_AD5933(portName, baudRate)
            try
                % Khởi tạo kết nối Serial
                obj.s = serialport(portName, baudRate);
                % Timeout 1.0s là đủ dài để đo các điểm chậm, vừa đủ ngắn để kích hoạt Watchdog
                obj.s.Timeout = 1.0; 
                flush(obj.s);
                obj.isConnected = true;
            catch ME
                disp(['[LỖI] Không thể mở cổng Serial: ', ME.message]);
            end
        end

        
        
        function is_ok = ping(obj)
            is_ok = false;
            if ~obj.isConnected, return; end
            try
                flush(obj.s);
                write(obj.s, uint8(hex2dec('A5')), "uint8"); % CMD_PING = 0xA5
                resp = read(obj.s, 1, "uint8");
                if ~isempty(resp) && resp == hex2dec('B6')   % CMD_PONG = 0xB6
                    is_ok = true;
                end
            catch
            end
        end
        
        function cfg = get_config(obj)
            cfg = [];
            if ~obj.isConnected, return; end
            try
                flush(obj.s);
                write(obj.s, uint8(hex2dec('20')), "uint8"); % CMD_GET_CONFIG = 0x20
                
                header = read(obj.s, 1, "uint8");
                if isempty(header) || header ~= hex2dec('22') % CMD_CONFIG_RESP_V2 = 0x22
                    return;
                end
                
                data = read(obj.s, 26, "uint8");
                if length(data) == 26
                    cfg.start     = typecast(data(1:4), 'single');
                    cfg.stop      = typecast(data(5:8), 'single');
                    cfg.step      = typecast(data(9:12), 'single');
                    cfg.mode      = data(13);
                    cfg.clock_sel = data(14);
                    cfg.i2c       = data(15);
                    cfg.regs      = data(16:25);
                    cfg.status    = data(26);
                end
            catch
            end
        end
        
        function success = set_sweep_params(obj, mode, clock_sel, start_f, ...
                stop_f, step_f,Voltage_Range, PGA_Gain, MUX_Ctrl, AVDD)
            success = false;
            if ~obj.isConnected, return; end
            try
                flush(obj.s);
                % Đóng gói <BBBfff
                cmd = uint8(hex2dec('80'));
                m = uint8(mode);
                c = uint8(clock_sel);
                st  = typecast(single(start_f), 'uint8');
                sp  = typecast(single(stop_f), 'uint8');
                stp = typecast(single(step_f), 'uint8');
                vr = uint8(Voltage_Range);
                gpa_gain = uint8(PGA_Gain);
                mux_ctrl = uint8(MUX_Ctrl);
                avdd = uint8(AVDD);
                write(obj.s, [cmd, m, c, st, sp, stp, vr, gpa_gain, mux_ctrl,avdd], "uint8");
                
                % --- TĂNG THỜI GIAN CHỜ (TIMEOUT) TẠM THỜI ---
                old_timeout = obj.s.Timeout;
                obj.s.Timeout = 6000000.0; % Tăng lên 3 giây để STM32 có dư thời gian setup I2C/Power
                
                resp = read(obj.s, 2, "uint8");
                
                obj.s.Timeout = old_timeout; % Trả lại timeout cũ
                % ---------------------------------------------
                % Check CMD_ACK = 0x81
                if length(resp) >= 2 && resp(1) == hex2dec('81') && resp(2) == mode
                    success = true;
                end
            catch
            end
        end
        
        function success = set_simple_mode(obj, mode)
            success = false;
            if ~obj.isConnected, return; end
            try
                flush(obj.s);
                write(obj.s, [uint8(hex2dec('80')), uint8(mode)], "uint8");
                resp = read(obj.s, 2, "uint8");
                if length(resp) >= 2 && resp(1) == hex2dec('81')
                    success = true;
                end
            catch
            end
        end
        
        function [freq, real_val, imag_val] = fetch_data_point(obj)
            freq = []; real_val = []; imag_val = [];
            if ~obj.isConnected, return; end    
            try
                CMD_FETCH_DATA = uint8(hex2dec('11'));
                HEADER_DATA = uint8(hex2dec('13'));
                flush(obj.s, "input");
                % --- 1. Gửi lệnh ---
                write(obj.s, CMD_FETCH_DATA, "uint8");
                % --- 2. Đợi header (có timeout) ---
                timeout = 3; % giây
                t_start = tic;
                header = [];
                while isempty(header)
                    if obj.s.NumBytesAvailable >= 1
                        header = read(obj.s, 1, "uint8");
                        break;
                    end
                    if toc(t_start) > timeout
                        return; % timeout giống Python
                    end
                end
                % --- 3. Check header ---
                if header ~= HEADER_DATA
                    flush(obj.s, "input"); % giống reset_input_buffer
                    return;
                end
                % --- 4. Đợi đủ 12 byte payload ---
                t_start = tic;
                while obj.s.NumBytesAvailable < 12
                    if toc(t_start) > timeout
                        flush(obj.s, "input");
                        return;
                    end
                end
                % --- 5. Đọc data ---
                data = read(obj.s, 12, "uint8");
                % --- 6. Parse giống Python ---
                freq = typecast(uint8(data(1:4)), 'single');
                real_raw = typecast(uint8(data(5:8)), 'uint32');
                imag_raw = typecast(uint8(data(9:12)), 'uint32');
                real_val = double(typecast(uint16(bitand(real_raw, 65535)), 'int16'));
                imag_val = double(typecast(uint16(bitand(imag_raw, 65535)), 'int16'));
            catch
                % có thể log lỗi nếu cần
            end
        end
        
        function disconnect(obj)
            if obj.isConnected
                try
                    obj.set_simple_mode(0); % Đưa STM32 về mode 0 (Stop)
                catch
                end
                clear obj.s;
                obj.isConnected = false;
            end
        end

    end
end