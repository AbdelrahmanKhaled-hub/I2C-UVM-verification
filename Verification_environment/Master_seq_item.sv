package Master_seq_item_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

class Master_seq_item extends uvm_sequence_item;
  `uvm_object_utils(Master_seq_item)

  // System Control
  rand logic        rst;
  rand bit          start;
  rand bit [7:0]    Data;           // 7-bit Address + 1-bit R/W

  // Captured Protocol Signals (Not randomized)
  logic             SDA_I;         // Captured ACK/NACK
  logic [7:0]       received_data; // Captured read payload

  // Burst Control (Higher-level stimulus)
  rand bit          last_byte;     // 1 = generate STOP after this byte
  rand bit          burst;         // 1 = part of burst transfer
  rand int unsigned burst_len;     

  // Constraints
  constraint reset_dist {
    rst dist {
      1 := 80, // Normal operation
      0 := 20  // Reset active
    };
  }

  constraint burst_ctrl {
    burst_len inside {[1:8]};
    if (burst == 0) {
      last_byte == 1; // Single transfers must end
    }
  }

  function new(string name = "Master_seq_item");
    super.new(name);
  endfunction

endclass
endpackage