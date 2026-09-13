"""Steps for be-cex-orders.feature. Mirror of node/be/api/steps/orders.steps.js.
Order actions and assertions on rows (qa.store) and responses. The account and
deposit steps are shared from cex_steps.py.
"""

from __future__ import annotations

import re

from pytest_bdd import given, parsers, then, when

from be.api.venues.minicex import ApiUnreachable, MiniCex

cex = MiniCex()


def coin(n):
    return round(float(n) * 1e8)


def acct(qa, alias):
    return qa.accounts[alias]


def act(qa, fn):
    if qa.source_error:
        return
    try:
        fn()
    except ApiUnreachable as err:
        qa.source_error = str(err)


def assert_(qa, description, cond, detail):
    if qa.source_error:
        qa.unobservable(description, "the source could not be reached -- " + qa.source_error)
        return
    qa.check(description, bool(cond), detail)


def expect_throw(fn, needle):
    try:
        fn()
        return (False, "no error thrown")
    except Exception as err:  # noqa: BLE001
        ok = re.search(needle, str(err), re.I) is not None
        return (ok, "rejected" if ok else "wrong error: " + str(err))


def place(qa, alias, side, size, base, price, quote, type="limit", tif="GTC", post_only=False, key=None):
    a = acct(qa, alias)
    body = {"base": base, "quote": quote, "side": side, "type": type, "size": coin(size), "tif": tif}
    if type == "limit":
        body["price"] = coin(price)
    if post_only:
        body["post_only"] = True
    if key:
        body["idempotency_key"] = key
    qa.api = cex.place_order(a["token"], body)
    if qa.api["status"] in (200, 201):
        qa.last_order = qa.api["body"]
        qa.last_order_by = getattr(qa, "last_order_by", {})
        qa.last_order_by[alias] = qa.api["body"]


# ---------------------------------------------------------------- schema

@then("inserting a balance whose reserved exceeds its amount fails a CHECK")
def reserved_check(qa):
    qa.tmp.execute("INSERT INTO accounts (id, handle, created_at) VALUES (1,'x',0)")
    ok, detail = expect_throw(lambda: qa.tmp.execute("INSERT INTO balances (account_id, asset, amount, reserved) VALUES (1,'BTC',5,10)"), r"CHECK|constraint")
    qa.check("reserved<=amount enforced", ok, detail)


@then("inserting an order whose filled exceeds its size fails a CHECK")
def filled_check(qa):
    qa.tmp.execute("INSERT INTO accounts (id, handle, created_at) VALUES (1,'x',0)")
    ok, detail = expect_throw(lambda: qa.tmp.execute("INSERT INTO orders (account_id,base,quote,side,type,price,size,filled,status,tif,post_only,created_at,seq) VALUES (1,'BTC','USD','sell','limit',100,5,10,'open','GTC',0,0,1)"), r"CHECK|constraint")
    qa.check("filled<=size enforced", ok, detail)


@then("inserting a fill whose taker and maker are the same account fails a CHECK")
def fill_check(qa):
    qa.tmp.execute("INSERT INTO accounts (id, handle, created_at) VALUES (1,'x',0)")
    qa.tmp.execute("INSERT INTO orders (id,account_id,base,quote,side,type,price,size,filled,status,tif,post_only,created_at,seq) VALUES (1,1,'BTC','USD','buy','limit',100,5,0,'open','GTC',0,0,1)")
    qa.tmp.execute("INSERT INTO orders (id,account_id,base,quote,side,type,price,size,filled,status,tif,post_only,created_at,seq) VALUES (2,1,'BTC','USD','sell','limit',100,5,0,'open','GTC',0,0,2)")
    ok, detail = expect_throw(lambda: qa.tmp.execute("INSERT INTO fills (taker_order,maker_order,base,quote,price,size,taker_account,maker_account,created_at) VALUES (1,2,'BTC','USD',100,5,1,1,0)"), r"CHECK|constraint")
    qa.check("taker<>maker enforced", ok, detail)


# ---------------------------------------------------------------- order actions

@given(parsers.parse('"{alias}" is funded with {amt:g} {asset}'))
@when(parsers.parse('"{alias}" is funded with {amt:g} {asset}'))
def is_funded(qa, alias, amt, asset):
    act(qa, lambda: setattr(qa, "api", cex.deposit(acct(qa, alias)["token"], asset, coin(amt))))


