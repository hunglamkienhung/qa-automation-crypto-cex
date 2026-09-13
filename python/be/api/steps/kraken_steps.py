"""Steps for be-kraken-api.feature -- the live exchange, read-only. Mirror of
node/be/api/steps/kraken.steps.js. Every read routes SiteUnreachable into
Blocked; a completed read is graded. Kraken is not a system under test.
"""

from __future__ import annotations

from pytest_bdd import parsers, then, when

from be.api.venues.kraken import Kraken, SiteUnreachable
from be.api.venues.minicex import ApiUnreachable, MiniCex

cex = MiniCex()


def kr_check(qa, description, cond, detail):
    if qa.source_error:
        qa.unobservable(description, "the source could not be reached -- " + qa.source_error)
        return
    qa.check(description, bool(cond), detail)


@when("the Kraken asset list is read")
def read_kr_assets(qa):
    qa.fetch_or_block((SiteUnreachable,), lambda: setattr(qa, "kr_assets", Kraken.assets()))


@when("the Kraken pair list is read")
def read_kr_pairs(qa):
    qa.fetch_or_block((SiteUnreachable,), lambda: setattr(qa, "kr_pairs", Kraken.pair_names()))


@when(parsers.parse('the Kraken last price for "{pair}" is read'))
def read_kr_price(qa, pair):
    qa.fetch_or_block((SiteUnreachable,), lambda: setattr(qa, "kr_price", Kraken.last_price(pair)))


@then("the Kraken asset list is non-empty")
def kr_assets_nonempty(qa):
    kr_check(qa, "Kraken assets non-empty", getattr(qa, "kr_assets", None) and len(qa.kr_assets) > 0, f"{len(qa.kr_assets)} assets" if getattr(qa, "kr_assets", None) else "none")


@then("every Kraken pair name is a non-empty string")
def kr_pairs_wellformed(qa):
    names = getattr(qa, "kr_pairs", []) or []
    bad = [n for n in names if not isinstance(n, str) or len(n) == 0]
    kr_check(qa, "Kraken pair names well-formed", len(names) > 0 and len(bad) == 0, f"{len(names)} names, {len(bad)} bad")


@then(parsers.parse("a USD pair exists on Kraken for each of {a}, {b}, {c}"))
def kr_usd_pairs(qa, a, b, c):
    names = set(getattr(qa, "kr_pairs", []) or [])
    alias = {"BTC": ["XBT", "BTC"]}

    def has(sym):
        return any((s + "/USD") in names for s in alias.get(sym, [sym]))
    missing = [s for s in (a, b, c) if not has(s)]
    kr_check(qa, "USD pairs exist on Kraken", len(missing) == 0, "missing " + ",".join(missing) if missing else "all present")


@then("the Kraken price is a positive number")
def kr_price_positive(qa):
    p = getattr(qa, "kr_price", None)
    kr_check(qa, "Kraken price positive", isinstance(p, (int, float)) and p > 0, f"price {p}")


@then("the mini-cex BTC price is the same order of magnitude as Kraken's")
def mini_vs_kraken(qa):
    if qa.source_error:
        qa.unobservable("mini-cex vs Kraken order of magnitude", "the source could not be reached -- " + qa.source_error)
        return
    try:
        r = cex.get("/assets")
        btc = next((x for x in (r["body"]["assets"] or []) if x["symbol"] == "BTC"), None)
        mini = btc["usd_micro"] / 1e6 if btc else None
    except ApiUnreachable as err:
        qa.unobservable("mini-cex vs Kraken order of magnitude", str(err))
        return
    ratio = (mini / qa.kr_price) if (mini and getattr(qa, "kr_price", None)) else 0
    qa.check("mini-cex BTC same order of magnitude as Kraken", 0.1 <= ratio <= 10, f"mini ${mini}, kraken ${qa.kr_price}, ratio {ratio:.2f}")
