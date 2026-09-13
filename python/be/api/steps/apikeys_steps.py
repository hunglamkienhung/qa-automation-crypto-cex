"""Steps for be-cex-apikeys.feature. Mirror of node/be/api/steps/apikeys.steps.js.
Keys are minted with the owner Bearer token and used via X-API-Key.
"""

from __future__ import annotations

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


@given(parsers.parse('"{alias}" holds a "{scope}" API key'))
def holds_key(qa, alias, scope):
    def go():
        r = cex.create_key(acct(qa, alias)["token"], scope)
        qa.current_key = {"key": r["body"]["key"], "owner": acct(qa, alias)["token"]}
    act(qa, go)


@given(parsers.parse('"{alias}" holds a "{scope}" API key limited to {rate:d} per minute'))
def holds_key_rate(qa, alias, scope, rate):
    def go():
        r = cex.create_key(acct(qa, alias)["token"], scope, rate)
        qa.current_key = {"key": r["body"]["key"], "owner": acct(qa, alias)["token"]}
    act(qa, go)


@given("the key is revoked")
def key_revoked(qa):
    act(qa, lambda: cex.revoke_key(qa.current_key["owner"], qa.current_key["key"]))


@when(parsers.parse('"{alias}" mints a "{scope}" API key'))
def mints_key(qa, alias, scope):
    act(qa, lambda: setattr(qa, "api", cex.create_key(acct(qa, alias)["token"], scope)))


@when(parsers.parse("the key places a limit sell of {size:g} {base} at {price:g} {quote}"))
def key_places(qa, size, base, price, quote):
    act(qa, lambda: setattr(qa, "api", cex.request_with_key("POST", "/orders", qa.current_key["key"], {"base": base, "quote": quote, "side": "sell", "type": "limit", "price": coin(price), "size": coin(size)})))


@when(parsers.parse("an unknown key places a limit sell of {size:g} {base} at {price:g} {quote}"))
def unknown_key_places(qa, size, base, price, quote):
    act(qa, lambda: setattr(qa, "api", cex.request_with_key("POST", "/orders", "key_nope", {"base": base, "quote": quote, "side": "sell", "type": "limit", "price": coin(price), "size": coin(size)})))


@when(parsers.parse("the key withdraws {amt:g} {asset}"))
def key_withdraws(qa, amt, asset):
    act(qa, lambda: setattr(qa, "api", cex.request_with_key("POST", "/withdraw", qa.current_key["key"], {"asset": asset, "amount": coin(amt)})))


@when(parsers.parse("the key deposits {amt:g} {asset} three times"))
def key_deposits_thrice(qa, amt, asset):
    def go():
        for _ in range(3):
            qa.api = cex.request_with_key("POST", "/deposit", qa.current_key["key"], {"asset": asset, "amount": coin(amt)})
    act(qa, go)


@when(parsers.parse('the key tries to mint a "{scope}" API key'))
def key_tries_mint(qa, scope):
    act(qa, lambda: setattr(qa, "api", cex.request_with_key("POST", "/apikeys", qa.current_key["key"], {"scope": scope})))


@when(parsers.parse('the keys of "{alias}" are read'))
def keys_read(qa, alias):
    act(qa, lambda: setattr(qa, "api", cex.keys_of(acct(qa, alias)["handle"])))


def _assert(qa, description, cond, detail):
    if qa.source_error:
        qa.unobservable(description, qa.source_error)
        return
    qa.check(description, bool(cond), detail)


@then(parsers.parse('the minted key has scope "{scope}"'))
def minted_scope(qa, scope):
    _assert(qa, "minted key scope " + scope, qa.api and qa.api["body"] and qa.api["body"].get("scope") == scope, str(qa.api["body"])[:80] if qa.api else "no response")


@then(parsers.parse("the last response status is {code:d}"))
def last_status(qa, code):
    _assert(qa, "last response status " + str(code), qa.api and qa.api["status"] == code, f"got {qa.api['status']}" if qa.api else "no response")


@then(parsers.parse('a listed key has scope "{scope}"'))
def listed_scope(qa, scope):
    found = qa.api and qa.api["body"] and any(k["scope"] == scope for k in qa.api["body"].get("keys", []))
    _assert(qa, "a listed key has scope " + scope, found, str(qa.api["body"])[:100] if qa.api else "no response")
