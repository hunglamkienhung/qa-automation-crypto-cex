-- Deterministic seed. Idempotent: INSERT OR IGNORE by primary key, so applying
-- it twice leaves exactly the same rows. Prices are USD per whole coin in
-- micro-dollars (1e6). Accounts and balances are NOT seeded -- every scenario
-- creates fresh accounts through the API, so account/balance rows never collide
-- between runs. One delisted asset and one inactive pair exist on purpose, as
-- the negative cases the tiers exercise.

INSERT OR IGNORE INTO assets (symbol, name, kind, decimals, usd_micro, active) VALUES
  ('USD',  'US Dollar',   'fiat',   2, 1000000,      1),
  ('USDC', 'USD Coin',    'crypto', 6, 1000000,      1),
  ('BTC',  'Bitcoin',     'crypto', 8, 60000000000,  1),
  ('ETH',  'Ether',       'crypto', 8, 2500000000,   1),
  ('SOL',  'Solana',      'crypto', 8, 100000000,    1),
  ('DOGE', 'Dogecoin',    'crypto', 8, 120000,       0);   -- delisted on purpose

INSERT OR IGNORE INTO pairs (base, quote, fee_bps, min_base, active) VALUES
  ('BTC',  'USD',  20, 10000,    1),   -- min 0.0001 BTC
  ('ETH',  'USD',  20, 100000,   1),   -- min 0.001 ETH
  ('SOL',  'USD',  20, 1000000,  1),   -- min 0.01 SOL
  ('BTC',  'USDC', 20, 10000,    1),
  ('ETH',  'USDC', 20, 100000,   1),
  ('SOL',  'USDC', 20, 1000000,  1),
  ('ETH',  'BTC',  30, 100000,   1),
  ('SOL',  'ETH',  30, 1000000,  1),
  ('USDC', 'USD',  0,  0,        1),
  ('DOGE', 'USD',  20, 0,        0);   -- inactive pair on purpose
