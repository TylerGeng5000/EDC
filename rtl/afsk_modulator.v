module afsk_modulator #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer SAMPLE_RATE = 48_000,
    parameter integer BAUD = 1200,
    parameter integer MARK_HZ = 1200,
    parameter integer SPACE_HZ = 2200,
    parameter integer PHASE_W = 24
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_bit,
    input  wire       tx_active,
    output reg        sample_strobe,
    output reg        bit_strobe,
    output reg [11:0] dac_data,
    output reg        dac_wrt,
    output wire       dac_clk
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

    localparam integer SAMPLE_DIV = CLK_HZ / SAMPLE_RATE;
    localparam integer SAMPLE_CNT_W = clog2(SAMPLE_DIV + 1);
    localparam integer SAMPLES_PER_BIT = SAMPLE_RATE / BAUD;
    localparam integer BIT_CNT_W = clog2(SAMPLES_PER_BIT + 1);
    localparam [PHASE_W-1:0] MARK_INC  = (MARK_HZ  * (1 << PHASE_W)) / SAMPLE_RATE;
    localparam [PHASE_W-1:0] SPACE_INC = (SPACE_HZ * (1 << PHASE_W)) / SAMPLE_RATE;

    reg [SAMPLE_CNT_W-1:0] sample_cnt;
    reg [BIT_CNT_W-1:0]    bit_sample_cnt;
    reg [PHASE_W-1:0]      phase;
    wire [11:0]            sine_sample;

    afsk_sine_rom u_rom (
        .addr(phase[PHASE_W-1 -: 8]),
        .sample(sine_sample)
    );

    assign dac_clk = clk;

    always @(posedge clk) begin
        if (rst) begin
            sample_cnt <= {SAMPLE_CNT_W{1'b0}};
            bit_sample_cnt <= {BIT_CNT_W{1'b0}};
            phase <= {PHASE_W{1'b0}};
            sample_strobe <= 1'b0;
            bit_strobe <= 1'b0;
            dac_data <= 12'd2048;
            dac_wrt <= 1'b0;
        end else begin
            sample_strobe <= 1'b0;
            bit_strobe <= 1'b0;
            dac_wrt <= 1'b0;

            if (sample_cnt == (SAMPLE_DIV - 1)) begin
                sample_cnt <= {SAMPLE_CNT_W{1'b0}};
                sample_strobe <= 1'b1;
                dac_wrt <= 1'b1;

                if (tx_active) begin
                    phase <= phase + (tx_bit ? MARK_INC : SPACE_INC);
                    dac_data <= sine_sample;
                    if (bit_sample_cnt == (SAMPLES_PER_BIT - 1)) begin
                        bit_sample_cnt <= {BIT_CNT_W{1'b0}};
                        bit_strobe <= 1'b1;
                    end else begin
                        bit_sample_cnt <= bit_sample_cnt + 1'b1;
                    end
                end else begin
                    bit_sample_cnt <= {BIT_CNT_W{1'b0}};
                    phase <= {PHASE_W{1'b0}};
                    dac_data <= 12'd2048;
                end
            end else begin
                sample_cnt <= sample_cnt + 1'b1;
            end
        end
    end
endmodule
