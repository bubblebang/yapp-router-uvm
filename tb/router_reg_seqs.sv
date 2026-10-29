class router_reg_access_seq extends uvm_reg_sequence;

  yapp_regs_c regs;

  `uvm_object_utils(router_reg_access_seq)

  function new (string name = "router_reg_access_seq");
    super.new(name);
  endfunction

  virtual task body();
    uvm_status_e   status;
    uvm_reg_data_t rdata;

    if (regs == null) begin
      `uvm_fatal("REG_ACCESS", "regs was not assigned")
    end

    `uvm_info("REG_ACCESS", "Checking RW en_reg", UVM_NONE)

    regs.en_reg.write(status, 8'hA5, UVM_FRONTDOOR);
    if (status != UVM_IS_OK) begin
      `uvm_error("REG_ACCESS", "Frontdoor write to en_reg failed")
    end
    regs.en_reg.peek(status, rdata);
    if (status != UVM_IS_OK || rdata[7:0] !== 8'hA5) begin
      `uvm_error("REG_ACCESS", $sformatf("en_reg peek: expected A5, got %02h (status %s)", rdata[7:0], status.name()))
    end
    regs.en_reg.poke(status, 8'h52);
    if (status != UVM_IS_OK) begin
      `uvm_error("REG_ACCESS", "Backdoor poke of en_reg failed")
    end
    regs.en_reg.read(status, rdata, UVM_FRONTDOOR);
    if (status != UVM_IS_OK || rdata[7:0] !== 8'h52) begin
      `uvm_error("REG_ACCESS", $sformatf("en_reg read: expected 52, got %02h (status %s)", rdata[7:0], status.name()))
    end

    `uvm_info("REG_ACCESS", "Checking RO addr0_cnt_reg", UVM_NONE)

    regs.addr0_cnt_reg.poke(status, 8'hA5);
    if (status != UVM_IS_OK) begin
      `uvm_error("REG_ACCESS", "Backdoor poke of addr0_cnt_reg failed")
    end
    regs.addr0_cnt_reg.read(status, rdata, UVM_FRONTDOOR);
    if (status != UVM_IS_OK || rdata[7:0] !== 8'hA5) begin
      `uvm_error("REG_ACCESS", $sformatf("addr0_cnt_reg read: expected A5, got %02h (status %s)", rdata[7:0], status.name()))
    end
    // The bus write is attempted; a read-only counter should retain A5.
    regs.addr0_cnt_reg.write(status, 8'h5A, UVM_FRONTDOOR);
    regs.addr0_cnt_reg.peek(status, rdata);
    if (status != UVM_IS_OK || rdata[7:0] !== 8'hA5) begin
      `uvm_error("REG_ACCESS", $sformatf("addr0_cnt_reg changed after write: expected A5, got %02h", rdata[7:0]))
    end
  endtask : body

endclass : router_reg_access_seq
