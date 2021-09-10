interface avalon_mm_if #(
  parameter D_W = 64,
  parameter A_W = 12,
  parameter BURST_W = 2
)(
  input rst,
  input clk
);

logic [A_W-1:0] address;

logic [BURST_W-1:0] burstcount;

logic [D_W/8-1:0] byteenable;

logic           write;
logic [D_W-1:0] writedata;

logic           read;

logic           readdatavalid;
logic [D_W-1:0] readdata;

logic           waitrequest;

endinterface : avalon_mm_if