@given(parsers.parse('"{alias}" places a limit {side} of {size:g} {base} at {price:g} {quote}'))
@when(parsers.parse('"{alias}" places a limit {side} of {size:g} {base} at {price:g} {quote}'))
def place_limit(qa, alias, side, size, base, price, quote):
    act(qa, lambda: place(qa, alias, side, size, base, price, quote))


@when(parsers.parse('"{alias}" places a limit {side} of {size:g} {base} at {price:g} {quote} with key "{key}"'))
def place_limit_key(qa, alias, side, size, base, price, quote, key):
    act(qa, lambda: place(qa, alias, side, size, base, price, quote, key=key))


@when(parsers.parse('"{alias}" places a post-only {side} of {size:g} {base} at {price:g} {quote}'))
def place_post_only(qa, alias, side, size, base, price, quote):
    act(qa, lambda: place(qa, alias, side, size, base, price, quote, post_only=True))


@when(parsers.parse('"{alias}" places a FOK {side} of {size:g} {base} at {price:g} {quote}'))
def place_fok(qa, alias, side, size, base, price, quote):
    act(qa, lambda: place(qa, alias, side, size, base, price, quote, tif="FOK"))


@when(parsers.parse('"{alias}" places an IOC {side} of {size:g} {base} at {price:g} {quote}'))
def place_ioc(qa, alias, side, size, base, price, quote):
    act(qa, lambda: place(qa, alias, side, size, base, price, quote, tif="IOC"))


@when(parsers.parse('"{alias}" places a market {side} of {size:g} {base} paying {quote}'))
def place_market(qa, alias, side, size, base, quote):
    act(qa, lambda: place(qa, alias, side, size, base, 0, quote, type="market"))


@when(parsers.parse('"{alias}" cancels the order'))
def cancel_order(qa, alias):
    def go():
        qa.api = cex.request("DELETE", "/orders/" + str(qa.last_order["id"]), token=acct(qa, alias)["token"])
        qa.last_order = qa.api["body"]
    act(qa, go)


# ---------------------------------------------------------------- assertions

@then(parsers.parse('the order status is "{status}"'))
def order_status(qa, status):
    assert_(qa, "order status " + status, qa.last_order and qa.last_order["status"] == status, f"got {qa.last_order['status']}" if qa.last_order else "no order")


@then(parsers.parse('the taker order status is "{status}"'))
def taker_status(qa, status):
    assert_(qa, "taker order status " + status, qa.last_order and qa.last_order["status"] == status, f"got {qa.last_order['status']}" if qa.last_order else "no order")


@then(parsers.parse("the order filled is {amt:g} {a2}"))
def order_filled(qa, amt, a2):
    assert_(qa, "order filled", qa.last_order and qa.last_order["filled"] == coin(amt), f"got {qa.last_order['filled']}" if qa.last_order else "no order")


@then(parsers.parse('the reserved {asset} of "{alias}" is {amt:g}'))
def reserved_of(qa, asset, alias, amt):
    got = qa.store.reserved(qa.store.account_id(acct(qa, alias)["handle"]), asset)
    assert_(qa, f"reserved {asset} of {alias}", got == coin(amt), f"got {got}")


@then(parsers.parse("the order book has an ask of {size:g} {base} at {price:g} {quote}"))
def book_ask(qa, size, base, price, quote):
    def go():
        r = cex.orderbook(base, quote)
        row = next((x for x in (r["body"]["asks"] or []) if x["price"] == coin(price) and x["size"] == coin(size)), None)
        assert_(qa, "ask present", row is not None, str(r["body"]["asks"]))
    act(qa, go)


@then(parsers.parse("a fill records {size:g} {base} at {price:g} {quote}"))
def fill_records(qa, size, base, price, quote):
    def go():
        r = cex.fills_of(base, quote)
        row = next((f for f in (r["body"]["fills"] or []) if f["size"] == coin(size) and f["price"] == coin(price)), None)
        assert_(qa, "fill present", row is not None, str(r["body"]["fills"]))
    act(qa, go)


