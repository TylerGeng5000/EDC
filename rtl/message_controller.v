`timescale 1ns / 1ps

module message_controller #(
    parameter CLK_HZ             = 100000000,
    parameter MAX_BYTES          = 160,
    parameter REPEAT_INTERVAL_MS = 500
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] uart_data,
    input  wire       uart_valid,
    input  wire       tx_done,
    output reg        tx_start,
    output reg [7:0]  tx_len,
    output reg [7:0]  tx_byte,
    output reg [7:0]  tx_addr,
    output reg [7:0]  char_count,
    output reg        overflow,
    output reg        busy
);
    localparam [1:0] ST_EDIT        = 2'd0;
    localparam [1:0] ST_LOAD_FRAME  = 2'd1;
    localparam [1:0] ST_WAIT_REPEAT = 2'd2;

    localparam integer REPEAT_TICKS = (CLK_HZ / 1000) * REPEAT_INTERVAL_MS;

    reg [7:0] mem [0:MAX_BYTES-1];
    reg [1:0] state;
    reg [1:0] ff_count;
    reg [7:0] send_index;
    reg [31:0] repeat_cnt;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_start   <= 1'b0;
            tx_len     <= 8'd0;
            tx_byte    <= 8'd0;
            tx_addr    <= 8'd0;
            char_count <= 8'd0;
            overflow   <= 1'b0;
            busy       <= 1'b0;
            state      <= ST_EDIT;
            ff_count   <= 2'd0;
            send_index <= 8'd0;
            repeat_cnt <= 32'd0;
            for (i = 0; i < MAX_BYTES; i = i + 1) begin
                mem[i] <= 8'd0;
            end
        end else begin
            tx_start <= 1'b0;

            if (uart_valid && (uart_data == 8'h18)) begin
                char_count <= 8'd0;
                overflow   <= 1'b0;
                busy       <= 1'b0;
                state      <= ST_EDIT;
                ff_count   <= 2'd0;
                send_index <= 8'd0;
                repeat_cnt <= 32'd0;
            end else begin
                case (state)
                    ST_EDIT: begin
                        busy <= 1'b0;

                        if (uart_valid) begin
                            if (uart_data == 8'hff) begin
                                if (ff_count != 2'd3) begin
                                    ff_count <= ff_count + 2'd1;
                                end
                                if (ff_count == 2'd2 && char_count != 8'd0) begin
                                    busy       <= 1'b1;
                                    state      <= ST_LOAD_FRAME;
                                    tx_len     <= char_count;
                                    tx_byte    <= mem[0];
                                    tx_addr    <= 8'd0;
                                    tx_start   <= 1'b1;
                                    send_index <= 8'd1;
                                    repeat_cnt <= 32'd0;
                                    ff_count   <= 2'd0;
                                end
                            end else begin
                                ff_count <= 2'd0;

                                if ((uart_data == 8'h0d) || (uart_data == 8'h0a)) begin
                                    if (char_count != 8'd0) begin
                                        busy       <= 1'b1;
                                        state      <= ST_LOAD_FRAME;
                                        tx_len     <= char_count;
                                        tx_byte    <= mem[0];
                                        tx_addr    <= 8'd0;
                                        tx_start   <= 1'b1;
                                        send_index <= 8'd1;
                                        repeat_cnt <= 32'd0;
                                    end
                                end else if ((uart_data == 8'h08) || (uart_data == 8'h7f)) begin
                                    if (char_count != 8'd0) begin
                                        char_count <= char_count - 8'd1;
                                    end
                                end else if ((uart_data >= 8'h20) && (uart_data <= 8'h7e)) begin
                                    if (char_count < MAX_BYTES) begin
                                        mem[char_count] <= uart_data;
                                        char_count      <= char_count + 8'd1;
                                    end else begin
                                        overflow <= 1'b1;
                                    end
                                end
                            end
                        end
                    end

                    ST_LOAD_FRAME: begin
                        busy <= 1'b1;

                        if (tx_done) begin
                            if (send_index == tx_len) begin
                                send_index <= 8'd0;
                                repeat_cnt <= 32'd0;
                                state      <= ST_WAIT_REPEAT;
                            end else begin
                                tx_byte    <= mem[send_index];
                                tx_addr    <= send_index;
                                tx_start   <= 1'b1;
                                send_index <= send_index + 8'd1;
                            end
                        end
                    end

                    ST_WAIT_REPEAT: begin
                        busy <= 1'b1;

                        if (char_count == 8'd0) begin
                            busy       <= 1'b0;
                            repeat_cnt <= 32'd0;
                            state      <= ST_EDIT;
                        end else if (repeat_cnt >= (REPEAT_TICKS - 1)) begin
                            if (tx_done) begin
                                tx_len     <= char_count;
                                tx_byte    <= mem[0];
                                tx_addr    <= 8'd0;
                                tx_start   <= 1'b1;
                                send_index <= 8'd1;
                                repeat_cnt <= 32'd0;
                                state      <= ST_LOAD_FRAME;
                            end
                        end else begin
                            repeat_cnt <= repeat_cnt + 32'd1;
                        end
                    end

                    default: begin
                        busy       <= 1'b0;
                        state      <= ST_EDIT;
                        ff_count   <= 2'd0;
                        send_index <= 8'd0;
                        repeat_cnt <= 32'd0;
                    end
                endcase
            end
        end
    end
endmodule
