library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library vunit_lib;
  context vunit_lib.vunit_context;

library rtl;

entity tb_timer is
  generic (
    RUNNER_CFG    : string;
    CLK_FREQ_HZ_G : natural := 1_000; -- Clock frequency in Hz
    DELAY_G       : time    := 10 ms
  );
end entity tb_timer;

architecture tb of tb_timer is

  constant CLK_PERIOD : time := (1 sec / CLK_FREQ_HZ_G);

  signal   clk        : std_ulogic := '0';
  signal   rst        : std_ulogic := '0';
  signal   start      : std_ulogic := '0';
  signal   done       : std_ulogic;
  signal   time_debug : time := 0 ms;

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
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;

    end loop;

  end process clk_gen;

  main : process is

    variable time_elapsed : time;

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
      time_elapsed := 0 ms;
      start        <= '1';
      wait until done = '0';

      wait until rising_edge(clk);

      while done = '0' loop

        time_elapsed := time_elapsed + CLK_PERIOD;
        time_debug   <= time_elapsed;
        wait until rising_edge(clk);

      end loop;

      if (DELAY_G - CLK_PERIOD < time_elapsed and time_elapsed < DELAY_G + CLK_PERIOD) then
        check_passed;
      else
        log("Time = " & time'image(time_elapsed));
        check_failed("The elapsed time should be within +- 1 clock period of the desired delay");
      end if;
    end if;

    test_runner_cleanup(runner);
    wait;

  end process main;

  test_runner_watchdog(runner, 2*DELAY_G);

end architecture tb;

