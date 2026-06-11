module uart_rx #(
    parameter int CLK_HZ = 100_000_000,
    parameter int BAUD = 9600
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       rx,
    output logic [7:0] data,
    output logic       data_valid,
    output logic       frame_error
);
    localparam int CLKS_PER_BIT = CLK_HZ / BAUD;
    localparam int HALF_BIT = CLKS_PER_BIT / 2;
    localparam int CNT_W = $clog2(CLKS_PER_BIT + 1);

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;

    logic [CNT_W-1:0] clk_cnt;
    logic [2:0]       bit_idx;
    logic [7:0]       shreg;
    logic             rx_meta;
    logic             rx_sync;

    always_ff @(posedge clk) begin
        if (rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            clk_cnt <= '0;
            bit_idx <= '0;
            shreg <= 8'h00;
            data <= 8'h00;
            data_valid <= 1'b0;
            frame_error <= 1'b0;
        end else begin
            data_valid <= 1'b0;
            frame_error <= 1'b0;

            case (state)
                IDLE: begin
                    clk_cnt <= '0;
                    bit_idx <= '0;
                    if (!rx_sync) begin
                        state <= START;
                    end
                end

                START: begin
                    if (clk_cnt == HALF_BIT) begin
                        if (!rx_sync) begin
                            clk_cnt <= '0;
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
                        clk_cnt <= '0;
                        shreg <= {rx_sync, shreg[7:1]};
                        if (bit_idx == 3'd7) begin
                            bit_idx <= '0;
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
                        clk_cnt <= '0;
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

                default: state <= IDLE;
            endcase
        end
    end
endmodule
