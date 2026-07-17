# Automated seed-vs-game verification

These scripts drive the natively-installed Factorio + Space Exploration to
produce a ground-truth universe dump for a seed, then diff it against the seed
finder's generation with `compare.lua`. They are a slim migration of the
"generate save" and "start server" logic from the `factorio-ai` bridge — native,
no docker, no MCP.

```
tools/verify/
  rcon.py         minimal Source-RCON client (stdlib only)
  ingame_dump.py  create seeded SE save -> headless server -> RCON dump -> JSON
  verify-seed.sh  ingame_dump.py + compare.lua, one command
```

## One-shot usage

```
# SE (Krastorio2 disabled in the mod set)
tools/verify/verify-seed.sh 123458

# SE + Krastorio2 (K2 enabled in the mod set)
SE_ENABLE_K2=1 tools/verify/verify-seed.sh 123458
```

Prints a `compare.lua` report; exit 0 = the finder matches the game for that seed.

## How it works

1. `ingame_dump.py` writes a `map-gen-settings.json` with the seed and runs
   `factorio --create` — this executes SE's `on_init`, generating the universe
   into the save. It then starts `factorio --start-server` (headless, RCON on),
   calls SE's `get_zone_index` remote interface, and writes the same JSON schema
   as `tools/ingame-dump.lua`.
2. `compare.lua` regenerates that seed in the finder and diffs. Each zone's `seed`
   is drawn sequentially from the global universe RNG, so all zone seeds matching
   by name means the RNG streams ran in lockstep.

The macOS `factorio.app` binary is a universal binary and runs **arm64 natively**;
`--create` and `--start-server` are fully headless (no display needed).

## Prerequisites & notes

- **Factorio.** Default `FACTORIO_BIN` is
  `/Applications/factorio.app/Contents/MacOS/factorio`; override via env if yours
  is elsewhere (e.g. the Steam copy).
- **Mods.** It uses Factorio's default local mod directory
  (`~/Library/Application Support/factorio/mods`), so **whatever is enabled there
  decides the map**. The finder side must match:
  - K2 enabled in the mod set  ⇒ run with `SE_ENABLE_K2=1`.
  - For a *pure-SE* comparison, disable Krastorio2 (and Space Age / any other
    generation-affecting mod) in the mod set and leave `SE_ENABLE_K2` unset.
- **Ports.** Uses game `:34717` / RCON `:27717` by default (override with
  `GAME_PORT` / `RCON_PORT`) to avoid clashing with a running game.
- **Lua runner.** `verify-seed.sh` uses `./bin/lua` when it runs natively,
  otherwise the `seedlua` docker image (a 90 MB Lua-interpreter image — this is
  the finder side, not Factorio). Override with `SEED_LUA`.

## Latest result

SE + Krastorio2, seed 123458: 1270/1270 zones, 1256/1258 shared zones with
byte-identical seeds. See `docs/universe-generation.md` → "Real-game comparison
result" for the full breakdown and the single remaining divergence.
