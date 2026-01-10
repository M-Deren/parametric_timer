 library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

entity timer is
  generic (
    CLK_FREQ_HZ_G : natural := 1_000_000;          -- Clock frequency in Hz
    DELAY_G       : time := 100 ms              -- Delay duration, e.g., 100 ms
  );
  port (
    clk_i         : in    std_ulogic;

    arst_i        : in    std_ulogic;
    start_i       : in    std_ulogic; -- No effect if not done_o

    done_o        : out   std_ulogic  -- ’1’ when not counting ("not busy")
  );
end entity timer;

architecture rtl of timer is

  constant CLK_PERIOD      : real := (1.0 / real(CLK_FREQ_HZ_G));
  constant DELAY_REAL_NS   : real := real(DELAY_G / 1 ns) / 1_000_000_000.0; -- Delay in ns as a floating number
  constant COUNT_THRESHOLD : natural := natural(ceil(DELAY_REAL_NS / CLK_PERIOD));

  type     state_type is (idle, counting);

  signal   state           : state_type := idle;
  signal   timer_cnt       : natural    := 0;
  signal   start_d1        : std_ulogic;                                     -- Resampling of the start signal
  signal   start_re        : std_ulogic;                                     -- Rising edge of the start signal

begin

  timer_proc : process (clk_i, arst_i) is
  begin

    if (arst_i = '1') then
      state     <= idle;
      start_d1  <= '0';
      timer_cnt <= 0;
    elsif rising_edge(clk_i) then
      start_d1      <= start_i;

      case state is
        when idle =>     -- Waits for a start rising edge
          timer_cnt <= 0;
          if (start_re = '1') then
            state <= counting;
          end if;

        when counting => -- Counts until it reaches the threshold
          if (timer_cnt < COUNT_THRESHOLD - 1) then
            timer_cnt <= timer_cnt + 1;
          else
            timer_cnt <= 0;
            state     <= idle;
          end if;

        when others =>
          state <= idle;

      end case;

    end if;

  end process timer_proc;

  start_re <= start_i and not start_d1; -- Rising edge is combinatorial to minimize latency
  done_o   <= '1' when state = idle else
              '0';

    ------------------------------------------------------------------------------
  -- PSL
  ------------------------------------------------------------------------------

  -- psl default clock is rising_edge(clk_i);

  -- psl assume always (start_i = prev(start_i) or rising_edge(clk_i));

  -- psl assert always (COUNT_THRESHOLD > 0);

  -- psl assert always (
  --   (done_o = '1' and start_re = '1') |->
  --     (done_o = '0')[*COUNT_THRESHOLD] ##1 (done_o = '1')
  -- );

end architecture rtl;
