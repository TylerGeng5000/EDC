`timescale 1ns / 1ps

module cxd720_afsk_sms_top #(
    parameter CLK_HZ    = 50000000,
    parameter UART_BAUD = 9600,
    parameter AFSK_BAUD = 1200,
    parameter MARK_HZ   = 1200,
    parameter SPACE_HZ  = 2200,
    parameter MAX_BYTES = 160
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       uart_rx,
    output wire       uart_tx,
    output wire [7:0] da_data,
    output wire       da_clk,
    output wire       afsk_busy,
    output wire [3:0] led
);
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
    wire [7:0] dac_sample;

    assign da_clk = clk;
    assign da_data = dac_sample;
    assign afsk_busy = tx_active;
    assign led[0] = tx_active;
    assign led[1] = (char_count != 8'd0);
    assign led[2] = overflow;
    assign led[3] = packet_done;

    uart_rx #(
        .CLK_HZ(CLK_HZ),
        .BAUD(UART_BAUD)
    ) u_uart_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx),
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
        .tx(uart_tx),
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
        .dac_sample(dac_sample)
    );
endmodule
