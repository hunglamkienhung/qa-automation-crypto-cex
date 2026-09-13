'use strict';

const fs = require('fs');
const path = require('path');
const { DatabaseSync } = require('node:sqlite');

/**
 * Read-only access to the mini-cex SQLite file -- the same file the service
 * writes. The DB tier asserts on its rows; the API tier reads them to compare
 * with HTTP responses. A missing file is DbUnreachable and grades Blocked.
 *
 * The WAL store must live on a native Linux filesystem for a WSL reader to
 * memory-map it -- set MINI_CEX_DB to a /tmp path when running under WSL.
 */

const DB_FILE = process.env.MINI_CEX_DB
  || path.join(__dirname, '..', '..', '..', 'services', 'mini-cex', 'data', 'mini-cex.db');
const SCHEMA = path.join(__dirname, '..', '..', '..', 'services', 'mini-cex', 'db', 'schema.sql');

class DbUnreachable extends Error {}

class Store {
  constructor(file = DB_FILE) {
    if (!fs.existsSync(file)) throw new DbUnreachable('no store at ' + file + ' -- start mini-cex (services/mini-cex/serve.sh up)');
    this.file = file;
    try { this.db = new DatabaseSync(file, { readOnly: true }); } catch (err) { throw new DbUnreachable('cannot open ' + file + ': ' + err.message); }
  }
  close() { try { this.db.close(); } catch { /* already closed */ } }
  all(sql, ...p) { return this.db.prepare(sql).all(...p); }
  get(sql, ...p) { return this.db.prepare(sql).get(...p); }
  count(table, where = '', ...p) { return Number(this.get(`SELECT COUNT(*) AS n FROM ${table} ${where}`, ...p).n); }
  tables() { return this.all("SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name").map((r) => r.name); }
  primaryKey(table) { return this.all(`PRAGMA table_info(${table})`).filter((c) => c.pk > 0).sort((a, b) => a.pk - b.pk).map((c) => c.name); }

  accountId(handle) { const r = this.get('SELECT id FROM accounts WHERE handle = ?', handle); return r ? Number(r.id) : null; }
  balance(accountId, asset) { const r = this.get('SELECT amount FROM balances WHERE account_id = ? AND asset = ?', accountId, asset); return r ? Number(r.amount) : 0; }
  reserved(accountId, asset) { const r = this.get('SELECT reserved FROM balances WHERE account_id = ? AND asset = ?', accountId, asset); return r ? Number(r.reserved) : 0; }

  /** The balance an account+asset's ledger implies: the sum of its movements. */
  ledgerBalance(accountId, asset) {
    const r = this.get('SELECT COALESCE(SUM(delta), 0) AS s FROM ledger WHERE account_id = ? AND asset = ?', accountId, asset);
    return Number(r.s);
  }
}

/** A throwaway in-memory store with the schema applied, for constraint checks. */
function throwaway() {
  const db = new DatabaseSync(':memory:');
  db.exec('PRAGMA foreign_keys = ON');
  db.exec(fs.readFileSync(SCHEMA, 'utf8').replace(/PRAGMA journal_mode = WAL;/, ''));
  return db;
}

module.exports = { Store, DbUnreachable, DB_FILE, throwaway };
