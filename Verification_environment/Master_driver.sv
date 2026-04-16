package Master_driver_pkg;

import uvm_pkg::*;
import Master_seq_item_pkg::*;
import shared_pkg::*;

`include "uvm_macros.svh"

class Master_driver extends uvm_driver #(Master_seq_item);

  `uvm_component_utils(Master_driver)

  Master_seq_item req;

  virtual I2C_if vif;

  function new(string name = "Master_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(virtual I2C_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "Virtual interface not set")
  endfunction

task run_phase(uvm_phase phase);
  forever begin

    req = new();
    seq_item_port.get_next_item(req);

    
    // Apply control signals
    
    vif.rst   = req.rst;
    vif.start = req.start;
    vif.Data  = req.Data;

    // Default: release SDA (open-drain style)
    vif.SDA_I = 1'b1;

    
    // WRITE WITH START
    
    if(req.start && !req.Data[0]) begin

      @(posedge vif.SCL_O);

      // send 8 bits
      for (int i = 7; i >= 0; i--) begin
        @(negedge vif.SCL_O);
        vif.SDA_I = req.Data[i];
      end

      // ACK phase
      @(negedge vif.SCL_O);
      vif.SDA_I = 1'b0;

      @(posedge vif.SCL_O);

      // release SDA after ACK
      @(negedge vif.SCL_O);
      vif.SDA_I = 1'b1;

    end

    
    // READ WITH START
    
    else if(req.start && req.Data[0]) begin

      @(posedge vif.SCL_O);

      for (int i = 7; i >= 0; i--) begin
        @(negedge vif.SCL_O);
        vif.SDA_I = req.Data[i];
      end

      // release for master ACK/NACK
      @(negedge vif.SCL_O);
      vif.SDA_I = 1'b1;

      @(posedge vif.SCL_O);

    end

    
    // WRITE WITHOUT START
    
    else if(!req.start && !req.Data[0]) begin

      `uvm_info("DRV", "WRITE without START", UVM_LOW)

      for (int i = 7; i >= 0; i--) begin
        @(negedge vif.SCL_O);
        vif.SDA_I = req.Data[i];   // FIX: removed randomization
      end

      // ACK
      @(negedge vif.SCL_O);
      vif.SDA_I = 1'b0;

      @(posedge vif.SCL_O);
      vif.SDA_I = 1'b1;

    end

    
    // READ WITHOUT START
    
    else if(!req.start && req.Data[0]) begin

      `uvm_info("DRV", "READ without START", UVM_LOW)

      for (int i = 7; i >= 0; i--) begin
        @(negedge vif.SCL_O);
        vif.SDA_I = req.Data[i];
      end

      // release bus
      @(negedge vif.SCL_O);
      vif.SDA_I = 1'b1;

      @(posedge vif.SCL_O);

    end

    
    // BURST STOP CONTROL 
    
    if (req.last_byte) begin

      // STOP condition
      @(negedge vif.SCL_O);
      vif.SDA_I = 1'b0;

      @(posedge vif.SCL_O);
      vif.SDA_I = 1'b1;

      `uvm_info("DRV", "STOP generated (burst end)", UVM_LOW)

    end
    else begin
      `uvm_info("DRV", "BURST continue", UVM_LOW)
    end

    seq_item_port.item_done();

  end
endtask
endclass

endpackage