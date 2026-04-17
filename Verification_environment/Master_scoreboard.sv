package Master_scoreboard_pg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Master_seq_item_pkg::*;
  import Master_shared_pkg::*;

  // Forward declarations
  typedef class Idle_state;
  typedef class Start_state;
  typedef class Address_state;
  typedef class Write_state;
  typedef class Read_state;
  typedef class Ack_send_state;
  typedef class Ack_check_state;
  typedef class stop_state;

  // BASE STATE
  class State;
    
    // Added a virtual name function for UVM error reporting
    virtual function string get_name();
      return "Base_State";
    endfunction

    virtual function State transition(Master_seq_item item);
      return this;
    endfunction

    function State reset_triggered();
      Idle_state s = new();
      return s;
    endfunction

    function State go_to_idle_state();
      Idle_state s = new();
      return s;
    endfunction

    function State go_to_start_state();
      Start_state s = new();
      return s;
    endfunction

    function State go_to_address_state();
      Address_state s = new();
      return s;
    endfunction

    function State go_to_write_state();
      Write_state s = new();
      return s;
    endfunction

    function State go_to_read_state();
      Read_state s = new();
      return s;
    endfunction

    function State go_to_ack_send_state();
      Ack_send_state s = new();
      return s;
    endfunction

    function State go_to_ack_check_state();
      Ack_check_state s = new();
      return s;
    endfunction

    function State go_to_stop_state();
      stop_state s = new();
      return s;
    endfunction

  endclass


  // IDLE STATE
  class Idle_state extends State;
    virtual function string get_name(); return "Idle_state"; endfunction

    function State transition(Master_seq_item item);
      if (~rst_n) begin
        SCL_O_ref = 1;
        SDA_O_ref = 1;
        received_data_ref = '0;
        return reset_triggered();
      end

      if (item.start) begin
        SCL_O_ref = 1;
        SDA_O_ref = 1;
        return go_to_start_state();
      end

      return this;
    endfunction
  endclass


  // START STATE
  class Start_state extends State;
    virtual function string get_name(); return "Start_state"; endfunction

    function State transition(Master_seq_item item);
      if (~rst_n) begin
          SCL_O_ref = 1;
          SDA_O_ref = 1;
          received_data_ref = '0;
          return reset_triggered();
      end

      SCL_O_ref = 1;
      SDA_O_ref = 0; // START condition (SDA drops while SCL is high)

      return go_to_address_state();
    endfunction
  endclass


  // ADDRESS STATE (Fixed with cycle counter)
  class Address_state extends State;
    int bit_cnt = 7; // Tracks progress across multiple clock cycles
    
    virtual function string get_name(); return "Address_state"; endfunction

    function State transition(Master_seq_item item);
      if (~rst_n) begin
          SCL_O_ref = 1;
          SDA_O_ref = 1;
          received_data_ref = '0;
          bit_cnt = 7;
          return reset_triggered();
      end

      SCL_O_ref = ~SCL_O_ref;
      SDA_O_ref = item.data[bit_cnt]; // Drive current bit

      if (bit_cnt == 0) begin
        bit_cnt = 7; // Reset counter for the next time this state is used
        if (item.data[0] == 0)
          return go_to_write_state();
        else
          return go_to_read_state();
      end else begin
        bit_cnt--;
        return this; // Stay in this state until all 8 bits are done
      end
    endfunction
  endclass


  // WRITE STATE (Fixed with cycle counter)
  class Write_state extends State;
    int bit_cnt = 7;
    
    virtual function string get_name(); return "Write_state"; endfunction

    function State transition(Master_seq_item item);
      if (~rst_n) begin
          SCL_O_ref = 1;
          SDA_O_ref = 1;
          received_data_ref = '0;
          bit_cnt = 7;
          return reset_triggered();
      end

      data_old = item.data;
      SCL_O_ref = ~SCL_O_ref;
      SDA_O_ref = item.data[bit_cnt];

      if (bit_cnt == 0) begin
        bit_cnt = 7;
        return go_to_ack_check_state();
      end else begin
        bit_cnt--;
        return this;
      end
    endfunction
  endclass


  // READ STATE (Fixed with cycle counter)
  class Read_state extends State;
    int bit_cnt = 7;
    
    virtual function string get_name(); return "Read_state"; endfunction

    function State transition(Master_seq_item item);
      if (~rst_n) begin
          SCL_O_ref = 1;
          SDA_O_ref = 1;
          received_data_ref = '0;
          bit_cnt = 7;
          return reset_triggered();
      end

      SCL_O_ref = ~SCL_O_ref;
      
      if (SCL_O_ref == 1) begin
         // Sample data only when SCL is high
         received_data_ref[bit_cnt] = item.SDA_I;
      end

      if (bit_cnt == 0) begin
        bit_cnt = 7;
        return go_to_ack_send_state();
      end else begin
        bit_cnt--;
        return this;
      end
    endfunction
  endclass


  // ACK SEND STATE 
  class Ack_send_state extends State;
    virtual function string get_name(); return "Ack_send_state"; endfunction

    function State transition(Master_seq_item item);
      if (~rst_n) begin
          SCL_O_ref = 1;
          SDA_O_ref = 1;
          received_data_ref = '0;
          return reset_triggered();
      end

      SCL_O_ref = ~SCL_O_ref;

      // WRITE → master drives repeated start if commanded
      if (item.start && !item.data[0]) begin
        SDA_O_ref = 0;
        return go_to_start_state();
      end

      // READ → master decides ACK/NACK
      // Assuming 'last_byte' is a valid field in your Master_seq_item
      if (item.last_byte) begin
        SDA_O_ref = 1; // NACK
        return go_to_stop_state();
      end else begin
        SDA_O_ref = 0; // ACK
        return go_to_read_state();
      end
    endfunction
  endclass


  // ACK CHECK STATE
  class Ack_check_state extends State;
    virtual function string get_name(); return "Ack_check_state"; endfunction

    function State transition(Master_seq_item item);
      if (~rst_n) begin
          SCL_O_ref = 1;
          SDA_O_ref = 1;
          received_data_ref = '0;
          return reset_triggered();
      end

      SCL_O_ref = ~SCL_O_ref;

      if (item.SDA_I == 0) begin
          // ACK received successfully
          return go_to_write_state();
      end else begin
        // NACK received, abort transaction
        return go_to_stop_state();
      end
    endfunction
  endclass 


  // STOP STATE
  class stop_state extends State;
    virtual function string get_name(); return "stop_state"; endfunction

    function State transition(Master_seq_item item);
      if (~rst_n) begin
          SCL_O_ref = 1;
          SDA_O_ref = 1;
          received_data_ref = '0;
          return reset_triggered();
      end

      SCL_O_ref = 1;
      SDA_O_ref = 1; // STOP condition (SDA goes high while SCL is high)

      return go_to_idle_state();
    endfunction 
  endclass


  // SCOREBOARD COMPONENT
  class Master_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(Master_scoreboard)

    Idle_state starting_state;
    State current_state_obj;

    function new(string name = "Master_scoreboard", uvm_component parent);
      super.new(name, parent);
      starting_state = new();
      this.current_state_obj = starting_state;
    endfunction

    // This function should be called by your monitor via an analysis port write() method
    function void Master_check(Master_seq_item item);
      
      // Update state object based on transition logic
      current_state_obj = current_state_obj.transition(item);

      // Compare DUT physical outputs to our Reference model
      if (item.SCL_O !== SCL_O_ref || item.SDA_O !== SDA_O_ref) begin
        `uvm_error("SCOREBOARD", $sformatf("Mismatch at state %0s: Expected SCL=%b, SDA=%b; Got SCL=%b, SDA=%b",
          current_state_obj.get_name(), SCL_O_ref, SDA_O_ref, item.SCL_O, item.SDA_O))
        error_count++;
      end else begin
        correct_count++;
      end

      // Check for test completion 
      if (test_finished) begin
        `uvm_info("SCOREBOARD", $sformatf("Test finished. Correct: %0d, Errors: %0d", correct_count, error_count), UVM_LOW)
      end
    endfunction

  endclass // Added the missing endclass here!

endpackage