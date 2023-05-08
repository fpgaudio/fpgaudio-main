module mod_wm7831_config
  ( output var o_done
  , output var o_hw_sdclk
  , inout tri b_hw_sdat

  , input var i_rst
  , input var i_clk
  , input var i_trigger
  );

  parameter bit [6:0] CHIP_ADDR = 'b0011010;

  parameter bit [2:0] BEGIN = 0;
  parameter bit [2:0] I2C_WRITE = 1;
  parameter bit [2:0] I2C_WAIT_XACTION = 2;
  parameter bit [2:0] I2C_FINISHED_WRITING = 3;
  parameter bit [2:0] DONE_DIE = 4;
  logic [2:0] state;

  parameter bit [4:0] NUM_I2C_MESSAGES = 5;
  logic [4:0] current_i2c_message = 0;
  logic [6:0] register_addr[0:NUM_I2C_MESSAGES];
  logic [8:0] config_data[0:NUM_I2C_MESSAGES];

  logic [6:0] i2c_current_reg;
  logic [8:0] i2c_current_data;
  logic i2c_done;
  logic i2c_trigger = 0;
  mod_i2c u_i2c
    ( o_hw_sdclk
    , b_hw_sdat
    , i2c_done
    , i2c_trigger
    , i_clk
    , CHIP_ADDR
    , i2c_current_reg
    , i2c_current_data
    , 0
    );

  always @(posedge i_clk or negedge i_rst) begin
    if (i_rst == 0) begin
      state <= BEGIN;
    end else begin
      case (state)
        // Page 46 of the manual
        BEGIN: begin
          config_data[0] <= 9'b000000000; // Boot
          config_data[1] <= 9'b001010011; // 16bit output
          config_data[2] <= 9'b000011000; // bypass and dacsel
          
          config_data[3] <= 9'b000000000; // Don't mute
          config_data[4] <= 9'b000000001; // Activate
          config_data[5] <= 9'b000000000; // Reboot

          register_addr[0] <= 7'b0000110;
          register_addr[1] <= 7'b0000111;
          register_addr[2] <= 7'b0000100;
          
          register_addr[3] <= 7'b0000101;
          register_addr[4] <= 7'b0001001;
          register_addr[5] <= 7'b0000110;

          state <= i_trigger ? I2C_WRITE : BEGIN;
        end
        I2C_WRITE: begin
          i2c_trigger <= 1;
          i2c_current_reg <= register_addr[current_i2c_message];
          i2c_current_data <= config_data[current_i2c_message];

          state <= I2C_WAIT_XACTION;
        end
        I2C_WAIT_XACTION: begin
          state <= i2c_done ? I2C_FINISHED_WRITING : I2C_WAIT_XACTION;
        end
        I2C_FINISHED_WRITING: begin
          i2c_trigger <= 1;
          if (current_i2c_message < NUM_I2C_MESSAGES) begin
            // Write next message
            current_i2c_message <= current_i2c_message + 1;
            state <= I2C_WRITE;
          end else begin
            state <= DONE_DIE;
          end
        end
        DONE_DIE: begin
          o_done <= 1;
          i2c_trigger <= 0;
        end
        default: begin
        end
      endcase
    end
  end
endmodule
