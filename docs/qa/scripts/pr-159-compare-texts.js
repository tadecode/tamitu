// QA PR #159: compares the "Teksty" table of docs/ux/screens/ek-07-ai-busy.md with lib/l10n/app_{pl,en}.arb.
// Usage: node pr-159-compare-texts.js <spec.md> <dir with app_pl.arb and app_en.arb>
const fs = require('fs'), path = require('path');
const [spec, arbDir] = process.argv.slice(2);
const md = fs.readFileSync(spec, 'utf8');
const sec = md.split('## Teksty')[1].split('\n## ')[0];
const rows = sec.split('\n').filter(l => /^\| `\w+` \|/.test(l));
const pl = JSON.parse(fs.readFileSync(path.join(arbDir, 'app_pl.arb'), 'utf8'));
const en = JSON.parse(fs.readFileSync(path.join(arbDir, 'app_en.arb'), 'utf8'));
let fail = 0;
for (const r of rows) {
  const cells = r.replace(/^\| /, '').replace(/ \|\s*$/, '').split(' | ');
  const key = cells[0].replace(/`/g, '');
  for (const [lang, want, arb] of [['PL', cells[1], pl], ['EN', cells[2], en]]) {
    const ok = arb[key] === want;
    if (!ok) fail++;
    console.log(`${ok ? 'OK  ' : 'DIFF'} ${key} ${lang}` + (ok ? '' : `\n  spec: ${want}\n  arb:  ${arb[key]}`));
  }
}
console.log(`${rows.length} keys x 2 langs, ${fail} differences`);
process.exit(fail ? 1 : 0);
