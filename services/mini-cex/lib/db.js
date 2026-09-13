'use strict';

const fs = require('fs');
const path = require('path');
const { DatabaseSync } = require('node:sqlite');

/**
 * Open (or create) the store, apply the schema, and seed it once. The file is
 * the contract between the service and both test stacks: they open this same
 * file read-only and assert on its rows directly.
 *
 * Foreign keys are enforced per connection, so they are turned on here for
 * every writer. A caller that only reads still gets a consistent view because
 * the service commits each mutation in a single transaction.
 */
function open(file, { seed = true } = {}) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const db = new DatabaseSync(file);
  db.exec('PRAGMA foreign_keys = ON');
  db.exec(fs.readFileSync(path.join(__dirname, '..', 'db', 'schema.sql'), 'utf8'));
  if (seed) db.exec(fs.readFileSync(path.join(__dirname, '..', 'db', 'seed.sql'), 'utf8'));
  return db;
}

module.exports = { open };
