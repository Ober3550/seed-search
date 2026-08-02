# Storage column analysis — `seeds` + `zone`

Planning doc. Goal: shrink bytes/seed and give columns readable names. These two
tables are ~all the storage; `zone` is ~90% (≈17.7 rows/universe, one per Calidus
body). Measured on the live DB (9,103 K2 seeds, 161,202 zone rows); "Domain" is
the true value space (u32 seed space, code-defined enums), not just this sample.

On-disk today: **seeds** 840 kB heap + 1.54 MB idx · **zone** 17 MB heap + 10 MB idx
(indexes ~40% — narrowing key columns shrinks them too).

Decisions baked in below:
- **Keep `SMALLINT`** for small columns — no bit-packing, no `"char"`. Packing
  would break per-column sort/filter; not worth it.
- Type wins come only from **8→4** (`BIGINT`→`INT4`) and **4→2** (`INT`→`SMALLINT`).
- u32 columns fit `INT4` via a `− 2³¹` bit-reinterpret (mapped back on read).
- Name convention: **`_id`** = points at a dictionary table (`zone_name`,
  `resource`); **`_idx`** = an `enum_value` domain index (the tags). Rename is
  name-only — stored values and dictionaries are untouched.
- **One schema serves both bulk and full-universe storage.** Three otherwise-safe
  optimizations are BULK-ONLY and would break the future full-universe mode — so
  we DON'T apply them (see [Full-universe compatibility](#full-universe-compatibility)):
  `dv` stays INT4, `star_name_id` is kept, `stellar_x/y` stay on `zone`.

