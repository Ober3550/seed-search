# Storage consolidation & DB normalization — design & decisions

Status: **DRAFT / deciding.** Goal: make a single **queryable, indexed** store the
only place data lives, and **delete the `output/` file tree entirely** — possibly
a **hosted Google Cloud DB** (credentials pending). This supersedes the
on-disk-layout parts of [binary-format.md](binary-format.md) (rows 2–3 there).
Nothing implemented yet.

## Why

The GUI's job is to **query, filter, sort, and drill into** generated worlds.
Keeping results as a tree of loose files on disk doesn't serve that — it's a
second, unindexed copy of data the DB already needs, plus large binary renders.
We want one store you can index and query, and no `output/` directory.

## The reframe that makes this easy: generation is deterministic

The only irreducible input is **`(seed, mod_set, generator version)`**. From that,
the universe tree, each surface's ore, the biome, and every rendered image are
**deterministic functions** (the whole project is a bit-for-bit port). So:

- **System of record** = the seed list (+ mod_set + generator version). Tiny.
- **Everything else is derived** — persist it only to *query it fast* or to
  *cache expensive renders*, never as the source of truth.

That means the store is fundamentally an **index + cache**, and the on-disk tree
is neither: it's an unindexed cache we can regenerate. Deleting it loses nothing
we can't recompute.

## What's on disk today

Producer/consumer traced from `job-manager.js` / `server.js`:

| path                                           | producer         | consumer (GUI)                    | role    | notes                                                                |
| ---------------------------------------------- | ---------------- | --------------------------------- | ------- | -------------------------------------------------------------------- |
| `output/<bucket>/seeds.jsonl`                  | seedgen (bulk)   | imported → `seeds`/`zones` tables | derived | already re-materialised in the DB; the file is redundant post-import |
| `output/<bucket>/<name>.jsonl`                 | GUI filter save  | re-download of a filtered set     | derived | = a saved query; already have a `filters` table                      |
| `output/<bucket>/seed_<n>/zones.jsonl`         | seedgen (expand) | surface gen input; DB `line`      | derived | one world; regenerable from seed                                     |
| `output/<bucket>/seed_<n>/<Zone>/ore.jsonl`    | segen (surface)  | per-cell ore lookups              | derived | regenerable from (seed, zone)                                        |
| `output/<bucket>/seed_<n>/<Zone>/summary.json` | segen            | `zoneSurfaceSummary()` at render  | derived | resource totals; read on demand                                      |
| `output/<bucket>/seed_<n>/<Zone>/*.png`        | segen / gpu      | `<img>` in the surface view       | derived | **the large binary component**: terrain/oremap/surface + cell tiles  |

DB today: 12 GB `data.sqlite` (+273 MB WAL). Tables: `seeds` (with a raw
`line TEXT` per world + `criteria TEXT`), `zones` (TEXT-heavy: name, zone_type,
primary_resource, 7 tag columns, `resource_scores`/`resource_yields` JSON),
`universe_jobs` (`output_file` path), `surface_jobs` (`png_file` path),
`filters`/`filtered`. **Surface ore/summary/images are NOT in the DB — they live
on disk and are read on demand.**

---

## Problem A — Normalize the DB (shrink + index)

**"Change the column data types" is a no-op in SQLite.** Declared types are only
*affinity*; integers are stored as minimal varints regardless, so `SMALLINT` vs
`INTEGER` changes nothing on disk. The real lever is the same one the binary
format uses: **replace repeated TEXT with integer codes** (normalization).

- **Lookup tables** for `zone_name`, `zone_type`, `resource`, and the seven tag
  enums — **the same code space as the binary format's Dictionary** (one shared
  set of codes across generator, DB, and any export).
- **`zones` table:** swap the TEXT columns (`name`, `zone_type`,
  `primary_resource`, `temperature`…`enemy`) for `INTEGER` FKs into those lookups.
- **Drop `resource_scores`/`resource_yields`** — already dead (estimates removed;
  see [resource-estimation-direction] work). Ore comes from surface gen now.
- **The elephant: `seeds.line TEXT`** (a full raw JSONL world per row, at tens of
  millions of rows) almost certainly dominates the 12 GB. Options: (a) **drop it**
  and regenerate the world on expand (deterministic), or (b) keep a **compact
  protobuf blob** if a stored snapshot is still wanted (binary-format row 3).
  Leaning (a) — it's regenerable.
