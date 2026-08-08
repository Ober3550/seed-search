# Universe output binary format — design & decisions

Status: **DECIDED — Protocol Buffers (proto3), length-delimited stream.** See
[Decision: Protocol Buffers](#decision-protocol-buffers). The custom / MessagePack
/ fixed-struct options below are retained as *alternatives considered*. Nothing is
implemented yet.

## Why

The universe generator (`seedgen`) currently emits **JSONL** — one *world* per
line. It is read by:

- **`space_explorer_gui`** (Node): `JSON.parse` per line → SQLite, and the raw
  line is stored as the re-expand source.
- **`surface_generator` / `segen`** (Zig): `std.json` parse, looks up one world
  by seed and its zones by name.

Motivations for going binary:

1. **Size** — JSON is dominated by repeated strings (zone/type/tag/resource
   names). 580k on-disk `zones.jsonl` files + large piped bulk streams.
2. **Parse speed** — `JSON.parse` per line on GUI import; string→enum reparsing
   in Zig.
3. **Extensibility (the hard requirement)** — output is **optional per mod**:
   vanilla omits `kr-*` resources, K2 adds them, and a future mod may add new
   resources *and new per-zone fields*. **An old reader must be able to skip a
   field it has never heard of** rather than fail. The previous project used a
   fixed binary struct, which does *not* allow this.

## What the format carries today

**World record** (one per seed):

| key           | meaning                                               | type         |
| ------------- | ----------------------------------------------------- | ------------ |
| `s`           | seed                                                  | uint         |
| `d`           | degenerate draws                                      | small uint   |
| `k`           | K2 enabled                                            | bool         |
| `l`           | vault-loot code                                       | short string |
| `npl`         | Calidus planets                                       | small uint   |
| `npm`         | Calidus planets+moons                                 | small uint   |
| `nw` `ne`     | n water / n enemy bodies                              | small uint   |
| `wp` `ef`     | water% / enemy%                                       | 0..100       |
| `naqdv` `fdv` | Δv to nearest naquium / any field (`10000000` = none) | uint         |
| `ed`          | signed enemy value                                    | -100..100    |
| `z`           | zone array                                            | list         |

**Zone record**:

| key                                                            | meaning                                  | type                                        | optional |
| -------------------------------------------------------------- | ---------------------------------------- | ------------------------------------------- | -------- |
| `i`                                                            | index                                    | small uint                                  | no       |
| `n`                                                            | name                                     | string                                      | no       |
| `t`                                                            | zone type (planet/moon/asteroid-field/…) | enum (~8)                                   | no       |
| `s`                                                            | zone seed                                | u32                                         | no       |
| `c`                                                            | in-Calidus flag                          | bool                                        | no       |
| `r`                                                            | radius                                   | **f64, full precision** (drives noise freq) | yes      |
| `temperature` `water` `moisture` `trees` `aux` `cliff` `enemy` | SE tags                                  | enum (~5–7 each)                            | yes      |
| `p`                                                            | primary resource                         | string (finite per mod)                     | yes      |
| `dv`                                                           | Δv from Nauvis                           | uint                                        | yes      |

Three facts that drive the design:

- **Strings dominate, and nearly all come from finite sets** — 8 zone types,
  ~5–7 values per tag, a fixed resource list per mod. Enums → 1 byte and
  resource-name interning is where the savings are. Only *zone names* are partly
  free-form (some static body tables, some generated).
- **Optionality is the extension axis** — vanilla vs K2 vs future mods differ by
  which fields/resources appear. Forward-compat skip-unknown is mandatory.
- **Two framings coexist** — one big piped stream (GUI bulk import; interning
  amortises well) and tiny per-seed `zones.jsonl` files (~18 Calidus zones; a
  per-file string table barely pays off). Symbols should come from a shared
  static dictionary, not a per-file table.

---

## Decision: Protocol Buffers

**Chosen.** proto3 schema in a `.proto` file, streamed **length-delimited** (one
varint-prefixed `Universe` message per record — the JSONL-line replacement).

### Why protobuf (over the alternatives below)

- **The schema is code, and it's neutral.** One `.proto` file is the single
  source of truth, decoupled from both the Zig backend and the Node frontend —
  the primary reason for this choice.
- **Field numbers ARE the extensibility requirement.** Every field has a stable
  number; a reader that meets an unknown field number skips it by wire type and
  keeps going. That is exactly "an old reader skips a mod field it has never
  heard of" — for free, as a wire-format guarantee, not something we hand-roll.
- **Presence is built in.** proto3 `optional` gives explicit has/no-has for the
  per-mod optional fields (radius, tags, `p`, `dv`) without sentinels.
- **Integer codes + a header dictionary recover the size AND keep it
  self-describing.** Zone names, zone type, the seven tags, and the resource list
  travel as small integer *codes* (1–2 byte varints) instead of repeated strings
  — the bulk of JSON's size — and a
  [Dictionary header](#self-describing-header-dictionary) maps every code back to
  its canonical string. Belt names aren't even coded — they're inferred from tree
  position. (If size still bites, gzip the stream.)
- **Radius fits in a `float`.** VERIFIED (see [Packing](#packing--field-sizing)):
  radius feeds only a continuous noise frequency (`5000/radius`) and an integer
  extent (`@intFromFloat`), never an RNG seed or hash, and the project's accepted
  ~95% biome bar swamps f32's ~1e-7 error. `float` (fixed32) = 4 bytes, not 8.

### Self-describing header (Dictionary)

A raw protobuf file is **not** self-describing — it carries field *numbers* and
enum *integers*, but the names live in the `.proto`, out-of-band. Two things are
missing versus JSON:

1. **Field names** — wire tags say "field 7, length-delimited", not `primary`.
2. **Enum/code value names** — a value is just an integer; a mod-added code is an
   unexplained one.

So the mod-extended / repeating string fields carry `uint32` *codes* (not
protobuf `enum`s, not inline strings) that a **`Dictionary` resolves**. This buys
two things at once:

- **Decodable like JSON.** A reader loads the Dictionary, then renders every code
  as its string — no external `.proto` needed to *display* the data.
- **Mods extend by data, not schema.** Adding a mod's resource/tag value is a new
  Dictionary entry — **zero `.proto` edit, zero code assignment ceremony.** This
  is the real payoff for "optionally including other resources and mods": the
  volatile part (which codes exist) is self-described in the Dictionary, while the
  stable part (World/Zone field *numbers*) stays in the `.proto`.

#### The Dictionary is **per bucket**, not per world

Across all worlds in a bucket the stringy data is identical — **the same zone
names, the same enum/tag/resource names.** Only per-world *properties* (which seed,
which radius, which tag value) differ, not the vocabulary. So the Dictionary is
written **once per bucket** and every world in it references the shared codes:

- **Zone names join the dictionary too.** VERIFIED against `data.zig`: every
  resource-bearing zone (planet / moon / asteroid-field) is named from a fixed
  table, so `Zone.name` becomes a `uint32` code into `Dictionary.zone_name` and
  the last free-form string is gone. The name space is **~757 distinct static
  names** (see [Zone-name inventory](#zone-name-inventory)) — not even
  bucket-computed; it's the same static set for every bucket of a given mod-set,
  generated straight from `data.zig`.
- **Amortised to nothing.** One dictionary for ~1Mi seeds; the per-world overhead
  of self-description rounds to zero.
- **No escape hatch needed.** Every body/field name is a dictionary code, and
  belt names are *inferred* from tree position (see
  [Hierarchy](#hierarchy-the-tree-is-the-format)) — so no zone stores a free-form
  string at all. `resource` codes keep a code-`0` = "inline string" fallback only
  as forward-proofing for an unregistered mod resource.

Codes are assigned deterministically per `(mod_set, schema_version)` from the
generator's `data.zig` tables, so the same resource/zone has the same code across
buckets (nice for the DB/compares) and each bucket is still independently
decodable. For **full** JSON-like self-description (field *names* too, not just
values), the Dictionary can optionally embed the compiled
`google.protobuf.FileDescriptorSet` — then a generic descriptor-aware reader
needs nothing external at all.

Two levels, pick per the decision table:
- **Level 1 (recommended):** embed the code→string Dictionary per bucket. Values
  are self-describing; field *names* still come from the checked-in `.proto`.
- **Level 2:** also embed the `FileDescriptorSet` in the bucket dictionary. Fully
  self-contained; a few KB of schema amortised across the whole bucket.

### Zone-name inventory

Every zone name is either from a **fixed table in `data.zig`** or one of two
**procedural** patterns. Only table names ever attach to a resource.

| Source table (`data.zig`)     | count | zone kind                                              | has resource?               |
| ----------------------------- | ----- | ------------------------------------------------------ | --------------------------- |
| `stars`                       | 31    | star (skipped in output) + prefix for procedural names | no                          |
| `space_zones`                 | 45    | asteroid-**field**                                     | **yes** (`field_primaries`) |
| `vulcanite_planets_names`     | 18    | planet                                                 | yes                         |
| `cryonite_moons_names`        | 16    | moon                                                   | yes                         |
| `iridium_moons_names`         | 16    | moon                                                   | yes                         |
| `holmium_moons_names`         | 16    | moon                                                   | yes                         |
| `vitamelange_moons_names`     | 17    | moon                                                   | yes                         |
| `haven_moons_names`           | 33    | moon                                                   | yes                         |
| `unassigned_planets`          | 16    | planet                                                 | yes                         |
| `unassigned_moons`            | 15    | moon                                                   | yes                         |
| `unassigned_planets_or_moons` | 534   | planet/moon                                            | yes                         |
| `special_bodies`              | 116   | planet/moon (dupes of the pools above)                 | yes                         |
| `special_moon_multipliers`    | —     | radius overrides (dupes; no new names)                 | —                           |

**Distinct total: ~757** (726 excluding star names). Overlaps are already
deduped. This is the entire `Dictionary.zone_name` set for the SE mod-set.

**Procedural names (NOT in a table):**
- `<Star> Orbit` — type `orbit`; **skipped in serialization** (`main.zig:404`),
  never emitted.
- `<Star> Asteroid Belt <N>` — type `asteroid-belt`; emitted, but the
  resource/tag/`dv` block only runs for `asteroid-field | planet | moon`
  (`main.zig:430`), so a belt is bare `{i,n,t,s,c}` with **no resource**. These
  are the only names that use the code-0 escape.

> Note: the home **beryllium** and **methane** belts are semantically resource
> sources but are typed `asteroid-belt` and currently emit no `p`. Under the
> hierarchical schema below a `Belt` carries an `optional primary`, so if belts
> ever emit resources it drops in without touching names (belt names are inferred
> from tree position, not stored).

### Hierarchy: the tree IS the format

The universe is a tree, and the generator already computes it (`parent_index`,
`computeGravityWells`). **Storing the tree instead of a flat zone list** removes
redundant bookkeeping and directly enables the "generate all star systems" user
request. The real structure (verified in `gen.zig`):

```
Universe
├─ Star*            (Calidus; + all others when "all systems")
│  ├─ Planet*
│  │  └─ Moon*
│  └─ Belt*         name inferred "<Star> Asteroid Belt <ordinal>"
└─ Field*           deep-space asteroid fields — TOP LEVEL, siblings of stars
                    (own stellar coords, no parent)
```

- **Two child kinds under a star: `Planet` and `Belt`.** A belt stores only its
  seed (and future `optional primary`); its **name is generated** as
  `"<parent star> Asteroid Belt <ordinal>"` from its position in the star's belt
  list — never stored. `Field` and `Star` share the top level (deep-space fields
  aren't owned by a star). **Orbits are dropped entirely** (not serialized today
  either).
- **Message type replaces the `t`/`c`/`i` fields.** Which repeated field a node
  sits in *is* its zone type and its parenthood, so the flat `type`, `in_calidus`
  and `index` fields disappear — Calidus membership is "child of the Calidus
  `Star`", ordering is list order. Simpler *and* smaller.
- **Include/exclude a system = include/exclude a `Star` subtree.** The default
  (Calidus-only) emits one `Star`; "all systems" emits all ~31. The GUI's
  "hide other systems" toggle and the all-systems feature become the same
  mechanism, with no flat-list `c` flag to maintain.
- **Tree stored, not re-derived.** Consumers stop rebuilding parent/child links
  from a flat list; the nesting is the structure. `Star` keeps `stellar_x/y` so
  cross-system Δv stays computable when more than Calidus is present.

### Zig codec: try the lib, fall back to hand-written

There **is** a Zig protobuf implementation — [`Arwalk/zig-protobuf`](https://github.com/Arwalk/zig-protobuf)
(user-flagged). It's proto3, supports nested messages / maps / optional /
repeated, generates Zig from `.proto` via `protoc`, and is stated
production-ready (JSON codec still beta). It ships a **`master`** branch (latest
*stable* Zig) and a **`zig-master`** branch (nightly Zig), so tracking our pin is
plausible — but it doesn't advertise a specific 0.16 build, and using it adds a
`protoc` + generated-code step to the build. **Plan:** try the lib first (pick the
branch matching our Zig); if the 0.16 build breaks or the `protoc` dependency is
unwanted, fall back to a **hand-written wire codec** — the wire format is small
(tag = `field<<3 | wire_type`, LEB128 varints, zig-zag for signed, fixed64 for
double; default case skips unknown fields) and the schema is a handful of small
messages (Universe / Star / Planet / Moon / Belt / Field / Body / Dictionary), so
a recursive encode/decode is mechanical either way. Node uses **protobufjs**,
which loads the `.proto` at runtime — no build/codegen step.

### Codec plan

| Side                        | Role     | Codec                                                                                                                                                             |
| --------------------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `seedgen` (Zig)             | producer | `zig-protobuf`-generated, or hand-written encoder: recurse the tree, write tag varint + value per present field; prefix each `Universe` with a varint byte-length |
| `segen` (Zig)               | consumer | `zig-protobuf`-generated, or hand-written decoder: per-message tag loop, dispatch on field number, **default = skip by wire type** (the extensibility path)       |
| `space_explorer_gui` (Node) | consumer | `protobufjs` `decodeDelimited` loop over the stream/file                                                                                                          |

### Schema draft (`proto/universe.proto`)

The message *shapes* (field numbers) are the stable protocol and live here; the
volatile *code→string* meanings live in the embedded `Dictionary`, so mods don't
touch this file. The structure is a **tree** (see
[Hierarchy](#hierarchy-the-tree-is-the-format)) — node type and parenthood are
expressed by *which message / which repeated field* a node sits in, so there is no
flat `type`/`in_calidus`/`index`. The stringy fields (`name`, `primary`, the seven
tags) are plain `uint32` codes resolved via the Dictionary — deliberately **not**
protobuf `enum`s, so adding a mod value needs no schema edit. **Mod-extension
fields use numbers 16+; existing numbers are never renumbered or reused.**

```proto
syntax = "proto3";
package seedsearch.v1;

// Emitted ONCE PER BUCKET (first length-delimited message of the bucket/stream).
// Makes the bucket self-describing: code → canonical string for every stringy
// field, shared by all ~1Mi universes. Adding a mod resource/tag/name = a new
// map entry here, nothing else. Resource code 0 = "inline string follows".
message Dictionary {
  string format         = 1;   // "seedsearch"
  uint32 schema_version = 2;   // message field-number schema revision
  string mod_set        = 3;   // "vanilla" | "k2" | ...
  map<uint32, string> zone_name   = 4;   // ~757 static names (bodies + fields + stars)
  map<uint32, string> resource    = 5;
  map<uint32, string> temperature = 6;
  map<uint32, string> water       = 7;
  map<uint32, string> moisture    = 8;
  map<uint32, string> trees       = 9;
  map<uint32, string> aux         = 10;
  map<uint32, string> cliff       = 11;
  map<uint32, string> enemy       = 12;
  // Level 2 (optional): full self-description incl. field NAMES.
  optional bytes file_descriptor_set = 15; // google.protobuf.FileDescriptorSet
}

// Shared payload for a surface body (planet / moon) or a deep-space field.
message Body {
  uint32  name = 1;                  // → Dictionary.zone_name (order dict: common < 128)
  fixed32 seed = 2;                  // high-entropy u32 → flat 4 bytes, not varint
  optional float  radius       = 3;  // f32 is sufficient (see Packing); unset for fields
  optional uint32 primary      = 4;  // → Dictionary.resource
  optional uint32 delta_v      = 5;
  optional uint32 temperature  = 6;  // → Dictionary.temperature
  optional uint32 water        = 7;
  optional uint32 moisture     = 8;
  optional uint32 trees        = 9;
  optional uint32 aux          = 10;
  optional uint32 cliff        = 11;
  optional uint32 enemy        = 12;
  // mod-specific per-body attributes: 16+
}

message Planet { Body body = 1; repeated Moon moons = 2; }
message Moon   { Body body = 1; }
message Field  { Body body = 1; }   // deep-space asteroid field (top level)

// Under a star. Name is INFERRED: "<star> Asteroid Belt <ordinal>" from list
// position — never stored. `primary` reserved for beryllium/methane belts.
message Belt {
  fixed32 seed = 1;
  optional uint32 primary = 2;   // → Dictionary.resource; usually unset
}

message Star {
  uint32  name = 1;                // → Dictionary.zone_name
  fixed32 seed = 2;
  double stellar_x = 3;            // for cross-system Δv when >1 star
  double stellar_y = 4;
  repeated Planet planets = 5;
  repeated Belt   belts   = 6;     // ordinal position drives the inferred name
}

message Universe {                 // ONE per seed (length-delimited record)
  fixed32 seed         = 1;   // high-entropy u32 → flat 4 bytes
  uint32 draws         = 2;
  bool   k2            = 3;
  string vault_loot    = 4;
  uint32 planets       = 5;   // npl  (= stars[Calidus].planets — kept for SQL sort)
  uint32 planets_moons = 6;   // npm
  uint32 n_water       = 7;   // nw
  uint32 n_enemy       = 8;   // ne
  uint32 water_pct     = 9;   // wp
  uint32 enemy_pct     = 10;  // ef
  uint32 naq_dv        = 11;  // naqdv (10_000_000 = none)
  uint32 field_dv      = 12;  // fdv
  sint32 enemy_value   = 13;  // ed (signed → sint = zig-zag)
  repeated Star  stars  = 14; // Calidus only by default; all ~31 for "all systems"
  repeated Field fields = 15; // deep-space asteroid fields (top level)
  // future universe/mod-level fields: 16+
}
```

### Framing

protobuf messages are not self-delimiting. Stream them **length-delimited**: each
message = `varint(byte_len)` then the encoded bytes. This is exactly protobufjs
`encodeDelimited`/`decodeDelimited`, and trivial on the Zig side.

A **bucket** is: **`Dictionary` first**, then one `Universe` per record. A reader
consumes the Dictionary once, builds the code→string maps, then decodes every
`Universe` and resolves codes through them. Each delimited `Universe` replaces one
JSONL line 1:1, so `METRICS_SCAN`/tail/expand paths keep their per-record
structure.

Where the bucket dictionary lives is the on-disk-layout decision (table row 2):
- **Bulk stream** (seedgen stdout → GUI import): emit the Dictionary as the first
  message of the run, then stream `Universe`s. It may never touch disk — used
  transiently to decode into SQLite.
- **On disk:** store one `output/<bucket>/dict.pb` per bucket; universe records
  either in a single `output/<bucket>/universes.pb` or per-seed
  `seed_<n>/universe.pb` that reference the bucket dictionary. Per-seed files are
  no longer self-contained — the **bucket** is the portable unit.

To read a `Universe` a consumer still needs the message *field-number* shapes —
those come from the checked-in `.proto` (or the Level-2 embedded descriptor). Only
the *code meanings* are self-described; the message layout is the fixed protocol.

### Packing & field sizing

**You don't pick packing or byte widths in protobuf — the wire type does.** This
reframes "use a smaller type for a small enum":

- **No sub-32-bit integer types exist.** There is no `uint8`/`uint16`. The
  integer-ish types (`int32`, `uint32`, `int64`, `uint64`, `bool`, `enum`) are all
  **varint** (wire type 0): 1 byte for values < 128, +1 byte per further 7 bits.
  So a 5-state tag and the ~757-entry name code **both cost 1 byte** until the
  value crosses 128 — declaring a "smaller" type would neither be legal nor save a
  byte. `enum` and our `uint32` codes are byte-identical on the wire (we picked
  codes for *extensibility*, not size).
- **Every present field also costs its tag.** On the wire a field is
  `varint(field_number<<3 | wire_type)` + value. Field numbers **1–15 → 1-byte
  tag**; 16+ → 2-byte tag. So a present small enum/code = **2 bytes** (1 tag +
  1 value). This is why the hot fields sit at 1–15.
- **Unset `optional` fields cost 0 bytes** — they're simply not emitted. The
  vanilla-vs-K2 sparsity (missing tags, missing `primary`) is free.

Per-body wire budget (a planet with all seven tags, idiomatic layout):

| field       | wire type       | bytes (tag + value)      |
| ----------- | --------------- | ------------------------ |
| `name` code | varint          | 1 + 1–2                  |
| `seed`      | **fixed32**     | 1 + 4                    |
| `radius`    | float (fixed32) | 1 + 4                    |
| `primary`   | varint          | 1 + 1                    |
| `delta_v`   | varint          | 1 + 1–3                  |
| 7 tags      | varint × 7      | 7 × (1 + 1) = 14         |
| **≈ total** |                 | **≈ 34 bytes** + framing |

The bytes concentrate in a few places, and the real levers are:

1. **`radius` — `float`, not `double`** (VERIFIED, saves 4 bytes → 5 total).
   Radius is consumed only as a continuous noise frequency (`5000/radius`) and an
   integer extent (`@intFromFloat`) in `se_main.zig`; it never seeds RNG or feeds
   a hash (RNG uses `zone_seed`), so f32's ~1e-7 error can't amplify. With the
   project's accepted ~95% biome bar (bit-exactness already skipped), the only
   edge is a body whose radius sits within ~0.0003 of an integer flipping the
   floored extent by ±1 tile (~0.03% of bodies) — inside tolerance. Revisit only
   if true bit-exact reproduction is ever pursued.
2. **`seed` — use `fixed32` (4 bytes), not varint.** Seeds are full-range,
   high-entropy u32s, so varint averages ~5 bytes and can hit 5–6; `fixed32` is a
   flat 4. Same for `Star.seed` / `Universe.seed`.
3. **Order the `zone_name` dictionary so common names get codes < 128** (the
   Calidus roster, since the default output is Calidus-only) → 1-byte name codes
   instead of 2.
4. **The 7 tags (14 bytes) are the only place sub-byte packing could help.** Each
   tag has ~5–7 states (3 bits); all seven fit in 21 bits → one `uint32` (~4 bytes
   incl. tag) instead of ~14. **But that bit-field is opaque** — it loses
   per-tag presence, per-tag skip-unknown, and self-description (the Dictionary
   would have to describe a bit *layout*, and adding an 8th tag repacks the field).
   Given extensibility/self-description are the whole point of this format,
   **recommended: keep the seven tags as separate fields and do NOT bit-pack.**
5. **gzip is the real size lever.** The stream is ~1Mi near-identical records; a
   generic gzip pass reclaims far more than field-level micro-packing (which
   fights the format's goals). Evaluate gzip (decision row 5) before hand-packing.

**Recommendation:** idiomatic protobuf — separate fields, hot fields at numbers
1–15, `fixed32` for seeds, `float` for radius, dictionary ordered so common name
codes are < 128 — and lean on gzip for bulk size rather than bit-packing tags.

---

## Alternatives considered

## Option A — Custom: core bitmask + TLV tail, over a static symbol dictionary

The idea that satisfies compactness **and** extensibility at once:

- **Known core fields → presence bitmask + packed values.** One `u16`/`u32`
  bitmask per zone marks which known fields are present; values follow in fixed
  order. No per-field key, no per-field tag — cheap.
- **Unknown / mod fields → a TLV tail.** After the core: a short list of
  `(field-id varint, wire-type nibble, value)`. New mods add field-ids here;
  **old readers skip by length and continue.** This is the extend-without-break
  guarantee.
- **Symbols from a versioned static dictionary**, not per-file. Types, tag
  values and the resource list are finite and known from mod data — bake them
  into a dictionary keyed by `(mod-set, dict-version)` named in the file header.
  `se-naquium-ore` → one varint; adding K2/another mod = a new dictionary
  version, not per-file overhead. Only free-form zone names use a small per-file
  intern table.

Byte-layout sketch:

```
File:  magic "SEB1" | u16 format_ver | u16 dict_id | u8 flags
       | [name-intern table: varint count, (varint len, bytes)* ]
       | world*  | EOF

World: varint seed | u16 mask | packed core (d,k,l,npl,npm,nw,ne,wp,ef,naqdv,fdv,ed)
       | varint nzones | zone*

Zone:  u16 core_mask | packed core (i, name_ref varint, type_id u8, seed u32, c bit
                                    [, r f64][, p resource_id varint][, dv varint])
       | u8 tag_mask  | (present tags, 1 byte enum each, in fixed order)
       | varint ext_count | (field_id varint, wire_type u4, value)*   ← mods here
```

Compat:
- **Old reader, new file:** unknown `dict_id` resource ids still resolve via the
  shipped dictionary (renderable as a raw name); unknown `field_id`s in the TLV
  tail are skipped by wire-type length.
- **New reader, old file:** absent bitmask bits / empty TLV → fields read as
  null.

**Pros:** smallest on disk, fastest parse, resource/enum interning.
**Cons:** hand-written encoder + two decoders (Zig producer, Zig + Node
consumers) to keep in sync. Most bespoke code.

## Option B — MessagePack / CBOR

Self-describing binary JSON. Same data model as today (maps with short keys),
just binary.

**Pros:** extensible for free (it's JSON); Node has fast libs; Zig needs only a
small codec. Far less bespoke code; skip-unknown is inherent.
**Cons:** ~1.5–2× larger than Option A — repeats the short map keys on every zone
and does no value interning (every `se-naquium-ore` written in full unless we add
a str-table layer on top).

## Option C — Versioned fixed struct + presence bitmask

A fixed schema per format version; a bitmask marks present optional fields; a
version number selects the layout.

**Pros:** simplest and fastest to read (near-`memcpy`). Compact.
**Cons:** **no skip-unknown escape hatch** — a new mod field means a new format
version that *every* reader must learn before it can read the file at all. Only
acceptable if the schema is essentially frozen. Fails the stated requirement.

---

## Rollout scope options

- **Everywhere, env-gated (recommended):** `seedgen` emits binary under e.g.
  `SEB_OUT=1`; GUI + surface-gen read both; migrate disk artifacts + pipe over
  time; JSON stays for debugging during transition.
- **On-disk bulk only:** binary for big streams / bulk import; keep JSON for the
  single-seed expand + GUI ad-hoc paths (tiny volume, human-readable helps).
- **Hard replace now:** rip JSONL out entirely. Cleanest end state, no fallback,
  one bigger cutover across all three codebases.

---

## Cross-cutting considerations

- **Endianness:** fix little-endian (all target platforms are LE; avoids a flag).
- **Varints:** LEB128 unsigned for counts/ids/most metrics; zig-zag for signed
  `ed`. `seed` as varint (fits u32 today, room to grow).
- **f64 radius:** store raw 8 bytes (bit-exact) — rounding shifts every
  temperature/moisture boundary (see `main.zig` radius comment).
- **GUI re-expand source:** today the raw JSONL line is stored in the seeds
  table. With binary, either store the record bytes as a BLOB or keep a JSON
  projection in the DB while the wire/disk format is binary.
- **Self-framing:** each world record should be length-prefixed (or the file
  section-indexed) so surface-gen can seek to one seed without decoding all.
- **Dictionary shipping:** the `(mod-set, dict-version)` dictionaries live in the
  repo (generated from the same mod data the generator uses) so all three codecs
  agree. Bump dict-version when a mod adds symbols; never renumber existing ids.

---

## Decisions

Record each decision here as it's made (date + who + rationale).

| #   | Decision                                                                      | Choice                                                                                                                            | Date       | Rationale                                                                                                                                                                                                                                            |
| --- | ----------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Encoding style                                                                | **Protocol Buffers (proto3)**                                                                                                     | 2026-07-31 | Schema-as-code, language-neutral `.proto` decoupled from front/back end; field numbers give skip-unknown extensibility natively                                                                                                                      |
| 1a  | Framing                                                                       | **Length-delimited stream** (varint len + message)                                                                                | 2026-07-31 | 1:1 replacement for a JSONL line; protobufjs `*Delimited` on Node, trivial on Zig                                                                                                                                                                    |
| 1b  | Zig codec                                                                     | **`Arwalk/zig-protobuf` if it supports Zig 0.16, else hand-written**                                                              | 2026-07-31 | User flagged the lib. Gen from `.proto` is nicer than hand-maintaining; only risk is the 0.16 pin (open item below). Tree is small either way                                                                                                        |
| 1c  | Structure                                                                     | **Hierarchical (nested tree)**: Universe→Star→Planet→Moon, Star→Belt, top-level Field                                             | 2026-07-31 | Tree already computed by the generator; nesting drops flat `type`/`in_calidus`/`index`, makes include/exclude of a system a subtree op, and directly enables the "all star systems" feature                                                          |
| 1d  | Belt names                                                                    | **Inferred** `"<star> Asteroid Belt <ordinal>"` from list position — not stored                                                   | 2026-07-31 | Belts kept (user), but the name is derivable; orbits dropped entirely (never serialized)                                                                                                                                                             |
| 1e  | Resources / tags / **zone name**                                              | **`uint32` codes resolved via the Dictionary** (not protobuf enums, not inline strings)                                           | 2026-07-31 | Self-describing (code→string in the dict); name roster is a static ~757-entry set; adding a mod value = new dict entry, zero `.proto` edit                                                                                                           |
| 1f  | Self-description level                                                        | **Level 1** (embed code→string Dictionary)                                                                                        | 2026-07-31 | Values decodable without the `.proto`; field names still from the checked-in schema. Level 2 (embed FileDescriptorSet) available if needed                                                                                                           |
| 1g  | **Dictionary scope**                                                          | **Per bucket** (one dict shared by ~1Mi universes)                                                                               | 2026-07-31 | Same names across all universes in a bucket → write once, amortise to ~nothing                                                                                                                                                                       |
| 2   | On-disk layout                                                                | _tbd_ (single `universes.pb` per bucket, vs per-seed `universe.pb` + shared `dict.pb`)                                            |            | bucket is the portable/self-contained unit either way                                                                                                                                                                                                |
| 3   | Re-expand source in DB: BLOB vs JSON projection                               | _tbd_                                                                                                                             |            |                                                                                                                                                                                                                                                      |
| 4   | Code assignment: stable per (mod_set, version) from `data.zig`, vs per-bucket | _tbd_ (leaning stable)                                                                                                            |            |                                                                                                                                                                                                                                                      |
| 5   | gzip the stream?                                                              | _tbd_ (only if size still bites after codes)                                                                                      |            |                                                                                                                                                                                                                                                      |
| 6   | Store belt zones at all, or drop them?                                        | _tbd_ — **store** (user: "good to store/generate")                                                                                | 2026-07-31 | Belts kept as `Star.belts`; cheap (seed + optional primary), names inferred                                                                                                                                                                          |
| 7   | Field sizing / packing                                                        | **Idiomatic** — varint codes, hot fields #1–15, `fixed32` seeds, `double` radius, common name codes < 128; **no tag bit-packing** | 2026-07-31 | Protobuf has no sub-32-bit types or manual packing; varint already minimises small values. Bit-packing the 7 tags saves ~10 B/body but is opaque and kills per-tag self-description/skip-unknown; gzip (row 5) is the real size lever                |
| 8   | Radius precision                                                              | **`float` (f32)** — not `double`                                                                                                  | 2026-07-31 | Verified: radius feeds only continuous freq (`5000/radius`) + integer extent (`@intFromFloat`), never RNG/hash; f32's ~1e-7 error is under the accepted ~95% biome bar. Saves 4 B/body. Revert to `double` only if bit-exact reproduction is pursued |

## Open questions

- ~~**(load-bearing) Is the zone-name roster fully stable across seeds?**~~
  **RESOLVED (2026-07-31):** yes for every resource-bearing zone — all planet/
  moon/asteroid-field names come from fixed `data.zig` tables (~757 distinct; see
  the inventory). The only procedural names are `<Star> Orbit` (never serialized)
  and `<Star> Asteroid Belt <N>` (serialized, no resource). So the dictionary is a
  static per-mod-set list, and the code-0 escape is needed only for belt names.
  **Open sub-question:** keep the belt escape, drop belt zones from the output
  entirely (they carry nothing the consumers use), or code belts structurally?
- Do we need random-access-by-seed on disk, or is sequential scan enough for
  every consumer? (Affects the on-disk layout — a single `worlds.pb` per bucket
  would want a seed→offset index for the surface-gen single-seed read.)
- Should the metrics header (`npl…ed`) stay in the binary, or move fully into the
  SQLite import and out of the on-disk record?
