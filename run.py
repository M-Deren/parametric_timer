import random

from pathlib import Path
from vunit import VUnit

# -----------------------------------------------------------------------------
# Create VUnit instance
# -----------------------------------------------------------------------------
vu = VUnit.from_argv()
vu.add_vhdl_builtins()
vu.add_osvvm()


# -----------------------------------------------------------------------------
# Project root
# -----------------------------------------------------------------------------
ROOT = Path(__file__).parent

# -----------------------------------------------------------------------------
# Libraries
# -----------------------------------------------------------------------------
lib_rtl      = vu.add_library("rtl")
lib_tb       = vu.add_library("tb")

# -----------------------------------------------------------------------------
# RTL sources
# -----------------------------------------------------------------------------
lib_rtl.add_source_files(ROOT / "src/*.vhd")

# -----------------------------------------------------------------------------
# Testbench sources
# -----------------------------------------------------------------------------
lib_tb.add_source_files(ROOT / "tb/*.vhd")


# -----------------------------------------------------------------------------
# Test configurations
# -----------------------------------------------------------------------------


tb_timer = lib_tb.entity("tb_timer")

random.seed(42)  # Reproducibility

for i in range(100):
    freq = random.randint(1, 100_000_000)
    delay = random.randint(0, 100_000_000)
    tb_timer.add_config(
        name=f"{freq}Hz__Delay_{delay}_ns",
        generics={
            "CLK_FREQ_HZ_G": freq,
            "DELAY_NS_G" : delay
        }
    )

# -----------------------------------------------------------------------------
# Default configuration (no generics overridden)
# -----------------------------------------------------------------------------
tb_timer.add_config(name="default")

# -----------------------------------------------------------------------------
# Corner cases
# -----------------------------------------------------------------------------

# tb_timer.add_config(
#         name=f"Max_freq_and_delay",
#         generics={
#             "CLK_FREQ_HZ_G": 1_000_000_000,   --Tested once succesfully, commented due to extremely long computation time
#             "DELAY_NS_G" : 2_000_000_000
#         }
# )       

tb_timer.add_config(
        name=f"0_Delay",
        generics={
            "CLK_FREQ_HZ_G": 100_000_000,
            "DELAY_NS_G" : 0
        }
)   

# -----------------------------------------------------------------------------
# Run VUnit
# -----------------------------------------------------------------------------
vu.set_sim_option("modelsim.vsim_flags", ["-t", "fs"])
vu.main()
