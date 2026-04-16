package Master_seq_item_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

class Master_seq_item extends uvm_sequence_item;

  `uvm_object_utils(Master_seq_item)

  
  // I2C Transaction Fields
  

  rand logic        rst;
  rand bit          start;

  rand bit [7:0]    Data;        // data byte

  rand bit          SCL_I;       // slave-side clock (if used)
  rand bit          SDA_I;       // slave-side data (ACK / READ)

  logic [7:0]       received_data;

  logic SCL_O;       // master clock (DUT output)
  logic SDA_O;       // master data (DUT output)

  
  // BURST CONTROL
  

  rand bit          last_byte;   // 1 = generate STOP after this byte
  rand bit          burst;       // 1 = part of burst transfer

  // optional: number of bytes in burst (advanced use)
  rand int unsigned burst_len;

  
  // Constraints
  

  constraint reset_dist {
    rst dist {
      1 := 80,
      0 := 20
    };
  }

  // burst constraints
  constraint burst_ctrl {
    burst_len inside {[1:8]};  // burst size range

    // consistency rule
    if (burst == 0)
      last_byte == 1;  // single transfer always ends
  }

  function new(string name = "Master_seq_item");
    super.new(name);
  endfunction

endclass

endpackage