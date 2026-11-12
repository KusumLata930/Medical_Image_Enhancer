 <!-- HEAD
# Medical_Image_Enhancer

# Medical Image Enhancer - Verilog end-to-end simulation project

Pipeline (same as the workflow slide):

    input_image.txt (noisy MRI, 6 % salt & pepper)
        -> salt_pepper_removal  (3x3 median)      -> output_filtered.txt
              -> image_enhancer          (contrast stretching)  -> output_contrast.txt
              -> image_enhancer_advanced (histogram equalisation / threshold)
                                                    -> output_histeq.txt, output_threshold.txt, output_thr_histeq.txt

## Folder layout
| Folder / file | Purpose |
|---|---|
| `Source_Code/` | The 3 modules + 3 testbenches (your code, with bug fixes - see below) |
| `sim/` | Simulation working folder. `input_image.txt` (256x256 hex, one pixel per line) is already here; ISim writes the `output_*.txt` files here |
| `isim/` | `.prj` project files and `.tcl` waveform scripts for ISim |
| `python/` | `generate_inputs.py` (make a new noisy image), `golden_model.py` (software reference), `compare_and_view.py` (check results + make PNGs) |
| `expected/` | What the correct outputs look like (hex + PNG + `workflow_expected.png`) |
| `run_isim.bat` / `run_isim.sh` | One-command run (compile + simulate all 3 stages + compare) |
| `run_iverilog.sh` | Same flow with free Icarus Verilog, optional |

## Running in ISim (Xilinx ISE 14.x)

### Option A - one command
1. Start **ISE Design Suite Command Prompt** (Start menu -> Xilinx ISE Design Suite 14.x -> Accessories). This puts `fuse` on the PATH.
2. `cd` into this folder, then
   * `run_isim.bat`        -> opens the ISim waveform window for each of the 3 stages (like your ALU screenshot), one after the other; close a window to go to the next stage.
   * `run_isim.bat batch`  -> no GUI, fastest.
3. At the end `python python\compare_and_view.py` runs automatically (needs Python with numpy + pillow) and prints PASS/FAIL per file and writes `results\workflow.png`.

### Option B - manually (what the script does)
```
cd sim
fuse work.tb_salt_pepper_removal -prj ../isim/tb_salt_pepper_removal.prj -o tb_salt_pepper_removal.exe
tb_salt_pepper_removal.exe -gui -tclbatch ../isim/wave_salt_pepper.tcl

fuse work.tb_image_enhancer -prj ../isim/tb_image_enhancer.prj -o tb_image_enhancer.exe
tb_image_enhancer.exe -gui -tclbatch ../isim/wave_contrast.tcl

fuse work.tb_image_enhancer_advanced -prj ../isim/tb_image_enhancer_advanced.prj -o tb_image_enhancer_advanced.exe
tb_image_enhancer_advanced.exe -gui -tclbatch ../isim/wave_advanced.tcl
```
**Order matters**: stage 1 must run first, because stages 2 and 3 read `output_filtered.txt`.

### Option C - inside the ISE Project Navigator GUI
1. File -> New Project, add all 6 `.v` files from `Source_Code/`.
2. Copy `sim/input_image.txt` into the project's working folder (the folder containing the `.xise` file, or ISim's `isim` subfolder - wherever ISim runs). Simplest: set the project location to this `sim/` folder.
3. View -> Simulation, select one testbench (e.g. `tb_salt_pepper_removal`), then Process "Simulate Behavioral Model".
4. In the ISim window drag `clk, rst, start, done, filtered_valid, filtered_pixel, pixel_addr, dut_state, dut_counter` into the waveform, type `run all` in the console (or press Run All). Zoom with "Zoom to Full View".

### Getting a waveform that looks like your ALU figure
A 256x256 image takes about 1.3 ms of simulated time, so the full waveform is dense. For a readable screenshot either zoom into the first ~2 us after `start`, or make a small image:
```
python python/generate_inputs.py --size 32
```
and change `parameter WIDTH = 256; HEIGHT = 256;` to 32 in all three testbenches (only the testbenches need editing), then re-run `python python/golden_model.py`.

## What was changed in your code
* **salt_pepper_removal.v**: at row/column 0 the old `get_pixel(r-1, ...)` on a 17-bit unsigned value wrapped to 131071, which the `>= HEIGHT` test clamped to the *last* row, so the top/left border took its neighbours from the opposite edge of the image instead of replicating the edge. Now uses signed integers so the border is replicated correctly. `row`/`col` are plain integers driven only by blocking assignments, and the median is stored with `output_image[pixel_counter] <= median`.
* **image_enhancer.v**: arithmetic registers widened to 32 bits, and `current_pixel`/`denominator` are now only used as blocking temporaries; no behavioural change for normal images.
* **image_enhancer_advanced.v**: `cdf_min` was found with a non-blocking assignment inside a loop, so every non-zero CDF entry "won" in turn and the last one (the total pixel count) ended up as `cdf_min`, which breaks equalisation. It is now the first non-zero CDF entry, computed with blocking temporaries. Mode 01 / 10 input selection simplified (`use_temp`).
* **Testbenches**: the two enhancer testbenches now read `output_filtered.txt` (the cleaned image) so the pipeline matches your slide; the advanced testbench runs three modes; `$dumpvars` limited to top level; internal state/counter/min/max exposed as `dut_*` wires for the waveform window; `%0d` formats.
* `$fscanf` format changed from `"%h\n"` to `"%h"` (whitespace is skipped automatically).

## Notes
* Output pixel format everywhere: one 2-digit hex value per line, row-major, 256x256 = 65536 lines.
* Use your own image: `python python/generate_inputs.py --source my_scan.png --size 256`.
* The RTL is written in a behavioural/testbench style (file I/O, loops, tasks), so it is for simulation, not synthesis.
 554efbe (Initial commit: Medical Image Enhancer) -->