- **Indexes** follow the query patterns already in `getSeeds` (score, npl, naqdv,
  fdv, …); add indexes on the normalized zone columns if zone-level filtering is
  wanted.

## Problem B — Absorb / eliminate the on-disk artifacts

1. **Universe seeds/zones** — stop writing `seeds.jsonl` and
   `seed_<n>/zones.jsonl`; stream the generator **straight into the DB import**
   (the binary pipe from binary-format.md). The DB is the only landing spot.
2. **Filtered sets (`<name>.jsonl`)** — already expressible as a saved query
   (`filters` table + `criteria`); drop the files, "download" re-runs the query.
3. **Surface ore + summary** — derived. Either **regenerate on demand**, or store
   a **normalized summary row** (resource → tiles/amount) in the DB as a cache.
   The per-cell `ore.jsonl` is only needed for the pixel-hover feature — regenerate
   on demand rather than persist.
4. **Images (the crux, and the biggest bytes).** Three options:

| option                   | disk removed?                    | DB size                         | view latency              | notes                                                                                    |
| ------------------------ | -------------------------------- | ------------------------------- | ------------------------- | ---------------------------------------------------------------------------------------- |
| **Regenerate on demand** | ✅ fully                          | unaffected                      | render cost per cold view | segen is deterministic; render to memory, stream to browser, keep a small in-process LRU |
| **Store as BLOB in DB**  | ✅ (single store)                 | **huge** — images dwarf metrics | instant                   | bloats backups/VACUUM; SQLite blob limits/pain at this scale                             |
| **Evictable cache dir**  | ⚠️ partial (a cache, not a tree) | unaffected                      | instant when warm         | pragmatic middle ground, but it *is* files on disk again                                 |

Recommended lean: **regenerate on demand + in-process LRU** — it's the only option
that genuinely removes disk, and it fits the deterministic-derivation model. If
render latency hurts, add a bounded evictable cache (explicitly a cache, capped,
not a system of record).

## Schema — flat leaves + zone-resource facts

