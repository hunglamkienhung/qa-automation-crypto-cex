'use strict';

const { Given, When, Then, After } = require('@cucumber/cucumber');
const { MiniCex, ApiUnreachable } = require('../venues/minicex');

/**
 * Steps for features/be-cex-orders.feature -- the spot order book. The account
 * and deposit steps are shared from be/db/steps/cex.steps.js; here are the order
 * actions and the assertions on rows (via this.store) and responses.
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
function expectThrow(fn, needle) {
  try { fn(); return { passed: false, detail: 'no error thrown' }; }
  catch (err) { const ok = new RegExp(needle, 'i').test(err.message); return { passed: ok, detail: ok ? 'rejected: ' + err.message.split('\n')[0] : 'wrong error: ' + err.message }; }
}

// The order book is shared across scenarios, so every mini-cex scenario cancels
// its accounts' resting orders afterwards -- leaving the book empty for the
// next one, the same discipline the crypto repo gets from anvil snapshot/revert.
After({ tags: '@minicex' }, async function () {
  for (const alias of Object.keys(this.accounts || {})) {
    const a = this.accounts[alias];
    try {
      const r = await cex.ordersOf(a.handle);
      for (const o of (r.body && r.body.orders) || []) if (o.status === 'open' || o.status === 'partial') await cex.cancelOrder(a.token, o.id);
    } catch { /* best-effort cleanup */ }
  }
});

async function place(world, alias, opts) {
  const a = acctOf(world, alias);
  const body = { base: opts.base, quote: opts.quote, side: opts.side, type: opts.type || 'limit', size: coin(opts.size), tif: opts.tif || 'GTC' };
  if (body.type === 'limit') body.price = coin(opts.price);
  if (opts.post_only) body.post_only = true;
  if (opts.key) body.idempotency_key = opts.key;
  world.api = await cex.placeOrder(a.token, body);
  if (world.api.status === 201 || world.api.status === 200) { world.lastOrder = world.api.body; world.lastOrderBy = world.lastOrderBy || {}; world.lastOrderBy[alias] = world.api.body; }
}

// ---------------------------------------------------------------- schema (throwaway)

Then('inserting a balance whose reserved exceeds its amount fails a CHECK', function () {
  this.tmp.exec("INSERT INTO accounts (id, handle, created_at) VALUES (1, 'x', 0)");
  const r = expectThrow(() => this.tmp.exec("INSERT INTO balances (account_id, asset, amount, reserved) VALUES (1, 'BTC', 5, 10)"), 'CHECK|constraint');
  this.check('reserved<=amount enforced', r.passed, r.detail);
});
Then('inserting an order whose filled exceeds its size fails a CHECK', function () {
  this.tmp.exec("INSERT INTO accounts (id, handle, created_at) VALUES (1, 'x', 0)");
  const r = expectThrow(() => this.tmp.exec("INSERT INTO orders (account_id, base, quote, side, type, price, size, filled, status, tif, post_only, created_at, seq) VALUES (1,'BTC','USD','sell','limit',100,5,10,'open','GTC',0,0,1)"), 'CHECK|constraint');
  this.check('filled<=size enforced', r.passed, r.detail);
});
Then('inserting a fill whose taker and maker are the same account fails a CHECK', function () {
  this.tmp.exec("INSERT INTO accounts (id, handle, created_at) VALUES (1, 'x', 0)");
  this.tmp.exec("INSERT INTO orders (id, account_id, base, quote, side, type, price, size, filled, status, tif, post_only, created_at, seq) VALUES (1,1,'BTC','USD','buy','limit',100,5,0,'open','GTC',0,0,1)");
  this.tmp.exec("INSERT INTO orders (id, account_id, base, quote, side, type, price, size, filled, status, tif, post_only, created_at, seq) VALUES (2,1,'BTC','USD','sell','limit',100,5,0,'open','GTC',0,0,2)");
  const r = expectThrow(() => this.tmp.exec("INSERT INTO fills (taker_order, maker_order, base, quote, price, size, taker_account, maker_account, created_at) VALUES (1,2,'BTC','USD',100,5,1,1,0)"), 'CHECK|constraint');
  this.check('taker<>maker enforced', r.passed, r.detail);
});

