`timescale 1ns / 1ps

module cxd720_afsk_sms_top #(
    parameter CLK_HZ    = 100000000,
    parameter UART_BAUD = 9600,
    parameter AFSK_BAUD = 1200,
    parameter MARK_HZ   = 1200,
    parameter SPACE_HZ  = 2200,
    parameter MAX_BYTES = 160
)(
    input  wire        clk_100m_in,
    input  wire        rst,
    input  wire [4:1]  key,
    output wire [8:1]  led,
    output wire [3:0]  seg_s,
    output wire [7:0]  seg_ap,
    output wire        ad_clk,
    input  wire [11:0] ad_din,
    output wire        da1_clk,
    output wire        da1_wrt,
    output wire [13:0] da1_out,
    output wire        da2_clk,
    output wire        da2_wrt,
    output wire [13:0] da2_out,
    inout  wire [38:3] ext
);
    wire       clk;
    wire       rst_n;
    wire       uart_rx_pin;
    wire       uart_tx_pin;
    wire [7:0] rx_data;
    wire       rx_valid;
    wire       msg_valid;
    wire [7:0] msg_len;
    wire [7:0] msg_byte;
    wire [7:0] msg_addr;
    wire [7:0] char_count;
    wire       msg_ready;
    wire       overflow;
    wire       packet_done;
    wire       bit_tick;
    wire       bit_value;
    wire       tx_active;
    wire       uart_tx_busy;
    wire [7:0] dac_sample_8;

    assign clk = clk_100m_in;
    assign rst_n = ~rst;

    // 陶晶驰串口屏默认连接到扩展排针：ext[3] = FPGA RX，ext[4] = FPGA TX。
    // 串口屏 TXD -> ext[3]，串口屏 RXD -> ext[4]，GND 共地。
    assign uart_rx_pin = ext[3];
    assign ext[4] = uart_tx_pin;
    assign ext[38:5] = {34{1'bz}};

    assign da1_clk = clk;
    assign da1_wrt = clk;
    assign da1_out = {dac_sample_8, 6'b000000};

    assign da2_clk = clk;
    assign da2_wrt = clk;
    assign da2_out = 14'd8192;

    assign ad_clk = clk;
    assign seg_s = 4'b1111;
    assign seg_ap = 8'hff;

    assign led[1] = tx_active;
    assign led[2] = (char_count != 8'd0);
    assign led[3] = overflow;
    assign led[4] = packet_done;
    assign led[5] = rx_valid;
    assign led[6] = uart_tx_busy;
    assign led[7] = key[1];
    assign led[8] = key[2];

    uart_rx #(
        .CLK_HZ(CLK_HZ),
        .BAUD(UART_BAUD)
    ) u_uart_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx_pin),
        .data(rx_data),
        .data_valid(rx_valid)
    );

    uart_tx #(
        .CLK_HZ(CLK_HZ),
        .BAUD(UART_BAUD)
    ) u_uart_tx (
        .clk(clk),
        .rst_n(rst_n),
        .data(rx_data),
        .data_valid(rx_valid && !uart_tx_busy),
        .tx(uart_tx_pin),
        .busy(uart_tx_busy)
    );

    message_controller #(
        .MAX_BYTES(MAX_BYTES)
    ) u_message_controller (
        .clk(clk),
        .rst_n(rst_n),
        .uart_data(rx_data),
        .uart_valid(rx_valid),
        .tx_done(msg_ready),
        .tx_start(msg_valid),
        .tx_len(msg_len),
        .tx_byte(msg_byte),
        .tx_addr(msg_addr),
        .char_count(char_count),
        .overflow(overflow),
        .busy()
    );

    afsk_packet_encoder #(
        .MAX_BYTES(MAX_BYTES),
        .PREAMBLE_BYTES(16)
    ) u_packet_encoder (
        .clk(clk),
        .rst_n(rst_n),
        .msg_len(msg_len),
        .msg_addr(msg_addr),
        .msg_data(msg_byte),
        .msg_valid(msg_valid),
        .msg_ready(msg_ready),
        .bit_tick(bit_tick),
        .tx_active(tx_active),
        .bit_value(bit_value),
        .packet_done(packet_done)
    );

    afsk_modulator #(
        .CLK_HZ(CLK_HZ),
        .BAUD(AFSK_BAUD),
        .MARK_HZ(MARK_HZ),
        .SPACE_HZ(SPACE_HZ)
    ) u_afsk_modulator (
        .clk(clk),
        .rst_n(rst_n),
        .tx_active(tx_active),
        .bit_value(bit_value),
        .bit_tick(bit_tick),
        .dac_sample(dac_sample_8)
    );
endmodule
