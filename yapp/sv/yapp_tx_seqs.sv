class yapp_base_seq extends uvm_sequence #(yapp_packet);

  `uvm_object_utils(yapp_base_seq)

  function new(string name="yapp_base_seq");
    super.new(name);
  endfunction

  virtual task pre_body();
    uvm_phase phase;
    phase = get_starting_phase();
    if (phase != null) begin
      phase.raise_objection(this, get_type_name());
      `uvm_info(get_type_name(), "raise objection", UVM_MEDIUM)
    end
  endtask : pre_body

  virtual task post_body();
    uvm_phase phase;
    phase = get_starting_phase();
    if (phase != null) begin
      phase.drop_objection(this, get_type_name());
      `uvm_info(get_type_name(), "drop objection", UVM_MEDIUM)
    end
  endtask : post_body

endclass : yapp_base_seq

class yapp_5_packets extends yapp_base_seq;

  `uvm_object_utils(yapp_5_packets)

  function new(string name="yapp_5_packets");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_5_packets sequence", UVM_LOW)
    repeat(5) begin
      `uvm_do(req)
    end
  endtask

endclass : yapp_5_packets

class yapp_1_seq extends yapp_base_seq;

  `uvm_object_utils(yapp_1_seq)

  function new(string name = "yapp_1_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_1_seq", UVM_LOW)
    `uvm_do_with(req, { addr == 1; })
  endtask

endclass : yapp_1_seq

class yapp_012_seq extends yapp_base_seq;

  `uvm_object_utils(yapp_012_seq)

  function new(string name = "yapp_012_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_012_seq", UVM_LOW)
    for (int i = 0; i < 3; i++) begin
      req = yapp_packet::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { addr == i; })
        `uvm_fatal("RANDFAILED", $sformatf("Randomization failed in %s", get_type_name()))
      finish_item(req);
    end
  endtask

endclass : yapp_012_seq

class yapp_111_seq extends yapp_base_seq;

  yapp_1_seq seq1;

  `uvm_object_utils(yapp_111_seq)

  function new(string name = "yapp_111_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(
      get_type_name(),
      $sformatf("Executing %s", get_type_name()),
      UVM_LOW
    )
    repeat (3) begin
      `uvm_do(seq1)
    end
  endtask

endclass : yapp_111_seq

class yapp_repeat_addr_seq extends yapp_base_seq;

  rand bit [1:0] seq_addr;

  constraint valid_addr_c {
    seq_addr inside {[0:2]};
  }

  `uvm_object_utils(yapp_repeat_addr_seq)

  function new(string name = "yapp_repeat_addr_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(
      get_type_name(),
      $sformatf("Executing %s", get_type_name()),
      UVM_LOW
    )
    repeat(2) begin
      `uvm_do_with(req, { addr == seq_addr; })
    end
  endtask

endclass : yapp_repeat_addr_seq

class yapp_incr_payload_seq extends yapp_base_seq;

  `uvm_object_utils(yapp_incr_payload_seq)

  function new(string name = "yapp_incr_payload_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(),
              $sformatf("Executing %s", get_type_name()),
              UVM_LOW
    )

    /*
    req = yapp_packet::type_id::create("req");
    start_item(req);
    if (!req.randomize()) begin
      `uvm_fatal("RANDFAILED", $sformatf("Randomization failed in %s", get_type_name()))
    end
    foreach (req.payload[i]) begin
      req.payload[i] = i;
    end
    req.set_parity();
    finish_item(req);
    */

    `uvm_create(req)
    if (!req.randomize()) begin
      `uvm_fatal("RANDFAILED", $sformatf("Randomization failed in %s", get_type_name()))
    end
    foreach (req.payload[i]) begin
      req.payload[i] = i;
    end
    req.set_parity();
    `uvm_send(req)

  endtask

endclass : yapp_incr_payload_seq


class yapp_rnd_seq extends yapp_base_seq;

  `uvm_object_utils(yapp_rnd_seq)

  rand int count;

  constraint count_c {
    count inside {[1:10]};
  }

  function new(string name = "yapp_rnd_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(
      get_type_name(),
      $sformatf("Executing %s, count = %0d", get_type_name(), count),
      UVM_LOW
    )
    repeat(count) begin
      `uvm_do(req)
    end
  endtask

endclass : yapp_rnd_seq


class six_yapp_seq extends yapp_base_seq;

  `uvm_object_utils(six_yapp_seq)

  yapp_rnd_seq seq_rnd;

  function new(string name = "six_yapp_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(
      get_type_name(),
      $sformatf("Executing %s", get_type_name()),
      UVM_LOW
    )
    `uvm_do_with(seq_rnd, { count == 6; })
  endtask

endclass : six_yapp_seq


class yapp_exhaustive_seq extends yapp_base_seq;

  yapp_1_seq seq_1;
  yapp_012_seq seq_012;
  yapp_111_seq seq_111;
  yapp_repeat_addr_seq seq_repeat;
  yapp_incr_payload_seq seq_incr;
  yapp_rnd_seq seq_rnd;
  six_yapp_seq seq_six_rnd;

  `uvm_object_utils(yapp_exhaustive_seq)

  function new(string name = "yapp_exhaustive_seq");
    super.new(name);
  endfunction

  virtual task body();
  `uvm_info(
    get_type_name(),
    $sformatf("Executing %s", get_type_name()),
    UVM_LOW
  )

  `uvm_do(seq_1)
  `uvm_do(seq_012)
  `uvm_do(seq_111)
  `uvm_do(seq_repeat)
  `uvm_do(seq_incr)
  `uvm_do(seq_rnd)
  `uvm_do(seq_six_rnd)
  endtask

