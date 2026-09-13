'use strict';

const { When, Then } = require('@cucumber/cucumber');
const { MiniCex, ApiUnreachable } = require('../venues/minicex');

/**
 * API-tier steps for features/be-cex-api.feature. The account and action steps
 * (deposit, transfer, swap, bridge) are shared from be/db/steps/cex.steps.js;
 * here are the read-only calls and the assertions on the HTTP response itself.
 * A transport failure grades Blocked; a 4xx/5xx is an answer under test.
 */

const cex = new MiniCex();
const coin = (n) => Math.round(Number(n) * 1e8);
const acctOf = (world, alias) => world.accounts[alias];

async function act(world, fn) {
  if (world.sourceError) return;
  try { await fn(); } catch (err) { if (err instanceof ApiUnreachable) { world.sourceError = err.message; return; } throw err; }
}
function assert(world, description, cond, detail) {
  if (world.sourceError) { world.unobservable(description, 'the source could not be reached -- ' + world.sourceError); return; }
  world.check(description, cond, detail);
}

// ---------------------------------------------------------------- read-only actions

When('the assets are read', async function () { await act(this, async () => { this.api = await cex.get('/assets'); }); });
When('the pairs are read', async function () { await act(this, async () => { this.api = await cex.get('/pairs'); }); });
When('a quote of {float} {word} to {word} is requested', async function (amt, from, to) {
  await act(this, async () => { this.api = await cex.quote(from, to, coin(amt)); this.quote = this.api.body; });
});
When('a fresh account {string} is created', async function (alias) {
  await act(this, async () => { const handle = alias + '-' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6); this.api = await cex.post('/accounts', { handle }); if (this.api.status === 201) this.accounts[alias] = this.api.body; });
});
When('an account is created with the same handle as {string}', async function (alias) {
  await act(this, async () => { this.api = await cex.post('/accounts', { handle: acctOf(this, alias).handle }); });
});
When('a deposit is attempted with no token', async function () {
  await act(this, async () => { this.api = await cex.post('/deposit', { asset: 'BTC', amount: coin(1) }); });
});

// ---------------------------------------------------------------- response assertions

Then('the response status is {int}', function (code) {
  assert(this, 'response status ' + code, this.api && this.api.status === code, this.api ? 'got ' + this.api.status + ' ' + (this.api.text || '').slice(0, 120) : 'no response');
});
Then('the response code is {string}', function (code) {
  assert(this, 'response code ' + code, this.api && this.api.body && this.api.body.code === code, this.api && this.api.body ? 'got ' + this.api.body.code : 'no body');
});
Then('the response has a token', function () {
  assert(this, 'response has token', this.api && this.api.body && typeof this.api.body.token === 'string' && this.api.body.token.length > 0, this.api && this.api.body ? JSON.stringify(this.api.body).slice(0, 80) : 'no body');
});
Then('the asset list includes {word}, {word}, {word}, {word}', function (a, b, c, d) {
  const have = new Set((this.api.body.assets || []).map((x) => x.symbol));
  const want = [a, b, c, d];
  assert(this, 'asset list includes ' + want.join(','), want.every((s) => have.has(s)), 'have ' + [...have].join(','));
});
Then('every listed asset has a name and a USD price', function () {
  const bad = (this.api.body.assets || []).filter((x) => !x.name || typeof x.usd_micro !== 'number');
  assert(this, 'assets have name + price', bad.length === 0 && (this.api.body.assets || []).length > 0, bad.length + ' incomplete');
});
Then('the pair list includes {word}\\/{word} and {word}\\/{word}', function (b1, q1, b2, q2) {
  const set = new Set((this.api.body.pairs || []).map((p) => p.base + '/' + p.quote));
  assert(this, 'pair list includes', set.has(b1 + '/' + q1) && set.has(b2 + '/' + q2), [...set].join(' '));
});
Then('no pair has the same asset on both legs', function () {
  const bad = (this.api.body.pairs || []).filter((p) => p.base === p.quote);
  assert(this, 'pairs have distinct legs', bad.length === 0, bad.length + ' bad');
});
Then('the quote net equals the gross minus the fee', function () {
  const q = this.quote;
  assert(this, 'quote net = gross - fee', q && q.to_amount === q.gross_amount - q.fee_amount, q ? `net ${q.to_amount}, gross ${q.gross_amount}, fee ${q.fee_amount}` : 'no quote');
});
Then('the quote fee matches the pair fee in basis points', function () {
  const q = this.quote;
  const expected = Math.floor((q.gross_amount * q.fee_bps) / 10000);
  assert(this, 'quote fee matches bps', q.fee_amount === expected, `fee ${q.fee_amount}, expected ${expected} at ${q.fee_bps}bps`);
});
Then('the API balance for {string} in {word} is {float} {word}', async function (alias, asset, amt, _a) {
  await act(this, async () => {
    const r = await cex.get('/balances/' + acctOf(this, alias).handle);
    const row = (r.body.balances || []).find((x) => x.asset === asset);
    const got = row ? row.amount : 0;
    assert(this, `API balance ${alias}/${asset}`, got === coin(amt), `got ${got}, want ${coin(amt)}`);
  });
});
Then('the API balance for {string} in {word} is above zero', async function (alias, asset) {
  await act(this, async () => {
    const r = await cex.get('/balances/' + acctOf(this, alias).handle);
    const row = (r.body.balances || []).find((x) => x.asset === asset);
    assert(this, `API balance ${alias}/${asset} > 0`, !!row && row.amount > 0, row ? ('got ' + row.amount) : 'no ' + asset + ' row');
  });
});
Then('the swap response output equals the quote for {float} {word} to {word}', async function (amt, from, to) {
  await act(this, async () => {
    const q = await cex.quote(from, to, coin(amt));
    assert(this, 'swap output == quote', this.api.body && this.api.body.to_amount === q.body.to_amount, `swap ${this.api.body && this.api.body.to_amount}, quote ${q.body.to_amount}`);
  });
});
Then('the second deposit was an idempotent replay', function () {
  assert(this, 'deposit idempotent replay', this.api && this.api.body && this.api.body.idempotent_replay === true, this.api && this.api.body ? JSON.stringify(this.api.body).slice(0, 80) : 'no body');
});
Then('the second bridge deposit was an idempotent replay', function () {
  assert(this, 'bridge deposit idempotent replay', this.api && this.api.body && this.api.body.idempotent_replay === true, this.api && this.api.body ? JSON.stringify(this.api.body).slice(0, 80) : 'no body');
});
Then('the bridge op is in status {string}', function (status) {
  assert(this, 'bridge op status ' + status, this.lastBridge && this.lastBridge.status === status, this.lastBridge ? 'got ' + this.lastBridge.status : 'no bridge op');
});
