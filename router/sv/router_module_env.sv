class router_module_env extends uvm_env;
  `uvm_component_utils(router_module_env)

  router_fifo_scoreboard fifo_scoreboard;

  uvm_analysis_export #(yapp_packet)      yapp_export;
  uvm_analysis_export #(hbus_transaction) hbus_export;
  uvm_analysis_export #(channel_packet)   chan0_export;
  uvm_analysis_export #(channel_packet)   chan1_export;
  uvm_analysis_export #(channel_packet)   chan2_export;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    yapp_export  = new("yapp_export",  this);
    hbus_export  = new("hbus_export",  this);
    chan0_export = new("chan0_export", this);
    chan1_export = new("chan1_export", this);
    chan2_export = new("chan2_export", this);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    fifo_scoreboard = router_fifo_scoreboard::type_id::create("fifo_scoreboard", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    yapp_export.connect(fifo_scoreboard.yapp_fifo.analysis_export);
    hbus_export.connect(fifo_scoreboard.hbus_fifo.analysis_export);
    chan0_export.connect(fifo_scoreboard.chan0_fifo.analysis_export);
    chan1_export.connect(fifo_scoreboard.chan1_fifo.analysis_export);
    chan2_export.connect(fifo_scoreboard.chan2_fifo.analysis_export);
  endfunction : connect_phase

endclass : router_module_env
