# Verifier

End-to-end verification against a real Factorio game.

## Prerequisites

Edit `.env` (copy from `.env.example` at the repo root) to set your
`FACTORIO_BIN` path. Set `SE_ENABLE_K2=1` if your Factorio mod set includes
Krastorio2.

## Files

- `compare.lua` — regenerates a seed in the harness and diffs every zone against
  a real in-game dump. Exit 0 = perfect match.
- `harness-dump.lua` — writes the harness's own generation to JSON (for
  eyeballing and self-testing).
- `ingame-dump.lua` — in-game console command (Factorio `/c`) that dumps
  every zone's name, type, parent, radius, seed, and resource controls from a
  live SE map to `script-output/se-universe-dump.json`.
- `verify/` — automated Python scripts that drive Factorio headless.
- `fixtures/` — ground-truth dumps from real game runs (gitignored; regenerable).

## One-shot verification

```sh
# Pure SE (Krastorio2 disabled in your Factorio mod set)
verifier/verify/verify-seed.sh 123458

# SE + Krastorio2 (K2 enabled in Factorio)
SE_ENABLE_K2=1 verifier/verify/verify-seed.sh 123458
```

This launches Factorio headless to generate a save, dumps the universe via RCON,
then runs `compare.lua` to diff it against the generator.

## Manual comparison

```sh
# Dump the harness for a seed:
runner/bin/lua verifier/harness-dump.lua 123458

# Compare against an in-game dump:
runner/bin/lua verifier/compare.lua verifier/fixtures/universe-ingame-123458.json
```
