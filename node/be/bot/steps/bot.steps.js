'use strict';

const { Given, When, Then } = require('@cucumber/cucumber');
const { RiskEngine } = require('../risk/engine');

/**
 * Steps for features/be-bot.feature. The engine is a pure function, so these
 * are deterministic and always graded -- there is no source to be unreachable.
 */

const coin = (n) => Math.round(Number(n) * 1e8);

function book() {
  return {
    assets: {
      BTC: { usd_micro: 60000000000 }, ETH: { usd_micro: 2500000000 }, SOL: { usd_micro: 100000000 },
      USD: { usd_micro: 1000000 }, USDC: { usd_micro: 1000000 }, DOGE: { usd_micro: 120000 },
    },
    pairs: [
      { base: 'BTC', quote: 'USD', fee_bps: 20, min_base: 10000, active: 1 },
      { base: 'ETH', quote: 'USD', fee_bps: 20, min_base: 100000, active: 1 },
      { base: 'SOL', quote: 'USD', fee_bps: 20, min_base: 1000000, active: 1 },
      { base: 'USDC', quote: 'USD', fee_bps: 0, min_base: 0, active: 1 },
      { base: 'DOGE', quote: 'USD', fee_bps: 20, min_base: 0, active: 0 },
    ],
    balances: { BTC: coin(1.0), USD: coin(1000), ETH: coin(10), USDC: coin(500) },
  };
}

Given('a risk engine with the default configuration and a funded book', function () {
  this.engine = new RiskEngine();
  this.ctx = book();
  this.decision = null;
});
Given('the kill switch is on', function () {
  this.engine = new RiskEngine({ killSwitch: true });
});

When('the engine plans a transfer of {float} {word}', function (amt, asset) {
  this.decision = this.engine.plan({ kind: 'transfer', asset, amount: coin(amt) }, this.ctx);
});
When('the engine plans a swap of {float} {word} to {word}', function (amt, from, to) {
  this.decision = this.engine.plan({ kind: 'swap', from, to, amount: coin(amt) }, this.ctx);
});
When('the engine plans a swap of {float} {word} to {word} demanding at least {float} {word}', function (amt, from, to, minv, _q) {
  this.decision = this.engine.plan({ kind: 'swap', from, to, amount: coin(amt), minTo: coin(minv) }, this.ctx);
});
When('the engine plans a bridge of {float} {word} to chain {string}', function (amt, asset, chain) {
  this.decision = this.engine.plan({ kind: 'bridge', asset, amount: coin(amt), dstChain: chain }, this.ctx);
});

Then('the plan is allowed', function () {
  this.check('plan allowed', this.decision && this.decision.ok === true, this.decision ? JSON.stringify(this.decision) : 'no decision');
});
Then('the plan is refused for {string}', function (reason) {
  this.check('plan refused: ' + reason, this.decision && this.decision.ok === false && this.decision.reason === reason, this.decision ? JSON.stringify(this.decision) : 'no decision');
});
