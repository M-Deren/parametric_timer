library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

library vunit_lib;
  context vunit_lib.vunit_context;

library rtl;

entity tb_timer is
  generic (
    RUNNER_CFG    : string;
    CLK_FREQ_HZ_G : natural := 1_000; -- Clock frequency in Hz
    DELAY_NS_G    : natural := 10_000_000
  );
end entity tb_timer;

architecture tb of tb_timer is

  constant CLK_PERIOD     : real := 1.0 / real(CLK_FREQ_HZ_G);
  constant CLK_PERIOD_FS  : time := round((CLK_PERIOD * 1_000_000_000_000_000.0)) * 1 fs;
  constant DELAY_G        : time := DELAY_NS_G * 1 ns;

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

  end procedure;

begin

  dut : entity rtl.timer
    generic map (
      CLK_FREQ_HZ_G => CLK_FREQ_HZ_G,
      DELAY_G       => DELAY_G
    )
    port map (
      clk_i         => clk,
      arst_i        => rst,
      start_i       => start,
      done_o        => done
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

    variable time_delay   : time  := 0 ns;
    variable start_time   : time := 0 ns;
    variable time_elapsed : time := 0 ns;

  begin

    test_runner_setup(runner, RUNNER_CFG);

    ----------------------------------------------------------------
    -- Test 1: reset clears counter
    ----------------------------------------------------------------
    if run("reset_sets_done") then
      apply_reset(rst, clk);
      check_equal(
            done,
            '1',
            "done should be high at reset"
            );
    end if;

    ----------------------------------------------------------------
    -- Test 2: counter increments when enabled
    ----------------------------------------------------------------
    if run("waits_the_correct_amount_of_time") then
      apply_reset(rst, clk);
      if (DELAY_G >= CLK_PERIOD_FS) then
        time_delay := DELAY_G;
      else
        time_delay := CLK_PERIOD_FS;
      end if;
      time_precision <= CLK_PERIOD_FS;
      start          <= '1';
      wait until done = '0';
      start_time     := now;
      start          <= '0';
      wait until done = '1';
      time_elapsed   := now - start_time;
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

  test_runner_watchdog(runner, (2*DELAY_G + 20*CLK_PERIOD_FS));

end architecture tb;

