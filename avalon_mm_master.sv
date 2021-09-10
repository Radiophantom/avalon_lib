`include "./avalon_mm_if.sv"

class amm_master #(
  parameter A_W = 12,
  parameter D_W = 64,
  parameter BURST_W = 2
);

virtual avalon_mm_if #(
  .A_W( A_W ),
  .D_W( D_W ),
  .BURST_W( BURST_W )
) amm_if_v;

function new(
  virtual avalon_mm_if #(
    .A_W( A_W ),
    .D_W( D_W ),
    .BURST_W( BURST_W )
  ) amm_if_v
);
  this.amm_if_v = amm_if_v;
  init_interface();
endfunction : new

function init_interface();
  amm_if_v.write  = 1'b0;
  amm_if_v.read   = 1'b0;
endfunction : init_interface

task automatic write_data(
  input bit [A_W-1:0] addr,
        bit [D_W-1:0] data
);

  amm_if_v.write      <= 1'b1;
  amm_if_v.address    <= addr;
  amm_if_v.writedata  <= data;
  amm_if_v.byteenable <= '1;
  do
    @( posedge amm_if_v.clk );
  while( amm_if_v.waitrequest );
  amm_if_v.write      <= 1'b0;

endtask : write_data

task automatic read_data(
  input   bit [A_W-1:0] addr,
  output  bit [D_W-1:0] data
);

  amm_if_v.read     <= 1'b1;
  amm_if_v.address  <= addr;
  do
    @( posedge amm_if_v.clk );
  while( amm_if_v.waitrequest );
  amm_if_v.read     <= 1'b0;
  while( ~amm_if_v.readdatavalid )
    @( posedge amm_if_v.clk );
  data = amm_if_v.readdata;

endtask : read_data

endclass : amm_master

