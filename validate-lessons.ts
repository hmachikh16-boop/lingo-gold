import { STAGE_1A_LESSONS } from './src/data/expansion/stage1a';
import { STAGE_1B_LESSONS } from './src/data/expansion/stage1b';
import { STAGE_2A_LESSONS } from './src/data/expansion/stage2a';
import { STAGE_2B_LESSONS } from './src/data/expansion/stage2b';
import { STAGE_3A_LESSONS } from './src/data/expansion/stage3a';
import { STAGE_3B_LESSONS } from './src/data/expansion/stage3b';
import { STAGE_4A_LESSONS } from './src/data/expansion/stage4a';
import { STAGE_4B_LESSONS } from './src/data/expansion/stage4b';
import { STAGE_1_PLUS_LESSONS } from './src/data/expansionPlus/stage1';
import { STAGE_2_PLUS_LESSONS } from './src/data/expansionPlus/stage2';
import { STAGE_3_PLUS_LESSONS } from './src/data/expansionPlus/stage3';
import { STAGE_4_PLUS_LESSONS } from './src/data/expansionPlus/stage4';
import { STAGE_1_PLUS2_LESSONS } from './src/data/expansionPlus2/stage1';
import { STAGE_2_PLUS2_LESSONS } from './src/data/expansionPlus2/stage2';
import { STAGE_3_PLUS2_LESSONS } from './src/data/expansionPlus2/stage3';
import { STAGE_4_PLUS2_LESSONS } from './src/data/expansionPlus2/stage4';
import { STAGE_1_PLUS3_LESSONS } from './src/data/expansionPlus3/stage1';
import { STAGE_2_PLUS3_LESSONS } from './src/data/expansionPlus3/stage2';
import { STAGE_3_PLUS3_LESSONS } from './src/data/expansionPlus3/stage3';
import { STAGE_4_PLUS3_LESSONS } from './src/data/expansionPlus3/stage4';
import { STAGE_1_PLUS4_LESSONS } from './src/data/expansionPlus4/stage1';
import { STAGE_2_PLUS4_LESSONS } from './src/data/expansionPlus4/stage2';
import { STAGE_3_PLUS4_LESSONS } from './src/data/expansionPlus4/stage3';
import { STAGE_4_PLUS4_LESSONS } from './src/data/expansionPlus4/stage4';
import { STAGE_1_PLUS5_LESSONS } from './src/data/expansionPlus5/stage1';
import type { ExpansionLessonSpec } from './src/data/expansion/types';

const VALID_CATEGORIES = new Set(['greetings','travel','food','work','shopping','health','idioms','grammar']);
const VALID_SCENES = new Set(['cafe','airport','office','street','shop','clinic','park','classroom']);
const VALID_LEVELS = new Set(['A1','A2','B1','B2','C1']);

const all: ExpansionLessonSpec[] = [
  ...STAGE_1A_LESSONS, ...STAGE_1B_LESSONS,
  ...STAGE_2A_LESSONS, ...STAGE_2B_LESSONS,
  ...STAGE_3A_LESSONS, ...STAGE_3B_LESSONS,
  ...STAGE_4A_LESSONS, ...STAGE_4B_LESSONS,
  ...STAGE_1_PLUS_LESSONS, ...STAGE_2_PLUS_LESSONS, ...STAGE_3_PLUS_LESSONS, ...STAGE_4_PLUS_LESSONS,
  ...STAGE_1_PLUS2_LESSONS, ...STAGE_2_PLUS2_LESSONS, ...STAGE_3_PLUS2_LESSONS, ...STAGE_4_PLUS2_LESSONS,
  ...STAGE_1_PLUS3_LESSONS, ...STAGE_2_PLUS3_LESSONS, ...STAGE_3_PLUS3_LESSONS, ...STAGE_4_PLUS3_LESSONS,
  ...STAGE_1_PLUS4_LESSONS, ...STAGE_2_PLUS4_LESSONS, ...STAGE_3_PLUS4_LESSONS, ...STAGE_4_PLUS4_LESSONS,
  ...STAGE_1_PLUS5_LESSONS,
];

let total = 0, issues = 0;
const seenIds = new Set<string>();
const dupIds: string[] = [];
const issueList: any[] = [];

for (const spec of all) {
  total++;
  const errs: string[] = [];
  if (!spec.id) errs.push('missing id');
  if (seenIds.has(spec.id)) { errs.push('DUPLICATE id'); dupIds.push(spec.id); }
  seenIds.add(spec.id);
  if (![1,2,3,4].includes(spec.stage)) errs.push('bad stage ' + spec.stage);
  if (!VALID_LEVELS.has(spec.level)) errs.push('bad level ' + spec.level);
  if (!spec.title) errs.push('missing title');
  if (!spec.titleAr) errs.push('missing titleAr');
  if (!spec.descriptionAr) errs.push('missing descriptionAr');
  if (!spec.objectiveAr) errs.push('missing objectiveAr');
  if (!spec.structureEn) errs.push('missing structureEn');
  if (!spec.structureAr) errs.push('missing structureAr');
  if (!VALID_CATEGORIES.has(spec.category as any)) errs.push('bad category ' + spec.category);
  if (!VALID_SCENES.has(spec.scene as any)) errs.push('bad scene ' + spec.scene);
  if (!spec.openingEn) errs.push('missing openingEn');
  if (!spec.openingAr) errs.push('missing openingAr');
  if (!spec.closingEn) errs.push('missing closingEn');
  if (!spec.closingAr) errs.push('missing closingAr');
  if (!Array.isArray(spec.words) || spec.words.length !== 4) errs.push('words count ' + (spec.words?.length ?? 0));
  else {
    for (let i = 0; i < spec.words.length; i++) {
      const w = spec.words[i];
      if (!Array.isArray(w) || w.length < 5 || w.length > 6) { errs.push(`word ${i} bad tuple (len ${w?.length})`); continue; }
      const [word, pos, ar, exEn, exAr] = w as any;
      if (!word || !pos || !ar || !exEn || !exAr) errs.push(`word ${i} empty field`);
      if (word && exEn) {
        const wordTokens = String(word).toLowerCase().split(/\s+/).filter((t) => t.length > 2);
        const exLower = String(exEn).toLowerCase();
        const missing = wordTokens.filter((t) => !exLower.includes(t));
        if (missing.length) errs.push(`word ${i} "${word}" tokens [${missing.join(',')}] not in example`);
      }
    }
  }
  if (errs.length) {
    issues++;
    issueList.push({ id: spec.id, stage: spec.stage, errs });
  }
}

console.log('Total specs:', total);
console.log('Issues:', issues);
console.log('Duplicates:', dupIds.length, dupIds.slice(0, 10));
// Group issues by error type.
const byErr = new Map<string, number>();
for (const it of issueList) for (const e of it.errs) {
  const key = e.replace(/".*"/, '"..."');
  byErr.set(key, (byErr.get(key) ?? 0) + 1);
}
console.log('\nError type counts:');
for (const [k, v] of [...byErr.entries()].sort((a,b)=>b[1]-a[1])) console.log('  ', v, k);
console.log('\nFirst 20 issues:');
for (const it of issueList.slice(0, 20)) console.log(' ', it.id, '|', it.errs.join('; '));
import * as fs from 'fs';
fs.writeFileSync('C:/Users/hmach/AppData/Local/Temp/opencode/validation-issues.json', JSON.stringify(issueList, null, 2));
console.log('\nWrote validation-issues.json (' + issueList.length + ' issues)');