Three tables, joined only by simple equality keys. **No intermediate branch
tables and no recursion** — the shallow, fixed-shape tree is captured by
*denormalised ancestry columns* on flat leaf rows, which is safe here because the
data is **regenerated wholesale, never mutated** (so the usual denormalisation
downside — update anomalies — can't occur).

```sql
-- TRUNK: one row per universe (the system of record is really just `seed`)
seeds(seed PK, k2, npl, npm, naqdv, fdv, ed, wp, ef, score, …);

-- FLAT LEAVES: every node (star/planet/moon/belt/field) is one row
zone(
  seed           REFERENCES seeds,   -- FK straight to the trunk
  zone_name_id,                       -- SHARED code (dictionary); same across seeds
  kind,                               -- star | planet | moon | belt | field
  star_name_id,                       -- denormalised system (self for a star)
  parent_name_id,                     -- planet for a moon; star for planet/belt; null for star/field
  zone_seed, radius, primary_id, dv,
  temperature_id … enemy_id,          -- tag codes
  stellar_x, stellar_y,               -- set for kind=star / field
  present_mask,                       -- bitset of resources present (co-occurrence fast path)
  PRIMARY KEY (seed, zone_name_id)
);

-- FACTS: resources on a leaf, hung off the same simple key
zone_resource(
  seed, zone_name_id, resource_id,    -- resource_id = code (mod-extensible)
  present,
  frequency, size, richness,          -- universe-gen CONTROLS: the queryable driver + estimator input
  tiles, amount,                      -- derived quantity …
  source,                             -- … 'estimate' | 'measured'
  source_version,                     -- estimator vN / GPU-kernel vN
  PRIMARY KEY (seed, zone_name_id, resource_id)
);

-- DICTIONARY / lookups (shared code space with the binary format)
name_dict(id PK, text);   resource_dict(id PK, text);   -- + tag/kind dicts
```

Key properties:

- **Names are a shared dimension; instances are `(seed, name)`.** A zone *name*
  ("Grishord") is one of ~757 static roster entries → the *same* `zone_name_id`
  in every seed. But a name is drawn without replacement per universe
  (`pickShuffledName`/`used_names`), so it is **unique within a seed**, and
  `(seed, zone_name_id)` uniquely identifies an instance. Index the fact table
  **both ways**: by `seed` (drill one universe) and by `zone_name_id` (per-named-
  body stats across the corpus — "how does Grishord's beryllium vary").
  Properties/quantities still differ per seed (each instance has its own
  `zone_seed`), so per-name aggregates are *distributions*.
- **Reconstruct a universe with one flat scan:** `SELECT * FROM zone WHERE
  seed = ?`, rebuild the tree in app code from `parent_name_id`/`star_name_id`.
  No recursive CTE, no per-level joins; depth is irrelevant.
- **Aggregate at any level with a plain `GROUP BY`** — `seed` (universe),
  `star_name_id` (system), `zone_name_id` (per-body), or `kind` — no traversal.
- **Controls vs quantity, with provenance.** Universe-gen yields the per-resource
  *controls* (`frequency/size/richness`, `present`) — cheap, universal, and the
  actual driver; store these. The *quantity* (`tiles/amount`) is derived either by
  an **estimate** (analytic from controls; estimator still TBD) or a **measured**
  run of the surface **GPU ore kernel** on select seeds. `source` tags which, and
  a row can be **upgraded estimate→measured in place**. The `measured` rows double
  as ground-truth to build the better estimator, which then backfills the rest.
- **Presence bitmask (`present_mask`)** on the leaf (OR-rolled to a per-system
  mask) answers co-occurrence/containment join-free: pairing A∧B =
  `(present_mask & bAB) = bAB`. Derived from the universal control data, so it
  covers every zone even before any quantity exists; the fact table holds amounts.
- **No wide pivot** (a column per resource) — it would force a schema migration
  per mod resource and defeat the extensibility goal.

Open forks (decisions below): **coverage** — materialise control/estimate rows
for *all* stored seeds vs only surface-generated ones (bitmask carrying presence
for the rest); **estimate storage** — store estimates as (versioned, upgradeable)
rows vs compute-on-read from stored controls; **engine** — see below.

## Store choice at scale

Current index is ~tens of millions of seeds. Points to weigh (decision below):

- **SQLite (normalized):** fine for the metric index; single-writer + WAL is
  already how it runs. Blobs-in-SQLite is where it strains — another reason to
  keep images out of the DB.
- **DuckDB / Parquet (columnar):** the GUI's workload is metric scans + sort +
  range filters over tens of millions of rows — exactly columnar's strength, and
  it compresses the coded columns hard. Worth considering if query latency on the
  normalized SQLite proves poor.
- **Postgres:** concurrent writers + TOAST blobs; heavier to operate, probably
  overkill unless multi-user — **but see hosting.**

### Hosted (Google Cloud) — now a live possibility

Credentials for a **remote Google Cloud DB** may be available to host this. That
changes the calculus toward a managed relational store and makes multi-user
access real:

- **Cloud SQL for PostgreSQL** — the natural primary candidate. Managed Postgres
  unlocks features SQLite lacks that map straight onto this schema: `int[]` +
  **GIN** indexes for the presence-set / co-occurrence queries, `JSONB`, optional
  `ltree` for the tree, **materialized views** for pairing/quantity rollups, and
  **partitioning** (by bucket / seed range) for the large `zone`/`zone_resource`
  tables. Good for both the flat drill-down *and* moderate analytics.
- **AlloyDB** — Postgres-compatible with columnar acceleration; step up if the
  heuristic/aggregate workload outgrows Cloud SQL.
- **BigQuery** — serverless columnar warehouse; ideal for the **corpus heuristics**
  (market-basket / co-occurrence / quantity distributions over tens of millions of
  rows), but query-priced and weak at low-latency per-seed point lookups. Best as
  an **analytics layer beside** a transactional store, not the primary.
- **Images / large blobs → Google Cloud Storage (GCS)**, never the DB. With
  hosting, "no local disk" becomes "**data in the managed DB + images in a GCS
  bucket**" (regenerated on demand by a server-side generator/GPU worker, cached
  in GCS/CDN). The deterministic-regeneration model is unchanged — it just needs a
  **server-side compute path** (where does the Zig generator + GPU kernel run?
  see open questions).

Lean if hosted: **Cloud SQL Postgres as the index/store (partitioned, coded
columns, GIN for presence sets), GCS for images, BigQuery only if corpus analytics
demand it.** Lean if local: **normalized SQLite (or DuckDB); images regenerated on
demand; no `output/` tree.**

