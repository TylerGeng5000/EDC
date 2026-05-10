module adc_capture (
    input  logic        clk,
    input  logic        rst,
    input  logic [11:0] adc_data,
    input  logic        adc_valid,
    output logic signed [15:0] sample,
    output logic        sample_valid
);
    always_ff @(posedge clk) begin
        if (rst) begin
            sample <= '0;
            sample_valid <= 1'b0;
        end else begin
            sample_valid <= adc_valid;
            if (adc_valid) begin
                sample <= $signed({1'b0, adc_data}) - 16'sd2048;
            end
        end
    end
endmodule
