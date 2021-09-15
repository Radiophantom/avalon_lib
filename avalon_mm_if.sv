interface avalon_mm_if #(
  parameter DATA_W  = 64,
  parameter ADDR_W  = 12,
  parameter BURST_W = 2
)(
  input rst,
  input clk
);

localparam DATA_B_W = DATA_W/8;

logic [ADDR_W-1:0]    address;

logic [BURST_W-1:0]   burstcount;

logic [DATA_B_W-1:0]  byteenable;

logic                 write;
logic [DATA_W-1:0]    writedata;

logic                 read;

logic                 readdatavalid;
logic [DATA_W-1:0]    readdata;

logic                 waitrequest;

endinterface : avalon_mm_if

