module xfft_1024 (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire [31:0] s_axis_data_tdata,
    input  wire        s_axis_data_tvalid,
    output wire        s_axis_data_tready,
    input  wire        s_axis_data_tlast,
    input  wire [15:0] s_axis_config_tdata,
    input  wire        s_axis_config_tvalid,
    output wire        s_axis_config_tready,
    output wire [31:0] m_axis_data_tdata,
    output wire        m_axis_data_tvalid,
    output wire        m_axis_data_tlast
);
    assign s_axis_data_tready = 1'b0;
    assign s_axis_config_tready = 1'b0;
    assign m_axis_data_tdata = 32'd0;
    assign m_axis_data_tvalid = 1'b0;
    assign m_axis_data_tlast = 1'b0;
endmodule
