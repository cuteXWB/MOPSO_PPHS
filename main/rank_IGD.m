%% rank_IGD.m
% IGD: smaller is better
% 功能：自动读取首个工作表，提取每个算法单元格中括号前的 mean 值，
%       计算每个数据集上的排名，并输出 ParsedMean / Ranks / AverageRank。
% 说明：算法列数、数据集行数可以变化；脚本会根据表头和可解析数值自动识别算法列。

clear; clc;

metricName = 'IGD';
higherIsBetter = false;
defaultFileName = 'IGD.xlsx';

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

inputFile = fullfile(scriptDir, defaultFileName);
if ~isfile(inputFile)
    inputFile = fullfile(pwd, defaultFileName);
end

if ~isfile(inputFile)
    [fileName, filePath] = uigetfile({'*.xlsx;*.xls', 'Excel Files (*.xlsx, *.xls)'}, ...
        ['Select ', metricName, ' result table']);
    if isequal(fileName, 0)
        error('No input file selected.');
    end
    inputFile = fullfile(filePath, fileName);
end

[inputPath, inputBase, ~] = fileparts(inputFile);
if isempty(inputPath)
    inputPath = pwd;
end
outputFile = fullfile(inputPath, [inputBase, '_rank_result.xlsx']);

raw = readcell(inputFile, 'Sheet', 1);
raw = remove_empty_rows_cols(raw);

[headers, dataRaw] = split_header_and_data(raw);
[algCols, algNames] = detect_algorithm_columns(headers, dataRaw);

if isempty(algCols)
    error('No algorithm columns were detected. Please check the header row and data format.');
end

[dataRows, datasetNames] = detect_dataset_rows(dataRaw, algCols);
if isempty(dataRows)
    error('No valid dataset rows were detected. Please check the table format.');
end

dataRaw = dataRaw(dataRows, :);

metaCols = 1:(min(algCols) - 1);
if isempty(metaCols)
    metaCols = 1;
end
metaHeaders = headers(metaCols);
metaData = dataRaw(:, metaCols);

meanValues = nan(numel(dataRows), numel(algCols));
for i = 1:numel(dataRows)
    for j = 1:numel(algCols)
        meanValues(i, j) = extract_first_number(dataRaw{i, algCols(j)});
    end
end

ranks = rank_metric_matrix(meanValues, higherIsBetter);
avgRank = nan(1, size(ranks, 2));
for j = 1:size(ranks, 2)
    validRank = ranks(~isnan(ranks(:, j)), j);
    if ~isempty(validRank)
        avgRank(j) = mean(validRank);
    end
end

[sortedAvgRank, order] = sort(avgRank, 'ascend');
algHeader = reshape(cellstr(algNames), 1, []);

meanSheet = [metaHeaders, algHeader; metaData, num2cell(meanValues)];
rankSheet = [metaHeaders, algHeader; metaData, num2cell(ranks)];
summarySheet = [{'Algorithm', 'AverageRank'}; reshape(algHeader(order), [], 1), num2cell(sortedAvgRank(:))];
settingsSheet = {
    'Metric', metricName;
    'Rule', rule_description(higherIsBetter);
    'InputFile', inputFile;
    'OutputFile', outputFile;
    'DatasetRowsUsed', numel(dataRows);
    'AlgorithmColumnsUsed', numel(algCols);
    'GeneratedAt', char(datetime('now'))
};

if isfile(outputFile)
    delete(outputFile);
end

writecell(meanSheet, outputFile, 'Sheet', 'ParsedMean');
writecell(rankSheet, outputFile, 'Sheet', 'Ranks');
writecell(summarySheet, outputFile, 'Sheet', 'AverageRank');
writecell(settingsSheet, outputFile, 'Sheet', 'Settings');

fprintf('\n%s ranking finished.\n', metricName);
fprintf('Input file:  %s\n', inputFile);
fprintf('Output file: %s\n', outputFile);
fprintf('Datasets used:   %d\n', numel(dataRows));
fprintf('Algorithms used: %d\n\n', numel(algCols));

