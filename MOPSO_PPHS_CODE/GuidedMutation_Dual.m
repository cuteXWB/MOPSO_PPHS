function OffDec = GuidedMutation_Dual(OffDec, W_Filter, W_Pareto)
% Stage 3: 基于双重权重的引导变异
% W_Filter: 静态的，来自数据 (先验)
% W_Pareto: 动态的，来自演化分层 (后验)

    [N, D] = size(OffDec);
    
    % 融合权重 (0.3 先验 + 0.7 后验，随着迭代可以调整，这里固定)
    % 目的：让 Pareto 权重占主导，Filter 权重做底色
    W_Total = 0.3 * W_Filter + 0.7 * W_Pareto;
    
    % 归一化总权重
    W_Total = (W_Total - min(W_Total)) / (max(W_Total) - min(W_Total) + eps);
    
    % 变异率 (稀疏变异)
    MutaRate = 1 / D;
    
    for i = 1 : N
        if rand < 0.5 % 并不是所有个体都变异
            continue;
        end
        
        % 随机选择变异位
        MutaMask = rand(1, D) < MutaRate;
        Idx = find(MutaMask);
        
        for j = Idx
            % 双重引导逻辑:
            % 如果当前是 0，且权重很高 -> 极大概率变为 1 (Add)
            % 如果当前是 1，且权重很低 -> 极大概率变为 0 (Remove)
            
            p_inject = W_Total(j); % 权重越高，越该是 1
            
            if OffDec(i, j) == 0
                % 当前为0 (没选)，根据权重决定是否开启
                % 权重越高，开启概率越大
                if rand < p_inject
                    OffDec(i, j) = 1;
                end
            else
                % 当前为1 (选中)，根据权重决定是否保留
                % 权重越低 (p_inject小)，保留概率越小 -> 关闭概率大
                if rand > p_inject 
                    OffDec(i, j) = 0;
                end
            end
        end
    end
end