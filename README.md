# CXD720 串口屏英文短信 AFSK 调制工程


本工程提供一个可导入 Vivado 的纯 Verilog（`.v`）设计，用于从陶晶驰/串口屏接收英文短信，编码成数据帧，再使用 AFSK 调制后从 DA 口输出 8 位无符号正弦采样。


## 功能概述

- 串口屏接口：默认 `9600 8N1`，接收可打印 ASCII 英文字符。

- 编辑支持：
  - 普通字符 `0x20` 到 `0x7e` 写入短信缓存；
  - Backspace/Delete 删除上一个字符；
  - 回车/换行或陶晶驰常用结束序列 `0xff 0xff 0xff` 触发发送。
- 编码格式：
  - 16 字节前导码 `0x55`；
  - 同步字节 `0x7e`；
  - 1 字节长度；
  - ASCII 载荷，最低位先发；
  - 1 字节 XOR 校验。
- AFSK 调制：默认 `1200 baud`，`bit=1` 为 `1200 Hz` mark，`bit=0` 为 `2200 Hz` space。


## 板级端口映射

| 功能 | 顶层端口 | XDC 引脚 | 说明 |
| --- | --- | --- | --- |
| 系统时钟 | `clk_100m_in` | `C19` | 100 MHz，XDC 中 `create_clock -period 10.000` |
| 复位 | `rst` | `P4` | 代码按低有效复位链路使用：`rst` 直接作为内部 `rst_n` |
| 串口屏 TX | `ext[3]` | `D21` | 接 FPGA UART RX |
| 串口屏 RX | `ext[4]` | `D22` | 接 FPGA UART TX，可不接 |
| AFSK DAC | `da1_out[13:0]` | 见 XDC | 8 位 DDS 采样左移到 14 位 DAC 总线 |
| DAC1 时钟/写 | `da1_clk` / `da1_wrt` | `W2` / `Y1` | 直接输出系统时钟 |
| 状态灯 | `led[1]` | `Y4` | AFSK 正在发送 |
| 状态灯 | `led[2]` | `V4` | 当前短信缓存非空 |
| 状态灯 | `led[3]` | `T3` | 输入缓存溢出 |
| 状态灯 | `led[4]` | `T4` | 数据包发送完成脉冲 |

如果你的板载复位按键实际是高有效，请把 `rtl/cxd720_afsk_sms_top.v` 中的 `assign rst_n = rst;` 改为 `assign rst_n = ~rst;`。

## 文件结构

- `rtl/cxd720_afsk_sms_top.v`：CXD720 板级顶层，连接 UART、短信控制、成帧编码、AFSK DDS、DA1 与扩展 IO。

- `rtl/uart_rx.v` / `rtl/uart_tx.v`：串口接收与回显。
- `rtl/message_controller.v`：短信编辑缓存与发送触发控制。
- `rtl/afsk_packet_encoder.v`：短信数据帧编码和按 bit 输出。
- `rtl/afsk_modulator.v`：DDS 正弦表 AFSK 调制器。

- `constr/cxd720_afsk_sms.xdc`：按你提供的 CXD720 引脚表整理后的约束文件。
- `scripts/create_vivado_project.tcl`：Vivado 工程创建脚本。
- `sim/tb_afsk_sms.v`：Icarus Verilog/Vivado Simulator 可用的基础仿真。

## 创建 Vivado 工程

```tcl
vivado -mode batch -source scripts/create_vivado_project.tcl
```


默认器件改为 `xc7a100tfgg484-2`，用于匹配带 `AA/AB` 管脚名的 CXD720 XDC。如果你的实际 FPGA 型号或速度等级不同，通过 tcl 参数覆盖：


```tcl
vivado -mode batch -source scripts/create_vivado_project.tcl -tclargs <your_fpga_part> cxd720_afsk_sms
```



## 串口屏配置建议

让串口屏在“发送”按钮中发送文本框内容并追加结束符。例如：

- 发送 ASCII 文本后追加 `0x0d`；或
- 使用陶晶驰指令结束标志 `0xff 0xff 0xff`。

推荐按钮事件：

```text
prints t0.txt,0
printh FF FF FF
```

FPGA 会把收到的可打印英文内容缓存起来，收到结束符后立即调制输出。
