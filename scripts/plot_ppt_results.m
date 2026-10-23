%% 生成 PPT 用实验结果图
% 变量：
% out.r_log
% out.beta_log
% out.mz_compare_log = [PC端已匹配Mz, STM32端Mz]
% out.mz_error_log
% out.valid_log

close all; clc;

%% 1. 读取数据
[tR, r]       = readLog(out.r_log,          'out.r_log');
[tBeta, beta] = readLog(out.beta_log,       'out.beta_log');
[tMz, mzData] = readLog(out.mz_compare_log, 'out.mz_compare_log');
[tErr, mzErr] = readLog(out.mz_error_log,   'out.mz_error_log');
[tValid, valid] = readLog(out.valid_log,    'out.valid_log');

if size(mzData,2) < 2
    error('mz_compare_log 必须由两输入 Mux 组成：[matched_local, match_mz]。');
end

mzPC  = mzData(:,1);     % PC 端已匹配的 Mz
mzSTM = mzData(:,2);     % STM32 端返回的 Mz
mzErr = mzErr(:,1);

% 只保留 valid=1 的匹配样本
validOnMz  = alignValid(tValid, valid, tMz);
validOnErr = alignValid(tValid, valid, tErr);

tMz    = tMz(validOnMz);
mzPC   = mzPC(validOnMz);
mzSTM  = mzSTM(validOnMz);

tErr   = tErr(validOnErr);
mzErr  = mzErr(validOnErr);

% 指标
coverage = 100 * mean(valid(:) ~= 0);
maxErr   = max(abs(mzErr));
rmseErr  = sqrt(mean(mzErr.^2));

% 输出文件夹
outDir = fullfile(pwd, 'PPT_Results');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

%% 2. 左图：PC 与 STM32 的 Mz 对比及误差
blue   = [0.00 0.45 0.74];
orange = [0.85 0.33 0.10];
green  = [0.12 0.55 0.28];
purple = [0.49 0.18 0.70];
red    = [0.88 0.22 0.07];
gridC  = [0.80 0.80 0.80];

f1 = figure('Color','w','Position',[100 100 1100 760]);
tl1 = tiledlayout(f1,2,1,'TileSpacing','compact','Padding','compact');

% (a) Mz 对比
ax1 = nexttile;
p1 = plot(tMz, mzPC, '-', 'Color',blue, 'LineWidth',1.35); hold on
p2 = plot(tMz, mzSTM, '--', 'Color',orange, 'LineWidth',1.35);

% 用少量圆点突出 STM32 实机采样点
step = max(1, round(numel(tMz)/45));
plot(tMz(1:step:end), mzSTM(1:step:end), 'o', ...
    'Color',orange, 'MarkerSize',4, 'LineWidth',1.0);

grid on; box on
title('(a) PC仿真与STM32实机输出（同序号对齐）', ...
    'FontWeight','normal')
ylabel('附加横摆力矩 M_z (N·m)')
legend([p1,p2], {'PC仿真','STM32实机'}, ...
    'Location','northeast','Box','off')

% (b) 误差
ax2 = nexttile;
plot(tErr, mzErr*1e3, '-', 'Color',green, 'LineWidth',1.15); hold on
yline(0,'--','Color',[0.25 0.25 0.25],'LineWidth',0.8);

grid on; box on
title('(b) PC与STM32同序号计算误差', 'FontWeight','normal')
xlabel('时间 t (s)')
ylabel('Mz误差 (mN·m)')

infoText = sprintf(['N = %d，max|e| = %.4g N·m，RMSE = %.4g N·m，' ...
    '接收覆盖率 = %.1f%%'], numel(mzErr), maxErr, rmseErr, coverage);

text(ax2, 0.03, 0.90, infoText, 'Units','normalized', ...
    'FontSize',11, 'BackgroundColor','w', ...
    'EdgeColor',[0.75 0.75 0.75], 'Margin',5);

set([ax1,ax2], 'FontName','Microsoft YaHei', ...
    'FontSize',13, 'LineWidth',1.0, ...
    'GridColor',gridC, 'GridAlpha',0.65, ...
    'XLim',[min(tMz), max(tMz)]);

exportgraphics(f1, fullfile(outDir,'Mz_PC_STM32_对比.png'), ...
    'Resolution',300);

%% 3. 右图：r 与 beta 响应
f2 = figure('Color','w','Position',[160 120 1100 760]);
tl2 = tiledlayout(f2,2,1,'TileSpacing','compact','Padding','compact');

% (a) 横摆角速度 r
ax3 = nexttile;
p3 = plot(tR, r, '-', 'Color',purple, 'LineWidth',1.45);
grid on; box on
title('(a) ESP介入下横摆角速度响应', 'FontWeight','normal')
ylabel('r (rad/s)')
legend(p3, {'横摆角速度 r'}, 'Location','northeast','Box','off')

% (b) 质心侧偏角 beta
ax4 = nexttile;
p4 = plot(tBeta, beta, '-', 'Color',red, 'LineWidth',1.45);
grid on; box on
title('(b) ESP介入下质心侧偏角响应', 'FontWeight','normal')
xlabel('时间 t (s)')
ylabel('\beta (rad)')
legend(p4, {'质心侧偏角 \beta'}, ...
    'Location','northeast','Box','off')

set([ax3,ax4], 'FontName','Microsoft YaHei', ...
    'FontSize',13, 'LineWidth',1.0, ...
    'GridColor',gridC, 'GridAlpha',0.65);

exportgraphics(f2, fullfile(outDir,'r_beta_响应.png'), ...
    'Resolution',300);

fprintf('图片已生成：\n%s\n', outDir);

%% ===== 本文件用到的本地函数 =====
function [t, y] = readLog(sig, signalName)
    if isa(sig, 'timeseries')
        t = sig.Time(:);
        y = squeeze(sig.Data);
    elseif isstruct(sig) && isfield(sig,'time') && isfield(sig,'signals')
        % 兼容 Structure With Time 格式
        t = sig.time(:);
        y = squeeze(sig.signals.values);
    else
        error('%s 不是 Timeseries 或 Structure With Time 数据。', signalName);
    end

    if isvector(y)
        y = y(:);
    end
end

function validMask = alignValid(tValid, valid, tTarget)
    valid = double(valid(:) ~= 0);
    [tValid, idx] = unique(tValid(:), 'stable');
    valid = valid(idx);

    validAtTarget = interp1(tValid, valid, tTarget(:), ...
        'nearest', 'extrap');

    validMask = validAtTarget >= 0.5;
end