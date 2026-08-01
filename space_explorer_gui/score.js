// Seed desirability score, shared by the server (display) and db.js (stored
// `score` column so the list can ORDER BY it in SQL, paginated).
//
// SIGNED scale [-100, 100], 0 = par: the score is a WEIGHTED SUM of per-metric
// components, so negative qualifiers (a hostile system, no naquium access) pull
// below 0 and the distribution is centred on 0 with two thin tails. Recover a
// 0..100 value as (score + 100) / 2.
//
// The weights + calibration live in ../score.config.json — the SINGLE source of
// truth shared with the Zig generator (universe_generator/zig/score.zig) and the
// plotter (scripts/plot_distributions.py). Edit that file to retune; nothing here
// changes. Each component maps its metric to a signed value centred on its median
// (lo/hi) with an odd-power emphasis (exp). kind 'signed' spans [-100,100];
// kind 'bonus' is one-sided [0,100] (a floor value contributes 0).
const fs = require("fs");
const path = require("path");

const CONFIG_PATH =
  process.env.SCORE_CONFIG || path.join(__dirname, "..", "score.config.json");
const CFG = JSON.parse(fs.readFileSync(CONFIG_PATH, "utf8"));
const NAQ_NONE = 10_000_000; // Δv sentinel: no reachable field

// sign(x/100)·|x/100|^p·100, staying in [-100, 100].
function oddPow(v, p) {
  const x = v / 100;
  return Math.sign(x) * Math.pow(Math.abs(x), p) * 100;
}

// One metric -> its signed (or one-sided 'bonus') component per the config entry.
function component(v, c, exp) {
  if (v == null) return 0; // unknown metric -> par (neutral)
  if (v >= NAQ_NONE) v = c.hi; // 'none' Δv sentinel -> far end (worst for lower-better)
  const t = Math.max(0, Math.min(1, (v - c.lo) / (c.hi - c.lo)));
  const good = c.higher_better ? t : 1 - t; // 0..1, 1 = best
  return c.kind === "bonus" ? oddPow(good * 100, exp) : oddPow(good * 200 - 100, exp);
}

// Signed desirability in [-100, 100], 0 = par. null when planet count is unknown.
function seedScore(s) {
  if (s == null || s.npl == null) return null;
  let sum = 0;
  for (const c of CFG.components) sum += c.weight * component(s[c.key], c, CFG.exp);
  return Math.round(sum);
}

module.exports = { seedScore, component, CFG };
