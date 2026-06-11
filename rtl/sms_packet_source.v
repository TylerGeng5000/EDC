module sms_packet_source #(
    parameter int MAX_CHARS = 26,
    parameter int PREAMBLE_BYTES = 8
) (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] uart_data,
    input  logic       uart_valid,
    input  logic       bit_strobe,
    output logic       tx_bit,
    output logic       tx_active,
    output logic       msg_ready,
    output logic       overflow,
    output logic [4:0] char_count
);
    typedef enum logic [2:0] {RX_IDLE, TX_PREAMBLE, TX_SYNC, TX_LEN, TX_PAYLOAD, TX_CRC, TX_END} state_t;
    state_t state;

    logic [7:0] msg_mem [0:MAX_CHARS-1];
    logic [7:0] shift_reg;
    logic [2:0] bit_idx;
    logic [$clog2(PREAMBLE_BYTES+1)-1:0] preamble_idx;
    logic [$clog2(MAX_CHARS+1)-1:0] rd_idx;
    logic [7:0] crc;
    logic [7:0] latched_len;
    localparam logic [4:0] MAX_CHARS_5 = MAX_CHARS;
    localparam logic [7:0] MAX_CHARS_8 = MAX_CHARS;

    function automatic logic is_letter(input logic [7:0] ch);
        is_letter = ((ch >= "A") && (ch <= "Z")) || ((ch >= "a") && (ch <= "z"));
    endfunction

    function automatic logic is_end(input logic [7:0] ch);
        is_end = (ch == 8'h0d) || (ch == 8'h0a) || (ch == 8'hff);
    endfunction

    function automatic logic [7:0] to_upper(input logic [7:0] ch);
        to_upper = ((ch >= "a") && (ch <= "z")) ? (ch - 8'd32) : ch;
    endfunction

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= RX_IDLE;
            shift_reg <= 8'h00;
            bit_idx <= 3'd7;
            preamble_idx <= '0;
            rd_idx <= '0;
            crc <= 8'h00;
            latched_len <= 8'h00;
            tx_bit <= 1'b1;
            tx_active <= 1'b0;
            msg_ready <= 1'b0;
            overflow <= 1'b0;
            char_count <= '0;
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
                            preamble_idx <= '0;
                            rd_idx <= '0;
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
                    if (char_count != 0) begin
                        char_count <= char_count - 1'b1;
                    end
                end else if (is_end(uart_data) && (char_count != 0)) begin
                    state <= TX_PREAMBLE;
                    tx_active <= 1'b1;
                    msg_ready <= 1'b1;
                    preamble_idx <= '0;
                    rd_idx <= '0;
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
                    char_count <= '0;
                    shift_reg <= 8'h00;
                end else begin
                    tx_bit <= shift_reg[bit_idx];
                    if (bit_idx != 0) begin
                    bit_idx <= bit_idx - 1'b1;
                end else begin
                    bit_idx <= 3'd7;
                    case (state)
                        TX_PREAMBLE: begin
                            if (preamble_idx == PREAMBLE_BYTES - 1) begin
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
                            rd_idx <= 1;
                        end

                        TX_PAYLOAD: begin
                            if (rd_idx == latched_len) begin
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

                        default: state <= RX_IDLE;
                    endcase
                end
            end
        end
    end
endmodule
