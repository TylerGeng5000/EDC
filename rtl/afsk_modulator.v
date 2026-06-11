module afsk_modulator #(
    parameter int CLK_HZ = 100_000_000,
    parameter int SAMPLE_RATE = 48_000,
    parameter int BAUD = 1200,
    parameter int MARK_HZ = 1200,
    parameter int SPACE_HZ = 2200,
    parameter int PHASE_W = 24
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        tx_bit,
    input  logic        tx_active,
    output logic        sample_strobe,
    output logic        bit_strobe,
    output logic [11:0] dac_data,
    output logic        dac_wrt,
    output logic        dac_clk
);
    localparam int SAMPLE_DIV = CLK_HZ / SAMPLE_RATE;
    localparam int SAMPLE_CNT_W = $clog2(SAMPLE_DIV + 1);
    localparam int SAMPLES_PER_BIT = SAMPLE_RATE / BAUD;
    localparam int BIT_CNT_W = $clog2(SAMPLES_PER_BIT + 1);
    localparam logic [PHASE_W-1:0] MARK_INC  = (MARK_HZ  * (1 << PHASE_W)) / SAMPLE_RATE;
    localparam logic [PHASE_W-1:0] SPACE_INC = (SPACE_HZ * (1 << PHASE_W)) / SAMPLE_RATE;

    logic [SAMPLE_CNT_W-1:0] sample_cnt;
    logic [BIT_CNT_W-1:0]    bit_sample_cnt;
    logic [PHASE_W-1:0]      phase;
    logic [11:0]             sine_sample;

    afsk_sine_rom u_rom (
        .addr(phase[PHASE_W-1 -: 8]),
        .sample(sine_sample)
    );

    assign dac_clk = clk;

    always_ff @(posedge clk) begin
        if (rst) begin
            sample_cnt <= '0;
            bit_sample_cnt <= '0;
            phase <= '0;
            sample_strobe <= 1'b0;
            bit_strobe <= 1'b0;
            dac_data <= 12'd2048;
            dac_wrt <= 1'b0;
        end else begin
            sample_strobe <= 1'b0;
            bit_strobe <= 1'b0;
            dac_wrt <= 1'b0;

            if (sample_cnt == SAMPLE_DIV - 1) begin
                sample_cnt <= '0;
                sample_strobe <= 1'b1;
                dac_wrt <= 1'b1;

                if (tx_active) begin
                    phase <= phase + (tx_bit ? MARK_INC : SPACE_INC);
                    dac_data <= sine_sample;
                    if (bit_sample_cnt == SAMPLES_PER_BIT - 1) begin
                        bit_sample_cnt <= '0;
                        bit_strobe <= 1'b1;
                    end else begin
                        bit_sample_cnt <= bit_sample_cnt + 1'b1;
                    end
                end else begin
                    bit_sample_cnt <= '0;
                    phase <= '0;
                    dac_data <= 12'd2048;
                end
            end else begin
                sample_cnt <= sample_cnt + 1'b1;
            end
        end
    end
endmodule
