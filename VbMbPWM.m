function [out_seq, path_length] = VbMbPWM(s, N, f_c, f_s, lm)

% 
% 输入参数:
%   s    - 复数输入样本（基带信号）
%   N    - 序列长度（输出的比特数）
%   f_c  - 载波频率 (Hz)
%   f_s  - 射频采样率 (Hz)
%   lm   - 维特比算法的记忆长度（通常为2或3）
%
% 输出参数:
%   out_seq     - N比特二进制输出序列
%   path_length - 最终路径长度（复数残差）

    % 节点数量 = 2^lm
    num_nodes = 2^lm;
    
    % 预计算EVec向量: (1/N) * e^(-j*2*pi*f_c*T_RF*n)，其中 n = 0 到 N-1
    T_RF = 1/f_s;
    EVec = exp(-1j * 2 * pi * f_c * T_RF * (0:N-1)) / N;
    
    % 初始化生存路径（每行是一个节点的路径）
    survival_paths = zeros(num_nodes, N);
    
    % 用输入样本y初始化所有节点的路径长度
    path_lengths = complex(zeros(num_nodes, 1));
    path_lengths(:) = s;
    
    % === Pre-SUB单元：第0次到第lm-1次迭代 ===
    % 根据节点索引初始化前lm位
    for node_idx = 0:num_nodes-1
        for bit_pos = 0:lm-1
            % 节点索引的第bit_pos位
            bit_val = mod(floor(node_idx / 2^bit_pos), 2);
            survival_paths(node_idx+1, bit_pos+1) = bit_val;
        end
    end
    
    % 计算lm次迭代后的初始路径长度（公式27）
    for node_idx = 0:num_nodes-1
        cumulative_contribution = 0;
        for bit_pos = 0:lm-1
            bit_val = survival_paths(node_idx+1, bit_pos+1);
            % p*[n] = 2*p[n] - 1
            bit_contribution = (2 * bit_val - 1) * EVec(bit_pos+1);
            cumulative_contribution = cumulative_contribution + bit_contribution;
        end
        path_lengths(node_idx+1) = s - cumulative_contribution;
    end
% ┌──────────────────────────────────────────────────────┐
% │ 状态转移的本质                                       │
% ├──────────────────────────────────────────────────────┤
% │ 当前状态(lm位) ──新比特──> 下一状态(lm位)            │
% │                                                     │
% │ 操作：右移1位，在最低位插入新比特                    │
% │                                                     │
% │ 当前状态最低lm-1位 → 下一状态最高lm-1位              │
% │                                                     │
% │ 代码操作：                                          │
% │ upper_bits = floor(dest_node/2)                     │
% │ output_bit = mod(dest_node, 2)                      │                                              │
% │ source_a = upper_bits                               │
% │ source_b = upper_bits + 2^(lm-1)                    │
% │           两个源的不同处只在最高位                   │
% └──────────────────────────────────────────────────────┘   
    % === 主维特比迭代：从lm到N-1 ===
    for iter = lm:N-1
        new_survival_paths = zeros(num_nodes, N);
        new_path_lengths = complex(zeros(num_nodes, 1));
        
        for dest_node = 0:num_nodes-1
            % ===== 源节点计算 =====
            %   
            upper_bits = floor(dest_node / 2);  % 目标节点的高(lm-1)位 = 源节点的低(lm-1)位
            
            source_a = upper_bits;               % 源节点A：最高位为0
            source_b = upper_bits + 2^(lm-1);    % 源节点B：最高位为1
            
            % 输出比特 = 目标节点的最低位
            output_bit = mod(dest_node, 2);
            % ================================
            
            % 从源节点复制路径并添加新比特
            path_a = survival_paths(source_a+1, :);
            path_a(iter+1) = output_bit;
            
            path_b = survival_paths(source_b+1, :);
            path_b(iter+1) = output_bit;
            
            % 使用增量更新计算新的路径长度（公式26）
            bit_contribution = (2 * output_bit - 1) * EVec(iter+1);
            len_a = path_lengths(source_a+1) - bit_contribution;
            len_b = path_lengths(source_b+1) - bit_contribution;
            
            % 选择幅度较小的路径（更接近目标y）
            if abs(len_a) <= abs(len_b)
                new_survival_paths(dest_node+1, :) = path_a;
                new_path_lengths(dest_node+1) = len_a;
            else
                new_survival_paths(dest_node+1, :) = path_b;
                new_path_lengths(dest_node+1) = len_b;
            end
        end
        
        % 更新以进行下一次迭代
        survival_paths = new_survival_paths;
        path_lengths = new_path_lengths;
    end
    
    % === 收敛单元 ===
    % 选择路径长度幅度最小的生存路径
    [~, best_node] = min(abs(path_lengths));
    out_seq = survival_paths(best_node, :);
    path_length = path_lengths(best_node);
end