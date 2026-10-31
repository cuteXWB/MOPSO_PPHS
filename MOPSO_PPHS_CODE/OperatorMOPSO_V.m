function [OffDec, NewVelocity] = OperatorMOPSO_V(Population, Pbest, Archive, Velocity, FE, maxFE)
% OperatorMOPSO_V: 标准 V-shape BPSO 算子
% 1. 计算连续速度 V
% 2. 使用 V-shape (tanh) 计算翻转概率
% 3. 执行位置翻转

    [N, D] = size(Population.decs);
    
    % 获取 0/1 矩阵 (逻辑值)
    PopDec = logical(Population.decs);
    PbestDec = logical(Pbest.decs);
    ArchiveDecs = logical(Archive.decs);
    
    %% 1. 选择全局引导者 (Leader)
    % 从 Archive 中随机选择 Leader，保持种群多样性
    if isempty(ArchiveDecs)
        GbestDec = PbestDec; % 兜底
    else
        LeaderIdx = randi(size(ArchiveDecs, 1), N, 1);
        GbestDec = ArchiveDecs(LeaderIdx, :);
    end

    %% 2. 速度更新 (Standard BPSO Velocity)
    % 惯性权重线性递减: 0.9 -> 0.4
    w = 0.9 - 0.5 * (FE / maxFE); 
    c1 = 2.0; 
    c2 = 2.0;
    
    R1 = rand(N, D);
    R2 = rand(N, D);
    
    % 标准速度公式: V(t+1) = w*V(t) + c1*r1*(Pbest-X) + c2*r2*(Gbest-X)
    % 注意：虽然 X 是二进制，但在速度公式里视为 0 和 1 的数值进行计算
    NewVelocity = w * Velocity + ...
                  c1 * R1 .* (double(PbestDec) - double(PopDec)) + ...
                  c2 * R2 .* (double(GbestDec) - double(PopDec));
    
    % 速度截断 [-6, 6] (防止 tanh 永远饱和)
    Vmax = 6.0;
    NewVelocity(NewVelocity > Vmax) = Vmax;
    NewVelocity(NewVelocity < -Vmax) = -Vmax;

    %% 3. V-shape 转换与位置更新
    % V-shape (Tanh) Transfer Function
    % 物理意义：速度绝对值越大，粒子"改变状态"的意愿越强
    FlipProb = abs(tanh(NewVelocity));
    
    % 执行翻转 (XOR)
    % 如果 rand < FlipProb，则将当前位取反 (0->1, 1->0)
    DoFlip = rand(N, D) < FlipProb;
    OffDec = xor(PopDec, DoFlip);
    
end