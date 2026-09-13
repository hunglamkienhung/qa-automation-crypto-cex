-- mini-cex: a small but real centralized exchange over one SQLite file. The
-- tables are the object under test; both test stacks open this same file and
-- assert on its rows directly, and the REST layer reads and writes it.
--
-- Amounts are stored in integer base units -- 1e8 per whole coin (8 dp), the
-- same scale for every asset -- never as a float, so every comparison is exact.
-- Prices are USD per whole coin in micro-dollars (1e6). The invariants a
-- custodian must never break -- a balance that never goes negative, a ledger
-- whose movements sum to the running balance, a swap that conserves value at
-- the quoted rate, an operation that is applied at most once per key -- are
-- enforced here so a bug in the service surfaces as a constraint violation or a
-- ledger that fails to balance, not as a quietly wrong number.

PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

-- The assets the exchange lists. decimals is informational (display); balances
-- are always in the uniform 1e8 base scale. kind separates fiat from crypto.
CREATE TABLE IF NOT EXISTS assets (
  symbol    TEXT    PRIMARY KEY,
  name      TEXT    NOT NULL,
  kind      TEXT    NOT NULL CHECK (kind IN ('fiat', 'crypto')),
  decimals  INTEGER NOT NULL CHECK (decimals >= 0 AND decimals <= 18),
  usd_micro INTEGER NOT NULL CHECK (usd_micro >= 0),   -- price of one whole coin, USD * 1e6
  active    INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1))
);

-- A tradable pair the exchange quotes. Both legs must be listed assets.
CREATE TABLE IF NOT EXISTS pairs (
  base       TEXT    NOT NULL REFERENCES assets(symbol),
  quote      TEXT    NOT NULL REFERENCES assets(symbol),
  fee_bps    INTEGER NOT NULL DEFAULT 20 CHECK (fee_bps >= 0 AND fee_bps <= 1000),
  min_base   INTEGER NOT NULL DEFAULT 0 CHECK (min_base >= 0),   -- minimum swap size, base units
  active     INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
  PRIMARY KEY (base, quote),
  CHECK (base <> quote)
);

CREATE TABLE IF NOT EXISTS accounts (
  id          INTEGER PRIMARY KEY,
  handle      TEXT    NOT NULL UNIQUE,
  token       TEXT    UNIQUE,            -- the API bearer, issued at creation
  created_at  INTEGER NOT NULL
);

-- One row per (account, asset). amount is in base units and never negative.
CREATE TABLE IF NOT EXISTS balances (
  account_id  INTEGER NOT NULL REFERENCES accounts(id),
  asset       TEXT    NOT NULL REFERENCES assets(symbol),
  amount      INTEGER NOT NULL DEFAULT 0 CHECK (amount >= 0),
  PRIMARY KEY (account_id, asset)
);

-- Every balance change, with a reason and a reference to what caused it. The
-- running balance must always equal the sum of an account+asset's movements --
-- a ledger the DB tier checks. Append-only; delta may be + or - but never 0.
CREATE TABLE IF NOT EXISTS ledger (
  id          INTEGER PRIMARY KEY,
  account_id  INTEGER NOT NULL REFERENCES accounts(id),
  asset       TEXT    NOT NULL REFERENCES assets(symbol),
  delta       INTEGER NOT NULL CHECK (delta <> 0),
  reason      TEXT    NOT NULL CHECK (reason IN
                ('seed','deposit','withdraw','transfer_in','transfer_out',
                 'swap_in','swap_out','fee','bridge_credit','bridge_debit')),
  ref_type    TEXT,                       -- 'transfer' | 'swap' | 'bridge' | NULL
  ref_id      INTEGER,
  created_at  INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS ledger_acct_asset ON ledger(account_id, asset);

-- An account-to-account move, or a deposit/withdraw against the outside world.
-- from_account is NULL for a deposit, to_account is NULL for a withdraw.
CREATE TABLE IF NOT EXISTS transfers (
  id              INTEGER PRIMARY KEY,
  from_account    INTEGER REFERENCES accounts(id),
  to_account      INTEGER REFERENCES accounts(id),
  asset           TEXT    NOT NULL REFERENCES assets(symbol),
  amount          INTEGER NOT NULL CHECK (amount > 0),
  kind            TEXT    NOT NULL CHECK (kind IN ('internal', 'deposit', 'withdraw')),
  idempotency_key TEXT    UNIQUE,          -- a retried transfer returns the first one
  created_at      INTEGER NOT NULL,
  CHECK (from_account IS NOT NULL OR to_account IS NOT NULL)
);

-- A spot conversion A -> B at the quoted rate, with a fee on the output leg.
-- from_amount and to_amount are base units; rate_micro is the USD-implied
-- base->quote rate captured at execution; fee_amount is in the to_asset.
CREATE TABLE IF NOT EXISTS swaps (
  id              INTEGER PRIMARY KEY,
  account_id      INTEGER NOT NULL REFERENCES accounts(id),
  from_asset      TEXT    NOT NULL REFERENCES assets(symbol),
  to_asset        TEXT    NOT NULL REFERENCES assets(symbol),
  from_amount     INTEGER NOT NULL CHECK (from_amount > 0),
  to_amount       INTEGER NOT NULL CHECK (to_amount > 0),
  fee_amount      INTEGER NOT NULL DEFAULT 0 CHECK (fee_amount >= 0),
  rate_micro      INTEGER NOT NULL CHECK (rate_micro > 0),
  idempotency_key TEXT    UNIQUE,
  created_at      INTEGER NOT NULL,
  CHECK (from_asset <> to_asset)
);

-- A cross-chain deposit or withdrawal, as a state machine. A withdrawal locks
-- the balance (requested -> locked), a simulated relayer confirms it
-- (-> confirmed -> credited on the destination). A deposit is credited when
-- its external tx is first observed. Idempotent by (direction, ext_tx).
CREATE TABLE IF NOT EXISTS bridge_ops (
  id          INTEGER PRIMARY KEY,
  account_id  INTEGER NOT NULL REFERENCES accounts(id),
  asset       TEXT    NOT NULL REFERENCES assets(symbol),
  amount      INTEGER NOT NULL CHECK (amount > 0),
  direction   TEXT    NOT NULL CHECK (direction IN ('deposit', 'withdraw')),
  src_chain   TEXT    NOT NULL,
  dst_chain   TEXT    NOT NULL,
  status      TEXT    NOT NULL CHECK (status IN ('requested','locked','confirmed','credited','failed')),
  ext_tx      TEXT    NOT NULL,
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL,
  UNIQUE (direction, ext_tx),
  CHECK (src_chain <> dst_chain)
);
