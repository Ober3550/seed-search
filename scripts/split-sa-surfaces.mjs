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
  const roots = new Set();
  for (const v of Object.values(mg.property_expression_names || {})) roots.add(v);
  // entity autoplace expressions from property_expression_names are already roots;
  // also add any autoplace settings name lists we know are expressions? no — tiles later.
  const want = closeOver([...roots]);
  const exprs = {}; const fns = {};
  for (const n of [...want].sort()) {
    if (expressions[n]) exprs[n] = expressions[n];
    if (functions[n]) fns[n] = functions[n];
  }
  const out = { planet,
    property_expressions: [...roots].sort(),
    functions: fns, expressions: exprs,
    resource_autoplace_overrides: planet === "fulgora" ? resources : {} };
  fs.writeFileSync(`${outDir}/${planet}.json`, JSON.stringify(out, null, 1) + "\n");
  console.log(`${planet}: ${Object.keys(exprs).length} expressions, ${Object.keys(fns).length} functions`);
}
