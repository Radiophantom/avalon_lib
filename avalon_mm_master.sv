class amm_master #(
  // address units "Bytes"="Symbols" or "Words"
  parameter WORD_ADDR_TYPE  = 1,

  // Basic parametets
  parameter ADDR_W          = 12,
  parameter DATA_W          = 64,

  // Random transaction
  parameter RND_WRITE       = 0,
  parameter RND_READ        = 0,

  // Burst enable
  parameter BURST_EN        = 1,
  parameter BURST_W         = 2,

  // Wathdog enable
  parameter WATCHDOG_EN     = 1,
  parameter TIMEOUT         = 1_000,

  // Pending parameters
  //NOTE: must be >= 1 for current version
  parameter PENDING_READ_AMOUNT   = 1,
  parameter PENDING_WRITE_AMOUNT  = 0
);

localparam DATA_B   = DATA_W / 8;
localparam DATA_B_W = $clog2( DATA_B );

virtual avalon_mm_if #(
  .ADDR_W ( ADDR_W  ),
  .DATA_W ( DATA_W  ),
  .BURST_W( BURST_W )
) amm_if_v;

semaphore wr_protection_sema = new( 1 );
semaphore rd_protection_sema = new( 1 );

semaphore capture_protection_sema = new( 1 );

int wr_transaction_in_process = 0;
int rd_transaction_in_process = 0;

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
  amm_if_v.write  = 1'b0;
  amm_if_v.read   = 1'b0;
endfunction : init_interface

task automatic write_data(
  input bit [ADDR_W-1:0]  addr,
        bit [7:0]         data [$]
);
  bit first_transaction = 1'b1;
  bit write;

  bit [ADDR_W-DATA_B_W-1:0] word_addr;
  bit [DATA_B_W-1:0]        byte_addr;
  bit [BURST_W-1:0]         burstcount;

  word_addr = addr[ADDR_W-1:DATA_B_W];
  byte_addr = addr[DATA_B_W-1:0];

  // simultaneous write tasks execution protection
  wr_protection_sema.get( 1 );

  //stop executing if current write transaction amount is over allowed
  if( wr_transaction_in_process > PENDING_WRITE_AMOUNT )
    wait( wr_transaction_in_process <= PENDING_WRITE_AMOUNT );

  // increment write transactions amount
  wr_transaction_in_process += 1;

  while( data.size() > 0 )
    begin
      // write signal assign
      write = 1'b1;
      if( RND_WRITE )
        write = $urandom_range( 1 );
      while( ~write )
        begin
          @( posedge amm_if_v.clk );
          write = $urandom_range( 1 );
        end
      // latch write address
      if( ~BURST_EN || first_transaction )
        begin
          if( WORD_ADDR_TYPE )
            amm_if_v.address <= word_addr;
          else
            amm_if_v.address <= word_addr << DATA_B_W;
          // increment address for next transaction
          word_addr++;
        end
      // calculate and latch burstcount
      if( first_transaction )
        begin
          if( WORD_ADDR_TYPE )
            begin
              // write bytes amount considering offset
              burstcount = ( data.size() + byte_addr + 1 );
              // burst words required
              burstcount = burstcount / DATA_B + ( burstcount % DATA_B != 0 );
            end
          else
            burstcount = data.size();
          amm_if_v.burstcount <= burstcount;
        end
      // fill write data vector with bytes
      for( int byte_num = 0; byte_num < DATA_B; byte_num++ )
        if( data.size() > 0 )
          if( ~first_transaction || ( byte_num >= byte_addr ) )
            begin
              amm_if_v.writedata[7 + byte_num*8 -: 8] <= data.pop_front();
              amm_if_v.byteenable[byte_num]           <= 1'b1;
            end
          else
            begin
              amm_if_v.writedata[7 + byte_num*8 -: 8] <= 8'h00;
              amm_if_v.byteenable[byte_num]           <= 1'b0;
            end
        else
          begin
            amm_if_v.writedata[7 + byte_num*8 -: 8] <= 8'h00;
            amm_if_v.byteenable[byte_num]           <= 1'b0;
          end
      // reset 'first transaction' flag
      first_transaction = 1'b0;
      // assert write request
      amm_if_v.write <= 1'b1;
      // run watchdog
      if( WATCHDOG_EN )
        fork
          watchdog( amm_if_v.waitrequest, 0 );
        join_none
      // wait for write transaction acception
      do
        @( posedge amm_if_v.clk );
      while( amm_if_v.waitrequest );
      amm_if_v.write <= 1'b0;
    end

  // NOTE: must be deleted????
  // decrement write transactions amount
  wr_transaction_in_process -= 1;

  wr_protection_sema.put( 1 );

