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
  bit prev_sda;

  forever begin

    req = new();

    
    // WAIT FOR CLOCK EDGE
    
    @(posedge vif.SCL_O);

    
    // START DETECTION
    // SDA: 1 → 0 while SCL = 1
    
    if (prev_sda == 1 && vif.SDA_O == 0 && vif.SCL_O == 1) begin
      `uvm_info("MON", "START detected", UVM_LOW)
    end

    
    // CAPTURE BYTE
    
    for (int i = 7; i >= 0; i--) begin
      @(posedge vif.SCL_O);
      req.Data[i] = vif.SDA_O;
    end

    
    // ACK / NACK CAPTURE
    
    @(posedge vif.SCL_O);
    req.SDA_I = vif.SDA_I;

    
    // STOP DETECTION (IMPORTANT FIX)
    // SDA: 0 → 1 while SCL = 1
    
    if (prev_sda == 0 && vif.SDA_O == 1 && vif.SCL_O == 1) begin
      `uvm_info("MON", "STOP detected (burst end)", UVM_LOW)
    end

    
    // STORE BUS STATE
    
    req.rst   = vif.rst;
    req.start = vif.start;
    req.SCL_O = vif.SCL_O;
    req.SDA_O = vif.SDA_O;

    // update previous SDA
    prev_sda = vif.SDA_O;

    
    // SEND TO SCOREBOARD
    
    `uvm_info("Master_monitor",
      $sformatf("Captured Data=%0h ACK=%0b",
                req.Data, req.SDA_I),
      UVM_MEDIUM)

    monitor_ap.write(req);

  end
endtask

endclass
    
endpackage