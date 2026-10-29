interface yapp_if (
  input logic clock,
  input logic reset
);

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // actual signals
  logic       in_data_vld;
  logic       in_suspend;
  logic [7:0] in_data;

  // signal for transaction recording
  bit drvstart;
  bit monstart;

  task yapp_reset();
    @(posedge reset);
    in_data     <=  'z;
    in_data_vld <= 1'b0;
    drvstart     = 1'b0;
    disable send_to_dut;
  endtask : yapp_reset

  // driver gets a packet and drives it into the DUT
  task send_to_dut(
    input bit [5:0] length,
    input bit [1:0] addr,
    input bit [7:0] payload[],
    input bit [7:0] parity,
    input int       packet_delay
  );
    repeat(packet_delay) begin
      @(negedge clock);
    end
    @(negedge clock iff (!in_suspend));
    drvstart     = 1'b1;
    in_data_vld <= 1'b1;
    in_data     <= {length, addr};
    foreach (payload[i]) begin
      @(negedge clock iff (!in_suspend));
      in_data <= payload[i];
    end
    @(negedge clock iff (!in_suspend));
    in_data_vld <= 1'b0;
    in_data     <= parity;
    @(negedge clock);
    in_data  <= 'z;
    drvstart  = 1'b0;
  endtask : send_to_dut

  // monitor collects packets
  task collect_packet(
    output bit [5:0]  length,
    output bit [1:0]  addr,
    output bit [7:0]  payload[],
    output bit [7:0]  parity
  );
    // Monitor samples on rising edges; the driver drives on falling edges.
    @(posedge clock iff (!in_suspend && in_data_vld));
    monstart = 1'b1;
    `uvm_info("YAPP_IF", "collecting packets", UVM_HIGH)
    {length, addr} = in_data;
    payload = new[length];
    foreach (payload[i]) begin
      @(posedge clock iff (!in_suspend));
      payload[i] = in_data;
    end
    @(posedge clock iff (!in_suspend));
    parity = in_data;
    monstart = 1'b0;
  endtask : collect_packet

  property yapp_suspended;
    @(posedge clock)
    disable iff (reset)
      !in_suspend ##1 in_suspend[*20] |=> !in_suspend;
  endproperty

  YAPP_SUSPENDED: assert property (yapp_suspended)
  else begin
    $fatal(1, "YAPP suspension exceeded 20 consecutive clock cycles.");
  end

endinterface : yapp_if