if any(isnan(meanValues(:)))
    warning('Some metric values could not be parsed and were written as NaN. Please check ParsedMean sheet.');
end

%% Local functions
function raw = remove_empty_rows_cols(raw)
    if isempty(raw)
        error('The input file is empty.');
    end
    emptyMask = false(size(raw));
    for r = 1:size(raw, 1)
        for c = 1:size(raw, 2)
            emptyMask(r, c) = is_empty_cell(raw{r, c});
        end
    end
    raw(all(emptyMask, 2), :) = [];
    raw(:, all(emptyMask, 1)) = [];
end

function [headers, dataRaw] = split_header_and_data(raw)
    headerRow = 1;
    maxCheck = min(10, size(raw, 1));
    for r = 1:maxCheck
        for c = 1:size(raw, 2)
            txt = lower(to_text(raw{r, c}));
            if strcmp(txt, 'problem') || strcmp(txt, 'dataset') || strcmp(txt, 'datasets')
                headerRow = r;
                headers = raw(headerRow, :);
                dataRaw = raw((headerRow + 1):end, :);
                headers = fill_empty_headers(headers);
                return;
            end
        end
    end
    headers = raw(headerRow, :);
    dataRaw = raw((headerRow + 1):end, :);
    headers = fill_empty_headers(headers);
end

function headers = fill_empty_headers(headers)
    for c = 1:numel(headers)
        if is_empty_cell(headers{c})
            headers{c} = ['Column', num2str(c)];
        end
    end
end

function [algCols, algNames] = detect_algorithm_columns(headers, dataRaw)
    nCols = numel(headers);
    algMask = false(1, nCols);

    usableRows = true(size(dataRaw, 1), 1);
    for r = 1:size(dataRaw, 1)
        firstTxt = lower(to_text(dataRaw{r, 1}));
        if strlength(firstTxt) == 0 || is_summary_row(firstTxt)
            usableRows(r) = false;
        end
    end
    totalRows = sum(usableRows);

    for c = 1:nCols
        h = lower(to_text(headers{c}));
        if is_meta_header(h)
            continue;
        end

        validCount = 0;
        for r = 1:size(dataRaw, 1)
            if ~usableRows(r)
                continue;
            end
            if ~isnan(extract_first_number(dataRaw{r, c}))
                validCount = validCount + 1;
            end
        end

        if totalRows > 0 && validCount >= max(1, ceil(0.5 * totalRows))
            algMask(c) = true;
        end
    end

    algCols = find(algMask);

    % Fallback: if automatic detection fails, assume algorithms start after Problem/M/D.
    if isempty(algCols)
        headerText = strings(1, nCols);
        for c = 1:nCols
            headerText(c) = lower(to_text(headers{c}));
        end
        lastMeta = find(ismember(headerText, ["problem", "dataset", "datasets", "m", "d"]), 1, 'last');
        if isempty(lastMeta)
            lastMeta = min(3, nCols);
        end
        algCols = (lastMeta + 1):nCols;
    end

    algNames = strings(1, numel(algCols));
    for j = 1:numel(algCols)
        name = to_text(headers{algCols(j)});
        if strlength(name) == 0
            name = "Alg_" + algCols(j);
        end
        algNames(j) = name;
    end
end

function [dataRows, datasetNames] = detect_dataset_rows(dataRaw, algCols)
    dataRows = [];
    for r = 1:size(dataRaw, 1)
        firstTxt = lower(to_text(dataRaw{r, 1}));
        if strlength(firstTxt) == 0 || is_summary_row(firstTxt)
            continue;
        end

        validCount = 0;
        for j = 1:numel(algCols)
            if ~isnan(extract_first_number(dataRaw{r, algCols(j)}))
                validCount = validCount + 1;
            end
        end

        if validCount >= max(1, ceil(0.5 * numel(algCols)))
            dataRows(end + 1) = r; %#ok<AGROW>
        end
    end

    datasetNames = strings(numel(dataRows), 1);
    for i = 1:numel(dataRows)
        datasetNames(i) = to_text(dataRaw{dataRows(i), 1});
    end
