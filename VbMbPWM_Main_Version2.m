clear;
close all;

% Check if parallel pool exists, create if not
if isempty(gcp('nocreate'))
    parpool(8);
end

% Parameter initialization
f_s = 16e9;          % RF sample rate
N = 64;              % Sequence length
f_BB = 5e6;         % Baseband data rate
M = 64;              % 64QAM
alpha = 0.5;         % Roll-off factor
T = 1e-4;            % Simulation duration
r = 0.5;            % Scaling value

% Waveform generation
t = 0:1/f_BB:T-1/f_BB;
INFO_bit = rand(length(t) * log2(M), 1) < 0.5;
INFO_int = bit2int(INFO_bit, log2(M));
INFO_sym = qammod(INFO_int, M, "bin");
INFO_sym = INFO_sym / max(abs(INFO_sym));

% Upsample
IF_interp_factor = f_s / N / f_BB;
f_IF = f_s / N;

rcos_filt = rcosdesign(alpha, 32, IF_interp_factor);
BB_sym = conv(upsample(INFO_sym, IF_interp_factor), rcos_filt);
BB_sym_norm = BB_sym / max(abs(BB_sym));
IF_sym_norm = BB_sym_norm;

t_IF = 0:1/f_IF:(length(IF_sym_norm)-1)/f_IF;

% Preallocate result arrays
fc_values = 0.5e9:0.5e9:7.5e9;  % Reduced frequency points for faster simulation
rms_EVM_org = zeros(1, length(fc_values));
rms_SNR_org = zeros(1, length(fc_values));  % Preallocate SNR array
fc_index = 1;

% 存储每个载波频率对应的生成序列
all_sequences = cell(1, length(fc_values));

fprintf('Starting VbPWM ADT Simulation\n');
fprintf('============================\n');

for f_c = fc_values
    fprintf('Processing carrier frequency: %.2f GHz\n', f_c/1e9);
    
    IF_sym_phaseCorr = IF_sym_norm .* exp(-1i*2*pi * f_c * t_IF)';
    lab_seg_len = floor(length(IF_sym_phaseCorr) / 8);
    
    % Process in parallel
    spmd
        current_lab = spmdIndex();
        local_path = zeros(1, lab_seg_len * N);
        
        for current_index = 1:lab_seg_len
            s = r * IF_sym_phaseCorr(current_index + (current_lab-1) * lab_seg_len);
            
            % Call the pure MATLAB VbPWM implementation
            [out_org, path_len] = VbMbPWM(s, N, f_c, f_s, 2);
            
            local_path((current_index-1)*N+1:current_index*N) = double(out_org);
        end
        target_path_org = local_path;
    end
    
    % Combine results from all workers
    RF_bin_org = [cell2mat(target_path_org(1)), cell2mat(target_path_org(2)), ...
                  cell2mat(target_path_org(3)), cell2mat(target_path_org(4)), ...
                  cell2mat(target_path_org(5)), cell2mat(target_path_org(6)), ... 
                  cell2mat(target_path_org(7)), cell2mat(target_path_org(8))];
    
    % 存储当前载波频率生成的序列
    all_sequences{fc_index} = RF_bin_org;
    
    % ========== 输出迭代生成的序列 ==========
    fprintf('\n  Generated sequence for f_c = %.2f GHz:\n', f_c/1e9);
    fprintf('  Sequence length: %d bits\n', length(RF_bin_org));
    
    % 显示序列的前100个比特（或全部，如果长度小于100）
    display_len = min(100, length(RF_bin_org));
    fprintf('  First %d bits: ', display_len);
    fprintf('%d', RF_bin_org(1:display_len));
    fprintf('\n');
    
    % 显示序列统计信息
    num_ones = sum(RF_bin_org);
    num_zeros = length(RF_bin_org) - num_ones;
    fprintf('  Sequence statistics:\n');
    fprintf('    Number of 1s: %d (%.2f%%)\n', num_ones, 100*num_ones/length(RF_bin_org));
    fprintf('    Number of 0s: %d (%.2f%%)\n', num_zeros, 100*num_zeros/length(RF_bin_org));
    fprintf('  ----------------------------------------\n');
    % ==========================================
    
    % Receiver processing
    t_RF = 0:1/f_s:length(RF_bin_org)*1/f_s-1/f_s;
    rx_carrier = exp(-1i * 2 * pi * f_c * t_RF) / N;
    rx_RF_sym = (2*RF_bin_org - 1) .* rx_carrier;
    
    rx_RF_reshape = reshape(rx_RF_sym, [N, length(rx_RF_sym)/N]);
    rx_IF_sym = sum(rx_RF_reshape);
    
    rx_INFO_filt = conv(rx_IF_sym, rcos_filt);
    rx_INFO_sym = downsample(rx_INFO_filt(length(rcos_filt):end-length(rcos_filt)+1), IF_interp_factor);
                                                                                  
    % Normalize received signal
    power_rx = sum(abs(rx_INFO_sym).^2);
    power_tx = sum(abs(INFO_sym).^2);
    rx_scale = power_tx / power_rx;
    rx_INFO_sym_norm = rx_INFO_sym .* sqrt(rx_scale);
    
    % Calculate EVM
    mEVM_org = abs(conj(INFO_sym)' - rx_INFO_sym_norm) ./ abs(INFO_sym') * 100;
    rms_EVM_org(fc_index) = sqrt(sum(mEVM_org.^2) / length(mEVM_org));
    
    % ========== 根据EVM计算SNR (公式39) ==========
    % SNR(dB) = -6.3 - 20*log10(EVM(%))
    rms_SNR_org(fc_index) = -5.8 - 20 * log10(0.01*rms_EVM_org(fc_index));
    % =============================================
    
    fprintf('  EVM: %.2f%%\n', rms_EVM_org(fc_index));
    fprintf('  SNR: %.2f dB\n\n', rms_SNR_org(fc_index));
    fc_index = fc_index + 1;
