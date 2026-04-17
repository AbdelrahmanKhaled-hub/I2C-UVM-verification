package Master_shared_pkg;
  typedef enum {IDLE, START, ADDRESS, WRITE, READ,
                ACK_SEND, ACK_CHECK, STOP} state_t;

  int correct_count = 0;
  int error_count = 0;

  // Reference signals for the scoreboard
  logic SCL_O_ref = 1; 
  logic SDA_O_ref = 1;
  logic [7:0] received_data_ref = '0;       
  logic [7:0] data_old = '0;

  bit test_finished = 0;              
endpackage