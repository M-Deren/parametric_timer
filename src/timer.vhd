 library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

entity timer is
  generic (
    CLK_FREQ_HZ_G : natural;          -- Clock frequency in Hz
    DELAY_G       : time              -- Delay duration, e.g., 100 ms
  );
  port (
    clk_i         : in    std_ulogic;

    arst_i        : in    std_ulogic;
    start_i       : in    std_ulogic; -- No effect if not done_o

    done_o        : out   std_ulogic  -- ’1’ when not counting ("not busy")
  );
end entity timer;

architecture rtl of timer is

  constant CLK_PERIOD        : real := (1.0 / real(CLK_FREQ_HZ_G));
  constant DELAY_REAL_NS     : real := real(DELAY_G / 1 ns) / 1_000_000_000.0; -- Delay in ns as a floating number
  constant COUNT_THRESHOLD   : natural := natural(ceil(DELAY_REAL_NS / CLK_PERIOD));

  type     state_type is (idle, counting);

  signal   state             : state_type := idle;
  signal   timer_cnt         : natural    := 0;
  signal   start_sample_vect : std_ulogic_vector(2 downto 0);                  -- Resampling of the start signal
  signal   start_re          : std_ulogic;

begin

  process (clk_i, arst_i) is
  begin

    if (arst_i = '1') then
      state             <= idle;
      start_sample_vect <= (others => '0');
      start_re          <= '0';
      timer_cnt         <= 0;
    elsif rising_edge(clk_i) then
      start_sample_vect <= start_sample_vect(start_sample_vect'high - 1 downto 0) & start_i; -- Resampling to avoid metastability issues in case start_i comes from a different domain
      start_re          <= start_sample_vect(1) and not start_sample_vect(2);

      case state is
        when idle =>
          timer_cnt     <= 0;
          if (start_re = '1') then
            state <= counting;
          end if;

        when counting =>
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

  end process;

  done_o <= '1' when state = idle else
            '0';

end architecture rtl;
