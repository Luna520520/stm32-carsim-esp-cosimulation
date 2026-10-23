# 复现与迁移说明

此文档记录现有文件的迁移路径。未在新环境完成运行验证，不能将本仓库视为开箱即用固件。

## 1. 准备环境

源模型保存为 MATLAB / Simulink R2025a；历史日志使用 CarSim 2024.1。模型引用 Vehicle Network Toolbox 的 CAN 块、Simulink Desktop Real-Time、STM32F1xx 硬件支持与 Embedded Coder 目标。需要在自己的环境中核实这些组件、PCAN 驱动、ARM 工具链和 STM32Cube 固件包。

`LED.ioc` 的主固件包字段为 STM32Cube FW_F1 V1.8.7，但自定义固件目录指向 V1.8.6；这是现存配置差异，需在本机确认实际使用版本。该目录包含旧机器路径，不能照搬。

## 2. 加载 PC 模型

1. 在 MATLAB 中切换到仓库根目录，将 `parameters` 与 `scripts` 加入搜索路径。
2. 打开 `models/pc/backup222.slx`。初始化回调调用 `Electronic_stability_program_model_parameter`，因此参数目录必须可搜索。
3. 配置本机 CarSim S-Function 与 Run，确认导出顺序为 `AVz`、`Beta`，导入变量为 `IMP_MZ_EXT`，模式为 Add。
4. 原 CarSim Run 指向 `D:\Lab\backup\backup222.slx`，应改为本机仓库中的模型路径。
5. PC CAN 设备保存为 `PEAK-System PCAN-USB (PCAN_USBBUS1)`，总线速率 500000 bit/s。依本机实际通道调整。
6. 活动配置 `Configuration` 步长为 0.0005 s；另有 `SLDRTBackup` 备用配置 0.01 s。不能把备用配置误当成当前活动配置。
7. 活动配置还保存了 Linux 64 的硬件类型字段，备用配置为 Windows64；迁移时需核对主机目标，不能只根据文件来自 Windows 判断生成目标。

CAN Pack/Unpack 当前采用 `manually specified signals`。其中仍保存旧 DBC 的绝对路径，但旧 DBC 不包含当前的四报文序号协议。不要直接切换成旧 DBC 驱动的打包方式，详见 [协议说明](can-protocol.md)。

## 3. 生成 STM32 工程

1. 打开 `hardware/LED.ioc`，核对芯片 STM32F103C8T6、系统时钟 72 MHz、APB1 36 MHz、CAN RX=PB8、TX=PB9。
2. IOC 的 CAN 时序为 Prescaler=9、BS1=5TQ、BS2=2TQ，保存的计算波特率为 500000 bit/s。
3. 打开 `models/stm32/stm32_delay_optimization_stage2_working.slx`，将硬件配置引用由原 `D:\Lab\LED\LED.ioc` 改为仓库中的 IOC。
4. 模型保存的 CAN1 Baudrate 字段为 1000000，而 IOC 与 PC 为 500000。核对代码生成后的实际 CAN 初始化参数并与 PC 对齐，不预设哪个字段最终生效。
5. PostCodeGenCommand 保留标准 `codertarget.postCodeGenHookCommand(h)` 和 `fix_stm32_can_fifo_release_hook()` 调用；将其中 `addpath` 的旧 `D:\Lab\step1` 路径更新为本机 `scripts` 的绝对路径。构建时工作目录会变化，不使用依赖当前目录的相对路径。
6. 原修复脚本尝试删除生成 ISR 中的第二次 FIFO 释放。它包含匹配数量和代码顺序断言；如果工具链生成结构变化，先检查生成代码，不跳过断言。
7. 编译成功后再按自己的开发板、下载器与 CAN 收发器配置烧录和连接。

本包不包含生成的 C 工程、HAL 驱动副本或编译固件；请从模型与 IOC 在自己的已配置环境中生成。PB8/PB9 的配置不能替代 CAN 收发器与总线接线说明，实物接线仍待维护者补充。

## 4. CarSim 工况重建

在自己的 CarSim 数据库副本中选择 C-Class Hatchback。历史工况的设置如下：

- 直线道路 Straight East，路面附着系数 0.85。
- 目标速度 108 km/h，时长 10 s；方向盘输入 0 deg，主缸压力 0 MPa。
- 自动换挡 AT (All Available Gears)，求解步长 0.0005 s，输出步长 0.02 s。
- 导出 `AVz`、`Beta`，依模型中的 `pi/180` 增益转换成 rad/s 和 rad。
- 导入附加横摆力矩 `IMP_MZ_EXT`。

随包 PC 模型还包含幅值为 +1000、-1000 的阶跃块，第二个时间参数为 1.1 s。实际扰动应连同默认阶跃时间、连线与开关状态在 Simulink 中核对，不能仅凭 CarSim 的零转向工况认定完全无扰动。

## 5. 重新记录结果

先确认收发与序号匹配，再检查控制器返回值是否真正进入车辆模型。保留 `tx_seq_log`、`rx_seq_log`、`valid_log`、`mz_compare_log`、`mz_error_log`、`mz_applied_log`、`r_log`、`beta_log`、`missed_log` 和完整时间轴。

`scripts/plot_ppt_results.m` 与 `scripts/plot_ppt_results11.m` 是两份历史绘图脚本，均依赖工作区变量 `out`，输出写入当前目录的 `PPT_Results`；它们不是脱离仿真数据即可运行的独立演示。暂未确认现有图片对应哪一份脚本。

新实验同时记录代码/模型版本、软件版本、板卡、CAN 配置和控制器开关。使用相同扰动增加关闭控制器的对照工况，再讨论控制改善效果。
