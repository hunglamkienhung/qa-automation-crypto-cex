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
  id                INTEGER PRIMARY KEY,
  handle            TEXT    NOT NULL UNIQUE,
  token             TEXT    UNIQUE,            -- the API bearer, issued at creation
  volume_usd_micro  INTEGER NOT NULL DEFAULT 0 CHECK (volume_usd_micro >= 0),  -- taker volume, drives the fee tier
  created_at        INTEGER NOT NULL
);

-- One row per (account, asset). amount is in base units and never negative.
-- `reserved` is the part locked by resting orders and stakes; the tradable
-- balance is amount - reserved, and reserved can never exceed amount.
CREATE TABLE IF NOT EXISTS balances (
  account_id  INTEGER NOT NULL REFERENCES accounts(id),
  asset       TEXT    NOT NULL REFERENCES assets(symbol),
  amount      INTEGER NOT NULL DEFAULT 0 CHECK (amount >= 0),
  reserved    INTEGER NOT NULL DEFAULT 0 CHECK (reserved >= 0 AND reserved <= amount),
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
                 'swap_in','swap_out','fee','bridge_credit','bridge_debit',
                 'trade_in','trade_out','stake_lock','stake_unlock','stake_reward')),
  ref_type    TEXT,                       -- 'transfer' | 'swap' | 'bridge' | 'order' | 'stake' | NULL
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

-- ============================ v2: spot order book ============================

-- The maker-taker fee schedule, by 30-day taker volume. tier 0 is the entry
-- band; a maker_bps below zero is a rebate the maker is paid.
CREATE TABLE IF NOT EXISTS fee_tiers (
  tier             INTEGER PRIMARY KEY,
  min_volume_micro INTEGER NOT NULL CHECK (min_volume_micro >= 0),  -- USD * 1e6
  maker_bps        INTEGER NOT NULL,                                 -- may be < 0 (rebate)
  taker_bps        INTEGER NOT NULL CHECK (taker_bps >= 0)
);

-- A spot order on one pair. price is NULL for a market order. filled never
-- exceeds size; a resting order holds its funds in balances.reserved.
CREATE TABLE IF NOT EXISTS orders (
  id              INTEGER PRIMARY KEY,
  account_id      INTEGER NOT NULL REFERENCES accounts(id),
  base            TEXT    NOT NULL REFERENCES assets(symbol),
  quote           TEXT    NOT NULL REFERENCES assets(symbol),
  side            TEXT    NOT NULL CHECK (side IN ('buy', 'sell')),
  type            TEXT    NOT NULL CHECK (type IN ('limit', 'market')),
  price           INTEGER CHECK (price IS NULL OR price > 0),   -- quote per whole base, USD-style micro of the pair
  size            INTEGER NOT NULL CHECK (size > 0),            -- base units
  filled          INTEGER NOT NULL DEFAULT 0 CHECK (filled >= 0 AND filled <= size),
  status          TEXT    NOT NULL CHECK (status IN ('open', 'partial', 'filled', 'cancelled', 'rejected')),
  tif             TEXT    NOT NULL DEFAULT 'GTC' CHECK (tif IN ('GTC', 'IOC', 'FOK')),
  post_only       INTEGER NOT NULL DEFAULT 0 CHECK (post_only IN (0, 1)),
  idempotency_key TEXT    UNIQUE,
  created_at      INTEGER NOT NULL,
  seq             INTEGER NOT NULL,                             -- monotonic, for price-time priority
  CHECK (base <> quote)
);
CREATE INDEX IF NOT EXISTS orders_book ON orders(base, quote, side, status);

-- One match between a taker and a resting maker order. Fees are in the leg each
-- side receives; a taker and its maker are never the same account.
CREATE TABLE IF NOT EXISTS fills (
  id            INTEGER PRIMARY KEY,
  taker_order   INTEGER NOT NULL REFERENCES orders(id),
  maker_order   INTEGER NOT NULL REFERENCES orders(id),
  base          TEXT    NOT NULL REFERENCES assets(symbol),
  quote         TEXT    NOT NULL REFERENCES assets(symbol),
  price         INTEGER NOT NULL CHECK (price > 0),
  size          INTEGER NOT NULL CHECK (size > 0),             -- base units matched
  taker_fee     INTEGER NOT NULL DEFAULT 0,
  maker_fee     INTEGER NOT NULL DEFAULT 0,                    -- may be < 0 (rebate paid to maker)
  taker_account INTEGER NOT NULL REFERENCES accounts(id),
  maker_account INTEGER NOT NULL REFERENCES accounts(id),
  created_at    INTEGER NOT NULL,
  CHECK (taker_account <> maker_account)
);

-- ============================ v2: API keys ============================

-- A scoped programmatic key. Presented in the X-API-Key header; the scope gates
-- what it can do (read < trade < withdraw), and rate_per_min caps its calls.
CREATE TABLE IF NOT EXISTS api_keys (
  key          TEXT    PRIMARY KEY,
  account_id   INTEGER NOT NULL REFERENCES accounts(id),
  scope        TEXT    NOT NULL CHECK (scope IN ('read', 'trade', 'withdraw')),
  rate_per_min INTEGER NOT NULL DEFAULT 120 CHECK (rate_per_min > 0),
  revoked      INTEGER NOT NULL DEFAULT 0 CHECK (revoked IN (0, 1)),
  created_at   INTEGER NOT NULL
);

-- ============================ v2: staking / earn ============================

-- A locked principal accruing a fixed APR. Accrual is driven by explicit
-- simulated seconds, so it is deterministic and independent of the wall clock.
CREATE TABLE IF NOT EXISTS stakes (
  id              INTEGER PRIMARY KEY,
  account_id      INTEGER NOT NULL REFERENCES accounts(id),
  asset           TEXT    NOT NULL REFERENCES assets(symbol),
  principal       INTEGER NOT NULL CHECK (principal > 0),
  apr_bps         INTEGER NOT NULL CHECK (apr_bps >= 0),
  elapsed_seconds INTEGER NOT NULL DEFAULT 0 CHECK (elapsed_seconds >= 0),
  accrued         INTEGER NOT NULL DEFAULT 0 CHECK (accrued >= 0),
  status          TEXT    NOT NULL CHECK (status IN ('active', 'redeemed')),
  idempotency_key TEXT    UNIQUE,
  created_at      INTEGER NOT NULL
);
