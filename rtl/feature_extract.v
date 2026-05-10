module feature_extract #(
    parameter int N = 1024
) (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] m_axis_tdata,
    input  logic        m_axis_tvalid,
    input  logic        m_axis_tlast,
    output logic [10:0] peak_count,
    output logic        result_valid
);
    typedef enum logic [1:0] {IDLE, CAPTURE, SCAN, DONE} state_t;
    state_t state;

    logic [$clog2(N)-1:0] wr_ptr;
    logic [$clog2(N)-1:0] scan_ptr;
    logic [17:0] max_mag;
    logic [17:0] mag_mem [0:N-1];

    function automatic [15:0] abs16(input logic signed [15:0] v);
        abs16 = v[15] ? (~v + 1'b1) : v;
    endfunction

    wire signed [15:0] re = m_axis_tdata[15:0];
    wire signed [15:0] im = m_axis_tdata[31:16];
    wire [17:0] mag = abs16(re) + abs16(im);

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            wr_ptr <= '0;
            scan_ptr <= '0;
            max_mag <= '0;
            peak_count <= '0;
            result_valid <= 1'b0;
        end else begin
            result_valid <= 1'b0;
            case (state)
                IDLE: begin
                    if (m_axis_tvalid) begin
                        state <= CAPTURE;
                        wr_ptr <= '0;
                        max_mag <= '0;
                    end
                end
                CAPTURE: begin
                    if (m_axis_tvalid) begin
                        mag_mem[wr_ptr] <= mag;
                        if (mag > max_mag) begin
                            max_mag <= mag;
                        end
                        if (m_axis_tlast || wr_ptr == N-1) begin
                            scan_ptr <= '0;
                            peak_count <= '0;
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
                    if (scan_ptr == N-1) begin
                        state <= DONE;
                    end else begin
                        scan_ptr <= scan_ptr + 1'b1;
                    end
                end
                DONE: begin
                    result_valid <= 1'b1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
