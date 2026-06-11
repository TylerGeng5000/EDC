module feature_extract #(
    parameter integer N = 1024
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] m_axis_tdata,
    input  wire        m_axis_tvalid,
    input  wire        m_axis_tlast,
    output reg  [10:0] peak_count,
    output reg         result_valid
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

    function [15:0] abs16;
        input signed [15:0] v;
        begin
            abs16 = v[15] ? (~v + 1'b1) : v;
        end
    endfunction

    localparam [1:0] IDLE    = 2'd0;
    localparam [1:0] CAPTURE = 2'd1;
    localparam [1:0] SCAN    = 2'd2;
    localparam [1:0] DONE    = 2'd3;
    localparam integer ADDR_W = clog2(N);

    reg [1:0] state;
    reg [ADDR_W-1:0] wr_ptr;
    reg [ADDR_W-1:0] scan_ptr;
    reg [17:0] max_mag;
    reg [17:0] mag_mem [0:N-1];

    wire signed [15:0] re;
    wire signed [15:0] im;
    wire [17:0] mag;

    assign re = m_axis_tdata[15:0];
    assign im = m_axis_tdata[31:16];
    assign mag = abs16(re) + abs16(im);

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            wr_ptr <= {ADDR_W{1'b0}};
            scan_ptr <= {ADDR_W{1'b0}};
            max_mag <= 18'd0;
            peak_count <= 11'd0;
            result_valid <= 1'b0;
        end else begin
            result_valid <= 1'b0;
            case (state)
                IDLE: begin
                    if (m_axis_tvalid) begin
                        state <= CAPTURE;
                        wr_ptr <= {ADDR_W{1'b0}};
                        max_mag <= 18'd0;
                    end
                end

                CAPTURE: begin
                    if (m_axis_tvalid) begin
                        mag_mem[wr_ptr] <= mag;
                        if (mag > max_mag) begin
                            max_mag <= mag;
                        end
                        if (m_axis_tlast || wr_ptr == (N - 1)) begin
                            scan_ptr <= {ADDR_W{1'b0}};
                            peak_count <= 11'd0;
                            state <= SCAN;
                        end else begin
                            wr_ptr <= wr_ptr + 1'b1;
                        end
                    end
                end

                SCAN: begin
                    if (mag_mem[scan_ptr] > (max_mag >> 2)) begin
                        peak_count <= peak_count + 1'b1;
                    end
                    if (scan_ptr == (N - 1)) begin
                        state <= DONE;
                    end else begin
                        scan_ptr <= scan_ptr + 1'b1;
                    end
                end

                DONE: begin
                    result_valid <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
