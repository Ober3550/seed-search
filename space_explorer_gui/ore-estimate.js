// Calibrated ore-count estimator for un-generated surfaces.
//
// Model (deliberately simple, per project direction — see resource-estimation-
// direction / storage memory):
//
//     amount(res) ≈ score(res) · K[res][water] · (π · R²)
//
// where score = zone.resource_scores[res] (normalised FSR, primary = 1), R is the
// zone radius capped at 5000, and water is a binary none/has-water split.
//
// K was calibrated from REAL generated ore on the LARGEST SE surfaces (law of
// large numbers), excluding Nauvis (a bad SE sample — world seed, starting
// patches, always r5000). Anchoring on big surfaces means small ones under-
// predict slightly (ore concentrates near spawn and fades outward), which is the
// accepted trade-off: "the larger the surface, the more accurate the estimate."
//
// Calibration: 36 moons/planets from seed 3403311347, K = median of
// amount/(score·area) over surfaces with R ≥ 3000. Validation over all 213
// (zone,resource) pairs: median predicted/actual ≈ 1.0, 71% within 2×, 86%
// within 3×. Regenerate with scratchpad fit_final.js if the generator changes.

// Per-resource K (ore units per unit-score per tile of disk area), none vs water.
const K_TABLE = {
  "iron-ore":         { none: 325, water: 121 },
  "copper-ore":       { none: 256, water: 130 },
  "coal":             { none: 117, water: 78 },
  "stone":            { none: 390, water: 62 },
  "uranium-ore":      { none: 26,  water: 12 },
  "se-iridium-ore":   { none: 52,  water: 40 },
  "se-holmium-ore":   { none: 60,  water: 37 },
  "se-beryllium-ore": { none: 53,  water: 12 },
  "se-cryonite":      { none: 78,  water: 112 },
  "se-vulcanite":     { none: 37,  water: 51 },
  "se-vitamelange":   { none: 38,  water: 24 },
};

const MAX_RADIUS = 5000;      // density model is anchored within this disk
const DISPLAY_MIN = 1e6;      // hide sub-1M estimates (noise at low scores)

// Estimate per-resource ore amounts for a zone that has FSR scores but no
// generated surface yet. Returns { resource: amount } (raw numbers), or {} when
// the zone lacks scores/radius (e.g. asteroid fields/belts, which carry neither).
//
// Only resources with a CALIBRATED K are estimated. This deliberately excludes
// resources that carry an FSR score but never render as ore under the current
// surface generator — K2 ores (kr-*), fluids (crude-oil, kr-mineral-water) —
// which would otherwise produce phantom estimates for patches that never appear.
function estimateZoneOre(zone) {
  if (!zone) return {};
  let scores;
  try { scores = JSON.parse(zone.resource_scores || "{}"); } catch (_) { return {}; }
  const R = Math.min(Math.round(zone.radius || 0), MAX_RADIUS);
  if (!R || !scores || typeof scores !== "object") return {};
  const area = Math.PI * R * R;
  const water = (!zone.water || zone.water === "none") ? "none" : "water";
  const out = {};
  for (const [res, score] of Object.entries(scores)) {
    if (!(score > 0)) continue;
    const k = K_TABLE[res];            // calibrated ores only — no __default__
    if (!k) continue;
    const amount = score * k[water] * area;
    if (amount >= DISPLAY_MIN) out[res] = amount;
  }
  return out;
}

module.exports = { estimateZoneOre, K_TABLE };
