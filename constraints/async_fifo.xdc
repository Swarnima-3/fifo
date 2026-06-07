# async_fifo.xdc

create_clock -name wclk -period 10 [get_ports wclk]    ;# 100 MHz
create_clock -name rclk -period 14 [get_ports rclk]    ;# ~71 MHz

set_clock_groups -asynchronous -group {wclk} -group {rclk}

set_false_path -to [get_cells -hierarchical -filter {NAME =~ *u_sync_*/ff1_reg*}]
