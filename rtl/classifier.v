module classifier (
    input  logic        clk,
    input  logic        rst,
    input  logic [10:0] peak_count,
    input  logic        result_valid,
    output logic [1:0]  mode,
    output logic        mode_valid
);
    localparam logic [1:0] MODE_CW = 2'b00;
    localparam logic [1:0] MODE_AM = 2'b01;
    localparam logic [1:0] MODE_FM = 2'b10;

    always_ff @(posedge clk) begin
        if (rst) begin
            mode <= MODE_CW;
            mode_valid <= 1'b0;
        end else begin
            mode_valid <= result_valid;
            if (result_valid) begin
                if (peak_count <= 1) begin
                    mode <= MODE_CW;
                end else if (peak_count <= 3) begin
                    mode <= MODE_AM;
                end else begin
                    mode <= MODE_FM;
                end
            end
        end
    end
endmodule
