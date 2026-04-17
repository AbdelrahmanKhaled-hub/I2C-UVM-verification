`timescale 1ns/10ps

package Master_monitor_pkg;

import uvm_pkg::*;
import Master_seq_item_pkg::*;
`include "uvm_macros.svh"

import Master_seq_item_pkg::*;

class Master_monitor extends uvm_monitor;

  `uvm_component_utils(Master_monitor)

  Master_seq_item req;
  virtual I2C_if vif;

  uvm_analysis_port #(Master_seq_item) monitor_ap;

  function new(string name = "Master_monitor", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    monitor_ap = new("monitor_ap", this);

    if(!uvm_config_db#(virtual I2C_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Virtual interface not set")
  endfunction

task run_phase(uvm_phase phase);
  forever begin
    // Wake up exactly when the RTL evaluates
    @(posedge vif.clk);

    req = Master_seq_item::type_id::create("req");

    // Capture everything
    req.rst   = vif.rst;
    req.start = vif.start;
    req.Data  = vif.Data;
    req.SCL_O = vif.SCL_O;
    req.SDA_O = vif.SDA_O;
    req.SDA_I = vif.SDA_I;

    // Send this specific clock cycle's data to the scoreboard
    monitor_ap.write(req);
  end
endtask

endclass
    
endpackage