// ---------------------------------------------------------------- order actions

Given('{string} is funded with {float} {word}', async function (alias, amt, asset) {
  await act(this, async () => { this.api = await cex.deposit(acctOf(this, alias).token, asset, coin(amt)); });
});
async function limit(world, alias, side, size, base, price, quote, extra) { await act(world, () => place(world, alias, { side, size, base, price, quote, type: 'limit', ...extra })); }

// One definition per phrase (Cucumber shares Given/When/Then), used by both the
// "And ... places" setup lines and the "When ... places" action lines.
When('{string} places a limit {word} of {float} {word} at {float} {word}', async function (alias, side, size, base, price, quote) { await limit(this, alias, side, size, base, price, quote, {}); });
When('{string} places a limit {word} of {float} {word} at {float} {word} with key {string}', async function (alias, side, size, base, price, quote, key) { await limit(this, alias, side, size, base, price, quote, { key }); });
When('{string} places a post-only {word} of {float} {word} at {float} {word}', async function (alias, side, size, base, price, quote) { await limit(this, alias, side, size, base, price, quote, { post_only: true }); });
When('{string} places a FOK {word} of {float} {word} at {float} {word}', async function (alias, side, size, base, price, quote) { await limit(this, alias, side, size, base, price, quote, { tif: 'FOK' }); });
When('{string} places an IOC {word} of {float} {word} at {float} {word}', async function (alias, side, size, base, price, quote) { await limit(this, alias, side, size, base, price, quote, { tif: 'IOC' }); });
When('{string} places a market {word} of {float} {word} paying {word}', async function (alias, side, size, base, quote) { await act(this, () => place(this, alias, { side, size, base, quote, type: 'market' })); });
When('{string} cancels the order', async function (alias) { await act(this, async () => { this.api = await cex.cancelOrder(acctOf(this, alias).token, this.lastOrder.id); this.lastOrder = this.api.body; }); });

// ---------------------------------------------------------------- assertions

