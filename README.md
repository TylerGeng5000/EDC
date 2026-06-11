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
- DA 输出：`da_data[7:0]` 为 8 位偏置正弦采样，`da_clk` 直接输出系统时钟。若板载 DAC 需要写使能/片选，可在顶层按 CXD720 原理图补充。

## 文件结构

- `rtl/cxd720_afsk_sms_top.v`：顶层，连接 UART、短信控制、成帧编码和 AFSK DDS。
- `rtl/uart_rx.v` / `rtl/uart_tx.v`：串口接收与回显。
- `rtl/message_controller.v`：短信编辑缓存与发送触发控制。
- `rtl/afsk_packet_encoder.v`：短信数据帧编码和按 bit 输出。
- `rtl/afsk_modulator.v`：DDS 正弦表 AFSK 调制器。
- `constr/cxd720_afsk_sms.xdc`：CXD720 引脚约束模板，需要按实际开发板手册填写 PACKAGE_PIN。
- `scripts/create_vivado_project.tcl`：Vivado 工程创建脚本。
- `sim/tb_afsk_sms.v`：Icarus Verilog/Vivado Simulator 可用的基础仿真。

## 创建 Vivado 工程

```tcl
vivado -mode batch -source scripts/create_vivado_project.tcl
```

默认器件是 `xc7a35tcsg324-1`。如果 CXD720 板卡型号不同，可通过 tcl 参数覆盖：

```tcl
vivado -mode batch -source scripts/create_vivado_project.tcl -tclargs <your_fpga_part> cxd720_afsk_sms
```

生成工程后，先按 CXD720 开发板手册修改 `constr/cxd720_afsk_sms.xdc` 中的时钟、复位、串口和 DA 口引脚，再综合、实现、生成 bitstream。

## 串口屏配置建议

让串口屏在“发送”按钮中发送文本框内容并追加结束符。例如：

- 发送 ASCII 文本后追加 `0x0d`；或
- 使用陶晶驰指令结束标志 `0xff 0xff 0xff`。

FPGA 会把收到的可打印英文内容缓存起来，收到结束符后立即调制输出。
