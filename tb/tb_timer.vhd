library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library vunit_lib;
  context vunit_lib.vunit_context;

library rtl;

entity tb_timer is
  generic (
    runner_cfg    : string;
    clk_freq_hz_g : natural := 1_000; -- Clock frequency in Hz
    delay_ns_g    : natural := 10_000_000
  );
end entity tb_timer;

architecture tb of tb_timer is

  constant CLK_PERIOD    : real := 1.0 / real(clk_freq_hz_g);
  constant CLK_PERIOD_FS : time := round((CLK_PERIOD * 1_000_000_000_000_000.0)) * 1 fs; -- The clock period is calculated in fs to minimize the approximation error
  constant DELAY_G       : time := delay_ns_g * 1 ns;

  signal   clk            : std_ulogic := '0';
  signal   rst            : std_ulogic := '0';
  signal   start          : std_ulogic := '0';
  signal   done           : std_ulogic;
  signal   time_precision : time := DELAY_G / 1000;

  procedure apply_reset (
    signal rst : out std_ulogic;
    signal clk : in  std_ulogic
  ) is
  begin

    rst <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    rst <= '0';
    wait until rising_edge(clk);

  end procedure apply_reset;

begin

  dut : entity rtl.timer
  generic map (
    clk_freq_hz_g => clk_freq_hz_g,
    delay_g       => DELAY_G
  )
  port map (
    clk_i   => clk,
    arst_i  => rst,
    start_i => start,
    done_o  => done
  );

  clk_gen : process is
  begin

    while true loop

      clk <= '0';
      wait for CLK_PERIOD_FS / 2;
      clk <= '1';
      wait for CLK_PERIOD_FS / 2;

    end loop;

  end process clk_gen;

  main : process is
    variable time_delay   : time  := 0 ns;        -- Requested delay
    variable start_time   : time := 0 ns;
    variable time_elapsed : time := 0 ns;
  begin

    test_runner_setup(runner, runner_cfg);

    if (DELAY_G >= CLK_PERIOD_FS) then              -- Selects the clock period as the delay if the requested one is too small
      time_delay := DELAY_G;
    else
      time_delay := CLK_PERIOD_FS;
    end if;

    if (CLK_PERIOD_FS > time_delay / 100000) then   -- Selects the correct precision for the test
      time_precision <= CLK_PERIOD_FS;
    else
      time_precision <= time_delay / 100000;
    end if;

    ----------------------------------------------------------------
    -- Test 0: reset is respected
    ----------------------------------------------------------------
    if run("reset_is_respected") then               -- Verifies that the module is reset correctly
      apply_reset(rst, clk);
      start <= '1';
      wait for time_delay/2;
      start <= '0';
      apply_reset(rst, clk);
      wait for time_delay/2;
      check_equal(
                  done,
                  '0',
                  "Done should be low at reset"
                );
    end if;

    ----------------------------------------------------------------
    -- Test 1: start is ignored while busy
    ----------------------------------------------------------------
    if run("start_is_ignored_while_busy") then      -- Toggles start after half the delay and verifies that the result isn't compromised
      apply_reset(rst, clk);
      start        <= '1';
      start_time   := now;
      wait until rising_edge(clk);
      start        <= '0';
      wait for time_delay / 2;
      start        <= '1';
      wait until done = '1';
      time_elapsed := now - start_time;
      if (time_elapsed > time_delay - time_precision and time_elapsed < time_delay + time_precision) then
        check_passed;
      else
        log("Time_elapsed = " & time'image(time_elapsed));
        log("Time_precision = " & time'image(time_precision));
        if (time_elapsed > time_delay) then
          log("Time_difference = " & time'image(time_elapsed - time_delay));
        else
          log("Time_difference = " & time'image(time_delay - time_elapsed));
        end if;
        log("Period = " & time'image(CLK_PERIOD_FS));
        check_failed("Elapsed time does not correspond to the delay");
      end if;
    end if;

    ----------------------------------------------------------------
    -- Test 2: timer waits the correct amount of time
    ----------------------------------------------------------------
    if run("waits_the_correct_amount_of_time") then -- Verifies that the elapsed time is within either +-1 clock period or +-0,001% of the requested delay
      apply_reset(rst, clk);
      start        <= '1';
      start_time   := now;
      wait until rising_edge(clk);
      start        <= '0';
      wait until done = '1';
      time_elapsed := now - start_time;
      if (time_elapsed > time_delay - time_precision and time_elapsed < time_delay + time_precision) then
        check_passed;
      else
        log("Time_elapsed = " & time'image(time_elapsed));
        log("Time_precision = " & time'image(time_precision));
        if (time_elapsed > time_delay) then
          log("Time_difference = " & time'image(time_elapsed - time_delay));
        else
          log("Time_difference = " & time'image(time_delay - time_elapsed));
        end if;
        log("Period = " & time'image(CLK_PERIOD_FS));
        check_failed("Elapsed time does not correspond to the delay");
      end if;
    end if;

    test_runner_cleanup(runner);
    wait;

  end process main;

  test_runner_watchdog(runner, (2*DELAY_G + 20*CLK_PERIOD_FS)); -- Watchdog to avoid endless looping

end architecture tb;

