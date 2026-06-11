# Run from the repository root with:
#   vivado -mode batch -source scripts/create_vivado_project.tcl
# Override device/project values when needed, for example:

#   vivado -mode batch -source scripts/create_vivado_project.tcl -tclargs xc7a100tfgg484-2 cxd720_afsk_sms

set part_name "xc7a100tfgg484-2"

set project_name "cxd720_afsk_sms"
if {$argc >= 1} { set part_name [lindex $argv 0] }
if {$argc >= 2} { set project_name [lindex $argv 1] }

set repo_dir [file normalize [file join [file dirname [info script]] ".."]]
set build_dir [file join $repo_dir "vivado_build" $project_name]
file mkdir $build_dir

create_project $project_name $build_dir -part $part_name -force
set_property target_language Verilog [current_project]

add_files -norecurse [glob [file join $repo_dir rtl *.v]]
add_files -fileset constrs_1 -norecurse [file join $repo_dir constr cxd720_afsk_sms.xdc]
set_property top cxd720_afsk_sms_top [current_fileset]
update_compile_order -fileset sources_1

puts "Created Vivado project $project_name for part $part_name"
puts "Open $build_dir/$project_name.xpr and edit constr/cxd720_afsk_sms.xdc with CXD720 package pins before implementation."
