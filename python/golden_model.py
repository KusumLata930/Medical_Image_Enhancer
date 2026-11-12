#!/usr/bin/env python3
"""
Bit-accurate software model of the three Verilog modules.
It mimics the exact integer arithmetic of the RTL (3x3 median with edge
replication, (p-min)*255/(max-min) with integer division, CDF-based histogram
equalisation, binary threshold) and writes the EXPECTED output files into
../expected/ so the simulator results can be compared against them.

  python golden_model.py [--threshold 48]
"""
import argparse, os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SIM = os.path.join(HERE, "..", "sim")
EXP = os.path.join(HERE, "..", "expected")


def read_hex(path):
    with open(path) as f:
        v = [int(x, 16) for x in f.read().split()]
    n = int(round(len(v) ** 0.5))
    assert n * n == len(v), "image is not square"
    return np.array(v, dtype=np.int64).reshape(n, n)


def write_hex(img, path):
    with open(path, "w") as f:
        for v in img.flatten():
            f.write("%02x\n" % int(v))


def median3x3(img):
    p = np.pad(img, 1, mode="edge")          # border replication, same as get_pixel()
    h, w = img.shape
    stack = np.stack([p[r:r + h, c:c + w] for r in range(3) for c in range(3)])
    return np.sort(stack, axis=0)[4]


def contrast(img):
    mn, mx = img.min(), img.max()
    if mx == mn:
        return img.copy()
    return (((img - mn) * 255) // (mx - mn)) & 0xFF


def histeq(img):
    total = img.size
    hist = np.bincount(img.flatten(), minlength=256)
    cdf = np.cumsum(hist)
    cdf_min = cdf[cdf > 0][0]
    if cdf_min == 0 or cdf_min >= total:
        return img.copy()
    return (((cdf[img] - cdf_min) * 255) // (total - cdf_min)) & 0xFF


def threshold(img, t):
    return np.where(img >= t, 255, 0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--threshold", type=int, default=0x30)
    a = ap.parse_args()

    os.makedirs(EXP, exist_ok=True)
    noisy = read_hex(os.path.join(SIM, "input_image.txt"))

    filt = median3x3(noisy)
    out = {
        "output_filtered.txt": filt,
        "output_contrast.txt": contrast(filt),
        "output_histeq.txt": histeq(filt),
        "output_threshold.txt": threshold(filt, a.threshold),
        "output_thr_histeq.txt": histeq(threshold(filt, a.threshold)),
    }
    for name, img in out.items():
        write_hex(img, os.path.join(EXP, name))
        Image.fromarray(img.astype(np.uint8)).save(os.path.join(EXP, name.replace(".txt", ".png")))
        print("%-24s min=%3d max=%3d mean=%6.1f" % (name, img.min(), img.max(), img.mean()))


if __name__ == "__main__":
    main()
