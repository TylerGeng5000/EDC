module frame_buffer #(
    parameter int N = 1024
) (
    input  logic              clk,
    input  logic              rst,
    input  logic signed [15:0] sample,
    input  logic              sample_valid,
    input  logic              fft_ready,
    output logic signed [15:0] fft_sample,
    output logic              fft_valid,
    output logic              fft_last
);
    typedef enum logic [0:0] {CAPTURE, OUTPUT} state_t;
    state_t state;

    logic [$clog2(N)-1:0] wr_ptr;
    logic [$clog2(N)-1:0] rd_ptr;
    logic signed [15:0] mem [0:N-1];

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= CAPTURE;
            wr_ptr <= '0;
            rd_ptr <= '0;
            fft_valid <= 1'b0;
            fft_last <= 1'b0;
        end else begin
            fft_valid <= 1'b0;
            fft_last <= 1'b0;
            case (state)
                CAPTURE: begin
                    if (sample_valid) begin
                        mem[wr_ptr] <= sample;
                        if (wr_ptr == N-1) begin
                            wr_ptr <= '0;
                            rd_ptr <= '0;
                            state <= OUTPUT;
                        end else begin
                            wr_ptr <= wr_ptr + 1'b1;
                        end
                    end
                end
                OUTPUT: begin
                    if (fft_ready) begin
                        fft_sample <= mem[rd_ptr];
                        fft_valid <= 1'b1;
                        fft_last <= (rd_ptr == N-1);
                        if (rd_ptr == N-1) begin
                            rd_ptr <= '0;
                            state <= CAPTURE;
                        end else begin
                            rd_ptr <= rd_ptr + 1'b1;
                        end
                    end
                end
                default: state <= CAPTURE;
            endcase
        end
    end
endmodule