## Migration — expand → backfill → verify → cut over → contract

The DB stays live throughout. This is a **parallel-change (expand/contract)**
migration: add the new structure alongside the old, move reads over once proven,
then drop the old. Nothing destructive happens until after verification.

> **Safety:** develop and rehearse the whole sequence against a **copy** of
> `data.sqlite` and a **copy** of `output/` first — never the live 13 GB DB or the
> real output tree. The contract phase (`DROP`/`VACUUM`, file deletion) is
> irreversible; snapshot before it.

1. **Expand (additive, reversible, DB serving normally).** Create the lookup/
   dictionary tables (from `data.zig`, same code space as the binary format), the
   new `zone` and `zone_resource` tables, and any new `seeds` columns. Old
   `zones`, `seeds.line`, and `output/` are untouched. `CREATE TABLE`/`ADD COLUMN`
   are cheap in SQLite.

2. **Backfill (background, idempotent, resumable, DB live).** Because generation
   is deterministic, the cleanest source is **regeneration**, not transforming the
   old rows (which lack the tree/parent and the controls):
   - For each stored seed (batched, a cursor tracks progress), **re-run the
     universe generator** → populate `zone` (flat leaves + ancestry codes) and
     `zone_resource` (`present` + controls; `source` empty/estimate). The generator
     is fast (~1 M seeds / 52 s), so the corpus is hours, not days.
   - **Import existing on-disk surface data**: parse each `summary.json` into
     `zone_resource` `measured` rows (`source='measured'`) **before** its files are
     deleted, so real stats aren't lost.
   - Idempotent (`INSERT OR REPLACE` on the PKs) so it can stop/resume and re-run
     safely.

3. **Verify (DB live, old still authoritative).** Run a checker over a sample of
   seeds comparing new-table results against the old: zone counts per seed, primary
   per zone, the header metrics (`npl/naqdv/…`) recomputed from `zone`, and (for
   surface-generated seeds) measured resources vs the old `summary.json`.
   Discrepancy list must be empty (or explained) before cut-over.

4. **Cut over the UI (reversible).** Point the GUI reads (`getSeeds`, zone detail,
   surface summary) at the new tables — ideally behind a flag so you can flip back.
   `getSeeds` stays flat (no new joins); zone detail becomes `WHERE seed = ?` on
   `zone`; resource views read `zone_resource`. Old tables remain as a rollback net.

5. **Contract (destructive — only after cut-over is proven, with a backup).**
   - `DROP TABLE zones`; drop `seeds.line` / dead `resource_scores`/`resource_yields`
     (SQLite ≥3.35 `DROP COLUMN`, else table-rebuild).
   - **Delete `output/`** — universe files first (regenerable), then surface
     artifacts once measured data is imported (step 2) and images regenerate on
     demand (the images decision). Clear the `output_file`/`png_file` path columns.
   - `VACUUM` to reclaim space (needs transient ~2× free space — plan for it).

Notes / caveats:
- This sequence is **in-place**, which favours **staying in SQLite**. If the engine
  fork picks **DuckDB or a hosted DB (Cloud SQL Postgres)**, "migration" instead
  becomes *build the new store in parallel and swap*: **regenerate** from the seed
  list straight into the target (no need to lift the old rows), verify against the
  old SQLite, repoint the app, then retire the local DB + `output/`. Same
  expand→verify→cut-over→contract spirit, different mechanics — and because the
  store of record is just the seed list, regenerating into a fresh remote DB is
  often *simpler* than an in-place transform. Images land in **GCS**, not the DB.
- Do the "measure what dominates the 13 GB" check (open questions) **before** the
  contract phase so the space reclaim is predictable.
- Nothing in steps 1–4 loses data or blocks the GUI; the only one-way door is
  step 5, gated on a passing verify and a snapshot.

## Relationship to the binary-format doc

- The on-disk **protobuf files** (binary-format decision row 2) become **moot** —
  nothing lands on disk.
- protobuf may still serve as **(a)** the generator→DB **pipe/interchange** format
  and **(b)** the stored re-expand **blob** *if* we keep one (row 3). Its
  Dictionary code space **is** the DB's lookup-table code space — define the codes
  once, share everywhere.
