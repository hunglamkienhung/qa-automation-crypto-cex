"""Steps for be-bot.feature -- the pure risk gate. Mirror of
node/be/bot/steps/bot.steps.js. Deterministic; always graded, never Blocked.
"""

from __future__ import annotations

from pytest_bdd import given, parsers, then, when

from be.bot.risk.engine import RiskEngine


def coin(n):
    return round(float(n) * 1e8)


def book():
    return {
        "assets": {
            "BTC": {"usd_micro": 60000000000}, "ETH": {"usd_micro": 2500000000}, "SOL": {"usd_micro": 100000000},
            "USD": {"usd_micro": 1000000}, "USDC": {"usd_micro": 1000000}, "DOGE": {"usd_micro": 120000},
        },
        "pairs": [
            {"base": "BTC", "quote": "USD", "fee_bps": 20, "min_base": 10000, "active": 1},
            {"base": "ETH", "quote": "USD", "fee_bps": 20, "min_base": 100000, "active": 1},
            {"base": "SOL", "quote": "USD", "fee_bps": 20, "min_base": 1000000, "active": 1},
            {"base": "USDC", "quote": "USD", "fee_bps": 0, "min_base": 0, "active": 1},
            {"base": "DOGE", "quote": "USD", "fee_bps": 20, "min_base": 0, "active": 0},
        ],
        "balances": {"BTC": coin(1.0), "USD": coin(1000), "ETH": coin(10), "USDC": coin(500)},
    }


@given("a risk engine with the default configuration and a funded book")
def engine(qa):
    qa.engine = RiskEngine()
    qa.ctx = book()
    qa.decision = None


@given("the kill switch is on")
def kill_switch(qa):
    qa.engine = RiskEngine(kill_switch=True)


@when(parsers.parse("the engine plans a transfer of {amt:g} {asset}"))
def plan_transfer(qa, amt, asset):
    qa.decision = qa.engine.plan({"kind": "transfer", "asset": asset, "amount": coin(amt)}, qa.ctx)


@when(parsers.parse("the engine plans a swap of {amt:g} {frm} to {to}"))
def plan_swap(qa, amt, frm, to):
    qa.decision = qa.engine.plan({"kind": "swap", "from": frm, "to": to, "amount": coin(amt)}, qa.ctx)


@when(parsers.parse("the engine plans a swap of {amt:g} {frm} to {to} demanding at least {minv:g} {q}"))
def plan_swap_min(qa, amt, frm, to, minv, q):
    qa.decision = qa.engine.plan({"kind": "swap", "from": frm, "to": to, "amount": coin(amt), "min_to": coin(minv)}, qa.ctx)


@when(parsers.parse('the engine plans a bridge of {amt:g} {asset} to chain "{chain}"'))
def plan_bridge(qa, amt, asset, chain):
    qa.decision = qa.engine.plan({"kind": "bridge", "asset": asset, "amount": coin(amt), "dst_chain": chain}, qa.ctx)


@then("the plan is allowed")
def plan_allowed(qa):
    qa.check("plan allowed", qa.decision and qa.decision["ok"] is True, str(qa.decision))


@then(parsers.parse('the plan is refused for "{reason}"'))
def plan_refused(qa, reason):
    qa.check("plan refused: " + reason, qa.decision and qa.decision["ok"] is False and qa.decision.get("reason") == reason, str(qa.decision))
