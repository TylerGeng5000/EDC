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

  - `led[7]`：重复发送模式保持中，直到收到 Clear 命令。


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

## 帧边界与接收端判帧

当前发送链路已经有明确帧边界：`0x55` 前导码之后是起始符 `0x7e`，然后按长度字段接收固定数量的载荷字节，接着接收 XOR 校验字节，最后必须收到结束符 `0x7f`。因此接收端可以用“搜索前导码/起始符 -> 读取长度 -> 读取载荷和校验 -> 检查结束符”的状态机区分上一帧和下一帧。点击 Send 后，主站会保留同一条短信并每隔 0.5 秒再次发送一帧；上一帧的 `0x7f` 结束符和下一帧的 `0x55...0x7e` 前导/起始序列会形成清楚分界。

注意：载荷允许普通可打印 ASCII，可能包含 `0x7e` 字符 `~`，但接收端在进入载荷状态后应以长度字段为准，不应在载荷中重新搜索起始符。

## 陶晶驰串口屏配置建议

建议在串口屏“发送”按钮事件中只发送文本框内容，不要清空 `t0`。发送文本后追加以下任一结束符：

- ASCII 回车 `0x0d`；或
- 陶晶驰指令结束标志 `0xff 0xff 0xff`。

FPGA 收到结束符后会保留当前短信缓存，并开始从 DA1 每隔 0.5 秒重复输出同一帧 AFSK 信号。

Clear 按钮建议执行两步：

1. 清空屏幕文本框，例如 `t0.txt=""`。
2. 向 FPGA 发送单字节 `0x18`，例如使用陶晶驰/Nextion 的十六进制发送命令 `printh 18`。

FPGA 收到 `0x18` 后停止后续重复发送，同时清空内部短信缓存。已经在空中发送到一半的当前帧不会被硬切断，但不会再启动下一帧。

