"""Read-only access to the mini-cex SQLite file. Mirror of node/be/db/store.js.

Both stacks open the same file. A missing file is DbUnreachable and grades
Blocked. The WAL store must live on a native Linux filesystem for a WSL reader
to memory-map it -- set MINI_CEX_DB to a /tmp path when running under WSL.
"""

from __future__ import annotations

import os
import sqlite3
from pathlib import Path

DB_FILE = Path(os.environ.get("MINI_CEX_DB") or Path(__file__).resolve().parents[3] / "services" / "mini-cex" / "data" / "mini-cex.db")
SCHEMA = Path(__file__).resolve().parents[3] / "services" / "mini-cex" / "db" / "schema.sql"


class DbUnreachable(Exception):
    pass


def _rows(cur):
    cols = [c[0] for c in cur.description] if cur.description else []
    return [dict(zip(cols, r)) for r in cur.fetchall()]


class Store:
    def __init__(self, file: Path = DB_FILE) -> None:
        self.file = Path(file)
        if not self.file.exists():
            raise DbUnreachable(f"no store at {self.file} -- start mini-cex (services/mini-cex/serve.sh up)")
        try:
            self.db = sqlite3.connect(f"file:{self.file.as_posix()}?mode=ro", uri=True, timeout=5, isolation_level=None)
            self.db.execute("SELECT 1 FROM assets").fetchall()
        except sqlite3.Error as err:
            raise DbUnreachable(f"cannot open {self.file}: {err}") from err

    def close(self):
        try:
            self.db.close()
        except sqlite3.Error:
            pass

    def all(self, sql, *p):
        return _rows(self.db.execute(sql, p))

    def get(self, sql, *p):
        r = self.all(sql, *p)
        return r[0] if r else None

    def count(self, table, where="", *p):
        return int(self.get(f"SELECT COUNT(*) AS n FROM {table} {where}", *p)["n"])

    def tables(self):
        return [r["name"] for r in self.all("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")]

    def account_id(self, handle):
        r = self.get("SELECT id FROM accounts WHERE handle = ?", handle)
        return int(r["id"]) if r else None

    def balance(self, account_id, asset):
        r = self.get("SELECT amount FROM balances WHERE account_id = ? AND asset = ?", account_id, asset)
        return int(r["amount"]) if r else 0

    def reserved(self, account_id, asset):
        r = self.get("SELECT reserved FROM balances WHERE account_id = ? AND asset = ?", account_id, asset)
        return int(r["reserved"]) if r else 0

    def ledger_balance(self, account_id, asset):
        return int(self.get("SELECT COALESCE(SUM(delta),0) AS s FROM ledger WHERE account_id = ? AND asset = ?", account_id, asset)["s"])


def throwaway():
    db = sqlite3.connect(":memory:", isolation_level=None)
    db.execute("PRAGMA foreign_keys = ON")
    db.executescript(SCHEMA.read_text(encoding="utf-8").replace("PRAGMA journal_mode = WAL;", ""))
    return db
