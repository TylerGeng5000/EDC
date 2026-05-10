module top (
    input  logic        clk_100m,
    input  logic        rst,
    input  logic [11:0] adc_data,
    input  logic        adc_valid,
    output logic [1:0]  mode,
    output logic        mode_valid
);
    logic signed [15:0] sample;
    logic              sample_valid;

    adc_capture u_adc (
        .clk(clk_100m),
        .rst(rst),
        .adc_data(adc_data),
        .adc_valid(adc_valid),
        .sample(sample),
        .sample_valid(sample_valid)
    );

    logic signed [15:0] fft_sample;
    logic              fft_valid;
    logic              fft_last;
    logic              fft_ready;

    frame_buffer #(.N(1024)) u_frame (
        .clk(clk_100m),
        .rst(rst),
        .sample(sample),
        .sample_valid(sample_valid),
        .fft_ready(fft_ready),
        .fft_sample(fft_sample),
        .fft_valid(fft_valid),
        .fft_last(fft_last)
    );

    logic [31:0] s_axis_tdata;
    assign s_axis_tdata = {16'sd0, fft_sample};

    logic [31:0] m_axis_tdata;
    logic        m_axis_tvalid;
    logic        m_axis_tlast;

    fft_wrapper u_fft (
        .clk(clk_100m),
        .rst(rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(fft_valid),
        .s_axis_tlast(fft_last),
        .s_axis_tready(fft_ready),
        .s_axis_config_tdata(16'h0001),
        .s_axis_config_tvalid(1'b1),
        .s_axis_config_tready(),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast)
    );

    logic [10:0] peak_count;
    logic        result_valid;

    feature_extract #(.N(1024)) u_feat (
        .clk(clk_100m),
        .rst(rst),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast),
        .peak_count(peak_count),
        .result_valid(result_valid)
    );

    classifier u_cls (
        .clk(clk_100m),
        .rst(rst),
        .peak_count(peak_count),
        .result_valid(result_valid),
        .mode(mode),
        .mode_valid(mode_valid)
    );
endmodule