end

% Cleanup parallel pool
delete(gcp('nocreate'));

% Plot EVM results
figure;
plot(fc_values/1e9, rms_EVM_org, '-o', 'LineWidth', 1.5);
xlabel('Carrier Frequency (GHz)');
ylabel('RMS EVM (%)');
title('VbPWM ADT EVM vs Carrier Frequency');
grid on;

% Plot SNR results
figure;
plot(fc_values/1e9, rms_SNR_org, '-s', 'LineWidth', 1.5, 'Color', [0.8500 0.3250 0.0980]);
xlabel('Carrier Frequency (GHz)');
ylabel('SNR (dB)');
title('VbPWM ADT SNR vs Carrier Frequency');
grid on;

% Plot EVM and SNR on dual-axis
figure;
yyaxis left;
plot(fc_values/1e9, rms_EVM_org, '-o', 'LineWidth', 1.5);
ylabel('RMS EVM (%)');
yyaxis right;
plot(fc_values/1e9, rms_SNR_org, '-s', 'LineWidth', 1.5);
ylabel('SNR (dB)');
xlabel('Carrier Frequency (GHz)');
title('VbPWM ADT EVM & SNR vs Carrier Frequency');
grid on;
legend('EVM (%)', 'SNR (dB)', 'Location', 'best');

fprintf('\nSimulation Complete!\n');
fprintf('==================== EVM Results ====================\n');
fprintf('Average EVM: %.2f%%\n', mean(rms_EVM_org));
fprintf('Max EVM:     %.2f%%\n', max(rms_EVM_org));
fprintf('Min EVM:     %.2f%%\n', min(rms_EVM_org));
fprintf('==================== SNR Results ====================\n');
fprintf('Average SNR: %.2f dB\n', mean(rms_SNR_org));
fprintf('Max SNR:     %.2f dB\n', max(rms_SNR_org));
fprintf('Min SNR:     %.2f dB\n', min(rms_SNR_org));
fprintf('=====================================================\n');
% ┌─────────────────────────────────────────────────────────────────────┐
% │                         发射端处理                                   │
% ├─────────────────────────────────────────────────────────────────────┤
% │                                                                     │
% │  随机比特 → 64-QAM调制 → 上采样 → 滤波 → 归一化                      │
% │     │           │          │         │          │                   │
% │     ▼           ▼          ▼         ▼          ▼                   │
% │  INFO_bit → INFO_sym → upsample → conv() → IF_sym_norm              │
% │                                                                     │
% │  上采样因子 = f_s / N / f_BB = 16e9 / 64 / 25e6 = 10                │
% │                                                                     │
% ├─────────────────────────────────────────────────────────────────────┤
% │                         VbPWM 编码                                   │
% ├─────────────────────────────────────────────────────────────────────┤
% │                                                                     │
% │  载波:  IF_sym_phaseCorr = IF_sym_norm * e^(-j*2π*f_c*t)            │
% │                                                                     │
% │  并行处理 (8个worker):                                              │
% │  ┌─────────────────────────────────────────────────────────────┐    │
% │  │  Worker 1: 处理 1/8 数据 ─┐                                 │    │
% │  │  Worker 2: 处理 1/8 数据 ─┤                                 │    │
% │  │  ...                      ├──> 合并 ──> RF_bin_org          │    │
% │  │  Worker 8: 处理 1/8 数据 ─┘                                 │    │
% │  └─────────────────────────────────────────────────────────────┘    │
% │                                                                     │
% │  每个符号:  s → VbMbPWM() → 64位二进制序列                          │
% │                                                                     │
% ├─────────────────────────────────────────────────────────────────────┤
% │                         接收端处理                                   │
% ├─────────────────────────────────────────────────────────────────────┤
% │                                                                     │
% │  1. 比特映射: RF_bin → (2*RF_bin - 1)                               │
% │                                                                     │
% │  2. 下变频: rx_RF_sym = mapped_bits * e^(-j*2π*f_c*t) / N          │
% │                                                                     │
% │  3. 积分/求和: reshape为[N, num_symbols], 对每列求和                │
% │                                                                     │
% │  4. 匹配滤波: conv(rx_IF_sym, rcos_filt)                            │
% │                                                                     │
% │  5. 下采样: 恢复原始符号率                                          │
% │                                                                     │
% │  6. 功率归一化                                                      │
% │                                                                     │
% └─────────────────────────────────────────────────────────────────────┘