- So: keep the protobuf schema for the wire/interchange, drop it as a storage
  layout, and normalize the DB against the same codes.

---

## Decisions

| #   | Decision                                       | Choice                                                                       | Date       | Rationale                                                                                                                                        |
| --- | ---------------------------------------------- | ---------------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | Delete the `output/` file tree                 | _tbd_ — **yes** (user)                                                       | 2026-07-31 | Unindexed second copy of derivable data; store should be query-first                                                                             |
| 2   | Store of record                                | _tbd_ — the seed list + mod_set + gen version (everything else derived)      |            | Generation is deterministic                                                                                                                      |
| 3   | Normalize `zones`/`seeds` TEXT → integer codes | _tbd_ (yes)                                                                  |            | SQLite affinity is a no-op; interning is the real lever; share the binary-format Dictionary codes                                                |
| 4   | `seeds.line` raw JSONL                         | _tbd_ — drop (regenerate) vs protobuf blob                                   |            | Likely dominates the 12 GB; regenerable                                                                                                          |
| 5   | Surface ore/summary                            | _tbd_ — regenerate vs cache row                                              |            | Derived; summary is small, per-cell ore is large                                                                                                 |
| 6   | Images                                         | _tbd_ — **regenerate on demand + LRU**                                       |            | Only option that truly removes disk                                                                                                              |
| 7   | Store engine                                   | _tbd_ — local SQLite/DuckDB **vs hosted Cloud SQL Postgres** (creds pending) | 2026-07-31 | Hosting may be available → managed Postgres (GIN presence sets, partitioning, MVs) + GCS images + multi-user; BigQuery only for corpus analytics |
| 13a | Where compute runs (if hosted)                 | _tbd_ — server-side generator + GPU worker for on-demand regen               |            | Deterministic regen needs a compute path near the hosted DB; images → GCS cache                                                                  |
| 8   | Tree modelling                                 | **Flat leaves + denormalised ancestry** (no branch tables, no recursion)     | 2026-07-31 | User pref; shallow fixed tree, regenerated wholesale → no update anomalies; whole universe = one `WHERE seed=?` scan                             |
| 9   | Zone instance grain                            | **`(seed, zone_name_id)`**; `zone_name_id` a shared code                     | 2026-07-31 | Names shared across seeds but unique within one; index both ways for drill-down + per-body corpus stats                                          |
| 10  | Zone-resource facts                            | **Fact table** w/ controls + `source` (estimate\|measured) + version         | 2026-07-31 | Controls are the universal driver; quantity provenance lets estimate→measured upgrade; measured = estimator ground truth                         |
| 11  | Co-occurrence fast path                        | **Presence bitmask** on leaf + per-system roll-up                            | 2026-07-31 | Join-free pairing/containment from universal control data; amounts stay in the fact table                                                        |
| 12  | Migration strategy                             | **Expand → backfill(regenerate) → verify → cut over → contract**, in place   | 2026-07-31 | DB stays live; destructive step gated on verify + snapshot; rehearse on a copy                                                                   |
| 13  | Backfill source                                | _tbd_ — **regenerate** from seeds vs transform old rows                      |            | Old rows lack tree/controls; regeneration is deterministic + fast (~1M/52s) and complete                                                         |

## Open questions

- What actually dominates the 13 GB — measure `seeds.line` vs `zones` vs indexes
  before deciding row 4 and before the contract phase. (`SELECT SUM(LENGTH(line)) …`,
  `dbstat`.)
- **Coverage:** materialise `zone`/`zone_resource` for *all* stored seeds, or only
  surface-generated ones (bitmask carrying presence for the rest)? (decision-shaping)
- **Estimate storage:** estimates as versioned upgradeable rows vs compute-on-read
  from stored controls?
- Is on-demand surface render fast enough for interactive drill-down, or is a
  bounded image cache needed in practice?
- Do we ever need to query *inside* a surface (per-tile), or only per-zone
  summaries? (Decides whether `ore.jsonl` data needs any DB presence at all.)
- **Hosting (pending creds):** which GCP service — Cloud SQL Postgres alone, or a
  split (Postgres for drill-down + BigQuery for corpus analytics)? What's the cost
  model at tens-of-millions of rows, and where does the generator/GPU-kernel
  compute run so on-demand regeneration works next to a remote DB?
