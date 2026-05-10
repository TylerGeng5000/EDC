module fft_wrapper (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] s_axis_tdata,
    input  logic        s_axis_tvalid,
    input  logic        s_axis_tlast,
    output logic        s_axis_tready,
    input  logic [15:0] s_axis_config_tdata,
    input  logic        s_axis_config_tvalid,
    output logic        s_axis_config_tready,
    output logic [31:0] m_axis_tdata,
    output logic        m_axis_tvalid,
    output logic        m_axis_tlast
);
    // Replace xfft_1024 with your generated Xilinx FFT IP name.
    xfft_1024 u_fft (
        .aclk(clk),
        .aresetn(~rst),
        .s_axis_data_tdata(s_axis_tdata),
        .s_axis_data_tvalid(s_axis_tvalid),
        .s_axis_data_tready(s_axis_tready),
        .s_axis_data_tlast(s_axis_tlast),
        .s_axis_config_tdata(s_axis_config_tdata),
        .s_axis_config_tvalid(s_axis_config_tvalid),
        .s_axis_config_tready(s_axis_config_tready),
        .m_axis_data_tdata(m_axis_tdata),
        .m_axis_data_tvalid(m_axis_tvalid),
        .m_axis_data_tlast(m_axis_tlast)
    );
endmodule