endclass : yapp_exhaustive_seq


class test_uvc_seq extends yapp_base_seq;
  `uvm_object_utils(test_uvc_seq)

  function new(string name = "test_uvc_seq");
    super.new(name);
  endfunction

  virtual task body();
   `uvm_info(
      get_type_name(),
      $sformatf("Executing %s", get_type_name()),
      UVM_LOW
    )
  `uvm_create(req)
  req.packet_delay = 1;
  for (int addr_i = 0; addr_i < 4; addr_i++) begin
    req.addr = addr_i;
    for (int length_i = 1; length_i < 23; length_i++) begin
      req.length = length_i;
      req.payload = new[length_i];
      foreach (req.payload[i])
        req.payload[i] = i;
      randcase
        80: req.parity_type = GOOD_PARITY;
        20: req.parity_type = BAD_PARITY;
      endcase
      req.set_parity();
      `uvm_send(req)
    end
  end
  endtask

endclass : test_uvc_seq

class yapp_funct_cov_seq extends yapp_base_seq;
  `uvm_object_utils(yapp_funct_cov_seq)

  function new(string name = "yapp_funct_cov_seq");
    super.new(name);
  endfunction

  virtual task body();
    int length_arr [11] = '{1, 2, 5, 10, 11, 35, 40, 41, 55, 62, 63};
    `uvm_info(get_type_name(), $sformatf("Executing %s", get_type_name()), UVM_LOW)
    foreach (length_arr[i]) begin
      for (int addr_i = 0; addr_i < 3; addr_i++) begin
        req = yapp_packet::type_id::create("req");
        start_item(req);
        if (!req.randomize() with {
          length      == length_arr[i];
          addr        == addr_i;
          parity_type == GOOD_PARITY;
        }) begin
          `uvm_fatal("RANDFAILED", $sformatf("Randomization failed in %s", get_type_name()))
        end
        finish_item(req);
      end
    end
  endtask
endclass : yapp_funct_cov_seq

class yapp_illegal_addr_cov_seq extends yapp_base_seq;
  `uvm_object_utils(yapp_illegal_addr_cov_seq)

  function new(string name = "yapp_illegal_addr_cov_seq");
    super.new(name);
  endfunction

  virtual task body();
    int length_arr [11] = '{1, 2, 5, 10, 11, 35, 40, 41, 55, 62, 63};
    `uvm_info(get_type_name(), $sformatf("Executing %s", get_type_name()), UVM_LOW)
    foreach (length_arr[i]) begin
      req = yapp_packet::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        length      == length_arr[i];
        parity_type == GOOD_PARITY;
      }) begin
        `uvm_fatal("RANDFAILED", $sformatf("Randomization failed in %s", get_type_name()))
      end
      req.addr = 3;
      req.set_parity();
      finish_item(req);
    end
  endtask
endclass : yapp_illegal_addr_cov_seq

class yapp_bad_parity_cov_seq extends yapp_base_seq;
  `uvm_object_utils(yapp_bad_parity_cov_seq)

  function new(string name = "yapp_bad_parity_cov_seq");
    super.new(name);
  endfunction

  virtual task body();
    int length_arr [11] = '{1, 2, 5, 10, 11, 35, 40, 41, 55, 62, 63};
    `uvm_info(get_type_name(), $sformatf("Executing %s", get_type_name()), UVM_LOW)
    foreach (length_arr[i]) begin
      for (int addr_i = 0; addr_i < 3; addr_i++) begin
        req = yapp_packet::type_id::create("req");
        start_item(req);
        if (!req.randomize() with {
          length      == length_arr[i];
          addr        == addr_i;
          parity_type == BAD_PARITY;
        }) begin
          `uvm_fatal("RANDFAILED", $sformatf("Randomization failed in %s", get_type_name()))
        end
        finish_item(req);
      end
    end
  endtask
endclass : yapp_bad_parity_cov_seq
