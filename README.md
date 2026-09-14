# qa-automation-crypto-cex

![Pytest-BDD](https://img.shields.io/badge/Pytest--BDD-tests-0A9EDC?logo=pytest&logoColor=white)
![Cucumber](https://img.shields.io/badge/Cucumber-BDD-23D96C?logo=cucumber&logoColor=white)
![Playwright](https://img.shields.io/badge/Playwright-E2E-2EAD33?logo=playwright&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-store-003B57?logo=sqlite&logoColor=white)
![Kraken API](https://img.shields.io/badge/Kraken-public%20API-5741D9)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)
![Node](https://img.shields.io/badge/Node-24-5FA04E?logo=nodedotjs&logoColor=white)
[![CI](https://github.com/hunglamkienhung/qa-automation-crypto-cex/actions/workflows/ci.yml/badge.svg)](https://github.com/hunglamkienhung/qa-automation-crypto-cex/actions/workflows/ci.yml)

QA automation for a **centralized crypto exchange** domain — swap, transfer, and
bridge — built as a working system rather than a slideshow. One exchange domain
tested at **every layer it has** — database, API, and screen — by **two
independent stacks** (Node with Cucumber, Python with pytest-bdd) that read
**one** shared set of Gherkin features and must return the **same verdict for
every case**.

Nothing here needs an account, a key, or a paid service. Clone it and it runs.

[Tiếng Việt](README.vi.md) · [Architecture](docs/ARCHITECTURE.md) ·
[Grading](docs/GRADING.md) · [Gherkin](docs/GHERKIN.md) · [Demo script](docs/DEMO.md)

## The two systems under test

| System | Access | What it is |
|---|---|---|
| **mini-cex** | read + write, real DB | A small custodial exchange in `services/mini-cex`: one SQLite file, Node standard library only, a REST API, and small labelled HTML pages for Playwright. |
| **Kraken public API** | read-only, live | A real exchange's public market data (`Assets`, `AssetPairs`, `Ticker`) — the real world, which nobody here can tune to pass. |

`mini-cex` is where the **write** paths live, each one transaction:

- **transfer** — deposit, withdraw, and account-to-account moves; refuses to
  overdraw, debits and credits atomically, writes a matching ledger line, and is
  idempotent by key.
- **swap** — a spot conversion A→B at the quoted rate; refuses on insufficient
  balance or when the quote falls below a slippage floor, captures the rate,
  charges a fee, and writes both ledger legs.
- **bridge** — a cross-chain deposit or withdrawal as a state machine
  (`requested → locked → confirmed → credited`); idempotent by the external tx,
  capped per transaction, and restricted to a chain allowlist.
- **spot order book** — limit and market orders matched price-time priority with
  self-trade prevention, `GTC`/`IOC`/`FOK` and post-only, a resting order holding
  its funds in reserve, and a **maker-taker fee** by volume tier (top tier pays
  the maker a rebate). Every match conserves base and quote across the two sides.
- **scoped API keys** — a programmatic `X-API-Key` carries a `read`/`trade`/
  `withdraw` scope and a per-minute rate limit; a read key cannot trade, a trade
  key cannot withdraw, a revoked key is refused, and a busy key is throttled.
- **staking / earn** — a locked principal accrues a fixed APR over explicit
  simulated seconds (deterministic, no wall clock) and redeems for principal plus
  reward, idempotently; staked funds are not available to withdraw.

Amounts are integer base units (1e8 per coin) and prices are USD-micros, so
every figure is exact — no floats in the money path. The live Kraken tier
cross-checks the mini-cex's listed assets and prices against a real venue.
- **market-maker bot** — a client that quotes a post-only bid+ask around a
  reference, cancels/replaces on a reprice, passes every order through the pure
  risk gate, fills when a taker lifts a quote, retries only transport failures
  (never a valid rejection), and never leaks its token. Verified at both the API
  tier and, from the SQLite rows, the DB tier.

**116 cases** across both stacks, including a `be-cex-security.feature` tier that
probes the auth surface adversarially — a garbage bearer token (401), one account
reaching for another's API key (403), and secret hygiene: a minted key is shown
once and only a prefix is ever listed again, and no credential leaks in a public
response. It sits alongside the scoped-key + rate-limit tier (`be-cex-apikeys`).

## The two ideas worth a minute

**One Gherkin set, two stacks, one verdict.** `features/*.feature` are shared.
`node/` runs them with Cucumber; `python/` runs the same files with pytest-bdd.
A per-case disagreement is itself a finding — the grading logic is being read
differently in two places — and the build fails on it.

**Failed > Blocked > Passed, and an outage is never a failure.** A case is
Failed only when an observed proposition is wrong. When a live source (Kraken, a
down service) cannot be reached, the case is **Blocked**, never Failed. The CI
gate checks the *shape* of a run against `fixtures/expected-results.json`: it
fails both when a Passed turns Failed (a regression) and when a Failed turns
Passed (a check that stopped checking). See [docs/GRADING.md](docs/GRADING.md).

## Run in 30 seconds

```bash
# the shared grading core, both stacks
cd core/node && node --test "selftest/*.test.js"
cd ../python && pip install -e . && python -m pytest selftest -q
```

## Run the whole suite

Each step below is exactly what CI runs (`scripts/*.sh`), so it works by hand too.

```bash
# backend, one stack, no browser (seed mini-cex, then DB + API + Kraken + bot)
bash scripts/run-be.sh node       # or: python

# the screens (installs a chromium browser)
bash scripts/run-fe.sh node       # or: python

# the whole suite, then verify the run's shape against the baseline
bash scripts/gate.sh node
```

Prerequisites: Node ≥ 22.13 (for `node:sqlite`) and Python ≥ 3.11. The FE
scripts install their own browser. A devcontainer with all of it is in
[.devcontainer/](.devcontainer/devcontainer.json).

## Layout

```
core/            one grading/queue/report/bugflow core, vendored into this repo
services/
  mini-cex/      SQLite + REST + HTML custodial exchange — an object of test
features/        one Gherkin set, shared by both stacks
fixtures/        testcases.json (IDs) · expected-results.json (shape)
node/  python/   the two stacks: be/{db,api,bot} fe/ui
testcases/       catalogue generated from the features (never drifts)
scripts/         the exact commands CI runs; reproducible by hand
docs/            architecture, grading rules, Gherkin conventions, demo script
.github/workflows/ci.yml
```

## Honest scope

`mini-cex` is a **teaching model** of a custodial exchange, not a real one: no
authentication beyond a bearer handle, no real custody, and the "bridge" is a
simulated state machine, not an on-chain relayer. That is deliberate — it makes
the write-path invariants (a ledger that balances, a transfer that cannot
overdraw, an idempotent operation) exactly testable and fully deterministic. The
Kraken tier depends on a third party that can be slow or rate-limit; those cases
grade **Blocked**, not Failed, when that happens.
