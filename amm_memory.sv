`include "./avalon_mm_if.sv"

class amm_memory #(
  parameter A_W = 12,
  parameter D_W = 64,
  parameter BURST_W = 2
);

parameter wr_delay = 0;
parameter rd_delay = 0;

virtual avalon_mm_if #(
  .A_W( A_W ),
  .D_W( D_W ),
  .BURST_W( BURST_W )
) amm_if_v;

bit [D_W-1:0] mem [2**A_W-1:0];

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
  amm_if_v.waitrequest = 1'b1;
endfunction : init_interface

task automatic write_data(); 
  bit [D_W-1:0] data;
  bit [A_W-1:0] addr;

  amm_if_v.waitrequest <= 1'b0;

  @( posedge amm_if_v.clk );
  addr = amm_if_v.address;
  data = amm_if_v.writedata;
  amm_if_v.waitrequest <= 1'b1;

  fork
    begin
      repeat( wr_delay ) @( posedge amm_if_v.clk );
      mem[addr] = data;
    end
  join_none

endtask : write_data

task automatic read_data();
  bit [A_W-1:0] addr;

  amm_if_v.waitrequest <= 1'b0;

  @( posedge amm_if_v.clk );
  addr = amm_if_v.address;

  fork
    begin
      repeat( rd_delay ) @( posedge amm_if_v.clk );
      amm_if_v.readdata <= mem[addr];
      amm_if_v.readdatavalid <= 1'b1;
      @( posedge amm_if_v.clk );
      amm_if_v.readdatavalid <= 1'b0;
    end
  join_none

endtask : read_data

task automatic run();
  fork
    forever
      begin
        if( amm_if_v.write )
          write_data();
        else
          if( amm_if_v.read )
            read_data();
        @( posedge amm_if_v.clk );
      end
  join_none
endtask : run
    
endclass : amm_memory

