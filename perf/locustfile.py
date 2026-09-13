"""Locust load test for the mini-cex service.

The performance counterpart to the functional BDD suite: the same REST API,
driven under concurrency. Amounts are in base units (1e8 per whole coin), the
same convention the service and the BDD steps use. Every request validates its
response so a wrong status counts as a failure, not just a slow success.

Run it headless with a pass/fail gate (see perf/run.sh):

    locust -f perf/locustfile.py --headless -u 40 -r 10 -t 30s \
        --host http://127.0.0.1:8110
"""

from __future__ import annotations

import os
import random
import time

from locust import HttpUser, between, events, task

MAX_FAIL_RATIO = float(os.environ.get("PERF_MAX_FAIL_RATIO", "0.01"))
MAX_P95_MS = float(os.environ.get("PERF_MAX_P95_MS", "750"))


def coin(x):
    return round(x * 1e8)


def _get(client, path, name, token=None, expect=(200,)):
    headers = {"authorization": "Bearer " + token} if token else {}
    with client.get(path, headers=headers, name=name, catch_response=True) as r:
        r.success() if r.status_code in expect else r.failure(f"{r.status_code} {r.text[:80]}")
        return r


def _post(client, path, name, token=None, json=None, expect=(200, 201)):
    headers = {"authorization": "Bearer " + token} if token else {}
    with client.post(path, json=json, headers=headers, name=name, catch_response=True) as r:
        r.success() if r.status_code in expect else r.failure(f"{r.status_code} {r.text[:80]}")
        return r


def _new_account(client, prefix="load"):
    handle = f"{prefix}-{int(time.time()*1000)}{random.randint(0,9999)}"
    r = _post(client, "/accounts", "POST /accounts", json={"handle": handle}, expect=(201,))
    return (r.json() if r.status_code == 201 else None)


class MarketData(HttpUser):
    """Reads the public market surface: listed assets, the book, the fee schedule."""

    weight = 5
    wait_time = between(0.1, 0.5)

    @task(3)
    def assets(self):
        _get(self.client, "/assets", "GET /assets")

    @task(3)
    def orderbook(self):
        _get(self.client, "/orderbook/BTC/USD", "GET /orderbook/BTC/USD")

    @task(1)
    def fees(self):
        _get(self.client, "/fees", "GET /fees")


class Quoter(HttpUser):
    """Prices a swap without committing to it -- a pure pricing endpoint."""

    weight = 2
    wait_time = between(0.2, 0.6)

    @task
    def quote(self):
        _post(self.client, "/quote", "POST /quote", json={"from_asset": "BTC", "to_asset": "USD", "from_amount": coin(0.1)})


class Trader(HttpUser):
    """Opens an account, funds it, and rests a small limit buy on the book."""

    weight = 2
    wait_time = between(0.2, 0.8)

    @task
    def trade(self):
        acct = _new_account(self.client, "trader")
        if not acct:
            return
        token = acct["token"]
        _post(self.client, "/deposit", "POST /deposit", token=token, json={"asset": "USD", "amount": coin(1_000_000)}, expect=(201,))
        # A buy well below the seeded mark rests instead of filling.
        _post(self.client, "/orders", "POST /orders", token=token, json={"base": "BTC", "quote": "USD", "side": "buy", "type": "limit", "price": coin(50_000), "size": coin(0.001)}, expect=(200, 201))
        _get(self.client, f"/orders/{acct['handle']}", "GET /orders/[handle]")


@events.quitting.add_listener
def _gate(environment, **_kw):
    stats = environment.stats.total
    p95 = stats.get_response_time_percentile(0.95)
    print(f"\nperf gate: requests={stats.num_requests} fails={stats.num_failures} "
          f"fail_ratio={stats.fail_ratio:.4f} p95={p95}ms rps={stats.total_rps:.1f}")
    reasons = []
    if stats.num_requests == 0:
        reasons.append("no requests were made")
    if stats.fail_ratio > MAX_FAIL_RATIO:
        reasons.append(f"fail ratio {stats.fail_ratio:.4f} > {MAX_FAIL_RATIO}")
    if p95 and p95 > MAX_P95_MS:
        reasons.append(f"p95 {p95}ms > {MAX_P95_MS}ms")
    if reasons:
        print("perf gate FAILED: " + "; ".join(reasons))
        environment.process_exit_code = 1
    else:
        print("perf gate PASSED")
        environment.process_exit_code = 0
