"""Steps for be-cex-security.feature. Mirror of node/be/api/steps/security.steps.js
-- a plugin module. Adversarial edges around the scoped-key tier: a garbage
bearer token, cross-account key revocation, and secret-hygiene invariants.
Account/key Givens and the response assertions are shared from the other
@minicex steps.
"""

from __future__ import annotations

import json

from pytest_bdd import parsers, then, when

from be.api.venues.minicex import ApiUnreachable, MiniCex

cex = MiniCex()
SELL = {"base": "BTC", "quote": "USD", "side": "sell", "type": "limit", "price": round(60000 * 1e8), "size": round(0.5 * 1e8)}


def act(qa, fn):
    if qa.source_error:
        return
    try:
        fn()
    except ApiUnreachable as err:
        qa.source_error = str(err)


def body_text(qa):
    return json.dumps((qa.api or {}).get("body") or {})


@when("a write is attempted with a garbage bearer token")
def garbage_bearer(qa):
    def go():
        qa.api = cex.request("POST", "/orders", token="acct_garbage000000000000000000", body=SELL)
    act(qa, go)


@when("another account tries to revoke that key")
def other_revokes(qa):
    def go():
        other = cex.create_account("intruder")
        qa.api = cex.request("DELETE", "/apikeys/" + qa.current_key["key"], token=other["token"])
    act(qa, go)


@when(parsers.parse('"{alias}"\'s API keys are listed'))
def keys_listed(qa, alias):
    def go():
        qa.api = cex.get("/apikeys/" + qa.accounts[alias]["handle"])
    act(qa, go)


@when("the listed assets are read")
def assets_read(qa):
    def go():
        qa.api = cex.get("/assets")
    act(qa, go)


@then("the key list shows a prefix but not the full key")
def key_list_prefix(qa):
    def ev():
        full = qa.current_key["key"]
        text = body_text(qa)
        return (full not in text and full[:12] in text, "FULL KEY LEAKED" if full in text else "prefix only")
    qa.observe("key list shows only a prefix", ev)


@then("the response carries no account token or API key")
def no_credential(qa):
    def ev():
        text = body_text(qa)
        leaks = [p for p in ("acct_", "key_") if p in text]
        return (not leaks, "leaked " + ",".join(leaks) if leaks else "clean")
    qa.observe("no credential leaked", ev)
