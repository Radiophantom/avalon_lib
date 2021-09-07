module amm_cdc #(
  parameter CDC_W         = 2,
  parameter A_W           = 32,
  parameter D_W           = 64,
  //parameter BE_EN         = 1,
  parameter INPUT_REG_EN  = 1,
  parameter OUTPUT_REG_EN = 1,
  parameter BURST_EN      = 0,
  parameter BURST_W       = 0
)(
  input   rst_m_i,
  input   rst_s_i,

  input   clk_m_i,
  input   clk_s_i,

  amm_if  amm_if_m,
  amm_if  amm_if_s
);

logic waitrequest;

//******************************************
// Module instances
//******************************************

logic master_md_req_valid, master_sd_req_valid;
logic master_md_ack_valid, master_sd_ack_valid;

logic slave_md_req_valid, slave_sd_req_valid;
logic slave_md_ack_valid, slave_sd_ack_valid;

cdc_handshake #(
  .CDC_REG_AMOUNT( CDC_W + INPUT_REG_EN + OUTPUT_REG_EN )
) master_cdc_handshake (
  .rst_m_i( rst_m_i             ),
  .rst_s_i( rst_s_i             ),

  .clk_m_i( clk_m_i             ),
  .clk_s_i( clk_s_i             ),

  .m_req_i( master_md_req_valid ),
  .m_ack_o( master_md_ack_valid ),

  .s_ack_i( master_sd_ack_valid ),
  .s_req_o( master_sd_req_valid )
);

cdc_handshake #(
  .CDC_REG_AMOUNT( CDC_W + INPUT_REG_EN + OUTPUT_REG_EN )
) slave_cdc_handshake (
  .rst_m_i( rst_s_i             ),
  .rst_s_i( rst_m_i             ),

  .clk_m_i( clk_s_i             ),
  .clk_s_i( clk_m_i             ),

  .m_req_i( slave_md_req_valid  ),
  .m_ack_o( slave_md_ack_valid  ),

  .s_ack_i( slave_sd_req_valid  ),
  .s_req_o( slave_sd_ack_valid  )
);

//******************************************
// Latch input signals
//******************************************

logic             m_write;
logic             m_read;
logic [A_W-1:0]   m_addr;
logic [D_W/8-1:0] m_be;
logic [D_W-1:0]   m_data

logic             s_readdatavalid;
logic [D_W-1:0]   s_readdata;

generate
  if( INPUT_REG_EN )
    begin

      always_ff @( posedge clk_m_i )
        if( master_md_req_valid )
          begin
            m_write <= amm_if_m.write;
            m_read  <= amm_if_m.read;
            m_addr  <= amm_if_m.address;
            m_be    <= amm_if_m.byteenable;
            if( amm_if_m.write )
              m_data <= amm_if_m.writedata;
          end

    end
  else
    begin

      always_comb
        begin
          m_write = amm_if_m.write;
          m_read  = amm_if_m.read;
          m_addr  = amm_if_m.address;
          m_be    = amm_if_m.byteenable;
          m_data  = amm_if_m.writedata;
        end

    end
endgenerate

always_ff @( posedge clk_s_i )
  if( slave_md_req_valid )
    begin
      s_readdatavalid <= amm_if_s.readdatavalid;
      s_readdata      <= amm_if_s.readdata;
    end

//******************************************
// Latch output signals
//******************************************

logic             s_write;
logic             s_read;
logic [A_W-1:0]   s_addr;
logic [D_W/8-1:0] s_be;
logic [D_W-1:0]   s_data

logic             m_readdatavalid;
logic [D_W-1:0]   m_readdata;

generate
  if( OUTPUT_REG_EN )
    begin

      always_ff @( posedge clk_s_i )
        if( master_sd_req_valid )
          begin
            s_write <= m_write;
            s_read  <= m_read;
            s_addr  <= m_addr;
            s_be    <= m_be;
            if( m_write )
              s_data <= m_data;
          end
        else
          if( ~amm_if_s.waitrequest )
            begin
              s_write <= 1'b0;
              s_read  <= 1'b0;
            end

      always_ff @( posedge clk_m_i )
        if( slave_md_req_valid )
          m_readdata <= s_readdata;

    end
  else
    begin

      always_comb
        if( master_sd_req_valid )
          begin
            s_write = m_write;
            s_read  = m_read;
            s_addr  = m_addr;
            s_be    = m_be;
            s_data  = m_data;
          end
        else
          begin
            write_s = 1'b0;
            read_s  = 1'b0;
          end

      always_comb
        m_readdata      = s_readdata;

    end
endgenerate

always_ff @( posedge clk_m_i, posedge rst_m_i )
  if( rst_m_i )
    m_readdatavalid <= 1'b0;
  else
    if( slave_md_req_valid )
      m_readdatavalid <= 1'b1;
    else
      m_readdatavalid <= 1'b0;

assign master_sd_ack_valid = ( s_write || s_read ) && ~!amm_if_s.waitrequest;

//**************************************************
// Master clock domain
//**************************************************

assign master_md_req_valid = ( amm_if_m.write || amm_if_m.read );

always_ff @( posedge clk_m_i, posedge rst_m_i )
  if( rst_m_i )
    waitrequest <= 1'b1;
  else
    if( master_md_ack_valid )
      waitrequest <= 1'b0;
    else
      waitrequest <= 1'b1;

//****************************************
// Master interface assigns
//****************************************

assign amm_if_m.readdatavalid = m_readdatavalid;
assign amm_if_m.readdata      = m_readdata;

assign amm_if_m.waitrequest   = waitrequest;

//****************************************
// Slave interface assigns
//****************************************

assign amm_if_s.write     = s_write;
assign amm_if_s.read      = s_read;
assign amm_if_s.be        = s_be;
assign amm_if_s.address   = s_address;
assign amm_if_s.writedata = s_writedata;

endmodule : amm_cdc

