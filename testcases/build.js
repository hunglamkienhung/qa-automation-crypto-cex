'use strict';

/**
 * Build fixtures/testcases.json (and TestCases.md) from the feature files.
 *
 * The features are the single source of truth: every scenario carries @case:N,
 * a feature carries @module/@be|@fe/@db|@api|@bot and a target tag, and a
 * Scenario Outline carries one @case per Examples block. This walks them and
 * emits one catalogue entry per @case, so the catalogue can never drift from
 * what actually runs.
 *
 *   node testcases/build.js            write the files
 *   node testcases/build.js --check    exit non-zero if they are stale
 */

const fs = require('fs');
const path = require('path');

const HERE = __dirname;
const FEATURES = path.join(HERE, '..', 'features');
const FIXTURE = path.join(HERE, '..', 'fixtures', 'testcases.json');
const MD = path.join(HERE, 'TestCases.md');
const CHECK = process.argv.includes('--check');

const LAYER = (tags) => {
  const be = tags.has('@be');
  if (tags.has('@db')) return 'BE/DB';
  if (tags.has('@api')) return 'BE/API';
  if (tags.has('@bot')) return 'BE/BOT';
  if (tags.has('@fe')) return 'FE/UI';
  return be ? 'BE' : 'FE';
};
const TIER = (tags) => {
  for (const t of tags) if (t.startsWith('@tier:')) return t.slice(6);
  if (tags.has('@minicex') && tags.has('@security')) return 'minicex-security';
  if (tags.has('@minicex') && tags.has('@db')) return 'minicex-db';
  if (tags.has('@minicex') && tags.has('@api')) return 'minicex-api';
  if (tags.has('@kraken') && tags.has('@api')) return 'kraken-api';
  if (tags.has('@bot')) return 'bot';
  if (tags.has('@minicex') && tags.has('@fe')) return 'minicex-fe';
  return 'unknown';
};
const MODULE = (tags) => { for (const t of tags) if (t.startsWith('@module:')) return t.slice(8); return 'misc'; };
const PRIORITY = (tags) => { for (const t of tags) if (t.startsWith('@priority:')) return t.slice(10)[0].toUpperCase() + t.slice(11); return 'Medium'; };
const tagsOf = (line) => new Set((line.match(/@[\w:.-]+/g) || []));
const moduleTitle = (m) => m.replace(/^\d+-/, '').replace(/-/g, ' ');

function parseFeature(file) {
  const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/);
  let featureTags = new Set();
  let pending = new Set();
  let scenario = null;
  let inExamples = false;
  const cases = [];
  const emit = (id, sc, extraTags) => {
    const tags = new Set([...featureTags, ...sc.tags, ...(extraTags || [])]);
    cases.push({ id: Number(id), module: MODULE(tags), moduleTitle: moduleTitle(MODULE(tags)), layer: LAYER(tags), tier: TIER(tags), title: sc.name, priority: PRIORITY(tags), steps: sc.steps.slice() });
  };
  const flushPlain = () => { if (scenario && scenario.plainCase) emit(scenario.plainCase, scenario); };

  for (const raw of lines) {
    const line = raw.trim();
    if (line.startsWith('@')) { for (const t of tagsOf(line)) pending.add(t); continue; }
    if (line.startsWith('Feature:')) { featureTags = new Set(pending); pending = new Set(); continue; }
    if (line.startsWith('Scenario Outline:') || line.startsWith('Scenario:')) {
      flushPlain();
      scenario = { name: line.replace(/^Scenario( Outline)?:\s*/, ''), steps: [], tags: new Set(pending), plainCase: null, outline: line.startsWith('Scenario Outline:') };
      for (const t of pending) { const m = /^@case:(\d+)$/.exec(t); if (m) scenario.plainCase = m[1]; }
      pending = new Set(); inExamples = false; continue;
    }
    if (line.startsWith('Background:')) { scenario = null; pending = new Set(); continue; }
    if (line.startsWith('Examples:')) { inExamples = true;
      for (const t of pending) { const m = /^@case:(\d+)$/.exec(t); if (m && scenario) emit(m[1], scenario); }
      pending = new Set(); continue; }
    if (!scenario) { pending = new Set(); continue; }
    if (inExamples) continue;
    if (/^(Given|When|Then|And|But)\b/.test(line)) { scenario.steps.push(line); }
  }
  flushPlain();
  return cases;
}

function main() {
  const files = fs.readdirSync(FEATURES).filter((f) => f.endsWith('.feature')).sort();
  let all = [];
  for (const f of files) all = all.concat(parseFeature(path.join(FEATURES, f)));
  all.sort((a, b) => a.id - b.id);

  const seen = new Set();
  for (const c of all) { if (seen.has(c.id)) throw new Error('duplicate @case:' + c.id); seen.add(c.id); }

  const cases = {};
  for (const c of all) cases[String(c.id)] = { module: c.module, layer: c.layer, tier: c.tier, title: c.title, priority: c.priority, steps: c.steps };
  const nextId = all.length ? Math.max(...all.map((c) => c.id)) + 1 : 1;
  const fixture = {
    meta: {
      domain: 'crypto-cex',
      targets: {
        'minicex-db': 'mini-cex SQLite, written by the service (be/db, both stacks open the same file)',
        'minicex-api': 'mini-cex REST over that SQLite (be/api)',
        'kraken-api': 'Kraken public API, read-only, no key (be/api)',
        bot: 'the pure risk gate (be/bot, no network)',
        'minicex-fe': 'mini-cex HTML pages (Playwright)',
      },
      idPolicy: 'immutable',
      nextId,
      note: 'Generated from features/*.feature by testcases/build.js. Every scenario carries @case:N; an N missing here is an error.',
    },
    cases,
  };

  const md = renderMd(all);
  const jsonText = JSON.stringify(fixture, null, 2) + '\n';
  if (CHECK) {
    const stale = [];
    if (!fs.existsSync(FIXTURE) || fs.readFileSync(FIXTURE, 'utf8') !== jsonText) stale.push('fixtures/testcases.json');
    if (!fs.existsSync(MD) || fs.readFileSync(MD, 'utf8') !== md) stale.push('testcases/TestCases.md');
    if (stale.length) { console.error('stale: ' + stale.join(', ') + ' -- run node testcases/build.js'); process.exit(1); }
    console.log('testcases up to date: ' + all.length + ' cases');
    return;
  }
  fs.mkdirSync(path.dirname(FIXTURE), { recursive: true });
  fs.writeFileSync(FIXTURE, jsonText);
  fs.writeFileSync(MD, md);
  const byTier = {};
  for (const c of all) byTier[c.tier] = (byTier[c.tier] || 0) + 1;
  console.log(all.length + ' cases; nextId ' + nextId + '; ' + JSON.stringify(byTier));
}

function renderMd(rows) {
  const out = ['# Crypto CEX — test cases', '', `${rows.length} cases across a self-written mini-cex (with a real SQLite database) and the live Kraken public API. Generated from \`../features/*.feature\` by \`build.js\`; do not edit by hand.`, ''];
  const tiers = [...new Set(rows.map((r) => r.tier))];
  for (const tier of tiers) {
    const group = rows.filter((r) => r.tier === tier);
    out.push('## ' + tier + ' (' + group.length + ')', '', '| ID | Layer | Priority | Title |', '|---|---|---|---|');
    for (const c of group) out.push(`| ${c.id} | ${c.layer} | ${c.priority} | ${c.title.replace(/\|/g, '\\|')} |`);
    out.push('');
  }
  return out.join('\n');
}

main();
