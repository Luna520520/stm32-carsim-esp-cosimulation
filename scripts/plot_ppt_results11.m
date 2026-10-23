%% =========================================================
%  PC–STM32 控制器对比结果绘图（PPT 白底版）
%
%  使用变量：
%  out.r_log
%  out.beta_log
%  out.mz_compare_log   % 两列：[matched_local, match_mz]
%  out.mz_error_log
%  out.valid_log
%
%  输出：
%  PPT_Results\Mz_PC_STM32_对比.png
%  PPT_Results\r_beta_响应.png
%% =========================================================

close all;
clc;

%% 1. 读取 To Workspace 数据
[tR, r] = readSignal(out.r_log, 'out.r_log');
[tBeta, beta] = readSignal(out.beta_log, 'out.beta_log');
[tMz, mzData] = readSignal(out.mz_compare_log, 'out.mz_compare_log');
[tErr, mzErr] = readSignal(out.mz_error_log, 'out.mz_error_log');
[tValid, validRaw] = readSignal(out.valid_log, 'out.valid_log');

% 确保 Mz 对比数据包含两列
if size(mzData, 2) < 2
    error(['out.mz_compare_log 必须由两输入 Mux 组成，' ...
           '数据顺序应为：[matched_local, match_mz]。']);
end

% 两列 Mz 的含义
mzPC  = mzData(:, 1);        % PC 端已匹配的 Mz
mzSTM = mzData(:, 2);        % STM32 端返回的 Mz
mzErr = mzErr(:, 1);         % Match Mz by sequence 的 error 输出
validRaw = validRaw(:, 1);   % valid 输出

%% 2. 仅保留成功匹配的样本
validOnMz = alignValid(tValid, validRaw, tMz);
validOnErr = alignValid(tValid, validRaw, tErr);

tMz = tMz(validOnMz);
mzPC = mzPC(validOnMz);
mzSTM = mzSTM(validOnMz);

tErr = tErr(validOnErr);
mzErr = mzErr(validOnErr);

if isempty(tMz) || isempty(tErr)
    error('没有有效匹配样本。请检查 valid_log 和 Mz 序号匹配模块。');
end

%% 3. 计算误差指标
sampleCount = numel(mzErr);
maxErr = max(abs(mzErr));
rmseErr = sqrt(mean(mzErr.^2));
coverage = 100 * mean(validRaw ~= 0);

%% 4. 输出文件夹
resultDir = fullfile(pwd, 'PPT_Results');
if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end

%% 5. 统一颜色与字体
cPC = [0.00 0.45 0.74];       % 蓝：PC 仿真
cSTM = [0.85 0.33 0.10];      % 橙：STM32
cErr = [0.10 0.55 0.28];      % 绿：误差
cR = [0.49 0.18 0.70];        % 紫：r
cBeta = [0.88 0.22 0.07];     % 红：beta
fontName = 'Microsoft YaHei';

%% =========================================================
%  图 1：PC 与 STM32 的 Mz 对比 + 误差
%% =========================================================
f1 = figure( ...
    'Color', 'w', ...
    'Position', [100, 100, 1200, 820], ...
    'Renderer', 'painters');

