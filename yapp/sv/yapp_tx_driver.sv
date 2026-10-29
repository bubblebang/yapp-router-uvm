class yapp_tx_driver extends uvm_driver #(yapp_packet);

  `uvm_component_utils(yapp_tx_driver)

  protected virtual interface yapp_if vif;

  protected int num_sent;
  protected bit tr_recording_active;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!yapp_vif_config::get(this, "", "vif", vif)) begin
      `uvm_fatal("VIF", {"vif not set for ", get_full_name()})
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    fork
      get_and_drive();
      reset_signals();
    join
  endtask : run_phase

  virtual task get_and_drive();
    wait (vif.reset === 1'b1);
    `uvm_info(get_type_name(), "Reset active", UVM_MEDIUM)
    @(negedge vif.reset);
    `uvm_info(get_type_name(), "Reset dropped", UVM_MEDIUM)

    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), $sformatf("Sending packet:\n%s", req.sprint()), UVM_HIGH)
      tr_recording_active = 1'b0;

      fork : DRIVE_OR_RESET
        drive_one_transaction();
        @(posedge vif.reset);
      join_any

      disable DRIVE_OR_RESET;

      if (vif.reset === 1'b1) begin
        if (tr_recording_active) begin
          end_tr(req);
          tr_recording_active = 1'b0;
        end
        `uvm_warning("RESET_ABORT", "Current YAPP packet was aborted by reset")
        seq_item_port.item_done();
        `uvm_info(get_type_name(), "Reset active", UVM_MEDIUM)
        @(negedge vif.reset);
        `uvm_info(get_type_name(), "Reset dropped", UVM_MEDIUM)
      end
      else begin
        seq_item_port.item_done();
        num_sent++;
      end
    end
  endtask : get_and_drive

  virtual protected task drive_one_transaction();
    fork
      begin : DRIVE_PACKET
        vif.send_to_dut(
          .length       (req.length),
          .addr         (req.addr),
          .payload      (req.payload),
          .parity       (req.parity),
          .packet_delay (req.packet_delay)
        );
      end
      begin : RECORD_PACKET
        @(posedge vif.drvstart);
        void'(begin_tr(req, "Driver_YAPP_Packet"));
        tr_recording_active = 1'b1;
      end
    join

    end_tr(req);
    tr_recording_active = 1'b0;
  endtask : drive_one_transaction

  virtual protected task reset_signals();
    forever begin
      vif.yapp_reset();
    end
  endtask : reset_signals

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(
      get_type_name(),
      $sformatf("Report: YAPP TX driver sent %0d packets", num_sent),
      UVM_LOW
    )
  endfunction : report_phase

endclass : yapp_tx_driver
