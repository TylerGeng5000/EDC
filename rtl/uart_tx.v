`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_HZ = 50000000,
    parameter BAUD   = 9600
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data,
    input  wire       data_valid,
    output reg        tx,
    output wire       busy
);
    localparam integer CLKS_PER_BIT = CLK_HZ / BAUD;

    localparam [1:0] ST_IDLE = 2'd0;
    localparam [1:0] ST_DATA = 2'd1;
    localparam [1:0] ST_STOP = 2'd2;

    reg [1:0] state;
    reg [15:0] clk_cnt;
    reg [2:0] bit_idx;
    reg [7:0] shifter;

    assign busy = (state != ST_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= ST_IDLE;
            clk_cnt <= 16'd0;
            bit_idx <= 3'd0;
            shifter <= 8'd0;
            tx      <= 1'b1;
        end else begin
            case (state)
                ST_IDLE: begin
                    tx      <= 1'b1;
                    clk_cnt <= 16'd0;
                    bit_idx <= 3'd0;
                    if (data_valid) begin
                        shifter <= data;
                        tx      <= 1'b0;
                        state   <= ST_DATA;
                    end
                end

                ST_DATA: begin
                    if (clk_cnt == (CLKS_PER_BIT - 1)) begin
                        clk_cnt <= 16'd0;
                        tx      <= shifter[bit_idx];
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 3'd0;
                            state   <= ST_STOP;
                        end else begin
                            bit_idx <= bit_idx + 3'd1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 16'd1;
                    end
                end

                ST_STOP: begin
                    if (clk_cnt == (CLKS_PER_BIT - 1)) begin
                        clk_cnt <= 16'd0;
                        tx      <= 1'b1;
                        state   <= ST_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 16'd1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
