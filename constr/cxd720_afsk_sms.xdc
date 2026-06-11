## CXD720 AFSK SMS project constraints template
## Replace PACKAGE_PIN values with the exact pins from your CXD720 board manual.
## The RTL port names are fixed and can be mapped here after confirming the board variant.

create_clock -period 20.000 -name sys_clk [get_ports clk]

## Example syntax only:
## set_property -dict {PACKAGE_PIN <CLK_PIN> IOSTANDARD LVCMOS33} [get_ports clk]
## set_property -dict {PACKAGE_PIN <RST_PIN> IOSTANDARD LVCMOS33 PULLUP true} [get_ports rst_n]
## set_property -dict {PACKAGE_PIN <UART_RX_PIN> IOSTANDARD LVCMOS33} [get_ports uart_rx]
## set_property -dict {PACKAGE_PIN <UART_TX_PIN> IOSTANDARD LVCMOS33} [get_ports uart_tx]
## set_property -dict {PACKAGE_PIN <DA_CLK_PIN> IOSTANDARD LVCMOS33} [get_ports da_clk]
## set_property -dict {PACKAGE_PIN <DA_D0_PIN> IOSTANDARD LVCMOS33} [get_ports {da_data[0]}]
## set_property -dict {PACKAGE_PIN <DA_D1_PIN> IOSTANDARD LVCMOS33} [get_ports {da_data[1]}]
## set_property -dict {PACKAGE_PIN <DA_D2_PIN> IOSTANDARD LVCMOS33} [get_ports {da_data[2]}]
## set_property -dict {PACKAGE_PIN <DA_D3_PIN> IOSTANDARD LVCMOS33} [get_ports {da_data[3]}]
## set_property -dict {PACKAGE_PIN <DA_D4_PIN> IOSTANDARD LVCMOS33} [get_ports {da_data[4]}]
## set_property -dict {PACKAGE_PIN <DA_D5_PIN> IOSTANDARD LVCMOS33} [get_ports {da_data[5]}]
## set_property -dict {PACKAGE_PIN <DA_D6_PIN> IOSTANDARD LVCMOS33} [get_ports {da_data[6]}]
## set_property -dict {PACKAGE_PIN <DA_D7_PIN> IOSTANDARD LVCMOS33} [get_ports {da_data[7]}]
## set_property -dict {PACKAGE_PIN <AFSK_BUSY_PIN> IOSTANDARD LVCMOS33} [get_ports afsk_busy]
## set_property -dict {PACKAGE_PIN <LED0_PIN> IOSTANDARD LVCMOS33} [get_ports {led[0]}]
## set_property -dict {PACKAGE_PIN <LED1_PIN> IOSTANDARD LVCMOS33} [get_ports {led[1]}]
## set_property -dict {PACKAGE_PIN <LED2_PIN> IOSTANDARD LVCMOS33} [get_ports {led[2]}]
## set_property -dict {PACKAGE_PIN <LED3_PIN> IOSTANDARD LVCMOS33} [get_ports {led[3]}]
