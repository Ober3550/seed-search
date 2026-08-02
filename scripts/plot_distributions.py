#!/usr/bin/env python3
"""Render distribution histograms for the capture metrics + the union result.

Reads a METRICS_SCAN CSV (seedgen METRICS_SCAN=1) and score.config.json, then
writes one PNG per metric with its enabled tail thresholds (lo/hi) marked and the
captured tails shaded, plus a "tail-match count" PNG (how many metrics each seed
is extreme in). Capture = UNION of the per-metric tails; no composite score.

  .venv/bin/python scripts/plot_distributions.py [metrics.csv] [out_dir]
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

# METRICS_SCAN column indices; `moons` is derived (npm − npl).
COL = {"bodies": 1, "water_pct": 4, "hostility_pct": 5, "naquium_dv": 6,
       "field_dv": 7, "planets": 9}
SENTINEL = 10_000_000
d = np.loadtxt(CSV, delimiter=",")
N = len(d)

def metric(key):
    if key == "moons":
        return d[:, 1] - d[:, 9]
    return d[:, COL[key]]

BLUE, RED = "#3b7dd8", "#d84b3b"

def hist(ax, vals, bucket, title, lo=None, hi=None):
    vals = np.asarray(vals, float)
    vmin = np.floor(vals.min() / bucket) * bucket
    vmax = np.ceil(vals.max() / bucket) * bucket + bucket
    edges = np.arange(vmin, vmax + bucket, bucket)
    ax.hist(vals, bins=edges, color=BLUE, edgecolor="white", linewidth=0.3)
    ax.axvline(np.median(vals), color="black", lw=1.3, label=f"median {np.median(vals):.0f}")
    lo_c = hi_c = 0
    if lo is not None:
        ax.axvline(lo, color=RED, lw=1.5, ls="--")
        ax.axvspan(vmin, lo, color=RED, alpha=0.10); lo_c = int((vals <= lo).sum())
    if hi is not None:
        ax.axvline(hi, color=RED, lw=1.5, ls="--")
        ax.axvspan(hi, vmax, color=RED, alpha=0.10); hi_c = int((vals >= hi).sum())
    tag = "  ".join(x for x in [f"lo≤{lo:g}·{lo_c}" if lo is not None else "",
                                 f"hi≥{hi:g}·{hi_c}" if hi is not None else ""] if x)
    ax.set_title(f"{title}\n{tag}", fontsize=10, fontweight="bold")
    ax.legend(fontsize=8, framealpha=0.85); ax.grid(axis="y", alpha=0.25)

# ---- union capture + tail-match count ----
hits = np.zeros(N, int)
for f in CFG["filters"]:
    v = metric(f["key"])
    if f.get("lo") is not None: hits += (v <= f["lo"])
    if f.get("hi") is not None: hits += (v >= f["hi"])
kept = int((hits > 0).sum())

# ---- per-metric PNGs ----
for f in CFG["filters"]:
    v = metric(f["key"])
    vd = v[v < SENTINEL]  # drop Δv sentinel for the display range
    nsent = int((v >= SENTINEL).sum())
    title = f["label"] + (f"  [{nsent} none]" if nsent else "")
    fig, ax = plt.subplots(figsize=(7, 4))
    hist(ax, vd, f["bucket"], title, f.get("lo"), f.get("hi"))
    ax.set_xlabel(f["key"]); ax.set_ylabel("seeds")
    fig.tight_layout(); fig.savefig(os.path.join(OUT, f'metric_{f["key"]}.png'), dpi=110); plt.close(fig)

# ---- tail-match count PNG ----
fig, ax = plt.subplots(figsize=(7, 4.2))
mx = int(hits.max())
ax.hist(hits, bins=np.arange(-0.5, mx + 1.5), color=BLUE, edgecolor="white")
ax.set_title(f"Tail-match count  (union captured = {kept}/{N} = {kept/N*100:.3f}%)", fontsize=11, fontweight="bold")
ax.set_xlabel("# metrics the seed is extreme in (0 = discarded)"); ax.set_ylabel("seeds")
ax.set_xticks(range(mx + 1)); ax.grid(axis="y", alpha=0.25)
fig.tight_layout(); fig.savefig(os.path.join(OUT, "matches.png"), dpi=110); plt.close(fig)

# ---- combined overview grid ----
nf = len(CFG["filters"]); ncol = 3; nrow = math.ceil((nf + 1) / ncol)
fig, axes = plt.subplots(nrow, ncol, figsize=(6.5 * ncol, 4 * nrow)); axes = axes.flatten()
for i, f in enumerate(CFG["filters"]):
    v = metric(f["key"]); hist(axes[i], v[v < SENTINEL], f["bucket"], f["label"], f.get("lo"), f.get("hi"))
axes[nf].hist(hits, bins=np.arange(-0.5, mx + 1.5), color=BLUE, edgecolor="white")
axes[nf].set_title(f"MATCHES → {kept} kept", fontsize=10, fontweight="bold"); axes[nf].set_xticks(range(mx + 1))
for j in range(nf + 1, len(axes)): axes[j].axis("off")
fig.suptitle("Capture metrics — per-metric tails (shaded) + union", fontsize=15, fontweight="bold")
fig.tight_layout(); fig.savefig(os.path.join(OUT, "overview.png"), dpi=100); plt.close(fig)

per = {f["key"]: (int((metric(f["key"]) <= f["lo"]).sum()) if f.get("lo") is not None else 0,
                  int((metric(f["key"]) >= f["hi"]).sum()) if f.get("hi") is not None else 0)
       for f in CFG["filters"]}
print(f"N={N}  union captured={kept} ({kept/N*100:.3f}% → {int(kept/N*1e5)}/100k)")
print("per-tail (lo,hi):", per)
print(f"wrote {nf + 2} PNGs to {OUT}/")
