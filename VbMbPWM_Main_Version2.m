clear;
close all;

% Check if parallel pool exists, create if not
if isempty(gcp('nocreate'))
    parpool(8);
end

% ========== 基本参数设置（对应论文 Section III-B2）==========
f_s   = 16e9;    % RF采样率 16 Gbps
N     = 64;      % 序列长度（VbPWM主要配置为64 bits）
alpha = 0.5;     % 滚降系数
T     = 1e-4;    % 仿真时长
r     = 0.5;     % 幅度缩放因子（VbPWM取0.5，论文 Section III-B2）

% 载波频率扫描：0.5 GHz → 7.5 GHz，步长0.5 GHz（论文图6）
fc_values = 0.5e9:0.5e9:7.5e9;
num_fc = length(fc_values);

% ========== 设计接收机抗混叠滤波器（固定，论文 Section III-B2）==========
% 第一级：8阶Chebyshev Type I IIR，16 Gsps → 1 Gsps（抽取因子16）
decim_factor1 = 16;
f_IF_rx = f_s / decim_factor1;          % 1 Gsps
[b_cheby, a_cheby] = cheby1(8, 0.5, 1/decim_factor1);

% 第二级：FIR滤波器，1 Gsps → 250 Msps（抽取因子4）
% 通带 75 MHz，阻带 100 MHz（论文 Section III-B2）
decim_factor2 = 4;
fir_order = 64;
fir_coeff = firpm(fir_order, [0, 2*75e6/f_IF_rx, 2*100e6/f_IF_rx, 1], [1, 1, 0, 0]);

% 接收机输出采样率固定为 250 Msps
f_rx_out = f_IF_rx / decim_factor2;     % 250 Msps

% ========== 仿真配置矩阵（对应论文图6各子图）==========
% configs: {M, f_BB, lm, use_sa, label}
configs = {
    16, 5e6,  2, false, 'VbPWM N=64, lm=2, no SA';
    16, 5e6,  3, false, 'VbPWM N=64, lm=3, no SA';
    16, 5e6,  2, true,  'VbPWM N=64, lm=2, with SA';
    16, 5e6,  3, true,  'VbPWM N=64, lm=3, with SA';
    16, 25e6, 2, false, 'VbPWM N=64, lm=2, no SA (25MBaud)';
    16, 25e6, 3, false, 'VbPWM N=64, lm=3, no SA (25MBaud)';
    16, 25e6, 2, true,  'VbPWM N=64, lm=2, with SA (25MBaud)';
    16, 25e6, 3, true,  'VbPWM N=64, lm=3, with SA (25MBaud)';
    64, 5e6,  2, true,  'VbPWM N=64, 64QAM, lm=2, with SA';
};
num_configs = size(configs, 1);

% 预分配结果数组
rms_EVM_all = zeros(num_configs, num_fc);
rms_SNR_all = zeros(num_configs, num_fc);

fprintf('Starting VbPWM ADT Simulation (Paper Section III-B2)\n');
fprintf('=====================================================\n');

