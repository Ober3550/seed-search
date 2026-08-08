# Filter DSL (design)

Status: **design proposal** — nothing implemented yet. Captures the design
discussion for unifying the two seed-filtering mechanisms behind one declarative
filter format.

## Motivation: two filters, one job

The tool currently has two distinct seed-filtering mechanisms. They *feel*
duplicative but operate at different points in the pipeline on different
representations of the world, with different rule vocabularies:

### 1. Extremity tails — Zig, streaming pre-filter

Runs **inside `seedgen` (Zig)** during rough universe generation. For each seed
it computes whole-system metrics (`naqdv`, `fdv`, `np`, `nw`, `ne`, `wp`, `ef`)
and keeps the seed only if a metric lands at an extreme.

- **Rule shape:** numeric range cutoffs with UNION semantics — keep if `metric ≤ lo`
  *or* `metric ≥ hi`; each side independently optional (`0 = off`).
- **Granularity:** whole-seed pass/fail. No notion of *which* bodies qualify.
- **Output:** a `seeds.jsonl` stream of survivors.
- **Today it's hardcoded** as env vars (`NAQ_DV_LOW/HIGH`, `PLANETS_LOW/HIGH`,
  `WATER_PCT_LOW/HIGH`, `ENEMY_PCT_LOW/HIGH`, with `MIN_NAQ_DV` back-compat
  alias for `NAQ_DV_LOW`).

### 2. Filter presets — JS, curated refinement

Runs in **JavaScript (`createFilteredSet` + `analyze.matchFilter`)**, on
world lines already stored per seed in the DB. Operates on the **per-body
resource composition** (`crit.bodies`, each with `present`, `primary`,
`enemy`, `water`, `radius`; plus the naq-primary field).

- **Rule shape:** conjunctive list of body constraints — `{ primary, res: [...],
  enemyMax, waterMin, radiusMin }`, with **distinct-body allocation** (N rules
  require N separate bodies).
- **Granularity:** seed pass/fail **and** which zones survive (feeds surface
  generation).
- **Output:** a named filtered `.jsonl` (**output/<bucket>/<name>.jsonl**) with
  only the matched bodies kept; stored in `filter_defs` / `filter_members`.

### The difference in one table

| capability      | Extremity tails (Zig)         | Filter presets (JS)           |
|-----------------|-------------------------------|-------------------------------|
| granularity     | whole-seed global metrics     | per-body composition          |
| boolean         | union (≤ lo OR ≥ hi), per rule| conjunction (AND across rules)|
| output          | seed pass/fail                | matched seeds **+ kept zones**|
| data available  | computed in the stream        | stored world `crit` per seed  |

## Goal: one DSL, two evaluators

Express seed-filter intent **once**, in a shared JSON format, and evaluate it in
both stages:

- **Zig (seedgen):** parse at startup, stream-pre-filter with the cheap whole-seed
  predicates.
- **JS (refinement):** reuse `matchFilter` for the body predicates and add the
  numeric-metric predicates.

The honest limits:

1. **Union vs conjunction.** Tails union within a metric (`≤ lo OR ≥ hi`);
   presets AND across bodies. A shared spec must express both.
2. **Zig lacks per-body presence** for arbitrary bodies during the stream. It
   computes whole-seed metrics but only builds per-body presence partially. So
   body-level rules are naturally a *refine*-stage concern unless we teach
   seedgen to compute them.

## Boolean composition

The boolean layer composes predicates with three operators:

- **`&&`** — every child must match.
- **`||`** — any child must match.
- **`!`** — inverts a single child.

Empty lists have fixed identities: `&&` of **no** filters is **true** (vacuous
conjunction), `||` of **no** filters is **false** (vacuous disjunction).

### Filter kinds and composition typing

There are **three kinds of filter**, distinguished by what they operate on:

- **`seed`-filter** — a boolean over a whole seed / its world. Includes the
  `$count`/`$fraction` value-functions with their `is` pass-condition, and any
  boolean over them. A top-level filter is always a `seed`-filter.
