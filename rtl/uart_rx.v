module uart_rx #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer BAUD = 9600
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        data_valid,
    output reg        frame_error
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

    localparam integer CLKS_PER_BIT = CLK_HZ / BAUD;
    localparam integer HALF_BIT = CLKS_PER_BIT / 2;
    localparam integer CNT_W = clog2(CLKS_PER_BIT + 1);

    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] START = 2'd1;
    localparam [1:0] DATA  = 2'd2;
    localparam [1:0] STOP  = 2'd3;

    reg [1:0]       state;
    reg [CNT_W-1:0] clk_cnt;
    reg [2:0]       bit_idx;
    reg [7:0]       shreg;
    reg             rx_meta;
    reg             rx_sync;

    always @(posedge clk) begin
        if (rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            clk_cnt <= {CNT_W{1'b0}};
            bit_idx <= 3'd0;
            shreg <= 8'h00;
            data <= 8'h00;
            data_valid <= 1'b0;
            frame_error <= 1'b0;
        end else begin
            data_valid <= 1'b0;
            frame_error <= 1'b0;

            case (state)
                IDLE: begin
                    clk_cnt <= {CNT_W{1'b0}};
                    bit_idx <= 3'd0;
                    if (!rx_sync) begin
                        state <= START;
                    end
                end

                START: begin
                    if (clk_cnt == HALF_BIT) begin
                        if (!rx_sync) begin
                            clk_cnt <= {CNT_W{1'b0}};
                            state <= DATA;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                DATA: begin
                    if (clk_cnt == (CLKS_PER_BIT - 1)) begin
                        clk_cnt <= {CNT_W{1'b0}};
                        shreg <= {rx_sync, shreg[7:1]};
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 3'd0;
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                STOP: begin
                    if (clk_cnt == (CLKS_PER_BIT - 1)) begin
                        state <= IDLE;
                        clk_cnt <= {CNT_W{1'b0}};
                        if (rx_sync) begin
                            data <= shreg;
                            data_valid <= 1'b1;
                        end else begin
                            frame_error <= 1'b1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
