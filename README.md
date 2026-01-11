# 🕒 Parametric Timer

![VUnit CI](https://github.com/M-Deren/parametric_timer/actions/workflows/ci.yml/badge.svg)

A VHDL design for a configurable **parametric timer** module with generic clock frequency and delay duration.

---



## 📊 Overview

The timer generates a delay by counting clock cycles. The number of required cycles (threshold) is computed using the relationship:

```
Threshold = Delay / Clock_Period
```

To avoid numerical issues such as overflow or underflow (e.g., clamping to zero), the computation is split into two steps.

---

## ⏱️ Clock Period Calculation

The clock period is derived from the generic clock frequency:

```vhdl
CLK_PERIOD := 1.0 / real(CLK_FREQ_HZ_G);
```

The result is stored as a `real` value to preserve precision.  
Assuming a maximum clock frequency of **1 GHz**, the precision provided by the `real` type is more than sufficient to accurately represent the clock period.

---

## 🢶 Threshold Derivation

The delay generic (`DELAY_G`), provided as a VHDL `time` type, is first normalized:

```vhdl
DELAY_REAL_NS := real(DELAY_G / 1 ns) / 1_000_000_000.0;
```

This converts the delay into seconds, represented as a `real`.  
The required number of clock cycles is then computed as:

```vhdl
COUNT_THRESHOLD := natural(ceil(DELAY_REAL_NS / CLK_PERIOD));
```

Given the maximum guaranteed range of the VHDL `integer` type and a resolution of 1 ns, the maximum supported delay is approximately **2.147 seconds**, which is sufficient for most timing applications.

---

## 🔒 Safety Considerations

- If the computed threshold is less than one clock cycle, it is implicitly clamped to **1**, guaranteeing a minimum delay of one cycle.
- The `start_i` signal is assumed to be synchronous with the timer’s clock domain. Therefore, to avoid introducing unnecessary latency, no metastability mitigation or resynchronization logic is included for this signal.
- The timer output (`done_o`) is derived purely from the FSM state to ensure glitch-free behavior.

---

## 📝 Notes and Assumptions

- The timer delay is measured from the **falling edge of `done_o`** to its **rising edge**.  
  If your use case measures delay from the rising edge of `start_i`, you should account for an **extra clock cycle**.

- The module has been successfully synthesized using Vivado, confirming that all **real** and **time** based computations are resolved at elaboration.

- In simulation, the **clock signal is generated with femtosecond (fs) resolution**.  
  However, due to rounding during real-number computations (e.g., converting frequency to time), the actual simulated clock period may slightly differ from the ideal one.  
  This results in **small cumulative errors** over time.

- In some corner cases, this **accumulated timing error** may cause the measured delay to differ by more than one clock period, leading to test failures.

- To account for this, a **tolerance margin of 0.001% of the requested delay** is used when comparing expected vs. actual timing in simulation.  
  If the measured delay is within this range, the test is considered successful.

- Note: an alternative would be to check the **number of clock cycles** elapsed, which would eliminate timing error — but this would make the testbench logic **too similar** to the DUT, reducing the value of the test itself.

## 📝 Running VUnit Tests Locally

To run the VUnit tests locally, simply execute the `run_tests.bat` script located in the project root directory. This will launch all tests, including the default configuration and 100 randomized configurations to verify correct delay behavior.

For Linux users, you can copy the commands from the `.bat` file and run them manually in a terminal opened in the project directory, or create an equivalent shell script (e.g., `run_tests.sh`) for convenience.
