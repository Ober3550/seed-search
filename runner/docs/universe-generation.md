# Universe generation & PRNG accounting

Target mod: **Space Exploration `0.7.57`** (Factorio **2.0** / Space Age era).
The old seed finder was written against SE **`0.6.114`** (Factorio 1.1). The
generation algorithm was rewritten between those versions, which is why seeds no
longer match in game. This document records *where* generation happens and
*exactly how the PRNG is consumed*, because the seed finder only reproduces a
seed if it draws from the PRNG **the same number of times, in the same order**,
as the game does.

> "Seed" here means a PRNG start (call count 0). To mimic the game we must roll
> the PRNG the identical number of times as the generator, in identical order.
> There is **no single constant "count"** — the total number of draws is
> seed-dependent (several loops are data-dependent). What is invariant is the
> *ordered algorithm*; the finder must reimplement it faithfully.

## Where generation is filed

Harness side (this repo):

| Step | File | What it does |
|------|------|--------------|
| Entry point | `generate.lua` | iterates seeds in a chunk, calls `summarize.summarize_seed(seed)` |
| Per-seed driver | `summarize.lua` → `summarize_seed()` | sets `FactorioRNG.global_seed = seed`, resets globals, calls **`Universe.build()`**, then reads back `zones_by_name` / children |
| Mod loader + stubs | `se_env.lua` | extracts the mod zip and `load()`s `scripts/universe.lua` etc.; stubs the Factorio runtime (`game`, `settings`, `defines`, RNG) |
| PRNG implementation | native `rng` module (compiled into `bin/lua`) | `FactorioRNG.__call = rng.call` — replicates Factorio's `LuaRandomGenerator` |

Mod side (inside `space-exploration_0.7.57.zip`):

| File | Role |
|------|------|
| `scripts/universe.lua` | **`Universe.build()`** — the top-level generator |
| `scripts/universe-raw.lua` | static data: star / planet / moon / asteroid-field name pools |
| `scripts/universe-homesystem.lua` | `make_validate_homesystem()` — guarantees the starting system's resources (called at the end of `build`) |
| `scripts/zone.lua`, `scripts/zonelist.lua` | zone objects & indexing |

## The two PRNG streams (most important thing to get right)

SE `0.7.x` uses **two distinct kinds** of random generator. Conflating them is
the easiest way to desync the finder.

1. **The global universe stream — `storage.universe_rng`.**
   Seeded **once** at the start of `Universe.build()` from the map seed:
   `storage.universe_rng = game.create_random_generator()` (no argument → uses
   the initial map seed). *Every* draw advances one shared state. The order and
   count of these draws is what must match the game. Used by the structural code
   in `Universe.build()` and by `universe-homesystem.lua`.

2. **Per-zone independent sub-streams — `game.create_random_generator(zone.seed)`.**
   Each zone is given a `zone.seed` drawn from the global stream (one
   `storage.universe_rng(4294967295)` per zone). Climate, tags, and resource
   detail are then rolled from a *fresh generator seeded by that `zone.seed`* —
   these draws **do not touch the global stream**. Sites:
   - `Universe.inflate_climate_controls` (`universe.lua:1565`, `crng`)
   - `Universe.fit_climate_to_primary_resource` (`universe.lua:1855`)
   - `Universe.generate_zone_resource_bias` (`universe.lua:1170`)
   - `Universe.get_resource_settings_and_order` (`universe.lua:740`, seeded from
     `storage.seed`, the map seed)

   Consequence for the port: once you know a zone's `zone.seed`, all of its
   climate/resource rolls can be reproduced **in isolation**, independent of
   global ordering. Only the *assignment* of `zone.seed` values consumes the
   global stream.

### Call semantics

The generator is called three ways (`universe.lua:326-330`):

- `rng()` → float in `[0, 1)`
- `rng(N)` → integer. Factorio's `LuaRandomGenerator` returns `[1, N]`. **Note:**
  the comment in `build()` says `[0, N]`; the authoritative behaviour is whatever
  the native `rng` module / `factorio-util.lua` implements — verify against the
  old harness before trusting either comment.
