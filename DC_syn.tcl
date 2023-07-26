#Read All Files
read_verilog STI_DAC.v
current_design STI_DAC
link

#Setting Clock Constraints
source -echo -verbose STI_DAC.sdc

#Synthesis all design
compile -map_effort high -area_effort high
compile -map_effort high -area_effort high -inc
#compile_ultra

write -format ddc     -hierarchy -output "STI_DAC_syn.ddc"
write_sdf STI_DAC_syn.sdf
write_file -format verilog -hierarchy -output STI_DAC_syn.v
report_area > area.log
report_timing > timing.log
report_qor   >  STI_DAC_syn.qor

