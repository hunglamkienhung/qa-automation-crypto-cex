"""Steps for the market-maker bot, API tier (be-mm-bot.feature) and DB tier
(be-mm-bot-db.feature). Mirror of node/be/bot/steps/mm.steps.js. The bot's account
is registered under qa.accounts so the shared teardown cancels its resting quotes.
"""

from __future__ import annotations

from pytest_bdd import given, parsers, then, when

from be.api.venues.minicex import ApiUnreachable, MiniCex
from be.bot.client.bot import MarketMaker

cex = MiniCex()


def coin(n):
    return round(float(n) * 1e8)


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


def make_bot(qa, ref, bps, kill_switch=False, dry_run=False):
    def go():
        acct = cex.create_account("mm")
        qa.accounts["mm"] = acct
        qa.mm_account = acct
        cex.deposit(acct["token"], "BTC", coin(1.0))
        cex.deposit(acct["token"], "USD", coin(100000))
        qa.mm_ref = coin(ref)
        qa.bot = MarketMaker(cex, token=acct["token"], handle=acct["handle"], base="BTC", quote="USD",
                             ref_price=coin(ref), spread_bps=bps, size=coin(0.1), kill_switch=kill_switch, dry_run=dry_run)
    act(qa, go)


@given(parsers.parse("a funded market maker on BTC/USD at reference {ref:d} with {bps:d} bps spread"))
def mm(qa, ref, bps):
    make_bot(qa, ref, bps)


@given(parsers.parse("a funded market maker on BTC/USD at reference {ref:d} with {bps:d} bps spread with the kill switch on"))
def mm_kill(qa, ref, bps):
    make_bot(qa, ref, bps, kill_switch=True)


@given(parsers.parse("a funded market maker on BTC/USD at reference {ref:d} with {bps:d} bps spread in dry-run mode"))
def mm_dry(qa, ref, bps):
    make_bot(qa, ref, bps, dry_run=True)


@given("the market maker quotes")
@when("the market maker quotes")
def mm_quotes(qa):
    act(qa, lambda: setattr(qa, "mm_result", qa.bot.quote()))


@when(parsers.parse("the market maker reprices to {ref:d}"))
@given(parsers.parse("the market maker reprices to {ref:d}"))
def mm_reprices(qa, ref):
    act(qa, lambda: setattr(qa, "mm_result", qa.bot.reprice(coin(ref))))


def _lift(qa):
    taker = cex.create_account("mmtaker")
    qa.accounts["mmtaker"] = taker
    cex.deposit(taker["token"], "USD", coin(100000))
    cex.place_order(taker["token"], {"base": "BTC", "quote": "USD", "side": "buy", "type": "limit", "price": qa.bot.ask_price(), "size": qa.bot.size})


@given("a taker lifts the maker's ask")
@when("a taker lifts the maker's ask")
def taker_lifts(qa):
    act(qa, lambda: _lift(qa))


# ---------------------------------------------------------------- API assertions

@then("the quote is placed")
def quote_placed(qa):
    assert_(qa, "quote placed", qa.mm_result and qa.mm_result["ok"] is True and not qa.mm_result.get("dryRun"), str(qa.mm_result))


@then("the bid is below the reference and the ask is above it")
def bid_ask_span(qa):
    r = qa.mm_result
    assert_(qa, "bid<ref<ask", r and r["bidPrice"] < qa.mm_ref < r["askPrice"], f"bid {r['bidPrice']} ref {qa.mm_ref} ask {r['askPrice']}" if r else "no result")


@then(parsers.parse('the quote is refused for "{reason}"'))
def quote_refused(qa, reason):
    assert_(qa, "quote refused " + reason, qa.mm_result and qa.mm_result["ok"] is False and reason in str(qa.mm_result.get("reason")), str(qa.mm_result))


@then("the quote is a dry run")
def quote_dry(qa):
    assert_(qa, "quote dry run", qa.mm_result and qa.mm_result["ok"] is True and qa.mm_result.get("dryRun") is True, str(qa.mm_result))


@then("the order book shows the maker's bid and ask")
def book_shows(qa):
    def go():
        b = cex.orderbook("BTC", "USD")["body"]
        has_bid = any(x["price"] == qa.bot.bid_price() for x in (b["bids"] or []))
        has_ask = any(x["price"] == qa.bot.ask_price() for x in (b["asks"] or []))
        assert_(qa, "book shows bid+ask", has_bid and has_ask, str(b))
    act(qa, go)


@then("the maker has exactly one bid and one ask resting")
def one_each(qa):
    def go():
        qs = qa.bot.active_quotes()
        bids = [o for o in qs if o["side"] == "buy"]
        asks = [o for o in qs if o["side"] == "sell"]
        assert_(qa, "one bid + one ask", len(bids) == 1 and len(asks) == 1, f"bids {len(bids)} asks {len(asks)}")
    act(qa, go)


