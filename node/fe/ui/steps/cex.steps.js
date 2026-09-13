'use strict';

const { Given, When, Then } = require('@cucumber/cucumber');
const { WalletPage, ScreenNotReady } = require('../pages/wallet');
const { MiniCex, ApiUnreachable } = require('../../../be/api/venues/minicex');

/**
 * Steps for features/fe-cex.feature -- the only steps in this domain that drive
 * a browser. The comparison figures come from the same API the BE tier reads,
 * so the screen is held to the backend's numbers. The mini-cex is deterministic
 * and local, so these grade strictly; they Block only if the service or the
 * browser is unavailable.
 */

const cex = new MiniCex();
const acctOf = (world, alias) => world.accounts[alias];

Given('the service is reachable and the home page is open', { timeout: 90_000 }, async function () {
  this.wallet = new WalletPage(this.page);
  await this.fetchOrBlock([ScreenNotReady], async () => { await this.wallet.open('/'); this.screen.assets = await this.wallet.assets(); });
});

async function screen(world, description, fn) {
  if (world.sourceError) { world.unobservable(description, 'the source could not be reached -- ' + world.sourceError); return; }
  let r;
  try { r = await fn(); } catch (err) { if (err instanceof ScreenNotReady || err instanceof ApiUnreachable) { world.unobservable(description, err.message); return; } throw err; }
  world.check(description, r.passed, r.detail);
}

Then('the assets on screen include {word}, {word}, {word}, {word}', async function (a, b, c, d) {
  await screen(this, 'assets on screen', async () => { const have = new Set((this.screen.assets || []).map((x) => x.symbol)); const want = [a, b, c, d]; const missing = want.filter((s) => !have.has(s)); return { passed: missing.length === 0, detail: missing.length ? 'missing ' + missing.join(',') : 'all present' }; });
});
Then('every asset row on screen shows a symbol and a USD price', async function () {
  await screen(this, 'asset rows complete', async () => { const bad = (this.screen.assets || []).filter((x) => !x.symbolText || !/^\$[0-9]/.test(x.usdText)); return { passed: bad.length === 0 && (this.screen.assets || []).length > 0, detail: bad.length + ' incomplete' }; });
});
Then('the {word} row on screen is marked delisted', async function (sym) {
  await screen(this, sym + ' marked delisted', async () => { const row = (this.screen.assets || []).find((x) => x.symbol === sym); return { passed: !!row && /delisted/i.test(row.activeText), detail: row ? row.activeText : 'no ' + sym + ' row' }; });
});
Then('the number of assets on screen equals the API asset count', async function () {
  await screen(this, 'screen asset count == API', async () => { const r = await cex.get('/assets'); const api = (r.body.assets || []).length; return { passed: (this.screen.assets || []).length === api, detail: `screen ${(this.screen.assets || []).length}, api ${api}` }; });
});

When('the wallet page for {string} is opened', { timeout: 90_000 }, async function (alias) {
  await this.fetchOrBlock([ScreenNotReady], async () => { await this.wallet.open('/wallet/' + acctOf(this, alias).handle); this.screen.balances = await this.wallet.balances(); });
});
Then('the {word} balance on screen is {float}', async function (asset, amt) {
  await screen(this, asset + ' balance on screen', async () => { const row = (this.screen.balances || []).find((x) => x.asset === asset); return { passed: !!row && Number(row.amountText) === Number(amt), detail: row ? `screen ${row.amountText}, want ${amt}` : 'no ' + asset + ' row' }; });
});
Then('every balance on screen matches the API balance for {string}', async function (alias) {
  await screen(this, 'screen balances == API', async () => {
    const r = await cex.get('/balances/' + acctOf(this, alias).handle);
    const api = Object.fromEntries((r.body.balances || []).map((x) => [x.asset, x.amount / 1e8]));
    const bad = (this.screen.balances || []).filter((x) => Number(x.amountText) !== api[x.asset]);
    return { passed: bad.length === 0 && (this.screen.balances || []).length > 0, detail: bad.length ? 'mismatch ' + bad.map((x) => x.asset).join(',') : 'match' };
  });
});

When('the op page for that bridge op is opened', { timeout: 90_000 }, async function () {
  await this.fetchOrBlock([ScreenNotReady], async () => { await this.wallet.open('/op/' + this.lastBridge.id); this.screen.op = await this.wallet.op(); });
});
Then('the op status on screen is {string}', async function (status) {
  await screen(this, 'op status on screen', async () => ({ passed: this.screen.op && this.screen.op.statusText === status, detail: this.screen.op ? this.screen.op.statusText : 'no op page' }));
});
