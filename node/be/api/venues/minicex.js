'use strict';

/**
 * HTTP client for the mini-cex service. Node's built-in fetch; no library.
 *
 * A response is returned whole -- status, lower-cased headers, parsed body --
 * so a step can assert on any of them. Only a transport failure is
 * ApiUnreachable (grades Blocked); a 4xx/5xx is an answer, often the one under
 * test.
 */

const BASE = (process.env.MINI_CEX_URL || 'http://127.0.0.1:8110').replace(/\/+$/, '');

class ApiUnreachable extends Error {}

class MiniCex {
  constructor(base = BASE) { this.base = base; }

  async request(method, path, { token, body, headers = {} } = {}) {
    const h = { ...headers };
    if (token) h.authorization = 'Bearer ' + token;
    const init = { method, headers: h };
    if (body !== undefined) { h['content-type'] = 'application/json'; init.body = JSON.stringify(body); }
    let res;
    try { res = await fetch(this.base + path, init); } catch (err) {
      throw new ApiUnreachable('mini-cex at ' + this.base + ' did not answer ' + method + ' ' + path + ': ' + (err.cause && err.cause.message ? err.cause.message : err.message));
    }
    const text = await res.text();
    let parsed = null; try { parsed = text ? JSON.parse(text) : null; } catch { parsed = null; }
    return { status: res.status, headers: Object.fromEntries([...res.headers.entries()].map(([k, v]) => [k.toLowerCase(), v])), body: parsed, text };
  }
  get(p, o) { return this.request('GET', p, o); }
  post(p, body, o = {}) { return this.request('POST', p, { ...o, body }); }

  /** Create a fresh account with a unique handle; returns { id, handle, token }. */
  async createAccount(prefix = 'acct') {
    const handle = prefix + '-' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
    const r = await this.post('/accounts', { handle });
    if (r.status !== 201) throw new Error('create account failed: HTTP ' + r.status + ' ' + r.text);
    return r.body;
  }
  deposit(token, asset, amount, key) { return this.post('/deposit', { asset, amount, idempotency_key: key }, { token }); }
  withdraw(token, asset, amount, key) { return this.post('/withdraw', { asset, amount, idempotency_key: key }, { token }); }
  transfer(token, toHandle, asset, amount, key) { return this.post('/transfer', { to_handle: toHandle, asset, amount, idempotency_key: key }, { token }); }
  quote(fromAsset, toAsset, fromAmount) { return this.post('/quote', { from_asset: fromAsset, to_asset: toAsset, from_amount: fromAmount }); }
  swap(token, body) { return this.post('/swap', body, { token }); }
  bridgeWithdraw(token, body) { return this.post('/bridge/withdraw', body, { token }); }
  bridgeDeposit(body) { return this.post('/bridge/deposit', body); }
  bridgeConfirm(id) { return this.post('/bridge/' + id + '/confirm', undefined); }

  /** A funded account with `amount` base units of `asset` deposited. */
  async funded(asset, amount, prefix = 'acct') {
    const acct = await this.createAccount(prefix);
    const r = await this.deposit(acct.token, asset, amount);
    if (r.status !== 201) throw new Error('funding failed: HTTP ' + r.status + ' ' + r.text);
    return acct;
  }
}

module.exports = { MiniCex, ApiUnreachable, BASE };
