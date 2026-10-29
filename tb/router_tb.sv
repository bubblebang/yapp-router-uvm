class router_tb extends uvm_env;

  yapp_env            yapp;
  channel_env         chan0;
  channel_env         chan1;
  channel_env         chan2;
  hbus_env            hbus;
  clock_and_reset_env clock_and_reset;
  router_mcsequencer  mcseqr;
  router_module_env   router_module;

  yapp_router_regs_vendor_Cadence_Design_Systems_library_Yapp_Registers_version_1_5 yapp_rm;
  hbus_reg_adapter reg2bus;

  `uvm_component_utils_begin(router_tb)
    `uvm_field_object(yapp_rm, UVM_ALL_ON)
  `uvm_component_utils_end

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), {"Build phase of ", get_full_name()}, UVM_HIGH)

    uvm_config_int::set(this, "chan0", "channel_id",  0);
    uvm_config_int::set(this, "chan1", "channel_id",  1);
    uvm_config_int::set(this, "chan2", "channel_id",  2);
    uvm_config_int::set(this, "hbus",  "num_masters", 1);
    uvm_config_int::set(this, "hbus",  "num_slaves",  0);

    yapp            = yapp_env::type_id::create("yapp", this);
    chan0           = channel_env::type_id::create("chan0", this);
    chan1           = channel_env::type_id::create("chan1", this);
    chan2           = channel_env::type_id::create("chan2", this);
    hbus            = hbus_env::type_id::create("hbus", this);
    clock_and_reset = clock_and_reset_env::type_id::create("clock_and_reset", this);
    mcseqr          = router_mcsequencer::type_id::create("mcseqr", this);
    router_module   = router_module_env::type_id::create("router_module", this);

    yapp_rm         = yapp_router_regs_vendor_Cadence_Design_Systems_library_Yapp_Registers_version_1_5::type_id::create("yapp_rm", this);
    yapp_rm.build();
    yapp_rm.lock_model();
    yapp_rm.set_hdl_path_root("hw_top.dut");
    yapp_rm.default_map.set_auto_predict(1);

    reg2bus         = hbus_reg_adapter::type_id::create("reg2bus", this);

  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mcseqr.yapp_seqr = yapp.tx_agent.sequencer;
    mcseqr.hbus_seqr = hbus.masters[0].sequencer;
    yapp.tx_agent.monitor.item_collected_port.connect(router_module.yapp_export);
    hbus.masters[0].monitor.item_collected_port.connect(router_module.hbus_export);
    chan0.rx_agent.monitor.item_collected_port.connect(router_module.chan0_export);
    chan1.rx_agent.monitor.item_collected_port.connect(router_module.chan1_export);
    chan2.rx_agent.monitor.item_collected_port.connect(router_module.chan2_export);
    yapp_rm.default_map.set_sequencer(hbus.masters[0].sequencer, reg2bus);
  endfunction : connect_phase

  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(get_type_name(), {"Start Of Simulation phase of ", get_full_name()}, UVM_HIGH)
  endfunction : start_of_simulation_phase

endclass : router_tb
