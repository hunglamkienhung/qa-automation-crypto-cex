"""Steps for be-cex-earn.feature. Mirror of node/be/api/steps/earn.steps.js.
Staking locks a principal that accrues a fixed APR over explicit simulated
seconds and is redeemed for principal + reward.
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


@then("inserting a stake with a non-positive principal fails a CHECK")
def stake_principal_check(qa):
    qa.tmp.execute("INSERT INTO accounts (id, handle, created_at) VALUES (1,'x',0)")
    try:
        qa.tmp.execute("INSERT INTO stakes (account_id, asset, principal, apr_bps, status, created_at) VALUES (1,'BTC',0,500,'active',0)")
        qa.check("principal>0 enforced", False, "no error thrown")
    except Exception as err:  # noqa: BLE001
        qa.check("principal>0 enforced", re.search(r"CHECK|constraint", str(err), re.I) is not None, str(err))


def do_stake(qa, alias, amt, asset, apr):
    a = acct(qa, alias)
    qa.stake_token = a["token"]
    qa.api = cex.stake(a["token"], {"asset": asset, "amount": coin(amt), "apr_bps": apr})
    if qa.api["status"] in (200, 201):
        qa.current_stake = qa.api["body"]


@given(parsers.parse('"{alias}" stakes {amt:g} {asset} at {apr:d} bps'))
@when(parsers.parse('"{alias}" stakes {amt:g} {asset} at {apr:d} bps'))
def stakes(qa, alias, amt, asset, apr):
    act(qa, lambda: do_stake(qa, alias, amt, asset, apr))


@given(parsers.parse("the stake accrues {seconds:d} seconds"))
@when(parsers.parse("the stake accrues {seconds:d} seconds"))
def stake_accrues(qa, seconds):
    def go():
        qa.api = cex.stake_accrue(qa.stake_token, qa.current_stake["id"], seconds)
        qa.current_stake = qa.api["body"]
    act(qa, go)


@given("the stake is redeemed")
@when("the stake is redeemed")
def stake_redeemed(qa):
    def go():
        qa.api = cex.stake_redeem(qa.stake_token, qa.current_stake["id"])
        qa.current_stake = qa.api["body"]
    act(qa, go)


@when("the stake is redeemed again")
def stake_redeemed_again(qa):
    act(qa, lambda: setattr(qa, "api", cex.stake_redeem(qa.stake_token, qa.current_stake["id"])))


@when(parsers.parse('"{alias}" tries to withdraw {amt:g} {asset}'))
def tries_withdraw(qa, alias, amt, asset):
    act(qa, lambda: setattr(qa, "api", cex.withdraw(acct(qa, alias)["token"], asset, coin(amt))))


def _assert(qa, description, cond, detail):
    if qa.source_error:
        qa.unobservable(description, qa.source_error)
        return
    qa.check(description, bool(cond), detail)


@then(parsers.parse("the stake accrued is {amt:g} {a2}"))
def stake_accrued(qa, amt, a2):
    _assert(qa, "stake accrued " + str(amt), qa.current_stake and qa.current_stake["accrued"] == coin(amt), f"got {qa.current_stake['accrued']} want {coin(amt)}" if qa.current_stake else "no stake")


@then("the second redemption was an idempotent replay")
def redeem_replay(qa):
    _assert(qa, "redeem idempotent replay", qa.api and qa.api["body"] and qa.api["body"].get("idempotent_replay") is True, str(qa.api["body"])[:80] if qa.api else "no response")
