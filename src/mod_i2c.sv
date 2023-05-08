module mod_i2c
  ( output var o_hw_sdclk
  , inout tri b_hw_sdat
  , output var o_done

  , input var i_rst
  , input var i_clk
  , input var bit [6:0] i_addr
  , input var bit [6:0] i_reg
  , input var bit [8:0] i_data
  , input var i_read
  );

  // Need to scale down the high-speed 50MHz clock down to i2c speeds.
  logic i2c_clk;
  logic [9:0] i2c_clk_counter = 1;

  // Firstly -- clock subsampling.
  always_comb @(posedge i_clk or negedge i_rst) begin
    if (!i_rst) begin
      i2c_clk <= 0;
      i2c_clk_counter <= 0;
    end else begin
      i2c_clk_counter <= (i2c_clk_counter + 1) % 200;
      i2c_clk <= i2c_clk_counter == 0 ? !i2c_clk : i2c_clk;
    end
  end

  logic [4:0] state = 0;
  logic [3:0] i2c_err = 0;
  logic sdclk;
  logic sdat;

  // Given subsampled clock.
  always_comb @(posedge i2c_clk or negedge i_rst) begin
    if (!i_rst) begin
      state <= 0;
      o_done <= 0;
    end else begin
      state <= state < 58 ? state + 1 : state;
      if (i2c_err == 0 || i2c_err == 'hf) begin
        case (state)
          0: begin
            i2c_err <= o_done ? 1 : i2c_err;

            sdclk <= 1;
            sdat <= 1;
          end
          // Start condition
          1: begin
            sdclk <= 1;
            sdat <= 0;
          end
          // Addressing
          2: begin
            sdclk <= 0;
            sdat <= i_addr[6];
          end
          3: begin
            sdclk <= 1;
          end
          4: begin
            sdclk <= 0;
            sdat <= i_addr[5];
          end
          5: begin
            sdclk <= 1;
          end
          6: begin
            sdclk <= 0;
            sdat <= i_addr[4];
          end
          7: begin
            sdclk <= 1;
          end
          8: begin
            sdclk <= 0;
            sdat <= i_addr[3];
          end
          9: begin
            sdclk <= 1;
          end
          10: begin
            sdclk <= 0;
            sdat <= i_addr[2];
          end
          11: begin
            sdclk <= 1;
          end
          12: begin
            sdclk <= 0;
            sdat <= i_addr[1];
          end
          13: begin
            sdclk <= 1;
          end
          14: begin
            sdclk <= 0;
            sdat <= i_addr[0];
          end
          15: begin
            sdclk <= 1;
          end
          // Read bit
          16: begin
            sdclk <= 0;
            sdat <= i_read;
          end
          17: begin
            sdclk <= 1;
          end
          18: begin
            sdclk <= 0;
            sdat <= 1;
          end
          19: begin
            sdclk <= 1;
            i2c_err <= b_hw_sdat ? 2 : i2c_err;
          end
          // Send actual I2C payload
          20: begin
            sdclk <= 0;
            sdat <= i_reg[6];
          end
          21: begin
            sdclk <= 1;
          end
          22: begin
            sdclk <= 0;
            sdat <= i_reg[5];
          end
          23: begin
            sdclk <= 1;
          end
          24: begin
            sdclk <= 0;
            sdat <= i_reg[4];
          end
          25: begin
            sdclk <= 1;
          end
          26: begin
            sdclk <= 0;
            sdat <= i_reg[3];
          end
          27: begin
            sdclk <= 1;
          end
          28: begin
            sdclk <= 0;
            sdat <= i_reg[2];
          end
          29: begin
            sdclk <= 1;
          end
          30: begin
            sdclk <= 0;
            sdat <= i_reg[1];
          end
          31: begin
            sdclk <= 1;
          end
          32: begin
            sdclk <= 0;
            sdat <= i_reg[0];
          end
          33: begin
            sdclk <= 1;
          end
          34: begin
            sdclk <= 0;
            sdat <= i_data[8];
          end
          35: begin
            sdclk <= 1;
          end
          // First byte must be acked.
          36: begin
            sdclk <= 0;
            sdat <= 1;
          end
          37: begin
            sdclk <= 1;
            i2c_err <= b_hw_sdat ? 3 : i2c_err;
          end
          38: begin
            sdclk <= 0;
            sdat <= i_data[7];
          end
          39: begin
            sdclk <= 1;
          end
          40: begin
            sdclk <= 0;
            sdat <= i_data[6];
          end
          41: begin
            sdclk <= 1;
          end
          42: begin
            sdclk <= 0;
            sdat <= i_data[5];
          end
          43: begin
            sdclk <= 1;
          end
          44: begin
            sdclk <= 0;
            sdat <= i_data[4];
          end
          45: begin
            sdclk <= 1;
          end
          46: begin
            sdclk <= 0;
            sdat <= i_data[3];
          end
          47: begin
            sdclk <= 1;
          end
          48: begin
            sdclk <= 0;
            sdat <= i_data[2];
          end
          49: begin
            sdclk <= 1;
          end
          50: begin
            sdclk <= 0;
            sdat <= i_data[1];
          end
          51: begin
            sdclk <= 1;
          end
          52: begin
            sdclk <= 0;
            sdat <= i_data[0];
          end
          53: begin
            sdclk <= 1;
          end
          // Byte must be acked.
          54: begin
            sdclk <= 0;
            sdat <= 1;
          end
          55: begin
            sdclk <= 1;
            i2c_err <= b_hw_sdat ? 4 : i2c_err;
          end
          // Stop cond + Release bus
          56: begin
            sdclk <= 0;
            sdat <= 0;
          end
          57: begin
            sdclk <= 1;
            sdat <= 0;
          end
          58: begin
            sdclk <= 1;
            sdat <= 1;
            o_done <= 1;
            i2c_err <= 'hf;
          end

          default: begin
            i2c_err <= 'hf - 1;
          end
        endcase
      end else begin
        // In the case of an error, there is nothing we can do.
      end
    end
  end

  assign o_hw_sdclk = sdclk;
  assign b_hw_sdat = (i_rst ? sdat : 0) == 1 ? 'bz : 0;
endmodule
