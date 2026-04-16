package Master_sequencer_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

class Master_sequencer extends uvm_sequencer;

  `uvm_component_utils(Master_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

endpackage