# 🕒 Parametric Timer

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
- The `start_i` input is resynchronized internally using a multi-stage shift register to mitigate metastability when crossing clock domains.
- The timer output (`done_o`) is derived purely from the FSM state to ensure glitch-free behavior.

---
