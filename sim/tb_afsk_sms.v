`timescale 1ns / 1ps

module tb_afsk_sms;
    reg clk;
    reg rst_n;
    reg uart_rx_line;
    wire uart_tx_line;
    wire [7:0] da_data;
    wire da_clk;
    wire afsk_busy;
    wire [3:0] led;

    cxd720_afsk_sms_top #(
        .CLK_HZ(1000000),
        .UART_BAUD(9600),
        .AFSK_BAUD(1200),
        .MARK_HZ(1200),
        .SPACE_HZ(2200),
        .MAX_BYTES(160)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(uart_rx_line),
        .uart_tx(uart_tx_line),
        .da_data(da_data),
        .da_clk(da_clk),
        .afsk_busy(afsk_busy),
        .led(led)
    );

    initial begin
        clk = 1'b0;
        forever #500 clk = ~clk;
    end

    task send_uart_byte;
        input [7:0] b;
        integer k;
        begin
            uart_rx_line = 1'b0;
            #(104000);
            for (k = 0; k < 8; k = k + 1) begin
                uart_rx_line = b[k];
                #(104000);
            end
            uart_rx_line = 1'b1;
            #(104000);
        end
    endtask

    initial begin
        rst_n = 1'b0;
        uart_rx_line = 1'b1;
        #(10000);
        rst_n = 1'b1;
        #(10000);

        send_uart_byte("H");
        send_uart_byte("i");
        send_uart_byte(8'h0d);

        wait (afsk_busy == 1'b1);
        wait (afsk_busy == 1'b0);
        #(200000);
        $finish;
    end
endmodule
