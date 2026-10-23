function Mz = direct_lyapunov_controller(beta, r, delta)
    % 1. 车辆参数定义 
    m = 1750; Iz = 3000; a = 1.25; b = 1.45;
    kf = 65000; kr = 45000; vx = 30;
    
    % 2. 设定期望的能量耗散速度 (可调参数)
    K1 = 500000;         % 对应 beta 的衰减力度
    K2 = 500000;         % 对应 r 的衰减力度
    epsilon = 0.00001;    % 极小保护阈值
    % 3. 实时计算当前轮胎侧向力
    Fyf = kf * (delta - beta - a * r / vx);
    Fyr = kr * (-beta + b * r / vx);

    if abs(r) < epsilon
        if r >= 0
            r_safe = epsilon;
        else
            r_safe = -epsilon;
        end
    else
        r_safe = r;
    end
    
    % 4. 严格执行李雅普诺夫代数解公式
    term1 = -K1 * beta^2 - K2 * r_safe^2;
    term2 = -2 * beta * (Fyf + Fyr - m * vx * r_safe);
    
    Mz_raw = (term1 + term2) /(2 * r_safe )  - (a * Fyf - b * Fyr);
    
    % 5. 物理限幅 
    if Mz_raw > 4000
        Mz = 4000;
    elseif Mz_raw < -4000
        Mz = -4000;
    else
        Mz = Mz_raw;
    end
end