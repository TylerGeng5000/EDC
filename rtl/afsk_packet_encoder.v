`timescale 1ns / 1ps

module afsk_packet_encoder #(
    parameter MAX_BYTES      = 160,
    parameter PREAMBLE_BYTES = 16
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] msg_len,
    input  wire [7:0] msg_addr,
    input  wire [7:0] msg_data,
    input  wire       msg_valid,
    output wire       msg_ready,
    input  wire       bit_tick,
    output reg        tx_active,
    output reg        bit_value,
    output reg        packet_done
);
    localparam [2:0] ST_IDLE     = 3'd0;
    localparam [2:0] ST_PREAMBLE = 3'd1;
    localparam [2:0] ST_SYNC     = 3'd2;
    localparam [2:0] ST_LENGTH   = 3'd3;
    localparam [2:0] ST_PAYLOAD  = 3'd4;
    localparam [2:0] ST_CHECKSUM = 3'd5;

    reg [7:0] payload [0:MAX_BYTES-1];
    reg [2:0] state;
    reg [7:0] expected_len;
    reg [7:0] checksum;
    reg [7:0] byte_data;
    reg [2:0] bit_idx;
    reg [7:0] byte_idx;
    reg [7:0] preamble_idx;
    reg [7:0] next_byte;
    reg       loading;

    integer i;

    assign msg_ready = (state == ST_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= ST_IDLE;
            expected_len <= 8'd0;
            checksum     <= 8'd0;
            byte_data    <= 8'd0;
            bit_idx      <= 3'd0;
            byte_idx     <= 8'd0;
            preamble_idx <= 8'd0;
            tx_active    <= 1'b0;
            bit_value    <= 1'b1;
            packet_done  <= 1'b0;
            loading      <= 1'b0;
            for (i = 0; i < MAX_BYTES; i = i + 1) begin
                payload[i] <= 8'd0;
            end
        end else begin
            packet_done <= 1'b0;

            if (state == ST_IDLE) begin
                tx_active <= 1'b0;
                bit_value <= 1'b1;

                if (msg_valid && msg_ready) begin
                    payload[msg_addr] <= msg_data;
                    expected_len      <= msg_len;
                    loading           <= 1'b1;
                    if (msg_addr == 8'd0) begin
                        checksum <= msg_data;
                    end else begin
                        checksum <= checksum ^ msg_data;
                    end

                    if ((msg_addr + 8'd1) == msg_len) begin
                        loading      <= 1'b0;
                        tx_active    <= 1'b1;
                        state        <= ST_PREAMBLE;
                        byte_data    <= 8'h55;
                        bit_value    <= 1'b1;
                        bit_idx      <= 3'd0;
                        preamble_idx <= 8'd0;
                        byte_idx     <= 8'd0;
                    end
                end
            end else if (bit_tick) begin
                if (bit_idx != 3'd7) begin
                    bit_idx   <= bit_idx + 3'd1;
                    bit_value <= byte_data[bit_idx + 3'd1];
                end else begin
                    bit_idx <= 3'd0;
                    case (state)
                        ST_PREAMBLE: begin
                            if (preamble_idx == (PREAMBLE_BYTES - 1)) begin
                                next_byte    = 8'h7e;
                                preamble_idx <= 8'd0;
                                state        <= ST_SYNC;
                            end else begin
                                next_byte    = 8'h55;
                                preamble_idx <= preamble_idx + 8'd1;
                            end
                            byte_data <= next_byte;
                            bit_value <= next_byte[0];
                        end

                        ST_SYNC: begin
                            next_byte  = expected_len;
                            byte_data  <= next_byte;
                            bit_value  <= next_byte[0];
                            state      <= ST_LENGTH;
                        end

                        ST_LENGTH: begin
                            next_byte  = payload[0];
                            byte_data  <= next_byte;
                            bit_value  <= next_byte[0];
                            byte_idx   <= 8'd0;
                            state      <= ST_PAYLOAD;
                        end

                        ST_PAYLOAD: begin
                            if ((byte_idx + 8'd1) == expected_len) begin
                                next_byte = checksum;
                                byte_idx  <= 8'd0;
                                state     <= ST_CHECKSUM;
                            end else begin
                                next_byte = payload[byte_idx + 8'd1];
                                byte_idx  <= byte_idx + 8'd1;
                            end
                            byte_data <= next_byte;
                            bit_value <= next_byte[0];
                        end

                        ST_CHECKSUM: begin
                            tx_active   <= 1'b0;
                            bit_value   <= 1'b1;
                            packet_done <= 1'b1;
                            state       <= ST_IDLE;
                        end

                        default: state <= ST_IDLE;
                    endcase
                end
            end
        end
    end
endmodule
