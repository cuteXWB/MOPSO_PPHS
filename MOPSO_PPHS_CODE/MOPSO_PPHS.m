classdef MOPSO_PPHS< ALGORITHM
% <multi> <binary> <large/none> <constrained/none>
% EM-MOPSO-PHW (V-shape Standard Version)
% Stage 1: 集成筛选 (Ensemble Filter)
% Stage 2: 标准 V-shape BPSO 更新
% Stage 3: 双重引导变异 (Dual Guided Mutation)
% Stage 4: 混合环境选择 (Hybrid Selection)

    properties
        Velocity % 显式存储速度，实现惯性记忆
    end

    methods
        function main(Algorithm, Problem)
            %% 0. 数据准备
            TrainX = []; TrainY = [];
            try
                if isprop(Problem, 'TrainIn'), TrainX = Problem.TrainIn; TrainY = Problem.TrainOut;
                elseif isprop(Problem, 'Input'), TrainX = Problem.Input; if isprop(Problem, 'Target'), TrainY = Problem.Target; end
                elseif isprop(Problem, 'Source') && isfield(Problem.Source, 'TrainIn'), TrainX = Problem.Source.TrainIn; TrainY = Problem.Source.TrainOut;
                end
            catch
            end
            
            %% === Stage 1: 集成特征筛选 ===
            ReducedIdx = 1:Problem.D;
            W_Filter = rand(1, Problem.D);
            if ~isempty(TrainX)
                [ReducedIdx, W_Filter] = Stage1_EnsembleFilter(TrainX, TrainY, Problem.D);
                % 归一化 Filter 权重
                W_Filter = (W_Filter - min(W_Filter)) / (max(W_Filter) - min(W_Filter) + eps);
            end

            %% 初始化种群 (稀疏初始化)
            Decs = false(Problem.N, Problem.D);
            % 根据 Filter 权重进行精英初始化 (Top 10%)
            [~, SortF] = sort(W_Filter, 'descend');
            TopFeats = SortF(1:ceil(Problem.D * 0.1));
            
            for i = 1 : Problem.N
                % 混合初始化：一半关注 Top 特征，一半全局随机
                if i <= Problem.N / 2
                    Decs(i, TopFeats(rand(1, length(TopFeats)) < 0.2)) = true;
                else
                    Decs(i, rand(1, Problem.D) < 0.05) = true;
                end
                % 兜底：防止全0
                if sum(Decs(i,:))==0, Decs(i, randi(Problem.D)) = true; end
            end
            
            Population = Problem.Evaluation(Decs);
            
            % [关键] 初始化速度矩阵
            Algorithm.Velocity = zeros(Problem.N, Problem.D);
            
            Archive = EnvironmentalSelection_Hybrid(Population, Problem.N);
            Pbest = Population;
            
            %% === 优化主循环 ===
            while Algorithm.NotTerminated(Archive)
                
                % 1. 计算 Pareto 权重 (用于 Stage 3 引导)
                W_Pareto = CalculateParetoWeights([Population, Archive], Problem.D);
                
                % 2. === Stage 2: 标准 V-shape 更新 ===
                % [修正] 不再进行复杂的二次处理，直接通过速度翻转
                [OffDec, Algorithm.Velocity] = OperatorMOPSO_V(Population, Pbest, Archive, Algorithm.Velocity, Problem.FE, Problem.maxFE);
                
                % 3. === Stage 3: 双重引导变异 ===
                % 仅作为一种“后处理”变异，不干扰 Stage 2 的物理运动
                OffDec = GuidedMutation_Dual(OffDec, W_Filter, W_Pareto);
                
                % 4. 评估与修复
                for i=1:size(OffDec,1)
                    if sum(OffDec(i,:))==0, OffDec(i, randi(Problem.D))=true; end
                end
                Offspring = Problem.Evaluation(OffDec);
                
                % 5. === Stage 4: 环境选择 ===
                Archive = EnvironmentalSelection_Hybrid([Archive, Offspring], Problem.N);
                
                
                Pbest = UpdatePbest(Pbest, Offspring);
                Population = Offspring;
                
            end
        end
    end
end