- **`surface`-filter** — a boolean over a single surface (the body/surface
  vocabulary: `type`, `starSystem`, `water`, `enemy`, `cliff`, `radius`, `deltaV`, and the
  numeric FSR score for each resource, ...).
- **`value`-filter** — a boolean over a single scalar value: the `is`
  grammar (`>=`/`<=`/`==`/`>`/`<`).

**Naming convention:** a key that does **not** start with `[a-zA-Z]` is an operator
(`&&`, `||`, `!`, `>=`, `<=`, `==`, `>`, `<`, `$count`, `$fraction`); a key that
**does** start with a letter is a surface-property filter (`type`, `starSystem`,
`water`, `enemy`, `cliff`, `radius`, `deltaV`, or a resource's FSR score such as
`iron`).

`&&`/`||`/`!` operate over **filters of the same kind only** — it is illegal
to mix kinds inside one boolean node. The output of a boolean over `<X>`-filters
is again an `<X>`-filter, so:

```jsonc
{ "||":  [ <seed-filter>,    <seed-filter>,    ... ] }   // -> seed-filter
{ "||":  [ <surface-filter>, <surface-filter>, ... ] }   // -> surface-filter
{ "||":  [ <value-filter>,   <value-filter>,   ... ] }   // -> value-filter
```

Mixing kinds (e.g. a `seed`-filter with a `surface`-filter in one `||`) is a
**schema error**.

### Composition

A bare surface field (`naq_dv`, `water`, `enemy`, `cliff`, `radius`, ...) is a
scalar read from the seed's metrics (numeric or ordered-enum). To match it, put
a `value`-filter directly on the property, e.g. `{ "water": { "==": "high" } }`
tests that the seed's `water` value equals `high`.

