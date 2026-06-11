module top #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer UART_BAUD = 9600,
    parameter integer SAMPLE_RATE = 48_000,
    parameter integer BIT_BAUD = 1200,
    parameter integer MARK_HZ = 1200,
    parameter integer SPACE_HZ = 2200
) (
    input  wire        clk_100m,
    input  wire        rst_n,
    input  wire        tjc_rx,
    output wire [11:0] dac_data,
    output wire        dac_clk,
    output wire        dac_wrt,
    output wire        tx_active,
    output wire        msg_ready,
    output wire        uart_error,
    output wire        overflow,
    output wire [4:0]  char_count
);
    wire rst;
    wire [7:0] uart_data;
    wire       uart_valid;
    wire       bit_strobe;
    wire       tx_bit;

    assign rst = ~rst_n;

    uart_rx #(
        .CLK_HZ(CLK_HZ),
        .BAUD(UART_BAUD)
    ) u_uart_rx (
        .clk(clk_100m),
        .rst(rst),
        .rx(tjc_rx),
        .data(uart_data),
        .data_valid(uart_valid),
        .frame_error(uart_error)
    );

    sms_packet_source u_packet (
        .clk(clk_100m),
        .rst(rst),
        .uart_data(uart_data),
        .uart_valid(uart_valid),
        .bit_strobe(bit_strobe),
        .tx_bit(tx_bit),
        .tx_active(tx_active),
        .msg_ready(msg_ready),
        .overflow(overflow),
        .char_count(char_count)
    );

    afsk_modulator #(
        .CLK_HZ(CLK_HZ),
        .SAMPLE_RATE(SAMPLE_RATE),
        .BAUD(BIT_BAUD),
        .MARK_HZ(MARK_HZ),
        .SPACE_HZ(SPACE_HZ)
    ) u_afsk (
        .clk(clk_100m),
        .rst(rst),
        .tx_bit(tx_bit),
        .tx_active(tx_active),
        .sample_strobe(),
        .bit_strobe(bit_strobe),
        .dac_data(dac_data),
        .dac_wrt(dac_wrt),
        .dac_clk(dac_clk)
    );
endmodule
