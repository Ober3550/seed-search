#!/usr/bin/env python3
"""Render distribution histograms for the seed-score metrics + the score itself.

Reads a METRICS_SCAN CSV (seedgen METRICS_SCAN=1) and score.config.json, then
writes one PNG per metric (with lo/hi calibration + median overlaid) and a score
PNG with the capture cutoffs. Bucketing: small-count scales use integer buckets,
10k–150k Δv scales use 5k buckets (per-component `bucket` in the config).

  .venv/bin/python scripts/plot_distributions.py [metrics.csv] [out_dir]

The score is recomputed here from the SAME config the generator/GUI use, so
editing weights/lo/hi in score.config.json and re-running reflects immediately.
"""
import sys, os, json, math
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "metrics.csv")
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, "plots")
CFG = json.load(open(os.path.join(ROOT, "score.config.json")))
os.makedirs(OUT, exist_ok=True)

# METRICS_SCAN columns -> index
COL = {"seed":0,"npm":1,"nw":2,"ne":3,"wp":4,"ef":5,"naqdv":6,"fdv":7,"ed":8,"npl":9}
SENTINEL = 10_000_000
d = np.loadtxt(CSV, delimiter=",")
N = len(d)

# ---- score (mirror of score.js / score.zig, driven by the config) ----
def odd_pow(v, p):
    x = v / 100.0
    return math.copysign(abs(x) ** p, x) * 100.0

def component(v, c, exp):
    lo, hi = c["lo"], c["hi"]
    t = max(0.0, min(1.0, (v - lo) / (hi - lo)))
    good = t if c["higher_better"] else 1.0 - t
    return odd_pow(good * 100.0, exp) if c["kind"] == "bonus" else odd_pow(good * 200.0 - 100.0, exp)

def score_row(row, exp):
    s = 0.0
    for c in CFG["components"]:
        v = row[COL[c["key"]]]
        if c["key"] in ("naqdv", "fdv") and v >= SENTINEL:
            v = c["hi"]  # "none" -> far end
        s += c["weight"] * component(v, c, exp)
    return round(s)

exp = CFG["exp"]
scores = np.array([score_row(r, exp) for r in d])

BLUE, RED, GREEN, ORANGE = "#3b7dd8", "#d84b3b", "#2fa84f", "#e08a00"

def hist(ax, vals, bucket, title, lo=None, hi=None, cuts=None):
    vals = np.asarray(vals, float)
    vmin, vmax = np.floor(vals.min()/bucket)*bucket, np.ceil(vals.max()/bucket)*bucket + bucket
    edges = np.arange(vmin, vmax + bucket, bucket)
    ax.hist(vals, bins=edges, color=BLUE, edgecolor="white", linewidth=0.3)
    med = np.median(vals)
    ax.axvline(med, color="black", lw=1.4, ls="-", label=f"median {med:.0f}")
    if lo is not None: ax.axvline(lo, color=GREEN, lw=1.2, ls="--", label=f"lo {lo:g}")
    if hi is not None: ax.axvline(hi, color=ORANGE, lw=1.2, ls="--", label=f"hi {hi:g}")
    for cv in (cuts or []): ax.axvline(cv, color=RED, lw=1.4, ls="-.")
    ax.set_title(title, fontsize=11, fontweight="bold")
    ax.legend(fontsize=8, framealpha=0.85)
    ax.grid(axis="y", alpha=0.25)

# ---- per-metric PNGs ----
panels = []
for c in CFG["components"]:
    v = d[:, COL[c["key"]]]
    n_sent = int((v >= SENTINEL).sum())
    v = v[v < SENTINEL]
    title = f'{c["label"]}  (w={c["weight"]}, {"↑" if c["higher_better"] else "↓"} better)'
    if n_sent: title += f"  [{n_sent} none]"
    fig, ax = plt.subplots(figsize=(7, 4))
    hist(ax, v, c["bucket"], title, c["lo"], c["hi"])
    ax.set_xlabel(c["key"]); ax.set_ylabel("seeds")
    fig.tight_layout(); path = os.path.join(OUT, f'metric_{c["key"]}.png')
    fig.savefig(path, dpi=110); plt.close(fig); panels.append((c, path))

# ---- score PNG ----
fig, ax = plt.subplots(figsize=(8, 4.2))
hist(ax, scores, 2, f"Seed score  (signed, N={N})", cuts=[CFG["pos_cut"], CFG["neg_cut"]])
kept = int(((scores >= CFG["pos_cut"]) | (scores <= CFG["neg_cut"]) |
            (d[:, COL["npl"]] >= CFG["many_planets"])).sum())
ax.set_xlabel("score  (red = capture cutoffs)"); ax.set_ylabel("seeds")
ax.text(0.02, 0.95, f"captured: {kept}/{N}  ({kept/N*100:.2f}%)\ncut ≥{CFG['pos_cut']} / ≤{CFG['neg_cut']}",
        transform=ax.transAxes, va="top", fontsize=9,
        bbox=dict(boxstyle="round", fc="white", ec="0.7"))
fig.tight_layout(); fig.savefig(os.path.join(OUT, "score.png"), dpi=110); plt.close(fig)

# ---- combined overview grid ----
ncol = 3; nrow = math.ceil((len(CFG["components"]) + 1) / ncol)
fig, axes = plt.subplots(nrow, ncol, figsize=(6.5*ncol, 4*nrow))
axes = axes.flatten()
for i, c in enumerate(CFG["components"]):
    v = d[:, COL[c["key"]]]; v = v[v < SENTINEL]
    hist(axes[i], v, c["bucket"], c["label"], c["lo"], c["hi"])
hist(axes[len(CFG["components"])], scores, 2, "SCORE", cuts=[CFG["pos_cut"], CFG["neg_cut"]])
for j in range(len(CFG["components"])+1, len(axes)): axes[j].axis("off")
fig.suptitle("Seed-score metric distributions", fontsize=15, fontweight="bold")
fig.tight_layout(); fig.savefig(os.path.join(OUT, "overview.png"), dpi=100); plt.close(fig)

print(f"N={N}  score min={scores.min()} p50={int(np.median(scores))} max={scores.max()}  captured={kept} ({kept/N*100:.2f}%)")
print(f"wrote {len(panels)+2} PNGs to {OUT}/")
