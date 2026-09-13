"""Steps for be-cex-db.feature and the shared "drive the service" account and
action steps that the API and FE features reuse. Mirror of
node/be/db/steps/cex.steps.js -- a plugin module.

Isolation is by fresh accounts and deltas, not reset. Amounts in the features
are decimal coins; coin() scales them to the 1e8 base units the store holds.
Steps that a feature uses under both `And`(Given) and `When` carry both
decorators, because pytest-bdd matches on the keyword group.
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest
from pytest_bdd import given, parsers, then, when

from be.api.venues.minicex import ApiUnreachable, MiniCex
from be.db.store import DbUnreachable, Store, throwaway

cex = MiniCex()
UNREACHABLE = (DbUnreachable, ApiUnreachable)
SEED = Path(__file__).resolve().parents[4] / "services" / "mini-cex" / "db" / "seed.sql"


def coin(n):
    return round(float(n) * 1e8)


@pytest.fixture(autouse=True)
def cex_scenario(qa):
    qa.store = None
    qa.cex = cex
    qa.accounts = {}
    qa.api = None
    qa.tmp = None
    qa.last_bridge = None
    qa.bridge_deposit_req = None
    yield
    if qa.tmp is not None:
        qa.tmp.close()
    if qa.store is not None:
        qa.store.close()


def act(qa, fn):
    if qa.source_error:
        return None
    try:
        return fn()
    except UNREACHABLE as err:
        qa.source_error = str(err)
        return None


def check(qa, description, fn):
    if qa.source_error:
        qa.unobservable(description, "the source could not be reached -- " + qa.source_error)
        return
    try:
        passed, detail = fn()
    except UNREACHABLE as err:
        qa.unobservable(description, str(err))
        return
    qa.check(description, passed, detail)


def expect_throw(fn, needle):
    try:
        fn()
        return (False, "no error thrown")
    except Exception as err:  # noqa: BLE001
        ok = re.search(needle, str(err), re.I) is not None
        return (ok, ("rejected: " + str(err).split(chr(10))[0]) if ok else ("wrong error: " + str(err)))


def ensure_account(qa, alias):
    if alias in qa.accounts:
        return qa.accounts[alias]
    a = cex.create_account(alias)
    qa.accounts[alias] = a
    return a


def acct(qa, alias):
    return qa.accounts[alias]


# ---------------------------------------------------------------- Background

@given("the store is open and the service is reachable")
def store_open(qa):
    if qa.source_error:
        return
    try:
        qa.store = Store()
    except DbUnreachable as err:
        qa.source_error = str(err)
        return
    r = act(qa, lambda: cex.get("/assets"))
    if qa.source_error:
        return
    if not r or r["status"] != 200:
        qa.source_error = "mini-cex /assets returned " + str(r["status"] if r else "nothing")


# ---------------------------------------------------------------- throwaway schema

@given("a throwaway database with the schema applied")
def throwaway_schema(qa):
    qa.tmp = throwaway()
    qa.tmp.execute("INSERT INTO assets (symbol, name, kind, decimals, usd_micro) VALUES ('BTC','Bitcoin','crypto',8,1), ('USD','US Dollar','fiat',2,1)")


@given("a throwaway database with the schema and seed applied")
def throwaway_seed(qa):
    qa.tmp = throwaway()
    qa.tmp.executescript(SEED.read_text(encoding="utf-8"))


@then(parsers.re(r"the store has tables (?P<csv>.+)"))
def has_tables(qa, csv):
    def ev():
        have = set(qa.store.tables())
        want = [s.strip() for s in csv.split(",")]
        missing = [t for t in want if t not in have]
        return (not missing, "missing " + ",".join(missing) if missing else "all present")
    check(qa, "documented tables present", ev)


@then("inserting a balance with a negative amount fails a CHECK")
def neg_balance(qa):
    qa.tmp.execute("INSERT INTO accounts (id, handle, created_at) VALUES (1, 'x', 0)")
    ok, detail = expect_throw(lambda: qa.tmp.execute("INSERT INTO balances (account_id, asset, amount) VALUES (1, 'BTC', -1)"), r"CHECK|constraint")
    qa.check("negative balance rejected", ok, detail)


@then("inserting a ledger row with zero delta fails a CHECK")
def zero_delta(qa):
    qa.tmp.execute("INSERT INTO accounts (id, handle, created_at) VALUES (1, 'x', 0)")
    ok, detail = expect_throw(lambda: qa.tmp.execute("INSERT INTO ledger (account_id, asset, delta, reason, created_at) VALUES (1, 'BTC', 0, 'deposit', 0)"), r"CHECK|constraint")
    qa.check("zero delta rejected", ok, detail)


@then(parsers.parse('inserting a ledger row with reason "{reason}" fails a CHECK'))
def bad_reason(qa, reason):
    ok, detail = expect_throw(lambda: qa.tmp.execute(f"INSERT INTO ledger (account_id, asset, delta, reason, created_at) VALUES (1, 'BTC', 1, '{reason}', 0)"), r"CHECK|constraint")
    qa.check("bad reason rejected", ok, detail)


@then("inserting a balance for a missing account fails a FOREIGN KEY")
def missing_account_fk(qa):
    ok, detail = expect_throw(lambda: qa.tmp.execute("INSERT INTO balances (account_id, asset, amount) VALUES (999, 'BTC', 1)"), r"FOREIGN KEY|constraint")
    qa.check("missing account FK rejected", ok, detail)


@then("inserting two deposit bridge ops with the same external tx fails on the second")
def dup_bridge(qa):
    qa.tmp.execute("INSERT INTO accounts (id, handle, created_at) VALUES (1, 'x', 0)")
    ins = "INSERT INTO bridge_ops (account_id, asset, amount, direction, src_chain, dst_chain, status, ext_tx, created_at, updated_at) VALUES (1,'BTC',1,'deposit','ethereum','mini-cex','credited','tx1',0,0)"
    qa.tmp.execute(ins)
    ok, detail = expect_throw(lambda: qa.tmp.execute(ins), r"UNIQUE|constraint")
    qa.check("duplicate bridge ext_tx rejected", ok, detail)


@then("inserting a pair whose base equals its quote fails a CHECK")
def same_leg_pair(qa):
    ok, detail = expect_throw(lambda: qa.tmp.execute("INSERT INTO pairs (base, quote) VALUES ('BTC','BTC')"), r"CHECK|constraint")
    qa.check("same-leg pair rejected", ok, detail)


@then("applying the seed again changes no row counts")
def seed_idempotent(qa):
    def cnt():
        return (qa.tmp.execute("SELECT COUNT(*) FROM assets").fetchone()[0], qa.tmp.execute("SELECT COUNT(*) FROM pairs").fetchone()[0])
    before = cnt()
    qa.tmp.executescript(SEED.read_text(encoding="utf-8"))
    after = cnt()
    qa.check("seed is idempotent", before == after, f"assets {before[0]}->{after[0]}, pairs {before[1]}->{after[1]}")


# ---------------------------------------------------------------- shared account + action steps

@given(parsers.parse('a fresh account "{alias}"'))
def fresh_account(qa, alias):
    act(qa, lambda: ensure_account(qa, alias))


@given(parsers.parse('a fresh account "{alias}" funded with {amt:f} {asset}'))
def fresh_funded(qa, alias, amt, asset):
    def go():
        a = ensure_account(qa, alias)
        qa.api = cex.deposit(a["token"], asset, coin(amt))
    act(qa, go)


def _deposit(qa, alias, amt, asset, key=None):
    a = ensure_account(qa, alias)
    qa.api = cex.deposit(a["token"], asset, coin(amt), key)


@given(parsers.parse('"{alias}" deposits {amt:f} {asset}'))
@when(parsers.parse('"{alias}" deposits {amt:f} {asset}'))
def deposits(qa, alias, amt, asset):
    act(qa, lambda: _deposit(qa, alias, amt, asset))


@when(parsers.parse('"{alias}" deposits {amt:f} {asset} with key "{key}"'))
def deposits_key(qa, alias, amt, asset, key):
    act(qa, lambda: _deposit(qa, alias, amt, asset, key))


@when(parsers.parse('"{alias}" withdraws {amt:f} {asset}'))
def withdraws(qa, alias, amt, asset):
    def go():
        qa.api = cex.withdraw(acct(qa, alias)["token"], asset, coin(amt))
    act(qa, go)


@when(parsers.parse('"{alias}" transfers {amt:f} {asset} to "{to}"'))
def transfers(qa, alias, amt, asset, to):
    def go():
        to_acct = ensure_account(qa, to)
        qa.api = cex.transfer(acct(qa, alias)["token"], to_acct["handle"], asset, coin(amt))
    act(qa, go)


@when(parsers.parse('"{alias}" tries to transfer {amt:f} {asset} to "{to}"'))
def tries_transfer(qa, alias, amt, asset, to):
    def go():
        to_acct = ensure_account(qa, to)
        qa.api = cex.transfer(acct(qa, alias)["token"], to_acct["handle"], asset, coin(amt))
    act(qa, go)


@when(parsers.parse('"{alias}" swaps {amt:f} {frm} to {to}'))
def swaps(qa, alias, amt, frm, to):
    def go():
        qa.api = cex.swap(acct(qa, alias)["token"], {"from_asset": frm, "to_asset": to, "from_amount": coin(amt)})
    act(qa, go)


@when(parsers.parse('"{alias}" swaps {amt:f} {frm} to {to} demanding at least {minv:f} {q} out'))
def swaps_min(qa, alias, amt, frm, to, minv, q):
    def go():
        qa.api = cex.swap(acct(qa, alias)["token"], {"from_asset": frm, "to_asset": to, "from_amount": coin(amt), "min_to_amount": coin(minv)})
    act(qa, go)


@given(parsers.parse('"{alias}" bridge-withdraws {amt:f} {asset} to chain "{chain}"'))
@when(parsers.parse('"{alias}" bridge-withdraws {amt:f} {asset} to chain "{chain}"'))
def bridge_withdraw(qa, alias, amt, asset, chain):
    def go():
        qa.api = cex.bridge_withdraw(acct(qa, alias)["token"], {"asset": asset, "amount": coin(amt), "dst_chain": chain})
        if qa.api["status"] == 201:
            qa.last_bridge = qa.api["body"]
    act(qa, go)


@when(parsers.parse('a bridge deposit of {amt:f} {asset} for "{alias}" from chain "{chain}" with tx "{tx}" is observed'))
def bridge_deposit(qa, amt, asset, alias, chain, tx):
    def go():
        a = ensure_account(qa, alias)
        qa.bridge_deposit_req = {"handle": a["handle"], "asset": asset, "amount": coin(amt), "src_chain": chain, "ext_tx": tx}
        qa.api = cex.bridge_deposit(qa.bridge_deposit_req)
        if qa.api["body"] and qa.api["body"].get("id"):
            qa.last_bridge = qa.api["body"]
    act(qa, go)


@when("the same bridge deposit is observed again")
def bridge_deposit_again(qa):
    act(qa, lambda: setattr(qa, "api", cex.bridge_deposit(qa.bridge_deposit_req)))


@when("the bridge op is confirmed")
def bridge_confirm(qa):
    def go():
        qa.api = cex.bridge_confirm(qa.last_bridge["id"])
        qa.last_bridge = qa.api["body"]
    act(qa, go)


# ---------------------------------------------------------------- DB Thens

def _bal(qa, alias, asset):
    return qa.store.balance(qa.store.account_id(acct(qa, alias)["handle"]), asset)


def _ledger_sum(qa, alias, asset):
    return qa.store.ledger_balance(qa.store.account_id(acct(qa, alias)["handle"]), asset)


@then(parsers.parse('the balance row for "{alias}" in {asset} is {amt:f} {a2}'))
def balance_row(qa, alias, asset, amt, a2):
    check(qa, f"balance {alias}/{asset}", lambda: ((_bal(qa, alias, asset) == coin(amt)), f"got {_bal(qa, alias, asset)}, want {coin(amt)}"))


@then(parsers.parse('a ledger line credits "{alias}" {amt:f} {asset} with reason "{reason}"'))
def ledger_credit(qa, alias, amt, asset, reason):
    def ev():
        aid = qa.store.account_id(acct(qa, alias)["handle"])
        row = qa.store.get("SELECT * FROM ledger WHERE account_id=? AND asset=? AND delta=? AND reason=?", aid, asset, coin(amt), reason)
        return (row is not None, "found" if row else "no matching ledger line")
    check(qa, f"ledger credit {reason}", ev)


@then(parsers.parse('a ledger line debits "{alias}" {amt:f} {asset} with reason "{reason}"'))
def ledger_debit(qa, alias, amt, asset, reason):
    def ev():
        aid = qa.store.account_id(acct(qa, alias)["handle"])
        row = qa.store.get("SELECT * FROM ledger WHERE account_id=? AND asset=? AND delta=? AND reason=?", aid, asset, -coin(amt), reason)
        return (row is not None, "found" if row else "no matching ledger line")
    check(qa, f"ledger debit {reason}", ev)


@then(parsers.parse('the ledger sum for "{alias}" in {asset} equals the balance row'))
def ledger_eq_balance(qa, alias, asset):
    check(qa, f"ledger == balance {asset}", lambda: ((_ledger_sum(qa, alias, asset) == _bal(qa, alias, asset)), f"ledger {_ledger_sum(qa, alias, asset)}, balance {_bal(qa, alias, asset)}"))


@then(parsers.parse('the total BTC across "{a1}" and "{a2}" is unchanged'))
def total_conserved(qa, a1, a2):
    check(qa, "total conserved", lambda: (((_bal(qa, a1, "BTC") + _bal(qa, a2, "BTC")) == coin(1.0)), f"total {_bal(qa, a1, 'BTC') + _bal(qa, a2, 'BTC')}"))


@then(parsers.parse('"{alias}" has a swap row from {frm} to {to}'))
def swap_row(qa, alias, frm, to):
    def ev():
        aid = qa.store.account_id(acct(qa, alias)["handle"])
        row = qa.store.get("SELECT * FROM swaps WHERE account_id=? AND from_asset=? AND to_asset=?", aid, frm, to)
        return (row is not None, f"swap #{row['id']}" if row else "no swap row")
    check(qa, "swap row present", ev)


@then(parsers.parse('the bridge op for "{alias}" is in status "{status}"'))
def bridge_status_db(qa, alias, status):
    def ev():
        aid = qa.store.account_id(acct(qa, alias)["handle"])
        row = qa.store.get("SELECT * FROM bridge_ops WHERE account_id=? ORDER BY id DESC LIMIT 1", aid)
        return (row is not None and row["status"] == status, f"status {row['status']}" if row else "no bridge op")
    check(qa, "bridge op status", ev)


@then(parsers.parse('"{alias}" has exactly one bridge op with external tx "{tx}"'))
def one_bridge(qa, alias, tx):
    check(qa, "one bridge op by ext_tx", lambda: ((qa.store.count("bridge_ops", "WHERE ext_tx = ?", tx) == 1), f"count {qa.store.count('bridge_ops', 'WHERE ext_tx = ?', tx)}"))


@then(parsers.parse('the transfer is refused with code "{code}"'))
def transfer_refused(qa, code):
    check(qa, "transfer refused", lambda: ((qa.api and qa.api["status"] >= 400 and qa.api["body"] and qa.api["body"].get("code") == code), f"status {qa.api['status']} code {qa.api['body'].get('code') if qa.api['body'] else None}" if qa.api else "no response"))


@then(parsers.parse('"{alias}" has no {asset} balance row'))
def no_balance_row(qa, alias, asset):
    def ev():
        aid = qa.store.account_id(acct(qa, alias)["handle"])
        row = qa.store.get("SELECT * FROM balances WHERE account_id=? AND asset=?", aid, asset) if aid else None
        return (row is None, f"amount {row['amount']}" if row else "absent")
    check(qa, "no balance row", ev)
