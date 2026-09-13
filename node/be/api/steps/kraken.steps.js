'use strict';

const { When, Then } = require('@cucumber/cucumber');
const { Kraken, SiteUnreachable } = require('../venues/kraken');
const { MiniCex, ApiUnreachable } = require('../venues/minicex');

/**
 * Steps for features/be-kraken-api.feature -- the live exchange, read-only.
 * Every read routes SiteUnreachable into Blocked (fetchOrBlock); a completed
 * read is graded. Kraken is not a system under test, so nothing here can Fail
 * on Kraken being down or slow.
 */

const cex = new MiniCex();

function krCheck(world, description, cond, detail) {
  if (world.sourceError) { world.unobservable(description, 'the source could not be reached -- ' + world.sourceError); return; }
  world.check(description, cond, detail);
}

When('the Kraken asset list is read', { timeout: 30_000 }, async function () {
  await this.fetchOrBlock([SiteUnreachable], async () => { this.krAssets = await Kraken.assets(); });
});
When('the Kraken pair list is read', { timeout: 30_000 }, async function () {
  await this.fetchOrBlock([SiteUnreachable], async () => { this.krPairs = await Kraken.pairNames(); });
});
When('the Kraken last price for {string} is read', { timeout: 30_000 }, async function (pair) {
  await this.fetchOrBlock([SiteUnreachable], async () => { this.krPrice = await Kraken.lastPrice(pair); });
});

Then('the Kraken asset list is non-empty', function () {
  krCheck(this, 'Kraken assets non-empty', this.krAssets && Object.keys(this.krAssets).length > 0, this.krAssets ? Object.keys(this.krAssets).length + ' assets' : 'none');
});
Then('every Kraken pair name is a non-empty string', function () {
  const bad = (this.krPairs || []).filter((n) => typeof n !== 'string' || n.length === 0);
  krCheck(this, 'Kraken pair names well-formed', (this.krPairs || []).length > 0 && bad.length === 0, `${(this.krPairs || []).length} names, ${bad.length} bad`);
});
Then('a USD pair exists on Kraken for each of {word}, {word}, {word}', function (a, b, c) {
  // Kraken uses XBT for bitcoin; accept either spelling per asset.
  const names = new Set(this.krPairs || []);
  const alias = { BTC: ['XBT', 'BTC'] };
  const has = (sym) => (alias[sym] || [sym]).some((s) => names.has(s + '/USD'));
  const missing = [a, b, c].filter((s) => !has(s));
  krCheck(this, 'USD pairs exist on Kraken', missing.length === 0, missing.length ? 'missing ' + missing.join(',') : 'all present');
});
Then('the Kraken price is a positive number', function () {
  krCheck(this, 'Kraken price positive', typeof this.krPrice === 'number' && this.krPrice > 0, 'price ' + this.krPrice);
});
Then('the mini-cex BTC price is the same order of magnitude as Kraken\'s', async function () {
  if (this.sourceError) { this.unobservable('mini-cex vs Kraken order of magnitude', 'the source could not be reached -- ' + this.sourceError); return; }
  let mini;
  try { const r = await cex.get('/assets'); const btc = (r.body.assets || []).find((x) => x.symbol === 'BTC'); mini = btc ? btc.usd_micro / 1e6 : null; }
  catch (err) { if (err instanceof ApiUnreachable) { this.unobservable('mini-cex vs Kraken order of magnitude', err.message); return; } throw err; }
  const ratio = mini && this.krPrice ? mini / this.krPrice : 0;
  this.check('mini-cex BTC same order of magnitude as Kraken', ratio >= 0.1 && ratio <= 10, `mini $${mini}, kraken $${this.krPrice}, ratio ${ratio.toFixed(2)}`);
});
