vlib work

vlog -sv amm_cdc.sv

vlog -sv amm_cdc_tb.sv

vopt +acc amm_cdc_tb -o top_amm_cdc

vsim top_amm_cdc

do wave.do

run -all