@then(parsers.parse("the last fill taker fee is {bps:d} basis points of {amt:g} {a2}"))
def last_taker_fee(qa, bps, amt, a2):
    def go():
        f = (cex.fills_of(qa.last_order["base"], qa.last_order["quote"])["body"]["fills"] or [])[-1:]
        f = f[0] if f else None
        expected = (coin(amt) * bps) // 10000
        assert_(qa, "taker fee", f and f["taker_fee"] == expected, f"got {f['taker_fee']}, expected {expected}" if f else "no fill")
    act(qa, go)


@then(parsers.parse("the last fill maker fee is {bps:d} basis points of {amt:g} {a2}"))
def last_maker_fee(qa, bps, amt, a2):
    def go():
        f = (cex.fills_of(qa.last_order["base"], qa.last_order["quote"])["body"]["fills"] or [])[-1:]
        f = f[0] if f else None
        expected = (coin(amt) * bps) // 10000
        assert_(qa, "maker fee", f and f["maker_fee"] == expected, f"got {f['maker_fee']}, expected {expected}" if f else "no fill")
    act(qa, go)


@then(parsers.parse('the maker order for "{alias}" is "{status}" with filled {amt:g} {a2}'))
def maker_order_state(qa, alias, status, amt, a2):
    def go():
        r = cex.orders_of(acct(qa, alias)["handle"])
        o = (r["body"]["orders"] or [])[-1:]
        o = o[0] if o else None
        assert_(qa, "maker order state", o and o["status"] == status and o["filled"] == coin(amt), f"status {o['status']} filled {o['filled']}" if o else "no order")
    act(qa, go)


@then(parsers.parse('the open orders of "{alias}" number {n:d}'))
def open_orders_count(qa, alias, n):
    def go():
        r = cex.orders_of(acct(qa, alias)["handle"], "open")
        assert_(qa, "open orders count", len(r["body"]["orders"] or []) == n, "got " + str(len(r["body"]["orders"] or [])))
    act(qa, go)


@then("the second order was an idempotent replay")
def order_replay(qa):
    assert_(qa, "order idempotent replay", qa.api and qa.api["body"] and qa.api["body"].get("idempotent_replay") is True, str(qa.api["body"])[:80] if qa.api else "no response")


@then("the base leaving the maker equals the base reaching the taker plus the taker fee")
def base_conserved(qa):
    def go():
        fills = cex.fills_of(qa.last_order["base"], qa.last_order["quote"])["body"]["fills"] or []
        f = fills[-1] if fills else None
        taker_base = qa.store.balance(qa.store.account_id(acct(qa, "taker")["handle"]), qa.last_order["base"])
        assert_(qa, "base conserved", f and (taker_base + f["taker_fee"] == f["size"]), f"taker {taker_base} + fee {f['taker_fee']} vs size {f['size']}" if f else "no fill")
    act(qa, go)


@then("the quote leaving the taker equals the quote reaching the maker plus the maker fee")
def quote_conserved(qa):
    def go():
        fills = cex.fills_of(qa.last_order["base"], qa.last_order["quote"])["body"]["fills"] or []
        f = fills[-1] if fills else None
        if not f:
            assert_(qa, "quote conserved", False, "no fill")
            return
        maker_quote = qa.store.balance(qa.store.account_id(acct(qa, "maker")["handle"]), qa.last_order["quote"])
        quote_total = (f["size"] * f["price"]) // int(1e8)
        assert_(qa, "quote conserved", maker_quote + f["maker_fee"] == quote_total, f"maker {maker_quote} + fee {f['maker_fee']} vs total {quote_total}")
    act(qa, go)


@when("the fee schedule is read")
def read_fees(qa):
    act(qa, lambda: setattr(qa, "fee_tiers", cex.fees()["body"]["tiers"]))


@then(parsers.parse("the entry tier charges {taker:d} basis points taker and {maker:d} maker"))
def entry_tier(qa, taker, maker):
    t0 = next((t for t in (getattr(qa, "fee_tiers", []) or []) if t["tier"] == 0), None)
    assert_(qa, "entry tier bps", t0 and t0["taker_bps"] == taker and t0["maker_bps"] == maker, str(t0))


@then("a higher tier pays the maker a rebate")
def rebate_tier(qa):
    assert_(qa, "a rebate tier exists", any(t["maker_bps"] < 0 for t in (getattr(qa, "fee_tiers", []) or [])), str(getattr(qa, "fee_tiers", [])))
