# CXD720 AFSK SMS transmitter constraint template.
# Replace every PACKAGE_PIN value according to your CXD720 board schematic.

## 100 MHz system clock
#set_property PACKAGE_PIN <CLK_100M_PIN> [get_ports clk_100m]
#set_property IOSTANDARD LVCMOS33 [get_ports clk_100m]
#create_clock -period 10.000 -name clk_100m [get_ports clk_100m]

## Active-low reset
#set_property PACKAGE_PIN <RST_N_PIN> [get_ports rst_n]
#set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

## TJC serial screen TX -> FPGA RX
#set_property PACKAGE_PIN <TJC_RX_PIN> [get_ports tjc_rx]
#set_property IOSTANDARD LVCMOS33 [get_ports tjc_rx]
#set_property PULLUP true [get_ports tjc_rx]

## 12-bit DAC data bus
#set_property PACKAGE_PIN <DAC_D0_PIN>  [get_ports {dac_data[0]}]
#set_property PACKAGE_PIN <DAC_D1_PIN>  [get_ports {dac_data[1]}]
#set_property PACKAGE_PIN <DAC_D2_PIN>  [get_ports {dac_data[2]}]
#set_property PACKAGE_PIN <DAC_D3_PIN>  [get_ports {dac_data[3]}]
#set_property PACKAGE_PIN <DAC_D4_PIN>  [get_ports {dac_data[4]}]
#set_property PACKAGE_PIN <DAC_D5_PIN>  [get_ports {dac_data[5]}]
#set_property PACKAGE_PIN <DAC_D6_PIN>  [get_ports {dac_data[6]}]
#set_property PACKAGE_PIN <DAC_D7_PIN>  [get_ports {dac_data[7]}]
#set_property PACKAGE_PIN <DAC_D8_PIN>  [get_ports {dac_data[8]}]
#set_property PACKAGE_PIN <DAC_D9_PIN>  [get_ports {dac_data[9]}]
#set_property PACKAGE_PIN <DAC_D10_PIN> [get_ports {dac_data[10]}]
#set_property PACKAGE_PIN <DAC_D11_PIN> [get_ports {dac_data[11]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {dac_data[*]}]

## DAC clock/write controls
#set_property PACKAGE_PIN <DAC_CLK_PIN> [get_ports dac_clk]
#set_property PACKAGE_PIN <DAC_WRT_PIN> [get_ports dac_wrt]
#set_property IOSTANDARD LVCMOS33 [get_ports {dac_clk dac_wrt}]

## Optional debug/status pins
#set_property PACKAGE_PIN <TX_ACTIVE_PIN> [get_ports tx_active]
#set_property PACKAGE_PIN <MSG_READY_PIN> [get_ports msg_ready]
#set_property PACKAGE_PIN <UART_ERROR_PIN> [get_ports uart_error]
#set_property PACKAGE_PIN <OVERFLOW_PIN> [get_ports overflow]
#set_property IOSTANDARD LVCMOS33 [get_ports {tx_active msg_ready uart_error overflow}]