% ========== 对每种仿真配置循环 ==========
for cfg_idx = 1:num_configs
    M        = configs{cfg_idx, 1};
    f_BB     = configs{cfg_idx, 2};
    lm       = configs{cfg_idx, 3};
    use_sa   = configs{cfg_idx, 4};
    cfg_name = configs{cfg_idx, 5};

    fprintf('\n[Config %d/%d] %s\n', cfg_idx, num_configs, cfg_name);

    % ---------- 发射端基带波形生成 ----------
    % IF采样率和上采样因子
    f_IF = f_s / N;                        % 250 Msps (N=64)
    IF_interp_factor = f_IF / f_BB;        % 上采样因子（5 MBaud→50, 25 MBaud→10）
    assert(mod(IF_interp_factor, 1) == 0, 'f_IF must be an integer multiple of f_BB');

    t = 0:1/f_BB:T-1/f_BB;
    INFO_bit = rand(length(t) * log2(M), 1) < 0.5;
    INFO_int = bit2int(INFO_bit, log2(M));
    INFO_sym = qammod(INFO_int, M, 'bin');
    INFO_sym = INFO_sym / max(abs(INFO_sym));

    % 发射端RRC滤波器（设计在IF采样率）
    rcos_filt_tx = rcosdesign(alpha, 32, IF_interp_factor);
    BB_sym = conv(upsample(INFO_sym, IF_interp_factor), rcos_filt_tx);
    BB_sym_norm = BB_sym / max(abs(BB_sym));
    IF_sym_norm = BB_sym_norm;

    t_IF = 0:1/f_IF:(length(IF_sym_norm)-1)/f_IF;

    % 接收机侧RRC匹配滤波器：基于固定250 Msps接收机输出率
    rx_interp_factor = f_rx_out / f_BB;    % 50(5MBaud) 或 10(25MBaud)
    assert(mod(rx_interp_factor, 1) == 0, 'f_rx_out must be an integer multiple of f_BB');
    rcos_filt_rx = rcosdesign(alpha, 32, rx_interp_factor);

    % ---------- VbPWM编码 + 接收机处理（并行化载波频率循环）----------
    rms_EVM_cfg = zeros(1, num_fc);
    rms_SNR_cfg = zeros(1, num_fc);

    parfor fc_idx = 1:num_fc
        f_c = fc_values(fc_idx);

        % 相位校正（上变频到载波）
        IF_sym_phaseCorr = IF_sym_norm .* exp(-1i*2*pi * f_c * t_IF).';

        % VbPWM编码：每个IF样点→N比特RF序列
        num_samples = length(IF_sym_phaseCorr);
        RF_bin = zeros(1, num_samples * N);

        for idx = 1:num_samples
            s = r * IF_sym_phaseCorr(idx);
            out_seq = VbMbPWM(s, N, f_c, f_s, lm, use_sa);
            RF_bin((idx-1)*N+1:idx*N) = double(out_seq);
        end

        % ---------- 接收机处理（论文 Section III-B2）----------
        t_RF = (0:length(RF_bin)-1) / f_s;

        % 第一步：下变频到复数基带
        rx_BB_RF = (2*RF_bin - 1) .* exp(-1i * 2 * pi * f_c * t_RF);

        % 第二步：抗混叠滤波 + 抽取 16 Gsps→1 Gsps（Chebyshev Type I IIR, 8阶）
        rx_BB_filt1 = filter(b_cheby, a_cheby, rx_BB_RF);
        rx_IF1 = rx_BB_filt1(1:decim_factor1:end);

        % 第三步：抗混叠滤波 + 抽取 1 Gsps→250 Msps（FIR, 通带75/阻带100 MHz）
        rx_IF1_filt = filter(fir_coeff, 1, rx_IF1);
        rx_IF_sym = rx_IF1_filt(1:decim_factor2:end);

        % 第四步：RRC匹配滤波 + 下采样到符号率
        % RRC滤波器群延迟 = (length-1)/2 个样点（对称FIR）
        rx_INFO_filt = conv(rx_IF_sym, rcos_filt_rx);
        group_delay = (length(rcos_filt_rx) - 1) / 2;
        valid_start = group_delay + 1;
        valid_end   = length(rx_INFO_filt) - group_delay;
        rx_INFO_sym = downsample(rx_INFO_filt(valid_start:valid_end), rx_interp_factor);

        % 截断至参考符号长度
        min_len = min(length(rx_INFO_sym), length(INFO_sym));
        rx_INFO_sym = rx_INFO_sym(1:min_len);
        ref_sym = INFO_sym(1:min_len);

        % 功率归一化
        power_rx = sum(abs(rx_INFO_sym).^2);
        power_tx = sum(abs(ref_sym).^2);
        rx_INFO_sym_norm = rx_INFO_sym .* sqrt(power_tx / power_rx);

        % EVM 计算
        mEVM = abs(conj(ref_sym).' - rx_INFO_sym_norm) ./ abs(ref_sym.') * 100;
        rms_EVM_cfg(fc_idx) = sqrt(sum(mEVM.^2) / length(mEVM));

        % SNR 计算（论文公式25）: SNR(dB) = -5.8 - 20*log10(EVM(%)/100)
        % 系数5.8为16QAM的PAPR（dB）
        rms_SNR_cfg(fc_idx) = -5.8 - 20 * log10(0.01 * rms_EVM_cfg(fc_idx));
    end

    rms_EVM_all(cfg_idx, :) = rms_EVM_cfg;
    rms_SNR_all(cfg_idx, :) = rms_SNR_cfg;

    fprintf('  EVM range: %.2f%% ~ %.2f%%\n', min(rms_EVM_cfg), max(rms_EVM_cfg));
    fprintf('  SNR range: %.2f ~ %.2f dB\n',  min(rms_SNR_cfg), max(rms_SNR_cfg));
