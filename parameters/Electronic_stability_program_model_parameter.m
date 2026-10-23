%% 车辆参数
m = 1750;      %整车质量
Iz = 3000;     %车辆绕z轴的转动惯量
a = 1.25;      %质心至前轴距离
b = 1.45;      %质心至后轴距离
L = a + b;     %轴距
vx = 30;       % 车速
kf = 65000;    % 前轮侧偏刚度
kr = 45000;    % 后轮侧偏刚度

%矩阵A的计算
A11 = -(kf + kr) / (m * vx);
A12 = (b * kr - a * kf) / (m * vx^2) - 1;
A21 = (b * kr - a * kf) / Iz;
A22 = -(a^2 * kf + b^2 * kr) / (Iz * vx);
A = [A11, A12; A21, A22]; 

%计算输入矩阵 B 
B1 = [kf / (m * vx); a * kf / Iz];
B2 = [0; 1 / Iz];
B = [B1, B2];

%% 特征值验证打印
disp('--- 理论预检 ---');
eigenvalues = eig(A);
disp('当前真实系统矩阵 A 的特征值为：');
disp(eigenvalues);
if max(real(eigenvalues)) >= 0
    disp('【警告】系统已失稳！准备在 Simulink 中观察能量发散。');
else
    disp('系统安全。');
end