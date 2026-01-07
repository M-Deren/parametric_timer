# 🕒 Parametric Timer

A VHDL design for a simple **parametric timer** module with generic clock frequency and delay time.

---

## 📐 Overview

The timer's threshold counter is calculated using the formula:

```
Threshold = Delay / Clock_Period
```

To avoid overflow or underflow (e.g., clamping to 0), the calculation is broken into two parts:

1. **Clock Period Calculation**  
   The clock period is computed as:

   ```
   Period = 1 sec / CLK_FREQ_HZ_G
   ```

   This is an operation between a `time` and a `natural`, resulting in a `time` value.

   > ⚠️ Since the maximum representable `time` in VHDL is `9223372036854775807 fs`, clamping from this operation is extremely unlikely, even with very high clock frequencies.

2. **Threshold Derivation**  
   The required threshold is then determined by dividing the desired delay by the computed period:

   ```
   Threshold = Delay / Period
   ```

   This is a division between two `time` values and produces an `integer`.

---

## 🔒 Safety Check

If the computed threshold results in **0** (i.e., if the delay is smaller than the clock period), it is **clamped to 1**, ensuring that the timer always waits at least one clock cycle.

---
