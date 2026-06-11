module top #(
    parameter int CLK_HZ = 100_000_000,
    parameter int UART_BAUD = 9600,
    parameter int SAMPLE_RATE = 48_000,
    parameter int BIT_BAUD = 1200,
    parameter int MARK_HZ = 1200,
    parameter int SPACE_HZ = 2200
) (
    input  logic        clk_100m,
    input  logic        rst_n,
    input  logic        tjc_rx,
    output logic [11:0] dac_data,
    output logic        dac_clk,
    output logic        dac_wrt,
    output logic        tx_active,
    output logic        msg_ready,
    output logic        uart_error,
    output logic        overflow,
    output logic [4:0]  char_count
);
    logic rst;
    assign rst = ~rst_n;

    logic [7:0] uart_data;
    logic       uart_valid;
    logic       bit_strobe;
    logic       tx_bit;

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
