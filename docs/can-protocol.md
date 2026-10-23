# 当前模型中的 CAN 协议

依据 PC 与 STM32 SLX 中 CAN Pack/Unpack 的 `InstanceData` 静态提取，未进行总线抓包验证。

| ID | 方向 | DLC | 字节 0–3 | 字节 4–5 |
|---|---|---|---|---|
| 0x201（513） | PC → STM32 | 6 | beta，single，小端 | seq_beta，uint16，小端 |
| 0x202（514） | PC → STM32 | 6 | yaw_rate，single，小端 | seq_r，uint16，小端 |
| 0x204（516） | PC → STM32 | 6 | delta，single，小端 | seq_delta，uint16，小端 |
| 0x203（515） | STM32 → PC | 6 | M，single，小端 | sample_seq，uint16，小端 |

均为标准 11 位标识符。SignalInfo 中因子为 1、偏移为 0；按控制器的物理含义，beta/delta 使用 rad、yaw_rate 使用 rad/s，M 使用 N·m。

PC 的 Function-Call Generator 与状态保持块采用 0.01 s 周期。STM32 通过 CAN1 RX FIFO0 message-pending 中断触发接收，三个状态序号相等且非零时允许进入控制计算子系统。模型基础步长 0.01 s 不意味着接收中断只能每 10 ms 执行一次。

PC 的 `match_mz` 使用 256 个缓存槽，根据返回序号匹配本地历史输出。无效时输出误差 0，同时输出 valid=false，因此统计误差必须过滤无效点，不能把无效点的 0 算成精度表现。

## 旧 DBC 的差异

`can/legacy/vehicle_controller.dbc` 原样保留，描述的是另一版协议：

- 0x201，DLC 8，三个 int16 状态，缩放因子 0.0001。
- 0x203，DLC 4，单个 float32 力矩。
- 没有当前模型的 0x202、0x204 和序号字段。

当前 SLX 使用手工信号定义，因此旧 DBC 不能解释当前模型报文。此次整理未改写 DBC，也未切换模型的数据格式。

## 需要通过实验补充

序号回绕、重复帧、缺帧、延迟和断线情况下的行为；独立收发帧计数；端到端延迟分布。现有 valid 标记覆盖率不能替代这些指标。
