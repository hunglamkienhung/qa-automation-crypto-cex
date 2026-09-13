"""API-tier steps for be-cex-api.feature. Mirror of node/be/api/steps/minicex.steps.js.
The account and action steps are shared from be/db/steps/cex_steps.py; here are
the read-only calls and the assertions on the HTTP response itself.
"""

from __future__ import annotations

import random
import time

from pytest_bdd import parsers, then, when

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


# ---------------------------------------------------------------- read-only actions

@when("the assets are read")
def read_assets(qa):
    act(qa, lambda: setattr(qa, "api", cex.get("/assets")))


@when("the pairs are read")
def read_pairs(qa):
    act(qa, lambda: setattr(qa, "api", cex.get("/pairs")))


@when(parsers.parse("a quote of {amt:f} {frm} to {to} is requested"))
def request_quote(qa, amt, frm, to):
    def go():
        qa.api = cex.quote(frm, to, coin(amt))
        qa.quote = qa.api["body"]
    act(qa, go)


@when(parsers.parse('a fresh account "{alias}" is created'))
def create_account_api(qa, alias):
    def go():
        handle = f"{alias}-{int(time.time()*1000):x}{random.randint(0, 65535):04x}"
        qa.api = cex.post("/accounts", {"handle": handle})
        if qa.api["status"] == 201:
            qa.accounts[alias] = qa.api["body"]
    act(qa, go)


@when(parsers.parse('an account is created with the same handle as "{alias}"'))
def create_duplicate(qa, alias):
    act(qa, lambda: setattr(qa, "api", cex.post("/accounts", {"handle": acct(qa, alias)["handle"]})))


@when("a deposit is attempted with no token")
def deposit_no_token(qa):
    act(qa, lambda: setattr(qa, "api", cex.post("/deposit", {"asset": "BTC", "amount": coin(1)})))


# ---------------------------------------------------------------- response assertions

@then(parsers.parse("the response status is {code:d}"))
def response_status(qa, code):
    assert_(qa, f"response status {code}", qa.api and qa.api["status"] == code, (f"got {qa.api['status']} {(qa.api['text'] or '')[:120]}" if qa.api else "no response"))


@then(parsers.parse('the response code is "{code}"'))
def response_code(qa, code):
    assert_(qa, f"response code {code}", qa.api and qa.api["body"] and qa.api["body"].get("code") == code, (f"got {qa.api['body'].get('code')}" if qa.api and qa.api["body"] else "no body"))


@then("the response has a token")
def response_token(qa):
    b = qa.api["body"] if qa.api else None
    assert_(qa, "response has token", b and isinstance(b.get("token"), str) and len(b["token"]) > 0, str(b)[:80] if b else "no body")


@then(parsers.parse("the asset list includes {a}, {b}, {c}, {d}"))
def asset_list_includes(qa, a, b, c, d):
    have = {x["symbol"] for x in (qa.api["body"]["assets"] or [])}
    want = [a, b, c, d]
    assert_(qa, "asset list includes " + ",".join(want), all(s in have for s in want), "have " + ",".join(sorted(have)))


@then("every listed asset has a name and a USD price")
def assets_complete(qa):
    lst = qa.api["body"]["assets"] or []
    bad = [x for x in lst if not x.get("name") or not isinstance(x.get("usd_micro"), int)]
    assert_(qa, "assets have name + price", len(bad) == 0 and len(lst) > 0, f"{len(bad)} incomplete")


@then(parsers.parse("the pair list includes {b1}/{q1} and {b2}/{q2}"))
def pair_list_includes(qa, b1, q1, b2, q2):
    s = {p["base"] + "/" + p["quote"] for p in (qa.api["body"]["pairs"] or [])}
    assert_(qa, "pair list includes", (b1 + "/" + q1) in s and (b2 + "/" + q2) in s, " ".join(sorted(s)))


@then("no pair has the same asset on both legs")
def pairs_distinct(qa):
    bad = [p for p in (qa.api["body"]["pairs"] or []) if p["base"] == p["quote"]]
    assert_(qa, "pairs have distinct legs", len(bad) == 0, f"{len(bad)} bad")


@then("the quote net equals the gross minus the fee")
def quote_net(qa):
    q = qa.quote
    assert_(qa, "quote net = gross - fee", q and q["to_amount"] == q["gross_amount"] - q["fee_amount"], (f"net {q['to_amount']}, gross {q['gross_amount']}, fee {q['fee_amount']}" if q else "no quote"))


@then("the quote fee matches the pair fee in basis points")
def quote_fee(qa):
    q = qa.quote
    expected = (q["gross_amount"] * q["fee_bps"]) // 10000
    assert_(qa, "quote fee matches bps", q["fee_amount"] == expected, f"fee {q['fee_amount']}, expected {expected} at {q['fee_bps']}bps")


@then(parsers.parse('the API balance for "{alias}" in {asset} is {amt:f} {a2}'))
def api_balance(qa, alias, asset, amt, a2):
    def go():
        r = cex.get("/balances/" + acct(qa, alias)["handle"])
        row = next((x for x in (r["body"]["balances"] or []) if x["asset"] == asset), None)
        got = row["amount"] if row else 0
        assert_(qa, f"API balance {alias}/{asset}", got == coin(amt), f"got {got}, want {coin(amt)}")
    act(qa, go)


@then(parsers.parse('the API balance for "{alias}" in {asset} is above zero'))
def api_balance_positive(qa, alias, asset):
    def go():
        r = cex.get("/balances/" + acct(qa, alias)["handle"])
        row = next((x for x in (r["body"]["balances"] or []) if x["asset"] == asset), None)
        assert_(qa, f"API balance {alias}/{asset} > 0", bool(row) and row["amount"] > 0, f"got {row['amount']}" if row else f"no {asset} row")
    act(qa, go)


@then(parsers.parse("the swap response output equals the quote for {amt:f} {frm} to {to}"))
def swap_output_matches(qa, amt, frm, to):
    def go():
        q = cex.quote(frm, to, coin(amt))
        assert_(qa, "swap output == quote", qa.api["body"] and qa.api["body"]["to_amount"] == q["body"]["to_amount"], f"swap {qa.api['body'].get('to_amount') if qa.api['body'] else None}, quote {q['body']['to_amount']}")
    act(qa, go)


@then("the second deposit was an idempotent replay")
def deposit_replay(qa):
    b = qa.api["body"] if qa.api else None
    assert_(qa, "deposit idempotent replay", b and b.get("idempotent_replay") is True, str(b)[:80] if b else "no body")


@then("the second bridge deposit was an idempotent replay")
def bridge_replay(qa):
    b = qa.api["body"] if qa.api else None
    assert_(qa, "bridge deposit idempotent replay", b and b.get("idempotent_replay") is True, str(b)[:80] if b else "no body")


@then(parsers.parse('the bridge op is in status "{status}"'))
def bridge_status_api(qa, status):
    assert_(qa, f"bridge op status {status}", qa.last_bridge and qa.last_bridge.get("status") == status, (f"got {qa.last_bridge['status']}" if qa.last_bridge else "no bridge op"))
