# qa-automation-crypto-cex — docs

QA automation for a centralized-exchange domain — swap, transfer, bridge, a spot
order book, maker-taker fees, scoped API keys, and staking — with one shared
grading core and two stacks (Node + Python) that read one Gherkin set and return
the **same verdict for every case**.

→ **[The repository](https://github.com/hunglamkienhung/qa-automation-crypto-cex)** ·
[README](https://github.com/hunglamkienhung/qa-automation-crypto-cex#readme)

## Contents

- **[Architecture](ARCHITECTURE.md)** — one core, two stacks, why the domain
  pairs a live read-only exchange (Kraken) with a self-written mini-cex that has
  a real database, and the exact integer money model.
- **[Grading](GRADING.md)** — Failed > Blocked > Passed, why an outage is never
  a failure, and a gate that fails in both directions.
- **[Gherkin conventions](GHERKIN.md)** — one feature set bound in two stacks.
- **[Queue format](QUEUE-FORMAT.md)** — the append-only source of truth.
- **[Demo script](DEMO.md)** — a five-minute walkthrough, least-dependent first.

## At a glance

| Tier | Target | Cases |
|---|---|---|
| DB | mini-cex SQLite, opened directly (balances, ledger, order book, stakes) | 23 |
| API | mini-cex REST: accounts, transfer, swap, bridge, order book + fees, API keys, staking | 49 |
| API | Kraken public API (read-only) | 6 |
| BOT | the pure risk gate | 10 |
| FE | mini-cex screens + interactive forms (Playwright) | 10 |
| | **Total** | **98** |

Modules: `01` DB · `02` mini-cex API · `03` Kraken · `04` risk gate · `05` FE ·
`06` spot order book + maker-taker fees · `07` scoped API keys + rate limits ·
`08` staking / earn.
