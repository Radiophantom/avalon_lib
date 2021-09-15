module cdc_handshake #(
  parameter CDC_REG_AMOUNT = 2
)(
  input   rst_m_i,
  input   rst_s_i,

  input   clk_m_i,
  input   clk_s_i,

  input   m_req_i,
  output  m_ack_o,

  input   s_ack_i,
  output  s_req_o
);

logic [CDC_REG_AMOUNT:0]  m_ack_sync_reg;
logic [CDC_REG_AMOUNT:0]  s_req_sync_reg;

logic m_ack_wait;
logic m_ack_wait_set;
logic m_ack_wait_clear;

logic s_req;
logic s_req_set;
logic s_req_clear;

logic m_req_flag;
logic m_req_set;
logic m_req_clear;

logic s_ack_flag;
logic s_ack_set;
logic s_ack_clear;

//**************************************************
// Master clock domain
//**************************************************

// master request register toggling
always_ff @( posedge clk_m_i, posedge rst_m_i )
  if( rst_m_i )
    m_req <= 1'b0;
  else
    if( m_req_toggle )
      m_req <= ~m_req;

// prevent toggling when request in process
always_ff @( posedge clk_m_i, posedge rst_m_i )
  if( rst_m_i )
    m_ack_wait <= 1'b0;
  else
    if( m_ack_wait_set )
      m_ack_wait <= 1'b1;
    else
      if( m_ack_wait_clear )
        m_ack_wait <= 1'b0;

assign m_req_toggle     = m_req_i && ~m_ack_wait;

assign m_ack_wait_set   = m_req_toggle;
assign m_ack_wait_clear = m_ack_stb;

//**************************************************
// Slave clock domain
//**************************************************

always_ff @( posedge clk_s_i, posedge rst_s_i )
  if( rst_s_i )
    s_ack <= 1'b0;
  else
    if( s_ack_toggle )
      s_ack <= ~s_ack;

always_ff @( posedge clk_s_i, posedge rst_s_i )
  if( rst_s_i )
    s_req <= 1'b0;
  else
    if( s_req_set )
      s_req <= 1'b1;
    else
      if( s_req_clear )
        s_req <= 1'b0;

assign s_ack_toggle = s_req && s_ack_i;

assign s_req_set    = s_req_stb;
assign s_req_clear  = s_ack_toggle;

//********************************************
// Cross domain sync registers
//********************************************

// cross clock domain sync registers
always_ff @( posedge clk_s_i, posedge rst_s_i )
  if( rst_s_i )
    s_req_sync_reg <= '0;
  else
    s_req_sync_reg <= { s_req_sync_reg[CDC_REG_AMOUNT-1:0], m_req_flag };

always_ff @( posedge clk_m_i, posedge rst_m_i )
  if( rst_m_i )
    m_ack_sync_reg <= '0;
  else
    m_ack_sync_reg <= { m_ack_sync_reg[CDC_REG_AMOUNT-1:0], s_ack_flag };

//********************************************
// Output assigns
//********************************************

assign s_req_posedge_stb = s_req_sync_reg[CDC_REG_AMOUNT]   && s_req_sync_reg[CDC_REG_AMOUNT-1];
assign s_req_negedge_stb = s_req_sync_reg[CDC_REG_AMOUNT-1] && s_req_sync_reg[CDC_REG_AMOUNT];

assign m_ack_posedge_stb = m_ack_sync_reg[CDC_REG_AMOUNT]   && m_ack_sync_reg[CDC_REG_AMOUNT-1];
assign m_ack_negedge_stb = m_ack_sync_reg[CDC_REG_AMOUNT-1] && m_ack_sync_reg[CDC_REG_AMOUNT];

assign s_req_stb = s_req_posedge_stb || s_req_negedge_stb;
assign m_ack_stb = m_ack_posedge_stb || m_ack_negedge_stb;

assign s_req_o = s_req;
assign m_ack_o = m_ack_stb;

endmodule : cdc_handshake

