import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { DEFAULT_PARAMS, type HumanParams } from '../src/core/params';
import { buildHuman } from '../src/core/human';
import { triangleCount } from '../src/core/mesh';
import { exportCharacter } from '../src/export';
import { nodeLibrary } from './node-assets';

type SkinRow = { id: string; params: Partial<HumanParams> };

const input = resolve(process.argv[2] ?? '../CharacterBuild/skins.json');
const output = resolve(process.argv[3] ?? '../Models/Characters');
const skins = JSON.parse(readFileSync(input, 'utf8')) as SkinRow[];
if (skins.length !== 8) throw new Error('Expected exactly 8 skins, got ' + skins.length);
mkdirSync(output, { recursive: true });
const library = await nodeLibrary();
const manifest: Record<string, { height_m: number; triangles: number; bytes: number; gender: string }> = {};

for (const row of skins) {
  console.log('Building ' + row.id + '...');
  const params: HumanParams = {
    ...DEFAULT_PARAMS,
    ...row.params,
    name: row.id,
    detail: 'medium',
    rig: 'game',
    faceBones: true,
    restPose: 'A',
    animations: true,
    faceShapes: true,
    speechShapes: false,
    vehicle: 'none',
    weapon: 'none',
    carry: 'none',
  };
  const character = await buildHuman(library, params, { onStage: (stage) => console.log('  ' + stage) });
  const exported = await exportCharacter(library, character, 'glb');
  const path = join(output, row.id + '.glb');
  writeFileSync(path, exported.data);
  const bytes = readFileSync(path).length;
  manifest[row.id] = {
    height_m: character.height,
    triangles: triangleCount(character.mesh),
    bytes,
    gender: Number(params.gender) < 0.5 ? 'female' : 'male',
  };
  console.log(row.id + ': ' + (character.height * 100).toFixed(1) + ' cm, ' + manifest[row.id].triangles + ' tris, ' + (bytes / 1024 / 1024).toFixed(2) + ' MB');
}

writeFileSync(join(output, 'manifest.json'), JSON.stringify({
  generator: 'Ara 3D Gen',
  anatomy_and_base_assets: 'MakeHuman CC0 1.0',
  player_target_height_m: 1.75,
  skins: manifest,
}, null, 2) + '\n');
console.log('All eight GLB characters and manifest exported.');
