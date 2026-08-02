# Seed score: original (hierarchical) vs current (weighted sum)

Both scores are pure functions of the stored per-seed metrics — no population
pass — so a row's score is stable and computable at insert. What changed is the
**aggregation philosophy**: the original was *lexicographic* (planets strictly
dominate; other metrics only break ties), the current is *compensatory* (a plain
weighted sum where any metric can trade against any other).

This doc states both mathematically and shows where they rank seeds differently —
so we can decide which properties to keep.

Notation shared by both:

$$\operatorname{oddPow}(v,p)=\operatorname{sign}(v)\left|\tfrac{v}{100}\right|^{p}\cdot 100,\qquad p=3$$

$$\operatorname{comp}(v;lo,hi,\uparrow)=\operatorname{oddPow}\big(g\cdot 200-100,\;p\big),\quad
g=\begin{cases}t & \uparrow\text{ (higher better)}\\ 1-t & \downarrow\text{ (lower better)}\end{cases},\quad
t=\operatorname{clamp}\!\Big(\tfrac{v-lo}{hi-lo},0,1\Big)$$

`comp` maps a metric to a **signed** value in $[-100,100]$: `lo`→ worst end,
`hi`→ best end, linear between, with the odd power flattening the middle and
steepening the ends. `oddPow` keeps the sign and stays in range.

---

## Original — hierarchical / banded (git `a32af0f`)

Output is an integer in **0..100**. Planet count owns the top tier; everything
else only moves *within* a planet's band.

**Planet tier (dominant).** With `npl` ∈ 6..14 → 9 levels:

$$\ell=\operatorname{clamp}(npl-6,\;0,\;8)\in\{0,1,\dots,8\}$$

**Within-band tiebreakers.** A weighted mean of three components, each remapped
from $[-100,100]$ to $[0,1]$, with weights $w$ = (naq 0.30, hostile 0.20, water 0.10):

$$o=\operatorname{clamp}\!\left(\frac{\sum_i w_i\cdot \tfrac{c_i+100}{200}}{\sum_i w_i},\;0,\;0.999999\right)\in[0,1)$$

with $c_{\text{host}}=\operatorname{comp}(ef;52,84,\downarrow)$,
$c_{\text{water}}=\operatorname{comp}(wp;50,88,\uparrow)$, and the naquium term below.
The clamp to $<1$ guarantees a band can never reach the next level.

**Naquium access — a two-band split (one metric per END of the scale).** Let
$g(v)=1-\operatorname{clamp}\!\big(\tfrac{v-16600}{63300-16600}\big)$ (1 at 16.6k Δv, 0 at 63.3k):

$$a=\begin{cases}0.5+0.5\,g(naqdv) & g(naqdv)>0\ \ (\text{a rich naq-primary field is reachable})\\[2pt] 0.5\,g(fdv) & \text{otherwise (no rich field → judge by the nearest ANY field)}\end{cases}$$

$$c_{\text{naq}}=\operatorname{oddPow}(a\cdot 200-100,\;3)$$

So `naqdv` alone ranks the **good half** $[0.5,1]$ and `fdv` alone ranks the
**bad half** $[0,0.5]$ — they are *mutually exclusive*, never added together.

**Final score:**

$$\text{score}_{\text{orig}}=\operatorname{round}\!\left(\frac{\ell+o}{9}\cdot 100\right)\in[0,100]$$

**Defining property (lexicographic):** because $o<1$, band $\ell$ occupies
exactly $[\,\tfrac{\ell}{9},\tfrac{\ell+1}{9})\cdot100$. **Any seed with more
planets outranks any seed with fewer, no matter the other metrics.** Hostility /
water / naquium only order seeds that have the *same* planet count.

---

## Current — signed weighted sum (`score.config.json`)

Output is a **signed** integer in $[-100,100]$, $0$ = par. Every metric is one
additive term; there is no tier.

$$\text{score}_{\text{cur}}=\operatorname{round}\!\Big(\textstyle\sum_i w_i\, C_i\Big)$$

| Term                     | weight | lo → hi       | dir | kind      |
| ------------------------ | ------ | ------------- | --- | --------- |
| hostility % (`ef`)       | 0.25   | 57 → 85       | ↓   | signed    |
| naquium Δv (`naqdv`)     | 0.25   | 17000 → 45000 | ↓   | signed    |
| planets+moons (`npm`)    | 0.15   | 14 → 36       | ↑   | signed    |
| nearest-field Δv (`fdv`) | 0.15   | 17000 → 20000 | ↓   | signed    |
| planets (`npl`)          | 0.10   | 6 → 13        | ↑   | **bonus** |
| water % (`wp`)           | 0.10   | 56 → 84       | ↑   | signed    |

