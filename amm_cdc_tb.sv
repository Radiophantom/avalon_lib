`include "./avalon_mm_if.sv"
`include "./avalon_mm_master.sv"
`include "./amm_memory.sv"

`timescale 1ns/1ps

module amm_cdc_tb;

parameter ADDR_W = 8;
parameter DATA_W = 64;
parameter DATA_B = DATA_W/8;
parameter DATA_B_W = $clog2( DATA_B );

amm_memory #(
  .ADDR_W     ( ADDR_W ),
  .DATA_W     ( DATA_W ),
  .BURST_W ( 2   )
) amm_memory;

amm_master #(
  .WORD_ADDR_TYPE( 0   ),
  .ADDR_W     ( ADDR_W ),
  .DATA_W     ( DATA_W ),
  .BURST_W ( 2   )
) amm_master;

bit clk_100MHz;
bit clk_15MHz;

bit rst_100MHz;
bit rst_15MHz;

bit [DATA_W-1:0] mem [2**ADDR_W-1:0];

bit [ADDR_W-1:0] address;
bit [DATA_W-1:0] writedata;
bit [DATA_W-1:0] readdata;

bit [DATA_W-1:0] readdata_q [$];

avalon_mm_if #(
  .ADDR_W     ( ADDR_W ),
  .DATA_W     ( DATA_W ),
  .BURST_W ( 2   )
) amm_master_if (
  .rst ( rst_100MHz ),
  .clk ( clk_100MHz )
);

avalon_mm_if #(
  .ADDR_W     ( ADDR_W ),
  .DATA_W     ( DATA_W ),
  .BURST_W ( 2   )
) amm_slave_if (
  .rst ( rst_15MHz ),
  .clk ( clk_15MHz )
);

amm_cdc #(
  .CDC_W         ( 2    ),
  .ADDR_W           ( ADDR_W  ),
  .DATA_W           ( DATA_W  ),
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
        bit [7:0] writedata_bytes [$];
        bit [7:0] readdata_bytes [$];
        bit [7:0] readdata_bytes_1 [$];
        bit [7:0] readdata_bytes_2 [$];
        bit [DATA_W-1:0] writedata;
        bit [DATA_W-1:0] readdata;

        address   = $urandom_range( 2**ADDR_W-1, 0 );
        repeat( DATA_W/8 )
          writedata_bytes.push_back( $urandom_range( 255, 0 ) );

        amm_master.write_data( address, writedata_bytes );
        repeat( 10 )
          @( posedge amm_slave_if.clk );
        amm_master.read_data( address, DATA_B - address[DATA_B_W-1:0], readdata_bytes_1 );
        if( address[DATA_B_W-1:0] != 0 )
          amm_master.read_data( address+(DATA_B-address[DATA_B_W-1:0]), address[DATA_B_W-1:0], readdata_bytes_2 );
        else
          readdata_bytes_2 = {};
        readdata_bytes = { readdata_bytes_1, readdata_bytes_2 };
        writedata = {<<8{writedata_bytes}};
        readdata  = {<<8{readdata_bytes_1, readdata_bytes_2}};
        writedata_bytes.delete();

        if( writedata != readdata )
          begin
            $display("Data mismatch. Expected: %h; Observed: %h", writedata, readdata );
            $stop();
          end
      end

    $display("Everything is OK");
    $stop();
  end

endmodule : amm_cdc_tb