- `rng(N1, N2)` → integer in `[N1, N2]`

`Universe.shuffle` (`universe.lua:1848`) is Fisher–Yates via
`util.shuffle_with_generator`: for a table of length `n` it makes **`n - 1`**
draws (`for i = #tbl, 2, -1 do random_generator(i) end`).

## Global-stream draw sequence in `Universe.build()`

In order. `F` = fixed number of draws, `V` = variable (data/loop-dependent).

| # | `universe.lua` | Draws | Notes |
|---|------|-------|-------|
| 1 | 347 | F: 1 | `requested_planets` |
| 2 | 364 | F: 14 | `shuffle(unassigned_moons)` — 15 entries → 14 |
| 3 | 365 | F: 30 | `shuffle(stars)` — 31 → 30 |
| 4 | 366 | F: 15 | `shuffle(unassigned_planets)` — 16 → 15 |
| 5 | 367 | F: 533 | `shuffle(unassigned_planets_or_moons)` — 534 → 533 |
| 6 | 376 | F: 16 | one `rng(1,#stars)` per unassigned planet (16) |
| 7 | 383 | F: 0 | fill min-planets-per-star: pops only, no draws |
| 8 | 393–402 | **V** | build remaining planets: `rng(1,#stars)` each iter, **+1** extra `rng()` only when a star is already full (`#children >= high_planets_per_star`, short-circuit) |
| 9 | 406 | F: 15 | one `rng(1,#all_planets)` per unassigned moon (15) |
| 10 | 415 | F: 0 | min-1-moon-per-planet: pops only |
| 11 | 449–459 | **V** | build remaining moons: `rng(1,#all_planets)` each iter, **+1** extra `rng()` when planet already full |
| 12 | 487–584 | **V** | per-star loop: `random_stellar_position` = **2** draws/star (`491/493`); `rng(1,max_asteroid_belts)` = 1/star (`505`); `shuffle(star.children)` (`508`); 1 `rng()` per inserted asteroid belt (`511`); per planet: `radius_multiplier` 1 draw (`547`) + `shuffle(planet.children)` (`562`); per moon: `radius_multiplier` 1 draw (`566`) |
| 13 | 586 | **V** | `shuffle(space_zones)` — 45 → 44 draws |
| 14 | 590 | F: 90 | `random_stellar_position` per space zone = 2 × 45 |
| 15 | 594–597 | **V** | **one `rng(4294967295)` per zone in `zone_index`** (`595`) to assign `zone.seed`. `inflate_climate_controls` (`596`) uses the per-zone sub-stream, **not** the global stream |
| 16 | 647 | **V** | `UniverseHomesystem.make_validate_homesystem` — up to ~11 global draws (`universe-homesystem.lua`), conditional on which guaranteed resources (vulcanite planet; cryonite/iridium/holmium/vitamelange/haven moons) are missing from the rolled home system; may create new zones and draw seeds/radii for them |
| 17 | 651+ | F: 0 (global) | `load_resource_data` / resource assignment use **independent** generators seeded from `storage.seed` and `zone.seed`, not the global stream |

So the global draw count ≈ `1 + 14 + 30 + 15 + 533 + 16 + 15` fixed prologue
(= 624), plus the star/planet/moon structural draws (depend on how the pool got
partitioned), plus one seed draw per generated zone, plus the homesystem draws.
**It is not a fixed number** — the finder must execute the same branches.

## Static pool sizes (`universe-raw.lua`, v0.7.57)

