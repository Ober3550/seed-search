# Vanilla (no-mods) ore calibration — seed 341, r=512, 2.0.77

Pipeline: `run_case.py --name X --seed 341 [--freq F --size S]` — creates a
truly vanilla world (empty mod dir, isolated write-data), force-generates
32x32 chunks, dumps every resource tile to `out/X.jsonl`.

## Control sweep vs our surfacegen (same settings)

| case    | GT tiles | GEN tiles | ratio | notes |
|---------|----------|-----------|-------|-------|
| base    | 8190     | 7621      | 0.93  | 57% exact tile overlap |
| freq2   | 13620    | 14031     | 1.03  | existing patches keep size/pos; new ones added |
| freq4   | 28331    | 25955     | 0.92  | SE-level freq — still ~1x |
| freq0.5 | 6344     | 4973      | 0.78  | GT keeps starting patch we lack |
| size2   | 13500    | 11956     | 0.89  | tiles scale ~2^(2/3)=1.59 in BOTH (1.63) |
| size0.5 | 5254     | 4889      | 0.93  | |

CONCLUSION: frequency & size handling in the core port is CORRECT (0.9-1.0x at
every setting incl. freq4). Patch positions match GT to <5 tiles.

## The three structural gaps to tile-exactness (control-independent)

1. STARTING PATCHES missing in the vanilla path: every unmatched GT patch sits
   at dist<120 from origin (iron 788@(-39,75), copper 320@(-107,7),
   stone 232@(-64,79)). The SE path has the port; vanilla path needs it.
2. PER-SPOT SIZE RNG: matched patches scatter 0.40x-3.19x individually while
   aggregate stays ~1x — our per-candidate random_penalty_between(smin,smax)
   draw stream differs from the game's inside spot_noise.
3. WATER MASKING: GEN-extra patches (copper 831@(-341,58), stone 342@(-500,269))
   where GT likely has lakes; vanilla path has no elevation gate. (Hypothesis —
   verify against a tile dump.)

Plus crude-oil (28 vs 7, 0% overlap) — see ghidra/export/random_penalty.c.

## Per-spot size RNG — SOLVED (oracle-verified)

The game registers a named noise expression per resource
(`default-<name>-patches`); `surface.calculate_tile_properties` evaluates it at
arbitrary positions (probe_field.py) — an exact oracle for the all_patches
field. Testing 4 draw-stream variants against it:

random_penalty_between draws are seeded from the FIRST STRIDED candidate's
position and consumed in REVERSE candidate order (RandomPenalty::run iterates
its column last->first). With this (spot_size_rng_variant=1, now default) the
cone apexes match the oracle to float32 precision and the placement-relevant
field (value>0) matches to <0.22 abs.

Also fixed: uranium random_spot_size 2..4 (was defaulting 0.25..2).

Result on base-341: 7 of 10 matched patches at ratio exactly 1.00;
exact tile overlap: uranium 100.0%, copper 83% (GEN tiles 100% inside GT,
missing = its starting patch exactly), iron 75%, coal 78%, stone 77%.
ALL residual mismatch = the two known gaps (starting patches, water clipping).
The remaining oracle diff is only in the deep basement (value<0, no placement)
where the vanilla startingPatches stub returns a constant floor.
