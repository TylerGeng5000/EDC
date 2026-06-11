`timescale 1ns/1ps

module tb_top;
    localparam int CLK_HZ = 1_000_000;
    localparam int UART_BAUD = 9600;
    localparam int SAMPLE_RATE = 20_000;
    localparam int BIT_BAUD = 1000;
    localparam int BIT_NS = 1_000_000_000 / UART_BAUD;

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic tjc_rx = 1'b1;
    logic [11:0] dac_data;
    logic dac_clk;
    logic dac_wrt;
    logic tx_active;
    logic msg_ready;
    logic uart_error;
    logic overflow;
    logic [4:0] char_count;

    always #500 clk = ~clk;

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

    task automatic send_uart(input [7:0] ch);
        int i;
        begin
            tjc_rx = 1'b0;
            #(BIT_NS);
            for (i = 0; i < 8; i++) begin
                tjc_rx = ch[i];
                #(BIT_NS);
            end
            tjc_rx = 1'b1;
            #(BIT_NS);
        end
    endtask

    int dac_edges;

    initial begin
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
            if (dac_wrt) dac_edges++;
        end

        if (uart_error) $fatal(1, "unexpected UART frame error");
        if (overflow) $fatal(1, "unexpected overflow");
        if (dac_edges < 50) $fatal(1, "too few DAC samples: %0d", dac_edges);
        $display("PASS: AFSK packet transmitted with %0d DAC samples", dac_edges);
        $finish;
    end
endmodule
