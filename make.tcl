vlib work

vlog -sv -f files

vopt +acc amm_cdc_tb -o top_amm_cdc

vsim top_amm_cdc

do wave.do

run -all

