 library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

entity timer is
  generic (
    CLK_FREQ_HZ_G : natural; -- Clock frequency in Hz
    DELAY_G       : time
  );
  port (
    clk_i : in    std_ulogic;

    arst_i  : in    std_ulogic; -- Delay duration, e.g., 100 ms
    start_i : in    std_ulogic; -- No effect if not done_o

    done_o : out   std_ulogic -- ’1’ when not counting ("not busy")
  );
end entity timer;
