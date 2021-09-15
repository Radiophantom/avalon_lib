module amm_cdc #(
  parameter CDC_W     = 2,
  parameter ADDR_W    = 32,
  parameter DATA_W    = 64,
  parameter BURST_EN  = 0,
  parameter BURST_W   = 0
)(
  input   rst_m_i,
  input   rst_s_i,

  input   clk_m_i,
  input   clk_s_i,

  avalon_mm_if  amm_if_m,
  avalon_mm_if  amm_if_s
);

//******************************************
// Variables declaration
//******************************************

logic waitrequest;

logic master_md_req_valid, master_sd_req_valid;
logic master_md_ack_valid, master_sd_ack_valid;

logic slave_md_req_valid, slave_sd_req_valid;
logic slave_md_ack_valid, slave_sd_ack_valid;

//******************************************
// Module instances
//******************************************

// instance CDC handshake for master write/read requests
cdc_handshake #(
  .CDC_REG_AMOUNT( CDC_W )
) master_request_cdc_handshake (
  .rst_m_i( rst_m_i             ),
  .rst_s_i( rst_s_i             ),

  .clk_m_i( clk_m_i             ),
  .clk_s_i( clk_s_i             ),

  .m_req_i( master_md_req_valid ),
  .m_ack_o( master_md_ack_valid ),

  .s_ack_i( master_sd_ack_valid ),
  .s_req_o( master_sd_req_valid )
);

assign master_md_req_valid = ( amm_if_m.write || amm_if_m.read );
assign master_sd_ack_valid = ~amm_if_s.waitrequest;

// instances CDC handshake for slave read responses
cdc_handshake #(
  .CDC_REG_AMOUNT( CDC_W ) // +1? to balance delay because of 'readdata' latching
) slave_response_cdc_handshake (
  .rst_m_i( rst_m_i             ),
  .rst_s_i( rst_s_i             ),

  .clk_m_i( clk_m_i             ),
  .clk_s_i( clk_s_i             ),

  .m_req_i( slave_sd_req_valid  ),
  .m_ack_o( slave_sd_ack_valid  ),

  .s_ack_i( slave_md_ack_valid  ),
  .s_req_o( slave_md_req_valid  )
);

assign slave_sd_req_valid = amm_if_s.readdatavalid;
assign slave_md_ack_valid = 1'b1;

//******************************************
// Latch output signals
//******************************************

always_ff @( posedge clk_s_i )
  if( master_sd_req_valid )
    begin
      amm_if_s.write      <= amm_if_m.write;
      amm_if_s.read       <= amm_if_m.read;
      amm_if_s.address    <= amm_if_m.address;
      amm_if_s.byteenable <= amm_if_m.byteenable;
      if( amm_if_m.write )
        amm_if_s.writedata  <= amm_if_m.writedata;
    end
  else
    if( ~amm_if_s.waitrequest )
      begin
        s_write <= 1'b0;
        s_read  <= 1'b0;
      end

always_ff @( posedge clk_s_i )
  if( amm_if_s.readdatavalid )
    s_readdata <= amm_if_s.readdata;

always_ff @( posedge clk_m_i )
  begin
    amm_if_m.readdatavalid <= slave_md_req_valid;
    if( slave_md_req_valid )
      amm_if_m.readdata <= s_readdata;
  end

//****************************************
// Master interface assigns
//****************************************

assign amm_if_m.waitrequest = ~master_md_ack_valid;

//****************************************
// Slave interface assigns
//****************************************

endmodule : amm_cdc

