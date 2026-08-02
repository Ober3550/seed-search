// Seed capture, shared by the server (display) and db.js (stored `score` column
// so the list can ORDER BY it in SQL, paginated).
//
// UNION OF EXTREMES — there is no composite score. A seed is captured if it lands
// in ANY enabled per-metric tail (value <= lo OR value >= hi; a null bound
// disables that tail). `seedScore` returns the tail-match COUNT — how many metrics
// the seed is extreme in — which is what's stored in `score` and used only for
// sorting (0 would mean "kept by nothing", which never happens for stored rows).
//
// The tails live in ../score.config.json — the SINGLE source of truth shared with
// the Zig generator (universe_generator/zig/score.zig) and the plotter
// (scripts/plot_distributions.py). Edit that file to retune; nothing here changes.
const fs = require("fs");
const path = require("path");

const CONFIG_PATH =
  process.env.SCORE_CONFIG || path.join(__dirname, "..", "score.config.json");
const CFG = JSON.parse(fs.readFileSync(CONFIG_PATH, "utf8"));

// Metric value for a filter key from a seed row. `moons` is derived (npm − npl);
// everything else is a stored column. The Δv 'none' sentinel (10M) sits above any
// hi threshold, so it naturally counts as the far tail.
function metricVal(s, key) {
  if (key === "moons") return (s.bodies ?? 0) - (s.planets ?? 0);
  return s[key];
}

// Tail-match count: how many enabled per-metric tails the seed lands in.
function seedScore(s) {
  if (s == null) return null;
  let n = 0;
  for (const f of CFG.filters) {
    const v = metricVal(s, f.key);
    if (v == null) continue;
    if (f.lo != null && v <= f.lo) { n++; continue; }
    if (f.hi != null && v >= f.hi) n++;
  }
  return n;
}

module.exports = { seedScore, metricVal, CFG };
