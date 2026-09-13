"""A market-maker over the mini-cex spot order book. Mirror of node/be/bot/client/bot.js.

Quotes a post-only bid below and ask above a reference price, cancels/replaces on
reprice, passes each order past the pure RiskEngine, retries only transport
failures, and never leaks its token. Prices are in the order book's integer form
(quote-per-base x 1e8).
"""

from __future__ import annotations

from be.api.venues.minicex import ApiUnreachable
from be.bot.risk.engine import RiskEngine

SCALE = 100_000_000


class MarketMaker:
    def __init__(self, cex, token=None, handle=None, base=None, quote=None, ref_price=None,
                 spread_bps=50, size=None, dry_run=False, kill_switch=False, risk=None):
        self.cex = cex
        self.token = token
        self.handle = handle
        self.base = base
        self.quote_asset = quote
        self.ref_price = ref_price
        self.spread_bps = spread_bps
        self.size = size
        self.dry_run = dry_run
        self.kill_switch = kill_switch
        self.risk = risk or RiskEngine(kill_switch=kill_switch)

    def bid_price(self):
        return (self.ref_price * (10000 - self.spread_bps)) // 10000

    def ask_price(self):
        return (self.ref_price * (10000 + self.spread_bps)) // 10000

    def risk_ctx(self):
        assets = {a["symbol"]: {"usd_micro": a["usd_micro"]} for a in self.cex.get("/assets")["body"]["assets"]}
        balances = {b["asset"]: b["amount"] for b in self.cex.get("/balances/" + self.handle)["body"]["balances"]}
        pairs = self.cex.get("/pairs")["body"]["pairs"]
        return {"assets": assets, "balances": balances, "pairs": pairs}

    def cancel_all(self):
        r = self.cex.orders_of(self.handle)
        for o in (r["body"]["orders"] or []):
            if o["base"] == self.base and o["quote"] == self.quote_asset and o["status"] in ("open", "partial"):
                self.cex.request("DELETE", "/orders/" + str(o["id"]), token=self.token)

    def active_quotes(self):
        r = self.cex.orders_of(self.handle, "open")
        return [o for o in (r["body"]["orders"] or []) if o["base"] == self.base and o["quote"] == self.quote_asset]

    def quote(self):
        if self.kill_switch:
            return {"ok": False, "reason": "kill switch"}
        bid, ask = self.bid_price(), self.ask_price()
        ctx = self.risk_ctx()
        p_buy = self.risk.plan({"kind": "order", "side": "buy", "base": self.base, "quote": self.quote_asset, "size": self.size, "price": bid}, ctx)
        if not p_buy["ok"]:
            return {"ok": False, "reason": p_buy["reason"], "leg": "bid"}
        p_sell = self.risk.plan({"kind": "order", "side": "sell", "base": self.base, "quote": self.quote_asset, "size": self.size, "price": ask}, ctx)
        if not p_sell["ok"]:
            return {"ok": False, "reason": p_sell["reason"], "leg": "ask"}
        if self.dry_run:
            return {"ok": True, "dryRun": True, "bid": bid, "ask": ask}
        self.cancel_all()
        bid_res = self.cex.place_order(self.token, {"base": self.base, "quote": self.quote_asset, "side": "buy", "type": "limit", "price": bid, "size": self.size, "post_only": True})
        ask_res = self.cex.place_order(self.token, {"base": self.base, "quote": self.quote_asset, "side": "sell", "type": "limit", "price": ask, "size": self.size, "post_only": True})
        return {"ok": True, "bid": bid_res["body"], "ask": ask_res["body"], "bidPrice": bid, "askPrice": ask}

    def reprice(self, new_ref):
        self.ref_price = new_ref
        return self.quote()

    def with_retry(self, fn, tries=3):
        last = None
        for _ in range(tries):
            try:
                return fn()
            except ApiUnreachable as err:
                last = err
        raise last

    def leaked_secret(self, s):
        return self.token in str(s)
