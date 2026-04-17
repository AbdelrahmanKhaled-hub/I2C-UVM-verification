package Master_config_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

class Master_config extends uvm_object;

  `uvm_object_utils(Master_config)

  // Configuration parameters for the Master agent
  virtual I2C_if vif;

  function new(string name = "Master_config");
    super.new(name);
  endfunction

endclass

endpackage