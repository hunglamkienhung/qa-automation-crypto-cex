'use strict';

/**
 * Read-only client for Kraken's public API -- the live exchange this domain
 * cross-checks the mini-cex against. No key, no account: only public market
 * data (Assets, AssetPairs, Ticker).
 *
 * Kraken wraps every response in { error: [...], result: {...} }. A transport
 * failure, a non-JSON body (a challenge or error page), or a non-empty `error`
 * array all mean the figure cannot be observed -- SiteUnreachable, which grades
 * Blocked, never Failed. The live exchange is not a system under test.
 */

const BASE = (process.env.KRAKEN_URL || 'https://api.kraken.com/0/public').replace(/\/+$/, '');
const TIMEOUT_MS = 15000;
const USER_AGENT = 'qa-automation-crypto-cex/1.0 (read-only invariants)';

class SiteUnreachable extends Error {}

async function call(pathAndQuery) {
  let res;
  try {
    res = await fetch(BASE + pathAndQuery, { headers: { 'user-agent': USER_AGENT, accept: 'application/json' }, signal: AbortSignal.timeout(TIMEOUT_MS) });
  } catch (err) {
    throw new SiteUnreachable('Kraken did not answer ' + pathAndQuery + ': ' + (err.cause && err.cause.message ? err.cause.message : err.message));
  }
  if (res.status === 403 || res.status === 429 || res.status >= 500) throw new SiteUnreachable('Kraken returned HTTP ' + res.status + ' for ' + pathAndQuery);
  const text = await res.text();
  let body = null; try { body = text ? JSON.parse(text) : null; } catch { body = null; }
  if (body === null || typeof body !== 'object') throw new SiteUnreachable('Kraken served a non-JSON body for ' + pathAndQuery + ' (a challenge or error page)');
  if (Array.isArray(body.error) && body.error.length) throw new SiteUnreachable('Kraken error for ' + pathAndQuery + ': ' + body.error.join(', '));
  if (!body.result || typeof body.result !== 'object') throw new SiteUnreachable('Kraken returned no result for ' + pathAndQuery);
  return body.result;
}

const Kraken = {
  SiteUnreachable,
  assets() { return call('/Assets'); },
  assetPairs() { return call('/AssetPairs'); },
  ticker(pair) { return call('/Ticker?pair=' + encodeURIComponent(pair)); },

  /** The set of wsname strings (e.g. "XBT/USD") the exchange lists. */
  async pairNames() {
    const r = await this.assetPairs();
    return Object.values(r).map((p) => p.wsname).filter(Boolean);
  },
  /** The last-trade price of a pair as a number, from ticker.c[0]. */
  async lastPrice(pair) {
    const r = await this.ticker(pair);
    const row = Object.values(r)[0];
    if (!row || !Array.isArray(row.c) || row.c.length === 0) throw new SiteUnreachable('Kraken ticker for ' + pair + ' had no last price');
    const n = Number(row.c[0]);
    if (!Number.isFinite(n) || n <= 0) throw new SiteUnreachable('Kraken ticker for ' + pair + ' had a non-numeric price');
    return n;
  },
};

module.exports = { Kraken, SiteUnreachable, BASE };
