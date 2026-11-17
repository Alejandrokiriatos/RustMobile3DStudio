import { readFileSync, writeFileSync } from 'node:fs';

const path = 'src/core/garments/catalog.ts';
let source = readFileSync(path, 'utf8');

function insertBefore(anchorId, newId, lines) {
  if (source.includes("id: '" + newId + "'")) return;
  const marker = "  {\n    id: '" + anchorId + "'";
  const at = source.indexOf(marker);
  if (at < 0) throw new Error('Cannot locate insertion point for ' + anchorId);
  source = source.slice(0, at) + lines.join('\n') + '\n' + source.slice(at);
}

insertBefore('fatigue_shirt', 'sports_bra', [
"  {",
"    id: 'sports_bra', label: 'Sports bra', slot: 'top', patterns: ['solid'], color: '#526c59', color2: '#252525',",
"    build: (g, st) => {",
"      const sx = g.body.L.shoulderX;",
"      return shellPart(g, {",
"        // Fully opaque fitted chest coverage, with shoulder straps and a free abdomen.",
"        covers: (v) => (isTrunk(v) && v.tt >= 0.52 && v.tt < 0.92) ||",
"          (v.region === REGION.upperarm && v.t < 0.11 && Math.abs(v.ax - 0.60 * sx) < 0.22 * sx),",
"        offset: cm(0.85), tile: 0.2, relax: 5,",
"      }, cloth(g, 'Sports bra', st));",
"    },",
"  },"
]);

insertBefore('fatigue_pants', 'survival_shorts', [
"  {",
"    id: 'survival_shorts', label: 'Simple survival shorts', slot: 'bottom', patterns: ['solid'], color: '#526457', color2: '#252525',",
"    build: (g, st) => shellPart(g, {",
"      // Plain shorts with real thigh coverage; no cargo pockets, belt or armour.",
"      covers: (v) => (isTrunk(v) && v.t < 0.24) || (v.region === REGION.upperleg && v.t < 0.55),",
"      offset: (v) => cm(0.6) + (v.region === REGION.upperleg ? cm(0.8) * v.t : 0),",
"      tile: 0.25, relax: 4,",
"    }, cloth(g, 'Simple survival shorts', st)),",
"  },"
]);

for (const required of ["id: 'sports_bra'", "id: 'survival_shorts'"]) {
  if (!source.includes(required)) throw new Error('Required garment was not registered: ' + required);
}
writeFileSync(path, source);
console.log('Registered and verified opaque sports_bra and simple survival_shorts garments.');
