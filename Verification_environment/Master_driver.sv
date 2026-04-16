package Master_driver_pkg;

import uvm_pkg::*;
import Master_seq_item_pkg::*;
import shared_pkg::*;

`include "uvm_macros.svh"

class Master_driver extends uvm_driver #(Master_seq_item);

  `uvm_component_utils(Master_driver)

  Master_seq_item req;

  virtual I2C_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(virtual I2C_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "Virtual interface not set")
  endfunction

task run_phase(uvm_phase phase);
  forever begin

    seq_item_port.get_next_item(req);

    @(negedge vif.clk);

    if(!stop_driving) begin
      vif.rst   = req.rst;
      vif.start = req.start;

      vif.Data  = req.Data;

      vif.SCL_I = req.SCL_I;
      vif.SDA_I = req.SDA_I;
    end

    seq_item_port.item_done();

    `uvm_info("Master_driver",
      $sformatf("Sent data: %0h", req.Data),
      UVM_MEDIUM)

  end
endtask

endclass

endpackage