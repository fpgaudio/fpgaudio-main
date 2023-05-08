module mod_wm7731dac
  ( output var o_done
  , output var o_hw_aud_dacdat
  , input var i_clk
  , input var i_rst
  , input var i_hw_aud_bclk
  , input var i_hw_aud_daclrck
  , input var bit [31:0] i_data
  );

  parameter bit [3:0] START = 0;
  parameter bit [3:0] SLEEP = 1;
  parameter bit [3:0] TRANSFER = 2;
  parameter bit [3:0] DONE = 3;
  parameter bit [3:0] ERROR = 4;

  // Counter for the number of bits to transfer.
  var bit [4:0] bits_left = 31;

  // Internal data buffer.
  var bit [31:0] m_data;
  
  // State machine variables.
  var bit [3:0] state;
  var bit [3:0] state_next;

  always @(posedge i_hw_aud_bclk or negedge i_rst) begin
    if (!i_rst) begin
      state <= START;
      bits_left = 31;
    end else begin
      state <= state_next;
      case (state)
        SLEEP: begin
          if (i_hw_aud_daclrck) begin
            m_data <= i_data;
          end
        end
        TRANSFER: begin
          bits_left <= bits_left - 1;
        end
        DONE: begin
          bits_left <= 31;
        end
        default: begin
        end
      endcase
    end
  end

  // State transitions
  always @(*) begin
    o_done = 0;
    case (state)
      START: begin
        state_next = SLEEP;
      end
      SLEEP: begin
        state_next = i_hw_aud_daclrck ? TRANSFER : SLEEP;
      end
      TRANSFER: begin
        state_next = bits_left == 0 ? DONE : TRANSFER;
      end
      DONE: begin
        o_done = 1;
        state_next = SLEEP;
      end
      ERROR: begin
        state_next = ERROR;
      end
      default: begin
        state_next = ERROR;
      end
    endcase
  end

  always @(*) begin
    o_hw_aud_dacdat = m_data[bits_left];
  end
endmodule
