# 诊断脚本（全部跑在机器人上，只读不动作，安全）

| 脚本 | 用途 | 判读 |
|---|---|---|
| `imu_check.py` | 问一次 IMU | 有数据=MCU 活；None=MCU 挂/串口断 |
| `imu_retry.py` | 连问 5 次（排除开机慢） | 同上，更稳 |
| `raw_serial_test.py` | **裸串口被动监听 4 秒**（绕过 SDK） | 静默=物理链路断（排座松/板坏）；有字节流=链路通 |
| `imu_fall_test.py` | 站→摔→起 全程带 IMU 取证 | X轴↔Z轴重力翻转=真动了；不变=没动 |
| `hw_diag.py` | 串口设备+IMU 综合体检 | 快速摸底 |
| `battery_check.py` | 读电池电压 | 本板固件不支持（返回 None 属正常） |

## 用法（在 PC 上）
```powershell
scp src\diagnostics\imu_retry.py pi@<机器人IP>:/tmp/
ssh pi@<机器人IP> "python3 /tmp/imu_retry.py"
```

## 诊断阶梯（"软件全绿但机器人不动"时按序走）
```
1. 听开机"哔"声    没哔 → MCU 没上电 → 查电池，断电15秒重启
2. imu_retry.py    None → 走第3步；有数据 → 软件问题（查 systemctl status fall-server）
3. raw_serial_test.py  静默 → 物理断连 → 断电重插树莓派40针排座（2026-10-14 实锤案例）
4. 都正常还不动    → imu_fall_test.py 看重力翻转，肉眼复核
```