end

% Cleanup parallel pool
delete(gcp('nocreate'));

% ========== 绘图（对应论文图6各子图）==========
fc_GHz = fc_values / 1e9;

% ----- 图6a等价：5 MBaud, 无SA, lm=2 vs lm=3 -----
figure('Name', 'Fig.6a - SNR vs fc (5MBaud, no SA)', 'NumberTitle', 'off');
plot(fc_GHz, rms_SNR_all(1, :), '-o', 'LineWidth', 1.5, 'DisplayName', 'VbPWM N=64, lm=2');
hold on;
plot(fc_GHz, rms_SNR_all(2, :), '-s', 'LineWidth', 1.5, 'DisplayName', 'VbPWM N=64, lm=3');
xlabel('Carrier Frequency (GHz)');
ylabel('In-Band SNR (dB)');
title('In-Band SNR vs Carrier Frequency (5 MBaud, no SA)');
legend('Location', 'best');
grid on;

% ----- 图6b等价：5 MBaud, lm=2, 无SA vs 有SA -----
figure('Name', 'Fig.6b - SNR vs fc (5MBaud, SA comparison)', 'NumberTitle', 'off');
plot(fc_GHz, rms_SNR_all(1, :), '-o',  'LineWidth', 1.5, 'DisplayName', 'N=64, lm=2 without SA');
hold on;
plot(fc_GHz, rms_SNR_all(3, :), '-^',  'LineWidth', 1.5, 'DisplayName', 'N=64, lm=2 with SA');
plot(fc_GHz, rms_SNR_all(2, :), '--s', 'LineWidth', 1.5, 'DisplayName', 'N=64, lm=3 without SA');
plot(fc_GHz, rms_SNR_all(4, :), '--d', 'LineWidth', 1.5, 'DisplayName', 'N=64, lm=3 with SA');
xlabel('Carrier Frequency (GHz)');
ylabel('In-Band SNR (dB)');
title('In-Band SNR vs Carrier Frequency - SA Comparison (5 MBaud)');
legend('Location', 'best');
grid on;

% ----- 图6c等价：25 MBaud, 有SA, lm=2 vs lm=3 -----
figure('Name', 'Fig.6c - SNR vs fc (25MBaud, with SA)', 'NumberTitle', 'off');
plot(fc_GHz, rms_SNR_all(7, :), '-o', 'LineWidth', 1.5, 'DisplayName', 'VbPWM N=64, lm=2, with SA');
hold on;
plot(fc_GHz, rms_SNR_all(8, :), '-s', 'LineWidth', 1.5, 'DisplayName', 'VbPWM N=64, lm=3, with SA');
plot(fc_GHz, rms_SNR_all(5, :), '--o','LineWidth', 1.5, 'DisplayName', 'VbPWM N=64, lm=2, no SA');
plot(fc_GHz, rms_SNR_all(6, :), '--s','LineWidth', 1.5, 'DisplayName', 'VbPWM N=64, lm=3, no SA');
xlabel('Carrier Frequency (GHz)');
ylabel('In-Band SNR (dB)');
title('In-Band SNR vs Carrier Frequency (25 MBaud)');
legend('Location', 'best');
grid on;

