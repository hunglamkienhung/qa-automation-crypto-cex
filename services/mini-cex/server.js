#!/usr/bin/env node
'use strict';

const http = require('http');
const path = require('path');
const { URL } = require('url');
const { open } = require('./lib/db');
const H = require('./lib/http');

/**
 * mini-cex: a small centralized exchange over one SQLite file. Node standard
 * library only.
 *
 * REST (JSON):
 *   GET  /assets                          listed assets + USD price
 *   GET  /pairs                           tradable pairs
 *   POST /quote            { from_asset, to_asset, from_amount }   (no auth)
 *   POST /accounts         { handle } -> { handle, token }
 *   GET  /accounts/:handle                balances
 *   GET  /balances/:handle
 *   POST /deposit          Bearer { asset, amount, idempotency_key? }
 *   POST /withdraw         Bearer { asset, amount, idempotency_key? }
 *   POST /transfer         Bearer { to_handle, asset, amount, idempotency_key? }
 *   POST /swap             Bearer { from_asset, to_asset, from_amount, min_to_amount?, idempotency_key? }
 *   POST /bridge/withdraw  Bearer { asset, amount, dst_chain, idempotency_key? }
 *   POST /bridge/deposit   { handle, asset, amount, src_chain, ext_tx }
 *   POST /bridge/:id/confirm
 *   GET  /bridge/:id
 *
 * HTML (for Playwright): /, /wallet/:handle, /op/:id.
 *
 * The write paths a custodian must get right -- a transfer that refuses to
 * overdraw and moves value atomically, a swap that conserves value at the
 * quoted rate and honours a slippage floor, a bridge op that is applied at most
 * once per external tx and never exceeds its cap -- are all here, in
 * transactions, so the DB tier can prove them from the rows.
 *
 * Amounts are integer base units: 1e8 per whole coin, the same scale for every
 * asset. Prices are USD per whole coin in micro-dollars (1e6). Cross-asset
 * arithmetic is done in BigInt so it never loses precision, then stored as the
 * integers the schema constrains.
 */

const cfg = {
  port: Number(process.env.MINI_CEX_PORT || 8110),
  dbFile: process.env.MINI_CEX_DB || path.join(__dirname, 'data', 'mini-cex.db'),
};

const SCALE = 100000000n;               // 1e8 base units per whole coin
const CHAINS = ['ethereum', 'arbitrum', 'solana', 'bitcoin']; // bridge allowlist
const BRIDGE_CAP_USD_MICRO = 100000n * 1000000n; // $100,000 per bridge tx

const now = () => Math.floor(Date.now() / 1000);

function json(res, status, body, extra = {}) {
  res.writeHead(status, { 'content-type': 'application/json; charset=utf-8', ...extra });
  res.end(JSON.stringify(body, (_k, v) => (typeof v === 'bigint' ? Number(v) : v)));
}
function html(res, status, body) {
  res.writeHead(status, { 'content-type': 'text/html; charset=utf-8' });
  res.end('<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">' + body);
}
function esc(s) {
  return String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
}
function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (c) => { data += c; if (data.length > 65536) reject(new H.ApiError(413, 'too_large', 'body too large')); });
    req.on('end', () => { try { resolve(data ? JSON.parse(data) : {}); } catch { reject(new H.ApiError(400, 'bad_request', 'body is not JSON')); } });
  });
}
/** A positive integer amount in base units, or reject. */
function amountOf(v) {
  if (typeof v !== 'number' || !Number.isInteger(v) || v <= 0) throw new H.ApiError(400, 'bad_request', 'amount must be a positive integer in base units (1e8 per coin)');
  return v;
}

