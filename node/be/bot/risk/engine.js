'use strict';

/**
 * A pure risk gate for a client that sends transfers, swaps and bridge ops to
 * the exchange. `plan(op, ctx) -> decision` -- no network, no clock, no state.
 * It answers the same questions the service enforces, but BEFORE a request is
 * sent, so a bot never fires an operation it can already see will be refused.
 *
 * The service is still the authority; this only stops obviously-doomed calls
 * and is the layer that is cheap to unit-test exhaustively. Mirrors the pattern
 * of the perpetuals repo's RiskEngine.
 */

const SCALE = 100000000n; // 1e8 base units per whole coin

const REASONS = {
  KILL_SWITCH: 'the kill switch is on',
  ZERO_AMOUNT: 'amount must be positive',
  UNKNOWN_ASSET: 'asset is not listed',
  INSUFFICIENT_FUNDS: 'balance is below the amount',
  NO_PAIR: 'no active pair for those assets',
  BELOW_MIN: 'below the pair minimum',
  SLIPPAGE: 'quote is below the slippage floor',
  UNKNOWN_CHAIN: 'destination chain is not supported',
  OVER_CAP: 'amount exceeds the bridge per-transaction cap',
  MAX_ORDER_SIZE: 'order size exceeds the max',
  UNKNOWN_OP: 'unknown operation kind',
};

const no = (reason) => ({ ok: false, reason });
const ok = (extra = {}) => ({ ok: true, action: 'send', ...extra });

function usdMicro(asset, amount, ctx) {
  const a = ctx.assets[asset];
  return (BigInt(amount) * BigInt(a.usd_micro)) / SCALE;
}

/** The net output of a swap, in base units of `to`. Pure integer arithmetic. */
function quoteNet(from, to, amount, feeBps, ctx) {
  const usd = usdMicro(from, amount, ctx);
  const gross = (usd * SCALE) / BigInt(ctx.assets[to].usd_micro);
  const fee = (gross * BigInt(feeBps)) / 10000n;
  return Number(gross - fee);
}

function findPair(from, to, ctx) {
  return (ctx.pairs || []).find((p) => (p.base === from && p.quote === to) || (p.base === to && p.quote === from));
}

class RiskEngine {
  constructor(cfg = {}) {
    this.cfg = {
      chains: ['ethereum', 'arbitrum', 'solana', 'bitcoin'],
      bridgeCapUsdMicro: 100000n * 1000000n,
      maxOrderSize: 100 * 1e8,   // 100 whole coins, base units
      killSwitch: false,
      ...cfg,
    };
  }

  plan(op, ctx) {
    if (this.cfg.killSwitch) return no(REASONS.KILL_SWITCH);
    const bal = (asset) => (ctx.balances && ctx.balances[asset]) || 0;

    // An order the market-maker wants to rest: gate size and the reserve it needs.
    if (op.kind === 'order') {
      if (!Number.isInteger(op.size) || op.size <= 0) return no(REASONS.ZERO_AMOUNT);
      if (!ctx.assets[op.base] || !ctx.assets[op.quote]) return no(REASONS.UNKNOWN_ASSET);
      if (op.size > this.cfg.maxOrderSize) return no(REASONS.MAX_ORDER_SIZE);
      const needAsset = op.side === 'buy' ? op.quote : op.base;
      const need = op.side === 'buy' ? Number((BigInt(op.size) * BigInt(op.price)) / SCALE) : op.size;
      if (bal(needAsset) < need) return no(REASONS.INSUFFICIENT_FUNDS);
      return ok();
    }

    if (!Number.isInteger(op.amount) || op.amount <= 0) return no(REASONS.ZERO_AMOUNT);

    if (op.kind === 'transfer') {
      if (!ctx.assets[op.asset]) return no(REASONS.UNKNOWN_ASSET);
      if (bal(op.asset) < op.amount) return no(REASONS.INSUFFICIENT_FUNDS);
      return ok();
    }
    if (op.kind === 'bridge') {
      if (!ctx.assets[op.asset]) return no(REASONS.UNKNOWN_ASSET);
      if (!this.cfg.chains.includes(op.dstChain)) return no(REASONS.UNKNOWN_CHAIN);
      if (usdMicro(op.asset, op.amount, ctx) > this.cfg.bridgeCapUsdMicro) return no(REASONS.OVER_CAP);
      if (bal(op.asset) < op.amount) return no(REASONS.INSUFFICIENT_FUNDS);
      return ok();
    }
    if (op.kind === 'swap') {
      if (!ctx.assets[op.from] || !ctx.assets[op.to]) return no(REASONS.UNKNOWN_ASSET);
      const pair = findPair(op.from, op.to, ctx);
      if (!pair || pair.active === 0 || pair.active === false) return no(REASONS.NO_PAIR);
      if (op.from === pair.base && op.amount < pair.min_base) return no(REASONS.BELOW_MIN);
      const net = quoteNet(op.from, op.to, op.amount, pair.fee_bps, ctx);
      if (op.minTo !== undefined && net < op.minTo) return no(REASONS.SLIPPAGE);
      if (bal(op.from) < op.amount) return no(REASONS.INSUFFICIENT_FUNDS);
      return ok({ net });
    }
    return no(REASONS.UNKNOWN_OP);
  }
}

module.exports = { RiskEngine, REASONS, quoteNet };
