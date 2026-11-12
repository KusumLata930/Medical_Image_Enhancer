#!/usr/bin/env python3
"""
Create the noisy medical test image for the Verilog simulation.

  python generate_inputs.py                 -> 256x256 knee-MRI style image, 6% salt & pepper
  python generate_inputs.py --size 64       -> small/quick image (also set WIDTH/HEIGHT=64 in the testbenches)
  python generate_inputs.py --source my.png -> use your own grayscale/RGB medical image instead

Writes (into ../sim):
  input_image.txt   one 8-bit pixel per line, hex, row-major  (what the testbenches read)
  input_image.png   same image as a PNG so you can look at it
"""
import argparse, os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SIM = os.path.join(HERE, "..", "sim")


def write_hex(img, path):
    with open(path, "w") as f:
        for v in img.flatten():
            f.write("%02x\n" % int(v))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--size", type=int, default=256)
    ap.add_argument("--source", default=os.path.join(HERE, "source_mri.png"))
    ap.add_argument("--noise", type=float, default=0.06, help="fraction of pixels hit by salt/pepper")
    ap.add_argument("--peak", type=int, default=110, help="brightest tissue level (raw MRI is dark)")
    ap.add_argument("--seed", type=int, default=7)
    a = ap.parse_args()

    n = a.size
    src = Image.open(a.source).convert("L").resize((n, n), Image.BICUBIC)
    clean = np.asarray(src, dtype=np.float64)

    # Make it look like a raw (dim, low-contrast) scan: compress the range to 0..peak
    raw = np.round(clean / max(clean.max(), 1) * a.peak).astype(np.uint8)

    rng = np.random.default_rng(a.seed)
    noisy = raw.copy()
    r = rng.random(raw.shape)
    noisy[r < a.noise / 2] = 0          # pepper
    noisy[(r >= a.noise / 2) & (r < a.noise)] = 255   # salt

    os.makedirs(SIM, exist_ok=True)
    write_hex(noisy, os.path.join(SIM, "input_image.txt"))
    Image.fromarray(noisy).save(os.path.join(SIM, "input_image.png"))
    Image.fromarray(raw).save(os.path.join(SIM, "reference_clean_dim.png"))
    print("wrote %dx%d image: %d pixels, %.1f%% corrupted" %
          (n, n, n * n, 100.0 * np.mean(noisy != raw)))


if __name__ == "__main__":
    main()