Each table below has one row per column: current name/type, its value domain, and
the proposed name/type (**DROP** / **move** where that's the call).

---

## `seeds` (one row per universe)

| Current      | Type now        | Domain                 | → Name          | → Type                | Note                                        |
| ------------ | --------------- | ---------------------- | --------------- | --------------------- | ------------------------------------------- |
| `seed`       | BIGINT (8)      | u32 `[0,2³²)`          | `seed`          | **INT4 (4)**          | u32 via −2³¹ reinterpret; also FK in `zone` |
| `k2`         | BOOL (1)        | {t,f}                  | `k2`            | BOOL (1)              | —                                           |
| `vault_loot` | TEXT            | 401 distinct, len 5–12 | `vault_loot`    | TEXT                  | optional: dict-encode → SMALLINT id         |
| `draws`      | INT (4)         | ~4–6k                  | —               | **DROP**              | unused: written + SELECTed, never surfaced  |
| `naqdv`      | INT (4)         | ≤~160k + 10M none      | `naquium_dv`    | INT4 (4)              | range forces 4B                             |
| `fdv`        | INT (4)         | ≤~60k + 10M none       | `field_dv`      | INT4 (4)              | nearest any field                           |
| `npl`        | SMALLINT (2)    | 6–14                   | `planets`       | SMALLINT (2)          | planets only                                |
| `npm`        | SMALLINT (2)    | 14–63                  | `bodies`        | SMALLINT (2)          | planets + moons                             |
| `nw`         | SMALLINT (2)    | 0–~63                  | `water_bodies`  | SMALLINT (2)          | count with water                            |
| `ne`         | SMALLINT (2)    | 0–~63                  | `enemy_bodies`  | SMALLINT (2)          | count with enemies                          |
| `wp`         | SMALLINT (2)    | 0–100                  | `water_pct`     | SMALLINT (2)          | —                                           |
| `ef`         | SMALLINT (2)    | 0–100                  | `hostility_pct` | SMALLINT (2)          | —                                           |
| `ed`         | SMALLINT (2)    | −100–20                | `enemy_danger`  | SMALLINT (2)          | signed                                      |
| `score`      | INT (4)         | −100–100               | `score`         | **SMALLINT (2)**      | was INT                                     |
| `created_at` | TIMESTAMPTZ (8) | —                      | —               | **DROP** / per-bucket | not needed per seed                         |

**seeds payload:** 59B → 41B (seed −4, score −2, draws −4, created_at −8).
Small table; the real win is `zone`. (`stellar_x/y` stay on `zone` — full-universe.)

---

## `zone` (≈17.7 rows/universe — the dominant table)

| Current          | Type now     | Domain                   | → Name            | → Type           | Note                                                |
| ---------------- | ------------ | ------------------------ | ----------------- | ---------------- | --------------------------------------------------- |
| `seed`           | BIGINT (8)   | u32                      | `seed`            | **INT4 (4)**     | ×17.7/seed → biggest single win                     |
| `zone_seed`      | BIGINT (8)   | u32                      | `zone_seed`       | **INT4 (4)**     | or DROP: recomputable from `seed`                   |
| `dv`             | INT (4)      | ≤12.6k bulk / ~150k full | `delta_v`         | INT4 (4)         | KEEP 4B: field Δv overflows SMALLINT                |
| `radius`         | REAL (4)     | 350–10,000               | `radius`          | REAL (4)         | keep                                                |
| `stellar_x`      | DOUBLE (8)   | ±64                      | `stellar_x`       | **REAL (4)**     | KEEP on zone: per star + per field in full universe |
| `stellar_y`      | DOUBLE (8)   | ±64                      | `stellar_y`       | **REAL (4)**     | " (Δv stored separately → REAL precision fine)      |
| `kind`           | SMALLINT (2) | 0–4 (5 kinds)            | `kind`            | SMALLINT (2)     | —                                                   |
| `star_name_id`   | INT (4)      | 0 bulk / many full       | `star_name_id`    | **SMALLINT (2)** | KEEP: identifies the system in full universes       |
| `parent_name_id` | INT (4)      | 0–757 (nullable)         | `parent_name_id`  | **SMALLINT (2)** | dict ref                                            |
| `zone_name_id`   | INT (4)      | 0–757 (758 names)        | `zone_name_id`    | **SMALLINT (2)** | dict ref, ≤1023                                     |
| `primary_id`     | SMALLINT (2) | 0–17 (18 resources)      | `primary_id`      | SMALLINT (2)     | resource dict ref                                   |
| `temperature`    | SMALLINT (2) | 0–13                     | `temperature_idx` | SMALLINT (2)     | enum idx                                            |
| `water`          | SMALLINT (2) | 0–4                      | `water_idx`       | SMALLINT (2)     | enum idx                                            |
| `moisture`       | SMALLINT (2) | 0–4                      | `moisture_idx`    | SMALLINT (2)     | enum idx                                            |
| `trees`          | SMALLINT (2) | 0–4                      | `trees_idx`       | SMALLINT (2)     | enum idx                                            |
| `aux`            | SMALLINT (2) | 0–4                      | `aux_idx`         | SMALLINT (2)     | enum idx                                            |
| `cliff`          | SMALLINT (2) | 0–4                      | `cliff_idx`       | SMALLINT (2)     | enum idx                                            |
| `enemy`          | SMALLINT (2) | 0–6                      | `enemy_idx`       | SMALLINT (2)     | enum idx                                            |
| `present_mask`   | BIGINT (8)   | ≤18 bits                 | `resource_mask`   | **INT4 (4)**     | 18 resources → 18 bits                              |

**zone payload:** 78B → 52B (seed −4, zone_name −2, star_name −2, parent −2,
zone_seed −4, present_mask −4, stellar DOUBLE→REAL −8; `dv` kept 4B). ~26 B/row ×
17.7 ≈ **~0.46 KB/seed** off `zone` — full-universe-safe. (A bulk-only variant
dropping `star_name_id`/`stellar` and narrowing `dv` would save ~8 B/row more.)

---

## Bottom line

|                                          | Now          | Narrowed (full-universe-safe) |
| ---------------------------------------- | ------------ | ----------------------------- |
| zone payload (×17.7)                     | ~1.45 KB     | ~0.99 KB                      |
| **on-disk /seed (incl. overhead + idx)** | **~3.37 KB** | **~2.2–2.5 KB**               |

≈ **1.4×** smaller from type-narrowing alone → full search space ~31 GB → **~22 GB**.
(Slightly less than a bulk-only schema because `dv`/`star_name_id`/`stellar` are
kept for full-universe support. Bit-packing / `"char"` would push further but cost
sortability — not doing it.)

### Structural options (bigger, separate decision)
1. **Fewer rows.** ~24 B PG row-header × 17.7 rows ≈ 425 B/seed of pure overhead.
   One row/universe (arrays / JSONB / blob) erases most of it; costs ad-hoc SQL on bodies.
2. **Recompute vs store.** `zone_seed` (and much static body layout) is
   deterministic from `seed` — droppable if recomputed on read.
3. **Columnar archive.** Parquet has zero row-overhead and compresses these
   low-cardinality enum columns hard (<0.5 KB/seed cold). PG stays the query index.
4. **Trim indexes.** `zone` has 3 (10 MB); `idx_zone_seed` is the hot path,
   `idx_zone_name` / `idx_zone_primary` are corpus-stat conveniences — drop if unused.

---

## Full-universe compatibility

Bulk storage keeps only the **Calidus home system** (~17.7 zones/seed). A future
**full-universe** mode (`ALL_ZONES=1`) stores the whole universe — a constant
**651 zones/seed** (measured over 10 seeds): 129 planets, 428 moons, 45
asteroid-fields, 48 belts, 1 anomaly (+ stars/orbits). The names are **static
across seeds** — every universe reuses the same 651 — only properties/positions
vary. The write path already writes stars/planets/moons/**fields** under
`ALL_ZONES` (the `inCalidus` filter is bypassed; all four names are dictionary-
covered). So the schema must stay full-universe-capable — hence three columns are
**not** bulk-optimized away:

| Column         | Bulk               | Full universe                               | Keep because                                      |
| -------------- | ------------------ | ------------------------------------------- | ------------------------------------------------- |
| `dv`           | bodies ≤12,606     | **fields reach ~150k Δv**                   | overflows SMALLINT → stay `INT4`                  |
| `star_name_id` | always Calidus (0) | **one of many systems**                     | needed to place a body's system → keep (SMALLINT) |
| `stellar_x/y`  | 1 star             | **many stars + 45 fields, each positioned** | needed for geometry/map → keep on `zone` (REAL)   |

### Names: belts + anomaly stay out of the dictionary
The 48 belt names (`<Star> Asteroid Belt N`) and the anomaly (`Foenestra`) are
procedural / trivially regenerable, so they are **excluded from the `zone_name`
dictionary** — generate them later from parent star + index if ever needed. Today
the write-path `switch` **skips belts / orbits / anomalies** (`else => continue`)
*before* interning, so their absence from the dictionary never errors. If a full
build later wants belt/anomaly rows, store them with a **NULL `zone_name_id`**
(don't add procedural names to the dictionary).

