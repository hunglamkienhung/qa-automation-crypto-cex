'use strict';

const { Given, When, Then } = require('@cucumber/cucumber');
const { MiniCex, ApiUnreachable } = require('../../api/venues/minicex');
const { MarketMaker } = require('../client/bot');

/**
 * Steps for the market-maker bot at the API tier (be-mm-bot.feature) and the DB
 * tier (be-mm-bot-db.feature). The bot's account is registered under this.accounts
 * so the shared @minicex cleanup hook cancels its resting quotes between scenarios.
 */

const cex = new MiniCex();
const coin = (n) => Math.round(Number(n) * 1e8);

async function act(world, fn) {
  if (world.sourceError) return;
  try { await fn(); } catch (err) { if (err instanceof ApiUnreachable) { world.sourceError = err.message; return; } throw err; }
}
function assert(world, description, cond, detail) {
  if (world.sourceError) { world.unobservable(description, 'the source could not be reached -- ' + world.sourceError); return; }
  world.check(description, cond, detail);
}

async function makeBot(world, ref, spreadBps, opts = {}) {
  await act(world, async () => {
    const acct = await cex.createAccount('mm');
    world.accounts.mm = acct;
    world.mmAccount = acct;
    await cex.deposit(acct.token, 'BTC', coin(1.0));
    await cex.deposit(acct.token, 'USD', coin(100000));
    world.mmRef = coin(ref);
    world.bot = new MarketMaker(cex, { token: acct.token, handle: acct.handle, base: 'BTC', quote: 'USD', refPrice: coin(ref), spreadBps, size: coin(0.1), killSwitch: !!opts.killSwitch, dryRun: !!opts.dryRun });
  });
}

Given('a funded market maker on BTC\\/USD at reference {int} with {int} bps spread', async function (ref, bps) { await makeBot(this, ref, bps); });
Given('a funded market maker on BTC\\/USD at reference {int} with {int} bps spread with the kill switch on', async function (ref, bps) { await makeBot(this, ref, bps, { killSwitch: true }); });
Given('a funded market maker on BTC\\/USD at reference {int} with {int} bps spread in dry-run mode', async function (ref, bps) { await makeBot(this, ref, bps, { dryRun: true }); });

// One definition per phrase (Cucumber shares the registry); serves both the
// "And the market maker quotes" setup lines and the "When ..." action lines.
When('the market maker quotes', async function () { await act(this, async () => { this.mmResult = await this.bot.quote(); }); });
When('the market maker reprices to {int}', async function (ref) { await act(this, async () => { this.mmResult = await this.bot.reprice(coin(ref)); }); });

async function liftAsk(world) {
  const taker = await cex.createAccount('mmtaker'); world.accounts.mmtaker = taker;
  await cex.deposit(taker.token, 'USD', coin(100000));
  await cex.placeOrder(taker.token, { base: 'BTC', quote: 'USD', side: 'buy', type: 'limit', price: world.bot.askPrice(), size: world.bot.size });
}
When('a taker lifts the maker\'s ask', async function () { await act(this, () => liftAsk(this)); });

// ---------------------------------------------------------------- API assertions

