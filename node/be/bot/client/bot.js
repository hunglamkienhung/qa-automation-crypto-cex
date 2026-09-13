'use strict';

const { ApiUnreachable } = require('../../api/venues/minicex');
const { RiskEngine } = require('../risk/engine');

/**
 * A market-maker that quotes a two-sided spread on one pair of the mini-cex spot
 * order book. It posts a post-only bid below and ask above a reference price,
 * cancels and replaces its quotes on a reprice, and passes every order past the
 * pure RiskEngine before sending. Mirrors the pattern of the perpetuals repo's
 * Bot client: it retries only transport failures, never a valid rejection, and
 * never lets its token leak.
 *
 * Prices are in the order book's integer form (quote base-units per whole base,
 * i.e. a human price x 1e8); spread math is BigInt so the reference x 10000 does
 * not overflow. The bot is otherwise pure orchestration over the venue.
 */
class MarketMaker {
  constructor(cex, opts = {}) {
    this.cex = cex;
    this.token = opts.token;
    this.handle = opts.handle;
    this.base = opts.base;
    this.quoteAsset = opts.quote;
    this.refPrice = opts.refPrice;               // integer, quote-per-base x 1e8
    this.spreadBps = opts.spreadBps === undefined ? 50 : opts.spreadBps;
    this.size = opts.size;                        // base units
    this.dryRun = !!opts.dryRun;
    this.killSwitch = !!opts.killSwitch;
    this.risk = opts.risk || new RiskEngine({ killSwitch: this.killSwitch });
  }

  bidPrice() { return Number((BigInt(this.refPrice) * BigInt(10000 - this.spreadBps)) / 10000n); }
  askPrice() { return Number((BigInt(this.refPrice) * BigInt(10000 + this.spreadBps)) / 10000n); }

  /** Build the risk context from the account's current balances + the venue's assets/pairs. */
  async riskCtx() {
    const assets = {}; for (const a of (await this.cex.get('/assets')).body.assets) assets[a.symbol] = { usd_micro: a.usd_micro };
    const balances = {}; for (const b of (await this.cex.get('/balances/' + this.handle)).body.balances) balances[b.asset] = b.amount;
    const pairs = (await this.cex.get('/pairs')).body.pairs;
    return { assets, balances, pairs };
  }

  async cancelAll() {
    const r = await this.cex.ordersOf(this.handle);
    for (const o of (r.body.orders || [])) if (o.base === this.base && o.quote === this.quoteAsset && (o.status === 'open' || o.status === 'partial')) await this.cex.cancelOrder(this.token, o.id);
  }
  async activeQuotes() {
    const r = await this.cex.ordersOf(this.handle, 'open');
    return (r.body.orders || []).filter((o) => o.base === this.base && o.quote === this.quoteAsset);
  }

  /**
   * Post (or refresh) the two-sided quote. Returns a decision: refused when the
   * kill switch is on or the risk gate blocks a leg; planned-only under dryRun;
   * otherwise the placed bid and ask.
   */
  async quote() {
    if (this.killSwitch) return { ok: false, reason: 'kill switch' };
    const bid = this.bidPrice(); const ask = this.askPrice();
    const ctx = await this.riskCtx();
    const pBuy = this.risk.plan({ kind: 'order', side: 'buy', base: this.base, quote: this.quoteAsset, size: this.size, price: bid }, ctx);
    if (!pBuy.ok) return { ok: false, reason: pBuy.reason, leg: 'bid' };
    const pSell = this.risk.plan({ kind: 'order', side: 'sell', base: this.base, quote: this.quoteAsset, size: this.size, price: ask }, ctx);
    if (!pSell.ok) return { ok: false, reason: pSell.reason, leg: 'ask' };
    if (this.dryRun) return { ok: true, dryRun: true, bid, ask };
    await this.cancelAll();
    const bidRes = await this.cex.placeOrder(this.token, { base: this.base, quote: this.quoteAsset, side: 'buy', type: 'limit', price: bid, size: this.size, post_only: true });
    const askRes = await this.cex.placeOrder(this.token, { base: this.base, quote: this.quoteAsset, side: 'sell', type: 'limit', price: ask, size: this.size, post_only: true });
    return { ok: true, bid: bidRes.body, ask: askRes.body, bidPrice: bid, askPrice: ask };
  }

  async reprice(newRef) { this.refPrice = newRef; return this.quote(); }

  /** Retry ONLY a transport failure (ApiUnreachable); a valid rejection is returned as-is. */
  async withRetry(fn, tries = 3) {
    let last;
    for (let i = 0; i < tries; i++) {
      try { return await fn(); }
      catch (err) { if (!(err instanceof ApiUnreachable)) throw err; last = err; }
    }
    throw last;
  }

  leakedSecret(s) { return String(s).includes(this.token); }
}

module.exports = { MarketMaker };
