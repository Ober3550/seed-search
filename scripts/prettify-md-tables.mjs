#!/usr/bin/env node
// Align GitHub-flavoured markdown pipe tables in place. Tables only — prose,
// code fences, and everything else are left byte-for-byte unchanged.
//
//   node scripts/prettify-md-tables.mjs <file.md> [more.md ...]
//
// A table = a header row containing `|`, immediately followed by a delimiter row
// of `---`/`:--:` cells. Cells are split on unescaped `|`; column widths are
// padded to the max, honouring the delimiter's alignment colons.
import { readFileSync, writeFileSync } from "node:fs";

const splitCells = (line) => {
  let s = line.trim();
  if (s.startsWith("|")) s = s.slice(1);
  if (s.endsWith("|")) s = s.slice(0, -1);
  return s.split(/(?<!\\)\|/).map((c) => c.trim());
};
const isDelim = (line) =>
  /^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$/.test(line) && line.includes("-");
const align = (cell) => {
  const l = cell.startsWith(":");
  const r = cell.endsWith(":");
  return l && r ? "center" : r ? "right" : l ? "left" : "none";
};
const pad = (text, width, how) => {
  const gap = width - text.length;
  if (gap <= 0) return text;
  if (how === "right") return " ".repeat(gap) + text;
  if (how === "center") {
    const left = gap >> 1;
    return " ".repeat(left) + text + " ".repeat(gap - left);
  }
  return text + " ".repeat(gap);
};

function formatBlock(rows) {
  // rows: [headerCells, delimCells, ...bodyCells]
  const aligns = rows[1].map(align);
  const cols = Math.max(...rows.map((r) => r.length));
  const widths = [];
  for (let c = 0; c < cols; c++) {
    let w = 3; // min so the delimiter stays >= "---"
    for (let r = 0; r < rows.length; r++) {
      if (r === 1) continue; // delimiter row sized separately
      w = Math.max(w, (rows[r][c] ?? "").length);
    }
    widths[c] = w;
  }
  const line = (cells, delim) => {
    const out = [];
    for (let c = 0; c < cols; c++) {
      const a = aligns[c] === "none" ? "left" : aligns[c];
      if (delim) {
        const w = widths[c];
        let bar = "-".repeat(w);
        if (aligns[c] === "center") bar = ":" + "-".repeat(w - 2) + ":";
        else if (aligns[c] === "right") bar = "-".repeat(w - 1) + ":";
        else if (aligns[c] === "left" && (rows[1][c] ?? "").startsWith(":"))
          bar = ":" + "-".repeat(w - 1);
        out.push(bar);
      } else {
        out.push(pad(cells[c] ?? "", widths[c], a));
      }
    }
    return "| " + out.join(" | ") + " |";
  };
  return rows.map((cells, i) => line(cells, i === 1));
}

function prettify(src) {
  const lines = src.split("\n");
  const out = [];
  let inFence = false;
  for (let i = 0; i < lines.length; i++) {
    const ln = lines[i];
    if (/^\s*```/.test(ln)) { inFence = !inFence; out.push(ln); continue; }
    if (!inFence && ln.includes("|") && lines[i + 1] !== undefined && isDelim(lines[i + 1])) {
      const block = [ln];
      let j = i + 1;
      while (j < lines.length && lines[j].includes("|") && lines[j].trim() !== "") block.push(lines[j++]);
      const rows = block.map(splitCells);
      const cols = Math.max(...rows.map((r) => r.length));
      for (const r of rows) while (r.length < cols) r.push("");
      out.push(...formatBlock(rows));
      i = j - 1;
      continue;
    }
    out.push(ln);
  }
  return out.join("\n");
}

let changed = 0;
for (const file of process.argv.slice(2)) {
  const before = readFileSync(file, "utf8");
  const after = prettify(before);
  if (after !== before) { writeFileSync(file, after); changed++; console.log("formatted", file); }
  else console.log("unchanged", file);
}
console.log(`\n${changed} file(s) changed`);
