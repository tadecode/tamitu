// QA PR #142: compare the 6 keys x PL/EN in lib/l10n/*.arb with the owner-approved table.
// Run from the PR checkout root: node <this file> <path to 0948-architect-TAM-93.md> <dir with old_pl.arb/old_en.arb from main>
const fs=require('fs');const [,,log,S]=process.argv;
const rows={};for(const l of fs.readFileSync(log,'utf8').split(/\r?\n/)){const m=l.match(/^\| `(\w+)` \((?:zmiana|nowy)\) \| [^|]+\| (.+?) \| (.+?) \|$/);if(m)rows[m[1]]=[m[2],m[3]];}
const pl=JSON.parse(fs.readFileSync('lib/l10n/app_pl.arb','utf8')),en=JSON.parse(fs.readFileSync('lib/l10n/app_en.arb','utf8'));
let ok=0;for(const [k,[p,e]] of Object.entries(rows))for(const [lang,arb,exp] of [['pl',pl,p],['en',en,e]]){const r=arb[k]===exp;ok+=r;console.log(r?'OK  ':'DIFF',lang,k,exp.length,r?'':JSON.stringify(arb[k]));}
console.log('total',ok,'/',2*Object.keys(rows).length);
for(const [lang,cur] of [['pl',pl],['en',en]]){const old=JSON.parse(fs.readFileSync(`${S}/old_${lang}.arb`,'utf8'));const ks=new Set([...Object.keys(old),...Object.keys(cur)]);console.log(lang,'changed:',[...ks].filter(k=>!k.startsWith('@')&&old[k]!==cur[k]).join(', '));}
