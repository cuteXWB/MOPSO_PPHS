%% MATLAB脚本: 计算HV平均排名并保留统计行
% 说明: 读取CSV，计算平均排名，并将排名的结果与 '+/-/=' 统计值一起保存。

clear; clc;

% 1. 设置文件路径
filename = 'HV.xlsx - HV.csv';
outputFilename = 'AverageRanks_WithStats.csv';

% 2. 读取数据
opts = detectImportOptions(filename);
opts.VariableNamingRule = 'preserve';
opts.VariableTypes = repmat({'string'}, 1, length(opts.VariableNames)); % 全部作为字符串读取以处理 '+/-'
T = readtable(filename, opts);

% 3. 数据预处理
% 假设前3列是 Problem, M, D，算法数据从第4列开始
algoStartCol = 4;
algoNames = T.Properties.VariableNames(algoStartCol:end);
numAlgos = length(algoNames);

% 寻找统计行 (通常是包含 '+/-' 或 '=' 的行)
% 我们假设它在最后一行，或者通过第一列的标识来找
statsRowIdx = [];
if contains(T{end, 1}, '+/') || contains(T{end, 1}, '=')
    statsRowIdx = height(T);
elseif contains(T{end, 1}, 'Check') % 有些文件可能标记为 Check
    statsRowIdx = height(T);
end

% 提取统计数据
if ~isempty(statsRowIdx)
    % 获取该行的算法列数据
    statsValues = T{statsRowIdx, algoStartCol:end}';
    % 从用于计算排名的表格中移除该行
    T_calc = T;
    T_calc(statsRowIdx, :) = [];
else
    % 如果没找到，用空字符串代替
    statsValues = repmat("-", numAlgos, 1);
    T_calc = T;
end

% 4. 提取数值并计算排名
numProblems = height(T_calc);
dataMatrix = zeros(numProblems, numAlgos);

for i = 1:numProblems
    for j = 1:numAlgos
        % 获取原始字符串
        rawStr = T_calc{i, j + algoStartCol - 1};
        
        % 提取数值部分: "0.1234 (0.01) -" -> 0.1234
        if ismissing(rawStr)
            val = NaN;
        else
            parts = split(rawStr, '(');
            val = str2double(parts(1));
        end
        dataMatrix(i, j) = val;
    end
end

% 5. 计算排名 (HV越大越好，所以取负值进行升序排名 = 降序)
ranks = zeros(size(dataMatrix));
for i = 1:numProblems
    % tiedrank 处理 NaN 的方式通常是返回 NaN，或者忽略
    % 这里假设所有问题都有数值。如果有NaN，需要特殊处理
    rowVals = dataMatrix(i, :);
    % 对负值排名 -> 值越大，负值越小，排名越靠前(1)
    ranks(i, :) = tiedrank(-rowVals);
end

% 6. 计算平均排名
avgRanks = mean(ranks, 1, 'omitnan')'; % 转置为列向量

% 7. 整合结果
% 结果包含: 算法名, 平均排名, 统计信息
resultsTable = table(algoNames', avgRanks, statsValues, ...
    'VariableNames', {'Algorithm', 'AverageRank', 'Statistics'});

% 按平均排名排序
resultsTable = sortrows(resultsTable, 'AverageRank');

% 8. 显示并写入文件
disp('计算结果 (前5行):');
disp(head(resultsTable, 5));

writetable(resultsTable, outputFilename);
fprintf('结果已保存至: %s\n', outputFilename);