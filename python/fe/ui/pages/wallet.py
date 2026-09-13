"""Page object for the mini-cex HTML pages. Mirror of node/fe/ui/pages/wallet.js.
Reads by label; a page that never loads raises ScreenNotReady (grades Blocked)."""

from __future__ import annotations

import os

BASE = os.environ.get("MINI_CEX_URL", "http://127.0.0.1:8110").rstrip("/")


class ScreenNotReady(Exception):
    pass


class WalletPage:
    def __init__(self, page) -> None:
        self.page = page
        self.base = BASE

    def open(self, path="/"):
        try:
            self.page.goto(self.base + path, wait_until="domcontentloaded", timeout=15000)
        except Exception as err:  # noqa: BLE001
            raise ScreenNotReady(f"mini-cex page {path} did not load: {err}") from err

    def assets(self):
        try:
            self.page.wait_for_selector("ul.assets li.asset", timeout=15000)
        except Exception as err:  # noqa: BLE001
            raise ScreenNotReady("asset list never rendered") from err
        return self.page.eval_on_selector_all("ul.assets li.asset", """els => els.map(el => ({
            symbol: el.getAttribute('data-symbol'),
            symbolText: el.querySelector('.symbol') ? el.querySelector('.symbol').textContent.trim() : '',
            usdText: el.querySelector('.usd') ? el.querySelector('.usd').textContent.trim() : '',
            activeText: el.querySelector('.active') ? el.querySelector('.active').textContent.trim() : '',
        }))""")

    def balances(self):
        try:
            self.page.wait_for_selector("h1.handle", timeout=15000)
        except Exception as err:  # noqa: BLE001
            raise ScreenNotReady("wallet page never rendered") from err
        return self.page.eval_on_selector_all("ul.balances li.balance", """els => els.map(el => ({
            asset: el.getAttribute('data-asset'),
            amountText: el.querySelector('.amount') ? el.querySelector('.amount').textContent.trim() : '',
        }))""")

    def op(self):
        try:
            self.page.wait_for_selector("h1.op-id", timeout=15000)
        except Exception as err:  # noqa: BLE001
            raise ScreenNotReady("op page never rendered") from err

        def read(sel):
            el = self.page.query_selector(sel)
            return el.text_content().strip() if el else None
        return {"idText": read("h1.op-id"), "directionText": read(".direction"), "statusText": read(".status"), "amountText": read(".amount")}
