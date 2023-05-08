module fpgaudio_main
  ( input var i_sw
  , input var i_clk
  , output var o_led1
  , output var o_led2
  );

  logic clk_48khz;
  logic clk_31khz;
  mod_clock u_clock(i_clk, clk_48khz, clk_31khz);

  assign o_led1 = clk_48khz;
  assign o_led2 = clk_31khz;
endmodule