@then("the resting ask is at the new ask price")
def ask_new_price(qa):
    def go():
        ask = next((o for o in qa.bot.active_quotes() if o["side"] == "sell"), None)
        assert_(qa, "ask at new price", ask and ask["price"] == qa.bot.ask_price(), f"got {ask['price']}" if ask else "no ask")
    act(qa, go)


@then("the maker's ask order is filled")
def ask_filled(qa):
    def go():
        r = cex.orders_of(qa.mm_account["handle"])
        ask = next((o for o in (r["body"]["orders"] or []) if o["id"] == qa.mm_result["ask"]["id"]), None)
        assert_(qa, "ask filled", ask and ask["status"] == "filled", f"status {ask['status']}" if ask else "no ask")
    act(qa, go)


@then("the maker has no resting quotes")
def no_resting(qa):
    def go():
        assert_(qa, "no resting quotes", len(qa.bot.active_quotes()) == 0, str(len(qa.bot.active_quotes())))
    act(qa, go)


@then("the maker's token does not leak into a log line")
def no_leak(qa):
    assert_(qa, "token does not leak", qa.bot.leaked_secret("mm posted a quote on BTC/USD") is False and qa.bot.leaked_secret(qa.mm_account["token"]) is True, "leak detector inconsistent")


# ---------------------------------------------------------------- DB assertions

def _maker_id(qa):
    return qa.store.account_id(qa.mm_account["handle"])


@then("the store has one open bid and one open ask for the maker")
def store_one_each(qa):
    def go():
        i = _maker_id(qa)
        bids = qa.store.count("orders", "WHERE account_id = ? AND side = 'buy' AND status = 'open'", i)
        asks = qa.store.count("orders", "WHERE account_id = ? AND side = 'sell' AND status = 'open'", i)
        assert_(qa, "one open bid + ask (store)", bids == 1 and asks == 1, f"bids {bids} asks {asks}")
    act(qa, go)


@then("the maker's reserved BTC covers the ask and reserved USD covers the bid")
def reserves_cover(qa):
    def go():
        i = _maker_id(qa)
        r_btc = qa.store.reserved(i, "BTC")
        r_usd = qa.store.reserved(i, "USD")
        bid_cost = (qa.bot.size * qa.bot.bid_price()) // int(1e8)
        assert_(qa, "reserves cover quotes", r_btc == qa.bot.size and r_usd == bid_cost, f"resBTC {r_btc} want {qa.bot.size}; resUSD {r_usd} want {bid_cost}")
    act(qa, go)


@then("a fill row records the ask size at the ask price")
def fill_at_ask(qa):
    def go():
        f = qa.store.get("SELECT * FROM fills WHERE base=? AND quote=? AND price=? AND size=? ORDER BY id DESC LIMIT 1", "BTC", "USD", qa.bot.ask_price(), qa.bot.size)
        assert_(qa, "fill at ask price", f is not None, "found" if f else "no fill")
    act(qa, go)


@then("the maker's ask order filled equals its size in the store")
def ask_filled_store(qa):
    def go():
        o = qa.store.get("SELECT * FROM orders WHERE id = ?", qa.mm_result["ask"]["id"])
        assert_(qa, "ask filled==size", o and o["filled"] == o["size"], f"filled {o['filled']} size {o['size']}" if o else "no order")
    act(qa, go)


@then("the maker has exactly two cancelled orders in the store")
def two_cancelled(qa):
    def go():
        n = qa.store.count("orders", "WHERE account_id = ? AND status = 'cancelled'", _maker_id(qa))
        assert_(qa, "two cancelled", n == 2, "got " + str(n))
    act(qa, go)


@then("the maker's reserved funds cover only the new quote")
def reserve_new_only(qa):
    def go():
        i = _maker_id(qa)
        r_btc = qa.store.reserved(i, "BTC")
        r_usd = qa.store.reserved(i, "USD")
        bid_cost = (qa.bot.size * qa.bot.bid_price()) // int(1e8)
        assert_(qa, "reserve only new quote", r_btc == qa.bot.size and r_usd == bid_cost, f"resBTC {r_btc}; resUSD {r_usd} want {bid_cost}")
    act(qa, go)


@then(parsers.parse("the ledger sum for the maker in {asset} equals its balance row"))
def maker_ledger(qa, asset):
    def go():
        i = _maker_id(qa)
        assert_(qa, "ledger==balance " + asset, qa.store.ledger_balance(i, asset) == qa.store.balance(i, asset), f"ledger {qa.store.ledger_balance(i, asset)} balance {qa.store.balance(i, asset)}")
    act(qa, go)
