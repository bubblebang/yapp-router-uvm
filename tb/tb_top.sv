module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import yapp_pkg::*;
  import channel_pkg::*;
  import clock_and_reset_pkg::*;
  import hbus_pkg::*;
  import router_module_pkg::*;
  import yapp_router_reg_pkg::*;

  `include "router_mcsequencer.sv"
  `include "router_mcseqs_lib.sv"
  `include "router_tb.sv"
  `include "router_test_lib.sv"

  initial begin
    yapp_vif_config::set(
      null,
      "uvm_test_top.tb.yapp.tx_agent.*",
      "vif",
      hw_top.in0
    );

    channel_vif_config::set(
      null,
      "uvm_test_top.tb.chan0.*",
      "vif",
      hw_top.ch0
    );

    channel_vif_config::set(
      null,
      "uvm_test_top.tb.chan1.*",
      "vif",
      hw_top.ch1
    );

    channel_vif_config::set(
      null,
      "uvm_test_top.tb.chan2.*",
      "vif",
      hw_top.ch2
    );

    clock_and_reset_vif_config::set(
      null,
      "uvm_test_top.tb.clock_and_reset.*",
      "vif",
      hw_top.cr
    );

    hbus_vif_config::set(
      null,
      "uvm_test_top.tb.hbus.*",
      "vif",
      hw_top.hb
    );

    run_test();

  end

endmodule : tb_top
