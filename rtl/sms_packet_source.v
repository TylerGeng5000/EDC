module sms_packet_source #(
    parameter integer MAX_CHARS = 26,
    parameter integer PREAMBLE_BYTES = 8
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] uart_data,
    input  wire       uart_valid,
    input  wire       bit_strobe,
    output reg        tx_bit,
    output reg        tx_active,
    output reg        msg_ready,
    output reg        overflow,
    output reg  [4:0] char_count
);
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1) begin
                clog2 = clog2 + 1;
            end
        end
    endfunction

    localparam [2:0] RX_IDLE     = 3'd0;
    localparam [2:0] TX_PREAMBLE = 3'd1;
    localparam [2:0] TX_SYNC     = 3'd2;
    localparam [2:0] TX_LEN      = 3'd3;
    localparam [2:0] TX_PAYLOAD  = 3'd4;
    localparam [2:0] TX_CRC      = 3'd5;
    localparam [2:0] TX_END      = 3'd6;

    localparam [4:0] MAX_CHARS_5 = MAX_CHARS;
    localparam [7:0] MAX_CHARS_8 = MAX_CHARS;
    localparam integer PREAMBLE_W = clog2(PREAMBLE_BYTES + 1);
    localparam integer RD_W = clog2(MAX_CHARS + 1);

    reg [2:0] state;
    reg [7:0] msg_mem [0:MAX_CHARS-1];
    reg [7:0] shift_reg;
    reg [2:0] bit_idx;
    reg [PREAMBLE_W-1:0] preamble_idx;
    reg [RD_W-1:0] rd_idx;
    reg [7:0] crc;
    reg [7:0] latched_len;

    function is_letter;
        input [7:0] ch;
        begin
            is_letter = ((ch >= "A") && (ch <= "Z")) || ((ch >= "a") && (ch <= "z"));
        end
    endfunction

    function is_end;
        input [7:0] ch;
        begin
            is_end = (ch == 8'h0d) || (ch == 8'h0a) || (ch == 8'hff);
        end
    endfunction

    function [7:0] to_upper;
        input [7:0] ch;
        begin
            to_upper = ((ch >= "a") && (ch <= "z")) ? (ch - 8'd32) : ch;
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state <= RX_IDLE;
            shift_reg <= 8'h00;
            bit_idx <= 3'd7;
            preamble_idx <= {PREAMBLE_W{1'b0}};
            rd_idx <= {RD_W{1'b0}};
            crc <= 8'h00;
            latched_len <= 8'h00;
            tx_bit <= 1'b1;
            tx_active <= 1'b0;
            msg_ready <= 1'b0;
            overflow <= 1'b0;
            char_count <= 5'd0;
        end else begin
            msg_ready <= 1'b0;
            overflow <= 1'b0;

            if (state == RX_IDLE && uart_valid) begin
                if (is_letter(uart_data)) begin
                    if (char_count < MAX_CHARS_5) begin
                        msg_mem[char_count] <= to_upper(uart_data);
                        if (char_count == (MAX_CHARS_5 - 1'b1)) begin
                            state <= TX_PREAMBLE;
                            tx_active <= 1'b1;
                            msg_ready <= 1'b1;
                            preamble_idx <= {PREAMBLE_W{1'b0}};
                            rd_idx <= {RD_W{1'b0}};
                            latched_len <= MAX_CHARS_8;
                            crc <= MAX_CHARS_8;
                            char_count <= MAX_CHARS_5;
                            shift_reg <= 8'h55;
                            tx_bit <= 1'b0;
                            bit_idx <= 3'd6;
                        end else begin
                            char_count <= char_count + 1'b1;
                        end
                    end else begin
                        overflow <= 1'b1;
                    end
                end else if ((uart_data == 8'h08) || (uart_data == 8'h7f)) begin
                    if (char_count != 5'd0) begin
                        char_count <= char_count - 1'b1;
                    end
                end else if (is_end(uart_data) && (char_count != 5'd0)) begin
                    state <= TX_PREAMBLE;
                    tx_active <= 1'b1;
                    msg_ready <= 1'b1;
                    preamble_idx <= {PREAMBLE_W{1'b0}};
                    rd_idx <= {RD_W{1'b0}};
                    latched_len <= {3'b000, char_count};
                    crc <= {3'b000, char_count};
                    shift_reg <= 8'h55;
                    tx_bit <= 1'b0;
                    bit_idx <= 3'd6;
                end
            end else if (tx_active && bit_strobe) begin
                if (state == TX_END) begin
                    state <= RX_IDLE;
                    tx_active <= 1'b0;
                    tx_bit <= 1'b1;
                    char_count <= 5'd0;
                    shift_reg <= 8'h00;
                end else begin
                    tx_bit <= shift_reg[bit_idx];
                    if (bit_idx != 3'd0) begin
                        bit_idx <= bit_idx - 1'b1;
                    end else begin
                        bit_idx <= 3'd7;
                        case (state)
                            TX_PREAMBLE: begin
                                if (preamble_idx == (PREAMBLE_BYTES - 1)) begin
                                    state <= TX_SYNC;
                                    shift_reg <= 8'h7e;
                                end else begin
                                    preamble_idx <= preamble_idx + 1'b1;
                                    shift_reg <= 8'h55;
                                end
                            end

                            TX_SYNC: begin
                                state <= TX_LEN;
                                shift_reg <= latched_len;
                            end

                            TX_LEN: begin
                                state <= TX_PAYLOAD;
                                shift_reg <= msg_mem[0];
                                crc <= crc ^ msg_mem[0];
                                rd_idx <= {{(RD_W-1){1'b0}}, 1'b1};
                            end

                            TX_PAYLOAD: begin
                                if (rd_idx == latched_len[RD_W-1:0]) begin
                                    state <= TX_CRC;
                                    shift_reg <= crc;
                                end else begin
                                    shift_reg <= msg_mem[rd_idx];
                                    crc <= crc ^ msg_mem[rd_idx];
                                    rd_idx <= rd_idx + 1'b1;
                                end
                            end

                            TX_CRC: begin
                                state <= TX_END;
                                shift_reg <= 8'h00;
                            end

                            default: begin
                                state <= RX_IDLE;
                            end
                        endcase
                    end
                end
            end
        end
    end
endmodule
