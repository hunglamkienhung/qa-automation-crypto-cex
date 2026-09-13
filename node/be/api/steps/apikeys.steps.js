'use strict';

const { Given, When, Then } = require('@cucumber/cucumber');
const { MiniCex, ApiUnreachable } = require('../venues/minicex');

/**
 * Steps for features/be-cex-apikeys.feature. Keys are minted with the owner's
 * Bearer token, then used via the X-API-Key header; the scope gates what they
 * can do and the rate limit throttles them. The account/deposit steps are
 * shared from cex.steps.js; the response assertions from minicex.steps.js.
 */

const cex = new MiniCex();
const coin = (n) => Math.round(Number(n) * 1e8);
const acctOf = (world, alias) => world.accounts[alias];
const SELL = { base: 'BTC', quote: 'USD', side: 'sell', type: 'limit', price: coin(60000), size: coin(0.5) };

async function act(world, fn) {
  if (world.sourceError) return;
  try { await fn(); } catch (err) { if (err instanceof ApiUnreachable) { world.sourceError = err.message; return; } throw err; }
}

Given('{string} holds a {string} API key', async function (alias, scope) {
  await act(this, async () => { const r = await cex.createKey(acctOf(this, alias).token, scope); this.currentKey = { key: r.body.key, owner: acctOf(this, alias).token }; });
});
Given('{string} holds a {string} API key limited to {int} per minute', async function (alias, scope, rate) {
  await act(this, async () => { const r = await cex.createKey(acctOf(this, alias).token, scope, rate); this.currentKey = { key: r.body.key, owner: acctOf(this, alias).token }; });
});
Given('the key is revoked', async function () {
  await act(this, async () => { await cex.revokeKey(this.currentKey.owner, this.currentKey.key); });
});

When('{string} mints a {string} API key', async function (alias, scope) {
  await act(this, async () => { this.api = await cex.createKey(acctOf(this, alias).token, scope); });
});
When('the key places a limit sell of {float} {word} at {float} {word}', async function (size, base, price, quote) {
  await act(this, async () => { this.api = await cex.requestWithKey('POST', '/orders', this.currentKey.key, { base, quote, side: 'sell', type: 'limit', price: coin(price), size: coin(size) }); });
});
When('an unknown key places a limit sell of {float} {word} at {float} {word}', async function (size, base, price, quote) {
  await act(this, async () => { this.api = await cex.requestWithKey('POST', '/orders', 'key_nope', { base, quote, side: 'sell', type: 'limit', price: coin(price), size: coin(size) }); });
});
When('the key withdraws {float} {word}', async function (amt, asset) {
  await act(this, async () => { this.api = await cex.requestWithKey('POST', '/withdraw', this.currentKey.key, { asset, amount: coin(amt) }); });
});
When('the key deposits {float} {word} three times', async function (amt, asset) {
  await act(this, async () => { for (let i = 0; i < 3; i++) this.api = await cex.requestWithKey('POST', '/deposit', this.currentKey.key, { asset, amount: coin(amt) }); });
});
When('the key tries to mint a {string} API key', async function (scope) {
  await act(this, async () => { this.api = await cex.requestWithKey('POST', '/apikeys', this.currentKey.key, { scope }); });
});
When('the keys of {string} are read', async function (alias) {
  await act(this, async () => { this.api = await cex.keysOf(acctOf(this, alias).handle); });
});

Then('the minted key has scope {string}', function (scope) {
  const ok = this.api && this.api.body && this.api.body.scope === scope;
  if (this.sourceError) { this.unobservable('minted key scope', this.sourceError); return; }
  this.check('minted key scope ' + scope, ok, this.api ? JSON.stringify(this.api.body).slice(0, 80) : 'no response');
});
Then('the last response status is {int}', function (code) {
  if (this.sourceError) { this.unobservable('last response status', this.sourceError); return; }
  this.check('last response status ' + code, this.api && this.api.status === code, this.api ? 'got ' + this.api.status : 'no response');
});
Then('a listed key has scope {string}', function (scope) {
  if (this.sourceError) { this.unobservable('listed key scope', this.sourceError); return; }
  const found = this.api && this.api.body && (this.api.body.keys || []).some((k) => k.scope === scope);
  this.check('a listed key has scope ' + scope, found, this.api ? JSON.stringify(this.api.body).slice(0, 100) : 'no response');
});
