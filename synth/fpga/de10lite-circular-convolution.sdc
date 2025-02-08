## Generated SDC file "de10lite-circular-convolution.out.sdc"

## Copyright (C) 2022  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 21.1.1 Build 850 06/23/2022 SJ Lite Edition"

## DATE    "Sat Feb  8 18:32:06 2025"

##
## DEVICE  "10M50DAF484C6GES"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -period "50.0 MHz" [get_ports MAX10_CLK1_50]

#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

derive_clock_uncertainty

#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_ports {KEY[*]}]  -to [all_clocks]
set_false_path -from [get_ports {SW[*]}]   -to [all_clocks]
set_false_path -from [get_ports {GPIO[*]}] -to [all_clocks]

set_false_path -from * -to [get_ports {LEDR[*]}]
set_false_path -from * -to [get_ports {HEX*}]
set_false_path -from * -to [get_ports {VGA*}]
set_false_path -from * -to [get_ports {GPIO[*]}]

#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

