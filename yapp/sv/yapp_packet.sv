typedef enum bit {
  GOOD_PARITY,
  BAD_PARITY
} parity_type_e;

class yapp_packet extends uvm_sequence_item;

  // protocol data
  rand bit [5:0] length;
  rand bit [1:0] addr;
  rand bit [7:0] payload[];
  bit [7:0] parity;

  // control knobs
  rand parity_type_e parity_type;
  rand int packet_delay;

  // automation of the packet's fields
  `uvm_object_utils_begin(yapp_packet)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(length, UVM_ALL_ON)
    `uvm_field_array_int(payload, UVM_ALL_ON)
    `uvm_field_int(parity, UVM_ALL_ON)
    `uvm_field_enum(parity_type_e, parity_type, UVM_ALL_ON)
    `uvm_field_int(packet_delay, UVM_ALL_ON | UVM_DEC | UVM_NOCOMPARE)
  `uvm_object_utils_end

  // packet constraints
  constraint addr_c {
    addr inside {[0:2]};
  }

  constraint length_c {
    length inside {[1:63]};
    length == payload.size();
  }

  constraint parity_type_c {
    parity_type dist {
      GOOD_PARITY := 5,
      BAD_PARITY  := 1
    };
  }

  constraint packet_delay_c {
    packet_delay inside {[0:19]};
  }

  function new(string name = "yapp_packet");
    super.new(name);
  endfunction

  function bit [7:0] calc_parity();
   calc_parity = {length, addr};
   foreach(payload[i]) begin
     calc_parity ^= payload[i];
   end
  endfunction

  function void set_parity();
    if (parity_type == GOOD_PARITY)
      parity = calc_parity();
    else
      parity = ~calc_parity();
  endfunction

  function void post_randomize();
    set_parity();
  endfunction

endclass: yapp_packet

class short_yapp_packet extends yapp_packet;

  `uvm_object_utils(short_yapp_packet)

  function new(string name = "short_yapp_packet");
    super.new(name);
  endfunction

  constraint short_length_c {
    length < 15;
  }

endclass : short_yapp_packet
