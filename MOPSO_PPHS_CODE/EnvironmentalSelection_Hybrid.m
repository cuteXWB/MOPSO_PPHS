function [Population] = EnvironmentalSelection_Hybrid(Population, N)
% Stage 4: 混合环境选择
% 1. 优先保留非支配层级靠前的 (Rank)
% 2. 在临界层 (Last Front)，分别保留 特征数最少(Obj1) 和 错误率最低(Obj2) 的解

    %% 1. 预处理 (去重)
    [~, uni] = unique(Population.objs, 'rows');
    Population = Population(uni);
    if length(Population) <= N
        return;
    end

    %% 2. 非支配排序
    [FrontNo, MaxFNo] = NDSort(Population.objs, Population.cons, N);
    
    % 肯定能进 Archive 的层级
    Next = FrontNo < MaxFNo;
    
    %% 3. 临界层筛选 (关键逻辑)
    % 还需要选多少个
    K = N - sum(Next);
    
    if K > 0
        LastFrontIdx = find(FrontNo == MaxFNo);
        LastPop = Population(LastFrontIdx);
        LastObjs = LastPop.objs;
        
        % 策略：特征数(Obj1) 和 错误率(Obj2) 各占 50%
        % 例如需要选 K 个：
        % K1 = ceil(K/2) 个选 Obj1 最小的
        % K2 = K - K1    个选 Obj2 最小的
        
        NumObj1 = ceil(K / 2);
        NumObj2 = K - NumObj1;
        
        SelectedInLast = false(1, length(LastPop));
        
        % --- 选特征数最少的 ---
        [~, SortObj1] = sort(LastObjs(:, 1), 'ascend');
        Idx1 = SortObj1(1 : min(end, NumObj1));
        SelectedInLast(Idx1) = true;
        
        % --- 选错误率最低的 (排除已被选的) ---
        RemainingIdx = find(~SelectedInLast);
        if NumObj2 > 0 && ~isempty(RemainingIdx)
            [~, SortObj2] = sort(LastObjs(RemainingIdx, 2), 'ascend');
            % 映射回 LastPop 的索引
            Idx2 = RemainingIdx(SortObj2(1 : min(end, NumObj2)));
            SelectedInLast(Idx2) = true;
        end
        
        % 将选中的加入 Next
        Next(LastFrontIdx(SelectedInLast)) = true;
    end
    
    Population = Population(Next);
end