Then('the quote is placed', function () { assert(this, 'quote placed', this.mmResult && this.mmResult.ok === true && !this.mmResult.dryRun, JSON.stringify(this.mmResult)); });
Then('the bid is below the reference and the ask is above it', function () { assert(this, 'bid<ref<ask', this.mmResult && this.mmResult.bidPrice < this.mmRef && this.mmResult.askPrice > this.mmRef, this.mmResult ? `bid ${this.mmResult.bidPrice} ref ${this.mmRef} ask ${this.mmResult.askPrice}` : 'no result'); });
Then('the quote is refused for {string}', function (reason) { assert(this, 'quote refused ' + reason, this.mmResult && this.mmResult.ok === false && String(this.mmResult.reason).includes(reason), JSON.stringify(this.mmResult)); });
Then('the quote is a dry run', function () { assert(this, 'quote dry run', this.mmResult && this.mmResult.ok === true && this.mmResult.dryRun === true, JSON.stringify(this.mmResult)); });
Then('the order book shows the maker\'s bid and ask', async function () {
  await act(this, async () => { const b = (await cex.orderbook('BTC', 'USD')).body; const hasBid = (b.bids || []).some((x) => x.price === this.bot.bidPrice()); const hasAsk = (b.asks || []).some((x) => x.price === this.bot.askPrice()); assert(this, 'book shows bid+ask', hasBid && hasAsk, JSON.stringify(b)); });
});
Then('the maker has exactly one bid and one ask resting', async function () {
  await act(this, async () => { const qs = await this.bot.activeQuotes(); const bids = qs.filter((o) => o.side === 'buy'); const asks = qs.filter((o) => o.side === 'sell'); assert(this, 'one bid + one ask', bids.length === 1 && asks.length === 1, `bids ${bids.length} asks ${asks.length}`); });
});
Then('the resting ask is at the new ask price', async function () {
  await act(this, async () => { const qs = await this.bot.activeQuotes(); const ask = qs.find((o) => o.side === 'sell'); assert(this, 'ask at new price', ask && ask.price === this.bot.askPrice(), ask ? `got ${ask.price} want ${this.bot.askPrice()}` : 'no ask'); });
});
Then('the maker\'s ask order is filled', async function () {
  await act(this, async () => { const r = await cex.ordersOf(this.mmAccount.handle); const ask = (r.body.orders || []).find((o) => o.id === this.mmResult.ask.id); assert(this, 'ask filled', ask && ask.status === 'filled', ask ? 'status ' + ask.status : 'no ask order'); });
});
Then('the maker has no resting quotes', async function () {
  await act(this, async () => { const qs = await this.bot.activeQuotes(); assert(this, 'no resting quotes', qs.length === 0, qs.length + ' resting'); });
});
Then('the maker\'s token does not leak into a log line', function () {
  assert(this, 'token does not leak', this.bot.leakedSecret('mm posted a quote on BTC/USD') === false && this.bot.leakedSecret(this.mmAccount.token) === true, 'leak detector inconsistent');
});

// ---------------------------------------------------------------- DB assertions

function makerId(world) { return world.store.accountId(world.mmAccount.handle); }

Then('the store has one open bid and one open ask for the maker', async function () {
  await act(this, async () => { const id = makerId(this); const bids = this.store.count('orders', "WHERE account_id = ? AND side = 'buy' AND status = 'open'", id); const asks = this.store.count('orders', "WHERE account_id = ? AND side = 'sell' AND status = 'open'", id); assert(this, 'one open bid + ask (store)', bids === 1 && asks === 1, `bids ${bids} asks ${asks}`); });
});
Then('the maker\'s reserved BTC covers the ask and reserved USD covers the bid', async function () {
  await act(this, async () => { const id = makerId(this); const rBtc = this.store.reserved(id, 'BTC'); const rUsd = this.store.reserved(id, 'USD'); const bidCost = Math.floor((this.bot.size * this.bot.bidPrice()) / 1e8); assert(this, 'reserves cover quotes', rBtc === this.bot.size && rUsd === bidCost, `resBTC ${rBtc} want ${this.bot.size}; resUSD ${rUsd} want ${bidCost}`); });
});
Then('a fill row records the ask size at the ask price', async function () {
  await act(this, async () => { const f = this.store.get('SELECT * FROM fills WHERE base=? AND quote=? AND price=? AND size=? ORDER BY id DESC LIMIT 1', 'BTC', 'USD', this.bot.askPrice(), this.bot.size); assert(this, 'fill at ask price', !!f, f ? 'found' : 'no fill'); });
});
Then('the maker\'s ask order filled equals its size in the store', async function () {
  await act(this, async () => { const o = this.store.get('SELECT * FROM orders WHERE id = ?', this.mmResult.ask.id); assert(this, 'ask filled==size', o && o.filled === o.size, o ? `filled ${o.filled} size ${o.size}` : 'no order'); });
});
Then('the maker has exactly two cancelled orders in the store', async function () {
  await act(this, async () => { const n = this.store.count('orders', "WHERE account_id = ? AND status = 'cancelled'", makerId(this)); assert(this, 'two cancelled', n === 2, 'got ' + n); });
});
Then('the maker\'s reserved funds cover only the new quote', async function () {
  await act(this, async () => { const id = makerId(this); const rBtc = this.store.reserved(id, 'BTC'); const rUsd = this.store.reserved(id, 'USD'); const bidCost = Math.floor((this.bot.size * this.bot.bidPrice()) / 1e8); assert(this, 'reserve only new quote', rBtc === this.bot.size && rUsd === bidCost, `resBTC ${rBtc}; resUSD ${rUsd} want ${bidCost}`); });
});
Then('the ledger sum for the maker in {word} equals its balance row', async function (asset) {
  await act(this, async () => { const id = makerId(this); assert(this, 'ledger==balance ' + asset, this.store.ledgerBalance(id, asset) === this.store.balance(id, asset), `ledger ${this.store.ledgerBalance(id, asset)} balance ${this.store.balance(id, asset)}`); });
});
