package Master_seq_item_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

class Master_seq_item extends uvm_sequence_item;

  `uvm_object_utils(Master_seq_item)

  
  // I2C Transaction Fields
  

  rand logic        rst;
  rand bit          start;

  rand bit [7:0]    Data;        // 8-bit address

  rand bit          SCL_I;       // Clock line
  rand bit          SDA_I;       // Data line

  logic [7:0]       received_data;

  logic SCL_O;       // Clock line output (for driving)
  logic SDA_O;       // Data line output (for driving)

  
  // Constraints
  

  constraint reset_dist {
    rst dist {
      1 := 80,   // normal operation
      0 := 20    // reset active
    };
  }

  function new(string name = "Master_seq_item");
    super.new(name);
  endfunction

endclass

endpackage