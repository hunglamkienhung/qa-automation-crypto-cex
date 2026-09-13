"""HTTP client for the mini-cex service. Mirror of node/be/api/venues/minicex.js.
urllib only. A transport failure is ApiUnreachable (grades Blocked); a 4xx/5xx
is an answer, often the one under test.
"""

from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request

BASE = os.environ.get("MINI_CEX_URL", "http://127.0.0.1:8110").rstrip("/")


class ApiUnreachable(Exception):
    pass


class MiniCex:
    def __init__(self, base: str = BASE) -> None:
        self.base = base

    def request(self, method, path, token=None, body=None, headers=None):
        h = dict(headers or {})
        if token:
            h["Authorization"] = "Bearer " + token
        data = None
        if body is not None:
            h["Content-Type"] = "application/json"
            data = json.dumps(body).encode()
        req = urllib.request.Request(self.base + path, data=data, headers=h, method=method)
        try:
            with urllib.request.urlopen(req, timeout=15) as res:
                status, text = res.status, res.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as err:
            status, text = err.code, err.read().decode("utf-8", "replace")
        except (urllib.error.URLError, TimeoutError, OSError) as err:
            raise ApiUnreachable(f"mini-cex at {self.base} did not answer {method} {path}: {err}") from err
        try:
            parsed = json.loads(text) if text else None
        except json.JSONDecodeError:
            parsed = None
        return {"status": status, "body": parsed, "text": text}

    def get(self, p, **kw):
        return self.request("GET", p, **kw)

    def post(self, p, body=None, **kw):
        return self.request("POST", p, body=body, **kw)

    def create_account(self, prefix="acct"):
        handle = f"{prefix}-{int(time.time()*1000):x}{os.urandom(2).hex()}"
        r = self.post("/accounts", {"handle": handle})
        if r["status"] != 201:
            raise RuntimeError("create account failed: HTTP " + str(r["status"]) + " " + r["text"])
        return r["body"]

    def deposit(self, token, asset, amount, key=None):
        return self.post("/deposit", {"asset": asset, "amount": amount, "idempotency_key": key}, token=token)

    def withdraw(self, token, asset, amount, key=None):
        return self.post("/withdraw", {"asset": asset, "amount": amount, "idempotency_key": key}, token=token)

    def transfer(self, token, to_handle, asset, amount, key=None):
        return self.post("/transfer", {"to_handle": to_handle, "asset": asset, "amount": amount, "idempotency_key": key}, token=token)

    def quote(self, from_asset, to_asset, from_amount):
        return self.post("/quote", {"from_asset": from_asset, "to_asset": to_asset, "from_amount": from_amount})

    def swap(self, token, body):
        return self.post("/swap", body, token=token)

    def bridge_withdraw(self, token, body):
        return self.post("/bridge/withdraw", body, token=token)

    def bridge_deposit(self, body):
        return self.post("/bridge/deposit", body)

    def bridge_confirm(self, op_id):
        return self.post(f"/bridge/{op_id}/confirm")

    def funded(self, asset, amount, prefix="acct"):
        acct = self.create_account(prefix)
        r = self.deposit(acct["token"], asset, amount)
        if r["status"] != 201:
            raise RuntimeError("funding failed: HTTP " + str(r["status"]) + " " + r["text"])
        return acct
