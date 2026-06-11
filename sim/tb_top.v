`timescale 1ns/1ps

module tb_top;
    parameter integer CLK_HZ = 1_000_000;
    parameter integer UART_BAUD = 9600;
    parameter integer SAMPLE_RATE = 20_000;
    parameter integer BIT_BAUD = 1000;
    parameter integer BIT_NS = 1_000_000_000 / UART_BAUD;

    reg clk;
    reg rst_n;
    reg tjc_rx;
    wire [11:0] dac_data;
    wire dac_clk;
    wire dac_wrt;
    wire tx_active;
    wire msg_ready;
    wire uart_error;
    wire overflow;
    wire [4:0] char_count;

    integer dac_edges;

    top #(
        .CLK_HZ(CLK_HZ),
        .UART_BAUD(UART_BAUD),
        .SAMPLE_RATE(SAMPLE_RATE),
        .BIT_BAUD(BIT_BAUD),
        .MARK_HZ(1000),
        .SPACE_HZ(2000)
    ) dut (
        .clk_100m(clk),
        .rst_n(rst_n),
        .tjc_rx(tjc_rx),
        .dac_data(dac_data),
        .dac_clk(dac_clk),
        .dac_wrt(dac_wrt),
        .tx_active(tx_active),
        .msg_ready(msg_ready),
        .uart_error(uart_error),
        .overflow(overflow),
        .char_count(char_count)
    );

    always #500 clk = ~clk;

    task send_uart;
        input [7:0] ch;
        integer i;
        begin
            tjc_rx = 1'b0;
            #(BIT_NS);
            for (i = 0; i < 8; i = i + 1) begin
                tjc_rx = ch[i];
                #(BIT_NS);
            end
            tjc_rx = 1'b1;
            #(BIT_NS);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        tjc_rx = 1'b1;
        dac_edges = 0;

        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (10) @(posedge clk);

        send_uart("H");
        send_uart("i");
        send_uart("Z");
        send_uart(8'h0d);

        wait (msg_ready);
        wait (tx_active);
        while (tx_active) begin
            @(posedge clk);
            if (dac_wrt) begin
                dac_edges = dac_edges + 1;
            end
        end

        if (uart_error) begin
            $display("FAIL: unexpected UART frame error");
            $finish;
        end
        if (overflow) begin
            $display("FAIL: unexpected overflow");
            $finish;
        end
        if (dac_edges < 50) begin
            $display("FAIL: too few DAC samples: %0d", dac_edges);
            $finish;
        end
        $display("PASS: AFSK packet transmitted with %0d DAC samples", dac_edges);
        $finish;
    end
endmodule