endtask : write_data

task automatic read_data(
  input   bit [ADDR_W-1:0]  addr,
          int               bytes_amount,
  output  bit [7:0]         data [$]
);
  bit read;

  bit [ADDR_W-DATA_B_W-1:0] word_addr;
  bit [DATA_B_W-1:0]        byte_addr;
  bit [BURST_W-1:0]         burstcount;

  word_addr = addr[ADDR_W-1:DATA_B_W];
  byte_addr = addr[DATA_B_W-1:0];

  // simultaneous read tasks execution protection
  rd_protection_sema.get();

  if( rd_transaction_in_process > PENDING_READ_AMOUNT )
    wait( rd_transaction_in_process <= PENDING_READ_AMOUNT );

  rd_transaction_in_process += 1;

  // read signal assign
  read = 1'b1;
  if( RND_READ )
    read = $urandom_range( 1 );
  while( ~read )
    begin
      @( posedge amm_if_v.clk );
      read = $urandom_range( 1 );
    end
  // latch read address
  if( WORD_ADDR_TYPE )
    amm_if_v.address <= word_addr;
  else
    amm_if_v.address <= word_addr << DATA_B_W;
  // write bytes amount considering offset
  burstcount = ( bytes_amount + byte_addr + 1 );
  // burst words required
  burstcount = burstcount / DATA_B + ( burstcount % DATA_B != 0 );
  //amm_if_v.burstcount <= burstcount;
  amm_if_v.read       <= 1'b1;
  fork
    capture_data( addr, bytes_amount, data );
    begin
      do
        @( posedge amm_if_v.clk );
      while( amm_if_v.waitrequest );
      amm_if_v.read     <= 1'b0;
    end
  join
  rd_protection_sema.put();

endtask : read_data

task automatic capture_data(
  input bit [ADDR_W-1:0]  addr,
        int               bytes_amount,
  ref   bit [7:0]        data [$]
);
  int captured_bytes_amount = 0;
  //bit first_transaction = 1'b1;

  bit [DATA_B_W-1:0]    byte_addr = addr[DATA_B_W-1:0];
  bit [DATA_B-1:0][7:0] word_data;

  capture_protection_sema.get();

  do
    @( posedge amm_if_v.clk );
  while( ~amm_if_v.readdatavalid );
  word_data = amm_if_v.readdata;
  for( int byte_num = 0; byte_num < DATA_B; byte_num++ )
    if( byte_num >= byte_addr && captured_bytes_amount < bytes_amount )
      begin
        data.push_back( word_data[byte_num] );
        captured_bytes_amount += 1;
      end
  /*
  while( captured_bytes_amount < bytes_amount )
    begin
      do
        @( posedge amm_if_v.clk );
      while( ~amm_if_v.readdatavalid );
      word_data = amm_if_v.readdata;
      for( int byte_num = 0; byte_num < DATA_B; byte_num++ )
        if( first_transaction )
          if( ( captured_bytes_amount <= bytes_amount ) && ( byte_addr >= byte_num ) )
            begin
              data.push_back( word_data[byte_num] );
              captured_bytes_amount += 1;
            end
        else
          if( captured_bytes_amount <= bytes_amount )
            begin
              data.push_back( word_data[byte_num] );
              captured_bytes_amount += 1;
            end
    end
  */

  rd_transaction_in_process -= 1;

  capture_protection_sema.put();

endtask : capture_data

task automatic watchdog(
  ref   logic signal,
  input int signal_level = 0
);
  int cur_ticks = 0;

  while( cur_ticks != TIMEOUT )
    begin
      @( posedge amm_if_v.clk );
      if( signal && signal_level )
        break;
      if( ~signal && !signal_level )
        break;
      cur_ticks++;
    end
  if( cur_ticks == TIMEOUT )
    begin
      $display("Watchdog timeout");
      $stop();
    end
endtask : watchdog

endclass : amm_master

