'use strict';

const { When, Then } = require('@cucumber/cucumber');
const { MiniCex, ApiUnreachable } = require('../venues/minicex');

/**
 * Steps for features/be-cex-security.feature -- adversarial edges around the
 * scoped-key tier: a garbage bearer token, cross-account key revocation, and
 * the secret-hygiene invariants (only a key prefix is ever listed; no
 * credential leaks in a public response). Account/key Givens and the response
 * assertions are shared from the other @minicex steps.
 */

const cex = new MiniCex();
const acctOf = (world, alias) => world.accounts[alias];
const SELL = { base: 'BTC', quote: 'USD', side: 'sell', type: 'limit', price: Math.round(60000 * 1e8), size: Math.round(0.5 * 1e8) };

async function act(world, fn) {
  if (world.sourceError) return;
  try { await fn(); } catch (err) { if (err instanceof ApiUnreachable) { world.sourceError = err.message; return; } throw err; }
}
const bodyText = (world) => JSON.stringify((world.api && world.api.body) || {});

When('a write is attempted with a garbage bearer token', async function () {
  await act(this, async () => { this.api = await cex.request('POST', '/orders', { token: 'acct_garbage000000000000000000', body: SELL }); });
});
When('another account tries to revoke that key', async function () {
  await act(this, async () => { const other = await cex.createAccount('intruder'); this.api = await cex.request('DELETE', '/apikeys/' + this.currentKey.key, { token: other.token }); });
});
When('{string}\'s API keys are listed', async function (alias) {
  await act(this, async () => { this.api = await cex.get('/apikeys/' + acctOf(this, alias).handle); });
});
When('the listed assets are read', async function () {
  await act(this, async () => { this.api = await cex.get('/assets'); });
});

Then('the key list shows a prefix but not the full key', function () {
  this.observe('key list shows only a prefix', () => { const full = this.currentKey.key; const text = bodyText(this); return { passed: !text.includes(full) && text.includes(full.slice(0, 12)), detail: text.includes(full) ? 'FULL KEY LEAKED' : 'prefix only' }; });
});
Then('the response carries no account token or API key', function () {
  this.observe('no credential leaked', () => { const text = bodyText(this); const leaks = ['acct_', 'key_'].filter((p) => text.includes(p)); return { passed: leaks.length === 0, detail: leaks.length ? 'leaked ' + leaks.join(',') : 'clean' }; });
});