`signed` terms use $C=\operatorname{comp}(\cdot)\in[-100,100]$. The **bonus** term
(planets) is one-sided, $C=\operatorname{oddPow}(g\cdot100,3)\in[0,100]$: the
common floor `npl=6` contributes 0, only the rare high counts lift.

**Defining property (compensatory):** every metric trades linearly against the
others. Planet count is now just a 10 % one-sided nudge — it can be, and often
is, outweighed by hostility + naquium + water.

---

## The differences

|                           | Original (hierarchical)                                                                          | Current (weighted sum)                                                                |
| ------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| **Aggregation**           | lexicographic — planet tier, then tiebreak                                                       | plain weighted sum                                                                    |
| **Planet role**           | **dominant** (owns a full 1/9 band each)                                                         | minor 0.10 one-sided **bonus**                                                        |
| **Guarantee**             | more planets ⇒ strictly higher score                                                             | none — planets can be outweighed                                                      |
| **Naquium**               | **two-band split**: `naqdv` ranks the good end *or* `fdv` ranks the bad end (mutually exclusive) | **two independent additive terms** (`naqdv` 0.25 **+** `fdv` 0.15, both always count) |
| **`npm` (planets+moons)** | not used                                                                                         | a 0.15 term                                                                           |
| **Scale**                 | 0..100 (bands)                                                                                   | signed −100..100                                                                      |
| **Calibration `lo/hi`**   | desirability *thresholds* (ef 52/84, wp 50/88, Δv 16.6k/63.3k)                                   | *median-centred* (ef 57/85, wp 56/84, naqdv 17k/45k) so 0 = typical                   |
| **Purpose**               | pure ranking (sort the list)                                                                     | ranking **+** the generation capture (`pos_cut`/`neg_cut` tails + `npl≥12`)           |

### Two properties that were lost

**1. Planets no longer strictly dominate.** Consider two seeds:

|     | `npl`      | `npm` | `ef`          | `wp`     | `naqdv`        | `fdv`  |
| --- | ---------- | ----- | ------------- | -------- | -------------- | ------ |
| A   | 6 (fewest) | 20    | 57 (peaceful) | 84 (wet) | 17 500 (close) | 17 500 |
| B   | 9 (many)   | 40    | 84 (hostile)  | 50 (dry) | 60 000 (far)   | 30 000 |

- **Original:** B is in band $\ell=3$, A in band $\ell=0$ → **B ≫ A always** (75+ vs <12), regardless of A's better tiebreakers.
- **Current:** A's peaceful/close/wet terms outweigh B's planet bonus → **A > B.** The strict "more planets wins" ordering is gone.

**2. Naquium double-counts.** A seed with a *mediocre* naq-primary field but a
*close* any-field — `naqdv = 32 030`, `fdv = 14 984`:

- **Original:** a rich field is reachable ($g(32030)=0.67>0$), so $a=0.835$ from
  `naqdv` **alone**; `fdv` is ignored. The close generic field gives **no** extra
  credit. (This was deliberate — the comment: "one metric per END of the scale".)
- **Current:** the two are separate terms. `naqdv`→ $C\approx 0$ (mediocre), but
  `fdv=14984 < lo` → $C=+100$, adding $0.15\times100=\mathbf{+15}$. The close
  generic field boosts the score **even though naquium access is mediocre** —
  precisely the effect the original was built to avoid.

---

## What could be brought back

If the lexicographic feel is what's missed, the two are not mutually exclusive —
options, cheapest first:

1. **Restore the two-band naquium split** as a single *derived* metric
   (`naq_access`) feeding one weighted term, instead of `naqdv` + `fdv` as two
   additive terms. Removes the double-count; small change to the component set.
2. **Re-assert planet dominance** by giving `npl` a large weight *and* a steep
   exponent, or by adding a coarse planet **tier offset** on top of the weighted
   sum (e.g. `score = 40·(npl−6) + weightedSum`), recovering "more planets wins"
   while keeping the sum for tiebreaks.
3. **Full hierarchy** — re-adopt the banded formula (now generator-side, config-
   driven) if strict lexicographic ordering is the goal.

The current weighted sum was chosen to give a *centred, both-tailed* distribution
for the generation filter (capture the best **and** worst extremes). A hierarchy
skews heavily to one end (planets pile at 6), which is why we moved off it — so
any restoration should weigh ranking clarity against that capture goal.
