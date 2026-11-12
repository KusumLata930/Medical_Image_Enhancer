#!/bin/bash
# Optional: run the same flow with Icarus Verilog (free) for a quick check.
set -e
cd "$(dirname "$0")/sim"
iverilog -o t1 ../Source_Code/salt_pepper_removal.v ../Source_Code/tb_salt_pepper_removal.v && vvp t1
iverilog -o t2 ../Source_Code/image_enhancer.v ../Source_Code/tb_image_enhancer.v && vvp t2
iverilog -o t3 ../Source_Code/image_enhancer_advanced.v ../Source_Code/tb_image_enhancer_advanced.v && vvp t3
cd ..; python3 python/compare_and_view.py
