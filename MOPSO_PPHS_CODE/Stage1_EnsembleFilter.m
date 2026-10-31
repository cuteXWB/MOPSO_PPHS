function [ReducedIdx, EnsembleScores] = Stage1_EnsembleFilter(Data, Label, D)
% 集成特征筛选：返回 Top 特征索引 和 所有特征的得分权重
% 包含: ReliefF + Fisher Score + Pearson Correlation

    %% 1. ReliefF
    if exist('relieff', 'file')
        [~, W_Relief] = relieff(Data, Label, 10);
        W_Relief(W_Relief < 0) = 0;
    else
        W_Relief = rand(1, D);
    end

    %% 2. Fisher Score
    W_Fisher = CalculateFisherScore(Data, Label);
    
    %% 3. Pearson Correlation
    W_Pearson = abs(corr(Data, Label));
    W_Pearson(isnan(W_Pearson)) = 0;
    W_Pearson = W_Pearson';
    
    %% 4. 集成与归一化
    % 归一化到 [0, 1]
    Norm = @(x) (x - min(x)) / (max(x) - min(x) + eps);
    EnsembleScores = Norm(W_Relief) + Norm(W_Fisher) + Norm(W_Pearson);
    
    % 返回 Top 20% (用于稀疏初始化参考)
    [~, SortIdx] = sort(EnsembleScores, 'descend');
    Ns = ceil(D * 0.2); 
    ReducedIdx = SortIdx(1:Ns);
end

function W = CalculateFisherScore(X, Y)
    Classes = unique(Y);
    [~, D] = size(X);
    Mu_Total = mean(X, 1);
    Sb = zeros(1, D); Sw = zeros(1, D);
    for i = 1 : length(Classes)
        idx = (Y == Classes(i));
        X_c = X(idx, :);
        n_c = sum(idx);
        if n_c > 0
            Mu_c = mean(X_c, 1);
            Var_c = var(X_c, 0, 1);
            Sb = Sb + n_c * (Mu_c - Mu_Total).^2;
            Sw = Sw + n_c * Var_c;
        end
    end
    W = Sb ./ (Sw + eps);
    W(isnan(W)) = 0;
end