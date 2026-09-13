"""A pure risk gate. Mirror of node/be/bot/risk/engine.js.

`plan(op, ctx) -> decision` -- no network, no clock, no state. It answers the
same questions the service enforces, but BEFORE a request is sent. The service
is still the authority; this only stops obviously-doomed calls and is the layer
that is cheap to unit-test exhaustively.
"""

from __future__ import annotations

SCALE = 100_000_000  # 1e8 base units per whole coin

REASONS = {
    "KILL_SWITCH": "the kill switch is on",
    "ZERO_AMOUNT": "amount must be positive",
    "UNKNOWN_ASSET": "asset is not listed",
    "INSUFFICIENT_FUNDS": "balance is below the amount",
    "NO_PAIR": "no active pair for those assets",
    "BELOW_MIN": "below the pair minimum",
    "SLIPPAGE": "quote is below the slippage floor",
    "UNKNOWN_CHAIN": "destination chain is not supported",
    "OVER_CAP": "amount exceeds the bridge per-transaction cap",
    "UNKNOWN_OP": "unknown operation kind",
}


def _no(reason):
    return {"ok": False, "reason": reason}


def _ok(**extra):
    return {"ok": True, "action": "send", **extra}


def _usd_micro(asset, amount, ctx):
    return (amount * ctx["assets"][asset]["usd_micro"]) // SCALE


def quote_net(from_asset, to_asset, amount, fee_bps, ctx):
    usd = _usd_micro(from_asset, amount, ctx)
    gross = (usd * SCALE) // ctx["assets"][to_asset]["usd_micro"]
    fee = (gross * fee_bps) // 10000
    return gross - fee


def _find_pair(from_asset, to_asset, ctx):
    for p in ctx.get("pairs", []):
        if (p["base"] == from_asset and p["quote"] == to_asset) or (p["base"] == to_asset and p["quote"] == from_asset):
            return p
    return None


class RiskEngine:
    def __init__(self, **cfg):
        self.cfg = {
            "chains": ["ethereum", "arbitrum", "solana", "bitcoin"],
            "bridge_cap_usd_micro": 100_000 * 1_000_000,
            "kill_switch": False,
            **cfg,
        }

    def plan(self, op, ctx):
        if self.cfg["kill_switch"]:
            return _no(REASONS["KILL_SWITCH"])
        amount = op.get("amount")
        if not isinstance(amount, int) or amount <= 0:
            return _no(REASONS["ZERO_AMOUNT"])

        def bal(asset):
            return (ctx.get("balances") or {}).get(asset, 0)

        kind = op.get("kind")
        if kind == "transfer":
            if op["asset"] not in ctx["assets"]:
                return _no(REASONS["UNKNOWN_ASSET"])
            if bal(op["asset"]) < amount:
                return _no(REASONS["INSUFFICIENT_FUNDS"])
            return _ok()
        if kind == "bridge":
            if op["asset"] not in ctx["assets"]:
                return _no(REASONS["UNKNOWN_ASSET"])
            if op.get("dst_chain") not in self.cfg["chains"]:
                return _no(REASONS["UNKNOWN_CHAIN"])
            if _usd_micro(op["asset"], amount, ctx) > self.cfg["bridge_cap_usd_micro"]:
                return _no(REASONS["OVER_CAP"])
            if bal(op["asset"]) < amount:
                return _no(REASONS["INSUFFICIENT_FUNDS"])
            return _ok()
        if kind == "swap":
            if op["from"] not in ctx["assets"] or op["to"] not in ctx["assets"]:
                return _no(REASONS["UNKNOWN_ASSET"])
            pair = _find_pair(op["from"], op["to"], ctx)
            if not pair or not pair.get("active"):
                return _no(REASONS["NO_PAIR"])
            if op["from"] == pair["base"] and amount < pair["min_base"]:
                return _no(REASONS["BELOW_MIN"])
            net = quote_net(op["from"], op["to"], amount, pair["fee_bps"], ctx)
            if op.get("min_to") is not None and net < op["min_to"]:
                return _no(REASONS["SLIPPAGE"])
            if bal(op["from"]) < amount:
                return _no(REASONS["INSUFFICIENT_FUNDS"])
            return _ok(net=net)
        return _no(REASONS["UNKNOWN_OP"])
