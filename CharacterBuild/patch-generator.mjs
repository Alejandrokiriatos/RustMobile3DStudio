import { readFileSync, writeFileSync } from 'node:fs';

const path = 'src/core/garments/catalog.ts';
let source = readFileSync(path, 'utf8');

function insertBefore(id, lines) {
  if (source.includes("id: '" + id + "'")) return;
  const marker = "  {\n    id: '" + id + "'";
  const at = source.indexOf(marker);
  if (at < 0) throw new Error('Cannot locate insertion point for ' + id);
  source = source.slice(0, at) + lines.join('\n') + '\n' + source.slice(at);
}

insertBefore('fatigue_shirt', [
"  {",
"    id: 'sports_bra', label: 'Sports bra', slot: 'top', patterns: ['solid'], color: '#526c59', color2: '#252525',",
"    build: (g, st) => {",
"      const sx = g.body.L.shoulderX;",
"      return shellPart(g, {",
"        // Cropped, opaque chest coverage with shoulder straps; the abdomen remains free.",
"        covers: (v) => (isTrunk(v) && v.tt >= 0.64 && v.tt < 0.95) ||",
"          (v.region === REGION.upperarm && v.t < 0.08 && Math.abs(v.ax - 0.6 * sx) < 0.2 * sx),",
"        offset: cm(0.7), tile: 0.2, relax: 5,",
"      }, cloth(g, 'Sports bra', st));",
"    },",
"  },"
]);

insertBefore('fatigue_pants', [
"  {",
"    id: 'survival_shorts', label: 'Simple survival shorts', slot: 'bottom', patterns: ['solid'], color: '#526457', color2: '#252525',",
"    build: (g, st) => shellPart(g, {",
"      // Plain shorts, without cargo pockets, belt, armour or accessories.",
"      covers: (v) => (isTrunk(v) && v.t < 0.24) || (v.region === REGION.upperleg && v.t < 0.55),",
"      offset: (v) => cm(0.6) + (v.region === REGION.upperleg ? cm(0.8) * v.t : 0),",
"      tile: 0.25,",
"    }, cloth(g, 'Simple survival shorts', st)),",
"  },"
]);

writeFileSync(path, source);
console.log('Added custom opaque sports_bra and plain survival_shorts garments.');