end

function ranks = rank_metric_matrix(values, higherIsBetter)
    [nRows, nAlgs] = size(values);
    ranks = nan(nRows, nAlgs);

    for i = 1:nRows
        rowValues = values(i, :);
        valid = ~isnan(rowValues);
        if ~any(valid)
            continue;
        end

        if higherIsBetter
            score = -rowValues(valid);  % HV: larger value gets smaller rank number.
        else
            score = rowValues(valid);   % IGD/ART/MER: smaller value gets smaller rank number.
        end
        ranks(i, valid) = tied_rank_local(score);
    end
end

function ranks = tied_rank_local(x)
    originalSize = size(x);
    x = x(:);
    ranksColumn = nan(size(x));
    [sortedX, order] = sort(x, 'ascend');
    n = numel(sortedX);
    k = 1;
    tol = 1e-12;

    while k <= n
        e = k;
        while e < n && abs(sortedX(e + 1) - sortedX(k)) <= tol * max(1, max(abs([sortedX(e + 1), sortedX(k)])))
            e = e + 1;
        end
        avgRank = (k + e) / 2;
        ranksColumn(order(k:e)) = avgRank;
        k = e + 1;
    end

    ranks = reshape(ranksColumn, originalSize);
end

function val = extract_first_number(x)
    val = NaN;

    if isempty(x)
        return;
    end

    if isnumeric(x)
        if isscalar(x) && ~isnan(x)
            val = double(x);
        end
        return;
    end

    txt = to_text(x);
    if strlength(txt) == 0
        return;
    end

    token = regexp(char(txt), '[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', 'match', 'once');
    if ~isempty(token)
        val = str2double(token);
    end
end

function txt = to_text(x)
    txt = "";
    if isempty(x)
        return;
    end

    try
        if any(ismissing(x))
            return;
        end
    catch
    end

    if ischar(x)
        txt = string(strtrim(x));
    elseif isstring(x)
        if ismissing(x)
            txt = "";
        else
            txt = strtrim(x);
        end
    elseif isnumeric(x) && isscalar(x)
        if isnan(x)
            txt = "";
        else
            txt = string(x);
        end
    elseif islogical(x) && isscalar(x)
        txt = string(x);
    else
        try
            txt = strtrim(string(x));
        catch
            txt = "";
        end
    end
end

function tf = is_empty_cell(x)
    if isempty(x)
        tf = true;
        return;
    end

    if isnumeric(x) && isscalar(x)
        tf = isnan(x);
        return;
    end

    tf = strlength(to_text(x)) == 0;
end

function tf = is_meta_header(h)
    h = lower(strtrim(h));
    metaHeaders = ["problem", "problems", "dataset", "datasets", "data", ...
                   "m", "d", "dim", "dimension", "feature", "features", ...
                   "sample", "samples", "instance", "instances", ...
                   "class", "classes", "fold", "no", "number"];
    tf = any(strcmp(h, metaHeaders));
end

function tf = is_summary_row(firstTxt)
    firstTxt = lower(strtrim(firstTxt));
    summaryKeys = ["+/-/=", "+/−/=", "average", "avg", "mean rank", ...
                   "average rank", "rank", "ranking", "summary", "win", "loss"];
    tf = false;
    for k = 1:numel(summaryKeys)
        if contains(firstTxt, summaryKeys(k))
            tf = true;
            return;
        end
    end
end

function desc = rule_description(higherIsBetter)
    if higherIsBetter
        desc = 'larger value is better; rank 1 is the largest mean value in each dataset row';
    else
        desc = 'smaller value is better; rank 1 is the smallest mean value in each dataset row';
    end
end
