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
const NAQ_ACCESS_W = 0.20;

// `exp` is the odd-power emphasis for that component (see oddPow): higher =
// flatter middle, so only near-extreme values of that metric move the score.
const SCORE_METRICS = [
  { key: "np", w: 0.60, lo: 16, hi: 40, higherIsBetter: true, exp: 9 }, // planets
  { key: "ef", w: 0.15, lo: 52, hi: 84, higherIsBetter: false, exp: 7 }, // hostile%
  { key: "wp", w: 0.05, lo: 50, hi: 88, higherIsBetter: true, exp: 3 }, // water%
];
const NAQ_EXP = 5; // naquium access odd-power emphasis

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

// Weighted mean of the components → signed score in [-100, 100] (integer), or
// null when no metric is known (renormalises over the components present).
function seedScore(s) {
  let sum = 0, wsum = 0;
  for (const m of SCORE_METRICS) {
    const c = metricComponent(s[m.key], m.lo, m.hi, m.higherIsBetter, m.exp);
    if (c == null) continue;
    sum += m.w * c;
    wsum += m.w;
  }
  const nc = naqComponent(s);
  if (nc != null) { sum += NAQ_ACCESS_W * nc; wsum += NAQ_ACCESS_W; }
  return wsum === 0 ? null : Math.round(sum / wsum);
}

module.exports = { seedScore, metricComponent, naqComponent, naqAccess01, SCORE_METRICS, DV_BEST, DV_WORST, NAQ_ACCESS_W };
