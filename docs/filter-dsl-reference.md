# Filter DSL — operators reference

Reference for the Filter DSL. See `docs/filter-dsl.md` for the design rationale.
This is the canonical list of valid operators, their grammar, and the filter
kinds they belong to.

## Filter kinds

There are three kinds of filter; `&&`/`||`/`!` operate only over filters of
the **same kind** (mixing kinds is a schema error), and their output is the
same kind as their inputs.

| kind            | operates on                                 | examples                                        |
|-----------------|---------------------------------------------|-------------------------------------------------|
| `seed`-filter   | a whole seed / its world                    | metric `$count`/`$fraction` with an `is` filter, top-level filter |
| `surface`-filter| a single surface                            | `type`, `starSystem`, `water`, `enemy`, `radius`, `deltaV`, and each resource's FSR score |
| `value`-filter  | a single scalar value                       | the `is` grammar (`>=`/`<=`/`==`/`>`/`<`) |

**Naming convention / parser dispatch:** the evaluator dispatches purely on the
**first character** of each object key — no operator list to maintain. A key
that does **not** start with `[a-zA-Z]` is an operator (`&&`, `||`, `!`, `>=`,
`<=`, `==`, `>`, `<`, `$count`, `$fraction`). A key that **does** start with a
letter is a surface-property filter (`type`, `starSystem`, `water`, `enemy`,
`cliff`, `radius`, `deltaV`, or a resource's FSR score such as `iron`). An
unknown non-letter key is an error; an unknown letter key is an error unless it
names a known surface property or resource.


## Boolean operators

| operator | kind     | grammar                           | semantics                    |
|----------|----------|-----------------------------------|------------------------------|
| `&&`    | any      | `{ "&&": [<X-filter>, …] }`      | every child must match (∅ → true) |
| `||`     | any      | `{ "||":  [<X-filter>, …] }`      | any child must match (∅ → false) |
| `!`    | any      | `{ "!": <X-filter> }`           | inverts a single child       |


## value-filters

| operator | grammar                                  | semantics                     |
|----------|------------------------------------------|-------------------------------|
| `>=`     | `{ ">=": <num-or-orderen> }`             | value ≥ bound (numeric, or ordered-enum tier) |
| `<=`     | `{ "<=": <num-or-orderen> }`             | value ≤ bound (numeric, or ordered-enum tier) |
| `==`     | `{ "==": <value> }`                      | exactly equal                 |
| `>`      | `{ ">": <num-or-orderen> }`              | value > bound (numeric, or ordered-enum tier) |
| `<`      | `{ "<": <num-or-orderen> }`              | value < bound (numeric, or ordered-enum tier) |

`>=`/`<=` (and the strict `>`/`<`) act as **ordered range checks** on compact
enum fields (`water`, `enemy`), comparing the string by ordinal position.

## Value-functions

`$count` and `$fraction` no longer need a separate `constraint`/`matches`: they
are self-contained `seed`-filters that carry their own pass-condition via the
`is` key, a `value`-filter.

| operator | grammar                                     | matches when                 |
|----------|---------------------------------------------|------------------------------|
| `$count`  | `{ "$count": { "of": <surface-filter>, "is": <value-filter> } }` | the integer count ≥ 0 of surfaces in `of` passes `is` |
| `$fraction`| `{ "$fraction": { "of": <surface-filter>, "matching": <surface-filter>, "is": <value-filter> } }` | the ratio in [0,1] = \|`of` ∧ `matching`\| ÷ \|`of`\| passes `is`; **fails (no match)** when \|`of`\| = 0 |

- `of`/`matching` take a **surface-filter** — an object of surface-property
  predicates. To combine multiple surface-property filters, use an explicit
  **`&&`** array: every surface property filter is a separate element.
  `$fraction`'s `matching` narrows within the `of`-set the same way.
- `$count` with `of: {}` counts **all** surfaces.
- `$count`/`$fraction` are **`seed`-filters**, so their `of`/`matching` operands
  are `surface`-filters only (per the composition-typing rule, a boolean node
  cannot mix kinds) — `$count`/`$fraction` never nest inside each other.

## Surface properties / filters

| property   | type          | values / semantics                                  |
|------------|---------------|-----------------------------------------------------|
| `type`     | string          | `"surface"` (default, no-op), `"planet"`, `"moon"`, `"star"`, `"asteroidField"`; multiple kinds are expressed with `||` of `==` tests |
| `starSystem` | string        | star system the surface belongs to; `"Calidus"` is the only value produced in practice |
| `deltaV`   | number        | travel Δv to the surface in km, measured relative to **Nauvis** |
| `water`    | ordered enum  | `none < low < med < high < max`                     |
| `enemy`    | ordered enum  | `none < very_low < low < med < high < very_high < max` |
| `cliff`    | ordered enum  | `none < low < med < high < max`                     |
| `radius`   | number        | surface radius                                      |
| `<resource>` | number      | normalized FSR score for that resource on the surface (freq×size×richness / norm); primary is the max (≈1.0 on planets, ≈1.024 on asteroid fields). All 18 resources are always present; a resource absent from a surface has FSR score **0.0**. |

**`primary` is derived, not a stored flag:** the surface's primary resource is
the one whose FSR score is the maximum in its `<resource>` map. On planets that
max is ≈1.0; on asteroid fields it is ≈1.024. A predicate like
`{ "$count": { "of": { "vulcanite": { ">=": 0.5 } }, "is": { ">=": 1 } } }` selects a seed with a surface rich in
vulcanite; `res`-style "is present" is `<resource>` with `{ ">": 0.0 }`.

> The FSR scores are emitted by seedgen as the `"rs"` map on each surface zone
> line, keyed by resource name. All 18 resources are always present on every
> surface — a missing resource is written as **0.0**, not omitted, so presence
> is tested with `> 0.0`. Filtering on a resource uses these values directly;
> there is no separate `res` array or
> `primary` boolean in the DSL surface vocabulary.

Note: `{ "$count": { "of": { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } }, "is": { ">=": 1 } } }` is the conventional "body"
constraint (any planet or moon, excluding fields and stars).

## Top-level shape

A filter is a single `seed`-filter — typically a `$count`/`$fraction`, or a
boolean (`&&`/`||`/`!`) over them. Example (default rough filter, union of
tails):

```jsonc
{
  "||": [
    // nearest naquium-PRIMARY asteroid field within 17500 km  (rich naq)
    {
      "$count": {
        "of": {
          "&&": [
            { "type": { "==": "asteroidField" } },
            { "naquium": { ">": 0.0 } },
            { "deltaV": { "<=": 17500 } }
          ]
        },
        "is": { ">=": 1 }
      }
    },
    // nearest ANY asteroid field beyond 37200 km  (long haul)
    {
      "$count": {
        "of": {
          "&&": [
            { "type": { "==": "asteroidField" } },
            { "deltaV": { ">=": 37200 } }
          ]
        },
        "is": { ">=": 1 }
      }
    },
    // fewest OR most Calidus planets+moons  (P+M: <= 16 or >= 46)
    {
      "$count": {
        "of": {
          "&&": [
            { "starSystem": { "==": "Calidus" } },
            { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } }
          ]
        },
        "is": { "||": [ { "<=": 16 }, { ">=": 46 } ] }
      }
    },
    // parched OR wet Calidus water share  (<= 40% or >= 95%)
    {
      "$fraction": {
        "of": {
          "&&": [
            { "starSystem": { "==": "Calidus" } },
            { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } }
          ]
        },
        "matching": { "water": { ">=": "low" } },
        "is": { "||": [ { "<=": 40 }, { ">=": 95 } ] }
      }
    },
    // quiet OR warzone Calidus hostile share  (<= 42% or >= 88%)
    {
      "$fraction": {
        "of": {
          "&&": [
            { "starSystem": { "==": "Calidus" } },
            { "type": { "||": [ { "==": "planet" }, { "==": "moon" } ] } }
          ]
        },
        "matching": { "enemy": { ">=": "very_low" } },
        "is": { "||": [ { "<=": 42 }, { ">=": 88 } ] }
      }
    }
  ]
}
```
