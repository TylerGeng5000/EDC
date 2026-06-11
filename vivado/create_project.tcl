# Run from repository root:
# vivado -mode batch -source vivado/create_project.tcl

set proj_name cxd720_afsk_sms
set proj_dir  ./build/$proj_name

create_project $proj_name $proj_dir -force
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]

add_files -fileset sources_1 [list \
    rtl/uart_rx.v \
    rtl/sms_packet_source.v \
    rtl/afsk_sine_rom.v \
    rtl/afsk_modulator.v \
    rtl/top.v \
]

set_property top top [current_fileset]
add_files -fileset constrs_1 constraints/cxd720_afsk_template.xdc

puts "Project created. Set the exact CXD720 FPGA part/board in Vivado before synthesis if needed."
