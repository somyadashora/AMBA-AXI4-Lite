force -freeze sim:/AXI_top/ACLK 1 2, 0 {52 ns} -r 100
force -freeze sim:/AXI_top/ARESETn 0 0
force -freeze sim:/AXI_top/awaddr 32'h00000001 0
force -freeze sim:/AXI_top/araddr 32'H00000000 0
force -freeze sim:/AXI_top/wdata 32'hcdaccafe 0
force -freeze sim:/AXI_top/mstr/wstrb 1111 0
run
force -freeze sim:/AXI_top/ARESETn 1 0
run
run
run
run
force -freeze sim:/AXI_top/araddr 32'H00000001 0
force -freeze sim:/AXI_top/mstr/wstrb 0001 0
run
force -freeze sim:/AXI_top/mstr/wstrb 0010 0
run
force -freeze sim:/AXI_top/mstr/wstrb 0011 0
run
force -freeze sim:/AXI_top/mstr/wstrb 0100 0
run
force -freeze sim:/AXI_top/mstr/wstrb 0100 0
run

run
run
run
run
run
run
run
run
run
run
run
run