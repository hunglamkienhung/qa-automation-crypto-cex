'use strict';

const fs = require('fs');
const path = require('path');
const { Given, When, Then, Before, After } = require('@cucumber/cucumber');
const { Store, DbUnreachable, throwaway } = require('../store');
const { MiniCex, ApiUnreachable } = require('../../api/venues/minicex');

/**
 * Steps for features/be-cex-db.feature, plus the shared "drive the service"
 * account and action steps that be-cex-api.feature and fe-cex.feature reuse.
 *
 * Isolation is by fresh accounts and deltas, not by reset: each scenario makes
 * its own accounts, drives the API, and asserts what changed -- so scenarios
 * never collide however they are ordered.
 */

const cex = new MiniCex();
const SEED = path.join(__dirname, '..', '..', '..', '..', 'services', 'mini-cex', 'db', 'seed.sql');
const UNREACHABLE = [DbUnreachable, ApiUnreachable];
const coin = (n) => Math.round(Number(n) * 1e8);

Before(function () {
  this.store = null;
  this.cex = cex;
  this.accounts = {};      // alias -> { id, handle, token }
  this.api = null;         // last HTTP response
  this.tmp = null;         // throwaway db
  this.lastBridge = null;  // last bridge op body
  this.quote = null;
});
After(function () {
  if (this.tmp) { try { this.tmp.close(); } catch { /* fine */ } }
  if (this.store) this.store.close();
});

// ---------------------------------------------------------------- helpers

async function act(world, fn) {
  if (world.sourceError) return undefined;
  try { return await fn(); } catch (err) {
    if (UNREACHABLE.some((C) => err instanceof C)) { world.sourceError = err.message; return undefined; }
    throw err;
  }
}
async function check(world, description, fn) {
  if (world.sourceError) { world.unobservable(description, 'the source could not be reached -- ' + world.sourceError); return; }
  let r;
  try { r = await fn(); } catch (err) { if (UNREACHABLE.some((C) => err instanceof C)) { world.unobservable(description, err.message); return; } throw err; }
  world.check(description, r.passed, r.detail);
}
function expectThrow(fn, needle) {
  try { fn(); return { passed: false, detail: 'no error thrown' }; }
  catch (err) { const ok = !needle || new RegExp(needle, 'i').test(err.message); return { passed: ok, detail: ok ? 'rejected: ' + err.message.split('\n')[0] : 'wrong error: ' + err.message }; }
}
async function ensureAccount(world, alias) {
  if (world.accounts[alias]) return world.accounts[alias];
  const a = await cex.createAccount(alias);
  world.accounts[alias] = a;
  return a;
}
const acctOf = (world, alias) => world.accounts[alias];

// ---------------------------------------------------------------- Background

Given('the store is open and the service is reachable', { timeout: 30_000 }, async function () {
  if (this.sourceError) return;
  try { this.store = new Store(); } catch (err) { if (err instanceof DbUnreachable) { this.sourceError = err.message; return; } throw err; }
  const r = await act(this, () => cex.get('/assets'));
  if (this.sourceError) return;
  if (!r || r.status !== 200) { this.sourceError = 'mini-cex /assets returned ' + (r ? r.status : 'nothing'); }
});

// ---------------------------------------------------------------- throwaway schema

Given('a throwaway database with the schema applied', function () {
  this.tmp = throwaway();
  // Seed the parent assets the constraint tests reference, so the constraint
  // under test (a CHECK, a UNIQUE) is what fires -- not an incidental missing
  // asset FOREIGN KEY.
  this.tmp.exec("INSERT INTO assets (symbol, name, kind, decimals, usd_micro) VALUES ('BTC','Bitcoin','crypto',8,1), ('USD','US Dollar','fiat',2,1)");
});
Given('a throwaway database with the schema and seed applied', function () {
  this.tmp = throwaway();
  this.tmp.exec(fs.readFileSync(SEED, 'utf8'));
});

