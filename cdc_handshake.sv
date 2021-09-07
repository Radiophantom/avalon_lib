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

logic m_busy;
logic m_busy_set;
logic m_busy_clear;

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

always_ff @( posedge clk_m_i, posedge rst_m_i )
  if( rst_m_i )
    m_busy <= 1'b0;
  else
    if( m_busy_set )
      m_busy <= 1'b1;
    else
      if( m_busy_clear )
        m_busy <= 1'b0;

assign m_busy_set   = m_req_i && ~m_busy;
assign m_busy_clear = m_ack_sync_reg[CDC_REG_AMOUNT] && ~m_ack_sync_reg[CDC_REG_AMOUNT-1];

//**************************************************
// Slave clock domain
//**************************************************

always_ff @( posedge clk_s_i, posedge rst_s_i )
  if( rst_s_i )
    s_req <= 1'b0;
  else
    if( s_req_set )
      s_req <= 1'b1;
    else
      if( s_req_clear )
        s_req <= 1'b0;

assign s_req_set   = s_req_sync_reg[CDC_REG_AMOUNT-1] && ~s_req_sync_reg[CDC_REG_AMOUNT];
assign s_req_clear = s_ack_i && s_req;

//********************************************
// Handshake logic
//********************************************

// cross clock domain sync registers
always_ff @( posedge clk_s_i )
  s_req_sync_reg <= { s_req_sync_reg[CDC_REG_AMOUNT-1:0], m_req_flag };

always_ff @( posedge clk_m_i )
  m_ack_sync_reg <= { m_ack_sync_reg[CDC_REG_AMOUNT-1:0], s_ack_flag };

// master request logic to cross clock domain
always_ff @( posedge clk_m_i, posedge rst_m_i )
  if( rst_m_i )
    m_req_flag <= 1'b0;
  else
    if( m_req_set )
      m_req_flag <= 1'b1;
    else
      if( m_req_clear )
        m_req_flag <= 1'b0;

assign m_req_set    = m_busy_set;
assign m_req_clear  = m_ack_sync_reg[CDC_REG_AMOUNT-1] && ~m_ack_sync_reg[CDC_REG_AMOUNT];

// slave acknowledge logic to cross clock domain
always_ff @( posedge clk_s_i, posedge rst_s_i )
  if( rst_s_i )
    s_ack_flag <= 1'b0;
  else
    if( s_ack_set )
      s_ack_flag <= 1'b1;
    else
      if( s_ack_clear )
        s_ack_flag <= 1'b0;

assign s_ack_set    = s_req_set;
assign s_ack_clear  = s_req_sync_reg[CDC_REG_AMOUNT] && ~ s_req_sync_reg[CDC_REG_AMOUNT-1];

//********************************************
// Output assigns
//********************************************

assign s_req_o = s_req;
assign m_ack_o = m_req_clear;

endmodule : cdc_handshake

