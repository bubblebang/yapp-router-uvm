`uvm_analysis_imp_decl(_yapp)
`uvm_analysis_imp_decl(_chan0)
`uvm_analysis_imp_decl(_chan1)
`uvm_analysis_imp_decl(_chan2)

class router_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(router_scoreboard)

  uvm_analysis_imp_yapp  #(yapp_packet,    router_scoreboard) yapp_in;
  uvm_analysis_imp_chan0 #(channel_packet, router_scoreboard) chan0_in;
  uvm_analysis_imp_chan1 #(channel_packet, router_scoreboard) chan1_in;
  uvm_analysis_imp_chan2 #(channel_packet, router_scoreboard) chan2_in;

  yapp_packet q0[$];
  yapp_packet q1[$];
  yapp_packet q2[$];

  // Count packets received without an expected packet in the channel queue.
  int num_yapp_in, num_yapp_invalid;
  int num_chan0_in, num_chan0_matched, num_chan0_mismatched, num_chan0_unexpected;
  int num_chan1_in, num_chan1_matched, num_chan1_mismatched, num_chan1_unexpected;
  int num_chan2_in, num_chan2_matched, num_chan2_mismatched, num_chan2_unexpected;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    yapp_in  = new("yapp_in",  this);
    chan0_in = new("chan0_in", this);
    chan1_in = new("chan1_in", this);
    chan2_in = new("chan2_in", this);
  endfunction

  virtual function bit pkt_compare(yapp_packet yp, channel_packet cp, uvm_comparer comparer = null);
    if (comparer == null)
      comparer = new();
    pkt_compare = comparer.compare_field("addr", yp.addr, cp.addr, 2);
    pkt_compare &= comparer.compare_field("length", yp.length, cp.length, 6);
    pkt_compare &= comparer.compare_field_int("payload_size", yp.payload.size(), cp.payload.size(), 32);
    if (yp.payload.size() == cp.payload.size()) begin
      foreach (yp.payload[i]) begin
        pkt_compare &= comparer.compare_field($sformatf("payload[%0d]", i), yp.payload[i], cp.payload[i], 8);
      end
    end
    pkt_compare &= comparer.compare_field("parity", yp.parity, cp.parity, 8);
  endfunction : pkt_compare

  virtual function void write_yapp(input yapp_packet pkt);
    yapp_packet pkt_clone;
    num_yapp_in++;
    if (!$cast(pkt_clone, pkt.clone())) begin
      `uvm_fatal("CLONE", "Failed to clone and cast YAPP packet!")
    end
    case(pkt_clone.addr)
      2'b00 : begin
        q0.push_back(pkt_clone);
        `uvm_info(get_type_name(), "Packet added to scoreboard queue 0", UVM_HIGH)
      end
      2'b01 : begin
        q1.push_back(pkt_clone);
        `uvm_info(get_type_name(), "Packet added to scoreboard queue 1", UVM_HIGH)
      end
      2'b10 : begin
        q2.push_back(pkt_clone);
        `uvm_info(get_type_name(), "Packet added to scoreboard queue 2", UVM_HIGH)
      end
      default : begin
        `uvm_error(
          get_type_name(),
          $sformatf("Reference model forwarded illegal address = %0d", pkt_clone.addr)
        )
        num_yapp_invalid++;
      end
    endcase
  endfunction : write_yapp

  virtual function void write_chan0(input channel_packet pkt);
    yapp_packet expected;
    num_chan0_in++;
    if (q0.size() == 0) begin
      `uvm_error("PKTCMP", "Received Channel 0 packet but channel 0 queue is empty")
      num_chan0_unexpected++;
      return;
    end
    expected = q0.pop_front();
    if (pkt_compare(expected, pkt)) begin
      `uvm_info("PKTCMP", "Channel 0 packet matched", UVM_LOW)
      num_chan0_matched++;
    end
    else begin
      `uvm_error("PKTCMP", $sformatf("Channel 0 packet mismatched:\nExpected: %s\nActual: %s", expected.sprint(), pkt.sprint()))
      num_chan0_mismatched++;
    end
  endfunction : write_chan0

  virtual function void write_chan1(input channel_packet pkt);
    yapp_packet expected;
    num_chan1_in++;
    if (q1.size() == 0) begin
      `uvm_error("PKTCMP", "Received Channel 1 packet but channel 1 queue is empty")
      num_chan1_unexpected++;
      return;
    end
    expected = q1.pop_front();
    if (pkt_compare(expected, pkt)) begin
      `uvm_info("PKTCMP", "Channel 1 packet matched", UVM_LOW)
      num_chan1_matched++;
    end
    else begin
      `uvm_error("PKTCMP", $sformatf("Channel 1 packet mismatched:\nExpected: %s\nActual: %s", expected.sprint(), pkt.sprint()))
      num_chan1_mismatched++;
    end
  endfunction : write_chan1

  virtual function void write_chan2(input channel_packet pkt);
    yapp_packet expected;
    num_chan2_in++;
    if (q2.size() == 0) begin
      `uvm_error("PKTCMP", "Received Channel 2 packet but channel 2 queue is empty")
      num_chan2_unexpected++;
      return;
    end
    expected = q2.pop_front();
    if (pkt_compare(expected, pkt)) begin
      `uvm_info("PKTCMP", "Channel 2 packet matched", UVM_LOW)
      num_chan2_matched++;
    end
    else begin
      `uvm_error("PKTCMP", $sformatf("Channel 2 packet mismatched:\nExpected: %s\nActual: %s", expected.sprint(), pkt.sprint()))
      num_chan2_mismatched++;
    end
  endfunction : write_chan2

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info(get_type_name(), "Checking Router Scoreboard", UVM_LOW)
    if (num_yapp_in == 0) begin
      `uvm_error(
        get_type_name(),
        "No expected YAPP packets were received from the reference model"
      )
    end
    if (q0.size() || q1.size() || q2.size()) begin
      `uvm_error(
        get_type_name(),
        $sformatf(
          "Scoreboard queues are not empty!\nChannel 0 queue left %0d\nChannel 1 queue left %0d\nChannel 2 queue left %0d",
          q0.size(),
          q1.size(),
          q2.size()
        )
      )
    end
    else begin
      `uvm_info(get_type_name(), "Scoreboard queues are empty", UVM_LOW)
    end
  endfunction : check_phase

  virtual function void report_phase(input uvm_phase phase);
    bit failed;
    super.report_phase(phase);
    `uvm_info(
      get_type_name(),
      $sformatf(
        {
          "Scoreboard Report:\n",
          "  YAPP: received = %0d, invalid = %0d\n",
          "  CH0 : received = %0d, unexpected = %0d, matched = %0d, mismatched = %0d, remaining in queue = %0d\n",
          "  CH1 : received = %0d, unexpected = %0d, matched = %0d, mismatched = %0d, remaining in queue = %0d\n",
          "  CH2 : received = %0d, unexpected = %0d, matched = %0d, mismatched = %0d, remaining in queue = %0d"
        },
        num_yapp_in, num_yapp_invalid,
        num_chan0_in, num_chan0_unexpected, num_chan0_matched, num_chan0_mismatched, q0.size(),
        num_chan1_in, num_chan1_unexpected, num_chan1_matched, num_chan1_mismatched, q1.size(),
        num_chan2_in, num_chan2_unexpected, num_chan2_matched, num_chan2_mismatched, q2.size()
      ),
      UVM_LOW
    )

    failed =
      (num_yapp_in          == 0) ||
      (num_yapp_invalid     != 0) ||
      (num_chan0_mismatched != 0) ||
      (num_chan0_unexpected != 0) ||
      (num_chan1_mismatched != 0) ||
      (num_chan1_unexpected != 0) ||
      (num_chan2_mismatched != 0) ||
      (num_chan2_unexpected != 0) ||
      (q0.size()            != 0) ||
      (q1.size()            != 0) ||
      (q2.size()            != 0);

    if (failed) begin
      `uvm_error(get_type_name(), "Final Status: Simulation FAILED!")
    end
    else begin
      `uvm_info(get_type_name(), "Final Status: Simulation PASSED!", UVM_LOW)
    end
  endfunction : report_phase

endclass : router_scoreboard
