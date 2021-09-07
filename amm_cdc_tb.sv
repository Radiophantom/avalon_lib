module amm_cdc_tb;

parameter D_W = 64;
parameter A_W = 4;

localparam D_B_W = D_W/8;

bit clk_100MHz;
bit clk_15MHz;
bit rst;

bit [D_W-1:0]   mem [2**A_W-1:0];

bit [A_W-1:0]   address;

bit             write;
bit [D_W-1:0]   writedata;

bit             read;
bit             readdatavalid;
bit [D_W-1:0]   readdata;

bit [D_B_W-1:0] byteenable;

bit             waitrequest;

bit [D_W-1:0] readdata_q [$];

task automatic write_data(
  input bit [D_W-1:0]   data,
        bit [A_W-1:0]   addr,
        bit [D_B_W-1:0] be
);

  write       <= 1'b1;
  address     <= addr;
  writedata   <= data;
  byteenable  <= be;
  do
    @( posedge clk );
  while( ~waitrequest );
  write       <= 1'b0;
endtask : write_data

task automatic read_data(
  input bit [A_W-1:0] addr
);

  read        <= 1'b1;
  address     <= addr;
  do
    @( posedge clk );
  while( ~waitrequest );
  read        <= 1'b0;
endtask : read_data

task automatic capture_read_data(
  output bit [D_W-1:0] data
);
  while( ~readdatavalid )
    @( posedge clk );
  readdata = data;
endtask : capture_read_data

endmodule : amm_cdc_tb

