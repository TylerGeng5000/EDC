module adc_capture (
    input  wire              clk,
    input  wire              rst,
    input  wire [11:0]       adc_data,
    input  wire              adc_valid,
    output reg signed [15:0] sample,
    output reg               sample_valid
);
    always @(posedge clk) begin
        if (rst) begin
            sample <= 16'sd0;
            sample_valid <= 1'b0;
        end else begin
            sample_valid <= adc_valid;
            if (adc_valid) begin
                sample <= $signed({1'b0, adc_data}) - 16'sd2048;
            end
        end
    end
endmodule
