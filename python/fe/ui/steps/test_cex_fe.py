"""The FE branch for the mini-cex screens. Binds ../../features/fe-cex.feature.
Mirror of node/fe/ui/steps/cex.steps.js. The `page` fixture is pytest-playwright's;
the comparison figures come from the same API the BE tier reads. The mini-cex is
deterministic and local, so these grade strictly; they Block only if the service
or the browser is unavailable.
"""

from __future__ import annotations

import re

from pytest_bdd import given, parsers, scenarios, then, when

from be.api.venues.minicex import ApiUnreachable, MiniCex
from fe.ui.pages.wallet import ScreenNotReady, WalletPage

scenarios("fe-cex.feature")

cex = MiniCex()
UNREACHABLE = (ScreenNotReady, ApiUnreachable)


def acct(qa, alias):
    return qa.accounts[alias]


@given("the service is reachable and the home page is open")
def home_open(page, qa):
    page.set_viewport_size({"width": 1440, "height": 900})
    qa.wallet = WalletPage(page)

    def go():
        qa.wallet.open("/")
        qa.screen["assets"] = qa.wallet.assets()
    qa.fetch_or_block(UNREACHABLE, go)


def screen(qa, description, fn):
    if qa.source_error:
        qa.unobservable(description, "the source could not be reached -- " + qa.source_error)
        return
    try:
        passed, detail = fn()
    except UNREACHABLE as err:
        qa.unobservable(description, str(err))
        return
    qa.check(description, passed, detail)


@then(parsers.parse("the assets on screen include {a}, {b}, {c}, {d}"))
def assets_on_screen(qa, a, b, c, d):
    def ev():
        have = {x["symbol"] for x in qa.screen.get("assets", [])}
        want = [a, b, c, d]
        missing = [s for s in want if s not in have]
        return (not missing, "missing " + ",".join(missing) if missing else "all present")
    screen(qa, "assets on screen", ev)


@then("every asset row on screen shows a symbol and a USD price")
def asset_rows_complete(qa):
    def ev():
        rows = qa.screen.get("assets", [])
        bad = [x for x in rows if not x["symbolText"] or not re.match(r"^\$[0-9]", x["usdText"])]
        return (len(bad) == 0 and len(rows) > 0, f"{len(bad)} incomplete")
    screen(qa, "asset rows complete", ev)


@then(parsers.parse("the {sym} row on screen is marked delisted"))
def delisted_row(qa, sym):
    def ev():
        row = next((x for x in qa.screen.get("assets", []) if x["symbol"] == sym), None)
        return (bool(row) and re.search("delisted", row["activeText"], re.I) is not None, row["activeText"] if row else f"no {sym} row")
    screen(qa, f"{sym} marked delisted", ev)


@then("the number of assets on screen equals the API asset count")
def count_eq_api(qa):
    def ev():
        r = cex.get("/assets")
        api = len(r["body"]["assets"] or [])
        return (len(qa.screen.get("assets", [])) == api, f"screen {len(qa.screen.get('assets', []))}, api {api}")
    screen(qa, "screen asset count == API", ev)


@when(parsers.parse('the wallet page for "{alias}" is opened'))
def open_wallet(qa, alias):
    def go():
        qa.wallet.open("/wallet/" + acct(qa, alias)["handle"])
        qa.screen["balances"] = qa.wallet.balances()
    qa.fetch_or_block(UNREACHABLE, go)


@then(parsers.parse("the {asset} balance on screen is {amt:f}"))
def balance_on_screen(qa, asset, amt):
    def ev():
        row = next((x for x in qa.screen.get("balances", []) if x["asset"] == asset), None)
        return (bool(row) and float(row["amountText"]) == float(amt), f"screen {row['amountText']}, want {amt}" if row else f"no {asset} row")
    screen(qa, f"{asset} balance on screen", ev)


@then(parsers.parse('every balance on screen matches the API balance for "{alias}"'))
def balances_match_api(qa, alias):
    def ev():
        r = cex.get("/balances/" + acct(qa, alias)["handle"])
        api = {x["asset"]: x["amount"] / 1e8 for x in (r["body"]["balances"] or [])}
        rows = qa.screen.get("balances", [])
        bad = [x for x in rows if float(x["amountText"]) != api.get(x["asset"])]
        return (len(bad) == 0 and len(rows) > 0, "mismatch " + ",".join(x["asset"] for x in bad) if bad else "match")
    screen(qa, "screen balances == API", ev)


@when("the op page for that bridge op is opened")
def open_op(qa):
    def go():
        qa.wallet.open("/op/" + str(qa.last_bridge["id"]))
        qa.screen["op"] = qa.wallet.op()
    qa.fetch_or_block(UNREACHABLE, go)


@then(parsers.parse('the op status on screen is "{status}"'))
def op_status_screen(qa, status):
    screen(qa, "op status on screen", lambda: (qa.screen.get("op") and qa.screen["op"]["statusText"] == status, qa.screen["op"]["statusText"] if qa.screen.get("op") else "no op page"))
