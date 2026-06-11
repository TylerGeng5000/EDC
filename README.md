# CXD720 串口屏英文短信 AFSK 调制 Vivado 工程

本工程是一个可直接导入 Vivado 的纯 Verilog（全部 RTL 文件均为 `.v`）设计，面向 CXD720 开发板：从陶晶驰串口屏输入/编辑英文短信，FPGA 将短信编码为比特流，采用 AFSK 调制，并从板载 DA1 口输出调制后的模拟波形。

## 功能概述

- **串口屏输入**：默认 `9600 8N1`。
  - 串口屏 `TXD` 接 CXD720 `ext[3]`，FPGA 作为 UART RX。
  - 串口屏 `RXD` 接 CXD720 `ext[4]`，FPGA 作为 UART TX 回显。
  - 串口屏与开发板必须共地。
- **英文短信编辑**：
  - 接收并缓存可打印 ASCII 字符 `0x20` 到 `0x7e`。
  - 支持 Backspace/Delete 删除上一个字符。
  - 收到回车/换行，或陶晶驰常用结束序列 `0xff 0xff 0xff`，触发发送。
- **编码格式**：
  - 16 字节前导码 `0x55`。
  - 同步字节 `0x7e`。
  - 1 字节长度。
  - ASCII 载荷，每字节最低位先发。
  - 1 字节 XOR 校验。
- **AFSK 调制**：默认 `1200 baud`，`bit=1` 输出 `1200 Hz` mark，`bit=0` 输出 `2200 Hz` space。
- **DA 输出**：DA1 使用 14 位并行数据口，`da1_out[13:0]` 输出由 DDS 正弦采样扩展得到的无符号波形，`da1_clk`/`da1_wrt` 同步输出系统时钟；DA2 固定输出中点值。
- **状态 LED**：
  - `led[1]`：AFSK 正在发送。
  - `led[2]`：当前短信缓存非空。
  - `led[3]`：输入超长溢出。
  - `led[4]`：单帧发送结束脉冲。
  - `led[5]`：UART 接收有效脉冲。
  - `led[6]`：UART 回显忙。

## 文件结构

- `rtl/cxd720_afsk_sms_top.v`：CXD720 顶层，端口名匹配用户给出的引脚约束；连接 UART、短信控制、成帧编码、AFSK DDS 与 DA1 输出。
- `rtl/uart_rx.v` / `rtl/uart_tx.v`：串口接收与回显。
- `rtl/message_controller.v`：短信编辑缓存与发送触发控制。
- `rtl/afsk_packet_encoder.v`：短信成帧编码与按 bit 输出。
- `rtl/afsk_modulator.v`：DDS 正弦表 AFSK 调制器。
- `constr/cxd720_afsk_sms.xdc`：已按你提供的 CXD720 引脚表整理，补充了 `ext[3]`/`ext[4]` 作为串口屏 UART 接口说明。
- `scripts/create_vivado_project.tcl`：Vivado 工程创建脚本。
- `sim/tb_afsk_sms.v`：基础仿真，发送字符串 `Hi` 并检查 AFSK 发送流程。

## 创建 Vivado 工程

```tcl
vivado -mode batch -source scripts/create_vivado_project.tcl
```

默认器件为 `xc7a35tcsg324-1`。如果你的 CXD720 板卡实际 FPGA 型号不同，可用参数覆盖：

```tcl
vivado -mode batch -source scripts/create_vivado_project.tcl -tclargs <your_fpga_part> cxd720_afsk_sms
```

生成工程后，可直接综合/实现/生成 bitstream。若你的串口屏不接在 `ext[3]`/`ext[4]`，只需要修改 `constr/cxd720_afsk_sms.xdc` 中对应的 `ext` 引脚，或修改顶层中 `uart_rx_pin`/`ext[4]` 的连接。

## 陶晶驰串口屏配置建议

建议在串口屏“发送”按钮事件中发送文本框内容，并追加以下任一结束符：

- ASCII 回车 `0x0d`；或
- 陶晶驰指令结束标志 `0xff 0xff 0xff`。

FPGA 收到结束符后会把当前缓存短信编码、调制并从 DA1 输出。
