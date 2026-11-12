#!/bin/bash
# End-to-end ISim run on Linux.  ./run_isim.sh  (GUI)   |  ./run_isim.sh batch
set -e
cd "$(dirname "$0")/sim"
MODE=$1
for T in tb_salt_pepper_removal tb_image_enhancer tb_image_enhancer_advanced; do
  echo "===== Compiling $T ====="
  fuse work.$T -prj ../isim/$T.prj -o $T.exe
done
if [ "$MODE" = "batch" ]; then
  ./tb_salt_pepper_removal.exe        -tclbatch ../isim/batch.tcl
  ./tb_image_enhancer.exe             -tclbatch ../isim/batch.tcl
  ./tb_image_enhancer_advanced.exe    -tclbatch ../isim/batch.tcl
else
  ./tb_salt_pepper_removal.exe        -gui -tclbatch ../isim/wave_salt_pepper.tcl
  ./tb_image_enhancer.exe             -gui -tclbatch ../isim/wave_contrast.tcl
  ./tb_image_enhancer_advanced.exe    -gui -tclbatch ../isim/wave_advanced.tcl
fi
cd ..
python3 python/compare_and_view.py
