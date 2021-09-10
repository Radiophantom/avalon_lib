`include "./avalon_mm_if.sv"
`include "./avalon_mm_master.sv"
`include "./amm_memory.sv"

`timescale 1ns/1ps

module amm_cdc_tb;

parameter A_W = 8;
parameter D_W = 64;

amm_memory #(
  .A_W     ( A_W ),
  .D_W     ( D_W ),
  .BURST_W ( 2   )
) amm_memory;

amm_master #(
  .A_W     ( A_W ),
  .D_W     ( D_W ),
  .BURST_W ( 2   )
) amm_master;

bit clk_100MHz;
bit clk_15MHz;

bit rst_100MHz;
bit rst_15MHz;

bit [D_W-1:0] mem [2**A_W-1:0];

bit [A_W-1:0] address;
bit [D_W-1:0] writedata;
bit [D_W-1:0] readdata;

bit [D_W-1:0] readdata_q [$];

avalon_mm_if #(
  .A_W     ( A_W ),
  .D_W     ( D_W ),
  .BURST_W ( 2   )
) amm_master_if (
  .rst ( rst_100MHz ),
  .clk ( clk_100MHz )
);

avalon_mm_if #(
  .A_W     ( A_W ),
  .D_W     ( D_W ),
  .BURST_W ( 2   )
) amm_slave_if (
  .rst ( rst_15MHz ),
  .clk ( clk_15MHz )
);

amm_cdc #(
  .CDC_W         ( 2    ),
  .A_W           ( A_W  ),
  .D_W           ( D_W  ),
  //BE_EN         = 1,
  .INPUT_REG_EN  ( 1    ),
  .OUTPUT_REG_EN ( 1    ),
  .BURST_EN      ( 0    ),
  .BURST_W       ( 0    )
) dut (
  .rst_m_i( amm_master_if.rst ),
  .rst_s_i( amm_slave_if.rst  ),

  .clk_m_i( amm_master_if.clk ),
  .clk_s_i( amm_slave_if.clk  ),

  .amm_if_m( amm_master_if    ),
  .amm_if_s( amm_slave_if     )
);

initial
  begin

    fork
      forever #5      clk_100MHz  = ~clk_100MHz;
      forever #6.666  clk_15MHz   = ~clk_15MHz;
    join_none

    amm_memory = new( amm_slave_if  );
    amm_master = new( amm_master_if );

    fork
      begin
        rst_100MHz <= 1'b1;
        @( posedge clk_100MHz );
        rst_100MHz <= 1'b0;
      end
      begin
        rst_15MHz <= 1'b1;
        @( posedge clk_15MHz );
        rst_15MHz <= 1'b0;
      end
    join

    amm_memory.run();

    repeat( 10 )
      begin
        address   = $urandom_range( 2**A_W-1, 0 );
        writedata = $urandom_range( 2**D_W-1, 0 );

        amm_master.write_data( address, writedata );
        amm_master.read_data( address, readdata );
        if( writedata != readdata )
          begin
            $display("Data mismatch. Expected: %h; Observed: %h", writedata, readdata );
            $stop();
          end
      end
  end

endmodule : amm_cdc_tb

