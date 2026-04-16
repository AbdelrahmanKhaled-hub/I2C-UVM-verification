package Master_agent_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import Master_sequencer_pkg::*;
import Master_driver_pkg::*;
import Master_monitor_pkg::*;
import Master_seq_item_pkg::*;
import Master_config_pkg::*;

class Master_agent extends uvm_agent;

  `uvm_component_utils(Master_agent)

  
  // Components
  
  Master_sequencer agent_sqr;
  Master_driver    agent_drv;
  Master_monitor   agent_mon;

  Master_config    agent_config;

  uvm_analysis_port #(Master_seq_item) agent_ap;

  
  // Constructor
  
  function new(string name = "Master_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  
  // Build Phase
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Master_config)::get(this, "", "CFG", agent_config))
      `uvm_fatal("AGENT", "Unable to get Master_config object")

    agent_sqr = Master_sequencer::type_id::create("agent_sqr", this);
    agent_drv = Master_driver::type_id::create("agent_drv", this);
    agent_mon = Master_monitor::type_id::create("agent_mon", this);

    agent_ap  = new("agent_ap", this);

  endfunction

  
  // Connect Phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // connect virtual interface from config
    agent_drv.vif = agent_config.vif;
    agent_mon.vif = agent_config.vif;

    // connect sequencer ↔ driver
    agent_drv.seq_item_port.connect(agent_sqr.seq_item_export);

    // connect monitor → agent analysis port
    agent_mon.monitor_ap.connect(agent_ap);

  endfunction

endclass

endpackage