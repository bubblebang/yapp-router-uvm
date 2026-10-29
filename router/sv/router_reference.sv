`uvm_analysis_imp_decl(_yapp)
`uvm_analysis_imp_decl(_hbus)

class router_reference extends uvm_component;
  `uvm_component_utils(router_reference)

  uvm_analysis_imp_yapp #(yapp_packet, router_reference) yapp_in;
  uvm_analysis_imp_hbus #(hbus_transaction, router_reference) hbus_in;
  uvm_analysis_port #(yapp_packet) yapp_valid;

  protected bit [7:0] router_ctrl_reg   = 8'h3f;
  protected bit [7:0] router_enable_reg = 8'h01;

  protected int num_packet_forwarded;
  protected int num_packet_dropped_disabled;
  protected int num_packet_dropped_bad_addr;
  protected int num_packet_dropped_bad_length;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    yapp_in = new("yapp_in", this);
    hbus_in = new("hbus_in", this);
    yapp_valid = new("yapp_valid", this);
  endfunction : new

  virtual function void write_hbus(hbus_transaction hbus_tr);
    `uvm_info(
      get_type_name(),
      $sformatf("Received HBUS Transaction:\n%s", hbus_tr.sprint()),
      UVM_MEDIUM
    )
    if (hbus_tr.hwr_rd == HBUS_WRITE) begin
      case (hbus_tr.haddr)
        16'h1000 : router_ctrl_reg   = hbus_tr.hdata;
        16'h1001 : router_enable_reg = hbus_tr.hdata;
      endcase
    end
  endfunction : write_hbus

  virtual function void write_yapp(yapp_packet pkt);
    `uvm_info(
      get_type_name(),
      $sformatf("Received YAPP Packet:\n%s", pkt.sprint()),
      UVM_LOW
    )
    if (pkt.addr == 2'b11) begin
      num_packet_dropped_bad_addr++;
      `uvm_info(
        get_type_name(),
        $sformatf("Packet dropped: illegal address = %0d", pkt.addr),
        UVM_LOW
      )
    end
    else if (router_enable_reg[0] == 1'b0) begin
      num_packet_dropped_disabled++;
      `uvm_info(
        get_type_name(),
        "Packet dropped: router disabled",
        UVM_LOW
      )
    end
    else if (pkt.length > router_ctrl_reg[5:0]) begin
      num_packet_dropped_bad_length++;
      `uvm_info(
        get_type_name(),
        $sformatf("Packet dropped: illegal length = %0d", pkt.length),
        UVM_LOW
      )
    end
    else begin
      yapp_valid.write(pkt);
      num_packet_forwarded++;
      `uvm_info(
        get_type_name(),
        "Packet forwarded to scoreboard",
        UVM_LOW
      )
    end
  endfunction : write_yapp

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(
      get_type_name(),
      $sformatf({
        "Reference Model Report:\n",
        "  Number of forwarded packets = %0d\n",
        "  Number of dropped packets due to disabled router = %0d\n",
        "  Number of dropped packets due to illegal address = %0d\n",
        "  Number of dropped packets due to illegal length = %0d"},
        num_packet_forwarded,
        num_packet_dropped_disabled,
        num_packet_dropped_bad_addr,
        num_packet_dropped_bad_length
      ),
      UVM_LOW
    )
  endfunction : report_phase

endclass : router_reference