function main() {
  const db = open(cfg.dbFile);

  const q = {
    assets: db.prepare('SELECT * FROM assets ORDER BY symbol'),
    asset: db.prepare('SELECT * FROM assets WHERE symbol = ?'),
    pairs: db.prepare('SELECT * FROM pairs ORDER BY base, quote'),
    pairEither: db.prepare('SELECT * FROM pairs WHERE (base = ? AND quote = ?) OR (base = ? AND quote = ?) LIMIT 1'),
    accountByHandle: db.prepare('SELECT * FROM accounts WHERE handle = ?'),
    accountByToken: db.prepare('SELECT * FROM accounts WHERE token = ?'),
    accountById: db.prepare('SELECT * FROM accounts WHERE id = ?'),
    insAccount: db.prepare('INSERT INTO accounts (handle, token, created_at) VALUES (?, ?, ?)'),
    balance: db.prepare('SELECT amount FROM balances WHERE account_id = ? AND asset = ?'),
    balancesOf: db.prepare('SELECT asset, amount FROM balances WHERE account_id = ? ORDER BY asset'),
    insBalance: db.prepare('INSERT INTO balances (account_id, asset, amount) VALUES (?, ?, ?)'),
    addBalance: db.prepare('UPDATE balances SET amount = amount + ? WHERE account_id = ? AND asset = ?'),
    insLedger: db.prepare('INSERT INTO ledger (account_id, asset, delta, reason, ref_type, ref_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)'),
    ledgerSum: db.prepare('SELECT COALESCE(SUM(delta), 0) AS s FROM ledger WHERE account_id = ? AND asset = ?'),
    insTransfer: db.prepare('INSERT INTO transfers (from_account, to_account, asset, amount, kind, idempotency_key, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)'),
    transferByKey: db.prepare('SELECT * FROM transfers WHERE idempotency_key = ?'),
    transfer: db.prepare('SELECT * FROM transfers WHERE id = ?'),
    insSwap: db.prepare('INSERT INTO swaps (account_id, from_asset, to_asset, from_amount, to_amount, fee_amount, rate_micro, idempotency_key, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'),
    swapByKey: db.prepare('SELECT * FROM swaps WHERE idempotency_key = ?'),
    swap: db.prepare('SELECT * FROM swaps WHERE id = ?'),
    insBridge: db.prepare('INSERT INTO bridge_ops (account_id, asset, amount, direction, src_chain, dst_chain, status, ext_tx, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'),
    bridge: db.prepare('SELECT * FROM bridge_ops WHERE id = ?'),
    bridgeByExt: db.prepare('SELECT * FROM bridge_ops WHERE direction = ? AND ext_tx = ?'),
    setBridgeStatus: db.prepare('UPDATE bridge_ops SET status = ?, updated_at = ? WHERE id = ?'),
    // v2: orders / fills / fees
    pair: db.prepare('SELECT * FROM pairs WHERE base = ? AND quote = ?'),
    reserveAdd: db.prepare('UPDATE balances SET reserved = reserved + ? WHERE account_id = ? AND asset = ?'),
    balanceRow: db.prepare('SELECT amount, reserved FROM balances WHERE account_id = ? AND asset = ?'),
    insOrder: db.prepare("INSERT INTO orders (account_id, base, quote, side, type, price, size, filled, status, tif, post_only, idempotency_key, created_at, seq) VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, (SELECT COALESCE(MAX(seq),0)+1 FROM orders))"),
    order: db.prepare('SELECT * FROM orders WHERE id = ?'),
    orderByKey: db.prepare('SELECT * FROM orders WHERE idempotency_key = ?'),
    ordersOf: db.prepare('SELECT * FROM orders WHERE account_id = ? ORDER BY id'),
    restingBuys: db.prepare("SELECT * FROM orders WHERE base = ? AND quote = ? AND side = 'buy' AND status IN ('open','partial') ORDER BY price DESC, seq ASC"),
    restingSells: db.prepare("SELECT * FROM orders WHERE base = ? AND quote = ? AND side = 'sell' AND status IN ('open','partial') ORDER BY price ASC, seq ASC"),
    setOrder: db.prepare('UPDATE orders SET filled = ?, status = ? WHERE id = ?'),
    insFill: db.prepare('INSERT INTO fills (taker_order, maker_order, base, quote, price, size, taker_fee, maker_fee, taker_account, maker_account, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'),
    fills: db.prepare('SELECT * FROM fills WHERE base = ? AND quote = ? ORDER BY id'),
    feeTiers: db.prepare('SELECT * FROM fee_tiers ORDER BY tier'),
    feeTierFor: db.prepare('SELECT * FROM fee_tiers WHERE min_volume_micro <= ? ORDER BY tier DESC LIMIT 1'),
    addVolume: db.prepare('UPDATE accounts SET volume_usd_micro = volume_usd_micro + ? WHERE id = ?'),
    // v2: api keys
    insApiKey: db.prepare('INSERT INTO api_keys (key, account_id, scope, rate_per_min, revoked, created_at) VALUES (?, ?, ?, ?, 0, ?)'),
    apiKey: db.prepare('SELECT * FROM api_keys WHERE key = ?'),
    apiKeysOf: db.prepare('SELECT * FROM api_keys WHERE account_id = ? ORDER BY created_at'),
    revokeApiKey: db.prepare('UPDATE api_keys SET revoked = 1 WHERE key = ?'),
    // v2: stakes
    insStake: db.prepare("INSERT INTO stakes (account_id, asset, principal, apr_bps, elapsed_seconds, accrued, status, idempotency_key, created_at) VALUES (?, ?, ?, ?, 0, 0, 'active', ?, ?)"),
    stake: db.prepare('SELECT * FROM stakes WHERE id = ?'),
    stakeByKey: db.prepare('SELECT * FROM stakes WHERE idempotency_key = ?'),
    stakesOf: db.prepare('SELECT * FROM stakes WHERE account_id = ? ORDER BY id'),
    setStakeAccrual: db.prepare('UPDATE stakes SET elapsed_seconds = ?, accrued = ? WHERE id = ?'),
    setStakeStatus: db.prepare('UPDATE stakes SET status = ? WHERE id = ?'),
  };

  const assetOr = (sym) => { const a = q.asset.get(String(sym)); if (!a) throw new H.ApiError(404, 'not_found', 'no such asset: ' + sym); return a; };
  const bal = (accountId, asset) => { const r = q.balance.get(accountId, asset); return r ? Number(r.amount) : 0; };
  /** The spendable balance: total minus what resting orders and stakes hold. */
  const avail = (accountId, asset) => { const r = q.balanceRow.get(accountId, asset); return r ? Number(r.amount) - Number(r.reserved) : 0; };
  const SECONDS_PER_YEAR = 31536000n;

  /**
   * Move value: write one balance change and its ledger line. Caller is inside
   * a transaction. An existing row is UPDATEd (the CHECK amount>=0 is evaluated
   * on the resulting balance, the backstop against an overdraw); a first row is
   * INSERTed, which only happens for a credit. We never INSERT a negative VALUES
   * -- SQLite would fail its CHECK before an UPSERT could resolve to an update.
   */
  function move(accountId, asset, delta, reason, refType, refId) {
    if (delta === 0) throw new Error('zero move');
    if (q.balance.get(accountId, asset)) q.addBalance.run(delta, accountId, asset);
    else q.insBalance.run(accountId, asset, delta);
    q.insLedger.run(accountId, asset, delta, reason, refType || null, refId || null, now());
  }

  // Auth is either the account's Bearer token (owner, full rights) or a scoped
  // X-API-Key. A key is rate-limited per minute; the owner token is not.
  const rateHits = new Map();  // key -> { windowStart, count }
  function rateLimit(key, perMin) {
    const t = now();
    let h = rateHits.get(key);
    if (!h || t - h.windowStart >= 60) { h = { windowStart: t, count: 0 }; rateHits.set(key, h); }
    h.count += 1;
    if (h.count > perMin) throw new H.ApiError(429, 'rate_limited', 'API key exceeded its per-minute rate', { rate_per_min: perMin });
  }
  function requireAccount(req) {
    const m = /^Bearer\s+(\S+)$/i.exec(req.headers.authorization || '');
    if (m) { const a = q.accountByToken.get(m[1]); if (!a) throw new H.ApiError(401, 'unauthenticated', 'unknown token'); return a; }
    const key = req.headers['x-api-key'];
    if (key) {
      const k = q.apiKey.get(String(key));
      if (!k || k.revoked) throw new H.ApiError(401, 'bad_key', 'unknown or revoked API key');
      rateLimit(String(key), k.rate_per_min);
      return q.accountById.get(k.account_id);
    }
    throw new H.ApiError(401, 'unauthenticated', 'a Bearer token or X-API-Key is required');
  }
  /** Minting or revoking API keys needs the account's own Bearer token, never a key. */
  function requireOwner(req) {
    const m = /^Bearer\s+(\S+)$/i.exec(req.headers.authorization || '');
    if (!m) throw new H.ApiError(401, 'unauthenticated', 'an owner Bearer token is required');
    const a = q.accountByToken.get(m[1]);
    if (!a) throw new H.ApiError(401, 'unauthenticated', 'unknown token');
    return a;
  }
  /** The scope the request carries: an owner Bearer is full ('withdraw'); a key is its own scope. */
  function scopeOf(req) {
    if (/^Bearer\s+\S+/i.test(req.headers.authorization || '')) return 'withdraw';
    const k = req.headers['x-api-key'] ? q.apiKey.get(String(req.headers['x-api-key'])) : null;
    return k ? k.scope : 'read';
  }
  function requireScope(req, _acct, needed) {
    const rank = { read: 1, trade: 2, withdraw: 3 };
    if (rank[scopeOf(req)] < rank[needed]) throw new H.ApiError(403, 'wrong_scope', 'the key lacks the ' + needed + ' scope', { scope: scopeOf(req), needed });
  }

  /** Quote a swap. Returns { pair, fromAmount, gross, fee, net, rateMicro } in base units. */
  function quoteSwap(fromSym, toSym, fromAmount) {
    const from = assetOr(fromSym); const to = assetOr(toSym);
    if (from.symbol === to.symbol) throw new H.ApiError(400, 'bad_request', 'from_asset and to_asset must differ');
    if (!from.active || !to.active) throw new H.ApiError(409, 'asset_inactive', 'an asset is not active');
    const pair = q.pairEither.get(from.symbol, to.symbol, to.symbol, from.symbol);
    if (!pair || !pair.active) throw new H.ApiError(409, 'no_pair', 'no active pair for those assets');
    if (from.symbol === pair.base && fromAmount < pair.min_base) throw new H.ApiError(400, 'below_min', 'below the pair minimum', { min_base: pair.min_base });
    const fa = BigInt(fromAmount);
    const usdMicro = (fa * BigInt(from.usd_micro)) / SCALE;
    const gross = (usdMicro * SCALE) / BigInt(to.usd_micro);
    if (gross <= 0n) throw new H.ApiError(400, 'dust', 'amount too small to quote');
    const fee = (gross * BigInt(pair.fee_bps)) / 10000n;
    const net = gross - fee;
    const rateMicro = (BigInt(from.usd_micro) * 1000000n) / BigInt(to.usd_micro);
    return { pair, fromAmount, gross: Number(gross), fee: Number(fee), net: Number(net), rateMicro: Number(rateMicro), usdMicro };
  }

  // ----------------------------------------------------------- v2: order book

  /** Lock funds a resting order holds. Caller is inside a transaction. */
  function reserve(accountId, asset, amt) {
    if (avail(accountId, asset) < amt) throw new H.ApiError(409, 'insufficient_funds', 'not enough available balance', { asset, available: avail(accountId, asset), needed: amt });
    q.reserveAdd.run(amt, accountId, asset);   // CHECK reserved<=amount is the backstop
  }
  function release(accountId, asset, amt) { if (amt !== 0) q.reserveAdd.run(-amt, accountId, asset); }
  /** Spend `amt` that was reserved: it leaves both amount and reserved, with a ledger line. */
  function settleReserved(accountId, asset, amt, reason, refId) {
    if (amt <= 0) return;
    // Reduce reserved BEFORE amount: the CHECK reserved<=amount is evaluated on
    // every UPDATE, and debiting amount first would momentarily leave
    // reserved > amount when the whole balance was reserved.
    q.reserveAdd.run(-amt, accountId, asset);
    q.addBalance.run(-amt, accountId, asset);
    q.insLedger.run(accountId, asset, -amt, reason, 'order', refId || null, now());
  }
  const quoteCost = (sizeBase, price) => (BigInt(sizeBase) * BigInt(price)) / SCALE; // quote base-units
  const usdOfBase = (asset, sizeBase) => (BigInt(sizeBase) * BigInt(assetOr(asset).usd_micro)) / SCALE;
  function feeBps(accountId) {
    const acc = q.accountById.get(accountId);
    const t = q.feeTierFor.get(acc.volume_usd_micro) || { maker_bps: 0, taker_bps: 0, tier: 0 };
    return t;
  }

  /**
   * Match a freshly-placed taker order against the resting book, price-time
   * priority, skipping the taker's own orders (self-trade prevention). Writes
   * fills and moves balances leg by leg. Returns the base amount filled. Caller
   * is inside a transaction; `o` is the just-inserted order row.
   */
  function matchTaker(o) {
    const makers = o.side === 'buy' ? q.restingSells.all(o.base, o.quote) : q.restingBuys.all(o.base, o.quote);
    let remaining = o.size;
    let filled = 0;
    const takerTier = feeBps(o.account_id);
    for (const m of makers) {
      if (remaining <= 0) break;
      if (m.account_id === o.account_id) continue;                       // self-trade prevention
      if (o.type === 'limit') {                                          // price gate
        if (o.side === 'buy' && m.price > o.price) break;                // best sell too expensive
        if (o.side === 'sell' && m.price < o.price) break;              // best buy too cheap
      }
      const mRemaining = m.size - m.filled;
      const matchSize = Math.min(remaining, mRemaining);
      if (matchSize <= 0) continue;
      const px = m.price;                                                // trade at the maker's price
      // market buy with no reserve: stop if the taker cannot afford this slice
      if (o.type === 'market' && o.side === 'buy') {
        const cost = Number(quoteCost(matchSize, px));
        if (avail(o.account_id, o.quote) < cost) break;
      }
      settleFill(o, m, matchSize, px, takerTier);
      remaining -= matchSize; filled += matchSize;
    }
    return filled;
  }

  /** One match: move base and quote between taker and maker, take fees, record it. */
  function settleFill(o, m, size, px, takerTier) {
    const makerTier = feeBps(m.account_id);
    const cost = Number(quoteCost(size, px));                            // quote base-units traded
    const buy = o.side === 'buy';
    // taker output leg + fee (fee is on what each side RECEIVES)
    const takerOutAsset = buy ? o.base : o.quote;
    const takerOutGross = buy ? size : cost;
    const takerFee = Math.floor((takerOutGross * takerTier.taker_bps) / 10000);
    const makerOutAsset = buy ? o.quote : o.base;
    const makerOutGross = buy ? cost : size;
    const makerFee = Math.floor((makerOutGross * makerTier.maker_bps) / 10000); // may be < 0 (rebate)

    if (buy) {
      // taker spends quote (reserved for limit; direct for market), receives base
      if (o.type === 'limit') { settleReserved(o.account_id, o.quote, cost, 'trade_out', o.id); release(o.account_id, o.quote, Number(quoteCost(size, o.price)) - cost); }
      else { q.addBalance.run(-cost, o.account_id, o.quote); q.insLedger.run(o.account_id, o.quote, -cost, 'trade_out', 'order', o.id, now()); }
      credit(o.account_id, o.base, size - takerFee, 'trade_in', o.id);
      // maker (a sell): base was reserved, receives quote
      settleReserved(m.account_id, m.base, size, 'trade_out', m.id);
      credit(m.account_id, m.quote, cost - makerFee, 'trade_in', m.id);
    } else {
      // taker sells base (reserved), receives quote
      settleReserved(o.account_id, o.base, size, 'trade_out', o.id);
      credit(o.account_id, o.quote, cost - takerFee, 'trade_in', o.id);
      // maker (a buy): quote was reserved at its price, receives base
      settleReserved(m.account_id, m.quote, cost, 'trade_out', m.id); release(m.account_id, m.quote, Number(quoteCost(size, m.price)) - cost);
      credit(m.account_id, m.base, size - makerFee, 'trade_in', m.id);
    }
    // advance the maker
    const mFilled = m.filled + size;
    q.setOrder.run(mFilled, mFilled >= m.size ? 'filled' : 'partial', m.id);
    m.filled = mFilled;
    // record the fill + the taker's traded volume (drives their fee tier)
    q.insFill.run(o.id, m.id, o.base, o.quote, px, size, takerFee, makerFee, o.account_id, m.account_id, now());
    q.addVolume.run(Number(usdOfBase(o.base, size)), o.account_id);
  }

  function credit(accountId, asset, amt, reason, refId) {
    if (amt === 0) return;
    if (amt < 0) throw new Error('negative credit');
    if (q.balance.get(accountId, asset)) q.addBalance.run(amt, accountId, asset);
    else q.insBalance.run(accountId, asset, amt);
    q.insLedger.run(accountId, asset, amt, reason, 'order', refId || null, now());
  }

  const orderView = (o) => ({ id: o.id, base: o.base, quote: o.quote, side: o.side, type: o.type, price: o.price, size: o.size, filled: o.filled, status: o.status, tif: o.tif, post_only: !!o.post_only });

  async function route(req, res, url) {
    const parts = url.pathname.replace(/\/+$/, '').split('/').filter(Boolean);
    const [a, b, c] = parts;
    const wantsHtml = (req.headers.accept || '').includes('text/html');

    // ---- HTML pages (for Playwright) ----
    if (req.method === 'GET' && parts.length === 0) return renderHome(res);
    if (req.method === 'GET' && a === 'wallet' && b) return renderWallet(res, b);
    if (req.method === 'GET' && a === 'op' && b) return renderOp(res, b);
    if (req.method === 'GET' && a === 'forms' && b) return renderForm(res, b);

    // ---- read-only market data ----
    if (req.method === 'GET' && a === 'assets') {
      return json(res, 200, { assets: q.assets.all().map((x) => ({ symbol: x.symbol, name: x.name, kind: x.kind, decimals: x.decimals, usd_micro: x.usd_micro, active: !!x.active })) });
    }
    if (req.method === 'GET' && a === 'pairs') {
      return json(res, 200, { pairs: q.pairs.all().map((p) => ({ base: p.base, quote: p.quote, fee_bps: p.fee_bps, min_base: p.min_base, active: !!p.active })) });
    }
    if (req.method === 'POST' && a === 'quote') {
      const body = await readBody(req);
      const qv = quoteSwap(body.from_asset, body.to_asset, amountOf(body.from_amount));
      return json(res, 200, { from_asset: body.from_asset, to_asset: body.to_asset, from_amount: qv.fromAmount, to_amount: qv.net, gross_amount: qv.gross, fee_amount: qv.fee, fee_bps: qv.pair.fee_bps, rate_micro: qv.rateMicro });
    }

    // ---- market data: order book, fills, fee schedule ----
    if (req.method === 'GET' && a === 'orderbook' && b && c) {
      const agg = (rows) => { const m = new Map(); for (const o of rows) { const rem = o.size - o.filled; if (rem > 0) m.set(o.price, (m.get(o.price) || 0) + rem); } return [...m.entries()].map(([price, size]) => ({ price, size })); };
      return json(res, 200, { base: b, quote: c, bids: agg(q.restingBuys.all(b, c)), asks: agg(q.restingSells.all(b, c)) });
    }
    if (req.method === 'GET' && a === 'fills') {
      const base = url.searchParams.get('base'); const quote = url.searchParams.get('quote');
      const rows = base && quote ? q.fills.all(base, quote) : [];
      return json(res, 200, { fills: rows.map((f) => ({ id: f.id, base: f.base, quote: f.quote, price: f.price, size: f.size, taker_fee: f.taker_fee, maker_fee: f.maker_fee, taker_order: f.taker_order, maker_order: f.maker_order })) });
    }
    if (req.method === 'GET' && a === 'fees' && !b) return json(res, 200, { tiers: q.feeTiers.all() });
    if (req.method === 'GET' && a === 'fees' && b) {
      const acct = q.accountByHandle.get(b);
      if (!acct) throw new H.ApiError(404, 'not_found', 'no such account');
      const t = q.feeTierFor.get(acct.volume_usd_micro) || {};
      return json(res, 200, { handle: acct.handle, volume_usd_micro: acct.volume_usd_micro, tier: t.tier, maker_bps: t.maker_bps, taker_bps: t.taker_bps });
    }
    if (req.method === 'GET' && a === 'orders' && b) {
      const acct = q.accountByHandle.get(b);
      if (!acct) throw new H.ApiError(404, 'not_found', 'no such account');
      const status = url.searchParams.get('status');
      let rows = q.ordersOf.all(acct.id);
      if (status && status !== 'all') rows = rows.filter((o) => o.status === status);
      return json(res, 200, { handle: acct.handle, orders: rows.map(orderView) });
    }

    // ---- place / cancel an order ----
    if (req.method === 'POST' && a === 'orders' && !b) {
      const acct = requireAccount(req); requireScope(req, acct, 'trade'); const body = await readBody(req);
      const base = String(body.base || ''); const quote = String(body.quote || '');
      const pair = q.pair.get(base, quote);
      if (!pair) throw new H.ApiError(404, 'no_pair', 'no such pair ' + base + '/' + quote);
      if (!pair.active) throw new H.ApiError(409, 'pair_inactive', 'pair is not active');
      const side = body.side; if (side !== 'buy' && side !== 'sell') throw new H.ApiError(400, 'bad_request', 'side must be buy or sell');
      const type = body.type || 'limit'; if (type !== 'limit' && type !== 'market') throw new H.ApiError(400, 'bad_request', 'type must be limit or market');
      let tif = body.tif || 'GTC'; if (!['GTC', 'IOC', 'FOK'].includes(tif)) throw new H.ApiError(400, 'bad_request', 'tif must be GTC, IOC or FOK');
      const postOnly = body.post_only ? 1 : 0;
      const size = amountOf(body.size);
      if (size < pair.min_base) throw new H.ApiError(400, 'below_min', 'below the pair minimum', { min_base: pair.min_base });
      let price = null;
      if (type === 'limit') price = amountOf(body.price);
      else { tif = tif === 'GTC' ? 'IOC' : tif; if (postOnly) throw new H.ApiError(400, 'bad_request', 'a market order cannot be post_only'); }
      const key = body.idempotency_key ? String(body.idempotency_key) : null;
      if (key) { const prior = q.orderByKey.get(key); if (prior) return json(res, 200, { ...orderView(prior), idempotent_replay: true }); }
      let id;
      tx(() => {
        const info = q.insOrder.run(acct.id, base, quote, side, type, price, size, 'open', tif, postOnly, key, now());
        id = Number(info.lastInsertRowid);
        const o = q.order.get(id);
        if (type === 'limit') { if (side === 'buy') reserve(acct.id, quote, Number(quoteCost(size, price))); else reserve(acct.id, base, size); }
        else if (side === 'sell') reserve(acct.id, base, size);            // market buy pays per fill
        if (postOnly) {
          const best = (side === 'buy' ? q.restingSells.all(base, quote) : q.restingBuys.all(base, quote)).find((m) => m.account_id !== acct.id);
          const crosses = best && (side === 'buy' ? best.price <= price : best.price >= price);
          if (crosses) throw new H.ApiError(409, 'would_cross', 'a post-only order would cross the book');
        }
        const filled = matchTaker(o);
        let status;
        if (filled >= size) status = 'filled';
        else if (type === 'limit' && tif === 'GTC') status = filled > 0 ? 'partial' : 'open';
        else {
          if (tif === 'FOK' && filled < size) throw new H.ApiError(409, 'fok_unfilled', 'fill-or-kill could not fully fill');
          const rem = size - filled;
          if (type === 'limit') { if (side === 'buy') release(acct.id, quote, Number(quoteCost(rem, price))); else release(acct.id, base, rem); }
          else if (side === 'sell') release(acct.id, base, rem);
          status = 'cancelled';
        }
        q.setOrder.run(filled, status, id);
      });
      return json(res, 201, orderView(q.order.get(id)));
    }
    if (req.method === 'DELETE' && a === 'orders' && b) {
      const acct = requireAccount(req); requireScope(req, acct, 'trade');
      const o = q.order.get(Number(b));
      if (!o) throw new H.ApiError(404, 'not_found', 'no such order');
      if (o.account_id !== acct.id) throw new H.ApiError(403, 'forbidden', 'not your order');
      if (o.status !== 'open' && o.status !== 'partial') throw new H.ApiError(409, 'not_open', 'order is not open', { status: o.status });
      tx(() => {
        const rem = o.size - o.filled;
        if (o.side === 'buy') release(acct.id, o.quote, Number(quoteCost(rem, o.price)));
        else release(acct.id, o.base, rem);
        q.setOrder.run(o.filled, 'cancelled', o.id);
      });
      return json(res, 200, orderView(q.order.get(o.id)));
    }

    // ---- accounts ----
    if (req.method === 'POST' && a === 'accounts' && !b) {
      const body = await readBody(req);
      const handle = String(body.handle || '').trim();
      if (!/^[a-zA-Z0-9_.-]{3,40}$/.test(handle)) throw new H.ApiError(400, 'bad_request', 'handle must be 3-40 chars [a-zA-Z0-9_.-]');
      if (q.accountByHandle.get(handle)) throw new H.ApiError(409, 'handle_taken', 'that handle is taken');
      const tok = H.token('acct');
      const info = q.insAccount.run(handle, tok, now());
      return json(res, 201, { id: Number(info.lastInsertRowid), handle, token: tok });
    }
    if (req.method === 'GET' && a === 'accounts' && b) {
      const acct = q.accountByHandle.get(b);
      if (!acct) throw new H.ApiError(404, 'not_found', 'no such account');
      return json(res, 200, accountView(acct));
    }
    if (req.method === 'GET' && a === 'balances' && b) {
      const acct = q.accountByHandle.get(b);
      if (!acct) throw new H.ApiError(404, 'not_found', 'no such account');
      return json(res, 200, { handle: acct.handle, balances: q.balancesOf.all(acct.id) });
    }

    // ---- deposit / withdraw (against the outside world, no bridge) ----
    if (req.method === 'POST' && a === 'deposit') {
      const acct = requireAccount(req); requireScope(req, acct, 'trade'); const body = await readBody(req);
      assetOr(body.asset); const amount = amountOf(body.amount);
      const key = body.idempotency_key ? String(body.idempotency_key) : null;
      if (key) { const prior = q.transferByKey.get(key); if (prior) return json(res, 200, { ...transferView(prior), idempotent_replay: true }); }
      let id;
      tx(() => { const info = q.insTransfer.run(null, acct.id, body.asset, amount, 'deposit', key, now()); id = Number(info.lastInsertRowid); move(acct.id, body.asset, amount, 'deposit', 'transfer', id); });
      return json(res, 201, transferView(q.transfer.get(id)));
    }
    if (req.method === 'POST' && a === 'withdraw') {
      const acct = requireAccount(req); requireScope(req, acct, 'withdraw'); const body = await readBody(req);
      assetOr(body.asset); const amount = amountOf(body.amount);
      const key = body.idempotency_key ? String(body.idempotency_key) : null;
      if (key) { const prior = q.transferByKey.get(key); if (prior) return json(res, 200, { ...transferView(prior), idempotent_replay: true }); }
      if (avail(acct.id, body.asset) < amount) throw new H.ApiError(409, 'insufficient_funds', 'not enough balance', { asset: body.asset, available: avail(acct.id, body.asset), requested: amount });
      let id;
      tx(() => { const info = q.insTransfer.run(acct.id, null, body.asset, amount, 'withdraw', key, now()); id = Number(info.lastInsertRowid); move(acct.id, body.asset, -amount, 'withdraw', 'transfer', id); });
      return json(res, 201, transferView(q.transfer.get(id)));
    }

    // ---- internal transfer ----
    if (req.method === 'POST' && a === 'transfer') {
      const acct = requireAccount(req); requireScope(req, acct, 'trade'); const body = await readBody(req);
      assetOr(body.asset); const amount = amountOf(body.amount);
      const to = q.accountByHandle.get(String(body.to_handle || ''));
      if (!to) throw new H.ApiError(404, 'not_found', 'no such recipient');
      if (to.id === acct.id) throw new H.ApiError(400, 'self_transfer', 'cannot transfer to yourself');
      const key = body.idempotency_key ? String(body.idempotency_key) : null;
      if (key) { const prior = q.transferByKey.get(key); if (prior) return json(res, 200, { ...transferView(prior), idempotent_replay: true }); }
      if (avail(acct.id, body.asset) < amount) throw new H.ApiError(409, 'insufficient_funds', 'not enough balance', { asset: body.asset, available: avail(acct.id, body.asset), requested: amount });
      let id;
      tx(() => {
        const info = q.insTransfer.run(acct.id, to.id, body.asset, amount, 'internal', key, now());
        id = Number(info.lastInsertRowid);
        move(acct.id, body.asset, -amount, 'transfer_out', 'transfer', id);
        move(to.id, body.asset, amount, 'transfer_in', 'transfer', id);
      });
      return json(res, 201, transferView(q.transfer.get(id)));
    }

    // ---- swap ----
    if (req.method === 'POST' && a === 'swap') {
      const acct = requireAccount(req); requireScope(req, acct, 'trade'); const body = await readBody(req);
      const amount = amountOf(body.from_amount);
      const key = body.idempotency_key ? String(body.idempotency_key) : null;
      if (key) { const prior = q.swapByKey.get(key); if (prior) return json(res, 200, { ...swapView(prior), idempotent_replay: true }); }
      const qv = quoteSwap(body.from_asset, body.to_asset, amount);  // validates assets/pair/min
      if (body.min_to_amount !== undefined && qv.net < Number(body.min_to_amount)) throw new H.ApiError(409, 'slippage', 'quote is below min_to_amount', { quoted: qv.net, min_to_amount: Number(body.min_to_amount) });
      if (avail(acct.id, body.from_asset) < amount) throw new H.ApiError(409, 'insufficient_funds', 'not enough balance', { asset: body.from_asset, available: avail(acct.id, body.from_asset), requested: amount });
      let id;
      tx(() => {
        const info = q.insSwap.run(acct.id, body.from_asset, body.to_asset, amount, qv.net, qv.fee, qv.rateMicro, key, now());
        id = Number(info.lastInsertRowid);
        move(acct.id, body.from_asset, -amount, 'swap_out', 'swap', id);
        move(acct.id, body.to_asset, qv.net, 'swap_in', 'swap', id);
      });
      return json(res, 201, swapView(q.swap.get(id)));
    }

    // ---- bridge ----
    if (req.method === 'POST' && a === 'bridge' && b === 'withdraw') {
      const acct = requireAccount(req); requireScope(req, acct, 'withdraw'); const body = await readBody(req);
      const asset = assetOr(body.asset); const amount = amountOf(body.amount);
      const dst = String(body.dst_chain || '');
      if (!CHAINS.includes(dst)) throw new H.ApiError(400, 'unknown_chain', 'unsupported destination chain', { supported: CHAINS });
      const usd = (BigInt(amount) * BigInt(asset.usd_micro)) / SCALE;
      if (usd > BRIDGE_CAP_USD_MICRO) throw new H.ApiError(409, 'over_cap', 'bridge amount exceeds the per-transaction cap', { cap_usd: Number(BRIDGE_CAP_USD_MICRO / 1000000n) });
      if (avail(acct.id, body.asset) < amount) throw new H.ApiError(409, 'insufficient_funds', 'not enough balance', { asset: body.asset, available: avail(acct.id, body.asset), requested: amount });
      const ext = H.token('wtx');
      let id;
      tx(() => {
        const info = q.insBridge.run(acct.id, body.asset, amount, 'withdraw', 'mini-cex', dst, 'locked', ext, now(), now());
        id = Number(info.lastInsertRowid);
        move(acct.id, body.asset, -amount, 'bridge_debit', 'bridge', id);   // lock: debit now
      });
      return json(res, 201, bridgeView(q.bridge.get(id)));
    }
    if (req.method === 'POST' && a === 'bridge' && b === 'deposit') {
      const body = await readBody(req);
      const acct = q.accountByHandle.get(String(body.handle || ''));
      if (!acct) throw new H.ApiError(404, 'not_found', 'no such account');
      const asset = assetOr(body.asset); const amount = amountOf(body.amount);
      const src = String(body.src_chain || ''); const ext = String(body.ext_tx || '');
      if (!CHAINS.includes(src)) throw new H.ApiError(400, 'unknown_chain', 'unsupported source chain', { supported: CHAINS });
      if (!ext) throw new H.ApiError(400, 'bad_request', 'ext_tx is required');
      const prior = q.bridgeByExt.get('deposit', ext);
      if (prior) return json(res, 200, { ...bridgeView(prior), idempotent_replay: true });  // observed before -> credit once
      let id;
      tx(() => {
        const info = q.insBridge.run(acct.id, asset.symbol, amount, 'deposit', src, 'mini-cex', 'credited', ext, now(), now());
        id = Number(info.lastInsertRowid);
        move(acct.id, asset.symbol, amount, 'bridge_credit', 'bridge', id);
      });
      return json(res, 201, bridgeView(q.bridge.get(id)));
    }
    if (req.method === 'POST' && a === 'bridge' && b && c === 'confirm') {
      const op = q.bridge.get(Number(b));
      if (!op) throw new H.ApiError(404, 'not_found', 'no such bridge op');
      if (op.direction !== 'withdraw') throw new H.ApiError(409, 'not_confirmable', 'only a withdrawal is confirmed');
      if (op.status === 'credited') return json(res, 200, { ...bridgeView(op), idempotent_replay: true });
      if (op.status !== 'locked') throw new H.ApiError(409, 'bad_state', 'op is not locked', { status: op.status });
      q.setBridgeStatus.run('credited', now(), op.id);   // relayer settled it on the destination
      return json(res, 200, bridgeView(q.bridge.get(op.id)));
    }
    if (req.method === 'GET' && a === 'bridge' && b) {
      const op = q.bridge.get(Number(b));
      if (!op) throw new H.ApiError(404, 'not_found', 'no such bridge op');
      return json(res, 200, bridgeView(op));
    }

    // ---- API keys (minted with the owner Bearer, then used via X-API-Key) ----
    if (req.method === 'POST' && a === 'apikeys' && !b) {
      const acct = requireOwner(req); const body = await readBody(req);
      const scope = body.scope;
      if (!['read', 'trade', 'withdraw'].includes(scope)) throw new H.ApiError(400, 'bad_request', 'scope must be read, trade or withdraw');
      const rate = body.rate_per_min === undefined ? 120 : Number(body.rate_per_min);
      if (!Number.isInteger(rate) || rate < 1) throw new H.ApiError(400, 'bad_request', 'rate_per_min must be a positive integer');
      const key = H.token('key');
      q.insApiKey.run(key, acct.id, scope, rate, now());
      return json(res, 201, { key, scope, rate_per_min: rate, account: acct.handle });
    }
    if (req.method === 'DELETE' && a === 'apikeys' && b) {
      const acct = requireOwner(req);
      const k = q.apiKey.get(b);
      if (!k) throw new H.ApiError(404, 'not_found', 'no such key');
      if (k.account_id !== acct.id) throw new H.ApiError(403, 'forbidden', 'not your key');
      q.revokeApiKey.run(b);
      return json(res, 200, { key: b, revoked: true });
    }
    if (req.method === 'GET' && a === 'apikeys' && b) {
      const acct = q.accountByHandle.get(b);
      if (!acct) throw new H.ApiError(404, 'not_found', 'no such account');
      return json(res, 200, { handle: acct.handle, keys: q.apiKeysOf.all(acct.id).map((k) => ({ key_prefix: k.key.slice(0, 12), scope: k.scope, rate_per_min: k.rate_per_min, revoked: !!k.revoked })) });
    }

    // ---- staking / earn ----
    if (req.method === 'POST' && a === 'stake' && !b) {
      const acct = requireAccount(req); requireScope(req, acct, 'trade'); const body = await readBody(req);
      const asset = assetOr(body.asset); const principal = amountOf(body.amount);
      const apr = body.apr_bps === undefined ? 500 : Number(body.apr_bps);
      if (!Number.isInteger(apr) || apr < 0) throw new H.ApiError(400, 'bad_request', 'apr_bps must be a non-negative integer');
      const key = body.idempotency_key ? String(body.idempotency_key) : null;
      if (key) { const prior = q.stakeByKey.get(key); if (prior) return json(res, 200, { ...stakeView(prior), idempotent_replay: true }); }
      if (avail(acct.id, asset.symbol) < principal) throw new H.ApiError(409, 'insufficient_funds', 'not enough available balance', { asset: asset.symbol, available: avail(acct.id, asset.symbol), requested: principal });
      let id;
      tx(() => {
        const info = q.insStake.run(acct.id, asset.symbol, principal, apr, key, now());
        id = Number(info.lastInsertRowid);
        move(acct.id, asset.symbol, -principal, 'stake_lock', 'stake', id);   // principal leaves the balance while locked
      });
      return json(res, 201, stakeView(q.stake.get(id)));
    }
    if (req.method === 'POST' && a === 'stake' && b && c === 'accrue') {
      const acct = requireAccount(req); requireScope(req, acct, 'trade'); const body = await readBody(req);
      const s = q.stake.get(Number(b));
      if (!s) throw new H.ApiError(404, 'not_found', 'no such stake');
      if (s.account_id !== acct.id) throw new H.ApiError(403, 'forbidden', 'not your stake');
      if (s.status !== 'active') throw new H.ApiError(409, 'not_active', 'stake is not active');
      const seconds = amountOf(body.seconds);
      const reward = Number((BigInt(s.principal) * BigInt(s.apr_bps) * BigInt(seconds)) / (SECONDS_PER_YEAR * 10000n));
      q.setStakeAccrual.run(s.elapsed_seconds + seconds, s.accrued + reward, s.id);
      return json(res, 200, stakeView(q.stake.get(s.id)));
    }
    if (req.method === 'POST' && a === 'stake' && b && c === 'redeem') {
      const acct = requireAccount(req); requireScope(req, acct, 'trade');
      const s = q.stake.get(Number(b));
      if (!s) throw new H.ApiError(404, 'not_found', 'no such stake');
      if (s.account_id !== acct.id) throw new H.ApiError(403, 'forbidden', 'not your stake');
      if (s.status === 'redeemed') return json(res, 200, { ...stakeView(s), idempotent_replay: true });
      tx(() => {
        move(acct.id, s.asset, s.principal, 'stake_unlock', 'stake', s.id);
        if (s.accrued > 0) move(acct.id, s.asset, s.accrued, 'stake_reward', 'stake', s.id);
        q.setStakeStatus.run('redeemed', s.id);
      });
      return json(res, 200, stakeView(q.stake.get(s.id)));
    }
    if (req.method === 'GET' && a === 'stakes' && b) {
      const acct = q.accountByHandle.get(b);
      if (!acct) throw new H.ApiError(404, 'not_found', 'no such account');
      return json(res, 200, { handle: acct.handle, stakes: q.stakesOf.all(acct.id).map(stakeView) });
    }

    if (['GET', 'POST', 'PATCH', 'DELETE'].includes(req.method)) throw new H.ApiError(404, 'not_found', 'no such route');
    throw new H.ApiError(405, 'method_not_allowed', 'method not allowed');
  }

  /** Run fn in one IMMEDIATE transaction; roll back on any throw. */
  function tx(fn) {
    db.exec('BEGIN IMMEDIATE');
    try { fn(); db.exec('COMMIT'); } catch (err) { db.exec('ROLLBACK'); throw err; }
  }

  const accountView = (a) => ({ handle: a.handle, balances: q.balancesOf.all(a.id) });
  const transferView = (t) => ({ id: t.id, kind: t.kind, asset: t.asset, amount: t.amount, from_account: t.from_account, to_account: t.to_account });
  const swapView = (s) => ({ id: s.id, from_asset: s.from_asset, to_asset: s.to_asset, from_amount: s.from_amount, to_amount: s.to_amount, fee_amount: s.fee_amount, rate_micro: s.rate_micro });
  const bridgeView = (o) => ({ id: o.id, direction: o.direction, asset: o.asset, amount: o.amount, src_chain: o.src_chain, dst_chain: o.dst_chain, status: o.status, ext_tx: o.ext_tx });
  const stakeView = (s) => ({ id: s.id, asset: s.asset, principal: s.principal, apr_bps: s.apr_bps, elapsed_seconds: s.elapsed_seconds, accrued: s.accrued, status: s.status });

  // ---- HTML renderers (minimal, labelled for Playwright) ----
  function renderHome(res) {
    const rows = q.assets.all().map((x) => `<li class="asset" data-symbol="${esc(x.symbol)}"><span class="symbol">${esc(x.symbol)}</span> <span class="name">${esc(x.name)}</span> <span class="usd">$${(x.usd_micro / 1e6).toFixed(2)}</span> <span class="active">${x.active ? 'listed' : 'delisted'}</span></li>`).join('');
    const nav = '<nav class="forms"><a href="/forms/transfer">Transfer</a> · <a href="/forms/swap">Swap</a> · <a href="/forms/bridge">Bridge</a></nav>';
    return html(res, 200, `<title>mini-cex</title><h1>mini-cex</h1>${nav}<ul class="assets">${rows}</ul>`);
  }
  function renderWallet(res, handle) {
    const acct = q.accountByHandle.get(handle);
    if (!acct) return html(res, 404, '<title>wallet</title><p>no such account</p>');
    const rows = q.balancesOf.all(acct.id).map((r) => `<li class="balance" data-asset="${esc(r.asset)}"><span class="asset">${esc(r.asset)}</span> <span class="amount">${(r.amount / 1e8)}</span></li>`).join('');
    return html(res, 200, `<title>wallet ${esc(handle)}</title><h1 class="handle">${esc(handle)}</h1><ul class="balances">${rows}</ul>`);
  }
  function renderOp(res, id) {
    const op = q.bridge.get(Number(id));
    if (!op) return html(res, 404, '<title>op</title><p>no such op</p>');
    return html(res, 200, `<title>bridge op ${op.id}</title><h1 class="op-id">Op ${op.id}</h1><p class="direction">${esc(op.direction)}</p><p class="status">${esc(op.status)}</p><p class="amount">${(op.amount / 1e8)} ${esc(op.asset)}</p>`);
  }

  /**
   * An interactive form for one write path. The submit handler POSTs to the
   * same REST endpoint the API tier tests, converting the decimal-coin amount
   * to base units, and writes the outcome (status + code + a result line) into
   * #result -- so a Playwright test can drive a real transfer/swap/bridge
   * through the browser and read what happened. The bearer token is a field
   * because mini-cex has no session; that is fine for a local teaching model.
   */
  function renderForm(res, action) {
    const forms = {
      transfer: {
        title: 'Transfer', endpoint: '/transfer',
        fields: [['to', 'to handle', ''], ['asset', 'asset', 'BTC'], ['amount', 'amount (coins)', '']],
        body: "{ to_handle: v('to'), asset: v('asset'), amount: coin('amount') }",
        okMsg: "'ok: transfer #' + b.id",
      },
      swap: {
        title: 'Swap', endpoint: '/swap',
        fields: [['from', 'from asset', 'BTC'], ['to', 'to asset', 'USD'], ['amount', 'from amount (coins)', '']],
        body: "{ from_asset: v('from'), to_asset: v('to'), from_amount: coin('amount') }",
        okMsg: "'ok: swap #' + b.id + ' -> ' + (b.to_amount/1e8)",
      },
      bridge: {
        title: 'Bridge withdraw', endpoint: '/bridge/withdraw',
        fields: [['asset', 'asset', 'BTC'], ['amount', 'amount (coins)', ''], ['chain', 'destination chain', 'ethereum']],
        body: "{ asset: v('asset'), amount: coin('amount'), dst_chain: v('chain') }",
        okMsg: "'ok: op #' + b.id + ' ' + b.status",
      },
    };
    const f = forms[action];
    if (!f) return html(res, 404, '<title>form</title><p>no such form</p>');
    const inputs = [['token', 'bearer token', '']].concat(f.fields)
      .map(([id, ph, dv]) => `<input id="${id}" class="f-${id}" placeholder="${esc(ph)}" value="${esc(dv)}">`).join('');
    const script =
      "function v(id){return document.getElementById(id).value.trim();}" +
      "function coin(id){return Math.round(parseFloat(v(id))*1e8);}" +
      "document.getElementById('go').addEventListener('click',async function(e){e.preventDefault();" +
      "var r=document.getElementById('result');r.textContent='sending...';r.removeAttribute('data-status');" +
      "try{var res=await fetch('" + f.endpoint + "',{method:'POST',headers:{'content-type':'application/json','authorization':'Bearer '+v('token')},body:JSON.stringify(" + f.body + ")});" +
      "var b=await res.json();r.setAttribute('data-status',res.status);r.setAttribute('data-code',(b&&b.code)||'ok');" +
      "r.textContent=(res.status===201||res.status===200)?(" + f.okMsg + "):('error: '+(b&&b.code));" +
      "}catch(err){r.setAttribute('data-status','0');r.setAttribute('data-code','network');r.textContent='error: '+err.message;}});";
    return html(res, 200, `<title>${f.title}</title><h1 class="form-title">${f.title}</h1><form id="form">${inputs}<button id="go" type="submit">${f.title}</button></form><div id="result" class="result"></div><script>${script}</script>`);
  }

  const server = http.createServer(async (req, res) => {
    const url = new URL(req.url, 'http://localhost');
    try { await route(req, res, url); }
    catch (err) {
      if (err instanceof H.ApiError) json(res, err.status, H.errorBody(err));
      else { console.error(err); json(res, 500, { error: 'internal error', code: 'internal' }); }
    }
  });
  server.listen(cfg.port, '127.0.0.1', () => console.error(`mini-cex on http://127.0.0.1:${cfg.port}  db ${cfg.dbFile}`));
  const shutdown = () => { server.close(); db.close(); process.exit(0); };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

if (require.main === module) main();
module.exports = { cfg };
