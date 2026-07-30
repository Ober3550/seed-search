// Seed desirability score (0-100), shared by the server (display) and db.js
// (stored `score` column so the list can ORDER BY it in SQL, paginated).
//
// Pure function of the stored per-seed metrics (np, ef, wp, naqdv, fdv) plus the
// fixed constants below — no population pass — so a row's score is stable and
// can be computed at insert time. If these constants change, re-run
// db.backfillScores() to refresh the column.
//
// Weights: planet count 60%, naquium access 20% (split), hostility 15%, water 5%.

const DV_BEST = 10000; // Δv at or below this scores 100%
const DV_WORST = 50000; // Δv at or above this scores 0%
const NAQ_ACCESS_W = 0.20;

const SCORE_METRICS = [
  { key: "np", w: 0.60, lo: 16, hi: 40, higherIsBetter: true },
  { key: "ef", w: 0.15, lo: 52, hi: 84, higherIsBetter: false }, // hostile%
  { key: "wp", w: 0.05, lo: 50, hi: 88, higherIsBetter: true }, // water% — more is wetter
];

// Naquium access, 0..1. Split into two bands so each metric ranks one END:
//   rich > 0 (naq-PRIMARY field within DV_WORST) → 0.5..1.0 by naqdv alone.
//   rich = 0 (no reachable rich field)          → 0.0..0.5 by fdv (any field) alone.
function naqAccess(s) {
  const g = (v) => (v == null ? null : 1 - Math.max(0, Math.min(1, (v - DV_BEST) / (DV_WORST - DV_BEST))));
  const rich = g(s.naqdv), reach = g(s.fdv);
  if (rich == null && reach == null) return null;
  if (rich == null) return 0.5 * reach;
  if (reach == null) return rich > 0 ? 0.5 + 0.5 * rich : 0;
  return rich > 0 ? 0.5 + 0.5 * rich : 0.5 * reach;
}

// 0..100 integer, or null when no metric is known (renormalises over present ones).
function seedScore(s) {
  let sum = 0, wsum = 0;
  for (const m of SCORE_METRICS) {
    const v = s[m.key];
    if (v == null) continue;
    const t = Math.max(0, Math.min(1, (v - m.lo) / (m.hi - m.lo)));
    sum += m.w * (m.higherIsBetter ? t : 1 - t);
    wsum += m.w;
  }
  const naq = naqAccess(s);
  if (naq != null) { sum += NAQ_ACCESS_W * naq; wsum += NAQ_ACCESS_W; }
  return wsum === 0 ? null : Math.round((100 * sum) / wsum);
}

module.exports = { seedScore, naqAccess, SCORE_METRICS, DV_BEST, DV_WORST, NAQ_ACCESS_W };