| Pool | Count |
|------|------:|
| `stars` (incl. Calidus; Nauvis is Calidus's child) | 31 |
| `space_zones` (asteroid fields etc.) | 45 |
| `anomaly` | 1 |
| `unassigned_planets` | 16 |
| `unassigned_moons` | 15 |
| `unassigned_planets_or_moons` | 534 |
| `haven_moons` | 33 |
| `vulcanite_planets` | 18 |
| `cryonite_moons` | 16 |
| `iridium_moons` | 16 |
| `holmium_moons` | 16 |
| `vitamelange_moons` | 17 |
| `prototypes_by_name` (all, deduped) | 758 |

## Generation constants (`universe.lua:49-57`)

```
planet_max_radius          = 10000
average_moons_per_planet   = 3
max_asteroid_belts         = 2
stellar_average_separation = 50
```

Derived in `build()`:
`average_planets_per_star = (#planets + #moons + #p_or_m) / (average_moons_per_planet + 1) / n_stars`,
`requested_planets = rng(floor(0.9·app·n_stars), ceil(1.1·app·n_stars))`,
`requested_moons = #moons + #p_or_m − requested_planets`.

## What changed from `0.6.114` → `0.7.57` (port checklist)

- **`global` → `storage`.** All state (`storage.zones_by_name`,
  `storage.zone_index`, `storage.universe_rng`, `storage.seed`, …) moved. The
  harness stubs and `summarize.lua` reference `global`; they must be updated.
- **New modules to load** in `se_env.lua` (currently only loads the 0.6 set):
  `scripts/universe-homesystem.lua` (`UniverseHomesystem`),
  `scripts/zonelist.lua`, and the rewritten `universe-raw.lua` / `universe.lua`.
- **Homesystem guarantees** are new: `make_validate_homesystem` runs at the end
  of `build` and consumes global RNG — it must be reimplemented or the stream
  desyncs before resource assignment.
- **`MOD_VERSION`** in `se_env.lua` is hard-coded to `'0.6.114'` — bump to
  `'0.7.57'` and drop the zip in `mods/` (or set `FACTORIO_HOME`).
- **Two-stream RNG** (above) — the biggest correctness risk for matching seeds.

## Port status (harness now runs against 0.7.57)

`se_env.lua` and `summarize.lua` have been updated so the real 0.7.57 generator
runs headless. What was changed / verified:

- **`se_env.lua`**: `MOD_VERSION` → `0.7.57`; added `storage`, `is_debug_mode`,
  `mod_prefix_snake_case`, `game.print`; `Event` is now a catch-all no-op;
  loads the new modules `Log`, `Zonelist`, `UniverseHomesystem`; and adds a
  Factorio-2.0 `prototypes` global (backed by the existing hardcoded
  entity/item/autoplace tables) with `get_entity_filtered` and the
  `se-universe-resource-word-rules` `mod_data` entry (empty for pure SE).
- **`summarize.lua`**: `global` → `storage` with the tables the generator reads
  before writing (`seed`, `meteor_zones`, `zones_by_surface`, `spaceships`,
  `forces`, `cache_travel_delta_v`); mirrors `Ancient.on_init` to seed
  `vault_loot_rng`; loot module rename `effectivity-module-9` →
  `efficiency-module-9`.

**Verified under docker (linux/amd64):**

- `Universe.build()` runs to completion. Seed `123456` → 1269 zones
  (31 stars, 153 planets, 402 moons, 45 asteroid-fields, 51 asteroid-belts,
  586 orbits, 1 anomaly). Nearly the entire body pool is consumed every seed, so
  the *set of names* barely changes between seeds — only hierarchy/positions/
  resources do.
- RNG semantics confirmed: `rng()` ∈ `[0,1)`, `rng(N)` ∈ `[1,N]`, `rng(N1,N2)`
  ∈ `[N1,N2]` — i.e. real Factorio semantics; the `build()` comment's `[0,N]` is
  wrong. The Tausworthe seed init masks the low bit (`seed & 0xFFFFFFFE`), so
  seeds differing only in the low bit are identical — which is exactly why
  `generate.lua` steps seeds by 2. Seeds differing by 2 diverge as expected.
- Full `summarize_seed` → `bin_pack` → `bin_unpack` round-trips (~929 B/seed).

### Running it here (Apple Silicon)

The `bin/lua` interpreter is a Linux x86_64 ELF with native modules, so it can't
run on macOS directly. Build the helper image once and run through it:

```
docker build --platform linux/amd64 -t seedlua - <<'EOF'
FROM --platform=linux/amd64 debian:bookworm-slim
RUN apt-get update -qq && apt-get install -y -qq libreadline8 libcurl4 && rm -rf /var/lib/apt/lists/*
EOF
docker run --rm --platform linux/amd64 -v "$PWD":/w -w /w \
  --entrypoint /w/runner/bin/lua-linux-x86_64 seedlua <script>.lua
```

The mod zip must be at `runner/mods/space-exploration_0.7.57.zip` (already copied there;
`runner/mods/*.zip` is gitignored). Throughput under emulation ≈ 0.24 s/seed; the native
Linux workers this tool targets will be several times faster.

## Optional Krastorio2 support

Set `SE_ENABLE_K2=1` in the environment to model SE **with Krastorio2 active**
(any consumer — `generator/generate.lua`, `verifier/compare.lua`, `verifier/harness-dump.lua` — reads
it via `se_env`). It reproduces what SE's K2 compatibility does to generation:

- **Data stage** (`se_k2.lua`): adds the resources `kr-rare-metal-ore`,
  `kr-mineral-water`, `kr-imersite` (+ their core fragments) and the
  `kr-imersite` placement rule (`forbid_space`, `forbid_homeworld`).
- **Control stage** (`scripts/compatibility/krastorio2.lua`, loaded when K2 is
  on): its `on_resource_setting_load` listener adds the `kr-mineral-water`
  override, and its `on_homesystem_make` listener adds a **guaranteed imersite
  home-system body**. To make these fire, `se_env`'s `Event` is a real (minimal)
  dispatcher and `script.active_mods["Krastorio2"]` is set.

Because the imersite body is created via `add_special_moon_from_unassigned`, it
**draws from the global universe RNG**, so K2 shifts the RNG stream and produces a
**different universe (and different seeds) than pure SE** from that point on. Pure
SE is unaffected (no base listeners for those events). Verified for one seed:
pure SE → 1268 zones, K2 → 1270 (the imersite moon + its orbit); both reproducible
across processes and self-comparing PERFECT.

⚠ When verifying K2 against the game, the in-game mod set must **also** have K2
enabled (`SE_ENABLE_K2=1 verifier/verify/verify-seed.sh <seed>` forwards the toggle
to the finder; you must enable K2 in `SE_MODS_DIR`). Note the finder's summary
vocabulary (`se_data.RESOURCE`) is unchanged, so `kr-*` resources are generated
but not yet scored/packed — add them there if the finder should weigh them.

## ⚠ Determinism: `pairs()` iteration order (critical)

SE 0.7's generator draws from the universe RNG **inside string-keyed `pairs()`
loops** (notably `universe-homesystem.lua`'s `guaranteed_special_types` loop), so
iteration order changes the RNG draw sequence and therefore the universe.

**Factorio iterates tables in insertion order.** Confirmed by probing a live
game (its console runs Factorio's own Lua): `{zebra,apple,mango}` iterates
`zebra,apple,mango`, and building a table by scrambled assignments iterates in
exactly that assignment order. This is Factorio's determinism mechanism (a
Lua modified to preserve insertion order), *not* natural hash order.

Plain Lua 5.2 (our `bin/lua`) instead uses hash order with a per-process random
seed (`luai_makeseed() == time(NULL)`), so `pairs()` order — and thus the
generated universe — **changes every run**, and can't recover a table's insertion
order after the fact.

`det_pairs.lua` (loaded first by `se_env.lua`) handles this in two layers:

- **Default:** a **stable sorted-key** order. Reproducible across processes, and
  it matches the game everywhere iteration order doesn't affect the result
  (arrays iterate identically; most string-keyed loops are order-independent).
- **Override:** `det_pairs.set_order(tbl, keys)` registers the real insertion
  order for a specific table. The one table whose order drives RNG draws —
  `UniverseHomesystem.guaranteed_special_types` — is registered in `se_env.lua`
  with its source-literal order; runtime additions (K2's `kr-imersite`) are
  appended, matching insertion order. This makes the generated universe match the
  real game exactly (verified: 1270/1270 and 1266/1266 zones, zero mismatches).

The only fully-general fix is an insertion-order-preserving interpreter like
Factorio's; that needs rebuilding `bin/lua`, blocked by the lack of source for
its native `zip`/`rng`/`env`/`curl` modules. `det_pairs.lua` + `set_order` is the
one place to extend the ordering rule if another order-dependent loop surfaces.

## Comparison harness (validate against a real map)

Three pieces close the "does it match the game?" gap:

- `verifier/ingame-dump.lua` — a console command to run in-game (SE 0.7.57) that
  writes every zone's `name/type/parent/radius/seed` + the map seed to
  `script-output/se-universe-dump.json`.
- `verifier/compare.lua` — `runner/bin/lua verifier/compare.lua <dump.json> [seed]` regenerates the
  universe for that seed and diffs it against the dump. Each zone's `seed` is
  drawn sequentially from the global RNG, so **all zone seeds matching by name ⇒
  the RNG stream ran in perfect lockstep**. Exit 0 = perfect, 1 = differences.
- `verifier/harness-dump.lua` — writes the harness's own generation in the same
  schema (for eyeballing and self-testing `compare.lua`).

Self-tested: a harness dump compared against its own seed reports PERFECT (1268/
1268 zones); against a different seed it reports ALL SEEDS DIFFER. Interpreting a
real run: a *structural* diff (only-in-\* / parent) means the global stream
desynced (suspect `pairs` order or the seed→generator mapping); *isolated* seed
mismatches localise where an earlier zone consumed a different number of draws;
same set but all seeds wrong ⇒ the seed value/mapping is off from draw one.

Dump the map **early** (right after creation, before visiting surfaces) so zones
carry only their generated values.

### Native runner (macOS, no docker)

`verifier/verify/ingame_dump.py` + `verifier/verify/verify-seed.sh` automate the above
against the installed `factorio.app` (universal binary, runs arm64) using headless
`--create` + `--start-server` + RCON — no docker, no Xvfb. It uses Factorio's
default local mod dir, so whatever is enabled there (here SE + Krastorio2)
decides the map; run the finder with a matching mode (`SE_ENABLE_K2=1`).

### Result — SE + Krastorio2 (PERFECT)

Two independent seeds, real game vs finder (K2 mode):

```
seed 123458:    1270/1270 zones, 0 mismatches; 68526 resource control fields, 0 mismatches — PERFECT
seed 987654321: 1266/1266 zones, 0 mismatches; 68310 resource control fields, 0 mismatches — PERFECT
```

**Every zone matches the real game exactly** — name, per-zone seed, type, parent,
radius, *and* every resource control (frequency/richness/size for all SE + K2
resources). The RNG stream runs in complete lockstep; the port (and the K2
support) is validated against ground truth, structure and resources alike.

(The only value not compared is the homeworld's ground resources: in-game Nauvis'
resources come from the live starting surface's map-gen controls, not universe
generation, so `compare.lua` skips them.)

Getting here took two fixes found via the comparison:

1. **Iteration order.** The first run matched 1256/1258 seeds; the sole divergence
   was `make_validate_homesystem` iterating `guaranteed_special_types` in a
   different order. Probing the live game (its console runs Factorio's own Lua)
   showed Factorio iterates tables in **insertion order**, not sorted or hash
   order (`{zebra,apple,mango}` → `zebra,apple,mango`). `det_pairs` now registers
   that table's real insertion order (see the determinism section).
2. **Nauvis radius.** The harness stubbed `planet-size` frequency at 6; the map
   default is 1. Fixed the stub (feeds no RNG — only Nauvis' radius and its
   derived haven moon).
