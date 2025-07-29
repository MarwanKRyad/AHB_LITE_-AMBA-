vlib work
vlog master.v mastet_tb.v 
vsim -voptargs=+acc work.mastet_tb
add wave -position insertpoint  \
sim:/mastet_tb/HCLK_tb
add wave -position insertpoint  \
sim:/mastet_tb/HREADY_tb
add wave -position insertpoint  \
sim:/mastet_tb/HWRITE_tb
add wave -position insertpoint  \
sim:/mastet_tb/HWDATA_tb
add wave -position insertpoint  \
sim:/mastet_tb/HTRANS_tb
add wave -position insertpoint  \
sim:/mastet_tb/HSIZE_tb
add wave -position insertpoint  \
sim:/mastet_tb/HBURST_tb
add wave -position insertpoint  \
sim:/mastet_tb/HRDATA_tb
add wave -position insertpoint  \
sim:/mastet_tb/HADDR_tb
add wave -position insertpoint  \
sim:/mastet_tb/Dut/trans_shift
run -all