tiledlayout(f1, 2, 1, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');

% -------- (a) Mz 对比 --------
ax1 = nexttile;

pPC = plot(tMz, mzPC, '-', ...
    'Color', cPC, ...
    'LineWidth', 1.45);
hold on;

pSTM = plot(tMz, mzSTM, '--', ...
    'Color', cSTM, ...
    'LineWidth', 1.40);

% 少量标记点，突出 STM32 实机离散采样
markerStep = max(1, round(numel(tMz)/45));
plot(tMz(1:markerStep:end), mzSTM(1:markerStep:end), 'o', ...
    'Color', cSTM, ...
    'MarkerFaceColor', 'w', ...
    'MarkerSize', 4.5, ...
    'LineWidth', 1.0);

title('(a) PC仿真与STM32实机输出（同序号对齐）', ...
    'FontWeight', 'normal');
ylabel('附加横摆力矩 M_z (N·m)');
legend([pPC, pSTM], {'PC仿真', 'STM32实机'}, ...
    'Location', 'northeast', ...
    'Box', 'off');

formatAxes(ax1, fontName);
xlim(ax1, [min(tMz), max(tMz)]);

% -------- (b) Mz 误差 --------
ax2 = nexttile;

plot(tErr, mzErr * 1e3, '-', ...
    'Color', cErr, ...
    'LineWidth', 1.20);
hold on;

yline(0, '--', ...
    'Color', [0.20, 0.20, 0.20], ...
    'LineWidth', 0.90);

title('(b) PC与STM32同序号计算误差', ...
    'FontWeight', 'normal');
xlabel('时间 t (s)');
ylabel('Mz误差 (mN·m)');

formatAxes(ax2, fontName);
xlim(ax2, [min(tErr), max(tErr)]);

statText = sprintf([ ...
    'N = %d，max|e| = %.4g N·m，RMSE = %.4g N·m，接收覆盖率 = %.1f%%'], ...
    sampleCount, maxErr, rmseErr, coverage);

text(ax2, 0.03, 0.90, statText, ...
    'Units', 'normalized', ...
    'FontName', fontName, ...
    'FontSize', 11, ...
    'Color', 'k', ...
    'BackgroundColor', 'w', ...
    'EdgeColor', [0.72, 0.72, 0.72], ...
    'Margin', 6);

exportgraphics(f1, ...
    fullfile(resultDir, 'Mz_PC_STM32_对比.png'), ...
    'Resolution', 300, ...
    'BackgroundColor', 'white');

%% =========================================================
%  图 2：横摆角速度 r 与质心侧偏角 beta
%% =========================================================
f2 = figure( ...
    'Color', 'w', ...
    'Position', [150, 120, 1200, 820], ...
    'Renderer', 'painters');

tiledlayout(f2, 2, 1, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');

% -------- (a) 横摆角速度 r --------
ax3 = nexttile;

pR = plot(tR, r, '-', ...
    'Color', cR, ...
    'LineWidth', 1.50);

title('(a) ESP介入下横摆角速度响应', ...
    'FontWeight', 'normal');
ylabel('r (rad/s)');
legend(pR, {'横摆角速度 r'}, ...
    'Location', 'northeast', ...
    'Box', 'off');

formatAxes(ax3, fontName);
xlim(ax3, [min(tR), max(tR)]);

% -------- (b) 质心侧偏角 beta --------
ax4 = nexttile;

pBeta = plot(tBeta, beta, '-', ...
    'Color', cBeta, ...
    'LineWidth', 1.50);

title('(b) ESP介入下质心侧偏角响应', ...
    'FontWeight', 'normal');
xlabel('时间 t (s)');
ylabel('\beta (rad)');
legend(pBeta, {'质心侧偏角 \beta'}, ...
    'Location', 'northeast', ...
    'Box', 'off');

formatAxes(ax4, fontName);
xlim(ax4, [min(tBeta), max(tBeta)]);

exportgraphics(f2, ...
    fullfile(resultDir, 'r_beta_响应.png'), ...
    'Resolution', 300, ...
    'BackgroundColor', 'white');

%% 6. 输出提示
fprintf('\n绘图完成。\n');
fprintf('结果图片保存位置：\n%s\n\n', resultDir);

%% =========================================================
%  本地函数
%% =========================================================

function [t, y] = readSignal(sig, signalName)
    % 兼容 To Workspace 的 Timeseries 与 Structure With Time

    if isa(sig, 'timeseries')
        t = sig.Time(:);
        y = squeeze(sig.Data);

    elseif isstruct(sig) && isfield(sig, 'time') && isfield(sig, 'signals')
        t = sig.time(:);
        y = squeeze(sig.signals.values);

    else
        error('%s 不是可识别的 Timeseries 数据。', signalName);
    end

    if isvector(y)
        y = y(:);
    end
end

function validMask = alignValid(tValid, valid, tTarget)
    % 将 valid 信号按最近时刻映射至待筛选数据的时间轴

    tValid = tValid(:);
    valid = double(valid(:) ~= 0);

    [tValid, index] = unique(tValid, 'stable');
    valid = valid(index);

    validAtTarget = interp1(tValid, valid, tTarget(:), ...
        'nearest', 'extrap');

    validMask = validAtTarget >= 0.5;
end

function formatAxes(ax, fontName)
    % 白底、黑字、浅灰网格：适用于当前蓝白 PPT

    grid(ax, 'on');
    box(ax, 'on');

    set(ax, ...
        'Color', 'w', ...
        'XColor', 'k', ...
        'YColor', 'k', ...
        'FontName', fontName, ...
        'FontSize', 13, ...
        'LineWidth', 1.0, ...
        'GridColor', [0.72, 0.72, 0.72], ...
        'GridAlpha', 0.58);

    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';
end