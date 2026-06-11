module classifier (
    input  wire       clk,
    input  wire       rst,
    input  wire [10:0] peak_count,
    input  wire       result_valid,
    output reg  [1:0] mode,
    output reg        mode_valid
);
    localparam [1:0] MODE_CW = 2'b00;
    localparam [1:0] MODE_AM = 2'b01;
    localparam [1:0] MODE_FM = 2'b10;

    always @(posedge clk) begin
        if (rst) begin
            mode <= MODE_CW;
            mode_valid <= 1'b0;
        end else begin
            mode_valid <= result_valid;
            if (result_valid) begin
                if (peak_count <= 11'd1) begin
                    mode <= MODE_CW;
                end else if (peak_count <= 11'd3) begin
                    mode <= MODE_AM;
                end else begin
                    mode <= MODE_FM;
                end
            end
        end
    end
endmodule
