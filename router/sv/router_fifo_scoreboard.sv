class router_fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(router_fifo_scoreboard)

  uvm_tlm_analysis_fifo #(yapp_packet)      yapp_fifo;
  uvm_tlm_analysis_fifo #(hbus_transaction) hbus_fifo;
  uvm_tlm_analysis_fifo #(channel_packet)   chan0_fifo;
  uvm_tlm_analysis_fifo #(channel_packet)   chan1_fifo;
  uvm_tlm_analysis_fifo #(channel_packet)   chan2_fifo;

  uvm_get_port #(yapp_packet) yapp_get_port;
  uvm_get_port #(hbus_transaction) hbus_get_port;
  uvm_get_port #(channel_packet) chan0_get_port;
  uvm_get_port #(channel_packet) chan1_get_port;
  uvm_get_port #(channel_packet) chan2_get_port;

  protected bit [7:0] router_ctrl_reg   = 8'h3f;
  protected bit [7:0] router_enable_reg = 8'h01;

  protected int num_yapp_in, num_yapp_dropped_disabled, num_yapp_dropped_address, num_yapp_dropped_length;
  protected int num_chan0_matched, num_chan0_mismatched;
  protected int num_chan1_matched, num_chan1_mismatched;
  protected int num_chan2_matched, num_chan2_mismatched;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    yapp_fifo  = new("yapp_fifo",  this);
    hbus_fifo  = new("hbus_fifo",  this);
    chan0_fifo = new("chan0_fifo", this);
    chan1_fifo = new("chan1_fifo", this);
    chan2_fifo = new("chan2_fifo", this);

    yapp_get_port  = new("yapp_get_port", this);
    hbus_get_port  = new("hbus_get_port", this);
    chan0_get_port = new("chan0_get_port", this);
    chan1_get_port = new("chan1_get_port", this);
    chan2_get_port = new("chan2_get_port", this);
  endfunction : new

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    yapp_get_port.connect(yapp_fifo.get_peek_export);
    hbus_get_port.connect(hbus_fifo.get_peek_export);
    chan0_get_port.connect(chan0_fifo.get_peek_export);
    chan1_get_port.connect(chan1_fifo.get_peek_export);
    chan2_get_port.connect(chan2_fifo.get_peek_export);
  endfunction : connect_phase

  virtual function bit pkt_compare(yapp_packet yp, channel_packet cp, uvm_comparer comparer = null);
    if (comparer == null) begin
      comparer = new();
    end
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

  virtual task process_yapp();
    yapp_packet    yp;
    channel_packet cp;
    forever begin
      yapp_get_port.get(yp);
      num_yapp_in++;
      `uvm_info(
        get_type_name(),
        $sformatf("Received YAPP Packet:\n%s", yp.sprint()),
        UVM_LOW
      )
      if (yp.addr == 2'b11) begin
        num_yapp_dropped_address++;
        `uvm_info(
          get_type_name(),
          $sformatf("Packet dropped: illegal address = %0d", yp.addr),
          UVM_LOW
        )
      end
      else if (router_enable_reg[0] == 1'b0) begin
        num_yapp_dropped_disabled++;
        `uvm_info(
          get_type_name(),
          "Packet dropped: router disabled",
         UVM_LOW
        )
      end
      else if (yp.length > router_ctrl_reg[5:0]) begin
        num_yapp_dropped_length++;
        `uvm_info(
          get_type_name(),
          $sformatf("Packet dropped: illegal length = %0d", yp.length),
          UVM_LOW
        )
      end
      else begin
        `uvm_info(
          get_type_name(),
          "Valid YAPP packet accepted",
          UVM_LOW
        )
        case(yp.addr)
          2'b00 : begin
            chan0_get_port.get(cp);
            if (pkt_compare(yp, cp)) begin
              num_chan0_matched++;
              `uvm_info(
                get_type_name(),
                "Channel 0 packet matched",
                UVM_LOW
              )
            end
            else begin
              num_chan0_mismatched++;
              `uvm_error(
                "PKTCMP",
                $sformatf(
                  "Channel 0 packet mismatched:\nExpected:\n%s\nActual:\n%s",
                  yp.sprint(),
                  cp.sprint()
                )
              )
            end
          end
          2'b01 : begin
            chan1_get_port.get(cp);
            if (pkt_compare(yp, cp)) begin
              num_chan1_matched++;
              `uvm_info(
                get_type_name(),
                "Channel 1 packet matched",
                UVM_LOW
              )
            end
            else begin
              num_chan1_mismatched++;
              `uvm_error(
                "PKTCMP",
                $sformatf(
                  "Channel 1 packet mismatched:\nExpected:\n%s\nActual:\n%s",
                  yp.sprint(),
                  cp.sprint()
                )
              )
            end
          end
          2'b10 : begin
            chan2_get_port.get(cp);
            if (pkt_compare(yp, cp)) begin
              num_chan2_matched++;
              `uvm_info(
                get_type_name(),
                "Channel 2 packet matched",
                UVM_LOW
              )
            end
            else begin
              num_chan2_mismatched++;
              `uvm_error(
                "PKTCMP",
                $sformatf(
                  "Channel 2 packet mismatched:\nExpected:\n%s\nActual:\n%s",
                  yp.sprint(),
                  cp.sprint()
                )
              )
            end
          end
        endcase
      end
    end
  endtask : process_yapp

  virtual task process_hbus();
    hbus_transaction hbus_tr;
    forever begin
      hbus_get_port.get(hbus_tr);
      `uvm_info(
        get_type_name(),
        $sformatf("Received HBUS Transaction:\n%s", hbus_tr.sprint()),
        UVM_MEDIUM
      )
      if (hbus_tr.hwr_rd == HBUS_WRITE) begin
        case (hbus_tr.haddr)
          16'h1000 : begin
            router_ctrl_reg = hbus_tr.hdata;
            `uvm_info(
              get_type_name(),
              $sformatf("Updated maxpktsize to %0d", router_ctrl_reg[5:0]),
              UVM_MEDIUM
            )
          end
          16'h1001 : begin
            router_enable_reg = hbus_tr.hdata;
            `uvm_info(
              get_type_name(),
              $sformatf("Updated router_en to %0b", router_enable_reg[0]),
              UVM_MEDIUM
            )
          end
        endcase
      end
    end
  endtask : process_hbus

  virtual task run_phase(uvm_phase phase);
    fork
      process_yapp();
      process_hbus();
    join
  endtask : run_phase

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info(get_type_name(), "Checking Router FIFO Scoreboard", UVM_LOW)
    if (
      yapp_fifo.used()  ||
      hbus_fifo.used()  ||
      chan0_fifo.used() ||
      chan1_fifo.used() ||
      chan2_fifo.used()
    ) begin
      `uvm_error(
        get_type_name(),
        $sformatf({
          "Scoreboard FIFOs are not empty!\n",
          "YAPP FIFO contains %0d unprocessed packets\n",
          "HBUS FIFO contains %0d unprocessed packets\n",
          "Channel 0 FIFO contains %0d unexpected packets\n",
          "Channel 1 FIFO contains %0d unexpected packets\n",
          "Channel 2 FIFO contains %0d unexpected packets"},
          yapp_fifo.used(),
          hbus_fifo.used(),
          chan0_fifo.used(),
          chan1_fifo.used(),
          chan2_fifo.used()
        )
      )
    end
    else begin
      `uvm_info(get_type_name(), "Scoreboard FIFOs are empty.", UVM_LOW)
    end
  endfunction : check_phase

  virtual function void report_phase(input uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(
      get_type_name(),
      $sformatf(
        {
          "Scoreboard Report:\n",
          "Number of processed packets = %0d\n",
          "Number of dropped packets due to disabled router = %0d\n",
          "Number of dropped packets due to illegal address = %0d\n",
          "Number of dropped packets due to illegal length = %0d\n",
          "Channel 0: Packet received: %0d; Packet matched: %0d; Packet mismatched: %0d; Packet unexpected: %0d\n",
          "Channel 1: Packet received: %0d; Packet matched: %0d; Packet mismatched: %0d; Packet unexpected: %0d\n",
          "Channel 2: Packet received: %0d; Packet matched: %0d; Packet mismatched: %0d; Packet unexpected: %0d"
        },
        num_yapp_in,
        num_yapp_dropped_disabled,
        num_yapp_dropped_address,
        num_yapp_dropped_length,

        num_chan0_matched + num_chan0_mismatched + chan0_fifo.used(),
        num_chan0_matched,
        num_chan0_mismatched,
        chan0_fifo.used(),

        num_chan1_matched + num_chan1_mismatched + chan1_fifo.used(),
        num_chan1_matched,
        num_chan1_mismatched,
        chan1_fifo.used(),

        num_chan2_matched + num_chan2_mismatched + chan2_fifo.used(),
        num_chan2_matched,
        num_chan2_mismatched,
        chan2_fifo.used()
      ),
      UVM_LOW
    )

    if (
      (num_yapp_in == 0)   ||
      yapp_fifo.used()     ||
      hbus_fifo.used()     ||
      chan0_fifo.used()    ||
      chan1_fifo.used()    ||
      chan2_fifo.used()    ||
      num_chan0_mismatched ||
      num_chan1_mismatched ||
      num_chan2_mismatched ||
      (num_yapp_in !=
      num_yapp_dropped_disabled +
      num_yapp_dropped_address  +
      num_yapp_dropped_length   +
      num_chan0_matched         +
      num_chan0_mismatched      +
      num_chan1_matched         +
      num_chan1_mismatched      +
      num_chan2_matched         +
      num_chan2_mismatched)
    ) begin
      `uvm_error(get_type_name(), "Final Status: Simulation FAILED!")
    end
    else begin
      `uvm_info(get_type_name(), "Final Status: Simulation PASSED!", UVM_LOW)
    end
  endfunction : report_phase

endclass : router_fifo_scoreboard