Then(/^the store has tables (.+)$/, async function (csv) {
  await check(this, 'documented tables present', async () => {
    const have = new Set(this.store.tables());
    const want = csv.split(',').map((s) => s.trim());
    const missing = want.filter((t) => !have.has(t));
    return { passed: missing.length === 0, detail: missing.length ? 'missing ' + missing.join(',') : 'all present' };
  });
});
Then('inserting a balance with a negative amount fails a CHECK', function () {
  this.tmp.exec("INSERT INTO accounts (id, handle, created_at) VALUES (1, 'x', 0)");
  const r = expectThrow(() => this.tmp.exec("INSERT INTO balances (account_id, asset, amount) VALUES (1, 'BTC', -1)"), 'CHECK|constraint');
  this.check('negative balance rejected', r.passed, r.detail);
});
Then('inserting a ledger row with zero delta fails a CHECK', function () {
  this.tmp.exec("INSERT INTO accounts (id, handle, created_at) VALUES (1, 'x', 0)");
  const r = expectThrow(() => this.tmp.exec("INSERT INTO ledger (account_id, asset, delta, reason, created_at) VALUES (1, 'BTC', 0, 'deposit', 0)"), 'CHECK|constraint');
  this.check('zero delta rejected', r.passed, r.detail);
});
Then('inserting a ledger row with reason {string} fails a CHECK', function (reason) {
  const r = expectThrow(() => this.tmp.exec(`INSERT INTO ledger (account_id, asset, delta, reason, created_at) VALUES (1, 'BTC', 1, '${reason}', 0)`), 'CHECK|constraint');
  this.check('bad reason rejected', r.passed, r.detail);
});
Then('inserting a balance for a missing account fails a FOREIGN KEY', function () {
  const r = expectThrow(() => this.tmp.exec("INSERT INTO balances (account_id, asset, amount) VALUES (999, 'BTC', 1)"), 'FOREIGN KEY|constraint');
  this.check('missing account FK rejected', r.passed, r.detail);
});
Then('inserting two deposit bridge ops with the same external tx fails on the second', function () {
  this.tmp.exec("INSERT INTO accounts (id, handle, created_at) VALUES (1, 'x', 0)");
  const ins = "INSERT INTO bridge_ops (account_id, asset, amount, direction, src_chain, dst_chain, status, ext_tx, created_at, updated_at) VALUES (1, 'BTC', 1, 'deposit', 'ethereum', 'mini-cex', 'credited', 'tx1', 0, 0)";
  this.tmp.exec(ins);
  const r = expectThrow(() => this.tmp.exec(ins), 'UNIQUE|constraint');
  this.check('duplicate bridge ext_tx rejected', r.passed, r.detail);
});
Then('inserting a pair whose base equals its quote fails a CHECK', function () {
  const r = expectThrow(() => this.tmp.exec("INSERT INTO pairs (base, quote) VALUES ('BTC', 'BTC')"), 'CHECK|constraint');
  this.check('same-leg pair rejected', r.passed, r.detail);
});
Then('applying the seed again changes no row counts', function () {
  const cnt = () => ({ assets: this.tmp.prepare('SELECT COUNT(*) AS n FROM assets').get().n, pairs: this.tmp.prepare('SELECT COUNT(*) AS n FROM pairs').get().n });
  const before = cnt();
  this.tmp.exec(fs.readFileSync(SEED, 'utf8'));
  const after = cnt();
  this.check('seed is idempotent', before.assets === after.assets && before.pairs === after.pairs, `assets ${before.assets}->${after.assets}, pairs ${before.pairs}->${after.pairs}`);
});

// ---------------------------------------------------------------- shared account + action steps

Given('a fresh account {string}', async function (alias) {
  await act(this, () => ensureAccount(this, alias));
});
Given('a fresh account {string} funded with {float} {word}', async function (alias, amt, asset) {
  await act(this, async () => { const a = await ensureAccount(this, alias); this.api = await cex.deposit(a.token, asset, coin(amt)); });
});

async function deposit(world, alias, amt, asset, key) {
  const a = await ensureAccount(world, alias);
  world.api = await cex.deposit(a.token, asset, coin(amt), key);
}
// One definition per phrase: Cucumber shares its registry across Given/When/Then,
// so this single step serves both the "And ... deposits" (Given) setup lines and
// the "When ... deposits" action lines in the features.
When('{string} deposits {float} {word}', async function (alias, amt, asset) { await act(this, () => deposit(this, alias, amt, asset)); });
When('{string} deposits {float} {word} with key {string}', async function (alias, amt, asset, key) { await act(this, () => deposit(this, alias, amt, asset, key)); });

When('{string} withdraws {float} {word}', async function (alias, amt, asset) {
  await act(this, async () => { this.api = await cex.withdraw(acctOf(this, alias).token, asset, coin(amt)); });
});
When('{string} transfers {float} {word} to {string}', async function (alias, amt, asset, to) {
  await act(this, async () => { const toAcct = await ensureAccount(this, to); this.api = await cex.transfer(acctOf(this, alias).token, toAcct.handle, asset, coin(amt)); });
});
When('{string} tries to transfer {float} {word} to {string}', async function (alias, amt, asset, to) {
  await act(this, async () => { const toAcct = await ensureAccount(this, to); this.api = await cex.transfer(acctOf(this, alias).token, toAcct.handle, asset, coin(amt)); });
});
When('{string} swaps {float} {word} to {word}', async function (alias, amt, from, to) {
  await act(this, async () => { this.api = await cex.swap(acctOf(this, alias).token, { from_asset: from, to_asset: to, from_amount: coin(amt), idempotency_key: null }); });
});
When('{string} swaps {float} {word} to {word} demanding at least {float} {word} out', async function (alias, amt, from, to, minv, _q) {
  await act(this, async () => { this.api = await cex.swap(acctOf(this, alias).token, { from_asset: from, to_asset: to, from_amount: coin(amt), min_to_amount: coin(minv) }); });
});
When('{string} bridge-withdraws {float} {word} to chain {string}', async function (alias, amt, asset, chain) {
  await act(this, async () => { this.api = await cex.bridgeWithdraw(acctOf(this, alias).token, { asset, amount: coin(amt), dst_chain: chain }); if (this.api.status === 201) this.lastBridge = this.api.body; });
});
When('a bridge deposit of {float} {word} for {string} from chain {string} with tx {string} is observed', async function (amt, asset, alias, chain, tx) {
  await act(this, async () => { const a = await ensureAccount(this, alias); this.bridgeDepositReq = { handle: a.handle, asset, amount: coin(amt), src_chain: chain, ext_tx: tx }; this.api = await cex.bridgeDeposit(this.bridgeDepositReq); if (this.api.body && this.api.body.id) this.lastBridge = this.api.body; });
});
When('the same bridge deposit is observed again', async function () {
  await act(this, async () => { this.api = await cex.bridgeDeposit(this.bridgeDepositReq); });
});
When('the bridge op is confirmed', async function () {
  await act(this, async () => { this.api = await cex.bridgeConfirm(this.lastBridge.id); this.lastBridge = this.api.body; });
});

