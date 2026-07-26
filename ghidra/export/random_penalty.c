/* ============================================================================
 * NoiseOperations::RandomPenalty::run @ 0x1015f0384 — DECODED
 *
 * Per-tile: seed = int(X)*0x1eef(7919) + int(Y + seed_const)*0x1ee3(7907)
 *                  + 0x3fbe2c,  clamp < 0x156(342) -> 0x155(341).
 * rng = taus88(seed,seed,seed); ONE step; r = (s1^s2^s3) * 2^-32.
 * output = source - r * amplitude.   (== our noise.zig randomPenaltySeeded)
 *
 * VERIFIED our port matches this op exactly. BUT it produces ANTI-DIAGONAL
 * correlation for the oil probability random_penalty{source=1, amplitude=48}:
 * along x+y=const the seed changes by only 7919-7907=12, and one taus88 step
 * from (s,s,s) does NOT decorrelate a delta-12 seed, so neighbouring tiles get
 * near-identical r -> candidates (r<1/48) form diagonal streaks.
 *
 * PROBLEM: the ground-truth oil is UNIFORM (43 tiles, 42 distinct x+y) and does
 * NOT align with our random_penalty>0 tiles (0/43). So the op matches but the
 * INPUTS differ — the X/Y passed here are probably NOT plain integer tile coords
 * (sub-tile offset, or the noise var x is pre-transformed), OR there is an RNG
 * detail we are missing. UNRESOLVED — needs the caller (computeConstant
 * @0x1015eff14) + how the x/y registers are filled for this op.
 * ============================================================================ */

