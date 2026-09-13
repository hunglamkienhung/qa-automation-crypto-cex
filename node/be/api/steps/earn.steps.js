'use strict';

const { Given, When, Then } = require('@cucumber/cucumber');
const { MiniCex, ApiUnreachable } = require('../venues/minicex');

/**
 * Steps for features/be-cex-earn.feature. Staking locks a principal that
 * accrues a fixed APR over explicit simulated seconds and is redeemed for
 * principal + reward. The account/deposit and ledger steps are shared; here are
 * the stake actions and stake-specific assertions.
 */

const cex = new MiniCex();
const coin = (n) => Math.round(Number(n) * 1e8);
const acctOf = (world, alias) => world.accounts[alias];

async function act(world, fn) {
  if (world.sourceError) return;
  try { await fn(); } catch (err) { if (err instanceof ApiUnreachable) { world.sourceError = err.message; return; } throw err; }
}
function expectThrow(fn, needle) {
  try { fn(); return { passed: false, detail: 'no error thrown' }; }
  catch (err) { const ok = new RegExp(needle, 'i').test(err.message); return { passed: ok, detail: ok ? 'rejected' : 'wrong error: ' + err.message }; }
}

Then('inserting a stake with a non-positive principal fails a CHECK', function () {
  this.tmp.exec("INSERT INTO accounts (id, handle, created_at) VALUES (1, 'x', 0)");
  const r = expectThrow(() => this.tmp.exec("INSERT INTO stakes (account_id, asset, principal, apr_bps, status, created_at) VALUES (1,'BTC',0,500,'active',0)"), 'CHECK|constraint');
  this.check('principal>0 enforced', r.passed, r.detail);
});

async function doStake(world, alias, amt, asset, apr) {
  const a = acctOf(world, alias);
  world.stakeToken = a.token;
  world.api = await cex.stake(a.token, { asset, amount: coin(amt), apr_bps: apr });
  if (world.api.status === 201 || world.api.status === 200) world.currentStake = world.api.body;
}
// One definition per phrase (Cucumber shares Given/When/Then); serves both the
// "And ..." setup lines and the "When ..." action lines.
When('{string} stakes {float} {word} at {int} bps', async function (alias, amt, asset, apr) { await act(this, () => doStake(this, alias, amt, asset, apr)); });
When('the stake accrues {int} seconds', async function (seconds) { await act(this, async () => { this.api = await cex.stakeAccrue(this.stakeToken, this.currentStake.id, seconds); this.currentStake = this.api.body; }); });
When('the stake is redeemed', async function () { await act(this, async () => { this.api = await cex.stakeRedeem(this.stakeToken, this.currentStake.id); this.currentStake = this.api.body; }); });
When('the stake is redeemed again', async function () { await act(this, async () => { this.api = await cex.stakeRedeem(this.stakeToken, this.currentStake.id); }); });

When('{string} tries to withdraw {float} {word}', async function (alias, amt, asset) {
  await act(this, async () => { this.api = await cex.withdraw(acctOf(this, alias).token, asset, coin(amt)); });
});

Then('the stake accrued is {float} {word}', function (amt, _a) {
  if (this.sourceError) { this.unobservable('stake accrued', this.sourceError); return; }
  this.check('stake accrued ' + amt, this.currentStake && this.currentStake.accrued === coin(amt), this.currentStake ? 'got ' + this.currentStake.accrued + ' want ' + coin(amt) : 'no stake');
});
Then('the second redemption was an idempotent replay', function () {
  if (this.sourceError) { this.unobservable('redeem replay', this.sourceError); return; }
  this.check('redeem idempotent replay', this.api && this.api.body && this.api.body.idempotent_replay === true, this.api ? JSON.stringify(this.api.body).slice(0, 80) : 'no response');
});
