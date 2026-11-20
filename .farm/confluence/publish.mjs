// Jednokierunkowa publikacja dokumentów z repo (docs/) do Confluence, przestrzeń Tamitu.
// Repo jest źródłem prawdy; strony w Confluence są czytelną kopią dla ludzi (CLAUDE.md, zasada 13).
//
//   node publish.mjs docs/adr/0002-....md [docs/...]   [--dry]
//
// Zmienne środowiskowe: ATLASSIAN_EMAIL, CONFLUENCE_TOKEN (lokalnie ustawia je publish.ps1
// z Menedżera poświadczeń; w CI - sekrety). Strony NIGDY nie są usuwane (tylko archiwizacja).
//
// Układy stron odtwarzają kod szablonów Confluence:
//   docs/adr/*                 -> „DACI: Decision documentation”
//   docs/requirements/US-*     -> „Product requirements”
//   docs/ux/components/*       -> „Design component”
//   pozostałe                  -> układ ogólny (baner, treść, historia)
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';
import MarkdownIt from 'markdown-it';

const SITE = 'https://tadecode.atlassian.net';
const SPACE_ID = '983044';
const REPO = 'https://github.com/tadecode/tamitu';
const PROP = 'tamitu-source';
const ROOT = execFileSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim();

// Folder -> strona sekcji (i podstrona dla podfolderu).
const SECTIONS = [
  { prefix: 'docs/requirements/', section: 'Wymagania' },
  { prefix: 'docs/adr/', section: 'ADR' },
  { prefix: 'docs/architecture/', section: 'Architektura' },
  { prefix: 'docs/data/', section: 'Architektura', sub: 'Model danych' },
  { prefix: 'docs/api/', section: 'Architektura', sub: 'API' },
  { prefix: 'docs/security/reviews/', section: 'Security', sub: 'Przeglądy bezpieczeństwa' },
  { prefix: 'docs/security/', section: 'Security' },
  { prefix: 'docs/ux/components/', section: 'UX', sub: 'Komponenty' },
  { prefix: 'docs/ux/screens/', section: 'UX', sub: 'Ekrany' },
  { prefix: 'docs/ux/', section: 'UX' },
];

const args = process.argv.slice(2);
const DRY = args.includes('--dry');
const files = args.filter((a) => !a.startsWith('--'));
const EMAIL = process.env.ATLASSIAN_EMAIL || 'farm-bot@tadecode.pl';
const TOKEN = process.env.CONFLUENCE_TOKEN;
if (!TOKEN && !DRY) throw new Error('Brak CONFLUENCE_TOKEN (lokalnie uruchom przez publish.ps1).');
const AUTH = 'Basic ' + Buffer.from(`${EMAIL}:${TOKEN}`).toString('base64');

