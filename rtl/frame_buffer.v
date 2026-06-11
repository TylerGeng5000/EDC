module frame_buffer #(
    parameter integer N = 1024
) (
    input  wire               clk,
    input  wire               rst,
    input  wire signed [15:0] sample,
    input  wire               sample_valid,
    input  wire               fft_ready,
    output reg signed [15:0]  fft_sample,
    output reg                fft_valid,
    output reg                fft_last
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

    localparam CAPTURE = 1'b0;
    localparam OUTPUT  = 1'b1;
    localparam integer ADDR_W = clog2(N);

    reg state;
    reg [ADDR_W-1:0] wr_ptr;
    reg [ADDR_W-1:0] rd_ptr;
    reg signed [15:0] mem [0:N-1];

    always @(posedge clk) begin
        if (rst) begin
            state <= CAPTURE;
            wr_ptr <= {ADDR_W{1'b0}};
            rd_ptr <= {ADDR_W{1'b0}};
            fft_sample <= 16'sd0;
            fft_valid <= 1'b0;
            fft_last <= 1'b0;
        end else begin
            fft_valid <= 1'b0;
            fft_last <= 1'b0;
            case (state)
                CAPTURE: begin
                    if (sample_valid) begin
                        mem[wr_ptr] <= sample;
                        if (wr_ptr == (N - 1)) begin
                            wr_ptr <= {ADDR_W{1'b0}};
                            rd_ptr <= {ADDR_W{1'b0}};
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
                        fft_last <= (rd_ptr == (N - 1));
                        if (rd_ptr == (N - 1)) begin
                            rd_ptr <= {ADDR_W{1'b0}};
                            state <= CAPTURE;
                        end else begin
                            rd_ptr <= rd_ptr + 1'b1;
                        end
                    end
                end
            endcase
        end
    end
endmodule