`$count`/`$fraction` lift a `surface`-set into a scalar aggregate and carry their
own pass-condition via `is` (itself a `value`-filter) — they are self-contained
`seed`-filters, no separate `constraint` wrapper is needed ("at least one
surface" is `{ "$count": { "of": <surface-filter>, "is": { ">=": 1 } } }`). So a
`seed`-level `||` may still contain `$count`/`$fraction` branches whose `is` is
itself a `value`-level `||` — the kinds stay homogeneous at each level.

Predicates compose freely. The canonical range example:

```jsonc
// 1000 ≤ radius ≤ 2000  (single object, implicit AND on distinct fields)
{ "radius": { ">=": 1000, "<=": 2000 } }

// negation: radius ≤ 1000  ∨  2000 ≤ radius  (or of two bounds)
{ "||": [ { "radius": { "<=": 1000 } },
          { "radius": { ">=": 2000 } } ] }

// just radius ≤ 2000
{ "radius": { "<=": 2000 } }

// just 1000 ≤ radius
{ "radius": { ">=": 1000 } }
```

Composition is freely nestable. `&&` earns its keep when several
constraints must combine onto the *same* field, where JSON forbids duplicate
keys in one object:

```jsonc
// same field, multiple bounds -> collate into one object (preferred)
{ "radius": { ">=": 1000, "<=": 2000 } }

// equivalent, but verbose (the duplicate-key workaround)
{ "&&": [ { "radius": { ">=": 1000 } },
           { "radius": { "<=": 2000 } } ] }
```

Preference: use the collated object form for ranges, and reserve `&&`/`||`/
`!` for higher-level composition.

## Design decisions

The DSL's operator set and conventions:

- **Boolean composition** uses **`&&`**, **`||`**, **`!`**; numeric fields
  use **`>=`**, **`<=`** (plus strict **`>`**, **`<`**); exact equality uses **`==`**.
- **Ordered enums on `>=`/`<=`** (below).

The DSL is evaluated only by our own matching code in seedgen (Zig) and the
refinement stage (JS) — there are no third-party validators. Both evaluators
must implement the DSL identically.

### Ordered enums on `>=`/`<=`

`water`, `enemy`, and `cliff` are **ordered enums** — they take a small set of string
labels in a fixed increasing order, and `>=`/`<=` act as range checks over
that order. They are **string-valued**: `>=`/`<=` on these fields means a
range over the tier order, comparing by ordinal position.

**Allowed values** (defined in `verifier/analyze.js` as `WATER_LEVELS` /
`ENEMY_LEVELS`; the ordinal is the array index):

- **`water`** — 5 tiers, `none < low < med < high < max`:
  `"none"`, `"low"`, `"med"`, `"high"`, `"max"`
- **`enemy`** — 7 tiers, `none < very_low < low < med < high < very_high < max`:
  `"none"`, `"very_low"`, `"low"`, `"med"`, `"high"`, `"very_high"`, `"max"`
- **`cliff`** — 5 tiers, `none < low < med < high < max`:
  `"none"`, `"low"`, `"med"`, `"high"`, `"max"`

So `{ "water": { ">=": "med" } }` means water tier ≥ `med`; `{ "enemy":
{ "<=": "low" } }` means enemy tier ≤ `low`. Exact equality uses the `==` operator:
`{ "water": { "==": "high" } }` is exact equality to tier `high`.

This is a deliberate part of the DSL: `>=`/`<=` are **ordered range checks**, and on an ordered-enum field they compare the string by its ordinal position rather than as a number. Our own Zig/JS evaluators implement this identically.

### `$count` / `$fraction`: self-contained aggregates

`$count` and `$fraction` are **`seed`-filters** (they decide, per seed, whether to
keep it) that aggregate over the seed's surfaces and test the aggregate against
an **`is`** value-filter. Both take an **`of`** key naming the surfaces to measure; `$fraction`
additionally takes a **`matching`** key. Each of `of`/`matching` takes a
**surface-filter** — an object of surface-property filters such as `type`,
`water`, `enemy`, `cliff`, `radius`, `starSystem`, `deltaV`, or a resource's
numeric FSR score. To combine multiple surface-property filters, use an
explicit **`&&`** array: every surface property filter is a separate element. Because they are `seed`-filters, their `of`/`matching`
operands are `surface`-filters only (per the composition-typing rule, a boolean
node cannot mix kinds) — so `$count`/`$fraction` never nest inside each other.

- **`$count`** — `{ "$count": { "of": <surface-predicate>, "is": <value-filter> } }` computes the **count**
  of surfaces in the `of`-set (an integer ≥ 0) and keeps the seed if it passes
  `is`. This is what the current P+M (planets+moons count) rough filter needs.
- **`$fraction`** — `{ "$fraction": { "of": <surface-predicate>, "matching":
  <surface-predicate>, "is": <value-filter> } }` computes the **ratio** of surfaces in the `of`-set
  that also pass `matching` (numerator = |`of` ∧ `matching`|, denominator =
  |`of`|) and keeps the seed if it passes `is`. This is the current `water%` /
  `hostile%` tails. If the denominator
  is **0** (empty `of`-set), `$fraction` returns **NaN** — it must not return 0,
  which would wrongly read as "no passing surfaces."

Because `of` accepts any surface predicate, it is a full set selector — e.g.
`{ "of": { "&&": [ { "starSystem": { "==": "Calidus" } }, { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } } ] } }` selects
Calidus planets+moons as the denominator. `matching` then narrows within that
set; the two predicates overlap, which is exactly the intent.

Resources are always present: seedgen emits **all 18** resources on every
surface, with **0.0** for any resource the surface lacks (they are never
omitted). Presence of a resource is therefore tested with `{ ">": 0.0 }`.

Used concretely to replicate the current tail filters:

```jsonc
// count of Calidus surfaces (planets+moons), in range [12, 30]  — the P+M rough filter
{ "$count": { "of": { "&&": [ { "starSystem": { "==": "Calidus" } }, { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } } ] },
             "is": { ">=": 12, "<=": 30 } } }

// fraction of Calidus surfaces with water ≥ low, in range [0.40, 0.95]
{ "$fraction": { "of": { "&&": [ { "starSystem": { "==": "Calidus" } }, { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } } ] },
                "matching": { "water": { ">=": "low" } },
                "is": { ">=": 0.40, "<=": 0.95 } } }

// fraction of Calidus surfaces that are planets  (of is a full set selector)
{ "$fraction": { "of": { "&&": [ { "starSystem": { "==": "Calidus" } }, { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } } ] },
                "matching": { "type": { "==": "planet" } },
                "is": { ">=": 0.2, "<=": 0.8 } } }
```

> `$count` with an empty `of` (`{ "$count": { "of": {} } }`) counts **all**
> surfaces — a convenient way to express a bare count filter, since the empty
> set matches every surface. (An `of` of `{}` with an `is` is the self-contained
> form; there is no separate `constraint`.)

#### `type` filter (surface kinds)

`type` is a **surface-level** filter selecting the *kind* of surface. A value of
`"surface"` is the default and effectively a no-op (matches every surface).
The other values are:

- `"planet"` — a planet
- `"moon"` — a moon
- `"star"` — a star (likely unused in practice, kept for completeness)
- `"asteroidField"` — an asteroid field

`type` is a scalar string; to match any of several kinds, express the disjunction as a `||` of `==` tests. In
particular `{ "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } }` implements the conventional
"body" constraint (any planet or moon, excluding fields and stars):

```jsonc
{ "$count": { "of": { "&&": [ { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } }, { "water": { ">=": "high" } } ] },
             "is": { ">=": 1 } } }
```

#### `deltaV` (surface property)

`deltaV` is a **numeric** surface property: the travel Δv to that surface, in
km. It can be used anywhere a numeric field can (`>=`/`<=`/`==`/`>`/`<`):

```jsonc
// a surface within 1000 km (e.g. a nearby asteroid field)
{ "$count": { "of": { "&&": [ { "type": { "==": "asteroidField" } }, { "deltaV": { "<=": 1000 } } ] },
             "is": { ">=": 1 } } }
```

**Reference point.** The current implementation measures `deltaV` **relative to
Nauvis** — seedgen's `deltaVFromNauvis()` mirrors SE's
`Zone.get_travel_delta_v(Nauvis, z)`. So `deltaV` is the cost to reach the
surface from the starting world, not from the system barycentre or the
home-system star.

#### `starSystem` (surface property)

`starSystem` is a **string-valued** surface property selecting the star system the
surface belongs to. Semantically it can name any system; in practice `"Calidus"`
is the only value the game/this tool ever produces, so it is the only one
used:

```jsonc
// a surface belonging to the Calidus system
{ "$count": { "of": { "&&": [ { "starSystem": { "==": "Calidus" } }, { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } } ] },
             "is": { ">=": 1 } } }
```

`starSystem` replaces the earlier boolean `inCalidusSystem` — expressed as a
string selector it is uniform with the rest of the surface vocabulary, and
future systems (if any) slot in without a schema change.

#### Tails via `! { count / fraction ... }`

Because `$count`/`$fraction` carry their `is` pass-condition, negating a *whole*
`$count`/`$fraction` gives the Extremity-tails idiom for free. `!` is a single,
uniform operator: it inverts the boolean result of any predicate node it wraps
(`$count`, `$fraction`, `&&`, `||`, ...). Inverting a `$fraction` whose `is` was a
bounded interval yields the union of the two tails:

```jsonc
// seeds where the Calidus water-body fraction is in the tails: < 0.40 or > 0.95
{ "!": { "$fraction": { "of": { "&&": [ { "starSystem": { "==": "Calidus" } }, { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } } ] },
                         "matching": { "water": { ">=": "low" } },
                         "is": { ">=": 0.40, "<=": 0.95 } } } }
```

### Sketch

Expressing the **default rough filter** (the Extremity-tails defaults from the
GUI: naq 17500/37200, P+M 16/46, water 40/95%, hostile 42/88%) with the DSL.
The top level is `||` (union — keep a seed if **any** tail matches). Note the
naq filter is expressed as a `$count` over asteroid fields (naq-primary within
17500 km, or any field beyond 37200 km), and the P+M count versus the
water/hostile percentages use `$count` vs `$fraction` respectively:

```jsonc
{
  "||": [
    // nearest naquium-PRIMARY asteroid field within 17500 km  (rich naq)
    { "$count": { "of": { "&&": [ { "type": { "==": "asteroidField" } }, { "naquium": { ">": 0.0 } }, { "deltaV": { "<=": 17500 } } ] },
                 "is": { ">=": 1 } } },
    // nearest ANY asteroid field beyond 37200 km    (long haul)
    { "$count": { "of": { "&&": [ { "type": { "==": "asteroidField" } }, { "deltaV": { ">=": 37200 } } ] },
                 "is": { ">=": 1 } } },

    // fewest Calidus planets+moons (≤ 16)
    { "$count": { "of": { "&&": [ { "starSystem": { "==": "Calidus" } }, { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } } ] },
                 "is": { "<=": 16 } } },
    // most Calidus planets+moons (≥ 46)
    { "$count": { "of": { "&&": [ { "starSystem": { "==": "Calidus" } }, { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } } ] },
                 "is": { ">=": 46 } } },

    // parched: ≤ 40% of Calidus surfaces have water
    { "$fraction": { "of": { "&&": [ { "starSystem": { "==": "Calidus" } }, { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } } ] },
                    "matching": { "water": { ">=": "low" } },
                    "is": { "<=": 40 } } },
    // wet: ≥ 95% of Calidus surfaces have water
    { "$fraction": { "of": { "&&": [ { "starSystem": { "==": "Calidus" } }, { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } } ] },
                    "matching": { "water": { ">=": "low" } },
                    "is": { ">=": 95 } } },

    // quiet: ≤ 42% of Calidus surfaces hostile
    { "$fraction": { "of": { "&&": [ { "starSystem": { "==": "Calidus" } }, { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } } ] },
                    "matching": { "enemy": { ">=": "very_low" } },
                    "is": { "<=": 42 } } },
    // warzone: ≥ 88% of Calidus surfaces hostile
    { "$fraction": { "of": { "&&": [ { "starSystem": { "==": "Calidus" } }, { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } } ] },
                    "matching": { "enemy": { ">=": "very_low" } },
                    "is": { ">=": 88 } } }
  ]
}
```

> Note on the percentage denominators: seedgen measures `wp`/`ef` over **tagged
> Calidus bodies** = Calidus planets+moons **excluding Nauvis** (Nauvis carries no
> universe tags). The `$fraction` above uses `of` = Calidus planets+moons, so the
> denominator includes Nauvis; since Nauvis never matches the `matching`
> predicate (has-water / is-hostile), the intended ratio is approximated. If
> exact parity with seedgen's `body_cnt` is needed, the denominator set must
> exclude Nauvis (a future refinement).

For a resource-composition (filter-preset) example, `count { of: <surface-filter>, is: { ">=": 1 } }` composes under the
same boolean layer:

```jsonc
{ "$count": { "of": { "&&": [ { "vulcanite": { ">": 0.0 } }, { "enemy": { "<=": "low" } }, { "water": { ">=": "med" } }, { "radius": { ">=": 1000 } } ] },
             "is": { ">=": 1 } } }
```

## Open questions / next steps

- Teach seedgen (Zig) to parse the DSL once at startup via **`std.json`** (ships
  in the Zig stdlib — **no new dependency**, seedgen is a single-file
  `build-exe` today, and importing `std.json` requires no build-system change).
  The `range`/numeric predicates map onto metrics already in the hot loop; the
  `body` predicates need per-body presence seedgen only partially builds.
- Watch the **mode** split: rough vs refine. The streaming pre-filter should
  only pay for the predicates that can short-circuit cheaply; body curation
  stays a refine-stage concern.
- Confirm the ordered-enum **ranking** (the `WATER_LEVELS` / `ENEMY_LEVELS`
  tier → index mapping) and whether the instance carries the rank or the label.
