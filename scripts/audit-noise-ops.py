#!/usr/bin/env python3
"""Audit: every noise function/op referenced by surface-generation data across
base + space-age + SE/AB (as installed), vs what the Zig engine implements.

Sources:
  surface_generator/sa-data/expressions.json      (core noise-programs + base +
                                                   space-age expressions)
  surface_generator/sa-data/noise-functions.json  (Lua-defined helpers)
  surface_generator/biome/tile-autoplace-exprs.json (base/SE/AB tile autoplace
                                                   probability expressions)
Implement list is scraped from sa_expr.zig (callNative + natives string
matches). Lua-defined set = keys of the two sa-data files (those expand to ops
themselves, so they are NOT missing even if their name appears as a call).
"""
import json, re, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def load(p):
    return json.load(open(ROOT / p))

exprs = load("surface_generator/sa-data/expressions.json")
funcs = load("surface_generator/sa-data/noise-functions.json")
tiles = load("surface_generator/biome/tile-autoplace-exprs.json")

def strings_of(src):
    for k, v in src.items():
        if isinstance(v, dict) and "expression" in v:
            if isinstance(v["expression"], str):
                yield k, v["expression"]
        elif isinstance(v, str):
            yield k, v

CALL = re.compile(r"(?<![\w:.])([A-Za-z_]\w*)\s*[({]")
VAR = re.compile(r"var\(\s*['\"]([^'\"]+)")
CTRL = re.compile(r"control:([A-Za-z0-9_-]+)")
# tokens that are variables / scalars / numbers, not calls
NONCALL = {"x", "y", "map_seed", "x_from_start", "y_from_start", "distance",
           "true", "false"}

refs = {}   # name -> [sample sources]
def add(name, srcname):
    refs.setdefault(name, [])
    if len(refs[name]) < 2:
        refs[name].append(srcname)

for label, src in [("exprs", exprs), ("funcs", funcs), ("tiles", tiles)]:
    for k, expr in strings_of(src):
        for m in CALL.finditer(expr):
            tok = m.group(1)
            if tok in NONCALL:
                continue
            add(tok, f"{label}:{k}")
        for m in VAR.finditer(expr):
            add("var:" + m.group(1), f"{label}:{k}")
        for m in CTRL.finditer(expr):
            add("control:" + m.group(1), f"{label}:{k}")

# Lua-defined names (data helpers) — available once the engine can call data fns
lua_defs = set(exprs) | set(funcs)
# names that are ALSO plain data defs but called internally (skip, they are not ops)
defs_only = {n for n in refs if n in lua_defs}

# implemented natives from sa_expr.zig string matches
src = (ROOT / "surface_generator/src/sa_expr.zig").read_text()
impl = set(re.findall(r'eql\(u8, name, "([^"]+)"\)', src))
impl |= {"min", "max", "abs", "clamp", "if", "sin", "cos", "sqrt", "floor",
         "ceil", "pow", "exp", "log2", "var", "lerp", "rand", "random"}
# ops implemented in noise.zig/terrain.zig but maybe not in sa_expr string list:
impl |= {"basis_noise", "multioctave_noise", "quick_multioctave_noise",
         "variable_persistence_multioctave_noise", "random_penalty", "spot_noise",
         "voronoi_cell_id", "voronoi_spot_noise", "voronoi_facet_noise",
         "voronoi_pyramid_noise", "terrace"}

missing = sorted(n for n in refs
                 if n not in lua_defs and n not in impl and not n.startswith(("var:", "control:")))
print("== referenced call-like names:", len(refs))
print("\n== MISSING (referenced, no Lua def, not implemented in sa_expr): ==")
for n in missing:
    print(f"  {n:45s} e.g. {refs[n][0]}")

print("\n== native ops implemented (for reference) ==")
known = sorted(n for n in refs if n in impl)
print("  " + ", ".join(known))
print("\n== lua-defined helpers referenced (resolve via data engine) count:", len(defs_only))
print("== control lookups:", sorted(n for n in refs if n.startswith('control:')))
print("== var() references:", sorted(n for n in refs if n.startswith('var:')))