% ----- 图6d等价：EVM vs fc, 64QAM -----
figure('Name', 'Fig.6d - EVM vs fc (64QAM)', 'NumberTitle', 'off');
plot(fc_GHz, rms_EVM_all(9, :), '-o', 'LineWidth', 1.5, 'DisplayName', '64QAM for VbPWM (lm=2, with SA)');
hold on;
plot(fc_GHz, rms_EVM_all(3, :), '-s', 'LineWidth', 1.5, 'DisplayName', '16QAM for VbPWM (lm=2, with SA)');
xlabel('Carrier Frequency (GHz)');
ylabel('EVM (%)');
title('EVM vs Carrier Frequency (64QAM vs 16QAM)');
legend('Location', 'best');
grid on;

% ========== 打印汇总结果 ==========
fprintf('\n\n==================== Simulation Summary ====================\n');
fprintf('%-48s  EVM(avg)  EVM(max)  SNR(avg)  SNR(min)\n', 'Configuration');
fprintf('%s\n', repmat('-', 1, 95));
for cfg_idx = 1:num_configs
    fprintf('%-48s  %6.2f%%  %6.2f%%  %7.2fdB  %7.2fdB\n', ...
        configs{cfg_idx, 5}, ...
        mean(rms_EVM_all(cfg_idx, :)), ...
        max(rms_EVM_all(cfg_idx, :)), ...
        mean(rms_SNR_all(cfg_idx, :)), ...
        min(rms_SNR_all(cfg_idx, :)));
end
fprintf('=============================================================\n');

% ┌─────────────────────────────────────────────────────────────────────┐
% │                         发射端处理                                   │
% ├─────────────────────────────────────────────────────────────────────┤
% │  随机比特 → 16/64-QAM调制 → 上采样 → RRC滤波 → 归一化               │
% │     │           │            │          │           │               │
% │     ▼           ▼            ▼          ▼           ▼               │
% │  INFO_bit → INFO_sym → upsample → conv() → IF_sym_norm              │
% │                                                                     │
% │  5 MBaud:  上采样因子 = f_IF / f_BB = 250 Msps / 5 Msps  = 50      │
% │  25 MBaud: 上采样因子 = f_IF / f_BB = 250 Msps / 25 Msps = 10      │
% │                                                                     │
% ├─────────────────────────────────────────────────────────────────────┤
% │                         VbPWM 编码                                   │
% ├─────────────────────────────────────────────────────────────────────┤
% │  载波: IF_sym_phaseCorr = IF_sym_norm * e^(-j*2π*f_c*t)             │
% │  每个IF样点: s → VbMbPWM(s, N=64, f_c, f_s, lm, use_sa) → 64位序列  │
% │                                                                     │
% ├─────────────────────────────────────────────────────────────────────┤
% │                    接收端处理（论文 Section III-B2）                  │
% ├─────────────────────────────────────────────────────────────────────┤
% │  1. 下变频: (2*RF_bin - 1) * e^(-j*2π*f_c*t) @ 16 Gbps             │
% │  2. 第一级抽取: 16 Gsps→1 Gsps，8阶Chebyshev Type I IIR             │
% │  3. 第二级抽取: 1 Gsps→250 Msps，FIR（通带75/阻带100 MHz）           │
% │  4. RRC匹配滤波（基于250 Msps输出率设计）                             │
% │  5. 下采样至符号率（50x for 5 MBaud, 10x for 25 MBaud）              │
% │  6. 功率归一化 + EVM/SNR计算                                         │
% └─────────────────────────────────────────────────────────────────────┘