# CXD720 / 陶晶驰串口屏 AFSK 短信调制 Vivado 工程 RTL

本目录给出一个可直接加入 Vivado 的 Verilog RTL 设计，所有工程源文件均使用 `.v` 文件与 Verilog 语法，用于在 CXD720 开发板上完成：

1. 从陶晶驰（TJC/Nextion 类）串口屏接收用户编辑的英文短信；
2. 限制并缓存最多 26 个英文字母，自动把小写字母转成大写；
3. 将短信封装为二进制帧；
4. 使用 Bell-202 风格 AFSK 调制；
5. 从 12 bit 并行 DA 口输出调制后的离散模拟采样值。

## 顶层接口

顶层模块为 `top`：

| 端口 | 方向 | 说明 |
| --- | --- | --- |
| `clk_100m` | input | FPGA 100 MHz 系统时钟 |
| `rst_n` | input | 低有效复位 |
| `tjc_rx` | input | 陶晶驰串口屏 TX 接到 FPGA RX，默认 9600-8-N-1 |
| `dac_data[11:0]` | output | 送外部 DAC 的无符号采样，2048 为零电平 |
| `dac_clk` | output | DAC 参考时钟，默认直接输出系统时钟 |
| `dac_wrt` | output | 新采样写使能脉冲，默认 48 kHz |
| `tx_active` | output | 正在发送 AFSK 帧 |
| `msg_ready` | output | 收到一条合法短信并开始发送时脉冲 |
| `uart_error` | output | UART 停止位错误脉冲 |
| `overflow` | output | 输入超过 26 个字母时脉冲 |
| `char_count[4:0]` | output | 当前已缓存字母个数 |

## 串口屏输入约定

串口屏应把文本框内容以 ASCII 字节发送到 FPGA。RTL 只接收 `A`~`Z` 和 `a`~`z`，并丢弃其它普通字符。收到以下任一字节后，如果当前缓存非空，则立即开始发送：

- `0x0d`：回车；
- `0x0a`：换行；
- `0xff`：兼容部分 TJC 控件结束符。

退格 `0x08` 或 `0x7f` 会删除一个已缓存字符。缓存达到 26 个字母时会自动开始发送。

## 编码帧格式

比特按每字节 MSB first 输出：

```text
8 字节 0x55 前导码 | 1 字节 0x7e 同步字 | 1 字节长度 N | N 字节大写 ASCII 文本 | 1 字节 XOR 校验
```

XOR 校验覆盖“长度字节 + 文本字节”。

## AFSK 参数

默认参数适合常见窄带 AFSK 链路：

- 比特率：1200 bit/s；
- 采样率：48 ksample/s；
- Mark（比特 1）：1200 Hz；
- Space（比特 0）：2200 Hz；
- DDS 相位累加器：24 bit；
- 正弦查找表：256 点，12 bit，约 1800 LSB 峰值幅度。

如果接收端采用其它 AFSK 约定，可在 `top` 参数或 `afsk_modulator` 参数中修改 `BIT_BAUD`、`MARK_HZ`、`SPACE_HZ` 和 `SAMPLE_RATE`。

## Vivado 使用步骤

1. 在 Vivado 中新建 RTL Project，选择 CXD720 开发板对应 FPGA 型号；
2. 添加 `rtl/rtl.f` 中列出的 `.v` 源文件，或运行 `vivado/create_project.tcl`；
3. 根据板卡原理图修改 `constraints/cxd720_afsk_template.xdc` 中的引脚；
4. 综合、实现、生成 bitstream；
5. 串口屏 TX 接 `tjc_rx`，FPGA `dac_data/dac_wrt/dac_clk` 接板载或外接 DAC。

> 注意：不同批次 CXD720 开发板的 FPGA 型号、时钟脚和 DA 接口引脚可能不同，本仓库只提供约束模板，烧录前必须按你的板卡原理图填写准确管脚。
