function [V, V_dot] = Analytical_Lyapunov_Observer(beta, r, delta, Mz)
    % 1. 统一的车辆参数 
    m = 1750; Iz = 3000; a = 1.25; b = 1.45; vx = 30;
    kf = 65000; kr = 45000; mu = 0.8; g = 9.8;
    
    % 2. 内部重构轮胎受力
    Fzf = m * g * b / (a + b);
    Fzr = m * g * a / (a + b);
    Fmax_f = mu * Fzf;
    Fmax_r = mu * Fzr;
    
    alpha_f = delta - beta - a * r / vx;
    alpha_r = -beta + b * r / vx;
    
    Fyf = Fmax_f * tanh(kf * alpha_f / Fmax_f);
    Fyr = Fmax_r * tanh(kr * alpha_r / Fmax_r);
    
    % 3. 利用动力学解析方程计算导数
    beta_dot = (Fyf + Fyr) / (m * vx) - r;
    r_dot = (a * Fyf - b * Fyr + Mz) / Iz;
    
    % 4. 计算并输出李雅普诺夫函数值及导数值
    V = m * vx * beta^2 + Iz * r^2;
    V_dot = 2 * m * vx * beta * beta_dot + 2 * Iz * r * r_dot;
    
end