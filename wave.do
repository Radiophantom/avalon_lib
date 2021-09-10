onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider -height 28 {Master interface}
add wave -noupdate /amm_cdc_tb/amm_master_if/clk
add wave -noupdate /amm_cdc_tb/amm_master_if/rst
add wave -noupdate -divider {common signals}
add wave -noupdate /amm_cdc_tb/amm_master_if/address
add wave -noupdate /amm_cdc_tb/amm_master_if/burstcount
add wave -noupdate /amm_cdc_tb/amm_master_if/byteenable
add wave -noupdate /amm_cdc_tb/amm_master_if/waitrequest
add wave -noupdate -divider {write signals}
add wave -noupdate /amm_cdc_tb/amm_master_if/write
add wave -noupdate /amm_cdc_tb/amm_master_if/writedata
add wave -noupdate -divider {read signals}
add wave -noupdate /amm_cdc_tb/amm_master_if/read
add wave -noupdate /amm_cdc_tb/amm_master_if/readdatavalid
add wave -noupdate /amm_cdc_tb/amm_master_if/readdata
add wave -noupdate -divider -height 28 {Slave interface}
add wave -noupdate /amm_cdc_tb/amm_slave_if/clk
add wave -noupdate /amm_cdc_tb/amm_slave_if/rst
add wave -noupdate -divider {common signals}
add wave -noupdate /amm_cdc_tb/amm_slave_if/address
add wave -noupdate /amm_cdc_tb/amm_slave_if/burstcount
add wave -noupdate /amm_cdc_tb/amm_slave_if/byteenable
add wave -noupdate /amm_cdc_tb/amm_slave_if/waitrequest
add wave -noupdate -divider {write signals}
add wave -noupdate /amm_cdc_tb/amm_slave_if/write
add wave -noupdate /amm_cdc_tb/amm_slave_if/writedata
add wave -noupdate -divider {read signals}
add wave -noupdate /amm_cdc_tb/amm_slave_if/read
add wave -noupdate /amm_cdc_tb/amm_slave_if/readdatavalid
add wave -noupdate /amm_cdc_tb/amm_slave_if/readdata
add wave -noupdate -divider DUT
add wave -noupdate /amm_cdc_tb/dut/waitrequest
add wave -noupdate -divider {master domain}
add wave -noupdate /amm_cdc_tb/dut/master_md_req_valid
add wave -noupdate /amm_cdc_tb/dut/master_sd_req_valid
add wave -noupdate /amm_cdc_tb/dut/master_md_ack_valid
add wave -noupdate /amm_cdc_tb/dut/master_sd_ack_valid
add wave -noupdate /amm_cdc_tb/dut/m_write
add wave -noupdate /amm_cdc_tb/dut/m_read
add wave -noupdate /amm_cdc_tb/dut/m_addr
add wave -noupdate /amm_cdc_tb/dut/m_be
add wave -noupdate /amm_cdc_tb/dut/m_data
add wave -noupdate /amm_cdc_tb/dut/m_readdatavalid
add wave -noupdate /amm_cdc_tb/dut/m_readdata
add wave -noupdate -divider {slave domain}
add wave -noupdate /amm_cdc_tb/dut/slave_md_req_valid
add wave -noupdate /amm_cdc_tb/dut/slave_sd_req_valid
add wave -noupdate /amm_cdc_tb/dut/slave_md_ack_valid
add wave -noupdate /amm_cdc_tb/dut/slave_sd_ack_valid
add wave -noupdate /amm_cdc_tb/dut/s_readdatavalid
add wave -noupdate /amm_cdc_tb/dut/s_readdata
add wave -noupdate /amm_cdc_tb/dut/s_write
add wave -noupdate /amm_cdc_tb/dut/s_read
add wave -noupdate /amm_cdc_tb/dut/s_addr
add wave -noupdate /amm_cdc_tb/dut/s_be
add wave -noupdate /amm_cdc_tb/dut/s_data
add wave -noupdate -divider {New Divider}
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/rst_m_i
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/rst_s_i
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/clk_m_i
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/clk_s_i
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/m_req_i
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/m_ack_o
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/s_ack_i
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/s_req_o
add wave -noupdate -radix binary /amm_cdc_tb/dut/master_cdc_handshake/m_ack_sync_reg
add wave -noupdate -radix binary /amm_cdc_tb/dut/master_cdc_handshake/s_req_sync_reg
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/m_busy
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/m_busy_set
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/m_busy_clear
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/m_req_flag
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/m_req_set
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/m_req_clear
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/s_req
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/s_req_set
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/s_req_clear
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/s_ack_flag
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/s_ack_set
add wave -noupdate /amm_cdc_tb/dut/master_cdc_handshake/s_ack_clear
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {12371 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 201
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {649468 ps}
