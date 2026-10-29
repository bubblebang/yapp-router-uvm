class router_simple_mcseq extends uvm_sequence;

  `uvm_object_utils(router_simple_mcseq)
  `uvm_declare_p_sequencer(router_mcsequencer)

  hbus_small_packet_seq hbus_small;
  hbus_read_max_pkt_seq hbus_read;
  hbus_set_default_regs_seq hbus_large;
  yapp_012_seq yapp_012;
  six_yapp_seq yapp_six;

  function new(string name = "router_simple_mcseq");
    super.new(name);
  endfunction

  virtual task body();
    uvm_phase starting_phase = get_starting_phase();

    if (starting_phase != null)
      starting_phase.raise_objection(this, get_type_name());

    // Configure the small-packet limit and send traffic to all three channels.
    `uvm_do_on(hbus_small, p_sequencer.hbus_seqr)
    `uvm_do_on(hbus_read,  p_sequencer.hbus_seqr)
    `uvm_do_on(yapp_012,   p_sequencer.yapp_seqr)
    `uvm_do_on(yapp_012,   p_sequencer.yapp_seqr)

    // Restore default register settings and send six packets.
    `uvm_do_on(hbus_large, p_sequencer.hbus_seqr)
    `uvm_do_on(hbus_read,  p_sequencer.hbus_seqr)
    `uvm_do_on(yapp_six,   p_sequencer.yapp_seqr)

    if (starting_phase != null)
      starting_phase.drop_objection(this, get_type_name());
  endtask

endclass : router_simple_mcseq