// ---------------------------------------------------------------- DB Thens

function bal(world, alias, asset) { const id = world.store.accountId(acctOf(world, alias).handle); return world.store.balance(id, asset); }
function ledgerSum(world, alias, asset) { const id = world.store.accountId(acctOf(world, alias).handle); return world.store.ledgerBalance(id, asset); }

Then('the balance row for {string} in {word} is {float} {word}', async function (alias, asset, amt, _a) {
  await check(this, `balance ${alias}/${asset}`, async () => { const got = bal(this, alias, asset); return { passed: got === coin(amt), detail: `got ${got}, want ${coin(amt)}` }; });
});
Then('a ledger line credits {string} {float} {word} with reason {string}', async function (alias, amt, asset, reason) {
  await check(this, `ledger credit ${reason}`, async () => { const id = this.store.accountId(acctOf(this, alias).handle); const row = this.store.get('SELECT * FROM ledger WHERE account_id = ? AND asset = ? AND delta = ? AND reason = ?', id, asset, coin(amt), reason); return { passed: !!row, detail: row ? 'found' : 'no matching ledger line' }; });
});
Then('a ledger line debits {string} {float} {word} with reason {string}', async function (alias, amt, asset, reason) {
  await check(this, `ledger debit ${reason}`, async () => { const id = this.store.accountId(acctOf(this, alias).handle); const row = this.store.get('SELECT * FROM ledger WHERE account_id = ? AND asset = ? AND delta = ? AND reason = ?', id, asset, -coin(amt), reason); return { passed: !!row, detail: row ? 'found' : 'no matching ledger line' }; });
});
Then('the ledger sum for {string} in {word} equals the balance row', async function (alias, asset) {
  await check(this, `ledger == balance ${asset}`, async () => { const s = ledgerSum(this, alias, asset); const b = bal(this, alias, asset); return { passed: s === b, detail: `ledger ${s}, balance ${b}` }; });
});
Then('the total BTC across {string} and {string} is unchanged', async function (a1, a2) {
  await check(this, 'total conserved', async () => { const t = bal(this, a1, 'BTC') + bal(this, a2, 'BTC'); return { passed: t === coin(1.0), detail: `total ${t}` }; });
});
Then('{string} has a swap row from {word} to {word}', async function (alias, from, to) {
  await check(this, 'swap row present', async () => { const id = this.store.accountId(acctOf(this, alias).handle); const row = this.store.get('SELECT * FROM swaps WHERE account_id = ? AND from_asset = ? AND to_asset = ?', id, from, to); return { passed: !!row, detail: row ? `swap #${row.id}` : 'no swap row' }; });
});
Then('the bridge op for {string} is in status {string}', async function (alias, status) {
  await check(this, 'bridge op status', async () => { const id = this.store.accountId(acctOf(this, alias).handle); const row = this.store.get('SELECT * FROM bridge_ops WHERE account_id = ? ORDER BY id DESC LIMIT 1', id); return { passed: !!row && row.status === status, detail: row ? `status ${row.status}` : 'no bridge op' }; });
});
Then('{string} has exactly one bridge op with external tx {string}', async function (alias, tx) {
  await check(this, 'one bridge op by ext_tx', async () => { const n = this.store.count('bridge_ops', 'WHERE ext_tx = ?', tx); return { passed: n === 1, detail: `count ${n}` }; });
});
Then('the transfer is refused with code {string}', async function (code) {
  await check(this, 'transfer refused', async () => ({ passed: this.api && this.api.status >= 400 && this.api.body && this.api.body.code === code, detail: this.api ? `status ${this.api.status} code ${this.api.body && this.api.body.code}` : 'no response' }));
});
Then('{string} has no {word} balance row', async function (alias, asset) {
  await check(this, 'no balance row', async () => { const id = this.store.accountId(acctOf(this, alias).handle); const row = id ? this.store.get('SELECT * FROM balances WHERE account_id = ? AND asset = ?', id, asset) : null; return { passed: !row, detail: row ? `amount ${row.amount}` : 'absent' }; });
});
