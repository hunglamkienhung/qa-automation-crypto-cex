"""Read-only client for Kraken's public API. Mirror of node/be/api/venues/kraken.js.

Public market data only (Assets, AssetPairs, Ticker), no key. A transport
failure, a non-JSON body, or a non-empty Kraken `error` array all mean the
figure cannot be observed -- SiteUnreachable, which grades Blocked, never
Failed. The live exchange is not a system under test.
"""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.parse
import urllib.request

BASE = os.environ.get("KRAKEN_URL", "https://api.kraken.com/0/public").rstrip("/")
TIMEOUT_S = 15
USER_AGENT = "qa-automation-crypto-cex/1.0 (read-only invariants)"


class SiteUnreachable(Exception):
    pass


def _call(path_and_query):
    req = urllib.request.Request(BASE + path_and_query, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT_S) as res:
            status, text = res.status, res.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as err:
        if err.code in (403, 429) or err.code >= 500:
            raise SiteUnreachable(f"Kraken returned HTTP {err.code} for {path_and_query}") from err
        status, text = err.code, err.read().decode("utf-8", "replace")
    except (urllib.error.URLError, TimeoutError, OSError) as err:
        raise SiteUnreachable(f"Kraken did not answer {path_and_query}: {err}") from err
    try:
        body = json.loads(text) if text else None
    except json.JSONDecodeError:
        body = None
    if not isinstance(body, dict):
        raise SiteUnreachable(f"Kraken served a non-JSON body for {path_and_query} (a challenge or error page)")
    if isinstance(body.get("error"), list) and body["error"]:
        raise SiteUnreachable("Kraken error for " + path_and_query + ": " + ", ".join(body["error"]))
    if not isinstance(body.get("result"), dict):
        raise SiteUnreachable(f"Kraken returned no result for {path_and_query}")
    return body["result"]


class Kraken:
    SiteUnreachable = SiteUnreachable

    @staticmethod
    def assets():
        return _call("/Assets")

    @staticmethod
    def asset_pairs():
        return _call("/AssetPairs")

    @staticmethod
    def ticker(pair):
        return _call("/Ticker?pair=" + urllib.parse.quote(pair))

    @staticmethod
    def pair_names():
        r = Kraken.asset_pairs()
        return [p.get("wsname") for p in r.values() if p.get("wsname")]

    @staticmethod
    def last_price(pair):
        r = Kraken.ticker(pair)
        row = next(iter(r.values()), None)
        if not row or not isinstance(row.get("c"), list) or not row["c"]:
            raise SiteUnreachable(f"Kraken ticker for {pair} had no last price")
        n = float(row["c"][0])
        if not (n > 0):
            raise SiteUnreachable(f"Kraken ticker for {pair} had a non-numeric price")
        return n
