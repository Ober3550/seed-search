// Seed desirability score, shared by the server (display) and db.js (stored
// `score` column so the list can ORDER BY it in SQL, paginated).
//
// EVERY component is on ONE signed scale: -100 (worst) .. +100 (best), 0 = par.
// That's the same scale as the odd-power enemy value `ed`, so terms compose by a
// plain weighted average — no per-term rescaling. The final score is the
// weighted mean of the components, also in [-100, 100].
//
// Pure function of the stored per-seed metrics (np, ef, wp, naqdv, fdv) plus the
// fixed constants below — no population pass — so a row's score is stable and can
// be computed at insert time. If these constants change, re-run
// db.backfillScores() to refresh the column.
//
// Weights: planet count 60%, naquium access 20% (split), hostility 15%, water 5%.

// Calibrated to the stored naqdv/fdv distribution (game-exact travel-only Δv):
// nearest field ≈ 16,600 min → +100; furthest ANY field ≈ 63,300 (fdv max; and
// fdv ≤ naqdv always, so this is the true worst reachability) → -100. naqdv beyond
// this reads as "no reachable rich field" and is judged by fdv, per naqAccess.
// Re-query (SELECT MIN/MAX naqdv,fdv … WHERE <10000000) and update if the Δv
// scale changes, then db.backfillScores().
const DV_BEST = 16600; // Δv at or below this scores +100
const DV_WORST = 63300; // Δv at or above this scores -100
const NAQ_ACCESS_W = 0.30; // field distance

// HIERARCHICAL score: planets (npl) is the dominant tier — each of its discrete
// levels owns its own band of the 0..100 range — and the other metrics only move
// WITHIN that band. So any seed with more planets ALWAYS outscores any seed with
// fewer; field/hostile/water only break ties among equal-planet seeds. This is
// what a weighted sum can't guarantee.
const PLANET = { key: "npl", lo: 6, hi: 14 }; // npl 6..14 → 9 discrete levels

// Within-band tiebreakers (weighted mean, each mapped to 0..1, best = 1). Their
// relative weights set the tie-break priority: field 30, hostile 20, water 10.
const SCORE_METRICS = [
  { key: "ef", w: 0.20, lo: 52, hi: 84, higherIsBetter: false, exp: 3 }, // hostile%
  { key: "wp", w: 0.10, lo: 50, hi: 88, higherIsBetter: true, exp: 3 }, // water%
];
const NAQ_EXP = 3; // naquium access odd-power emphasis

// Odd-power response on a signed value in [-100, 100] → still [-100, 100]:
// sign(x)·|x/100|^p·100. p=1 is linear; p>1 flattens the middle and steepens the
// ends so extremes dominate. Sign is preserved and |x/100|<=1 keeps it in range.
function oddPow(v, p) {
  const x = v / 100;
  return Math.sign(x) * Math.pow(Math.abs(x), p) * 100;
}

// A metric → signed component in [-100, 100]. At/below `lo` (accounting for
// direction) → -100, at/above `hi` → +100, linear between, then the odd-power
// emphasis. null if unknown.
function metricComponent(v, lo, hi, higherIsBetter, exp = 1) {
  if (v == null) return null;
  const t = Math.max(0, Math.min(1, (v - lo) / (hi - lo)));
  const good = higherIsBetter ? t : 1 - t; // 0..1, 1 = best
  return oddPow((good * 2 - 1) * 100, exp); // -100..100
}

// Naquium access, 0..1 (see below), then mapped onto the same -100..100 scale.
// Split into two bands so each metric ranks one END:
//   rich > 0 (naq-PRIMARY field within DV_WORST) → 0.5..1.0 by naqdv alone.
//   rich = 0 (no reachable rich field)          → 0.0..0.5 by fdv (any field) alone.
function naqAccess01(s) {
  const g = (v) => (v == null ? null : 1 - Math.max(0, Math.min(1, (v - DV_BEST) / (DV_WORST - DV_BEST))));
  const rich = g(s.naqdv), reach = g(s.fdv);
  if (rich == null && reach == null) return null;
  if (rich == null) return 0.5 * reach;
  if (reach == null) return rich > 0 ? 0.5 + 0.5 * rich : 0;
  return rich > 0 ? 0.5 + 0.5 * rich : 0.5 * reach;
}
function naqComponent(s) {
  const a = naqAccess01(s);
  return a == null ? null : oddPow((a * 2 - 1) * 100, NAQ_EXP); // -100..100
}

// Hierarchical score in 0..100: the planet level picks the band, the weighted
// tiebreakers fill within it. null when planet count is unknown.
const PLANET_LEVELS = PLANET.hi - PLANET.lo; // 8 gaps → levels 0..8 (9 bands)
function seedScore(s) {
  const npl = s[PLANET.key];
  if (npl == null) return null;
  const lvl = Math.max(0, Math.min(PLANET_LEVELS, npl - PLANET.lo)); // 0..8

  // Within-band position in [0,1): weighted mean of the tiebreakers, each mapped
  // from its signed [-100,100] component to [0,1] (best = 1).
  let sum = 0, wsum = 0;
  const add = (c, w) => { if (c != null) { sum += w * ((c + 100) / 200); wsum += w; } };
  for (const m of SCORE_METRICS) add(metricComponent(s[m.key], m.lo, m.hi, m.higherIsBetter, m.exp), m.w);
  add(naqComponent(s), NAQ_ACCESS_W);
  // Clamp strictly < 1 so a band never bleeds into the next planet level.
  const others01 = wsum > 0 ? Math.min(0.999999, Math.max(0, sum / wsum)) : 0.5;

  return Math.round(((lvl + others01) / (PLANET_LEVELS + 1)) * 100);
}

module.exports = { seedScore, metricComponent, naqComponent, naqAccess01, SCORE_METRICS, DV_BEST, DV_WORST, NAQ_ACCESS_W };
