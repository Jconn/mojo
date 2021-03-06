set projDir "C:/Users/John/Documents/mojo/PotentioLED-V/work/planAhead"
set projName "PotentioLED-V"
set topName top
set device xc6slx9-2tqg144
if {[file exists "$projDir/$projName"]} { file delete -force "$projDir/$projName" }
create_project $projName "$projDir/$projName" -part $device
set_property design_mode RTL [get_filesets sources_1]
set verilogSources [list "C:/Users/John/Documents/mojo/PotentioLED-V/work/verilog/mojo_top_0.v" "C:/Users/John/Documents/mojo/PotentioLED-V/work/verilog/avr_interface_1.v" "C:/Users/John/Documents/mojo/PotentioLED-V/work/verilog/input_capture_2.v" "C:/Users/John/Documents/mojo/PotentioLED-V/work/verilog/spi_master_3.v" "C:/Users/John/Documents/mojo/PotentioLED-V/work/verilog/cclk_detector_4.v" "C:/Users/John/Documents/mojo/PotentioLED-V/work/verilog/spi_slave_5.v" "C:/Users/John/Documents/mojo/PotentioLED-V/work/verilog/serial_rx_6.v" "C:/Users/John/Documents/mojo/PotentioLED-V/work/verilog/serial_tx_7.v" "C:/Users/John/Documents/mojo/PotentioLED-V/work/verilog/pwm_8.v"]
import_files -fileset [get_filesets sources_1] -force -norecurse $verilogSources
set ucfSources [list "C:/Users/John/Documents/mojo/PotentioLED-V/constraint/mojo.ucf"]
import_files -fileset [get_filesets constrs_1] -force -norecurse $ucfSources
set coreSources [list "C:/Users/John/Documents/mojo/PotentioLED-V/coreGen/dds_compiler_v5_0.ngc" "C:/Users/John/Documents/mojo/PotentioLED-V/coreGen/dds_compiler_v5_0.v"]
import_files -fileset [get_filesets sources_1] -force -norecurse $coreSources
set_property -name {steps.bitgen.args.More Options} -value {-g Binary:Yes -g Compress} -objects [get_runs impl_1]
set_property steps.map.args.mt on [get_runs impl_1]
set_property steps.map.args.pr b [get_runs impl_1]
set_property steps.par.args.mt on [get_runs impl_1]
update_compile_order -fileset sources_1
launch_runs -runs synth_1
wait_on_run synth_1
launch_runs -runs impl_1
wait_on_run impl_1
launch_runs impl_1 -to_step Bitgen
wait_on_run impl_1
