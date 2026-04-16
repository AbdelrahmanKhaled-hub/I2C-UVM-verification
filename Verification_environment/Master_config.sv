package Master_config_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

class Master_config extends uvm_object;

  `uvm_object_utils(Master_config)

  function new(string name = "Master_config");
    super.new(name);
  endfunction

endclass

endpackage