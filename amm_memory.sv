`include "./avalon_mm_if.sv"

class amm_memory #(
  parameter ADDR_W  = 12,
  parameter DATA_W  = 64,
  parameter BURST_W = 2
);

parameter wr_delay      = 0;
parameter rd_delay      = 0;
parameter rd_resp_delay = 0;

virtual avalon_mm_if #(
  .ADDR_W ( ADDR_W  ),
  .DATA_W ( DATA_W  ),
  .BURST_W( BURST_W )
) amm_if_v;

bit [DATA_W-1:0] mem [2**ADDR_W-1:0];

function new(
  virtual avalon_mm_if #(
    .ADDR_W ( ADDR_W  ),
    .DATA_W ( DATA_W  ),
    .BURST_W( BURST_W )
  ) amm_if_v
);
  this.amm_if_v = amm_if_v;
  void'( init_interface() );
endfunction : new

function init_interface();
  amm_if_v.waitrequest = 1'b1;
endfunction : init_interface

task automatic write_data(); 
  bit [DATA_W-1:0] data;
  bit [ADDR_W-1:0] addr;

  repeat( wr_delay )
    @( posedge amm_if_v.clk );
  amm_if_v.waitrequest <= 1'b0;

  @( posedge amm_if_v.clk );
  addr = amm_if_v.address;
  data = amm_if_v.writedata;
  amm_if_v.waitrequest <= 1'b1;

endtask : write_data

task automatic read_data();
  bit [ADDR_W-1:0] addr;

  repeat( rd_delay )
    @( posedge amm_if_v.clk );
  amm_if_v.waitrequest <= 1'b0;

  @( posedge amm_if_v.clk );
  addr = amm_if_v.address;
  amm_if_v.waitrequest <= 1'b1;

  fork
    begin
      repeat( rd_resp_delay )
        @( posedge amm_if_v.clk );
      amm_if_v.readdatavalid  <= 1'b1;
      amm_if_v.readdata       <= mem[addr];
      @( posedge amm_if_v.clk );
      amm_if_v.readdatavalid  <= 1'b0;
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
    
assert error ( amm_if_v.write && amm_if_v.read );

endclass : amm_memory

