function Wp = CalculateParetoWeights(Population, D)
% 复现 TSEA/DFW 中的 "Pareto-based hierarchical feature weighting"
% 基于非支配排序层级给予特征权重

    % 1. 非支配排序
    [FrontNo, ~] = NDSort(Population.objs, Population.cons, inf);
    MaxFront = max(FrontNo);
    
    Wp = zeros(1, D);
    PopDec = double(Population.decs); % 转换为 double 方便计算
    
    % 衰减参数 alpha (论文设定为 0.5) [cite: 281, 416]
    alpha = 0.5; 
    
    % 2. 分层累加
    for i = 1 : MaxFront
        % 获取第 i 层的解
        CurrentLevelIdx = (FrontNo == i);
        CurrentLevelPop = PopDec(CurrentLevelIdx, :);
        NumSols = size(CurrentLevelPop, 1);
        
        if NumSols > 0
            % 层级权重 omega [cite: 281]
            omega_i = exp(-alpha * (i - 1));
            
            % 该层内特征出现的频率 [cite: 337]
            phi_i = sum(CurrentLevelPop, 1) / NumSols;
            
            % 累加到总权重 [cite: 345]
            Wp = Wp + omega_i * phi_i;
        end
    end
    
    % 3. 归一化 [cite: 348]
    if max(Wp) > 0
        Wp = Wp / max(Wp);
    end
end