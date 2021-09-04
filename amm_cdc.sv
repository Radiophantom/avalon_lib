module amm_cdc #(
  parameter A_W           = 32,
  parameter D_W           = 64,
  parameter INPUT_REG_EN  = 1,
  parameter OUTPUT_REG_EN = 1,
  parameter PIPE_READ     = 1,
  parameter BURST_EN      = 0,
  parameter BURST_W       = 0
)(
  amm_if amm_if_m,
  amm_if amm_if_s
);

//******************************************
// Request assert logic
//******************************************

always_ff @( posedge amm_if_m.clk )
  if( m_req_stb )
    begin
      m_write <= amm_if_m.write;
      m_read  <= amm_if_m.read;
      m_addr  <= amm_if_m.address;
      if( amm_if_m.write )
        m_data <= amm_if_m.writedata;
    end

always_ff @( posedge amm_if_m.clk, posedge amm_if_m.rst )
  if( amm_if_m.rst )
    m_in_progress <= 1'b0;
  else
    if( m_req_set )
      m_in_progress <= 1'b1;
    else
      if( m_busy_clear )
        m_in_progress <= 1'b0;

assign m_req_en   = ( amm_if_m.write || amm_if_m.read );

assign m_req_set  = m_req_en && ~m_in_progress;

assign amm_if_m.waitrequest = m_in_progress;

//********************************************
// Handshake logic
//********************************************

always_ff @( posedge amm_if_m.clk, posedge amm_if_m.rst )
  if( amm_if_m.rst )
    m_req_flag <= 1'b0;
  else
    if( m_req_set )
      m_req_flag <= 1'b1;
    else
      if( m_req_clear )
        m_req_flag <= 1'b0;

always_ff @( posedge amm_if_s.clk )
  s_req_sync_reg <= { s_req_sync_reg[1:0], m_req_flag };

always_ff @( posedge amm_if_m.clk )
  m_ack_sync_reg <= { m_ack_sync_reg[1:0], s_ack_flag };

assign m_req_clear  =  m_ack_sync_reg[1] && ~m_ack_sync_reg[2];
assign m_busy_clear =  ~m_ack_sync_reg[1] &&  m_ack_sync_reg[2];

assign s_ack_set    =  s_req_sync_reg[1] && ~amm_if_s.waitrequest && ~s_ack_flag;
assign s_ack_clear  = ~s_req_sync_reg[1] &&  s_req_sync_reg[2];

always_ff @( posedge amm_if_s.clk, posedge amm_if_s.rst )
  if( amm_if_s.rst )
    s_ack_flag <= 1'b0;
  else
    if( s_ack_set )
      s_ack_flag <= 1'b1;
    else
      if( s_ack_clear )
        s_ack_flag <= 1'b0;

//******************************************
// Request answer logic
//******************************************

always_ff @( posedge amm_if_s.clk )
  if( s_ack_set )
    begin
      write_s <= write_m;
      read_s  <= read_m;
      addr_s  <= addr_m;
      if( write_m )
        data_s <= data_m;
    end
  else
    if( ~amm_if_s.waitrequest )
      begin
        write_s <= 1'b0;
        read_s  <= 1'b0;
      end

//****************************************
// Read transaction CDC
//****************************************

assign m_ack_set    =  m_ack_sync_reg[1] && ~m_ack_sync_reg[2];
assign m_ack_clear  = ~m_ack_sync_reg[1] &&  m_ack_sync_reg[2];

assign m_ack_set    =  m_ack_sync_reg[1] && ~m_ack_sync_reg[2];
assign m_ack_clear  = ~m_ack_sync_reg[1] &&  m_ack_sync_reg[2];

always_ff @( posedge amm_if_s.clk, posedge amm_if_s.rst )
  if( amm_if_s.rst )
    busy_s <= 1'b0;
  else
    if( s_req )
      busy_s <= 1'b1;
    else
      if( ~amm_if_s.waitrequest )
        busy_s <= 1'b0;

endmodule : amm_cdc

