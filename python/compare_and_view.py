#!/usr/bin/env python3
"""
After the Verilog simulation has run, this script
  1. reads the hex text files the testbenches wrote (sim/output_*.txt),
  2. checks them pixel-by-pixel against the golden model (expected/),
  3. converts them to PNG and builds results/workflow.png
     (Initial -> Salt&Pepper reduction -> Contrast stretching / Histogram equalisation),
     the same picture as the workflow slide.
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
SIM = os.path.join(HERE, "..", "sim")
EXP = os.path.join(HERE, "..", "expected")
RES = os.path.join(HERE, "..", "results")
os.makedirs(RES, exist_ok=True)


def read_hex(path):
    with open(path) as f:
        v = [int(x, 16) for x in f.read().split()]
    n = int(round(len(v) ** 0.5))
    return np.array(v, dtype=np.uint8)[: n * n].reshape(n, n)


files = ["output_filtered", "output_contrast", "output_histeq",
         "output_threshold", "output_thr_histeq"]
ok = True
imgs = {}
print("%-22s %-10s %s" % ("file", "result", "details"))
for name in files:
    sp = os.path.join(SIM, name + ".txt")
    ep = os.path.join(EXP, name + ".txt")
    if not os.path.exists(sp):
        print("%-22s %-10s %s" % (name, "MISSING", "not produced by simulation"))
        ok = False
        continue
    s, e = read_hex(sp), read_hex(ep)
    bad = int(np.count_nonzero(s != e)) if s.shape == e.shape else -1
    status = "PASS" if bad == 0 else "FAIL"
    ok &= bad == 0
    print("%-22s %-10s %d mismatching pixels" % (name, status, bad))
    imgs[name] = s
    Image.fromarray(s).save(os.path.join(RES, name + ".png"))

noisy = read_hex(os.path.join(SIM, "input_image.txt"))
Image.fromarray(noisy).save(os.path.join(RES, "input_image.png"))

if all(k in imgs for k in ("output_filtered", "output_contrast", "output_histeq")):
    n = noisy.shape[0]
    pad, lab = 20, 28
    W, H = 3 * n + 4 * pad, 2 * n + 3 * pad + 2 * lab
    canvas = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(canvas)
    pos = [(pad, pad + (n + lab) // 2, "1. Initial (noisy)", noisy),
           (2 * pad + n, pad + (n + lab) // 2, "2. Salt & pepper reduced", imgs["output_filtered"]),
           (3 * pad + 2 * n, pad, "3. Contrast stretching", imgs["output_contrast"]),
           (3 * pad + 2 * n, 2 * pad + n + lab, "4. Histogram equalisation", imgs["output_histeq"])]
    for x, y, t, im in pos:
        canvas.paste(Image.fromarray(im).convert("RGB"), (x, y))
        d.text((x, y + n + 6), t, fill="black")
    canvas.save(os.path.join(RES, "workflow.png"))
    print("\nwrote results/workflow.png and individual PNGs in results/")

print("\nOVERALL:", "ALL OUTPUTS MATCH GOLDEN MODEL" if ok else "CHECK FAILURES ABOVE")
sys.exit(0 if ok else 1)
