typedef enum bit {
  COV_ENABLE,
  COV_DISABLE
} cover_e;

class yapp_tx_monitor extends uvm_monitor;

  protected virtual interface yapp_if vif;

  uvm_analysis_port#(yapp_packet) item_collected_port;

  protected yapp_packet pkt;
  protected int num_pkt_col;
  protected bit tr_recording_active;

  cover_e coverage_control = COV_ENABLE;

  `uvm_component_utils_begin(yapp_tx_monitor)
    `uvm_field_enum(cover_e, coverage_control, UVM_ALL_ON)
  `uvm_component_utils_end

  covergroup collected_pkt_cg;
    option.per_instance = 1;
    cp_length : coverpoint pkt.length {
      bins MIN    = {1};
      bins SMALL  = {[2:10]};
      bins MEDIUM = {[11:40]};
      bins LARGE  = {[41:62]};
      bins MAX    = {63};
    }
    cp_addr : coverpoint pkt.addr {
      bins addr[]  = {[0:2]};
      bins illegal = {3};
    }
    cp_parity : coverpoint pkt.parity_type {
      bins good = {GOOD_PARITY};
      bins bad = {BAD_PARITY};
    }
    cross_length_addr : cross cp_length, cp_addr;
    cross_length_addr_012_parity_bad :
      cross cp_length, cp_addr, cp_parity {
        ignore_bins addr_illegal = binsof(cp_addr.illegal);
        ignore_bins parity_good = binsof(cp_parity.good);
      }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
    collected_pkt_cg = new();
    collected_pkt_cg.set_inst_name({get_full_name(), ".collected_pkt_cg"});
    `uvm_info(get_type_name(), {get_type_name(), " COVERAGE CREATED"}, UVM_LOW)
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!yapp_vif_config::get(this, "", "vif", vif)) begin
      `uvm_fatal("VIF", {"vif not set for ", get_full_name()})
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);

    wait (vif.reset === 1'b1);
    `uvm_info(get_type_name(), "Reset active", UVM_MEDIUM)
    @(negedge vif.reset);
    `uvm_info(get_type_name(), "Reset dropped", UVM_MEDIUM)

    forever begin
      pkt = yapp_packet::type_id::create("pkt", this);
      tr_recording_active = 1'b0;

      fork : COLLECT_OR_RESET
        collect_one_transaction();
        @(posedge vif.reset);
      join_any

      disable COLLECT_OR_RESET;

      if (vif.reset === 1'b1) begin
        if (tr_recording_active) begin
          end_tr(pkt);
          tr_recording_active = 1'b0;
        end
        `uvm_info(get_type_name(), "Reset active", UVM_MEDIUM)
        @(negedge vif.reset);
        `uvm_info(get_type_name(), "Reset dropped", UVM_MEDIUM)
      end
    end
  endtask : run_phase

  virtual protected task collect_one_transaction();
    fork
      vif.collect_packet(
            .length(pkt.length),
            .addr(pkt.addr),
            .payload(pkt.payload),
            .parity(pkt.parity)
      );

      begin
        @(posedge vif.monstart);
        void'(begin_tr(pkt, "Monitor_YAPP_Packet"));
        tr_recording_active = 1'b1;
      end
    join

    pkt.parity_type = (pkt.parity == pkt.calc_parity()) ? GOOD_PARITY : BAD_PARITY;
    end_tr(pkt);
    tr_recording_active = 1'b0;
    `uvm_info(get_type_name(), $sformatf("Packet collected:\n%s", pkt.sprint()), UVM_LOW)

    if ((coverage_control == COV_ENABLE) && (collected_pkt_cg != null)) begin
      collected_pkt_cg.sample();
      `uvm_info(get_type_name(), {get_type_name(), " COVERAGE SAMPLED"}, UVM_LOW)
    end

    item_collected_port.write(pkt);
    num_pkt_col++;
  endtask : collect_one_transaction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(
      get_type_name(),
      $sformatf("Report: YAPP TX monitor collected %0d packets", num_pkt_col),
      UVM_LOW
    )
    if ((coverage_control == COV_ENABLE) && (collected_pkt_cg != null)) begin
      `uvm_info(
        "COVERAGE",
        $sformatf(
          {
            "\nYAPP Coverage:",
            "\n  length              = %0.2f%%",
            "\n  address             = %0.2f%%",
            "\n  parity              = %0.2f%%",
            "\n  length x address    = %0.2f%%",
            "\n  len x addr x badpar = %0.2f%%",
            "\n  overall             = %0.2f%%"
          },
          collected_pkt_cg.cp_length.get_inst_coverage(),
          collected_pkt_cg.cp_addr.get_inst_coverage(),
          collected_pkt_cg.cp_parity.get_inst_coverage(),
          collected_pkt_cg.cross_length_addr.get_inst_coverage(),
          collected_pkt_cg.cross_length_addr_012_parity_bad.get_inst_coverage(),
          collected_pkt_cg.get_inst_coverage()
        ),
        UVM_NONE
      )
    end
  endfunction : report_phase

endclass : yapp_tx_monitor
