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

// Asteroid fields carry no FSR scores or radius — only a primary_resource — but
// they generate from a fixed-size field, so their yields depend almost entirely
// on which resource is primary (the primary amount is very stable, cv 0.04–0.12;
// delta-v / distance has no measurable effect). This is the per-primary median
// resource amount (at the r=5000 render), calibrated from 72 real fields across
// 3 seeds. naquium is present in every field but only substantial when primary.
// K2 primaries (kr-*) don't render their own ore, so those tables omit it.
const FIELD_TABLE = {
  "iron-ore":         { "iron-ore": 4404894871, "copper-ore": 31755627, "uranium-ore": 25666816, "stone": 39003574, "se-water-ice": 107276695, "se-methane-ice": 26686499, "se-naquium-ore": 2255302 },
  "copper-ore":       { "iron-ore": 83401512, "copper-ore": 3546134734, "uranium-ore": 6964197, "stone": 45140736, "se-water-ice": 32676733, "se-methane-ice": 26861364, "se-naquium-ore": 1899967 },
  "uranium-ore":      { "iron-ore": 112688602, "copper-ore": 17527549, "uranium-ore": 238708086, "stone": 126128929, "se-water-ice": 96525271, "se-methane-ice": 50691211, "se-naquium-ore": 4065844 },
  "stone":            { "iron-ore": 92836852, "copper-ore": 49959145, "uranium-ore": 8313636, "stone": 3639079371, "se-water-ice": 15408638, "se-methane-ice": 7492264, "se-naquium-ore": 8596839 },
  "se-water-ice":     { "iron-ore": 113781583, "copper-ore": 256575057, "uranium-ore": 5930279, "stone": 10357259, "se-water-ice": 1270070251, "se-methane-ice": 23819319, "se-naquium-ore": 11162724 },
  "se-methane-ice":   { "iron-ore": 273810829, "copper-ore": 15599559, "uranium-ore": 9236802, "stone": 56494476, "se-water-ice": 49263144, "se-methane-ice": 1307228748, "se-naquium-ore": 9418998 },
  "se-naquium-ore":   { "iron-ore": 140188911, "copper-ore": 138791388, "uranium-ore": 15134597, "stone": 41379171, "se-water-ice": 5779695, "se-methane-ice": 67516506, "se-naquium-ore": 262188281 },
  "kr-rare-metal-ore":{ "iron-ore": 28763922, "copper-ore": 52206181, "uranium-ore": 19344573, "stone": 73357469, "se-water-ice": 37940902, "se-methane-ice": 139188278, "se-naquium-ore": 4269053 },
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
  // Asteroid fields: yields are a fixed function of the primary resource (no
  // scores / radius to scale by). Look up the calibrated per-primary table.
  if (zone.zone_type === "asteroid-field") {
    const t = FIELD_TABLE[zone.primary_resource];
    const out = {};
    if (t) for (const [res, amt] of Object.entries(t)) if (amt >= DISPLAY_MIN) out[res] = amt;
    return out;
  }
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

module.exports = { estimateZoneOre, K_TABLE, FIELD_TABLE };