Then('the order status is {string}', function (status) { assert(this, 'order status ' + status, this.lastOrder && this.lastOrder.status === status, this.lastOrder ? 'got ' + this.lastOrder.status + ' (' + (this.api && this.api.status) + ')' : 'no order ' + (this.api && this.api.text)); });
Then('the taker order status is {string}', function (status) { assert(this, 'taker order status ' + status, this.lastOrder && this.lastOrder.status === status, this.lastOrder ? 'got ' + this.lastOrder.status : 'no order'); });
Then('the order filled is {float} {word}', function (amt, _a) { assert(this, 'order filled', this.lastOrder && this.lastOrder.filled === coin(amt), this.lastOrder ? 'got ' + this.lastOrder.filled : 'no order'); });
Then('the reserved {word} of {string} is {float}', function (asset, alias, amt) {
  assert(this, `reserved ${asset} of ${alias}`, this.store.reserved(this.store.accountId(acctOf(this, alias).handle), asset) === coin(amt), 'got ' + this.store.reserved(this.store.accountId(acctOf(this, alias).handle), asset));
});
Then('the order book has an ask of {float} {word} at {float} {word}', async function (size, base, price, quote) {
  await act(this, async () => { const r = await cex.orderbook(base, quote); const row = (r.body.asks || []).find((x) => x.price === coin(price) && x.size === coin(size)); assert(this, 'ask present', !!row, JSON.stringify(r.body.asks)); });
});
Then('a fill records {float} {word} at {float} {word}', async function (size, base, price, quote) {
  await act(this, async () => { const r = await cex.fillsOf(base, quote); const row = (r.body.fills || []).find((f) => f.size === coin(size) && f.price === coin(price)); assert(this, 'fill present', !!row, JSON.stringify(r.body.fills)); });
});
Then('the fills for {word} {word} number {int}', async function (base, quote, n) {
  await act(this, async () => { const r = await cex.fillsOf(base, quote); assert(this, 'fills count', (r.body.fills || []).length === n, 'got ' + (r.body.fills || []).length); });
});
Then('the last fill taker fee is {int} basis points of {float} {word}', async function (bps, amt, _a) {
  await act(this, async () => { const r = await cex.fillsOf(this.lastOrder.base, this.lastOrder.quote); const f = (r.body.fills || []).slice(-1)[0]; const expected = Math.floor((coin(amt) * bps) / 10000); assert(this, 'taker fee', f && f.taker_fee === expected, f ? `got ${f.taker_fee}, expected ${expected}` : 'no fill'); });
});
Then('the last fill maker fee is {int} basis points of {float} {word}', async function (bps, amt, _a) {
  await act(this, async () => { const r = await cex.fillsOf(this.lastOrder.base, this.lastOrder.quote); const f = (r.body.fills || []).slice(-1)[0]; const expected = Math.floor((coin(amt) * bps) / 10000); assert(this, 'maker fee', f && f.maker_fee === expected, f ? `got ${f.maker_fee}, expected ${expected}` : 'no fill'); });
});
Then('the maker order for {string} is {string} with filled {float} {word}', async function (alias, status, amt, _a) {
  await act(this, async () => { const r = await cex.ordersOf(acctOf(this, alias).handle); const o = (r.body.orders || []).slice(-1)[0]; assert(this, 'maker order state', o && o.status === status && o.filled === coin(amt), o ? `status ${o.status} filled ${o.filled}` : 'no order'); });
});
Then('the open orders of {string} number {int}', async function (alias, n) {
  await act(this, async () => { const r = await cex.ordersOf(acctOf(this, alias).handle, 'open'); assert(this, 'open orders count', (r.body.orders || []).length === n, 'got ' + (r.body.orders || []).length); });
});
Then('the second order was an idempotent replay', function () { assert(this, 'order idempotent replay', this.api && this.api.body && this.api.body.idempotent_replay === true, this.api ? JSON.stringify(this.api.body).slice(0, 80) : 'no response'); });
Then('the base leaving the maker equals the base reaching the taker plus the taker fee', async function () {
  await act(this, async () => {
    const f = (await cex.fillsOf(this.lastOrder.base, this.lastOrder.quote)).body.fills.slice(-1)[0];
    const takerBase = this.store.balance(this.store.accountId(acctOf(this, 'taker').handle), this.lastOrder.base);
    assert(this, 'base conserved', f && (takerBase + f.taker_fee === f.size), f ? `taker ${takerBase} + fee ${f.taker_fee} vs size ${f.size}` : 'no fill');
  });
});
Then('the quote leaving the taker equals the quote reaching the maker plus the maker fee', async function () {
  await act(this, async () => {
    const f = (await cex.fillsOf(this.lastOrder.base, this.lastOrder.quote)).body.fills.slice(-1)[0];
    if (!f) { assert(this, 'quote conserved', false, 'no fill'); return; }
    const makerQuote = this.store.balance(this.store.accountId(acctOf(this, 'maker').handle), this.lastOrder.quote);
    const quoteTotal = Math.floor((f.size * f.price) / 1e8);
    assert(this, 'quote conserved', makerQuote + f.maker_fee === quoteTotal, `maker ${makerQuote} + fee ${f.maker_fee} vs total ${quoteTotal}`);
  });
});
Then('the fee schedule is read', async function () { await act(this, async () => { this.feeTiers = (await cex.fees()).body.tiers; }); });
Then('the entry tier charges {int} basis points taker and {int} maker', function (taker, maker) {
  const t0 = (this.feeTiers || []).find((t) => t.tier === 0);
  assert(this, 'entry tier bps', t0 && t0.taker_bps === taker && t0.maker_bps === maker, t0 ? `taker ${t0.taker_bps} maker ${t0.maker_bps}` : 'no tier 0');
});
Then('a higher tier pays the maker a rebate', function () {
  assert(this, 'a rebate tier exists', (this.feeTiers || []).some((t) => t.maker_bps < 0), JSON.stringify(this.feeTiers));
});
