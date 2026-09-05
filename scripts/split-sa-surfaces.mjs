import fs from "node:fs";
const dir = "surface_generator/sa-data";
const planets = JSON.parse(fs.readFileSync(`${dir}/planets.json`, "utf8"));
const functions = JSON.parse(fs.readFileSync(`${dir}/noise-functions.json`, "utf8"));
const expressions = JSON.parse(fs.readFileSync(`${dir}/expressions.json`, "utf8"));
const resources = JSON.parse(fs.readFileSync(`${dir}/resource-autoplace.json`, "utf8"));
const outDir = `${dir}/surfaces`;
fs.mkdirSync(outDir, { recursive: true });

// DSL builtins / variables that are never expression references
const NONREF = new Set(["x","y","map_seed","x_from_start","y_from_start","starting_area",
  "pi","e","log2","sin","cos","abs","min","max","clamp","floor","ceil","sqrt","exp","pow",
  "if","mod","lerp","and","or","not","control","true","false","var"]);

// every name we could reference = expressions + functions + their local_expressions keys
const known = new Set([...Object.keys(expressions), ...Object.keys(functions)]);
const LOCAL = {}; // function/expr name -> set of its local names
function recordLocals(name, def) {
  const s = new Set();
  const loc = def && def.local_expressions;
  if (loc) for (const k of Object.keys(loc)) s.add(k);
  LOCAL[name] = s;
}
for (const [n, d] of Object.entries(expressions)) recordLocals(n, d);
for (const [n, d] of Object.entries(functions)) recordLocals(n, d);

function refsIn(src) {
  const out = new Set();
  const s = String(src);
  for (const m of s.matchAll(/var\(\s*['"]([^'"]+)['"]\s*\)/g)) out.add(m[1]);
  for (const m of s.matchAll(/control:([a-z0-9_-]+)/gi)) out.add("control:" + m[1]);
  for (const m of s.matchAll(/[A-Za-z_][A-Za-z0-9_]*/g)) {
    const tok = m[0];
    if (tok === "control") continue;
    if (NONREF.has(tok)) continue;
    if (known.has(tok)) out.add(tok); // resolves to a global expression/function
  }
  return out;
}

function closeOver(roots, owningName) {
  const want = new Set(roots);
  const stack = [...roots];
  while (stack.length) {
    const name = stack.pop();
    const def = functions[name] || expressions[name];
    if (!def) continue;
    const src = def.expression || "";
    for (const r of refsIn(src)) {
      // skip this function's OWN locals (defined in local_expressions)
      const locals = LOCAL[name] || new Set();
      if (locals.has(r) || (LOCAL[name] && LOCAL[name].has(r))) continue;
      if (!want.has(r)) { want.add(r); stack.push(r); }
    }
    if (def.local_expressions) {
      for (const [ln, lsrc] of Object.entries(def.local_expressions)) {
        for (const r of refsIn(lsrc)) {
          if (!want.has(r)) { want.add(r); stack.push(r); }
        }
      }
    }
  }
  return want;
}

for (const [planet, mg] of Object.entries(planets)) {
  // root expressions the surface's properties need. SA planets map each
  // property key -> a named expression (property_expression_names values).
  // Nauvis leaves the map EMPTY = engine defaults, whose root expression names
  // are the core noise-programs aliases (elevation/moisture/aux/temperature/…).
  const roots = new Set();
  for (const v of Object.values(mg.property_expression_names || {})) roots.add(v);
  if (planet === "nauvis" && roots.size === 0) {
    for (const n of ["elevation", "moisture", "aux", "temperature"]) roots.add(n);
  }
  // entity autoplace expressions from property_expression_names are already roots;
  // the planet's autoplaced TILE probability expressions (surfaces/<planet>-tiles.json)
  // are roots too, so the closure contains every fulgora_* noise expression the
  // tile competition references.
  const tileFile = `${outDir}/${planet}-tiles.json`;
  if (fs.existsSync(tileFile)) {
    const tj = JSON.parse(fs.readFileSync(tileFile, "utf8"));
    for (const t of tj.tiles || []) for (const r of refsIn(t.probability || "")) roots.add(r);
  }
  const want = closeOver([...roots]);
  const exprs = {}; const fns = {};
  for (const n of [...want].sort()) {
    if (expressions[n]) exprs[n] = expressions[n];
    if (functions[n]) fns[n] = functions[n];
  }
  // property tokens inside expression source (e.g. water_base's body uses bare
  // `elevation`) must resolve to THIS planet's property expression — rewrite
  // them to the property_expression_names entry before embedding.
  const aliases = {};
  for (const [k, v] of Object.entries(mg.property_expression_names || {})) {
    if (typeof v === "string" && v !== k) aliases[k] = v;
  }
  const word = (tok) => new RegExp("(?<![A-Za-z0-9_])" + tok + "(?![A-Za-z0-9_])", "g");
  function remap(src) {
    let s0 = String(src);
    for (const [k, v] of Object.entries(aliases)) s0 = s0.replace(word(k), v);
    return s0;
  }
  for (const e of Object.values(exprs)) if (e && e.expression) e.expression = remap(e.expression);
  for (const fn of Object.values(fns)) if (fn && fn.expression) fn.expression = remap(fn.expression);

  const out = { planet,
    property_expressions: [...roots].sort(),
    functions: fns, expressions: exprs,
    resource_autoplace_overrides: planet === "fulgora" ? resources : {} };
  // autoplaced tile competition: expression per tile lives in the closure
  // (entry keyed by tile name) and metadata (layer/colour) for the renderer
  if (fs.existsSync(tileFile)) {
    const tj = JSON.parse(fs.readFileSync(tileFile, "utf8"));
    out.tiles = (tj.tiles || []).map((t) => ({ name: t.name, layer: t.layer, color: t.color }));
    for (const t of tj.tiles || []) {
      if (expressions[t.name]) continue; // never shadow a global name
      exprs[t.name] = { name: t.name, expression: t.probability };
    }
  }
  fs.writeFileSync(`${outDir}/${planet}.json`, JSON.stringify(out, null, 1) + "\n");
  console.log(`${planet}: ${Object.keys(exprs).length} expressions, ${Object.keys(fns).length} functions`);
}