// ---------- HTTP ----------
async function api(method, url, body) {
  const res = await fetch(url.startsWith('http') ? url : `${SITE}/wiki${url}`, {
    method,
    headers: { Authorization: AUTH, Accept: 'application/json', ...(body ? { 'Content-Type': 'application/json' } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${method} ${url}: ${res.status} ${text.slice(0, 500)}`);
  return text ? JSON.parse(text) : null;
}

// ---------- Markdown -> format Confluence (storage) ----------
const md = new MarkdownIt({ html: false, xhtmlOut: true, linkify: false, breaks: false });
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
md.renderer.rules.fence = (tokens, idx) => {
  const t = tokens[idx];
  const lang = (t.info || '').trim().split(/\s+/)[0];
  const code = t.content.replace(/]]>/g, ']]]]><![CDATA[>');
  return `<ac:structured-macro ac:name="code">${lang ? `<ac:parameter ac:name="language">${esc(lang)}</ac:parameter>` : ''}<ac:plain-text-body><![CDATA[${code}]]></ac:plain-text-body></ac:structured-macro>`;
};
md.renderer.rules.code_block = md.renderer.rules.fence;
let currentFile = '';
const defaultLink = md.renderer.rules.link_open || ((tokens, idx, options, env, self) => self.renderToken(tokens, idx, options));
md.renderer.rules.link_open = (tokens, idx, options, env, self) => {
  const href = tokens[idx].attrGet('href') || '';
  if (href && !/^[a-z]+:/i.test(href) && !href.startsWith('#')) {
    // Link względny do pliku w repo -> GitHub (gałąź main).
    const target = path.posix.normalize(path.posix.join(path.posix.dirname(currentFile), href.split('#')[0]));
    tokens[idx].attrSet('href', `${REPO}/blob/main/${target}`);
  }
  return defaultLink(tokens, idx, options, env, self);
};
const render = (text) => (text && text.trim() ? md.render(text.trim()) : '');
const inline = (text) => (text && text.trim() ? md.renderInline(text.trim()) : '');

// ---------- Makra Confluence ----------
const status = (title, colour) =>
  `<ac:structured-macro ac:name="status" ac:schema-version="1"><ac:parameter ac:name="title">${esc(title)}</ac:parameter>${colour ? `<ac:parameter ac:name="colour">${colour}</ac:parameter>` : ''}</ac:structured-macro>`;
const emo = (name, short, id) => `<ac:emoticon ac:name="${name}" ac:emoji-shortname=":${short}:" ac:emoji-id="${id}" />`;
const h2 = (emoji, text) => `<h2>${emoji}&nbsp;${esc(text)}</h2>`;
const panel = (kind, html) => `<ac:structured-macro ac:name="${kind}"><ac:rich-text-body>${html}</ac:rich-text-body></ac:structured-macro>`;
const E = {
  book: emo('blue-star', 'blue_book', '1f4d8'), books: emo('blue-star', 'books', '1f4da'), rainbow: emo('blue-star', 'rainbow', '1f308'),
  check: emo('blue-star', 'white_check_mark', '2705'), star: emo('blue-star', 'star2', '1f31f'), cal: emo('blue-star', 'calendar_spiral', '1f5d3'),
  yellow: emo('blue-star', 'yellow_circle', '1f7e1'), shirt: emo('blue-star', 'running_shirt_with_sash', '1f3bd'), art: emo('blue-star', 'art', '1f3a8'),
  box: emo('blue-star', 'card_box', '1f5c3'), dart: emo('blue-star', 'dart', '1f3af'), note: emo('blue-star', 'notepad_spiral', '1f5d2'),
  warn: emo('warning', 'warning', 'atlassian-warning'), question: emo('question', 'question_mark', 'atlassian-question_mark'),
  seed: emo('blue-star', 'seedling', '1f331'), monocle: emo('blue-star', 'face_with_monocle', '1f9d0'), ruler: emo('blue-star', 'triangular_ruler', '1f4d0'),
  clock: emo('blue-star', 'clock3', '1f552'), lock: emo('blue-star', 'lock', '1f512'),
};

// ---------- Parsowanie dokumentu ----------
// Zwraca: title, meta [{key, value}], intro (markdown przed pierwszym ##), sections [{title, body}]
function parseDoc(text) {
  const lines = text.replace(/\r\n/g, '\n').split('\n');
  let title = '';
  let i = 0;
  while (i < lines.length && !title) { const m = lines[i].match(/^#\s+(.+)/); if (m) title = m[1].trim(); i++; }
  const meta = [];
  const intro = [];
  const sections = [];
  let cur = null;
  for (; i < lines.length; i++) {
    const l = lines[i];
    const h = l.match(/^##\s+(.+)/);
    if (h) { cur = { title: h[1].trim(), body: [] }; sections.push(cur); continue; }
    if (cur) { cur.body.push(l); continue; }
    const m = l.match(/^-\s+([^:*]{2,40}):\s+(.*)$/);
    if (m) { meta.push({ key: m[1].trim(), value: m[2].trim() }); continue; }
    intro.push(l);
  }
  return { title, meta, intro: intro.join('\n').trim(), sections: sections.map((s) => ({ title: s.title, body: s.body.join('\n').trim() })) };
}
const metaGet = (doc, re) => doc.meta.find((m) => re.test(m.key))?.value;
const takeSection = (doc, re) => {
  const i = doc.sections.findIndex((s) => re.test(s.title));
  if (i < 0) return null;
  return doc.sections.splice(i, 1)[0];
};
const firstSentence = (mdText) => {
  const plain = (mdText || '').replace(/\|.*\|/g, '').replace(/[*_`#>]/g, '').replace(/\[([^\]]+)\]\([^)]+\)/g, '$1').replace(/\s+/g, ' ').trim();
  const m = plain.match(/^(.{20,260}?[.!?])(\s|$)/);
  return m ? m[1] : plain.slice(0, 260);
};

// ---------- Historia zmian z git ----------
function history(file) {
  let out = '';
  try { out = execFileSync('git', ['log', '--follow', '--format=%H%x09%as%x09%s', '--', file], { cwd: ROOT, encoding: 'utf8' }); } catch { return []; }
  return out.trim().split('\n').filter(Boolean).map((l) => {
    const [sha, date, subject] = l.split('\t');
    const pr = (subject.match(/\(#(\d+)\)\s*$/) || [])[1];
    return { sha, date, subject: subject.replace(/\s*\(#\d+\)\s*$/, ''), pr };
  });
}
function historySection(file) {
  const h = history(file);
  if (!h.length) return '';
  const rows = h.map((c) => `<tr><td><p>${c.date}</p></td><td><p>${c.pr ? `<a href="${REPO}/pull/${c.pr}">PR #${c.pr}</a>` : `<a href="${REPO}/commit/${c.sha}">${c.sha.slice(0, 7)}</a>`}</p></td><td><p>${esc(c.subject)}</p></td></tr>`).join('');
  return `${h2(E.clock, 'Historia zmian')}<p>Każda zmiana tego dokumentu przeszła przez pull request (PR) w repozytorium. Najnowsze na górze.</p>`
    + `<table data-layout="default"><colgroup><col style="width: 110.0px;" /><col style="width: 90.0px;" /><col style="width: 560.0px;" /></colgroup><tbody>`
    + `<tr><th data-highlight-colour="#f4f5f7"><p><strong>Data</strong></p></th><th data-highlight-colour="#f4f5f7"><p><strong>Zmiana</strong></p></th><th data-highlight-colour="#f4f5f7"><p><strong>Opis</strong></p></th></tr>${rows}</tbody></table>`;
}
const sourceBanner = (file) => panel('info', `<p>Ta strona jest automatyczną kopią pliku <a href="${REPO}/blob/main/${file}">${esc(file)}</a> z repozytorium Tamitu. <strong>Nie edytuj jej tutaj</strong> – zmiany wprowadza się w repozytorium (przez PR), a strona aktualizuje się sama po zatwierdzeniu.</p>`);
const restSections = (doc) => doc.sections.map((s) => `<h2>${esc(s.title)}</h2>${render(s.body)}`).join('');

// ---------- Układ: ADR (DACI: Decision documentation) ----------
function adrStatus(raw) {
  const s = (raw || '').toLowerCase();
  if (/zast[aą]pion|wycofan/.test(s)) return status('ZASTĄPIONY', 'Grey');
  if (/odrzucon/.test(s)) return status('ODRZUCONY', 'Red');
  if (/zatwierdzon|przyj[eę]t/.test(s)) return status('ZATWIERDZONY', 'Green');
  return status('PROPONOWANY', 'Yellow');
}
function layoutAdr(doc, file) {
  const statusRaw = metaGet(doc, /^status/i) || '';
  const approver = /właściciel/i.test(statusRaw) ? 'Właściciel produktu' : '–';
  const context = takeSection(doc, /^kontekst/i);
  const options = takeSection(doc, /opcje|warianty/i);
  const decision = takeSection(doc, /^decyzja/i);
  const consequences = takeSection(doc, /^konsekwencje/i);
  const th = (t) => `<th><p><strong>${esc(t)}</strong></p></th>`;
  const row = (t, v) => `<tr>${th(t)}<td>${v.startsWith('<') ? v : `<p>${v}</p>`}</td></tr>`;
  const others = doc.meta.filter((m) => !/^(status|data|autor|zadanie)/i.test(m.key));
  return sourceBanner(file)
    + `<ac:structured-macro ac:name="details"><ac:rich-text-body><table data-layout="default"><colgroup><col style="width: 149.0px;" /><col style="width: 577.0px;" /></colgroup><tbody>`
    + row('Status', `${adrStatus(statusRaw)} ${inline(statusRaw.replace(/^\s*\S+\s*/, ''))}`)
    + row('W skrócie', esc(firstSentence(decision?.body || doc.intro)))
    + row('Prowadzący', inline(metaGet(doc, /^autor/i) || '–'))
    + row('Zatwierdzający', esc(approver))
    + row('Data decyzji', inline(metaGet(doc, /^data/i) || '–'))
    + row('Zadania i źródła', inline(metaGet(doc, /^zadanie/i) || '–'))
    + `</tbody></table></ac:rich-text-body></ac:structured-macro>`
    + (context ? h2(E.book, 'Kontekst – dlaczego decydujemy') + render(context.body) : '')
    + (others.length || doc.intro ? h2(E.books, 'Ważne informacje') + render(doc.intro) + (others.length ? `<ul>${others.map((m) => `<li><p><strong>${esc(m.key)}:</strong> ${inline(m.value)}</p></li>`).join('')}</ul>` : '') : '')
    + (options ? h2(E.rainbow, 'Rozważane opcje') + render(options.body) : '')
    + (decision ? h2(E.star, 'Decyzja') + panel('tip', render(decision.body.split(/\n(?=###\s)/)[0])) + render(decision.body.split(/\n(?=###\s)/).slice(1).join('\n')) : '')
    + (consequences ? h2(E.check, 'Konsekwencje') + render(consequences.body) : '')
    + restSections(doc)
    + historySection(file);
}

// ---------- Układ: wymaganie (Product requirements) ----------
function gwt(line) {
  const t = line.replace(/^\s*[-*]\s*/, '');
  const m = t.match(/\*\*Given\*\*\s*(.*?)\s*(?:\*\*When\*\*\s*(.*?)\s*)?\*\*Then\*\*\s*(.*)$/i);
  return m ? { given: m[1], when: m[2] || '–', then: m[3] } : null;
}
function layoutRequirement(doc, file) {
  const crit = takeSection(doc, /kryteria/i);
  const scope = takeSection(doc, /poza zakresem|uwagi/i);
  const questions = takeSection(doc, /pytania/i);
  const thc = (t, colour) => `<th${colour ? ` data-highlight-colour="${colour}"` : ''}><p><strong>${esc(t)}</strong></p></th>`;
  const metaRows = doc.meta.map((m) => {
    const isPrio = /priorytet/i.test(m.key);
    const icon = isPrio ? E.yellow : /dane osobowe/i.test(m.key) ? E.lock : E.shirt;
    const val = isPrio ? status(m.value, 'Blue') : inline(m.value);
    return `<tr><th><p>${icon}&nbsp;<strong>${esc(m.key)}</strong></p></th><td><p>${val}</p></td></tr>`;
  }).join('');
  const id = (doc.title.match(/^(US-\d+)/) || [])[1] || '';
  const jira = `${SITE}/issues/?jql=${encodeURIComponent(`project = TAM AND text ~ "${id}"`)}`;
  let critHtml = '';
  if (crit) {
    const items = crit.body.split('\n').map(gwt).filter(Boolean);
    critHtml = h2(E.note, 'Kryteria akceptacji – kiedy uznajemy, że działa')
      + (items.length
        ? `<table data-layout="default"><colgroup><col style="width: 40.0px;" /><col style="width: 230.0px;" /><col style="width: 230.0px;" /><col style="width: 260.0px;" /></colgroup><tbody><tr>${thc('#', '#deebff')}${thc('Gdy… (sytuacja)', '#deebff')}${thc('Kiedy… (działanie)', '#deebff')}${thc('Wtedy… (oczekiwany wynik)', '#deebff')}</tr>`
          + items.map((x, n) => `<tr><td><p>${n + 1}</p></td><td><p>${inline(x.given)}</p></td><td><p>${inline(x.when)}</p></td><td><p>${inline(x.then)}</p></td></tr>`).join('') + '</tbody></table>'
        : render(crit.body));
  }
  return sourceBanner(file)
    + `<table data-layout="default"><colgroup><col style="width: 189.0px;" /><col style="width: 536.0px;" /></colgroup><tbody>`
    + `<tr><th colspan="2"><p style="text-align: center;"><strong>Przegląd</strong></p></th></tr>${metaRows}`
    + `<tr><th colspan="2"><p style="text-align: center;"><strong>Szybkie linki</strong></p></th></tr>`
    + `<tr><th><p>${E.art}&nbsp;<strong>Ekrany i przepływy</strong></p></th><td><p><a href="${REPO}/blob/main/docs/requirements/screens-and-flows.md">screens-and-flows.md</a></p></td></tr>`
    + `<tr><th><p>${E.box}&nbsp;<strong>Zadania w Jirze</strong></p></th><td><p><a href="${jira}">Zadania powiązane z ${esc(id || doc.title)}</a></p></td></tr>`
    + `</tbody></table>`
    + h2(E.dart, 'Cel – czego potrzebuje użytkownik') + render(doc.intro)
    + critHtml
    + (scope ? h2(E.warn, 'Poza zakresem i uwagi') + render(scope.body) : '')
    + (questions ? h2(E.question, 'Pytania') + render(questions.body) : '')
    + restSections(doc)
    + historySection(file);
}

// ---------- Układ: komponent UX (Design component) ----------
function layoutComponent(doc, file) {
  const pick = (re) => takeSection(doc, re)?.body || '';
  const cel = pick(/^cel/i), warianty = pick(/warianty/i), stany = pick(/stany/i), zach = pick(/zachowanie/i);
  const rozm = pick(/rozmiar|odst/i), tokeny = pick(/tokeny|styl/i), teksty = pick(/teksty|tre[sś][cć]/i);
  const dost = pick(/dost[eę]pno/i), uzycie = pick(/u[zż]ycie/i), praktyki = pick(/praktyk|zasady/i), powiazane = pick(/powi[aą]zane/i);
  const cell = (label, colour, body) => `<tr><td data-highlight-colour="${colour}"><p><strong>${esc(label)}</strong></p></td><td>${body || '<p>–</p>'}</td></tr>`;
  const tbl = (rows, w1 = 120) => `<table data-layout="default"><colgroup><col style="width: ${w1}.0px;" /><col style="width: ${760 - w1}.0px;" /></colgroup><tbody>${rows}</tbody></table>`;
  const statusRaw = metaGet(doc, /^status/i);
  return sourceBanner(file)
    + h2(E.seed, 'Podstawy')
    + tbl(cell('Nazwa', '#e3fcef', `<p>${esc(doc.title.replace(/^Komponent:\s*/i, ''))}</p>`)
      + cell('Status', '#e3fcef', `<p>${statusRaw ? status(statusRaw, /zatwierdz/i.test(statusRaw) ? 'Green' : 'Yellow') : '–'} ${inline(metaGet(doc, /^autor/i) || '')}</p>`)
      + cell('Opis', '#e3fcef', render(cel))
      + cell('Odpowiednik we Flutterze', '#e3fcef', `<p>${inline(metaGet(doc, /odpowiednik/i) || '–')}</p>`))
    + h2(E.monocle, 'Specyfikacja')
    + tbl(cell('Użycie', '#e6fcff', render(uzycie)) + cell('Warianty', '#e6fcff', render(warianty)) + cell('Stany', '#e6fcff', render(stany))
      + cell('Zachowanie', '#e6fcff', render(zach)) + cell('Styl', '#e6fcff', render([tokeny, rozm && `**Rozmiary i odstępy.** ${rozm}`].filter(Boolean).join('\n\n'))))
    + h2(E.ruler, 'Wskazówki')
    + tbl(cell('Teksty', '#fffae6', render(teksty)) + cell('Dostępność', '#fffae6', render(dost))
      + (praktyki ? cell('Dobre praktyki', '#fffae6', render(praktyki)) : '') + (powiazane ? cell('Powiązane', '#fffae6', render(powiazane)) : ''))
    + restSections(doc)
    + historySection(file);
}

function layoutGeneric(doc, file) {
  const meta = doc.meta.length ? `<table data-layout="default"><tbody>${doc.meta.map((m) => `<tr><th data-highlight-colour="#f4f5f7"><p><strong>${esc(m.key)}</strong></p></th><td><p>${inline(m.value)}</p></td></tr>`).join('')}</tbody></table>` : '';
  return sourceBanner(file) + meta + render(doc.intro) + restSections(doc) + historySection(file);
}

function layoutFor(file) {
  if (file.startsWith('docs/adr/')) return layoutAdr;
  if (/^docs\/requirements\/US-\d+/.test(file)) return layoutRequirement;
  if (file.startsWith('docs/ux/components/')) return layoutComponent;
  return layoutGeneric;
}

// ---------- Strony ----------
const childCache = new Map();
async function childrenOf(parentId) {
  if (childCache.has(parentId)) return childCache.get(parentId);
  const out = [];
  let url = `/api/v2/pages/${parentId}/children?limit=250`;
  while (url) { const r = await api('GET', url); out.push(...r.results); url = r._links?.next ? r._links.next.replace(/^\/wiki/, '') : null; }
  childCache.set(parentId, out);
  return out;
}
async function ensureChild(parentId, title, description) {
  const hit = (await childrenOf(parentId)).find((p) => p.title === title);
  if (hit) return hit.id;
  if (DRY) return `(nowa: ${title})`;
  const r = await api('POST', '/api/v2/pages', { spaceId: SPACE_ID, status: 'current', title, parentId, body: { representation: 'storage', value: `<p>${esc(description)}</p>` } });
  (await childrenOf(parentId)).push(r);
  return r.id;
}
let spaceCache = null;
async function parentFor(file) {
  const rule = SECTIONS.find((s) => file.startsWith(s.prefix));
  if (!rule) throw new Error(`Plik ${file} nie należy do żadnej sekcji.`);
  const space = spaceCache || (spaceCache = await api('GET', `/api/v2/spaces/${SPACE_ID}`));
  const section = (await childrenOf(space.homepageId)).find((p) => p.title === rule.section);
  if (!section) throw new Error(`Brak strony sekcji „${rule.section}”.`);
  return rule.sub ? ensureChild(section.id, rule.sub, `Podstrona sekcji ${rule.section}: ${rule.sub}.`) : section.id;
}
// Strony opublikowane z repo rozpoznajemy po właściwości `tamitu-source` (ścieżka pliku), nie po tytule.
const propCache = new Map();
async function sourceProp(pageId) {
  if (!propCache.has(pageId)) {
    let prop = null;
    try { prop = (await api('GET', `/api/v2/pages/${pageId}/properties?key=${PROP}`)).results?.[0] || null; } catch { /* brak */ }
    propCache.set(pageId, prop);
  }
  return propCache.get(pageId);
}
async function findBySource(parentId, file) {
  for (const p of await childrenOf(parentId)) {
    const prop = await sourceProp(p.id);
    if (prop?.value?.path === file) return { page: p, prop };
  }
  return null;
}

async function publish(file) {
  currentFile = file;
  const text = fs.readFileSync(path.join(ROOT, file), 'utf8');
  const doc = parseDoc(text);
  const body = layoutFor(file)(doc, file);
  const hash = crypto.createHash('sha256').update(body).digest('hex').slice(0, 16);
  const title = doc.title || path.basename(file, '.md');
  if (DRY) { fs.writeFileSync(path.join(process.env.TEMP || '/tmp', path.basename(file) + '.storage.xml'), body); console.log(`[dry] ${file} -> „${title}” (${body.length} zn.)`); return; }
  const parentId = await parentFor(file);
  const found = await findBySource(parentId, file);
  if (!found) {
    let p;
    try {
      p = await api('POST', '/api/v2/pages', { spaceId: SPACE_ID, status: 'current', title, parentId, body: { representation: 'storage', value: body } });
    } catch (e) {
      // Tytuły w przestrzeni muszą być unikalne: przy kolizji dopisujemy nazwę pliku.
      if (!/title|already exists/i.test(e.message)) throw e;
      p = await api('POST', '/api/v2/pages', { spaceId: SPACE_ID, status: 'current', title: `${title} (${path.basename(file, '.md')})`, parentId, body: { representation: 'storage', value: body } });
    }
    await api('POST', `/api/v2/pages/${p.id}/properties`, { key: PROP, value: { path: file, hash } });
    (await childrenOf(parentId)).push(p);
    console.log(`nowa   ${file} -> ${SITE}/wiki/spaces/TAM/pages/${p.id}`);
    return;
  }
  if (found.prop.value.hash === hash && found.page.title === title) { console.log(`bez zmian ${file}`); return; }
  const page = await api('GET', `/api/v2/pages/${found.page.id}`);
  await api('PUT', `/api/v2/pages/${page.id}`, { id: page.id, status: 'current', title, body: { representation: 'storage', value: body }, version: { number: page.version.number + 1, message: 'Publikacja z repo' } });
  await api('PUT', `/api/v2/pages/${page.id}/properties/${found.prop.id}`, { key: PROP, value: { path: file, hash }, version: { number: found.prop.version.number + 1 } });
  console.log(`zmiana ${file} -> ${SITE}/wiki/spaces/TAM/pages/${page.id}`);
}

let failed = 0;
for (const f of files) {
  try { await publish(f.replace(/\\/g, '/')); }
  catch (e) { failed++; console.error(`BŁĄD   ${f}: ${e.message}`); }
}
if (failed) { console.error(`Nieudane: ${failed}`); process.exitCode = 1; }
