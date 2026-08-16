// Calibrated ore-count estimator for un-generated surfaces.
//
// MOON / PLANET model (hybrid — see ore-model.json, fit from 465 real full-radius
// surfaces across 9 seeds). For each resource in a zone:
//
//   scored (FSR score + score coeff) ...... est = KS[res][water] · score · R^B
//   unscored but always-present ........... est = PMED[primary][water][res] · R^B
//   scored AND always-present ............. est = max(scoreEst, PLO[...] · R^B)
//
// Why the profile floor matters: the surface generator places the base ores
// (iron/copper/coal/stone/uranium) — and kr-rare-metal — on EVERY surface, but
// the universe generator only assigns FSR scores to a few resources per zone. So
// a pure score model misses ~every unscored base ore (the "estimated 3, actually
// 7" bug). The per-(primary,water) PMED profile fills those in; PLO (a low
// percentile) floors severely under-predicted low-score resources without
// inflating well-scored ones. Only resources that generate >=1M in >=half a
// primary's zones enter the profile, so it rarely invents a resource a zone lacks.
//
// R^B (B≈1.49) captures that ore does NOT scale with area (r^2): it concentrates
// near spawn and thins outward, so density falls with radius.
//
// Validation over 2774 (zone,resource) pairs: 95% resource completeness, median
// predicted/actual ≈ 1.06, 72% within 2×, 87% within 3×. Also works for score-
// less zones (no resource_scores) via the profile alone. Nauvis excluded from
// calibration (bad SE sample). Regenerate with scratchpad calib2.js + fit5.js.
const MODEL = require("./ore-model.json"); // { B, KS, PMED, PLO }

// Asteroid fields carry no FSR scores or radius — only a primary_resource — but
// they generate from a fixed-size field, so their yields depend almost entirely
// on which resource is primary (the primary amount is very stable, cv 0.04–0.12;
// delta-v / distance has no measurable effect). Per-primary median resource
// amount (at the r=5000 render), calibrated from 72 real fields across 3 seeds.
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

// Nauvis is synthetic (not universe-generated): fixed r5000, default 1/1/1 FSR,
// SE autoplace over the base ores only — no per-zone scores or primary. Amounts
// are very stable across seeds (calibrated from 6 seeds). Under K2, Nauvis also
// carries rare-metal-ore (median below); its other K2 addition, mineral-water,
// is a FLUID the ore path doesn't count (like crude-oil), so it isn't listed.
const NAUVIS_BASE = { "iron-ore": 720891788, "copper-ore": 645692931, "coal": 502851057, "stone": 643189231, "uranium-ore": 61560588 };
const NAUVIS_K2 = { "kr-rare-metal-ore": 430267684 };

const MAX_RADIUS = 5000;      // matches GUI generation cap (effRadius) so est ≈ measured
const DISPLAY_MIN = 1e6;      // hide sub-1M estimates (noise)

// water-bucket helpers with a fallback to the other bucket when a coeff is absent.
const otherW = w => (w === "none" ? "water" : "none");
const ksOf = (res, w) => (MODEL.KS[res] || {})[w] ?? (MODEL.KS[res] || {})[otherW(w)];
const profOf = (T, p, w) => (T[p] || {})[w] || (T[p] || {})[otherW(w)] || {};

// Estimate per-resource ore amounts for a zone with no generated surface yet.
// Returns { resource: amount }. {} when there's nothing to key off (no primary
// and no scores — e.g. asteroid belts / anomalies, which carry neither).
function estimateZoneOre(zone, opts) {
  if (!zone) return {};
  // Nauvis: fixed default-FSR base ores; + rare-metal-ore when the seed is K2.
  if (zone.name === "Nauvis") {
    const out = {};
    for (const [res, amt] of Object.entries(NAUVIS_BASE)) if (amt >= DISPLAY_MIN) out[res] = amt;
    if (opts && opts.k2) for (const [res, amt] of Object.entries(NAUVIS_K2)) if (amt >= DISPLAY_MIN) out[res] = amt;
    return out;
  }
  // Asteroid fields: yields are a fixed function of the primary resource.
  if (zone.zone_type === "asteroid-field") {
    const t = FIELD_TABLE[zone.primary_resource];
    const out = {};
    if (t) for (const [res, amt] of Object.entries(t)) if (amt >= DISPLAY_MIN) out[res] = amt;
    return out;
  }
  // Moons / planets: hybrid score + per-primary profile model.
  const R = Math.min(Math.round(zone.radius || 0), MAX_RADIUS);
  if (!R) return {};
  const rB = Math.pow(R, MODEL.B);
  const w = (!zone.water || zone.water === "none") ? "none" : "water";
  let scores = null;
  try { scores = JSON.parse(zone.resource_scores || "null"); } catch (_) {}
  const out = {};
  // 1) score-based estimate for every scored resource we have a coefficient for.
  if (scores && typeof scores === "object") {
    for (const [res, sc] of Object.entries(scores)) {
      if (!(sc > 0)) continue;
      const k = ksOf(res, w);
      if (k) out[res] = k * sc * rB;
    }
  }
  // 2) profile: add always-present resources (unscored), floor the under-predicted.
  const pmed = profOf(MODEL.PMED, zone.primary_resource, w);
  const plo = profOf(MODEL.PLO, zone.primary_resource, w);
  for (const res in pmed) {
    if (out[res] == null) out[res] = pmed[res] * rB;            // unscored → profile median
    else out[res] = Math.max(out[res], (plo[res] || 0) * rB);  // scored → low-percentile floor
  }
  const f = {};
  for (const [res, v] of Object.entries(out)) if (v >= DISPLAY_MIN) f[res] = Math.round(v);
  return f;
}

module.exports = { estimateZoneOre, FIELD_TABLE, MODEL };
