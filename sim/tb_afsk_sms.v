`timescale 1ns / 1ps

module tb_afsk_sms;
    reg clk_100m_in;
    reg rst;
    reg uart_rx_line;
    wire uart_tx_line;
    reg [4:1] key;
    wire [8:1] led;
    wire [3:0] seg_s;
    wire [7:0] seg_ap;
    wire ad_clk;
    reg [11:0] ad_din;
    wire da1_clk;
    wire da1_wrt;
    wire [13:0] da1_out;
    wire da2_clk;
    wire da2_wrt;
    wire [13:0] da2_out;
    wire [38:3] ext;

    assign ext[3] = uart_rx_line;
    assign uart_tx_line = ext[4];

    cxd720_afsk_sms_top #(
        .CLK_HZ(1000000),
        .UART_BAUD(9600),
        .AFSK_BAUD(1200),
        .MARK_HZ(1200),
        .SPACE_HZ(2200),
        .MAX_BYTES(160)
    ) dut (
        .clk_100m_in(clk_100m_in),
        .rst(rst),
        .key(key),
        .led(led),
        .seg_s(seg_s),
        .seg_ap(seg_ap),
        .ad_clk(ad_clk),
        .ad_din(ad_din),
        .da1_clk(da1_clk),
        .da1_wrt(da1_wrt),
        .da1_out(da1_out),
        .da2_clk(da2_clk),
        .da2_wrt(da2_wrt),
        .da2_out(da2_out),
        .ext(ext)
    );

    initial begin
        clk_100m_in = 1'b0;
        forever #500 clk_100m_in = ~clk_100m_in;
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
        rst = 1'b1;
        key = 4'b1111;
        ad_din = 12'd0;
        uart_rx_line = 1'b1;
        #(10000);
        rst = 1'b0;
        #(10000);

        send_uart_byte("H");
        send_uart_byte("i");
        send_uart_byte(8'h0d);

        wait (led[1] == 1'b1);
        wait (led[1] == 1'b0);
        #(200000);
        $finish;
    end
endmodule
